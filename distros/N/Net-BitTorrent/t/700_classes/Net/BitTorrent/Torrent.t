#!/usr/bin/perl -w
use strict;
use warnings;
use Module::Build;
use Test::More;
use Digest::SHA qw[sha1_hex];
use File::Temp qw[tempdir tempfile];
use Scalar::Util qw[/weak/];
use File::Spec::Functions qw[rel2abs];
use Time::HiRes qw[];
use lib q[../../../../lib];
use Net::BitTorrent::Util qw[/code/];
use Net::BitTorrent::Torrent;
use Net::BitTorrent;
$|++;
my $credits_dot_txt = q[./t/900_data/950_torrents/credits.txt];
chdir q[../../../../] if not -f $credits_dot_txt;
my $test_builder = Test::More->builder;
my $build        = Module::Build->current;
my %torrents     = ();
_locate_torrents();
plan tests => int(6 + (90 * scalar keys %torrents));
my $okay_tcp        = $build->notes(q[okay_tcp]);
my $release_testing = $build->notes(q[release_testing]);
my $verbose         = $build->notes(q[verbose]);
my $threads         = $build->notes(q[threads]);
my $profile         = $build->notes(q[profile]);
$SIG{__WARN__} = (
    $verbose
    ? sub {
        diag(sprintf(q[%02.4f], Time::HiRes::time- $^T), q[ ], shift);
        }
    : sub { }
);
SKIP: {
    is(Net::BitTorrent::Torrent->new(), undef, q[new() returns undef]);
    is(Net::BitTorrent::Torrent->new(q[FAIL!]),
        undef, q[new('FAIL!') returns undef (requires hashref)]);
    is(Net::BitTorrent::Torrent->new({}), undef, q[new({}) returns undef]);
    is(Net::BitTorrent::Torrent->new({Path => q[]}),
        undef, q[new({Path => ''}) returns undef]);
    is(Net::BitTorrent::Torrent->new({Path => $credits_dot_txt}),
        undef, sprintf q[{ Path => '%s' } returns undef],
        $credits_dot_txt);
    is( Net::BitTorrent::Torrent->new({Path => q[./]}), undef,
        sprintf q[{ Path => '%s' } returns undef], q[./]);
    for my $_key (sort { $a cmp $b } keys %torrents) {
        my $dot_torrent = $torrents{$_key};
        warn sprintf q[Testing with '%s'], $dot_torrent;
        my ($tempdir)
            = tempdir(q[~NBSF_test_XXXXXXXX], CLEANUP => 1, TMPDIR => 1);
        warn(sprintf(q[File::Temp created '%s' for us to play with], $tempdir)
        );
        my $client = Net::BitTorrent->new({LocalHost => q[127.0.0.1]});
        skip(q[Failed to create client],
             (      $test_builder->{q[Expected_Tests]}
                  - $test_builder->{q[Curr_Test]}
             )
        ) if !$client;
        my $torrent =
            $client->add_torrent({Path    => $dot_torrent,
                                  BaseDir => $tempdir
                                 }
            );

        END {
            return if not defined $torrent;
            for my $file (@{$torrent->files}) { $file->_close() }
        }
        is($torrent->path, rel2abs($dot_torrent),
            q[Absolute paths returned from path()]);
        is_deeply($torrent->raw_data(1), _raw_data($_key),
                  sprintf q[Totally raw data for %s torrent looks good.],
                  $_key);
        is_deeply(scalar(bdecode($torrent->raw_data)),
                  _raw_data($_key),
                  sprintf q[bencoded raw data for %s torrent looks good.],
                  $_key
        );
        is( $torrent->infohash,
            _infohash($_key),
            sprintf q[Infohash checks out as %s (%s)],
            (join(q[ ... ], $torrent->infohash =~ m[^(.{4}).+(.{4})$])),
            $_key
        );
        is_deeply($torrent->trackers, [_trackers($_key)],
                  sprintf q[List of trackers (%s)], $_key);
        is($torrent->is_complete, 0, sprintf q[Download is incomplete (%s)],
            $_key);
        is($torrent->downloaded, 0,
            sprintf q[Nothing has been downloaded (%s)], $_key);
        is($torrent->uploaded, 0, sprintf q[Nothing has been uploaded (%s)],
            $_key);
        is($torrent->size, _size($_key), sprintf q[Full size is correct (%s)],
            $_key);
        is($torrent->_block_length, 16384,
            sprintf q[Block size is correct (%s)], $_key);
        is($torrent->private, 0, sprintf q[.torrent is not private (%s)],
            $_key);
        is( $torrent->bitfield,
            pack(q[b*],
                 qq[\0] x int(
                         length(
                             unpack(
                                 q[H*], _raw_data($_key)->{q[info]}{q[pieces]}
                             )
                             ) / 40
                 )
            ),
            sprintf q[Bitfield is correct (%s)],
            $_key
        );
        is($torrent->_client, $client, sprintf q[Client is correct (%s)],
            $_key);
        is($torrent->comment,
            _raw_data($_key)->{q[comment]},
            sprintf q[comment is correct (%s)], $_key);
        is($torrent->created_by,
            _raw_data($_key)->{q[created by]},
            sprintf q[created_by is correct (%s)], $_key);
        is($torrent->creation_date,
            _raw_data($_key)->{q[creation date]},
            sprintf q[creation_date is correct (%s)], $_key);
        is($torrent->name,
            _raw_data($_key)->{q[info]}{q[name]},
            sprintf q[name is correct (%s)], $_key);
        ok($torrent->status, sprintf q[Status indicates (%s )...], $_key);
        ok($torrent->status & 128,
            sprintf q[ ...%s torrent is attached to a client.], $_key);
        ok($torrent->status & 64,
            sprintf q[ ...%s torrent was loaded properly.], $_key);
        is( Net::BitTorrent::Torrent->new(
                                  {Path    => $dot_torrent,
                                   BaseDir => $tempdir,
                                   Client  => bless(\{}, q[Not::BitTorrent])
                                  }
            ),
            undef,
            sprintf q[Requires a blessed 'Client' object (2) (%s)],
            $_key
        );
        isa_ok(Net::BitTorrent::Torrent->new({Path    => $dot_torrent,
                                              BaseDir => $tempdir,
                                              Client  => $client
                                             }
               ),
               q[Net::BitTorrent::Torrent],
               sprintf q[Requires a blessed 'Client' object (3) (%s)],
               $_key
        );
        my $orphan_torrent = Net::BitTorrent::Torrent->new(
                {Path => $dot_torrent, BaseDir => $tempdir, Client => undef});
        isa_ok($orphan_torrent, q[Net::BitTorrent::Torrent],
               sprintf q[Works with an undef 'Client' parameter (%s)], $_key);
        isa_ok(Net::BitTorrent::Torrent->new(
                                   {Path => $dot_torrent, BaseDir => $tempdir}
               ),
               q[Net::BitTorrent::Torrent],
               sprintf q[Works without a 'Client' parameter too (%s)],
               $_key
        );
        is( Net::BitTorrent::Torrent->new({Path    => $dot_torrent,
                                           BaseDir => $tempdir,
                                           Client  => q[Test]
                                          }
            ),
            undef,
            sprintf q[Requires a blessed 'Client' object if defined (%s)],
            $_key
        );
        {
            warn sprintf q[Undocumented BlockLength parameter tests], $_key;
            my $_torrent_Test =
                Net::BitTorrent::Torrent->new({Path        => $dot_torrent,
                                               BaseDir     => $tempdir,
                                               BlockLength => q[Test]
                                              }
                );
            isa_ok($_torrent_Test, q[Net::BitTorrent::Torrent],
                   sprintf q[{ [...],  BlockLength => 'Test'} (%s)], $_key);
            is($_torrent_Test->_block_length,
                16384, sprintf q[ ...BlockLength == 16384 (default) (%s)],
                $_key);
            my $_torrent_4000000 =
                Net::BitTorrent::Torrent->new({Path        => $dot_torrent,
                                               BaseDir     => $tempdir,
                                               BlockLength => 4000000
                                              }
                );
            isa_ok($_torrent_4000000, q[Net::BitTorrent::Torrent],
                   sprintf q[{ [...],  BlockLength => 4000000} (%s)], $_key);
            is( $_torrent_4000000->_block_length,           4000000,
                sprintf q[ ...BlockLength == 4000000 (%s)], $_key);
        }
        {
            my %IS = qw[
                Started  1 Checking  2 StartAfterCheck  4 Checked   8
                Error   16 Paused   32 Loaded          64 Queued  128
            ];
            ok($orphan_torrent->status, sprintf q[Status indicates... (%s)],
                $_key);
            warn $orphan_torrent->status;
            is($orphan_torrent->status, $IS{q[Loaded]},
                sprintf q[ ...torrent is loaded but has no parent. (%s)],
                $_key);
            my $_torrent_Test =
                Net::BitTorrent::Torrent->new({Path    => $dot_torrent,
                                               BaseDir => $tempdir,
                                               Status  => q[Test],
                                               Client  => $client
                                              }
                );
            isa_ok($_torrent_Test, q[Net::BitTorrent::Torrent],
                   sprintf q[{ [...],  Status => 'Test'} (%s)], $_key);
            is( $_torrent_Test->status,
                ($IS{q[Started]} + $IS{q[Queued]} + $IS{q[Loaded]}),
                sprintf
                    q[ ...torrent is started (pending hashcheck) and loaded. (%s)],
                $_key
            );
            warn $_torrent_Test->status;
            ok($_torrent_Test->stop, sprintf q[Stop an active torrent (%s)],
                $_key);
            warn $_torrent_Test->status;
            ok($_torrent_Test->status ^ $IS{q[Started]},
                sprintf q[ ...Status says we're stopped. (%s)], $_key);
            ok($_torrent_Test->start, sprintf q[Start a stopped torrent (%s)],
                $_key);
            warn $_torrent_Test->status;
            ok($_torrent_Test->status & $IS{q[Started]},
                sprintf q[ ...Status says we're started. (%s)], $_key);
            ok($_torrent_Test->pause, sprintf q[Pause a torrent (%s)], $_key);
            warn $_torrent_Test->status;
            ok($_torrent_Test->pause & $IS{q[Paused]},
                sprintf q[ ...Status says we're paused. (%s)], $_key);
            ok($_torrent_Test->start, sprintf q[Start a paused torrent (%s)],
                $_key);
            warn $_torrent_Test->status;
            ok($_torrent_Test->status ^ $IS{q[Paused]},
                sprintf q[ ...Status says we're started. (%s)], $_key);
            my $_torrent_unchecked =
                Net::BitTorrent::Torrent->new(
                                         {Path    => $dot_torrent,
                                          BaseDir => $tempdir,
                                          Status  => $IS{q[StartAfterCheck]}
                                         }
                );
            isa_ok($_torrent_unchecked,
                   q[Net::BitTorrent::Torrent],
                   sprintf q[{ [...],  Status => %d} (%s)],
                   $IS{q[StartAfterCheck]},
                   $_key
            );
            is( $_torrent_unchecked->status,
                $IS{q[Loaded]} + $IS{q[StartAfterCheck]},
                sprintf
                    q[ ...Status == %d (Loaded, Start after Check, Orphan) (%s)],
                $IS{q[Loaded]} + $IS{q[StartAfterCheck]},
                $_key
            );
            ok($_torrent_unchecked->hashcheck,
                sprintf q[ ...checking (%s)], $_key);
            is( $_torrent_unchecked->status,
                $IS{q[Loaded]} + $IS{q[Checked]},
                sprintf q[ ...Status == %d (Loaded, Checked, Orphan) (%s)],
                $IS{q[Loaded]} + $IS{q[Checked]},
                $_key
            );
        }
        warn(q[TODO: Test BaseDir param]);
        is($torrent->downloaded, 0, sprintf q[    downloaded == 0 (%s)],
            $_key);
        is( $torrent->_add_downloaded(1024),       1024,
            sprintf q[_add_downloaded(1024) (%s)], $_key);
        is( $torrent->_add_downloaded(-1024),       1024,
            sprintf q[_add_downloaded(-1024) (%s)], $_key);
        is( $torrent->_add_downloaded(q[dude]),      1024,
            sprintf q[_add_downloaded('dude') (%s)], $_key);
        is($torrent->downloaded, 1024, sprintf q[    downloaded == 1024 (%s)],
            $_key);
        is($torrent->uploaded, 0, sprintf q[    uploaded == 0 (%s)], $_key);
        is( $torrent->_add_uploaded(1024),       1024,
            sprintf q[_add_uploaded(1024) (%s)], $_key);
        is( $torrent->_add_uploaded(-1024),       1024,
            sprintf q[_add_uploaded(-1024) (%s)], $_key);
        is( $torrent->_add_uploaded(q[dude]),      1024,
            sprintf q[_add_uploaded('dude') (%s)], $_key);
        is($torrent->uploaded, 1024, sprintf q[    uploaded == 1024 (%s)],
            $_key);
        my $torrent_with_files = Net::BitTorrent::Torrent->new(
                                {Path => $dot_torrent, BaseDir => $tempdir,});
        isa_ok($torrent_with_files, q[Net::BitTorrent::Torrent],
               sprintf q[Created new object to play with (%s)], $_key);
        my $_wanted = $torrent_with_files->_wanted;
        like(unpack(q[b*], $torrent_with_files->_wanted()), qr[^1+0*$],
             sprintf q[By default, we want everything (%s)], $_key);

        for my $file (@{$torrent_with_files->files()}) {
            $file->set_priority(0);
        }
        like(unpack(q[b*], $torrent_with_files->_wanted()), qr[^0+$],
             sprintf q[And now we want nothing (%s)], $_key);
        warn q[TODO: _piece_by_index  # returns undef];
        is($torrent->_piece_by_index(),
            undef, sprintf q[_piece_by_index( ) requires an index (%s)],
            $_key);
        is($torrent->_piece_by_index(q[Nine!]),
            undef, sprintf q[_piece_by_index('%s') is just plain wrong (%s)],
            q[Nine!], $_key);
        is($torrent->_piece_by_index(0),
            undef, sprintf q[_piece_by_index(%d) doesn't exist yet (%s)],
            0, $_key);
        is( $torrent->_piece_by_index($torrent->piece_count),
            undef,
            sprintf q[_piece_by_index(%d) doesn't exist yet (%s)],
            $torrent->piece_count,
            $_key
        );
        is( $torrent->_piece_by_index($torrent->piece_count + 1),
            undef,
            sprintf q[_piece_by_index(%d) will never exist (%s)],
            ($torrent->piece_count + 1),
            $_key
        );
        is($torrent->_piece_by_index(-1),
            undef, sprintf q[_piece_by_index(%d) will never exist (%s)],
            -1, $_key);
        is($orphan_torrent->_piece_by_index(0),
            undef,
            sprintf q[_piece_by_index(%d) orphans never have pieces (%s)],
            (0), $_key);
        my $_bitfield     = $torrent->bitfield();
        my $_new_bitfield = $_bitfield;
        vec($_new_bitfield, 0, 8) = 1;
        ok($torrent->_set_bitfield($_new_bitfield),
            sprintf q[Bitfield is being changed... (%s)], $_key);
        isn't($torrent->bitfield, $_bitfield,
              sprintf q[Bitfield is no longer default... (%s)], $_key);
        is($torrent->bitfield, $_new_bitfield,
            sprintf q[Bitfield has been faked. (%s)], $_key);
        is( $torrent->_set_bitfield(qq[\0] x 4),      undef,
            sprintf q[Bitfield is too short... (%s)], $_key);
        is($torrent->bitfield, $_new_bitfield,
            sprintf q[Bitfield has not changed. (%s)], $_key);
        ok($torrent->_set_status($torrent->status | 2),
            sprintf q[Set status | 2 (hashchecking).. (%s)], $_key);
        is( $torrent->_set_bitfield($_bitfield),
            undef,
            sprintf
                q[Bitfield is is proper size but ignored due to status... (%s)],
            $_key
        );
        is($torrent->bitfield, $_new_bitfield,
            sprintf q[Bitfield has not changed. (%s)], $_key);
        is($torrent->as_string(), $torrent->infohash,
            sprintf q[as_string( ) | simple (%s)], $_key);
        is($torrent->as_string(0),
            $torrent->infohash, sprintf q[as_string(0) | simple (%s)], $_key);
        isn't($torrent->as_string(1),
              $torrent->infohash, sprintf q[as_string(1) | advanced (%s)],
              $_key);
        sub TIEHANDLE { pass(q[Tied STDERR]); bless \{}, shift; }

        sub PRINT {
            is((caller(0))[0],
                q[Net::BitTorrent::Torrent], q[String written to STDERR]);
        }
        sub UNTIE { pass(q[Untied STDERR]); }
        tie(*STDERR, __PACKAGE__);
        $torrent->as_string();
        $torrent->as_string(1);
        untie *STDERR;
        ok(!$torrent->save_resume_data,
            sprintf q[save_resume_data() (%s)], $_key);
        my ($_fh, $_filename)
            = tempfile(q[NB_XXXX],
                       SUFFIX => q[.resume],
                       TMPDIR => 1,
                       UNLINK => 1
            );
        is( $torrent->resume_path(),
            undef,
            sprintf
                q[resume_path( ) (empty if not set in call to new()) (%s)],
            $_key
        );
        ok($torrent->save_resume_data($_filename),
            sprintf q[save_resume_data('%s') (%s)],
            $_filename, $_key);
        ok(-f $_filename,
            sprintf q[Resume data file was created... (%s)], $_key);
        ok(-s $_filename,
            sprintf q[               ...and has data. (%s)], $_key);
        warn q[TODO: Restore data];
    SKIP: {
            skip q[Multi-threaded tests have been skipped], 5 if !$threads;
            skip
                q[Multi-threaded tests have been skipped. (Devel::Cover is not thread safe)],
                5
                if defined $Devel::Cover::VERSION;
            skip
                q[Multi-threaded tests have been skipped. (Devel::NYTProf is not thread safe)],
                5
                if $profile;
            use_ok(q[threads]);
            use_ok(q[threads::shared]);
            my $_threaded_torrent = Net::BitTorrent::Torrent->new(
                                {Path => $dot_torrent, BaseDir => $tempdir,});
            ok($_threaded_torrent->_set_status(4),
                sprintf q[Parent sets status to 4 (%s)], $_key);
            my $_bitfield = $_threaded_torrent->bitfield();
            threads->create(
                sub {
                    warn q[Change contents of cached bitfield...];
                    vec($_bitfield, 0, 8) = 1;
                    $_threaded_torrent->_set_bitfield($_bitfield);
                    $_threaded_torrent->_set_status(0);
                    return 1;
                }
            )->join();
            isn't($_threaded_torrent->bitfield,
                  $_bitfield,
                  sprintf q[Parent sees bitfield has changed (%s)], $_key);
            is($_threaded_torrent->status, 0,
                sprintf q[Parent reads status is now 0 (%s)], $_key);
        }
    }
    warn q[TODO: Per-torrent callbacks];
}

sub _locate_torrents {
    %torrents = %{$build->_find_file_by_type(q[torrent],
                                             q[./t/900_data/950_torrents/])};
    $_ =~ s[.*[_/\\](.+)\.torrent$][$1] for values %torrents;
    return %torrents = reverse %torrents;
}

sub _trackers {
    my ($key) = @_;
    return (
        map {
            !@$_ ? [] : map {
                bless \$_->[0], q[Net::BitTorrent::Torrent::Tracker]
                } @$_
            } (_raw_data($key)->{q[announce-list]}
               ? _raw_data($key)->{q[announce-list]}
               : _raw_data($key)->{q[announce]}
               ? [[_raw_data($key)->{q[announce]}]]
               : ()
            )
    );
}

sub _size {
    my ($key) = @_;
    my $return = _raw_data($key)->{q[info]}{q[length]};
    $return
        || grep { $return += $_->{q[length]} }
        @{_raw_data($key)->{q[info]}{q[files]}};
    return $return;
}
my %_raw_data_cache;

sub _raw_data {
    my ($key) = @_;
    if (not $_raw_data_cache{$key}) {
        open(my $FH, q[<], $torrents{$key}) or return;
        sysread($FH, my $DATA, -s $FH) == -s $FH or return;
        $_raw_data_cache{$key} = scalar bdecode($DATA);
    }
    return $_raw_data_cache{$key};
}

sub _infohash {
    my ($key) = @_;
    return sha1_hex(bencode(_raw_data($key)->{q[info]}));
}
__END__
Copyright (C) 2008-2009 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it
under the terms of The Artistic License 2.0.  See the LICENSE file
included with this distribution or
http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered by
the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

$Id: Torrent.t d3c97de 2009-09-12 04:31:46Z sanko@cpan.org $
