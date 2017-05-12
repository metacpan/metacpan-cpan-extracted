use strict;
use warnings;

use Test::More 0.96;

{
  package TypeHolder;
  use Moose::Util::TypeConstraints;
  subtype 'Exes', as 'Str', where { length > 0 && $_ !~ /[^X]/ };
  subtype 'XL', as 'Int';
  coerce 'XL', from 'Exes', via { length };
}

{
  package Object;
  use Moose;
  with(
    'MooseX::OneArgNew' => {
      type     => 'XL',
      init_arg => 'size',
      coerce   => 1,
    },
  );

  has size => (is => 'ro', isa => 'XL');
}

{
  my $obj = Object->new('XXX');
  isa_ok($obj, 'Object');
  is($obj->size, 3, "coercing one-arg-new worked");
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
  my $obj = eval { Object->new('ten') };
  my $err = $@;
  ok(! $obj, "couldn't construct Object with non-{} non-Int single-arg new");
  like($err, qr/parameters to new/, "...error message seems plausible");
}

done_testing;
