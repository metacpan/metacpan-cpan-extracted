#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Test::ObjAnno::Util;

use Test::More tests => 35;

my $obj_a  = Some::Object->new;
my $obj_b  = Some::Object->new;

my $widget   = Some::Widget->new;

my @generic_widgets;
push @generic_widgets, Some::Widget::Generic->new for (1..5);

for ($obj_a, $obj_b) {
  isa_ok($_, 'Some::Object');
  can_ok($_, 'annotate');
}

isa_ok($widget, 'Some::Widget');
can_ok($widget, 'annotate');

for (@generic_widgets) {
  isa_ok($_, 'Some::Widget');
  isa_ok($_, 'Some::Widget::Generic');
  can_ok($_, 'annotate');
}

is(
  $obj_a->annotations_class,
  $obj_b->annotations_class,
  "both Some::Object objects have the same annotation class",
);

is(
  $obj_a->annotations_class,
  $widget->annotations_class,
  "and so does Some::Widget",
);

my $annotations_class = $obj_a->annotations_class;
like(
  $annotations_class,
  qr/\AObject::Annotate::Construct::0x/,
  "object annotation class looks like what we expect",
);

$obj_a->annotate({ event => "grand opening", comment => "colossal failure" });

{
  my @notes = $obj_a->search_annotations;
  is(@notes, 1, "object a now has one note");
}

$obj_a->annotate({ event => "grand closing", comment => "colossal success" });

{
  my @notes = $obj_a->search_annotations;
  is(@notes, 2, "object a now has two notes");
}

$obj_b->annotate({ event => "grand opening", comment => "rjbs cut ribbon" });

$widget->annotate({ event => "drive failure" });

for (@generic_widgets) {
  $_->annotate({ event => "hora de sieta", comment => "$_" });
}

{ # grand finale!
  my @notes;

  @notes = $obj_b->search_annotations;
  is(@notes, 1, "object b now has one note");

  @notes = $obj_a->search_annotations;
  is(@notes, 2, "object a has two notes, after note on object b");

  @notes = $obj_a->search_annotations({ event => 'grand opening' });
  is(@notes, 1, "object a has one 'grand opening' event");

  @notes = Some::Object->search_annotations;
  is(@notes, 3, "there are three annotations for this class");

  @notes = Some::Widget->search_annotations;
  is(@notes, 1, "there is one annotation for Some::Widget");

  @notes = Some::Widget::Generic->search_annotations;
  is(@notes, 5, "there are five annotations for Some::Widget::Generic");

  @notes = $generic_widgets[0]->search_annotations;
  is(@notes, 5, "there are five annotations for the first generic widget");

  @notes = $generic_widgets[1]->search_annotations;
  is(@notes, 5, "there are five annotations for the 2nd generic widget, too");

  @notes = Some::Object->annotations_class->retrieve_all;
  is(@notes, 9, "there are four annotations in $annotations_class");
}
