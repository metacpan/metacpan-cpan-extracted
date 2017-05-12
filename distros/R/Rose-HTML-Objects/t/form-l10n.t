#!/usr/bin/perl -w

use strict;

use Test::More tests => 7;

use_ok('Rose::HTML::Form');

BEGIN
{
  package MyObject::Messages;

  use Rose::HTML::Object::Messages qw(:all);
  use base 'Rose::HTML::Object::Messages';

  use constant MSG_FOO => 100_000;

  __PACKAGE__->add_messages;
}

BEGIN { MyObject::Messages->import(':all') }

my $form      = Rose::HTML::Form->new;
my $localizer = $form->localizer;

$localizer->messages_class('MyObject::Messages');

my $my_msg_id     = $localizer->add_localized_message(name => 'MY_MSG', text => 'my message');
my $bummer_msg_id = $localizer->add_localized_message(name => 'BUMMER', text => 'a bummer');

$localizer->add_localized_message_text(name => 'MSG_FOO', locale => 'en', text => 'Foo');
$localizer->add_localized_message_text(name => 'MSG_FOO', locale => 'fr', text => 'Le Foo');

$form->add_fields
(
  menu =>
  {
    type    => 'pop-up menu',
    options =>
    [
      mine => { label_id => $my_msg_id },
      bum  => { label_id => $bummer_msg_id },
      foo  => { label_id => MSG_FOO },
    ],
  },
);

is($form->field('menu')->html,
   qq(<select name="menu" size="1">\n) .
   qq(<option value="mine">my message</option>\n) .
   qq(<option value="bum">a bummer</option>\n) .
   qq(<option value="foo">Foo</option>\n) .
   qq(</select>),
   'hashref en 1');

$localizer->locale('fr');

#$form->localizer->locale('fr');
#$form->locale('fr');

is($form->field('menu')->html,
   qq(<select name="menu" size="1">\n) .
   qq(<option value="mine">my message</option>\n) .
   qq(<option value="bum">a bummer</option>\n) .
   qq(<option value="foo">Le Foo</option>\n) .
   qq(</select>),
   'hashref fr 1');

$form->delete_fields;

$localizer->locale('en');

$form->add_fields
(
  menu =>
  {
    type    => 'pop-up menu',
    options => [ qw(mine bum foo) ],
    label_ids =>
    {
      mine => $my_msg_id,
      bum  => $bummer_msg_id,
      foo  => MSG_FOO,
    },
    default => 'foo',
  },
);

is($form->field('menu')->html,
   qq(<select name="menu" size="1">\n) .
   qq(<option value="mine">my message</option>\n) .
   qq(<option value="bum">a bummer</option>\n) .
   qq(<option selected value="foo">Foo</option>\n) .
   qq(</select>),
   'label_ids en 1');

$form->localizer->locale('fr');

is($form->field('menu')->html,
   qq(<select name="menu" size="1">\n) .
   qq(<option value="mine">my message</option>\n) .
   qq(<option value="bum">a bummer</option>\n) .
   qq(<option selected value="foo">Le Foo</option>\n) .
   qq(</select>),
   'label_ids fr 1');

$form->delete_fields;

$localizer->locale('en');

my $subform = Rose::HTML::Form->new;

$subform->add_fields
(
  menu =>
  {
    type    => 'pop-up menu',
    options => [ qw(mine bum foo) ],
    label_ids =>
    {
      mine => $my_msg_id,
      bum  => $bummer_msg_id,
      foo  => MSG_FOO,
    },
    default => 'bum',
  },

  rbs =>
  {
    type    => 'radio group',
    choices => [ qw(c a b) ],
    label_ids =>
    {
      c => $my_msg_id,
      a => MSG_FOO,
      b => $bummer_msg_id,
    },
    default => 'a',
  },
);

$form->add_form(subform => $subform);

is(join("\n", map { $_->html } $form->fields),
   qq(<select name="subform.menu" size="1">\n) .
   qq(<option value="mine">my message</option>\n) .
   qq(<option selected value="bum">a bummer</option>\n) .
   qq(<option value="foo">Foo</option>\n) .
   qq(</select>\n) .
   qq(<input name="subform.rbs" type="radio" value="c"> <label>my message</label><br>\n) .
   qq(<input checked name="subform.rbs" type="radio" value="a"> <label>Foo</label><br>\n) .
   qq(<input name="subform.rbs" type="radio" value="b"> <label>a bummer</label>),
   'label_ids nested en 1');

$form->localizer->locale('fr');

is(join("\n", map { $_->html } $form->fields),
   qq(<select name="subform.menu" size="1">\n) .
   qq(<option value="mine">my message</option>\n) .
   qq(<option selected value="bum">a bummer</option>\n) .
   qq(<option value="foo">Le Foo</option>\n) .
   qq(</select>\n) .
   qq(<input name="subform.rbs" type="radio" value="c"> <label>my message</label><br>\n) .
   qq(<input checked name="subform.rbs" type="radio" value="a"> <label>Le Foo</label><br>\n) .
   qq(<input name="subform.rbs" type="radio" value="b"> <label>a bummer</label>),
   'label_ids nested fr 1');

#print join("\n", map { $_->html } $form->fields), "\n";
#print $form->field('menu')->html;
