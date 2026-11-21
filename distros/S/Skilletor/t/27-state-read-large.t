#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( write_json );

use Path::Tiny qw( tempdir );
use Time::HiRes ();
use Skilletor::JSON qw( js_ordered );
use Skilletor::State;

# A big state file reads in linear time (k196). A real sources-read.json of 307 KB stalled
# `check` for 13 s and `hook session-start` for 39 s: js_parse copied the text in every string
# and number, and a copy has no UTF-8 offset cache, so each pos() on it scanned from the start.
# That bites only on a UTF-8 flagged text, which is what read_text gives, so this reads through
# State as the CLI does; one non-ASCII address flags the text on any decoder.
my $root  = tempdir;
my %want;
my $all = js_ordered();
for my $k ( 1 .. 180 ) {
  my $key = sprintf '/tmp/work/project-%04d/.claude/skilletor.lock.json', $k;
  my $record = js_ordered();
  for my $n ( 1 .. 6 ) {
    $record->{ sprintf 'source-%02d', $n } = js_ordered(
      kind    => 'git',
      address => sprintf( 'https://github.com/example-org/skills-repository-%03d-%02d', $k, $n ),
      version => sprintf( 'git:%040x', $k * 1000 + $n ),
      ref     => 'main',
      path    => [ 'skills', sprintf( 'sub-%02d', $n ) ],
    );
  }
  $all->{$key} = $record;
}
$all->{'/home/jürgen/.claude/skilletor.lock.json'} = js_ordered(
  mine => js_ordered( kind => 'local', address => '/home/jürgen/dev/skills', version => 'local:ab12cd3' ),
);
my $file = write_json( $root->child('sources-read.json'), $all );
cmp_ok( -s $file, '>', 290_000, 'the file is as big as the one that stalled' );

my $state = Skilletor::State->new( root => "$root" );
my $start = Time::HiRes::time();
my $read  = $state->sources_read('/tmp/work/project-0180/.claude/skilletor.lock.json');
my $took  = Time::HiRes::time() - $start;
is_deeply(
  { %{ $read->{'source-06'} } },
  { kind => 'git', address => 'https://github.com/example-org/skills-repository-180-06', version => 'git:'.sprintf( '%040x', 180_006 ), ref => 'main', path => [ 'skills', 'sub-06' ] },
  'the last record of the last ASCII scope reads back whole',
);
is( scalar keys %$read, 6, 'all six sources of that scope' );
is( $state->sources_read('/home/jürgen/.claude/skilletor.lock.json')->{mine}{address}, '/home/jürgen/dev/skills', 'the non-ASCII scope reads back' );

# Unpatched this took 10 s and more; linear it takes a fraction of a second. The bound leaves
# a slow or busy machine room to spare and still fails the quadratic parse.
cmp_ok( $took, '<', 3, 'reading it takes well under the quadratic time' ) or diag sprintf 'took %.2f s', $took;
note sprintf 'sources_read on %d bytes: %.3f s', -s $file, $took;

done_testing;
