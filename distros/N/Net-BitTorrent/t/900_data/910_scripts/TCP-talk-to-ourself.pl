#!perl -w
# $Id: TCP-talk-to-ourself.pl 64e98b0 2009-09-12 05:23:14Z sanko@cpan.org $
use strict;
use warnings;
require IO::Socket;
if (@ARGV >= 2 && $ARGV[0] eq q[--port]) {
    my $port = $ARGV[1];
    require Sys::Hostname;
    my $host = Sys::Hostname::hostname();
    if (my $socket =
        IO::Socket::INET->new(PeerAddr => qq[$host:$port],
                              Timeout  => 5)
        )
    {   require IO::Select;
        if (IO::Select->new($socket)->can_read(1)) {
            my ($n, $buf);
            if ($n = sysread($socket, $buf, 512)) {
                exit if $buf eq qq[Hi there!\n];
                die
                    qq[Seems to be talking to the wrong server at $host:$port, got "$buf"\n];
            }
            elsif (defined $n) {
                die qq[Immediate EOF from server at $host:$port\n];
            }
            else {
                die qq[Can't read from server at $host:$port: $!];
            }
        }
        die qq[No response from server at $host:$port\n];
    }
    die qq[Can't connect: $@\n];
}

# server code
my $socket = IO::Socket::INET->new(Listen => 1, Timeout => 5);
my $port = $socket->sockport;
open(CLIENT, qq("$^X" "$0" --port $port |)) || die qq[Can't run $^X $0: $!\n];
if (my $client = $socket->accept) {
    print $client qq[Hi there!\n];
    close($client) || die qq[Can't close socket: $!];
}
else {
    warn qq[Test server timeout\n];
}
exit if close(CLIENT);
die qq[Can't wait for client: $!] if $!;
die qq[The can-we-talk-to-ourself test failed.\n];

=head1 Notes

This was stolen from libwww-perl.

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

=for svn $Id: TCP-talk-to-ourself.pl 64e98b0 2009-09-12 05:23:14Z sanko@cpan.org $

=cut
