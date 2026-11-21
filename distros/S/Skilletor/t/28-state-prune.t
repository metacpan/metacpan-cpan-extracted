#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( write_json );

use Path::Tiny qw( path tempdir );
use Skilletor::JSON qw( js_ordered js_parse js_stringify );
use Skilletor::State;

# k254: sources-read.json is keyed by lock path, and every scope a sync ever saw left its key –
# gone worktrees, fixtures under /tmp, the relative keys a relative --project-dir made. A put drops
# the keys of scopes that are gone: a key that is no absolute path, or whose lock's directory (the
# scope's .claude) no longer exists. The scope written stays, even before its lock does; a scope
# whose .claude exists keeps its record without a lock (a sync that installed nothing leaves none,
# and that record is what `check` compares its sources with, k80). As the reference's state.ts.

sub read_of {
  my ( $version ) = @_;
  return js_ordered( s => js_ordered( kind => 'git', address => 'https://example.invalid/s.git', version => $version ) );
}

sub file_of { js_stringify( $_[0], 2 )."\n" }

subtest 'a put drops gone scopes and relative keys, keeps the live ones byte for byte' => sub {
  my $tmp     = tempdir;
  my $root    = path( $tmp, 'state' );
  my $live    = "$tmp/live/.claude/skilletor.lock.json";
  my $bare    = "$tmp/bare/.claude/skilletor.lock.json";    # its .claude, no lock
  my $gone    = "$tmp/gone/.claude/skilletor.lock.json";
  my $written = "$tmp/new/.claude/skilletor.lock.json";     # nothing on disk yet
  path($live)->parent->mkpath;
  path($live)->spew_raw("{}\n");
  path($bare)->parent->mkpath;
  # A live record as another writer left it: fields in another order, one no version knows.
  my $live_record = js_ordered( s => js_ordered( version => 'git:1', address => 'https://example.invalid/s.git', kind => 'git', extra => [1] ) );
  write_json( $root->child('sources-read.json'), js_ordered(
    $gone => read_of('git:0'), '.claude/skilletor.lock.json' => read_of('git:0'), $live => $live_record, $bare => read_of('git:2'),
  ) );

  Skilletor::State->new( root => "$root" )->put_sources_read( $written, read_of('git:3') );
  is( $root->child('sources-read.json')->slurp_utf8,
    file_of( js_ordered( $live => $live_record, $bare => read_of('git:2'), $written => read_of('git:3') ) ),
    'the live scopes and the one written stay, in their order; the rest is gone' );
};

subtest 'a put that changes no record still drops gone scopes; with none to drop it writes nothing' => sub {
  my $tmp  = tempdir;
  my $root = path( $tmp, 'state' );
  my $live = "$tmp/live/.claude/skilletor.lock.json";
  my $gone = "$tmp/gone/.claude/skilletor.lock.json";
  path($live)->parent->mkpath;
  path($live)->spew_raw("{}\n");
  my $file = write_json( $root->child('sources-read.json'), js_stringify( js_ordered( $gone => read_of('git:0'), $live => read_of('git:1') ) ) );
  my $state = Skilletor::State->new( root => "$root" );
  $state->put_sources_read( $live, read_of('git:1') );
  is( $file->slurp_utf8, file_of( js_ordered( $live => read_of('git:1') ) ), 'the gone scope dropped' );
  my $compact = js_stringify( js_ordered( $live => read_of('git:1') ) );    # as no put writes it: a rewrite would show
  $file->spew_raw($compact);
  $state->put_sources_read( $live, read_of('git:1') );
  is( $file->slurp_utf8, $compact, 'nothing to drop, nothing changed: not written' );
};

# k255: unreached.json and render-inputs.json are keyed by lock path too and written in the same
# sync step; their puts drop the same keys as put_sources_read's. As the reference's state.test.ts.

subtest 'unreached and render-inputs puts drop gone scopes and relative keys, keep the live ones byte for byte' => sub {
  my $tmp     = tempdir;
  my $root    = path( $tmp, 'state' );
  my $live    = "$tmp/live/.claude/skilletor.lock.json";
  my $bare    = "$tmp/bare/.claude/skilletor.lock.json";    # its .claude, no lock
  my $gone    = "$tmp/gone/.claude/skilletor.lock.json";
  my $written = "$tmp/new/.claude/skilletor.lock.json";     # nothing on disk yet
  my $rel     = '.claude/skilletor.lock.json';
  path($live)->parent->mkpath;
  path($live)->spew_raw("{}\n");
  path($bare)->parent->mkpath;
  # Live records as another writer left them: an id list unsorted, a value no version writes.
  write_json( $root->child('unreached.json'), js_ordered(
    $gone => ['missing:skills/a@s'], $rel => ['missing:skills/b@s'], $live => [ 'z', 'a' ], $bare => js_ordered( odd => 1 ),
  ) );
  write_json( $root->child('render-inputs.json'), js_ordered( $gone => 'sha256:0', $rel => 'sha256:0', $live => 'sha256:1', $bare => 7 ) );

  my $state = Skilletor::State->new( root => "$root" );
  $state->put_unreached( $written, ['missing:skills/c@s'] );
  $state->put_render_inputs( $written, 'sha256:3' );
  is( $root->child('unreached.json')->slurp_utf8,
    file_of( js_ordered( $live => [ 'z', 'a' ], $bare => js_ordered( odd => 1 ), $written => ['missing:skills/c@s'] ) ),
    'unreached.json: the live scopes and the one written stay, in their order; the rest is gone' );
  is( $root->child('render-inputs.json')->slurp_utf8, file_of( js_ordered( $live => 'sha256:1', $bare => 7, $written => 'sha256:3' ) ),
    'render-inputs.json: the same' );
};

subtest 'an unreached or render-inputs put that changes no record still drops gone scopes; with none to drop it writes nothing' => sub {
  my $tmp   = tempdir;
  my $root  = path( $tmp, 'state' );
  my $live  = "$tmp/live/.claude/skilletor.lock.json";
  my $gone  = "$tmp/gone/.claude/skilletor.lock.json";
  my $empty = "$tmp/empty/.claude/skilletor.lock.json";    # records nothing
  path($live)->parent->mkpath;
  path($empty)->parent->mkpath;
  my $unreached = write_json( $root->child('unreached.json'), js_stringify( js_ordered( $gone => ['x'], $live => ['y'] ) ) );
  my $inputs = write_json( $root->child('render-inputs.json'), js_stringify( js_ordered( $gone => 'sha256:0', $live => 'sha256:1' ) ) );
  my $state = Skilletor::State->new( root => "$root" );
  $state->put_unreached( $empty, [] );    # drops a record it does not have
  $state->put_render_inputs( $empty, undef );
  is( $unreached->slurp_utf8, file_of( js_ordered( $live => ['y'] ) ),        'unreached.json: the gone scope dropped' );
  is( $inputs->slurp_utf8,    file_of( js_ordered( $live => 'sha256:1' ) ), 'render-inputs.json: the gone scope dropped' );
  my @compact = ( js_stringify( js_ordered( $live => ['y'] ) ), js_stringify( js_ordered( $live => 'sha256:1' ) ) );    # as no put writes them
  $unreached->spew_raw( $compact[0] );
  $inputs->spew_raw( $compact[1] );
  $state->put_unreached( $live, ['y'] );
  $state->put_render_inputs( $live, 'sha256:1' );
  $state->put_unreached( $empty, [] );
  $state->put_render_inputs( $empty, undef );
  is_deeply( [ $unreached->slurp_utf8, $inputs->slurp_utf8 ], \@compact, 'nothing to drop, nothing changed: not written' );
};

# k255: last-check.json is keyed by project dir – the session's project, the checkout a move
# answered for – not by lock path. A mark drops the marks of every other key that is no absolute
# path or whose directory itself no longer exists; a project without .claude (a session where
# skilletor is not used) is live and keeps its mark. The key marked stays, gone or not. Only a mark
# prunes: it writes the file anyway; is_due reads, and clear_checked follows a mark.

subtest 'mark_checked drops the marks of gone project dirs and relative keys, keeps the live ones in order' => sub {
  my $tmp         = tempdir;
  my $root        = path( $tmp, 'state' );
  my $live        = "$tmp/live";
  my $plain       = "$tmp/plain";           # a project dir without .claude
  my $gone        = "$tmp/gone";
  my $gone_parent = "$tmp/gone-too/proj";
  my $marked      = "$tmp/removed";         # marked though gone: a session in a removed dir
  path( $live, '.claude' )->mkpath;
  path($plain)->mkpath;
  my $seeded = file_of( js_ordered( $gone => 1, $live => 2, proj => 3, '' => 4, $plain => 5, $gone_parent => 6 ) );
  my $file = write_json( $root->child('last-check.json'), $seeded );

  my $state = Skilletor::State->new( root => "$root" );
  ok( $state->is_due( $gone, 600 ), 'a gone key is due' );
  is( $file->slurp_utf8, $seeded, 'is_due writes nothing' );
  $state->clear_checked($marked);
  is( $file->slurp_utf8, $seeded, 'clear_checked of a key not marked writes nothing' );
  $state->mark_checked($marked);
  my $after = js_parse( $file->slurp_utf8 );
  is_deeply( [ keys %$after ], [ $live, $plain, $marked ], 'the live marks and the one marked stay, in their order' );
  is_deeply( [ @$after{ $live, $plain } ], [ 2, 5 ], 'the live marks as they were' );
  ok( !$state->is_due( $marked, 600 ), 'marked' );
};

done_testing;
