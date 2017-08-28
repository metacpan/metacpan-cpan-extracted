#!/usr/bin/env perl

use strict;
use warnings all => 'FATAL';
use Test::More;
use Test::Trap;
use FindBin '$RealBin';

my @autosplit;

BEGIN {
    use Module::Runtime qw(use_module);
    eval { use_module("Moose") }
        or plan skip_all => 'Need Moose for this test';
    eval { use_module("Data::Record"); use_module("Regexp::Common"); }
        and @autosplit = ( autosplit => ',' );
}

{

    package t;
    use Moose;
    use MooX::Options;

    option 'bool'        => ( is => 'ro' );
    option 'counter'     => ( is => 'ro', repeatable => 1 );
    option 'empty'       => ( is => 'ro', negatable => 1 );
    option 'verbose'     => ( is => 'ro', negativable => 1 );
    option 'used'        => ( is => 'ro' );
    option 'unused'      => ( is => 'ro', short => 'no_used' );
    option 'split'       => ( is => 'ro', format => 'i@', @autosplit );
    option 'has_default' => ( is => 'ro', default => sub {'foo'} );
    option 'range'       => ( is => 'ro', format => 'i@', autorange => 1 );

    1;
}

{

    package r;
    use Moose;
    use MooX::Options;

    option 'str_req' => ( is => 'ro', format => 's', required => 1 );

    1;
}

{

    package sp_str;
    use Moose;
    use MooX::Options;

    option 'split_str'           => ( is => 'ro', format => 's', @autosplit );
    option 'split_conflict_str1' => ( is => 'ro', format => 's', @autosplit );
    option 'split_conflict_str2' => ( is => 'ro', format => 's', @autosplit );

    1;
}

{

    package sp_str_short;
    use Moose;
    use MooX::Options;

    option 'split_str' =>
        ( is => 'ro', format => 's', @autosplit, short => 'z' );

    1;
}

{

    package d;
    use Moose;
    use MooX::Options;
    option 'should_die_ok' =>
        ( is => 'ro', trigger => sub { die "this will die ok" } );
    1;
}

{

    package multi_req;
    use Moose;
    use MooX::Options;
    option 'multi_1' => ( is => 'ro', required => 1 );
    option 'multi_2' => ( is => 'ro', required => 1 );
    option 'multi_3' => ( is => 'ro', required => 1 );
    1;
}

{

    package t_doc;
    use Moose;
    use MooX::Options;
    option 't' => ( is => 'ro', doc => 'this is a test' );
    1;
}

{

    package t_short;
    use Moose;
    use MooX::Options;
    option 'verbose' => ( is => 'ro', short => 'v' );
    1;
}

{

    package t_skipopt;
    use Moose;
    use MooX::Options skip_options => [qw/multi/];

    option 'multi' => ( is => 'ro' );
    1;
}

{

    package t_prefer_cli;
    use Moose;
    use MooX::Options prefer_commandline => 1;

    option 't' => ( is => 'ro', format => 's' );

    1;
}

{

    package t_dash;
    use Moose;
    use MooX::Options;

    option 'start_date' => ( is => 'ro', format => 's', short => 's' );
    1;
}

{

    package t_json;
    use Moose;
    use MooX::Options;

    option 't' => ( is => 'ro', json => 1 );
    1;
}

{

    package t_json_opt;
    use Moose;
    use MooX::Options;

    option 't' => ( is => 'ro', format => 'json' );
    1;
}

{

    package rg_str;
    use Moose;
    use MooX::Options;

    option 'range_str' => (
        is        => 'ro',
        format    => 's',
        autorange => 1,
        short     => 'rs',
        @autosplit
    );
    option 'range_conflict_str1' =>
        ( is => 'ro', format => 's', autorange => 1 );
    option 'range_conflict_str2' =>
        ( is => 'ro', format => 's', autorange => 1 );

    1;
}

{

    package rg_str_short;
    use Moose;
    use MooX::Options;

    option 'range_str' =>
        ( is => 'ro', format => 's', autorange => 1, short => 'r' );

    1;
}

{

    package rg_str_short_common;
    use Moose;
    use MooX::Options;

    option 'range_str' =>
        ( is => 'ro', format => 's', autorange => 1, short => 'r' );
    option 'range_json' => ( is => 'ro', format => 'json', short => 'j' );

    1;
}

subtest "Moose" => sub {
    note "Test Moose";
    do $RealBin . '/base.st';
    $@ and diag $@;
};

done_testing;
