package Proc::ProcessTable::Match;

use 5.006;
use strict;
use warnings;

=head1 NAME

Proc::ProcessTable::Match - Matches a Proc::ProcessTable::Process against a stack of checks.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

    use Proc::ProcessTable::Match;
    use Proc::ProcessTable;
    use Data::Dumper;
    
    # looks for a kernel proc with the PID of 0
    my %args=(
              checks=>[
                       {
                        type=>'PID',
                        invert=>0,
                        args=>{
                               pids=>['0'],
                               }
                       },{
                        type=>'KernProc',
                        invert=>0,
                        args=>{
                               }
                      }
                      ]
                     );
    
    # hits on every proc but the idle proc
    %args=(
              checks=>[
                       {
                        type=>'Idle',
                        invert=>1,
                        args=>{
                               }
                       }
                      ]
                     );
    
    my $ppm;
    eval{
        $ppm=Proc::ProcessTable::Match->new( \%args );
    } or die "New failed with...".$@;
    
    my $pt = Proc::ProcessTable->new;
    foreach my $proc ( @{$t->table} ){
        if ( $ppm->match( $proc ) ){
            print Dumper( $proc );
        }
    }

=head1 METHODS

=head2 new

This ininitates the object.

One argument is taken and it is a hashref with the key "checks".
That value needs to contains a array of hashs of checks to run.

=head3 checks hash

Every check must hit for it to beconsidered a match.

Each of these should always be defined.

=head4 type

This is the module to use to use to run the check.

The name is relative 'Proc::ProcessTable::Match::', so
'PID' becomes 'Proc::ProcessTable::Match::PID'.

=head4 invert

This inverts inverts the returned value from the check.

=head4 args

This is a hash that will be pashed to the checker module's
new method.

For any required keys, check the documents for that checker.

If it does not take any arguments, just pass a blank hash.

    my %args=(
              checks=>[
                       {
                        type=>'PID',
                        invert=>0,
                        args=>{
                               pids=>['0'],
                               }
                       },{
                        type=>'KernProc',
                        invert=>0,
                        args=>{
                               }
                       }
                      ]
                     );
    
    my $ppm;
    eval{
        $ppm=Proc::ProcessTable::Match->new( \%args );
    } or die "New failed with...".$@;

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	# Provides some basic checks.
	# Could make these all one if, but this provides more
	# granularity for some one using it.
	if ( ! defined( $args{checks} )	){
		die ('No check key specified in the argument hash');
	}
	if ( ref( @{ $args{checks} } ) eq 'ARRAY' ){
		die ('The checks key is not a array');
	}
	# Will never match anything.
	if ( ! defined $args{checks}[0] ){
		die ('Nothing in the checks array');
	}
	if ( ref( %{ $args{checks}[0] } ) eq 'HASH' ){
		die ('The first item in the checks array is not a hash');
	}

    my $self = {
				checks=>[],
				};
    bless $self;

	# will hold the created check objects
	my @checks;

	# Loads up each check or dies if it fails to.
	my $check_int=0;
	while( defined( $args{checks}[$check_int] ) ){
		my %new_check=(
					   type=>undef,
					   args=>undef,
					   invert=>undef,
					   );

		# make sure we have a check type
		if ( defined($args{checks}[$check_int]{'type'}) ){
		   $new_check{type}=$args{checks}[$check_int]{'type'};
		}else{
			die('No type defined for check '.$check_int);
		}

		# does a quick check on the tpye name
		my $type_test=$new_check{type};
		$type_test=~s/[A-Za-z0-9]//g;
		$type_test=~s/\:\://g;
		if ( $type_test !~ /^$/ ){
			die 'The type "'.$new_check{type}.'" for check '.$check_int.' is not a valid check name';
		}

		# makes sure we have a args object and that it is a hash
		if (
			( defined($args{checks}[$check_int]{'args'}) ) &&
			( ref( $args{checks}[$check_int]{'args'} ) eq 'HASH' )
			){
		   $new_check{args}=$args{checks}[$check_int]{'args'};
		}else{
			die('No type defined for check '.$check_int.' or it is not a HASH');
		}

		# makes sure we have a args object and that it is a hash
		if (
			( defined($args{checks}[$check_int]{'invert'}) ) &&
			( ref( \$args{checks}[$check_int]{'invert'} ) ne 'SCALAR' )
			){
			die('Invert defined for check '.$check_int.' but it is not a SCALAR');
		}elsif(
			( defined($args{checks}[$check_int]{'invert'}) ) &&
			( ref( \$args{checks}[$check_int]{'invert'} ) eq 'SCALAR' )
			   ){
			$new_check{invert}=$args{checks}[$check_int]{'invert'};
		}

		my $check;
		my $eval_string='use Proc::ProcessTable::Match::'.$new_check{type}.';'.
		'$check=Proc::ProcessTable::Match::'.$new_check{type}.'->new( $new_check{args} );';
		eval( $eval_string );

		if (!defined( $check )){
			die 'Failed to init the check for '.$check_int.' as it returned undef... '.$@;
		}

		$new_check{check}=$check;

		push(@{ $self->{checks} }, \%new_check );

		$check_int++;
	}

	if ( $args{testing} ){
		$self->{testing}=1;
	}

	return $self;
}

=head2 match

Checks if a single Proc::ProcessTable::Process object matches the stack.

One object is argument is taken and that is the Net::Connection to check.

The return value is a boolean.

    if ( $ppm->match( $conn ) ){
        print "It matched.\n";
    }

=cut

sub match{
	my $self=$_[0];
	my $proc=$_[1];

	if (
		( ! defined( $proc ) ) ||
		( ref( $proc ) ne 'Proc::ProcessTable::Process' )
		){
		$self->{error}=2;
		$self->{errorString}='Either the connection is undefined or is not a Proc::ProcessTable::Process object';
		if ( ! $self->{testing} ){
			$self->warn;
		}
		return undef;
	}

	# Stores the number of hits
	my $hits=0;
	my $required=0;
	foreach my $check ( @{ $self->{checks} } ){
		my $hit;
		eval{
			$hit=$check->{check}->match($proc);
		};

		# If $hits is undef, then one of the checks errored and we skip processing the results.
		# Should only be 0 or 1.
		if ( defined( $hit ) ){
			# invert if needed
			if ( $check->{invert} ){
				$hit = $hit ^ 1;
			}

			# increment the hits count if we hit
			if ( $hit ){
				$hits++;
			}
		}

		$required++;
	}

	# if these are the same, then we have a match
	if ( $required eq $hits ){
		return 1;
	}

	# If we get here, it is not a match
	return 0;
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-proc-processtable-match at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Proc-ProcessTable-Match>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Proc::ProcessTable::Match


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Proc-ProcessTable-Match>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Proc-ProcessTable-Match>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Proc-ProcessTable-Match>

=item * Search CPAN

L<https://metacpan.org/release/Proc-ProcessTable-Match>

=item * Repository

L<https://gitea.eesdp.org/vvelox/Proc-ProcessTable-Match>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Proc::ProcessTable::Match
