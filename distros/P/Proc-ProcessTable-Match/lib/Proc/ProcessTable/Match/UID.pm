package Proc::ProcessTable::Match::UID;

use 5.006;
use strict;
use warnings;
use User::pwent;

=head1 NAME

Proc::ProcessTable::Match::UID - Check if the UID or username of a process matches.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Proc::ProcessTable::Match::UID;
    
    my %args=(
              uids=>[
                     0,
                     '>1000',
                     '!foo',
                     'www'
                    ],
              );
    
    my $checker=Proc::ProcessTable::Match::UID->new( \%args );
    
    if ( $checker->match( $proc ) ){
        print "It matches.\n";
    }

=head1 METHODS

=head2 new

This intiates the object.

It takes a hash reference with one key. One key is required and
that is 'uids', which is a array of UIDs or usernames to match.

The values can be prefixed with the equalities below for doing
additional comparisons.

    <
    <=
    >
    >=
    !

If a username is specified, only ! is valid. Otherwise the rest will
result in a unresolved or misresolved username to UID.

Atleast one value must be specified.

If the new method fails, it dies.

    my %args=(
              uids=>[
                     0,
                     '>1000',
                     '!foo',
                     'www'
                    ],
              );
    
    my $checker=Proc::ProcessTable::Match::UID->new( \%args );

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	# run some basic checks to make sure we have the minimum stuff required to work
	if ( ! defined( $args{uids} ) ){
		die ('No uids key specified in the argument hash');
	}
	if ( ref( \$args{uids} ) eq 'ARRAY' ){
		die ('The uids key is not a array');
	}
	if ( ! defined $args{uids}[0] ){
		die ('Nothing defined in the uids array');
	}

    my $self = {
				uids=>$args{uids},
				};
    bless $self;

	return $self;
}

=head2 match

Checks if a single Proc::ProcessTable::Process object matches the stack.

One argument is taken and that is a Proc::ProcessTable::Process object.

The returned value is a boolean.

    if ( $checker->match( $proc ) ){
        print "The process matches.\n";
    }

=cut

sub match{
	my $self=$_[0];
	my $object=$_[1];

	if ( !defined( $object ) ){
		return 0;
	}

	if ( ref( $object ) ne 'Proc::ProcessTable::Process' ){
		return 0;
	}

	my $proc_uid;
	eval{
		$proc_uid=$object->uid;
	};

	# don't bother proceeding, the object won't match ever
	# as it does not have a UID
	if ( ! defined( $proc_uid ) ){
		return 0;
	}

	# use while as foreach will reference the value
	my $uid_int=0;
	while (defined( $self->{uids}[$uid_int] )){
		my $uid=$self->{uids}[$uid_int];
		if (
			( $uid =~ /^[0-9]+$/ ) &&
			( $uid eq $proc_uid )
			){
			return 1;
		}elsif(
			   ( $uid =~ /[A-Za-z]/ ) &&
			   ( $uid !~ /^\!/ )
			   ){
			my $pw=getpwnam($uid);
			if ( defined( $pw ) ){
				if ( $pw->uid eq $proc_uid ){
					return 1;
				}
			}
		}elsif(
			   ( $uid =~ /[A-Za-z]/ ) &&
			   ( $uid =~ /^\!/ )
			   ){
			$uid =~ s/^\!//;
			my $pw=getpwnam($uid);
			if ( defined( $pw ) ){
				if ( $pw->uid ne $proc_uid ){
					return 1;
				}
			}
		}elsif( $uid =~ /^\<\=[0-9]+$/ ){
			$uid=~s/^\<\=//;
			if ( $proc_uid <= $uid ){
				return 1;
			}
		}elsif( $uid =~ /^\<[0-9]+$/ ){
			$uid=~s/^\<//;
			if ( $proc_uid < $uid ){
				return 1;
			}
		}elsif( $uid =~ /^\>\=[0-9]+$/ ){
			$uid=~s/^\>\=//;
			if ( $proc_uid >= $uid ){
				return 1;
			}
		}elsif( $uid =~ /^\>[0-9]+$/ ){
			$uid=~s/^\>//;
			if ( $proc_uid > $uid ){
				return 1;
			}
		}elsif( $uid =~ /^\![0-9]+$/ ){
			$uid=~s/^\!//;
			if ( $proc_uid ne $uid ){
				return 1;
			}
		}
		$uid_int++;
	}

	return 0;
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Proc-ProcessTable-Match at rt.cpan.org>, or through
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

1; # End of Proc::ProcessTable::Match
