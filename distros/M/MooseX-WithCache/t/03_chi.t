use strict;
use Test::More;
use Test::Exception;
use IO::Socket::INET;
use Moose::Meta::Class;

{
    package Hoge;
    use MooseX::WithCache;
}

{
    eval "use CHI";
    if ($@) {
        plan(skip_all => "CHI not available");
    } else {
        plan(tests => 9);
    }
}

{
    my $class = Moose::Meta::Class->create_anon_class(
        superclasses => [ 'Moose::Object' ],
        roles => [
            'MooseX::WithCache' => { backend => 'CHI' }
        ],
    );

    my $object = $class->new_object(
        cache => CHI->new(
            driver => 'Memory',
        ),
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
        lives_ok { $object->cache_del($key) }
            "delete key '$key' to purge";
    }
}
