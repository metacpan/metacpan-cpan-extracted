#!perl

use 5.006;
use strict; use warnings;
use Test::Tester;
use Test::CSS;
use Test::More tests => 18;

my $desc = 'well formed CSS string';
check_test(
    sub { ok_css_string('body { xyx: red }', $desc) },
    { ok => 0, name => $desc },
    $desc
);

check_test(
    sub { ok_css_string('body { background: red }', $desc) },
    { ok => 1, name => $desc },
    $desc
);

my $css_file  = 't/sample.css';
my $file_desc = 'well formed CSS file';
check_test(
    sub { ok_css_file($css_file, $file_desc) },
    { ok => 1, name => $file_desc },
    $file_desc
);
