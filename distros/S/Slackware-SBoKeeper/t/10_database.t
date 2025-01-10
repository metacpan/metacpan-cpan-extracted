#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use Slackware::SBoKeeper::Database;

plan tests => 41;

my $TEST_REPO = 't/data/repo';
my $TEST_FILE = 'test-data-file.txt';

sub db_wipe {

	my $db = shift;

	$db->remove([ $db->packages ]);

}

my $db;
my $rdb;

$db = Slackware::SBoKeeper::Database->new(
	'',
	$TEST_REPO
);

isa_ok($db, 'Slackware::SBoKeeper::Database', 'new works');

is_deeply(
	[ $db->real_immediate_dependencies('f') ],
	[ qw(a b e) ],
	'real_immediate_dependencies() works'
);

is_deeply(
	[ $db->real_dependencies('f') ],
	[ qw(a b c d e) ],
	'real_dependencies() works'
);

# 'f' should pull in every other single-letter package

is_deeply(
	[ $db->add(['f'], 1) ],
	[ qw(a b c d e f) ],
	'add pulled in correct packages'
);

is_deeply(
	[ $db->packages ],
	[ qw(a b c d e f) ],
	'Package list and add list agree'
);

foreach my $p (qw(a b c d e f)) {
	ok($db->exists($p), 'exists() works');
	ok($db->has($p),    'has() works');
}

ok(!$db->exists('@fakepkg'), 'exists() does not find fake packages');
ok(!$db->has('@fakepkg'),    'has() does not find fake packages');
ok($db->exists('%README%'),  '%README% is considered real');

foreach my $p (qw(a b c d e)) {
	ok($db->is_dependency($p, 'f'), 'is_dependency() works');
}

is_deeply(
	[ $db->immediate_dependencies('f') ],
	[ qw(a b e) ],
	'immediate_dependencies() works'
);

is_deeply(
	[ $db->dependencies('f') ],
	[ qw(a b c d e) ],
	'dependencies() works'
);

is_deeply(
	[ $db->depremove('f', [ qw(a) ]) ],
	[ qw(a) ],
	'depremove() removed dependencies'
);

is_deeply(
	[ $db->immediate_dependencies('f') ],
	[ qw(b e) ],
	"depremove'd dependencies no longer tracked"
);

is_deeply(
	[ $db->depadd('f', [ qw(a) ]) ],
	[ qw(a) ],
	'depadd() added dependencies'
);

is_deeply(
	[ $db->immediate_dependencies('f', [ qw(a) ]) ],
	[ qw(a b e) ],
	"depadd'd dependencies tracked"
);

$db->write($TEST_FILE);
ok(-s $TEST_FILE, 'write() created database file');

$rdb = Slackware::SBoKeeper::Database->new(
	$TEST_FILE,
	$TEST_REPO
);
isa_ok($rdb, 'Slackware::SBoKeeper::Database',
	'new() works (when reading from file)'
);

is_deeply(
	[ $rdb->packages ],
	[ qw(a b c d e f) ],
	'new() read database file correctly'
);

is_deeply(
	[ $db->remove([ qw(a b c d e f) ]) ],
	[ qw(a b c d e f) ],
	'remove() removed correct packages'
);

is_deeply(
	[ $db->packages ],
	[ ],
	'Package database is empty after wipe'
);

is_deeply(
	[ $db->tack(['f'], 1) ],
	[ qw(f) ],
	'tack() added correct packages'
);

$db->remove(['f']);

is_deeply(
	[ $db->add(['multiline'], 1) ],
	[ qw(a c d multiline) ],
	'Can handle multiline REQUIRES'
);

db_wipe($db);
$db->tack([ qw(f) ], 1);

is_deeply(
	{ $db->missing() },
	{ f => [ qw(a b e) ] },
	"missing() works"
);

$db->unmanual('f');

ok(!$db->is_manual('f'), 'unmanual() works');

db_wipe($db);

$db->add([ qw (a c d) ], 1);
$db->depadd('a', [ qw(c d) ]);

is_deeply(
	{ $db->extradeps() },
	{ 'a' => [ qw(c d) ] },
	'extradeps() works'
);

END {
	unlink $TEST_FILE if -e $TEST_FILE;
}
