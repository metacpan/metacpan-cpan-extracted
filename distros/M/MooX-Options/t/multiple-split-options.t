#!perl
#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use t::Test;

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
