use strict;
use warnings;

use Test::More;

my @mods = qw(
  Moose::Meta::Attribute::Custom::Trait::Indexed
  MooseX::AttributeIndexes
  MooseX::AttributeIndexes::Meta::Attribute::Trait::Indexed
  MooseX::AttributeIndexes::Provider
  MooseX::AttributeIndexes::Provider::FromAttributes
);

plan tests => scalar @mods;

for my $mod (@mods) {
  if (
    eval "
    package TestBox::${mod};
    use ${mod};
    1;
  "
    )
  {
    ok( 1, "use ${mod}" );
  }
  else {
    ok( 0, "use ${mod}" );
    diag("$@");
  }
}

