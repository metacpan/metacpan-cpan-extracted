#!/usr/bin/perl
use Config;
use Test::More (
    $Config{d_symlink} ? (tests => 9)
		       : (skip_all => "symlink not available")
);
use PerlIO::via::symlink;
use strict;

use POSIX qw(setlocale LC_ALL);
setlocale (LC_ALL, 'C');

my $fname = 'symlink-test';
unlink ($fname);
open my $fh, '+>:via(symlink)', $fname;
ok ($! =~ m'Invalid argument');

open $fh, '>:via(symlink)', $fname or die $!;
print $fh "link foobar";
close $fh;
ok (-l $fname);
is (readlink $fname, 'foobar');

open $fh, '<:via(symlink)', $fname or die $!;
is (<$fh>, 'link foobar', 'read');
seek $fh, 0, 0;
is (<$fh>, 'link foobar', 'read');

unlink ($fname);

eval {
open my $fh, '>:via(symlink)', $fname or die $!;
print $fh "foobar";
close $fh or die $!;
};
ok ($@ =~ m'Invalid argument');

open $fh, '<:via(symlink)', $fname;
ok ($! =~ m'Bad file (number|descriptor)');

eval {
open my $fh, '>:via(symlink)', $fname or die $!;
`touch $fname`;
print $fh "link foobar";
close $fh or die $!;
};
ok ($@ =~ m'File exists');

open $fh, '<:via(symlink)', $fname;
ok ($! =~ m'Bad file (number|descriptor)');
