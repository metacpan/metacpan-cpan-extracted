#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest;

use Path::Tiny qw( tempdir );
use Skilletor::State;

# Expected bytes and answers: the reference's State, run once with Node on the same steps.
my $root = tempdir;
$root->child('trust.json')->spew_raw('{"old":"https://legacy/x","z":{"kind":"git","address":"https://z"}}');
my $s = Skilletor::State->new( root => "$root" );
$s->trust( b => { kind => 'git', address => 'https://b', extra => 'dropped' } );
$s->trust( 2 => { kind => 'local', address => '/home/ü/dev' } );
$s->trust( a => { kind => 'url', address => 'https://a/x.tgz' } );
$s->trust( z => { kind => 'local', address => '/z' } );
is( $root->child('trust.json')->slurp_utf8,
  qq({\n  "2": {\n    "kind": "local",\n    "address": "/home/ü/dev"\n  },\n  "old": "https://legacy/x",\n  "z": {\n    "kind": "local",\n    "address": "/z"\n  },\n  "b": {\n    "kind": "git",\n    "address": "https://b"\n  },\n  "a": {\n    "kind": "url",\n    "address": "https://a/x.tgz"\n  }\n}\n),
  'trust.json as the reference writes it' );

my @checks = (
  [ b    => { kind => 'git',   address => 'https://b',        origin => 'project' }, 1 ],
  [ b    => { kind => 'url',   address => 'https://b',        origin => 'project' }, 0 ],
  [ old  => { kind => 'git',   address => 'https://legacy/x', origin => 'project' }, 1 ],
  [ old  => { kind => 'url',   address => 'https://legacy/x', origin => 'project' }, 1 ],
  [ old  => { kind => 'local', address => 'https://legacy/x', origin => 'project' }, 0 ],
  [ nope => { kind => 'git',   address => 'x',                origin => 'user' },    1 ],
  [ nope => { kind => 'git',   address => 'x',                origin => 'project' }, 0 ],
);
for my $c (@checks) {
  is( $s->is_trusted( $c->[0], $c->[1] ), $c->[2], 'is_trusted '.$c->[0].' '.$c->[1]{kind}.' '.$c->[1]{origin} );
}

$root->child('trust.json')->spew_raw('[1]');
ok( !$s->is_trusted( b => { kind => 'git', address => 'https://b', origin => 'project' } ), 'a non-object file trusts nothing' );
$s->trust( c => { kind => 'git', address => 'https://c' } );
is( $root->child('trust.json')->slurp_utf8, qq({\n  "c": {\n    "kind": "git",\n    "address": "https://c"\n  }\n}\n), 'and is replaced on the next trust' );

my $home = tempdir;
my $h = Skilletor::State->for_home("$home");
is( $h->root, "$home/.claude/skilletor", 'state root under the home' );
ok( -d $h->root, 'created' );

done_testing;
