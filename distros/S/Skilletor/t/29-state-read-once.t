#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( write_json );

use Cwd ();
use Path::Tiny qw( path tempdir );
use Skilletor::Hooks qw( run_hook );
use Skilletor::JSON qw( js_ordered js_stringify );
use Skilletor::State;

delete $ENV{CLAUDE_CONFIG_DIR};

# k250: a session start read sources-read.json six times – its check once per scope, its sync
# twice per scope – and Perl took a quarter of a second for each parse of a 300 KB file. A
# read_once state parses each file once and drops a file from what it read when it writes it, and
# with_lock starts and ends with nothing read: so a check reads each file once, and so does the
# holder of the sync lock, the one writer of the records a sync keeps. The check runs outside the
# lock, so the sync reads once more: another session's sync may have written in between. As the
# reference's state.test.ts and hooks.test.ts.

# The state files read from disk under $root while $code runs, by name: every slurp through
# Path::Tiny, which read_text takes – a missing file counts too.
sub reads_of {
  my ( $root, $code ) = @_;
  my %reads;
  my $orig = \&Path::Tiny::slurp_raw;
  no warnings 'redefine';
  local *Path::Tiny::slurp_raw = sub {
    $reads{ $_[0]->basename }++ if $_[0]->parent->stringify eq $root;
    goto &$orig;
  };
  $code->();
  return \%reads;
}

sub read_of {
  my ( $version ) = @_;
  return js_ordered( s => js_ordered( kind => 'git', address => 'https://example.invalid/s.git', version => $version ) );
}

# Two live scopes' records, as a sync keeps them.
sub scopes {
  my ( $tmp ) = @_;
  my @keys = map { my $k = "$tmp/$_/.claude/skilletor.lock.json"; path($k)->parent->mkpath; $k } qw( a b );
  return @keys;
}

subtest 'a read_once state parses each file once; a plain state every time' => sub {
  my $tmp  = Cwd::realpath( "".tempdir );
  my $root = "$tmp/state";
  my ( $one, $two ) = scopes($tmp);
  write_json( "$root/sources-read.json", js_ordered( $one => read_of('git:1'), $two => read_of('git:2') ) );
  my ( %plain, %once );
  my $reads = reads_of( $root, sub {
    my $state = Skilletor::State->new( root => $root );
    $plain{$_} = $state->sources_read($_)->{s}{version} for $one, $two;
  } );
  is( $reads->{'sources-read.json'}, 2, 'plain: one read per call' );
  $reads = reads_of( $root, sub {
    my $state = Skilletor::State->new( root => $root, read_once => 1 );
    $once{$_} = $state->sources_read($_)->{s}{version} for $one, $two;
    $state->unreached($_) for $one, $two;    # a missing file is read once too
  } );
  is( $reads->{'sources-read.json'}, 1, 'read_once: one read for both scopes' );
  is( $reads->{'unreached.json'}, 1, 'read_once: a missing file once as well' );
  is_deeply( \%once, \%plain, 'both read the same records' );
  is_deeply( \%once, { $one => 'git:1', $two => 'git:2' }, 'which are the file\'s' );
};

subtest 'a write drops the file from the view: the next read parses what was written, the bytes are a plain state\'s' => sub {
  my $tmp = Cwd::realpath( "".tempdir );
  my ( $one, $two ) = scopes($tmp);
  my %bytes;
  for my $once ( 0, 1 ) {
    my $root = "$tmp/state-$once";
    write_json( "$root/sources-read.json", js_ordered( $one => read_of('git:1'), $two => read_of('git:2') ) );
    my $state = Skilletor::State->new( root => $root, read_once => $once );
    my $after;
    my $reads = reads_of( $root, sub {
      $state->sources_read($one);
      $state->put_sources_read( $one, read_of('git:3') );
      $state->put_render_inputs( $one, 'sha256:1' );
      $state->put_unreached( $one, ['missing:skills/x@s'] );
      $after = $state->sources_read($one)->{s}{version};
      $state->sources_read($two);
    } );
    is( $after, 'git:3', "read_once=$once: the read after the put is what was written" );
    if ($once) {
      is( $reads->{'sources-read.json'}, 2, 'read_once: once before the put, once after it' );
    }
    $bytes{$once} = { map { ( $_ => path("$root/$_")->slurp_raw ) } qw( sources-read.json render-inputs.json unreached.json ) };
  }
  is_deeply( $bytes{1}, $bytes{0}, 'a read_once state writes the bytes a plain one writes' );
};

subtest 'with_lock reads afresh: what another run wrote before the lock or after it is seen' => sub {
  my $tmp  = Cwd::realpath( "".tempdir );
  my $root = "$tmp/state";
  my ( $one ) = scopes($tmp);
  my $other = Skilletor::State->new( root => $root );    # another run
  $other->put_sources_read( $one, read_of('git:1') );
  my $state = Skilletor::State->new( root => $root, read_once => 1 );
  my @seen;
  my $reads = reads_of( $root, sub {
    push @seen, $state->sources_read($one)->{s}{version};
    $other->put_sources_read( $one, read_of('git:2') );
    $state->with_lock( sub {
      push @seen, $state->sources_read($one)->{s}{version};
      push @seen, $state->sources_read($one)->{s}{version};
    }, timeout_ms => 0 );
    $other->put_sources_read( $one, read_of('git:3') );
    push @seen, $state->sources_read($one)->{s}{version};
  } );
  is_deeply( \@seen, [qw( git:1 git:2 git:2 git:3 )], 'the lock taken, and given up, the file is read again' );
  # The other run's puts read it too: one each.
  is( $reads->{'sources-read.json'}, 2 + 3, 'three reads of the read_once state: before, under, after the lock' );
};

subtest 'a removed hermes-home.json leaves the view too' => sub {
  my $tmp   = Cwd::realpath( "".tempdir );
  my $state = Skilletor::State->new( root => "$tmp/state", read_once => 1 );
  $state->put_hermes_home("$tmp/hermes-b");
  is( $state->hermes_home, "$tmp/hermes-b", 'recorded' );
  $state->put_hermes_home(undef);
  ok( !-e "$tmp/state/hermes-home.json", 'the record removed' );
  is( $state->hermes_home, undef, 'and read as none' );
};

# Black box: a SessionStart of a synced machine, a user scope with a local source (which always
# counts as changed, so the hook syncs) and a project scope, reads each record file twice: once
# for the check (both scopes), once for the sync under the lock (both scopes, its puts included).
# It writes none of them, and says nothing.
subtest 'a session start reads each record file once for its check and once under the lock' => sub {
  my $tmp  = Cwd::realpath( "".tempdir );
  my $home = "$tmp/home";
  my $root = "$tmp/state";
  path("$tmp/$_/.claude")->mkpath for qw( home proj );
  write_json( "$tmp/src/skills/hello/SKILL.md", "---\nname: hello\ndescription: hello\n---\nBODY\n" );
  write_json( "$home/.claude/skilletor.json", { sources => { s => { local => "$tmp/src" } }, install => { skills => ['hello@s'] } } );
  my $ctx = {
    home        => $home,
    project_dir => "$tmp/proj",
    state_root  => $root,
    engine      => {
      markers          => { claude => [$home], codex => [] },
      is_git_work_tree => sub { 0 },
      git_tracked      => sub { [] },
      host             => { name => 'box', os => 'linux' },
      user             => { name => 'getty', home => $home },
    },
    background => sub { },
  };
  like( js_stringify( run_hook( 'session-start', { source => 'startup' }, $ctx ) ), qr/1 item\(s\) updated/, 'the first start syncs' );
  my %before = map { ( $_ => path("$root/$_")->slurp_raw ) } qw( sources-read.json render-inputs.json );
  my $out;
  my $reads = reads_of( $root, sub { $out = run_hook( 'session-start', { source => 'startup' }, $ctx ) } );
  is( js_stringify($out), '{}', 'synced: silent' );
  is( $reads->{$_}, 2, "$_: read twice (the check, the sync)" ) for qw( sources-read.json unreached.json render-inputs.json );
  is( path("$root/$_")->slurp_raw, $before{$_}, "$_: not written" ) for sort keys %before;
  ok( !-e "$root/unreached.json", 'unreached.json: still none' );
};

done_testing;
