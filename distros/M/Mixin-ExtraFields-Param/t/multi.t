#!perl -T
use strict;
use warnings;

use Test::More tests => 15;

{
  package Widget::Parameterized;
  use Mixin::ExtraFields::Param
    -fields => { driver  => 'HashGuts' },
    -fields => {
      moniker => 'field',
      driver  => {
        class    => 'HashGuts',
        hash_key => 'field',
      }
    };

  sub new { bless {} => shift; }
  sub id { 0 + $_[0] }
}

my $widget = Widget::Parameterized->new;

isa_ok($widget, 'Widget::Parameterized');
can_ok($widget, 'param');
can_ok($widget, 'field');

{
  my @names = $widget->param;
  cmp_ok(@names, '==', 0, "there are zero params to start with");

  my @names_fields = $widget->field;
  cmp_ok(@names_fields, '==', 0, "there are zero params_fields to start with");
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

is(
  $widget->field('flavor'),
  undef,
  "...but it didn't affect the same-name field",
);

{
  my @names = $widget->param;
  cmp_ok(@names, '==', 1, "so now there is one param");

  my @names_fields = $widget->field;
  cmp_ok(@names_fields, '==', 0, "but still zero fields");
}

is(
  $widget->field(flavor => 'canadamint'),
  'canadamint',
  "we set a field and got its value back",
);

is(
  $widget->field('flavor'),
  'canadamint',
  "...and that value stuck",
);

is(
  $widget->param('flavor'),
  'teaberry',
  "...but it didn't affect the same-name param",
);
