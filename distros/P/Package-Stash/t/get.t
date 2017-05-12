#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Package::Stash;
use Scalar::Util;

{
    BEGIN {
        my $stash = Package::Stash->new('Hash');
        my $val = $stash->get_symbol('%foo');
        is($val, undef, "got nothing yet");
    }
    {
        no warnings 'void', 'once';
        %Hash::foo;
    }
    BEGIN {
        my $stash = Package::Stash->new('Hash');
        my $val = $stash->get_symbol('%foo');
        is(ref($val), 'HASH', "got something");
        $val->{bar} = 1;
        is_deeply($stash->get_symbol('%foo'), {bar => 1},
                  "got the right variable");
        is_deeply(\%Hash::foo, {bar => 1},
                  "stash has the right variable");
    }
}

{
    BEGIN {
        my $stash = Package::Stash->new('Array');
        my $val = $stash->get_symbol('@foo');
        is($val, undef, "got nothing yet");
    }
    {
        no warnings 'void', 'once';
        @Array::foo;
    }
    BEGIN {
        my $stash = Package::Stash->new('Array');
        my $val = $stash->get_symbol('@foo');
        is(ref($val), 'ARRAY', "got something");
        push @$val, 1;
        is_deeply($stash->get_symbol('@foo'), [1],
                  "got the right variable");
        is_deeply(\@Array::foo, [1],
                  "stash has the right variable");
    }
}

{
    BEGIN {
        my $stash = Package::Stash->new('Scalar');
        my $val = $stash->get_symbol('$foo');
        is($val, undef, "got nothing yet");
    }
    {
        no warnings 'void', 'once';
        $Scalar::foo;
    }
    BEGIN {
        my $stash = Package::Stash->new('Scalar');
        my $val = $stash->get_symbol('$foo');
        is(ref($val), 'SCALAR', "got something");
        $$val = 1;
        is_deeply($stash->get_symbol('$foo'), \1,
                  "got the right variable");
        is($Scalar::foo, 1,
           "stash has the right variable");
    }
}

{
    BEGIN {
        my $stash = Package::Stash->new('Code');
        my $val = $stash->get_symbol('&foo');
        is($val, undef, "got nothing yet");
    }
    {
        no warnings 'void', 'once';
        sub Code::foo { }
    }
    BEGIN {
        my $stash = Package::Stash->new('Code');
        my $val = $stash->get_symbol('&foo');
        is(ref($val), 'CODE', "got something");
        is(prototype($val), undef, "got the right variable");
        &Scalar::Util::set_prototype($val, '&');
        is($stash->get_symbol('&foo'), $val,
           "got the right variable");
        is(prototype($stash->get_symbol('&foo')), '&',
           "got the right variable");
        is(prototype(\&Code::foo), '&',
           "stash has the right variable");
    }
}

{
    BEGIN {
        my $stash = Package::Stash->new('Io');
        my $val = $stash->get_symbol('FOO');
        is($val, undef, "got nothing yet");
    }
    {
        no warnings 'void', 'once';
        package Io;
        fileno(FOO);
    }
    BEGIN {
        my $stash = Package::Stash->new('Io');
        my $val = $stash->get_symbol('FOO');
        isa_ok($val, 'IO');
        my $str = "foo";
        open $val, '<', \$str;
        is(readline($stash->get_symbol('FOO')), "foo",
           "got the right variable");
        seek($stash->get_symbol('FOO'), 0, 0);
        {
            package Io;
            ::isa_ok(*FOO{IO}, 'IO');
            ::is(<FOO>, "foo",
                 "stash has the right variable");
        }
    }
}

{
    my $stash = Package::Stash->new('Hash::Vivify');
    my $val = $stash->get_or_add_symbol('%foo');
    is(ref($val), 'HASH', "got something");
    $val->{bar} = 1;
    is_deeply($stash->get_or_add_symbol('%foo'), {bar => 1},
              "got the right variable");
    no warnings 'once';
    is_deeply(\%Hash::Vivify::foo, {bar => 1},
              "stash has the right variable");
}

{
    my $stash = Package::Stash->new('Array::Vivify');
    my $val = $stash->get_or_add_symbol('@foo');
    is(ref($val), 'ARRAY', "got something");
    push @$val, 1;
    is_deeply($stash->get_or_add_symbol('@foo'), [1],
              "got the right variable");
    no warnings 'once';
    is_deeply(\@Array::Vivify::foo, [1],
              "stash has the right variable");
}

{
    my $stash = Package::Stash->new('Scalar::Vivify');
    my $val = $stash->get_or_add_symbol('$foo');
    is(ref($val), 'SCALAR', "got something");
    $$val = 1;
    is_deeply($stash->get_or_add_symbol('$foo'), \1,
              "got the right variable");
    no warnings 'once';
    is($Scalar::Vivify::foo, 1,
       "stash has the right variable");
}

{
    BEGIN {
        my $stash = Package::Stash->new('Io::Vivify');
        my $val = $stash->get_or_add_symbol('FOO');
        isa_ok($val, 'IO');
        my $str = "foo";
        open $val, '<', \$str;
        is(readline($stash->get_symbol('FOO')), "foo",
           "got the right variable");
        seek($stash->get_symbol('FOO'), 0, 0);
    }
    {
        package Io::Vivify;
        no warnings 'once';
        ::isa_ok(*FOO{IO}, 'IO');
        ::is(<FOO>, "foo",
             "stash has the right variable");
    }
}

done_testing;
