use strict;
use warnings;
use Test::More tests => 7;

{
  package Class;

  use Moose::Micro '$foo @bar; $baz $!quux';
}

can_ok('Class', qw(foo bar baz _quux));
my $obj = Class->new(foo => 1, bar => [2,3], baz => 4);
isa_ok($obj, 'Class');
is($obj->foo, 1);
is_deeply($obj->bar, [2,3]);
is($obj->baz, 4);

eval { $obj->bar(1) };
like $@, qr/does not pass the type constraint/;

eval { $obj->foo([]) };
like $@, qr/does not pass the type constraint/;
