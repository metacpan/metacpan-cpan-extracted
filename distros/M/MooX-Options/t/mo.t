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

BEGIN {
    eval 'use Mo 0.36';
    if ($@) {
        plan skip_all => 'Need Mo (0.36) for this test';
        exit 0;
    }
}

{

    package tRole;
    use Moo::Role;
    use Mo 'default';
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

    package t;
    use Mo;
    use Role::Tiny::With;
    with 'tRole';

    1;
}

{

    package rRole;
    use Moo::Role;
    use Mo 'required';
    use MooX::Options;

    option 'str_req' => ( is => 'ro', format => 's', required => 1 );

    1;
}
{

    package r;
    use Mo;
    use Role::Tiny::With;
    with 'rRole';

    1;
}

{

    package sp_strRole;
    use Moo::Role;
    use Mo;
    use MooX::Options;

    option 'split_str' => ( is => 'ro', format => 's', autosplit => "," );
    option 'split_conflict_str1' =>
        ( is => 'ro', format => 's', autosplit => "," );
    option 'split_conflict_str2' =>
        ( is => 'ro', format => 's', autosplit => "," );

    1;
}
{

    package sp_str;
    use Mo;
    use Role::Tiny::With;
    with 'sp_strRole';

    1;
}

{

    package sp_str_shortRole;
    use Moo::Role;
    use Mo;
    use MooX::Options;

    option 'split_str' =>
        ( is => 'ro', format => 's', autosplit => ",", short => 'z' );

    1;
}
{

    package sp_str_short;
    use Mo;
    use Role::Tiny::With;
    with 'sp_str_shortRole';

    1;
}

{

    package dRole;
    use Moo::Role;
    use Mo 'coerce';
    use MooX::Options;
    option 'should_die_ok' =>
        ( is => 'ro', coerce => sub { die "this will die ok" } );
    1;
}
{

    package d;
    use Mo 'coerce';
    use Role::Tiny::With;
    with 'dRole';
    1;
}

{

    package multi_reqRole;
    use Moo::Role;
    use Mo 'required';
    use MooX::Options;
    option 'multi_1' => ( is => 'ro', required => 1 );
    option 'multi_2' => ( is => 'ro', required => 1 );
    option 'multi_3' => ( is => 'ro', required => 1 );
    1;
}
{

    package multi_req;
    use Mo;
    use Role::Tiny::With;
    with 'multi_reqRole';
    1;
}

{

    package t_docRole;
    use Moo::Role;
    use Mo;
    use MooX::Options;
    option 't' => ( is => 'ro', doc => 'this is a test' );
    1;
}
{

    package t_doc;
    use Mo;
    use Role::Tiny::With;
    with 't_docRole';
    1;
}

{

    package t_shortRole;
    use Moo::Role;
    use Mo;
    use MooX::Options;
    option 'verbose' => ( is => 'ro', short => 'v' );
    1;
}

{

    package t_short;
    use Mo;
    use Role::Tiny::With;
    with 't_shortRole';
    1;
}

{

    package t_skipoptRole;
    use Moo::Role;
    use Mo;
    use MooX::Options skip_options => [qw/multi/];

    option 'multi' => ( is => 'ro' );
    1;
}
{

    package t_skipopt;
    use Mo;
    use Role::Tiny::With;
    with 't_skipoptRole';
    1;
}

{

    package t_prefer_cliRole;
    use Moo::Role;
    use Mo;
    use MooX::Options prefer_commandline => 1;

    option 't' => ( is => 'ro', format => 's' );
    1;
}
{

    package t_prefer_cli;
    use Mo;
    use Role::Tiny::With;
    with 't_prefer_cliRole';
    1;
}

{

    package t_dashRole;
    use Moo::Role;
    use Mo;
    use MooX::Options;

    option 'start_date' => ( is => 'ro', format => 's', short => 's' );
    1;
}
{

    package t_dash;
    use Mo;
    use Role::Tiny::With;
    with 't_dashRole';
    1;
}

{

    package t_jsonRole;
    use Moo::Role;
    use Mo;
    use MooX::Options;

    option 't' => ( is => 'ro', json => 1 );
    1;

}

{

    package t_json;
    use Mo;
    use Role::Tiny::With;
    with 't_jsonRole';
    1;
}

{

    package t_jsonOptRole;
    use Moo::Role;
    use Mo;
    use MooX::Options;

    option 't' => ( is => 'ro', format => 'json' );
    1;

}

{

    package t_json_opt;
    use Mo;
    use Role::Tiny::With;
    with 't_jsonOptRole';
    1;
}

{

    package rg_strRole;
    use Moo::Role;
    use Mo;
    use MooX::Options;

    option 'range_str' => ( is => 'ro', format => 's', autorange => 1 );
    option 'range_conflict_str1' =>
        ( is => 'ro', format => 's', autorange => 1 );
    option 'range_conflict_str2' =>
        ( is => 'ro', format => 's', autorange => 1 );

    1;
}

{

    package rg_str;
    use Mo;
    use Role::Tiny::With;
    with 'rg_strRole';

    1;
}

{

    package rg_str_shortRole;
    use Moo::Role;
    use Mo;
    use MooX::Options;

    option 'range_str' =>
        ( is => 'ro', format => 's', autorange => 1, short => 'r' );

    1;
}
{

    package rg_str_short;
    use Mo;
    use Role::Tiny::With;
    with 'rg_str_shortRole';

    1;
}

subtest "Mo" => sub {
    note "Test Mo";
    require $RealBin . '/base.st';
};

done_testing;
