use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Warn;
use CHI;
use Scalar::Util qw(refaddr);
use Simple::Factory;

use lib 't/lib';

subtest "default is croak when error (default)" => sub {
    my $factory = Simple::Factory->new(
        Foo => {
            boom => sub { die "ops" }
        },
    );

    throws_ok {
        $factory->resolve('boom');
    }
    qr/cant resolve instance for key 'boom': ops/, 'should croak';
};

subtest "default is croak when error" => sub {
    my $factory = Simple::Factory->new(
        Foo => {
            boom => sub { die "ops" }
        },
        on_error => "croak",
    );

    throws_ok {
        $factory->resolve('boom');
    }
    qr/cant resolve instance for key 'boom': ops/, 'should croak';
};

subtest "default is confess when error" => sub {
    my $factory = Simple::Factory->new(
        Foo => {
            boom => sub { die "ops" }
        },
        on_error => "confess",
    );

    throws_ok {
        $factory->resolve('boom');
    }
    qr/cant resolve instance for key 'boom': ops/, 'should croak';
};

subtest "should substitute the on_error attr" => sub {
    my $factory = Simple::Factory->new(
        Foo => {
            boom => sub { die "ops" }
        },
        on_error => "carp",    # will carp and return undef
    );

    my $instance = -1;
    warning_like {
        $instance = $factory->resolve('boom');
    }
    { carped => qr/cant resolve instance for key 'boom': ops/ },
      'should not die, but carp';

    ok !defined $instance, 'resolve should return undef';
};

subtest "should return undef if on_error is 'undef'" => sub {
    my $factory = Simple::Factory->new(
        Foo => {
            boom => sub { die "ops" }
        },
        on_error => "undef",    # will return undef
    );

    my $instance = -1;
    lives_ok {
        $instance = $factory->resolve('boom');
    }
    'should not die';

    ok !defined $instance, 'resolve should return undef';
};

subtest "should substitute the on_error attr from coderef" => sub {
    my $other = bless {}, 'other';
    my $factory = Simple::Factory->new(
        Foo => {
            boom => sub { die "ops" }
        },
        on_error => sub { $other },    # will return other obj
    );

    my $instance = -1;
    lives_ok {
        $instance = $factory->resolve('boom');
    }
    'should not die';

    ok defined $instance, 'resolve should NOT return undef';
    is refaddr($instance), refaddr($other), 'should return other';
};

subtest "should be able to call the fallback" => sub {
    my $factory = Simple::Factory->new(
        Foo      => { one => 1 },
        fallback => 2,
    );

    my $instance = $factory->get_fallback_for_key("two");

    isa_ok $instance, 'Foo', 'instance';
    is $instance->value, 2, 'should resolve with fallback';
};

subtest "can call fallback from on_error" => sub {
    my $factory = Simple::Factory->new(
        Foo => {
            boom => sub { die "ops" }
        },
        fallback => -1,
        on_error => "fallback"
        ,    # sub { $_[0]->{factory}->get_fallback_for_key( $_[0]->{key} ); },
    );

    my $instance;

    lives_ok {
        $instance = $factory->resolve("two");
    }
    'should not die';

    isa_ok $instance, 'Foo', 'instance';
    is $instance->value, -1, 'should get fallback in case of error';
};

subtest "can call fallback from on_error" => sub {
    my $factory = Simple::Factory->new(
        Foo => {
            boom => sub { die "ops" }
        },
        fallback => sub { die "fallback" },
        on_error => "fallback"
        ,    #sub { $_[0]->{factory}->get_fallback_for_key( $_[0]->{key} ); },
    );

    throws_ok {
        $factory->resolve("two");
    }
    qr/fallback/, 'should die';
};

subtest "should croak if string on_error if not croak, carp of fallback" =>
  sub {
    throws_ok {
        Simple::Factory->new( Foo => { a => 1 }, on_error => "boom" );
    }
qr/coercion for "on_error" failed: can't coerce on_error 'boom', please use: carp, confess, croak, fallback or undef/,
      'should die';
  };

done_testing;
