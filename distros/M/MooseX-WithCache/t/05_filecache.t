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
    eval { require Cache::FileCache };
    if ( $@ ) {
        plan(skip_all => "no Cache::FileCache found");
    } else {
        plan(tests => 13);
    }
}

{
    my $class = Moose::Meta::Class->create_anon_class(
        superclasses => [ 'Moose::Object' ],
        roles => [ 'MooseX::WithCache' => { backend => 'Cache::FileCache' } ]
    );

    my $object = $class->new_object(
        cache => Cache::FileCache->new,
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
}
