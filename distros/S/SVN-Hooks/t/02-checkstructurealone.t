# -*- cperl -*-

use strict;
use warnings;
use lib 't';
use lib 'blib/lib';
use Test::More tests => 14;
use SVN::Hooks::CheckStructure;

my $structure = [
    file     => 'FILE',
    dir      => 'DIR',
    subdir1  => [
	qr/^regex/   => 1,
	qr/^noregex/ => 0,
	1           => 'FILE',
    ],
    subdir2  => [
	subfile => 'FILE',
	0       => 'error 2',
    ],
    sub1 => [
	sub2 => [
	    sub3 => [
	    ],
	],
    ],
];

sub check_ok {
    my ($path, $test) = @_;
    eval {check_structure($structure, $path)};
    ok(!$@, $test)
	or diag $@;
}

sub check_nok {
    my ($path, $expect, $test) = @_;
    eval {check_structure($structure, $path)};
    if ($@) {
	like($@, $expect, $test);
    }
    else {
	fail($test);
	diag('test succeeded unexpectedly');
    }
}

check_ok('/file', 'FILE ok');
check_nok('/file/', qr/the component \(file\) should be a FILE/, 'FILE nok');

check_ok('/dir/', 'DIR ok');
check_nok('/dir', qr/the component \(dir\) should be a DIR/, 'DIR nok');

check_nok('/subdir1', qr/the component \(subdir1\) should be a DIR/, 'array DIR nok');
check_ok('/subdir1/', 'array DIR ok');

check_ok('/subdir1/regex', 'regex ok');
check_nok('/subdir1/noregex', qr/invalid path/, 'regex nok');

check_ok('/subdir1/file', 'else FILE ok');
check_nok('/subdir1/file/', qr/the component \(file\) should be a FILE/, 'else FILE nok');

check_nok('/subdir2/other', qr/error 2/, '0 =>');

check_ok('/sub1/', '/sub1');
check_ok('/sub1/sub2/', '/sub1/sub2/');
check_ok('/sub1/sub2/sub3/', '/sub1/sub2/sub3/');
