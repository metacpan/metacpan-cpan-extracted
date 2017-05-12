#!/usr/bin/env perl
use strict; use warnings;
use lib '../lib' ;

use Test::More;

BEGIN {
  use_ok( 'Term::ReadLine::Perl5::Common' );
}

foreach my $tuple (
    ['yank', 'Yank'],
    ['BeginningOfLine', 'BeginningOfLine',
     'beginning-of-line', 'BeginningOfLine']) {
    my ($name, $expect) = @{$tuple};
    is(canonic_command_function($name), $expect,
       "canonicalization('$name')");
};

foreach my $tuple (
    ['\C-w', [23]],
    ['\C-\M-a', [27, 1]],
    ['\M-e',    [27, 101]],
    ['\x10',    [16]],
    ['\007',    [7]],
    ['\010',    [8]],
    ['\d',      [4]],
    ['\b',      [127]]) {
    my ($name, $expect) = @{$tuple};
    my @unescape =  unescape($name);
    is_deeply(\@unescape, $expect, "unescape('$name')");
};

done_testing();
