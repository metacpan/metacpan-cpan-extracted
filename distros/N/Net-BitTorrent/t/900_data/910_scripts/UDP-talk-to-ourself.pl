#!perl -w
# $Id: UDP-talk-to-ourself.pl 64e98b0 2009-09-12 05:23:14Z sanko@cpan.org $
# Stolen from IO
use strict;
use warnings;
use Socket;
use IO::Socket qw(AF_INET SOCK_DGRAM INADDR_ANY);

#
sub compare_addr {
    my ($a, $b) = @_;
    if (length($a) != length $b) {
        my $min = (length($a) < length $b) ? length($a) : length $b;
        if ($min and substr($a, 0, $min) eq substr($b, 0, $min)) {
            printf qq[# Apparently: %d bytes junk at the end of %s\n# %s\n],
                abs(length($a) - length($b)),
                $_[length($a) < length($b) ? 1 : 0],
                qq[consider decreasing bufsize of recfrom.];
            substr($a, $min) = "";
            substr($b, $min) = "";
        }
        return 0;
    }
    my @a = unpack_sockaddr_in($a);
    my @b = unpack_sockaddr_in($b);
    return qq[$a[0]$a[1]] eq qq[$b[0]$b[1]];
}
$|++;
my $udpa = IO::Socket::INET->new(Proto => q[udp], LocalAddr => q[localhost])
    || IO::Socket::INET->new(Proto => q[udp], LocalAddr => q[127.0.0.1])
    or die
    qq[$! (maybe your system does not have a localhost at all, q[localhost] or 127.0.0.1)];
my $udpb = IO::Socket::INET->new(Proto => q[udp], LocalAddr => q[localhost])
    || IO::Socket::INET->new(Proto => q[udp], LocalAddr => q[127.0.0.1])
    or die
    qq[$! (maybe your system does not have a localhost at all, q[localhost] or 127.0.0.1)];
$udpa->send(qq[ok 4], 0, $udpb->sockname);
die $^E
    unless compare_addr($udpa->peername, $udpb->sockname, q[peername],
                        q[sockname]);
my $rin = q[];
my ($where);
vec($rin, fileno($udpb), 1) = 1;

if (select($rin, undef, undef, 5)) {
    $where = $udpb->recv(my ($buf) = q[], 5);
    die sprintf q[UDPB recieved bad data: '%s'], $buf if $buf ne q[ok 4];
}
else {
    die q[UDPB timedout while waiting for data];
}
my @xtra = ();
unless (compare_addr($where, $udpa->sockname, q[recv name], q[sockname])) {
    die sprintf q[Addresses do not match?];
    @xtra = (0, $udpa->sockname);
}
$udpb->send(qq[ok 6], @xtra);
$rin = q[];    # reset
vec($rin, fileno($udpa), 1) = 1;
if (select($rin, undef, undef, 5)) {
    $udpa->recv(my ($buf) = q[], 5);
    die sprintf q[UDPA recieved bad data: '%s'], $buf if $buf ne q[ok 6];
    die sprintf q[UDPA dropped the 'connection': [%d] %s], $^E, %^E
        if $udpa->connected;
}
else {
    die q[UDPA timedout while waiting for data];
}
exit;

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2008-2009 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify
it under the terms of The Artistic License 2.0.  See the F<LICENSE>
file included with this distribution or
http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered
by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

Neither this module nor the L<Author|/Author> is affiliated with
BitTorrent, Inc.

=for svn $Id: UDP-talk-to-ourself.pl 64e98b0 2009-09-12 05:23:14Z sanko@cpan.org $

=cut
