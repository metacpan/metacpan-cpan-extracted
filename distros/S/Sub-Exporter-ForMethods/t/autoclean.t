#!perl
use strict;
use warnings;

use Test::More;

BEGIN {
  unless (eval { require namespace::autoclean }) {
    plan skip_all => 'namespace::autoclean required for this test';
  }
}

plan 'no_plan';

use lib 't/lib';

{
  package Class;
  use namespace::autoclean;
  use TestMexp
    foo => { -as => 'bar' },
    foo => { -as => 'baz' };

  use TestDexp
    foo => { -as => 'quux' };

  sub new { bless {} }
}

{
  my $mess = eval { Class->new->bar };
  like($mess, qr{Class::bar}, "bar method appears under its own name");
}

{
  my $mess = eval { Class->new->baz };
  like($mess, qr{Class::baz}, "baz method appears under its own name");
}

{
  my $mess  = eval { Class->new->quux };
  my $error = $@;

  is($mess, undef, "we fail to get any result from autocleaned ->quux");
  like($error, qr{can't locate \S+ method .quux}i, '...method not found');
}

1;
