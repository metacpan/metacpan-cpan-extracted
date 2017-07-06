#!/usr/bin/env perl
use strict;
use warnings all => 'FATAL';
use Test::More;
use Test::Trap;
use Carp;

local $ENV{TEST_FORCE_COLUMN_SIZE} = 78;

eval <<__EOF__
    package FailureNegatableWithFormat;
    use Moo;
    use MooX::Options;

    option fail => (
        is => 'rw',
        negatable => 1,
        format => 'i',
    );

    1;
__EOF__
    ;
like $@,
    qr/^Negatable\sparams\sis\snot\susable\swith\snon\sboolean\svalue,\sdon't\spass\sformat\sto\suse\sit\s\!/x,
    "negatable and format are incompatible";

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
    qr/^Negatable\sparams\sis\snot\susable\swith\snon\sboolean\svalue,\sdon't\spass\sformat\sto\suse\sit\s\!/x,
    "negatable and format are incompatible";

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
    like $@, qr/^\QCan't find the method <with> in <MissingWith>!
Ensure to load a Role::Tiny compatible module like Moo or Moose before using MooX::Options.\E/,
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
    like $@, qr/^\QCan't find the method <around> in <MissingAround>!
Ensure to load a Role::Tiny compatible module like Moo or Moose before using MooX::Options.\E/,
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
    like $@, qr/^\QCan't find the method <has> in <MissingHas>!
Ensure to load a Role::Tiny compatible module like Moo or Moose before using MooX::Options.\E/,
        'missing with';
}

{
    eval <<__EOF__
    {
        package IllegalShortEnding;
        use Moo;
        use MooX::Options;
        option 'legal' => (is => 'rw', short => 'l!');
        1;
    }
    IllegalShortEnding->new_with_options;
__EOF__
        ;
    like $@,
        qr/^cmdline\sargument\s'legal|l!'\sshould\send\swith\sa\sword\scharacter/x,
        'illegal short trailing char causes reasonable failure';
}

{
    eval <<__EOF__
    {
        package ShortOptionConflict;
        use Moo;
        use MooX::Options;
	option 'l' => (is => 'rw');
        option 'legal' => (is => 'rw', short => 'l');
        1;
    }
    ShortOptionConflict->new_with_options;
__EOF__
        ;
    like $@,
        qr/^There\sis\salready\san\soption\s'l'\s\-\scan't\suse\sit\sto\sshorten\s'legal'/x,
        'short conflict with existing option';
}

{
    eval <<__EOF__
    {
        package ShortShortConflict;
        use Moo;
        use MooX::Options;
	option 'list' => (is => 'rw', short => 'l');
        option 'legal' => (is => 'rw');
        1;
    }
    ShortShortConflict->new_with_options;
__EOF__
        ;
    like $@,
        qr/^There\sis\salready\san\sabbreviation\s'l'\s\-\scan't\suse\sit\sto\sshorten\s'list'/x,
        'short conflict with previous option abbreviation';
}

trap {
    eval <<__EOF__
    {
        package NonNegatableNegated;
        use Moo;
        use MooX::Options;
        option 'legal' => (is => 'rw');
        1;
    }
    local \@ARGV = ('--no-legal');
    NonNegatableNegated->new_with_options;
__EOF__
        ;
};
like $trap->stderr, qr/^Unknown\soption:\sno_legal/x, 'Unexisting negation';

done_testing;
