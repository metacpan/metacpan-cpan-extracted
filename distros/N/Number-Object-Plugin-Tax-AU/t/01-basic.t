#!/usr/bin/env perl

use Test::More qw/no_plan/;
use Number::Object;

my $load_plugins = qq{ 
  Number::Object->load_components('Autocall');
};

ok( eval "$load_plugins; 1", "loaded plugins" );

my $load_components = qq{
  Number::Object->load_plugins('Tax::AU::GST');
};

ok( eval "$load_components; 1", "loaded components" );

my $num1 = Number::Object->new(99.95);

isa_ok($num1, 'Number::Object');

is( "$num1", 99.95, "num1 correctly stringified" );
is( $num1 + 0, 99.95, "num1 correctly numified" );

is( $num1->value,       99.95, 'num1 value is correct' );
is( $num1->tax,         9.995, 'num1->tax is correct'  );
is( $num1->include_tax, 109.945, 'num1->include_tax is correct' );
is( sprintf('%.04f', $num1->deduct_tax), 90.8636, 'num1->deduct_tax is correct' );
