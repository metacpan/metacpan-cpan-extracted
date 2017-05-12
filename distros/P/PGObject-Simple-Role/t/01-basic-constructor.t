
#########

package test1;
use Moo;
with('PGObject::Simple::Role');

has 'id' => (is => 'ro');
has 'foo' => (is => 'ro');
has 'bar' => (is => 'ro');
has 'baz' => (is => 'ro');

package test2;
use Moo;
with('PGObject::Simple::Role');

has 'id' => (is => 'ro');

sub _get_dbh {
    return 1;
}

##########

package main;

use Test::More tests => 10;
use Test::Exception;
use DBI;

my %args = (
   id => 3, 
   foo => 'test1',
   bar => 'test2',
   baz => 33,
   biz => 112,
);

my $obj;

lives_ok {$obj = test1->new(%args)} 'created new object without crashing';
ok(eval {$obj->isa('test1')}, 'ISA test passed');
is($obj->id, 3, 'attribute id passed');
is($obj->foo, 'test1', 'attribute foo passed');
is($obj->bar, 'test2', 'attribute bar passed');
is($obj->baz, 33, 'attribute baz passed');
ok(!defined($obj->can('biz')), 'No dbh method exists');
throws_ok {$obj->_build__DBH(1)} qr/Subclasses MUST set/, 
          'Threw exception, "Subclasses MUST set"';

lives_ok {$obj = test2->new(%args)} 'created new object without crashing';
throws_ok {$obj->_DBH} qr/Expected a database handle/, 
          'Threw exception, "Expected a database handle"';
