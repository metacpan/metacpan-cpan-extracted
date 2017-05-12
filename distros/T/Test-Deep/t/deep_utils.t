use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use Test::Deep qw( cmp_deeply descend render_stack methods deep_diag );

{
  my $a = [];

  my $base = Test::Deep::_td_reftype($a);
  is($base, "ARRAY", "_td_reftype base ref");
}

{
  my $a = bless [], "A::Class";

  my $base = Test::Deep::_td_reftype($a);
  is($base, "ARRAY", "_td_reftype base obj");
}

{
  my $a = qr/a/;

  my $base = Test::Deep::_td_reftype($a);
  is($base, ($] < 5.011 ? "Regexp" : "REGEXP"), "class_base base regexp");
}

done_testing;
