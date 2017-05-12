use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::MockObject;

use CHI;
use Simple::Factory;

use lib 't/lib';

subtest "eager should be false by default" => sub {
    my $factory;
    lives_ok {
        $factory = Simple::Factory->new(
            Foo => {
                a => sub { die "ops" }
            }
        );
    }
    'should not die';

    ok !$factory->eager, 'attr eager should be false';
};

subtest "should die on constructor if eager is true" => sub {
    throws_ok {
        Simple::Factory->new(
            Foo => {
                a => sub { die "ops" }
            },
            eager => 1
        );
    }
    qr/cant resolve instance for key 'a': ops/, 'should die';
};

subtest "eager should store data in the cache" => sub {
    my $cache = CHI->new( driver => "RawMemory", datastore => {} );
    my $factory =
      Simple::Factory->new( Foo => { a => 1 }, cache => $cache, eager => 1 );

    my $instance = $cache->get('Foo:a')->[0];

    isa_ok $instance, 'Foo', 'instance';
    is $instance->value, 1, 'value should be 1';
};

done_testing;
