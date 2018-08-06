# Paranoid::Network::Socket -- Socket wrapper for seemless IPv6 support
#
# (c) 2005 - 2017, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Paranoid/Network/Socket.pm, 2.06 2018/08/05 01:21:48 acorliss Exp $
#
#    This software is licensed under the same terms as Perl, itself.
#    Please see http://dev.perl.org/licenses/ for more information.
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Paranoid::Network::Socket;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Socket qw(:all);

($VERSION) = ( q$Revision: 2.06 $ =~ /(\d+(?:\.\d+)+)/sm );

#####################################################################
#
# Module code follows
#
#####################################################################

our $ipv6_enabled;
our $socket6;

sub has_ipv6 {
    return $ipv6_enabled;
}

BEGIN {

    @EXPORT    = ( 'has_ipv6', @Socket::EXPORT );
    @EXPORT_OK = ( 'has_ipv6', @Socket::EXPORT_OK );
    %EXPORT_TAGS = (
        %Socket::EXPORT_TAGS,
        all => [ 'has_ipv6', @{ $Socket::EXPORT_TAGS{all} } ],
        );

    # Check to see if we've got any IPv6 functions available
    $socket6 = 0;
    $ipv6_enabled = ( defined *sockaddr_in6{CODE} ) ? 1 : 0;

    # Set inet_pton/inet_ntop to import by default -- don't know why
    # this isn't done in Socket at all...
    if ( grep { $_ eq 'inet_pton' } @EXPORT_OK ) {
        push @EXPORT, qw(inet_pton inet_ntop);
    }

    unless ($ipv6_enabled) {

        # Socket didn't provide it, let's see if Socket6 is available
        if ( eval 'require Socket6; 1;' ) {

            # Conditionally import Socket6 routines.  This is important
            # because perl 5.12 has partial IPv6 support, and 5.14 full.  I
            # want to avoid redefined and prototype mismatch warnings.
            for my $symbol (@Socket6::EXPORT) {
                unless ( grep /^$symbol$/s, @EXPORT, @EXPORT_OK ) {
                    import Socket6 $symbol;
                    push @EXPORT, $symbol;
                    push @{ $EXPORT_TAGS{all} }, $symbol;
                }
            }
            for my $symbol (@Socket6::EXPORT_OK) {
                unless ( grep /^$symbol$/s, @EXPORT, @EXPORT_OK ) {
                    import Socket6 $symbol;
                    push @EXPORT_OK, $symbol;
                    push @{ $EXPORT_TAGS{all} }, $symbol;
                }
            }
        }

        # Check one more time...
        $ipv6_enabled = ( defined *sockaddr_in6{CODE} ) ? 1 : 0;
        if ($ipv6_enabled) {
            $socket6 = *sockaddr_in{PACKAGE} eq 'Socket6' ? 1 : 0;
        }
    }
}

1;

__END__

=head1 NAME

Paranoid::Network::Socket - Socket wrapper for seemless IPv6 support

=head1 VERSION

$Id: lib/Paranoid/Network/Socket.pm, 2.06 2018/08/05 01:21:48 acorliss Exp $

=head1 SYNOPSIS

  # use Socket; # no longer needed
  use Paranoid::Network::Socket;
  use Paranoid::Network::Socket qw(:crlf);

  $ipv6_enabled = has_ipv6();

=head1 DESCRIPTION

This module is a wrapper for L<Socket(3)> and L<Socket6(3)>, and is meant to
be used in lieu of using those packages directly.  Doing so removes any of the
version dependent support issues on Perl and its bundled L<Socket(3)> where
IPv6 is concerned.

Starting in Perl 5.12 the beginnings of IPv6 support emerged in the bundled
L<Socket(3)> module, but full IPv6 support didn't arrive until 5.14.  Prior
versions of Perl required the use of the external L<Socket6(3)> module 
(available on CPAN).

With this module IPv6 support, if available, is brought in automatically at
runtime, regardless of where that support is provided.  It also makes a
default export of B<inet_pton> and B<inet_ntop>, something that L<Socket(3)>
only does on request.

Finally, this module provides a B<has_ipv6> function which will return whether
your Perl has full IPv6 support.  Full support is determined by the presence
of B<sockaddr_in6>.

All of the regular tag sets provided by either B<Socket> modules are supported
by this module.

=head1 SUBROUTINES/METHODS

=head2 has_ipv6

    $ipv6_enabled = has_ipv6();

Returns a boolean value denoting whether or not this module has full IPv6
support.

=head1 DEPENDENCIES

=over

=item o

L<Socket>

=item o

L<Socket6> (optional)

=back

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2005 - 2017, Arthur Corliss (corliss@digitalmages.com)

