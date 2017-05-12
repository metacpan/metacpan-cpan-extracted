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
use Carp;

local $ENV{TEST_FORCE_COLUMN_SIZE} = 78;

eval <<__EOF__
    package FailureNegativableWithFormat;
    use Moo;
    use MooX::Options;

    option fail => (
        is => 'rw',
        negativable => 1,
        format => 'i',
    );

    1;
__EOF__
    ;
like $@,
    qr/^Negativable\sparams\sis\snot\susable\swith\snon\sboolean\svalue,\sdon't\spass\sformat\sto\suse\sit\s\!/x,
    "negativable and format are incompatible";

for my $ban (
    qw/help man usage option new_with_options parse_options options_usage _options_data _options_config/
    )
{
    eval <<__EOF__
    package FailureHelp$ban;
    use Moo;
    use MooX::Options;

    option $ban => (
        is => 'rw',
    );
__EOF__
        ;
    like $@,
        qr/^You\scannot\suse\san\soption\swith\sthe\sname\s'$ban',\sit\sis\simplied\sby\sMooX::Options/x,
        "$ban method can't be defined";
}

{
    eval <<__EOF__
    {
        package FailureRoleMyRole;
        use Moo::Role;
        use MooX::Options;
        option 't' => (is => 'rw');
        1;
    }
    {
        package FailureRole;
        use Moo;
        with 'FailureRoleMyRole';
        1;
    }
__EOF__
        ;
    like $@,
        qr/^Can't\sapply\sFailureRoleMyRole\sto\sFailureRole\s-\smissing\s_options_data,\s_options_config/x,
        "role could only be apply with a MooX::Options ready package"
}

{
    eval <<__EOF__
    {
        package t;
        use Moo;
        sub _options_data {};
        sub _options_config {};
        use MooX::Options;
        1;
    }
__EOF__
        ;
    like $@, qr/^Subroutine\s_options_data\sredefined/x, 'redefined methods';
    ok( !t->can('new_with_options'), 't has crash' );
}

{
    eval <<__EOF__
    {
        package MissingWith;
        use MooX::Options;
        1;
    }
__EOF__
        ;
    like $@,
        qr/^\QCan't find the method <with> in <MissingWith> ! Ensure to load a Role::Tiny compatible module like Moo or Moose before using MooX::Options.\E/,
        'missing with';
}

{
    eval <<__EOF__
    {
        package MissingAround;
        sub with {};
        use MooX::Options;
        1;
    }
__EOF__
        ;
    like $@,
        qr/^\QCan't find the method <around> in <MissingAround> ! Ensure to load a Role::Tiny compatible module like Moo or Moose before using MooX::Options.\E/,
        'missing with';
}

{
    eval <<__EOF__
    {
        package MissingHas;
        sub with {};
        sub around {};
        use MooX::Options;
        1;
    }
__EOF__
        ;
    like $@,
        qr/^\QCan't find the method <has> in <MissingHas> ! Ensure to load a Role::Tiny compatible module like Moo or Moose before using MooX::Options.\E/,
        'missing with';
}

done_testing;
