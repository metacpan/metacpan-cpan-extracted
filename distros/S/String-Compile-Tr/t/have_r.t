#!perl -T

use Test2::Require::Perl 'v5.14';
use 5.014;
use Test2::V0;

use String::Compile::Tr;

{
    my $x = 'abc';
    my $y = '123';
    is trgen($x, $y, 'r')->('edcba'), 'ed321', 'use options';
}

done_testing;

