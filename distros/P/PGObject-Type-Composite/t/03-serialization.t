package testpkg;
use PGObject::Type::Composite;

package main;
use Test::More tests => 8;

my @columns = (
             { attname => 'foo', atttype => 'text' },
             { attname => 'bar', atttype => 'int4' },
             { attname => 'baz', atttype => 'int8' },
);

my @cols2;
ok(@cols2 = testpkg->initialize(
      columns => \@columns
   ), 'Successfully initialized');

is(scalar @cols2, 3, '3 columns set');

my $string = "(foo,3,4333)";
my $string2 = "(bar,133,444)";
my $string3 = q(("foo,bar",133,42222));

ok(my $obj1 = testpkg->from_db($string), 'First object deserialized');
ok(my $obj2 = testpkg->from_db($string2), 'First object deserialized');
ok(my $obj3 = testpkg->from_db($string3), 'First object deserialized');

is($obj1->to_db->{value}, $string, 'First object serialized correctly');
is($obj2->to_db->{value}, $string2, 'Second object serialized correctly');
is($obj3->to_db->{value}, $string3, 'Third object serialized correctly');
