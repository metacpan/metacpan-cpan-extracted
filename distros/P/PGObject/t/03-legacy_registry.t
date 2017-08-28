package Foo;

sub from_db { }; # needs to exist to be a valid class for registration

package Foo2;

sub from_db { }; # needs to exist to be a valid class for registration

package main;

use Test::More tests => 14;
use PGObject;
use Test::Exception;


lives_ok(sub {PGObject->register_type(pg_type => 'foo', perl_class => 'Foo') },      "Basic type registration");
lives_ok(sub {PGObject->register_type(pg_type => 'foo', perl_class => 'Foo')},
       "Repeat type registration, same type");
throws_ok(sub {PGObject->register_type(pg_type => 'foo', 
    perl_class => 'main')}, qr/different target/,
    "Repeat type registration, different type, fails");
throws_ok(sub {PGObject->register_type(pg_type => 'foo2', 
    perl_class => 'Foobar123')}, qr/not yet loaded/,
    "Cannot register undefined type");


throws_ok{PGObject->register_type(
          pg_type => 'foo', perl_class => 'Foo2', registry => 'bar')
} qr/Registry.*exist/, 
'Correction exception thrown, reregistering in nonexistent registry.';

ok(PGObject->unregister_type(pg_type => 'foo'), 'Unregister type, try 1');
dies_ok(sub {PGObject->unregister_type(pg_type => 'foo')}, 'Unregister type, try 2');
is(PGObject->register_type(pg_type => 'foo', perl_class => 'Foo2'), 1,
       "Repeat type registration, different type, succeeds now");

throws_ok{PGObject->unregister_type(
          pg_type => 'foo', registry => 'bar')
} qr/Registry.*exist/, 
'Correction exception thrown, unregistering in nonexisting registry.';

lives_ok(sub {PGObject->new_registry('bar') }, 'new registry succeeds first try');
lives_ok(sub {PGObject->new_registry('bar') }, 'new registry already exists, lives');

is(PGObject->register_type(
             pg_type => 'foo', perl_class => 'Foo', registry => 'bar'
   ), 1,
       "Basic type registration");
is(PGObject->register_type(
             pg_type => 'foo', perl_class => 'Foo', registry => 'bar'
   ), 1,
       "Repeat type registration, same type");
dies_ok( sub {PGObject->register_type(
             pg_type => 'foo', perl_class => 'Foo2', registry => 'bar'
) },
       "Repeat type registration, different type, fails");

my $test_registry = {
   default => { foo => 'Foo2',
              },
   bar     => {
                foo => 'Foo',
         
               },
};

