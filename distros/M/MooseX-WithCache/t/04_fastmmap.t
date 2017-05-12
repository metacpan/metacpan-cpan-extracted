use strict;
use Test::More;
use Test::Exception;
use IO::Socket::INET;
use Moose::Meta::Class;

{
    package Hoge;
    use MooseX::WithCache;
}

BEGIN
{
    eval { require Cache::FastMmap };
    if ( $@ ) {
        plan(skip_all => "no Cache::FastMmap found");
    } else {
        plan(tests => 20);
    }
}

{
    my $class = Moose::Meta::Class->create_anon_class(
        superclasses => [ 'Moose::Object' ],
        roles => [ 'MooseX::WithCache' => { backend => 'Cache::FastMmap' } ]
    );

    my $object = $class->new_object(
        cache => Cache::FastMmap->new,
    );


    {
        my $value = time();
        my $key   = 'foo';
        lives_ok { $object->cache_del($key) }
            "delete key '$key' first to make sure";
        lives_ok { $object->cache_set($key => $value) }
            "set value '$key' to '$value'";
        lives_and { 
            my $v = $object->cache_get($key);
            is($v, $value, "value gotten from cache '$v' should match '$value'");
        } "get value '$key' to '$value' should live";
        lives_ok { $object->cache_del($key) }
            "delete key '$key' to purge";
    }

    {
        require MooseX::WithCache::KeyGenerator::DumpChecksum;
        $object->cache_key_generator(
            MooseX::WithCache::KeyGenerator::DumpChecksum->new
        );
        my $value = time();
        my $key   = [ qw(1 2 3), { foo => 'bar' } ];
        lives_ok { $object->cache_del($key) }
            "delete key '$key' first to make sure";
        lives_ok { $object->cache_set($key => $value) }
            "set value '$key' to '$value'";
        lives_and { 
            my $v = $object->cache_get($key);
            is($v, $value, "value gotten from cache '$v' should match '$value'");
        } "get value '$key' to '$value' should live";
        lives_and { 
            my $v = $object->cache_get([ qw(1 2 3), { foo => 'bar' } ]);
            is($v, $value, "value gotten from cache '$v' should match '$value' (same structure, different object)");
        } "get value '$key' to '$value' should live (same structure, different key object)";

        lives_and {
            $object->cache_disabled(1);
            ok( ! $object->cache_get($key), "cache disabled, fetch should fail" );
            $object->cache_set($key, "foo");
            ok( ! $object->cache_get($key), "cache disabled, fetch should fail (even if cache_set was called)" );
            $object->cache_set($key, "foo");
            ok( ! $object->cache_get($key), "cache disabled, fetch should fail (even if cache_set was called)" );

            $object->cache_set($key, "foo");
            $object->cache_disabled(0);
            is($object->cache_get($key), $value, "cache wasn't changed while it was disabled");

        } "no errors while testing cache disable";
        $object->cache_disabled(0);

        lives_ok { $object->cache_del($key) }
            "delete key '$key' to purge";
    }

    { # memcached specific
        my $value = time();
        my $key   = [ qw(incr decr test) ];

        $object->cache_set($key, $value);
        is( $object->cache_incr($key), $value + 1, "incr returns correct result");
        is( $object->cache_get($key), $value + 1, "effect of incr is saved" );
        is( $object->cache_decr($key), $value, "decr returns correct result");
        is( $object->cache_get($key), $value, "effect of decr is saved" );

        lives_and {
            $object->cache_disabled(1);

            ok( ! $object->cache_incr($key), "incr while cache disabled" );
            ok( ! $object->cache_decr($key), "decr while cache disabled" );
        } "no errors while testing cache disable";
        $object->cache_disabled(0);
        lives_ok { $object->cache_del($key) }
            "delete key '$key' to purge";
    }
}
