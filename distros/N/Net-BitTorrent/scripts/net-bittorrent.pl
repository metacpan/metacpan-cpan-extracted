#!perl -I../lib
use strict;
use warnings;
use Getopt::Long;
use Net::BitTorrent;
$|++;
my ($port, $int) = (0, 0);
GetOptions q[port:i] => \$port;
my @t = grep {-e} @ARGV;
@t || exit printf q[%s [-port \d] some.torrent [another.torrent ...]], $0;
my $bt = new Net::BitTorrent({LocalPort => $port})
    || die sprintf q[Failed to create N::B object (%s)], $^E;
$SIG{q[INT]} = sub {
    $int = $int + 3 > time ? exit : time;
    for ($bt, values %{$bt->torrents}) { printf qq[%s\n], $_->as_string(1) }
};
$bt->on_event(
    q[piece_hash_pass],
    sub {
        my $a = pop;
        my $t = $a->{q[Torrent]};
        my $h = grep {$_} split //, unpack q[b*], $t->bitfield;
        my $w = grep {$_} split //, unpack q[b*], $t->_wanted;
        printf qq[+%d: %04d|%s|%4d/%4d|% 3.2f%%\r],
            $t->save_resume_data, $a->{q[Index]}, $t->as_string(), $h,
            $t->piece_count, 100 - ($w / $t->piece_count * 100);
    }
);
$bt->on_event(q[file_write],
              sub { pop->{q[File]}->torrent->save_resume_data });
for my $_t (@t) {
    printf qq[Loading '%s'...\n], $_t;
    my $t = $bt->add_torrent({Path => $_t, Resume => $_t . q[.resume]})
        || warn sprintf q[Cannot load %s: %s], $_t, $^E && next;
    $t->hashcheck;
    $t->start;
}
$bt->do_one_loop(0.5) && sleep 1 while 1;

=pod

=head1 NAME

net-bittorrent - Painfully small example

=head1 Description

Kwalitee dictates I have at least one script in C</script/> or C</bin/>
or whatever so, here it is.

=head1 Synopsis

 net-bittorrent.pl file.torrent
   or
 net-bittorrent.pl -port \d some.torrent [another.torrent ...]

=head1 See Also

For better examples, see the files under the C</tatoeba/> directory;
specifically C</tatoeba/005-console.pl>.

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2009 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

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

=for SVN $Id: net-bittorrent.pl 862fd03 2009-02-17 22:11:17Z sanko@cpan.org $

=cut
