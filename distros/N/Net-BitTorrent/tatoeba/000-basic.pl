#!perl -w -I../lib
use strict;
use warnings;
use Net::BitTorrent;
my $client = Net::BitTorrent->new();
my $torrent = $client->add_torrent({Path => 'a.legal.torrent'}) or exit;
$client->do_one_loop while 1;

=pod

=head1 NAME

000-basic.pl - Bare minimum example BitTorrent client

=head1 Description

This is the least amount of code needed to create a full
C<Net::BitTorrent>-based client.

=head1 Synopsis

 000-basic.pl

=head1 Lowdown

This section only makes sense when you view the source.

=over

=item Line 5

Creates a new C<Net::BitTorrent> object.  Lets OS pick a random port and
opens sockets (TCP and UDP) on all available hosts.

=item Line 6

Attempts to create a new C<Net::BitTorrent::Torrent> object.  Defaults to
current working directory for storage.

If there's a problem loading the .torrent, an error will (probably) be
C<Carp>ed by C<Net::BitTorrent::Torrent>.

=item Line 7

Works forever.  C<Net::BitTorrent> will continue to seed the torrent
after download is complete.

=back

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

=for svn $Id: 000-basic.pl d3c97de 2009-09-12 04:31:46Z sanko@cpan.org $

=cut
