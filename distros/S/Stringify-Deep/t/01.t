#!/usr/bin/perl

use strict;
use warnings;

use Test::More            tests => 6;
use Storable              qw(dclone);
use Stringify::Deep       qw(deep_stringify);
use Data::Structure::Util qw(get_refs unbless);

my @tests = (
    {
        struct => {
            foo   => 'bar',
            bar   => Stringify::Deep::TestObject::Overloaded->new('obj1'),
            baz   => [ 1, 2, 3, 4, Stringify::Deep::TestObject::Overloaded->new('obj2') ],
            pizza => [ { cats => 'lol', refs => {
                array   => [],
                hash    => {},
                blessed => Stringify::Deep::TestObject::Overloaded->new('obj3'),
            } } ],
            unoverloaded => Stringify::Deep::TestObject->new('obj4'),
        },
        expected => {
            foo   => 'bar',
            bar   => 'obj1',
            baz   => [ 1, 2, 3, 4, 'obj2' ],
            pizza => [ { cats => 'lol', refs => {
                array   => [],
                hash    => {},
                blessed => 'obj3',
            } } ],
        },
        precheck => { unoverloaded => qr/^Stringify::Deep::TestObject/ },
    },
    {
        struct => {
            foo   => 'bar',
            bar   => Stringify::Deep::TestObject::Overloaded->new('obj1'),
            baz   => [ 1, 2, 3, 4, Stringify::Deep::TestObject::Overloaded->new('obj2') ],
            pizza => [ { cats => 'lol', refs => {
                array   => [],
                hash    => {},
                blessed => Stringify::Deep::TestObject::Overloaded->new('obj3'),
            } } ],
            unoverloaded => Stringify::Deep::TestObject->new('obj4'),
        },
        expected => {
            foo   => 'bar',
            bar   => 'obj1',
            baz   => [ 1, 2, 3, 4, 'obj2' ],
            pizza => [ { cats => 'lol', refs => {
                array   => [],
                hash    => {},
                blessed => 'obj3',
            } } ],
            unoverloaded => { str => 'obj4' },
        },
        params => { leave_unoverloaded_objects_intact => 1 },
    },
);

for my $test (@tests) {
    my $struct   = $test->{struct};
    my $expected = $test->{expected};
    my $params   = $test->{params};

    deep_stringify($struct, $params);

    if (my $precheck = $test->{precheck}) {
        for my $key (keys %$precheck) {
            ok( $struct->{$key} =~ /$precheck->{$key}/ );
            delete $struct->{$key};
        }
    }

    is_deeply($struct, $expected);
}

my $undef = undef;
deep_stringify(undef);
is $undef, undef;

my $foo = [];
deep_stringify($foo);
is_deeply( $foo, [] );

my $code = sub { 1 };
deep_stringify($code);
ok( $code =~ /^CODE/ );

package Stringify::Deep::TestObject::Overloaded;

use overload (
    '""' => 'stringify',
);
use base 'Stringify::Deep::TestObject';

package Stringify::Deep::TestObject;

sub new {
    my $class = shift;
    my $str   = shift;
    my $self  = { str => $str };
    bless $self, $class;
    return $self;
};

sub stringify {
    shift->{str};
}


