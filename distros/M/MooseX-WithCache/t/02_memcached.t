use strict;
use Test::More;
use Test::Exception;
use IO::Socket::INET;
use Moose::Meta::Class;

our @MEMDTYPES;

{
    package Hoge;
    use MooseX::WithCache;
}

BEGIN
{
    my $socket = IO::Socket::INET->new(
        PeerPort => '11211',
        PeerAddr => '127.0.0.1',
    );

    if (! $socket) {
        plan(skip_all => "no memcached server found");
    } else {
        my $tests = 0;
        foreach my $class (qw(Cache::Memcached Cache::Memcached::Fast Cache::memcached::libmemcached)) {
            eval "require $class";
            next if $@;

            diag("found $class...");
            $tests += 54;
            push @MEMDTYPES, $class;
        }

        if (! @MEMDTYPES) {
            plan(skip_all => "No memcached client found");
        } else {
            plan(tests => $tests);
        }
    }
}

foreach my $memd (@MEMDTYPES) {
    diag("testig with $memd...");
    my $class = Moose::Meta::Class->create_anon_class(
        superclasses => [ 'Moose::Object' ],
        roles        => [ 'MooseX::WithCache' => { backend => 'Cache::Memcached' } ],
    );

    foreach my $cache_build_method (qw( object coerce )) {
        my $object;

        if ($cache_build_method eq 'object') {
            diag("Specifying with memcached object...");
            $object = $class->new_object(
                cache => $memd->new({
                    servers => [ '127.0.0.1:11211' ],
                    namespace => join('.', rand(), time, $$, {}),
                })
            );
        } else {
            diag("Specifying with hashref ...");
            $object = $class->new_object(
                cache => {
                    servers => [ '127.0.0.1:11211' ],
                    namespace => join('.', rand(), time, $$, {}),
                } 
            );
        }

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
    
        {
            my %data = (
                a => 1,
                b => 2,
                c => 3,
                d => 4
            );
    
            while(my($key, $value) = each %data) {
                $object->cache_set($key, $value);
            }
    
            lives_and {
                my @keys = keys %data;
                my @ret  = $object->cache_get_multi(@keys);
    
                is( scalar @ret, scalar @keys, "got the same number of values" );
                is_deeply( \@ret, [ @data{@keys} ], "data validates" );
            } "get_multi";
    
            lives_and {
                my @keys = keys %data;
                push @keys, 'missing';
                my @ret  = $object->cache_get_multi(@keys);
    
                is( scalar @ret, scalar @keys - 1, "got the less results than requested" );
                is_deeply( \@ret, [ @data{ keys %data } ], "data validates" );
    
                my $ret  = $object->cache_get_multi(@keys);
                is( scalar keys(%{$ret->{results}}) + 1, scalar @keys, "got the less results than requested" );
                is_deeply( $ret->{results}, \%data, "data validates" );
                is_deeply( $ret->{missing}, [ 'missing' ], "missing key validates" );
            } "get_multi with missing keys";
        }
    }
}
