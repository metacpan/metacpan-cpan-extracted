package SQL::Bibliosoph::CatalogFile; {
	use Moose;
    use utf8;
	use Data::Dumper;
    use Package::Constants; 
    use SQL::Bibliosoph::Exceptions;

    our $VERSION = "2.00";

    has file                => ( is => 'rw', isa=>'Str',  required => 1 );
    has read_only           => ( is => 'rw', isa=>'Bool', default => 0 );
    has 'constants_from'    => ( is => 'ro', isa => 'Maybe[Str]');

	#------------------------------------------------------------------

	# Constructor
	sub BUILD {
		my ($self) = @_;

		my $file = $self->file();

		# Is read only?
		if (substr ($file,0,1) eq '<' ) {
			$file = substr($file,1);
			$self->read_only(1);
		}

        SQL::Bibliosoph::Exception::CatalogFileError->throw(
            desc => "File does not exists $file " 
        ) if ! -e $file;
	}

    #------------------------------------------------------------------
    sub replace_contants {
        my ($self, $pstr)  =@_;

        my $p = $self->constants_from() or return;

        eval {

            # Read constants
            eval "require $p";

            import $p;
            my @cs = Package::Constants->list($p);

            # DO Replace constants
            foreach my $key (@cs) {
                my $value = eval "$key" ;
                $$pstr =~ s/\b$key\b/$value/g;
            }
        };
        if ($@) {
            die "error importing constants from $p : $@";
        }
    }

    #------------------------------------------------------------------

	sub read {
		my ($self) = @_;

		my $file_contents= $self->file_to_str( $self->file() ); 

        $self->replace_contants(\$file_contents);

		my $qs = $self->_parse($file_contents);

		# Read only?
		$self->filter_out_writes(\$qs) if $self->read_only();

		return $qs;
	}

	sub _parse {
		my ($self, $raw) = @_;
		return {} if ! $raw;

#       print STDERR "RAW: $raw\n\n";        
		return {
				map { 
					$_->[0] => $_->[1]
				}
				grep { $_->[0] } 						# Filter out empty element
				map {
					[ 
						map	  { $_ =~ s/^\s+|\s+$//g;$_ } 	# Trim
						split /\]\s*\n/,$_ 				# Separate name & statement
					]	
				}
				grep { $_ } 							# Filter out empty element
				split (/--\s*\[/ , 						# Separate elements
					$raw
				) 
		};
	}

	#------------------------------------------------------------------
	# Filter (in-place) write queries
	sub filter_out_writes {
		my ($self,$queries)= @_;

		$$queries  = {
			map {
				$_ => $$queries->{$_}
			}
			grep {
				$_ && $$queries->{$_} && ! ( $$queries->{$_} =~ /^insert|^update|^delete/i  )
			}
			keys %$$queries
		};
	}

	#------------------------------------------------------------------
	# Reads a file to a string
	sub file_to_str {
		my ($self, $file) = @_;

		my $FH;
		open ($FH,$file) 
			or SQL::Bibliosoph::Exception::CatalogFileError->throw(
                desc => "Could not read \"".$file."\" : $!"
        ); 

		my @all = <$FH>;
		close ($FH);
		return join ('', 
			grep { ! /^#/ } 		    #filler out comments with #
			grep { ! /^--[^\[]+/ } 		#filler out comments with --
			grep { ! /^[\s\t]*$/ } 		#filler out blanks
			@all
		);
	}
}

1;

__END__

=head1 NAME

SQL::Bibliosoph::CatalogFile - Bibliosoph SQL Statements Parser

=head1 VERSION

2.0

=head1 DESCRIPTION

Reads a SQL library statements file, using the BB format (SEE below)

=head1 BB Format

--[ Query_name1 ] 
SQL statement

The query name must be a simple string, case sensitive, with no spaces. The file can have comment in every line, starting with #. Statements can include bind params denoted with question mark `?`. Optionally, parameters can be numbered: 1?, 2?, 3? ... This allows to reuse paraments, like in:

		SELECT * 
			FROM user
			 WHERE name = 1? OR nick = 1?

The bind parameter number can be preceded by a `#`. This force the parameter to be strictly numeric. This is useful for using bind parameters with the LIMIT clause.

==head1 Examples

=over

=item A simple query, using two bind parament

	--[ GET_T1 ]
	# A very nice commentA
		SELECT		t1.*
		FROM		table1 t1
	# A other comment
        LEFT JOIN   table2 t2
        ON			t1.id = t2.t1_fk
        WHERE		t2.id = ? 
		LIMIT #?

=item An insert statement. This returns the last inserted ID.

	--[ INSERT_USER ]
	# This returns LAST_INSERT_ID if `user` has a auto_increment column
		INSERT 
			INTO user (name,country) 
			VALUES 
			(?, IFNULL(?,'US') )

=item An update statement. Returns modifed rows.

	--[ AGE_USERS ]
	# This returns the modified rows
		UPDATE user
			SET age = age + 1
			WHERE birthday = ? 

=item The select using numeric and ordered params

	--[ GET_USERS ]
	# Example using numeric and ordered params
		SELECT * 
			FROM user 
			WHERE 
				(1? IS NULL OR country = 1? )
				AND (2? IS NULL OR state =  2?)
			LIMIT #3?,#4?

=back

=head1 AUTHORS

SQL::Bibliosoph by Matias Alejo Garcia (matiu at cpan.org) and Lucas Lain (lucas at confronte.com).

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


