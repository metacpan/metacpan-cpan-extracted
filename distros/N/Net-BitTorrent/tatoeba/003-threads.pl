#!perl -w -I../lib
use strict;
use warnings;
use Time::HiRes qw[sleep];
use threads;
use threads::shared;
use Net::BitTorrent;
my $client = Net::BitTorrent->new();
my $torrent = $client->add_torrent({Path => 'a.legal.torrent'}) or exit;
threads->create(
    sub {
        sleep 15;
        $torrent->on_event(q[piece_hash_pass], sub { warn q[Yay] });
        $torrent->on_event(q[piece_hash_fail], sub { warn q[Boo] });
        threads->yield();
        $torrent->hashcheck;
        threads->detach();
    }
);
sleep(0.25) and $client->do_one_loop(0.25) while !$torrent->is_complete;

=pod

=head1 NAME

003-threads.pl - Trivial Demonstration of a Multi-threaded Client

=head1 Description

This is a demonstration of C<Net::BitTorrent> can be used in a thre--
((sigh)) ya know, if you really want to try this, I can't stop you, but
don't bug me if mixing threads and C<Net::BitTorrent> turns your RAM into
dark matter or causes you to foam at the mouth.

=head1 Synopsis

 000-basic.pl

=head1 Lowdown

This section only makes sense when you view the source.

=over

=item Line 5-6

When L<Net::BitTorrent|Net::BitTorrent> sees that
L<threads::shared|threads::shared> has been used, it tries its best to
keep things organized.  There is a limited subset of data that's actually
shared between threads; just enough to be of some use but not enough to
let you ruin everything.

=item Line 10

Creates a new thread.  And this is where your sanity ends.

=item Line 12

Just a short delay to make it obvious that we're in the child.

=item Line 13-14

Sets callbacks to make it obvious that the data is being hashchecked.

=item Line 15

Steps aside for a moment.

=item Line 16

Validates data. As this starts,
connections to L<peers|Net::BitTorrent::Torrent/"peers ( )"> related to
this L<torrent|Net::BitTorrent::Torrent> in the parent thread are closed.
While the child does the checking, our
L<bitfield|Net::BitTorrent::Torrent/"bitfield ( )"> is kept in sync with
the parent (thanks to L<threads::shared|threads::shared>), and our
L<status|Net::BitTorrent::Torrent/"status ( )"> goes through some
changes.

=item Line 17

Child says goodbye now that (s)he is finished.

=item Line 20

Works until we're finished downloading everything.  C<Net::BitTorrent>
will continue to seed the torrent after download is complete.

=back

=head1 Bugs/Notes/Warnings

Unless someone sends me a few good patches (hint, hint) threads will
probably never be B<completely> supported by
L<Net::BitTorrent|Net::BitTorrent> but there are a few things you can do
with them.

Note: The data shared between threads is undocumented and subject to
change.

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

=for svn $Id: 003-threads.pl d3c97de 2009-09-12 04:31:46Z sanko@cpan.org $

=cut
