Redis ResourcePool
==================

The library provides a ResourcePool wrapper for Redis.


Usage
=====

    use ResourcePool::Resource::Redis;
    use ResourcePool::Factory;

    my $factory = ResourcePool::Factory::Redis->new('server' => '127.0.0.1');
    my $pool = ResourcePool->new($factory);

    my $redis = $pool->get();
    $redis->set("foo", "bar);
    $pool->free($redis);


Installation
============

Module::Build is used as the build system for this library. The typical
procedure applies:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install


Documentation
=============

The library contains embedded POD documentation. Any of the POD tools
can be used to generate documentation, such as pod2html


License
=======

The library is licensed under the MIT license. Please read the LICENSE
file for details.

