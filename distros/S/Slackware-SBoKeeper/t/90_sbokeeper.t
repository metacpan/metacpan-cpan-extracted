#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use Cwd;
use File::Spec;

use Slackware::SBoKeeper;
use Slackware::SBoKeeper::System;

# There are some limitations to testing sbokeeper
# We can test the following commands for not dying, but cannot test that their
# output is correct:
# * deps
# * diff
# * depwant
# * depextra
# * print
# * tree
# * dump
# * help
#
# The following commands we cannot test at all, because their behavior depends
# on the system's state:
# * pull

plan tests => 90;

my $TMP_DATA = 'tmp-data.txt';
my $DATA_DIR = File::Spec->catfile(qw(t data datafiles));
my $TEST_REPO = File::Spec->catfile(qw(t data repo));
my $TEST_CONF = 'test.conf';

my @COMMON_OPTS = (
	'-d', $TMP_DATA,
	'-s', $TEST_REPO,
	'-t', '_SBo',
	'-y',
);

sub new_test_obj {

	my @args = @_;

	@ARGV = (@COMMON_OPTS, @args);
	my $obj = Slackware::SBoKeeper->init();

	@ARGV = ();

	return $obj;

}

sub slurp {

	my $file = shift;

	local $/ = undef;

	open my $fh, '<', $file
		or die "Failed to open $file for reading: $!";

	my $slurp = readline $fh;

	close $fh;

	return $slurp;

}

sub create_test_config {

	my $config = shift;

	open my $fh, '>', $config
		or die "Failed to open $config for writing: $!";

	say { $fh } "DataFile = " . File::Spec->catfile(cwd(), $TMP_DATA);
	say { $fh } "SBoPath = "  . File::Spec->catfile(cwd(), $TEST_REPO);
	say { $fh } "Tag = _SBo";

	close $fh;

}

my $obj;

$obj = new_test_obj(qw(add luajit python3-meson-opt libplacebo mpv));
isa_ok($obj, 'Slackware::SBoKeeper');

is($obj->get('DataFile'),   $TMP_DATA,  'DataFile is correct');
is($obj->get('SBoPath'),    $TEST_REPO, 'SBoPath is correct');
is($obj->get('Tag'),        '_SBo',     'Tag is correct');
is($obj->get('YesAll'),     1,          'YesAll is correct');
is($obj->get('Command'),    'add',      'Command is correct');
is_deeply(
	$obj->get('Args'),
	[ qw(luajit python3-meson-opt libplacebo mpv) ],
	'Args is correct'
);

ok($obj->run(), "'add' runs ok");

is(
	slurp($TMP_DATA),
	slurp(File::Spec->catfile($DATA_DIR, 'add.txt')),
	"'add' added packages correctly"
);

# We aren't actually testing that the output of deps is correct, we're just
# testing to make sure it doesn't crash and burn.
$obj = new_test_obj(qw(deps mpv));
ok($obj->run(), "'deps' runs ok");

$obj = new_test_obj(qw(rm luajit python3-meson-opt libplacebo mpv));
ok($obj->run(), "'rm' runs ok");

is(
	slurp($TMP_DATA),
	slurp(File::Spec->catfile($DATA_DIR, 'rm.txt')),
	"'rm' removed packages correctly"
);

$obj = new_test_obj(qw(clean));
ok($obj->run(), "'clean' runs ok");

is(
	slurp($TMP_DATA),
	'',
	"'clean' cleaned up packages correctly"
);

$obj = new_test_obj(qw(tack luajit python3-meson-opt libplacebo mpv));
ok($obj->run(), "'tack' runs ok");

is(
	slurp($TMP_DATA),
	slurp(File::Spec->catfile($DATA_DIR, 'tack.txt')),
	"'tack' added packages correctly"
);

$obj = new_test_obj(qw(rm @all));
ok($obj->run(), "'rm \@all' runs ok");

is(
	slurp($TMP_DATA),
	'',
	"'rm \@all' removed packages correctly"
);

$obj = new_test_obj(qw(addish luajit python3-meson-opt libplacebo mpv));
ok($obj->run(), "'addish' runs ok");

is(
	slurp($TMP_DATA),
	slurp(File::Spec->catfile($DATA_DIR, 'addish.txt')),
	"'addish' added packages correctly"
);

unlink $TMP_DATA;

$obj = new_test_obj(qw(tackish luajit python3-meson-opt libplacebo mpv));
ok($obj->run(), "'tackish' runs ok");

is(
	slurp($TMP_DATA),
	slurp(File::Spec->catfile($DATA_DIR, 'tackish.txt')),
	"'tackish' adds packages correctly"
);

unlink $TMP_DATA;

$obj = new_test_obj(qw(tack luajit python3-meson-opt libplacebo mpv));
$obj->run();

$obj = new_test_obj(qw(unmanual luajit python3-meson-opt libplacebo mpv));
ok($obj->run(), "'unmanual' runs ok");

is(
	slurp($TMP_DATA),
	slurp(File::Spec->catfile($DATA_DIR, 'unmanual.txt')),
	"'unmanual' unmanuals packages correctly"
);

unlink $TMP_DATA;

$obj = new_test_obj(qw(tack mpv));
$obj->run(),

$obj = new_test_obj(qw(depadd mpv luajit python3-meson-opt libplacebo));
ok($obj->run(), "'depadd' runs ok");

is(
	slurp($TMP_DATA),
	slurp(File::Spec->catfile($DATA_DIR, 'depadd.txt')),
	"'depadd' adds dependencies correctly"
);

$obj = new_test_obj(qw(depextra));
ok($obj->run(), "'depextra' runs ok");

$obj = new_test_obj(qw(deprm mpv luajit python3-meson-opt libplacebo));
ok($obj->run(), "'deprm' runs ok");

is(
	slurp($TMP_DATA),
	slurp(File::Spec->catfile($DATA_DIR, 'deprm.txt')),
	"'deprm' adds dependencies correctly"
);

$obj = new_test_obj(qw(depwant));
ok($obj->run(), "'depwant' runs ok");

SKIP: {

	skip "'diff' cannot be used by non-Slackware systems", 1
		unless Slackware::SBoKeeper::System->is_slackware();

	$obj = new_test_obj(qw(diff));
	ok($obj->run(), "'diff' runs ok");

}

$obj = new_test_obj(qw(tree mpv luajit python3-meson-opt libplacebo));
ok($obj->run(), "'tree' runs ok");

$obj = new_test_obj(qw(dump));
ok($obj->run(), "'dump' runs ok");

for my $help (qw(
	add tack addish tackish rm clean deps depadd deprm pull diff depwant
	depextra unmanual print tree dump help
)) {

	$obj = new_test_obj(qw(help), $help);
	ok($obj->run(), "'help $help' runs ok");

	$obj = new_test_obj(qw(help), uc $help);
	ok($obj->run(), "'help $help' runs ok (with non-lowercase argument)");

}

for my $cat (qw(
	all manual nonmanual necessary unnecessary missing untracked phony
)) {

	$obj = new_test_obj(qw(print), $cat);
	ok($obj->run(), "'print $cat' runs ok");

	$obj = new_test_obj(qw(print), "\@$cat");
	ok($obj->run(), "'print \@$cat' runs ok (with '@' prefix)");

}

$obj = new_test_obj(qw(print
	all manual nonmanual necessary unnecessary missing untracked phony
));
ok($obj->run(), "'print' with all categories runs ok");

create_test_config($TEST_CONF);

@ARGV = ('-c', $TEST_CONF, 'help');
$obj = Slackware::SBoKeeper->init();

is(
	$obj->get('ConfigFile'),
	$TEST_CONF,
	"-c config file is correct"
);
is(
	$obj->get('DataFile'),
	File::Spec->catfile(cwd(), $TMP_DATA),
	"DataFile config file option is ok"
);
is(
	$obj->get('SBoPath'),
	File::Spec->catfile(cwd(), $TEST_REPO),
	"SBoPath config file option is ok"
);
is(
	$obj->get('Tag'),
	'_SBo',
	"Tag config file option is ok"
);

END {
	unlink $TMP_DATA       if -e $TMP_DATA;
	unlink "$TMP_DATA.bak" if -e "$TMP_DATA.bak";
	unlink $TEST_CONF      if -e $TEST_CONF;
}
