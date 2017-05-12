package testpkg;
use PGObject::Type::Composite;

package main;
use Test::More tests => 14;

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
my $string3 = qw(("foo,bar",133,42222));

ok(my $obj1 = testpkg->from_db($string), 'First object deserialized');
ok(my $obj2 = testpkg->from_db($string2), 'First object deserialized');
ok(my $obj3 = testpkg->from_db($string3), 'First object deserialized');

is($obj1->{foo}, 'foo', 'obj1 foo is foo');
is($obj1->{bar}, '3', 'obj1 bar is 3');
is($obj1->{baz}, '4333', 'obj1 baz is 4333');

is($obj2->{foo}, 'bar', 'obj2 foo is bar');
is($obj2->{bar}, 133, 'obj2 bar is 133');
is($obj2->{baz}, 444, 'obj2 baz is 444');

is($obj3->{foo}, 'foo,bar', 'obj3 foo is foo,bar');
is($obj3->{bar}, 133, 'obj3 bar is 133');
is($obj3->{baz}, 42222, 'obj3 baz is 42222');

use Data::Dumper;
warn Dumper($obj3);
