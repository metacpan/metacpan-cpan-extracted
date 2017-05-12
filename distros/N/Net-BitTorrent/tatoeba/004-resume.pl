#!perl -w -I../lib
use strict;
use warnings;
use Time::HiRes qw[sleep];
use Net::BitTorrent;
my $client = Net::BitTorrent->new();
my $torrent
    = $client->add_torrent({Path => 'a.legal.torrent', Resume => '.resume'})
    or exit;
$torrent->on_event(q[piece_hash_pass], sub { save(shift) });

END {
    for my $t (values %{$client->torrents || {}}) { save($t); }
}
$torrent->hashcheck;
sleep(0.25) and $client->do_one_loop(0.25) while !$torrent->is_complete;

sub save {
    my ($torrent) = @_;
    rename $torrent->resume_path, $torrent->resume_path . q[.bak]
        if !-f $torrent->resume_path . q[.bak];
    $torrent->save_resume_data;
    warn q[---------- ] x 3;
    for my $file (@{$torrent->files}) {
        warn sprintf q[%s is %3.2f%% complete], $file->path,
            _percent_complete($file);
    }
}

sub _percent_complete {
    my ($self) = @_;
    my $start = 0;
    for my $index (0 .. $self->index - 1) {
        $start += $self->torrent->files->[$index]->size;
    }
    my $end = $start + $self->size;
    my $piece_length
        = $self->torrent->raw_data(1)->{q[info]}{q[piece length]};
    my $have      = 0;
    my $_bitfield = $self->torrent->bitfield;
    $start = int($start / $piece_length);
    $end   = int(($end / $piece_length) + 1);
    for my $index ($start .. $end) { $have += vec($_bitfield, $index, 1); }
    my $return = ($have / ($end - $start) * 100)
        ;    # may be > 100 because pieces and file boundries overlap
    return $return > 100 ? 100 : $return;
}

=pod

=head1 NAME

004-resume.pl - Demonstration of Net::BitTorrent::Torrent's Resume System

=head1 Description

This is a basic example of how the Resume System built into
L<Net::BitTorrent::Torrent|Net::BitTorrent::Torrent> is to be used.

=head1 Synopsis

 004-resume.pl

=head1 Lowdown

This section only makes sense when you view the source.

=over

=item Line 7

Loads our .torrent file and sets the filename for the related resume
data.

=item Line 10

Sets a per-torrent callback which, when triggered, saves our resume data.

=item Line 12-14

Here, at the end of the process, we store resume data for every torrent
in the client.  Yes, yes, I know... this little script only loads a
single torrent.  Consider it a bonus for folks writing your own your own
clients.  A small and obvious bonus, sure, but a bonus all the same.

This is probably the most important place to save resume data because on
restore, the last modified times of each file is compared with the times
stored in the resume data.  If any of them fail to match, all of the
resume data is considered invalid.

=item Line 20

Let's keep a backup of the
L<original metadata file|Net::BitTorrent::Torrent/"resume_path ( )"> just
in case L<Net::BitTorrent::Torrent|Net::BitTorrent::Torrent> makes a
mistake and ruins everything.

=item Line 22

Writes the new
L<resume data|Net::BitTorrent::Torrent/"save_resume_data ( [ PATH ] )">
to the file.  Now, the next time
L<Net::BitTorrent::Torrent|Net::BitTorrent::Torrent/"new ( { [ARGS] } )">
loads this file, it will see the resume data and if it looks okay, your
progress will be restored.

=back

=head1 Notes

In this script, we store resume data after each piece validates and at
the end of the script.  In practice, you may want to store this on a more
regular basis or on a schedule (every half hour).  I B<do not> suggest
saving resume data every time a block is written to disk; true, this
would keep resume data as up to date as possible, but there are certain
internal steps taken while resume data is gathered that would, in the
long run, slow everything down to a crawl.  For more, see
L<C<save_resume_data ( )>|Net::BitTorrent::Torrent/"save_resume_data ( [ PATH ] )"> in
L<Net::BitTorrent::Torrent|Net::BitTorrent::Torrent> and the sections
L<'Resume API'|Net::BitTorrent::Notes/"Resume API"> and
L<'How do I quick Resume a .torrent Session Between Client Sessions?'|Net::BitTorrent::Notes/"Quick Resume a .torrent Session Between Client Sessions">
in L<Net::BitTorrent::Notes|Net::BitTorrent::Notes>.

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

=for svn $Id: 004-resume.pl d3c97de 2009-09-12 04:31:46Z sanko@cpan.org $

=cut
