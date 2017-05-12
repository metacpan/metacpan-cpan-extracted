#!/usr/bin/perl
# '$Id: 80export.t,v 1.1 2004/12/05 21:19:33 ovid Exp $';
use warnings;
use strict;
use Test::More tests => 4;
#use Test::More qw/no_plan/;

BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib', 'test_lib/';
    use_ok 'ExportTest', 'foo' or die;
}

ok defined &foo,
    'We can export functions that have signatures';

is_deeply foo({this => 'one'}), {this => 'one'},    
    '... and call the correct function';

is_deeply foo(1,2), [1,2],
    '... and watch it dispatch correctly';
