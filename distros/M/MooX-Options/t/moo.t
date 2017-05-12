#!/usr/bin/env perl
#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use t::Test;
use Test::Trap;
use Carp;
use FindBin qw/$RealBin/;
use Try::Tiny;

{

    package t;
    use Moo;
    use MooX::Options;

    option 'bool'    => ( is => 'ro' );
    option 'counter' => ( is => 'ro', repeatable => 1 );
    option 'empty'   => ( is => 'ro', negativable => 1 );
    option 'split'   => ( is => 'ro', format => 'i@', autosplit => ',' );
    option 'has_default' => ( is => 'ro', default => sub {'foo'} );
    option 'range' => ( is => 'ro', format => 'i@', autorange => 1 );

    1;
}

{

    package r;
    use Moo;
    use MooX::Options;

    option 'str_req' => ( is => 'ro', format => 's', required => 1 );

    1;
}

{

    package sp_str;
    use Moo;
    use MooX::Options;

    option 'split_str' => ( is => 'ro', format => 's', autosplit => "," );
    option 'split_conflict_str1' =>
        ( is => 'ro', format => 's', autosplit => "," );
    option 'split_conflict_str2' =>
        ( is => 'ro', format => 's', autosplit => "," );

    1;
}

{

    package sp_str_short;
    use Moo;
    use MooX::Options;

    option 'split_str' =>
        ( is => 'ro', format => 's', autosplit => ",", short => 'z' );

    1;
}

{

    package d;
    use Moo;
    use MooX::Options;
    option 'should_die_ok' =>
        ( is => 'ro', isa => sub { die "this will die ok" } );
    1;
}

{

    package multi_req;
    use Moo;
    use MooX::Options;
    option 'multi_1' => ( is => 'ro', required => 1 );
    option 'multi_2' => ( is => 'ro', required => 1 );
    option 'multi_3' => ( is => 'ro', required => 1 );
    1;
}

{

    package t_doc;
    use Moo;
    use MooX::Options;
    option 't' => ( is => 'ro', doc => 'this is a test' );
    1;
}

{

    package t_short;
    use Moo;
    use MooX::Options;
    option 'verbose' => ( is => 'ro', short => 'v' );
    1;
}

{

    package t_skipopt;
    use Moo;
    use MooX::Options skip_options => [qw/multi/];

    option 'multi' => ( is => 'ro' );
    1;
}

{

    package t_prefer_cli;
    use Moo;
    use MooX::Options prefer_commandline => 1;

    option 't' => ( is => 'ro', format => 's' );
    1;
}

{

    package t_dash;
    use Moo;
    use MooX::Options;

    option 'start_date' => ( is => 'ro', format => 's', short => 's' );
    1;
}

{

    package t_json;
    use Moo;
    use MooX::Options;

    option 't' => ( is => 'ro', json => 1 );
    1;
}

{

    package t_json_opt;
    use Moo;
    use MooX::Options;

    option 't' => ( is => 'ro', format => 'json' );
    1;
}

{

    package rg_str;
    use Moo;
    use MooX::Options;

    option 'range_str' => ( is => 'ro', format => 's', autorange => 1 );
    option 'range_conflict_str1' =>
        ( is => 'ro', format => 's', autorange => 1 );
    option 'range_conflict_str2' =>
        ( is => 'ro', format => 's', autorange => 1 );

    1;
}

{

    package rg_str_short;
    use Moo;
    use MooX::Options;

    option 'range_str' =>
        ( is => 'ro', format => 's', autorange => 1, short => 'r' );

    1;
}

subtest "Moo" => sub {
    note "Test Moo";
    require $RealBin . '/base.st';
};

done_testing;
