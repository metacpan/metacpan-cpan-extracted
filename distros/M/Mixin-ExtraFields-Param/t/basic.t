#!perl -T
use strict;
use warnings;

use Test::More tests => 11;

{
  package Widget::Parameterized;
  use Mixin::ExtraFields::Param -fields => { driver => 'HashGuts' };

  sub new { bless {} => shift; }
  sub id { 0 + $_[0] }
}

my $widget = Widget::Parameterized->new;

isa_ok($widget, 'Widget::Parameterized');
can_ok($widget, 'param');

{
  my @names = $widget->param;
  cmp_ok(@names, '==', 0, "there are zero params to start with");
}

is(
  $widget->param('flavor'),
  undef,
  "a specific param is also unset",
);

{
  my @names = $widget->param;
  cmp_ok(@names, '==', 0, "checking on a given param didn't create it");
}

is(
  $widget->param(flavor => 'teaberry'),
  'teaberry',
  "we set a param and got its value back",
);

is(
  $widget->param('flavor'),
  'teaberry',
  "...and that value stuck",
);

{
  my @names = $widget->param;
  cmp_ok(@names, '==', 1, "so now there is one param");
}

{
  my @values = $widget->param(size => 'big', limits => undef);
  cmp_ok(@values, '==', 2, "we get back two values");
  is_deeply(\@values, [ 'big', undef ], "...and they're the two set set");

  my @names = $widget->param;
  cmp_ok(@names, '==', 3, "we set two more, now there are three");
}
