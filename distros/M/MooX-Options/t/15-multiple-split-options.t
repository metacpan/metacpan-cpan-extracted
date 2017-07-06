#!perl
use strict;
use warnings all => 'FATAL';
use Test::More;

BEGIN {
    use Module::Runtime qw(use_module);
    eval { use_module("Data::Record"); use_module("Regexp::Common"); }
        or plan skip_all => "This test needs Data::Record and Regexp::Common";
}

{

    package TestMultipleSplitOptions;
    use Moo;
    use MooX::Options;

    option 'opt'  => ( is => 'ro', format => 'i@', autosplit => ',' );
    option 'opt2' => ( is => 'ro', format => 'i@', autosplit => ',' );
    1;
}

local @ARGV = ( '--opt', '1,2', '--opt2', '3,4' );
my $opt = TestMultipleSplitOptions->new_with_options;

is_deeply $opt->opt,  [ 1, 2 ], 'opt got split correctly';
is_deeply $opt->opt2, [ 3, 4 ], 'opt2 got split correctly';

done_testing;
