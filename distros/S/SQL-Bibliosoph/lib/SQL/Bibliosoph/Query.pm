package SQL::Bibliosoph::Query; {
	use Moose;
	use DBI;
    use Data::Dumper;
    use Time::HiRes qw(gettimeofday tv_interval);

    use Log::Contextual::WarnLogger;
    use Log::Contextual qw(:log),
    -default_logger => Log::Contextual::WarnLogger->new({
        env_prefix => 'Bibliosoph'
    });


    use feature qw(say);

    use SQL::Bibliosoph::Dummy;
    use SQL::Bibliosoph::Exceptions;

    our $VERSION = "2.00";

    has benchmark  => ( is => 'rw', isa=>'Num', default => 0);
    has debug      => ( is => 'rw', isa=>'Bool', default => 0);
    has quiet      => ( is => 'rw', isa=>'Bool', default => 0);
    has dbh        => ( is => 'rw', isa => 'DBI::db',  required=> 1);
    has delayed    => ( is => 'rw', isa => 'Bool', default=> 0);

    has name       => ( is => 'rw', default=> 'unnamed');
    has st         => ( is => 'rw');
    has sth        => ( is => 'rw');
    has bind_links => ( is => 'rw', default => sub { return []; } );
    has bind_params=> ( is => 'rw');

    has throw_errors=> ( is => 'rw', default => 1);



	sub BUILD {
		my ($self) = @_;

        $self->prepare() unless $self->delayed();
	}

	#------------------------------------------------------------------
    
	sub prepare {
        my ($self) = @_;

		my $st = $self->st;

		# Process bb language
		my $numeric_fields  = $self->parse(\$st);

        #say 'Preparing "' . $self->name() ;

		$self->sth( $self->dbh()->prepare_cached($st) )
            or SQL::Bibliosoph::Exception::QuerySyntaxError->throw(
                desc => "error preparing :  $st"
        );

		# Set numeric bind variables
		foreach (@$numeric_fields) {
			$self->sth()->bind_param($_,100,DBI::SQL_INTEGER);
		}

        $self->delayed(0);
    }

	#------------------------------------------------------------------
	sub select_many {
		my ($self, $values, $splice) = @_;

        $self->prepare() if $self->delayed();

		return $self->pexecute($values)->fetchall_arrayref($splice)
	}

	#------------------------------------------------------------------
    # with sql_calc_found_rows
	sub select_many2 {
		my ($self, $values,$splice) = @_;

        $self->prepare() if $self->delayed();

		return ( 
            $self->pexecute($values)->fetchall_arrayref($splice),
            $self->dbh()->selectrow_array('SELECT FOUND_ROWS()'),
        )
	}

	#------------------------------------------------------------------
	# It's good to return [] if not found in order to allow
	# to do @{xxxx} in the caller
	sub select_row {
		my ($self,$values) = @_;

        $self->prepare() if $self->delayed();



		return $self->pexecute($values)->fetchrow_arrayref() || [];
	}

	#------------------------------------------------------------------
    # Returns a hash ref
	sub select_row_hash {
		my ($self, $values) = @_;

        $self->prepare() if $self->delayed();

		return $self->pexecute($values)->fetchrow_hashref() || {};
	}

	#------------------------------------------------------------------
	sub select_do {
		my ($self, $values) = @_;

        $self->prepare() if $self->delayed();

		return $self->pexecute($values);
	}

	#------------------------------------------------------------------
	# Private
	#------------------------------------------------------------------
	
	# Replaces #? bind variables to ?
	# and retuns 
	sub parse {
		my ($self,$st)  = @_;
		my @nums;

		my @m = ($$st =~ m/(\#?\d*?\?)/g );
        my $numbered =0;

		my $total=0;
		foreach (@m)  {

			# Numeric field?
			/\#/ && do {
				push @nums, $total+1;
			};

			# Linked field?
			/(\d+)/ && do {

                $self->bind_links()->[$total]= int($1);
                $numbered++;
			};
			$total++;
		}
		$self->bind_params($total);

        SQL::Bibliosoph::Exception::QuerySyntaxError->throw(
            desc => "Bad statament use ALL numbered bind variables, or NONE, but don't mix them in $$st"
        ) if $numbered && $numbered != $total;

		# Replaces nums
		$$st =~ s/\#?\d*?\?/?/g;

		return \@nums;
	}

	#------------------------------------------------------------------

	sub pexecute {
		my ($self,$values) = @_;

        my $start_time = [ gettimeofday ] if $self->benchmark();



		# Completes the input array
		if (@$values < $self->bind_params()) {
			$values->[$self->bind_params()-1] = undef;
		}
        #say "EXE ", $self->dump(), 'VAUES', Dumper($values);

		# Use links
		eval {
			# Has Numeric Links? ( i.e. 3? )
            my $l = $self->bind_links();
			if ( @$l>0 ) {
				#say("start:".Dumper($values), Dumper($l));

				my @v;
				foreach (@$l) {
					push @v, $values->[$_-1];
				}
                #say "EXE1 ". Dumper(@v);

				$self->sth()->execute (@v);
			}

			# No links, direct param mapping ( ? ? )
			else {
                #say "EXE2 ", Dumper($values);
				$self->sth()->execute( 
                        @$values[ 0 .. $self->bind_params() - 1 ],
                );
			}
		};

        if ( $@ ) {

            my $e = __PACKAGE__ 
                    ." ERROR  $@ in statement  '"
                    .  $self->name() 
                    . "': \"" 
                    . $self->st() 
                    . '\"'
                    ;

            if (
                $self->throw_errors() == 2
                || ($self->throw_errors() == 1 && $e !~ /\sDuplicate entry\s/ )
            ) {
               # $sth->err and $DBI::err will be true if error was from DBI
               SQL::Bibliosoph::Exception::QuerySyntaxError->throw (
                   desc => $e,
               ) unless $self->quiet() ; # print the error
            }
            else {
                log_debug { $e };        
                return SQL::Bibliosoph::Dummy->new();
            }
        }

        if ( my $min_t = $self->benchmark() ) {

            my $t = tv_interval( $start_time ) ;

            # Only if it takes more that 1ms...
            log_debug { "[". $t *1000 . " ms] " } if $t > $min_t;
        }

		return $self->sth();
	}

}

1;

__END__

=head1 NAME

SQL::Bibliosoph::Query - A SQL Prepared statement 

=head1 VERSION

2.0

=head1 DESCRIPTION

	Implements one prepared statement

=head1 METHODS
		
=head2 new

	Constructor: Parameters are:

=item dbh 

	a DB handler

=item st 

The SQL statement string, using BB syntax (SEE SQL::Bibliosoph::CatalogFile)

=item name

The SQL statement name. (only for debugging information, on statement error).

=head2 destroy

Release the prepared statement.

=head1 AUTHORS

SQL::Bibliosoph by Matias Alejo Garcia (matias at confronte.com) and Lucas Lain (lucas at confronte.com).

=head1 COPYRIGHT

Copyright (c) 2007-2009 Matias Alejo Garcia. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SUPPORT / WARRANTY

The SQL::Bibliosoph is free Open Source software. IT COMES WITHOUT WARRANTY OF ANY KIND.


=head1 SEE ALSO
	
	SQL::Bibliosoph
	SQL::Bibliosoph::CatalogFile

At	http://nits.com.ar/bibliosoph you can find:
	* Examples
	* VIM syntax highlighting definitions for bb files
	* CTAGS examples for indexing bb files.


=head1 ACKNOWLEDGEMENTS

To Confronte.com and its associates to support the development of this module.


