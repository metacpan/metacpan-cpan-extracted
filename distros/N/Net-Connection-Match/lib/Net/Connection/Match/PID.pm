package Net::Connection::Match::PID;

use 5.006;
use strict;
use warnings;

=head1 NAME

Net::Connection::Match::PID - Check if the PID of a connection matches.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Net::Connection::Match::PID;
    use Net::Connection;
    
    my $connection_args={
                         foreign_host=>'10.0.0.1',
                         foreign_port=>'22',
                         local_host=>'10.0.0.2',
                         local_port=>'12322',
                         proto=>'tcp4',
                         state=>'ESTABLISHED',
                         pid=>0,
                        };
    
    my $conn=Net::Connection->new( $connection_args );
    
    my %args=(
              pids=>[
                     0,
                     '>1000',
                    ],
              );
    
    my $checker=Net::Connection::Match::PID->new( \%args );
    
    if ( $checker->match( $conn ) ){
        print "It matches.\n";
    }

=head1 METHODS

=head2 new

This intiates the object.

It takes a hash reference with one key. One key is required and
that is 'pids', which is a array of pids to match.

The PID values can be prefixed with the equalities below for doing
additional comparisons.

    <
    <=
    >
    >=

Atleast one PID must be specified.

If the new method fails, it dies.

    my %args=(
              pids=>[
                     0,
                     '>1000',
                    ],
              );
    
    my $checker=Net::Connection::Match::PID->new( \%args );

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	# run some basic checks to make sure we have the minimum stuff required to work
	if ( ! defined( $args{pids} ) ){
		die ('No pids key specified in the argument hash');
	}
	if ( ref( \$args{pids} ) eq 'ARRAY' ){
		die ('The pids key is not a array');
	}
	if ( ! defined $args{pids}[0] ){
		die ('Nothing defined in the pids array');
	}

    my $self = {
				pids=>$args{pids},
				};
    bless $self;

	return $self;
}

=head2 match

Checks if a single Net::Connection object matches the stack.

One argument is taken and that is a Net::Connection object.

The returned value is a boolean.

    if ( $checker->match( $conn ) ){
        print "The connection matches.\n";
    }

=cut

sub match{
	my $self=$_[0];
	my $object=$_[1];

	if ( !defined( $object ) ){
		return 0;
	}

	if ( ref( $object ) ne 'Net::Connection' ){
		return 0;
	}

	my $conn_pid=$object->pid;

	# don't bother proceeding, the object won't match ever
	# as it does not have a PID
	if ( ! defined( $conn_pid ) ){
		return 0;
	}

	# use while as foreach will reference the value
	my $pid_int=0;
	while (defined( $self->{pids}[$pid_int] )){
		my $pid=$self->{pids}[$pid_int];
		if (
			( $pid =~ /^[0-9]+$/ ) &&
			( $pid eq $conn_pid )
			){
			return 1;
		}elsif( $pid =~ /^\<\=[0-9]+$/ ){
			$pid=~s/^\<\=//;
			if ( $conn_pid <= $pid ){
				return 1;
			}
		}elsif( $pid =~ /^\<[0-9]+$/ ){
			$pid=~s/^\<//;
			if ( $conn_pid < $pid ){
				return 1;
			}
		}elsif( $pid =~ /^\>\=[0-9]+$/ ){
			$pid=~s/^\>\=//;
			if ( $conn_pid >= $pid ){
				return 1;
			}
		}elsif( $pid =~ /^\>[0-9]+$/ ){
			$pid=~s/^\>//;
			if ( $conn_pid > $pid ){
				return 1;
			}
		}
		$pid_int++;
	}

	return 0;
}

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
