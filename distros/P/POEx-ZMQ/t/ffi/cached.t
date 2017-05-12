use Test::More;
use strict; use warnings FATAL => 'all';


use POEx::ZMQ::FFI::Cached;
use POEx::ZMQ::FFI::Callable;

my $obj = POEx::ZMQ::FFI::Callable->new;

POEx::ZMQ::FFI::Cached->set( Foo => bar => $obj );
POEx::ZMQ::FFI::Cached->set( Bar => foo => $obj );
my $retrieved = POEx::ZMQ::FFI::Cached->get(Foo => 'bar');
ok $retrieved == $obj, 'Cache set/get ok';

ok scalar keys %POEx::ZMQ::FFI::Cached::Cache == 2,
  'two items in cache ok';

POEx::ZMQ::FFI::Cached->clear(Foo => 'bar');

ok scalar keys %POEx::ZMQ::FFI::Cached::Cache == 1,
  'clear ok';

POEx::ZMQ::FFI::Cached->clear_all;
ok scalar keys %POEx::ZMQ::FFI::Cached::Cache == 0,
  'clear_all ok';

done_testing
