#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;


BEGIN {
    use_ok( 'Tail::Stat' );
    use_ok( 'Tail::Stat::Plugin' );
    use_ok( 'Tail::Stat::Plugin::apache' );
    use_ok( 'Tail::Stat::Plugin::clamd' );
    use_ok( 'Tail::Stat::Plugin::cvsupd' );
    use_ok( 'Tail::Stat::Plugin::nginx' );
    use_ok( 'Tail::Stat::Plugin::spamd' );
}

done_testing;

