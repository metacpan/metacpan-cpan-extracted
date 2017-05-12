
package testpkg;
use PGObject::Type::Composite;

package main;
use Test::More tests => 7;

my @columns = (
             { attname => 'foo', atttype => 'text' },
             { attmame => 'bar', atttype => 'int4' },
             { attname => 'baz', atttype => 'int8' },
);

my @cols2;
ok(@cols2 = testpkg->initialize(
      columns => \@columns
   ), 'Successfully initialized');

is($column[$_]->{attname}, $col2[$_]->{attname}, "Correct name for col $_") 
   for 0 .. $#columns;
is($column[$_]->{atttype}, $col2[$_]->{atttype}, "Correct type for col $_") 
   for 0 .. $#columns;
