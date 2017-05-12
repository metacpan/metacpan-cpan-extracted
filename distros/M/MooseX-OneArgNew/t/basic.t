use strict;
use warnings;

use Test::More 0.96;

{
  package Object;
  use Moose;
  with(
    'MooseX::OneArgNew' => {
      type     => 'Int',
      init_arg => 'size',
    },
    'MooseX::OneArgNew' => {
      type     => 'ArrayRef',
      init_arg => 'nums',
    },
  );

  has size => (is => 'ro', isa => 'Int');
  has nums => (is => 'ro', isa => 'ArrayRef[Int]');
}

{
  my $obj = Object->new(10);
  isa_ok($obj, 'Object');
  is($obj->size, 10, "one-arg-new worked");
}

{
  my $obj = Object->new({ size => 10 });
  isa_ok($obj, 'Object');
  is($obj->size, 10, "hashref args to ->new worked");
}

{
  my $obj = Object->new(size => 10);
  isa_ok($obj, 'Object');
  is($obj->size, 10, "pair args to ->new worked");
}

{
  my $obj = Object->new([ 1, 2, 3 ]);
  isa_ok($obj, 'Object');
  is($obj->size, undef, 'no size after ->new([...])');
  is_deeply($obj->nums, [1, 2, 3], "arrayref args to ->new worked");
}

{
  my $obj = eval { Object->new('ten') };
  my $err = $@;
  ok(! $obj, "couldn't construct Object with non-{} non-Int single-arg new");
  like($err, qr/parameters to new/, "...error message seems plausible");
}

done_testing;
