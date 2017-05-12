use strict;
use warnings;
use String::Template qw/missing_values/;
use Test::More qw/no_plan/;

my $template = "<hello>, <world>";

my ($hello) = missing_values( $template, { world => 'foo' } );
cmp_ok $hello, 'eq', 'hello', "missing word";

ok !missing_values( $template, { hello => "foo", world => "bar" } ), "not missing values";

ok !missing_values( $template, { hello => undef, world => "bar" } ), "not missing values";

ok missing_values( $template, { hello => undef, world => "bar" }, 1 ), "missing some values";

my @lots = missing_values( "<hello%2d> <world!a> <out#x> <there:y>", {} );
is_deeply [ sort @lots ],
          [ qw/hello out there world/ ],
          "missing values with modifiers";
