use Test::More tests => 18;
use PGObject;
use Test::Exception;

is(PGObject->register_type(pg_type => 'foo', perl_class => 'Foo'), 1,
       "Basic type registration");
is(PGObject->register_type(pg_type => 'foo', perl_class => 'Foo'), 1,
       "Repeat type registration, same type");
is(PGObject->register_type(pg_type => 'foo', perl_class => 'Foo2'), 0,
       "Repeat type registration, different type, fails");

throws_ok{PGObject->register_type(
          pg_type => 'foo', perl_class => 'Foo2', registry => 'bar')
} qr/Registry.*exist/, 
'Correction exception thrown, reregistering in nonexistent registry.';

is(PGObject->unregister_type(pg_type => 'foo'), 1, 'Unregister type, try 1');
is(PGObject->unregister_type(pg_type => 'foo'), 0, 'Unregister type, try 0');
is(PGObject->register_type(pg_type => 'foo', perl_class => 'Foo2'), 1,
       "Repeat type registration, different type, succeeds now");

throws_ok{PGObject->unregister_type(
          pg_type => 'foo', registry => 'bar')
} qr/Registry.*exist/, 
'Correction exception thrown, unregistering in nonexisting registry.';

is(PGObject->new_registry('bar'), 1, 'new registry succeeds first try');
is(PGObject->new_registry('bar'), 2, 'new registry already exists status');

is(PGObject->register_type(
             pg_type => 'foo', perl_class => 'Foo', registry => 'bar'
   ), 1,
       "Basic type registration");
is(PGObject->register_type(
             pg_type => 'foo', perl_class => 'Foo', registry => 'bar'
   ), 1,
       "Repeat type registration, same type");
is(PGObject->register_type(
             pg_type => 'foo', perl_class => 'Foo2', registry => 'bar'
), 0,
       "Repeat type registration, different type, fails");

my $test_registry = {
   default => { foo => 'Foo2',
              },
   bar     => {
                foo => 'Foo',
         
               },
};

is(PGObject->get_registered(registry => 'bar', pg_type => 'bar'), undef,
   "get_registered_type returns undef on non-registered type");
is(PGObject->get_registered(registry => 'default', pg_type => 'foo'), 'Foo2',
   "get_registered_type returns Foo on registered type, explicit default reg.");
is(PGObject->get_registered(registry => 'bar', pg_type => 'foo'), 'Foo',
   "get_registered_type returns Foo on registered type, bar reg.");
is(PGObject->get_registered(pg_type => 'foo'), 'Foo2',
   "get_registered_type returns Foo on registered type, implicit default reg.");

is_deeply(PGObject->get_type_registry(), $test_registry, 'Correct registry');
