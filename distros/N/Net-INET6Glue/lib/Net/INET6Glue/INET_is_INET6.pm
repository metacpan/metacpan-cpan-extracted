use strict;
use warnings;
package Net::INET6Glue::INET_is_INET6;
our $VERSION = 0.6;

############################################################################
# copy IO::Socket::INET to IO::Socket::INET4
# copy IO::Socket::(IP|INET6) to IO::Socket::INET
############################################################################
use IO::Socket::INET;

our $INET6CLASS;
$INC{'IO/Socket/INET4.pm'} = $INC{'IO/Socket/INET.pm'};
if ( eval "require IO::Socket::IP" 
    && $IO::Socket::IP::VERSION >= 0.25 ) {
    $INC{'IO/Socket/INET.pm'}  = $INC{'IO/Socket/IP.pm'};
    $INET6CLASS = 'IO::Socket::IP';
} elsif ( eval "require IO::Socket::INET6"
    && $IO::Socket::INET6::VERSION >= 2.54 ) {
    $INC{'IO/Socket/INET.pm'}  = $INC{'IO/Socket/INET6.pm'};
    $INET6CLASS = 'IO::Socket::INET6';
} else {
    die "failed to load IO::Socket::IP or IO::Socket::INET6: $@"
}
    

{
    # copy subs
    no strict 'refs';
    no warnings 'redefine';
    for ( keys %{IO::Socket::INET::} ) {
	ref(my $v = $IO::Socket::INET::{$_}) and next;
	*{'IO::Socket::INET4::'.$_} = \&{ "IO::Socket::INET::$_" } if *{$v}{CODE};
    }

    for ( keys %{"$INET6CLASS\::"} ) {
	eval { *{${"$INET6CLASS\::"}{$_}} && *{${"$INET6CLASS\::"}{$_}}{CODE} } or next;
	*{'IO::Socket::INET::'.$_} = \&{ "$INET6CLASS\::$_" };
    }
}


1;

=head1 NAME

Net::INET6Glue::INET_is_INET6 - make L<IO::Socket::INET> behave like
L<IO::Socket::INET6>

=head1 SYNOPSIS

 use Net::INET6Glue::INET_is_INET6;
 use LWP::Simple;
 print get( 'http://[::1]:80' );
 print get( 'http://ipv6.google.com' );

=head1 DESCRIPTION

Many modules directly create L<IO::Socket::INET> sockets or have it as a
superclass. Because L<IO::Socket::INET> has no support for IPv6 these modules
don't have it either.

This module tries to make L<IO::Socket::INET> behave like L<IO::Socket::IP>
(with fallback to L<IO::Socket::INET6>) by copying the symbol table from
L<IO::Socket::IP> into L<IO::Socket::INET>.
The original symbol table from L<IO::Socket::INET> is still available in
L<IO::Socket::INET4>.

This strategy works for L<Net::SMTP>, L<LWP> and probably a lot of other modules
too, which don't try to depend too much on the innards of L<IO::Socket::INET> or
on the text representation of IP addresses (IPv6 addresses look different than
IPv4 addresses).

=head1 COPYRIGHT

This module is copyright (c) 2008..2014, Steffen Ullrich.
All Rights Reserved.
This module is free software. It may be used, redistributed and/or modified 
under the same terms as Perl itself.
