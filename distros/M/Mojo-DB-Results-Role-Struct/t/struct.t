use Mojo::Base -strict;
use Scalar::Util 'blessed';
use Test::More;

my @cols;
{
  package My::Test::Results;

  use Mojo::Base -base;
  use Mojo::Collection 'c';
  use Role::Tiny::With;

  has rows => sub { [] };
  sub columns { \@cols }
  sub array { shift @{$_[0]->rows} }
  sub arrays { c(@{$_[0]->rows}) }

  with 'Mojo::DB::Results::Role::Struct';
}

@cols = qw(foo bar foo.bar "bar");

my $results = My::Test::Results->new(rows => [[qw(a b c d)]]);
is $results->structs->size, 1, 'one row';
my $row = $results->struct;
my $struct_name = blessed $row;
is $row->foo, 'a', 'right value';
is $row->bar, 'b', 'right value';
my $name = 'foo.bar';
is $row->$name, 'c', 'right value';
$name = '"bar"';
is $row->$name, 'd', 'right value';
ok !defined $results->struct, 'no more rows';

$results = My::Test::Results->new(rows => [[qw(e f g h)], [qw(1 2 3 4)]]);
is $results->structs->size, 2, 'two rows';
$row = $results->struct;
is blessed($row), $struct_name, 'same struct definition';
is $row->foo, 'e', 'right value';
is $row->bar, 'f', 'right value';
$name = 'foo.bar';
is $row->$name, 'g', 'right value';
$name = '"bar"';
is $row->$name, 'h', 'right value';
$row = $results->struct;
is blessed($row), $struct_name, 'same struct definition';
is $row->foo, 1, 'right value';
is $row->bar, 2, 'right value';
$name = 'foo.bar';
is $row->$name, 3, 'right value';
$name = '"bar"';
is $row->$name, 4, 'right value';
ok !defined $results->struct, 'no more rows';

$results = My::Test::Results->new;
is_deeply $results->structs, [], 'no rows';
ok !defined $results->struct, 'no rows';

@cols = ();
$results = My::Test::Results->new(rows => [[]]);
is $results->structs->size, 1, 'one row';
$row = $results->struct;
ok defined $row, 'empty struct';
isnt blessed($row), $struct_name, 'different struct definition';
ok !eval { $row->foo; 1 }, 'no foo accessor';

done_testing;
