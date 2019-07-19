package Net::Connection::Match;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';

=head1 NAME

Net::Connection::Match - Runs a stack of checks to match Net::Connection objects.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Net::Connection::Match;
    use Net::Connection;
    
    my $connection_args={
                         foreign_host=>'10.0.0.1',
                         foreign_port=>'22',
                         local_host=>'10.0.0.2',
                         local_port=>'12322',
                         proto=>'tcp4',
                         state=>'LISTEN',
                        };
    my $conn=Net::Connection->new( $connection_args );
    
    my %args=(
              checks=>[
                       {
                        type=>'Ports',
                        invert=>0,
                        args=>{
                               ports=>[
                                       '22',
                                      ],
                               lports=>[
                                        '53',
                                       ],
                               fports=>[
                                        '12345',
                                       ],
                        }
                       },
                       {
                        type=>'Protos',
                        invert=>0,
                        args=>{
                               protos=>[
                                        'tcp4',
                                       ],
                        }
                       }
                      ]
             );
    
    my $checker;
    eval{
        $checker=Net::Connection::Match->new( \%args );
    } or die "New failed with...".$@;
    
    if ( $check->match( $conn ) ){
        print "It matched!\n";
    }

=head1 METHODS

=head2 new

This initializes a new check object.

It takes one value and thht is a hash ref with the key checks.
This is a array of hashes.

If new fails, it will die.

=head3 checks hash keys

=head4 type

This is the name of the check relative to 'Net::Connection::Match::'.

So 'Net::Connection::Match::PTR' would become 'PTR'.

=head4 args

This is a hash or args to pash to the check. These are passed to the new
method of the check module.

=head4 invert

This is either boolean on if the check should be inverted or not.

    my $mce;
    eval{
        $ncm=Net::Connection::Match->new( $args );
    };

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
				perror=>undef,
				error=>undef,
				errorString=>"",
				testing=>0,
				errorExtra=>{
							 flags=>{
									 1=>'failedCheckInit',
									 2=>'notNCobj',
									 }
							 },
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
		my $eval_string='use Net::Connection::Match::'.$new_check{type}.';'.
		'$check=Net::Connection::Match::'.$new_check{type}.'->new( $new_check{args} );';
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

Checks if a single Net::Connection object matches the stack.

One object is argument is taken and that is the Net::Connection to check.

The return value is a boolean.

    if ( $ncm->match( $conn ) ){
        print "It matched.\n";
    }

=cut

sub match{
	my $self=$_[0];
	my $conn=$_[1];

	if( ! $self->errorblank ){
		return undef;
	}

	if (
		( ! defined( $conn ) ) ||
		( ref( $conn ) ne 'Net::Connection' )
		){
		$self->{error}=2;
		$self->{errorString}='Either the connection is undefined or is not a Net::Connection object';
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
			$hit=$check->{check}->match($conn);
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

=head1 ERROR HANDLING / FLAGS

Error handling is provided by L<Error::Helper>.

=head2 2 / notNCobj

Not a Net::Connection object. Either is is not defined
or what is being passed is not a Net::Connection object.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-connection-match at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Connection-Match>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Connection::Match


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Connection-Match>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Connection-Match>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-Connection-Match>

=item * Search CPAN

L<https://metacpan.org/release/Net-Connection-Match>

=item * Git Repo

L<https://gitea.eesdp.org/vvelox/Net-Connection-Match>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Net::Connection::Match
