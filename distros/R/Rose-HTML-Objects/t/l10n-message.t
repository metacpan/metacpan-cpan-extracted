#!/usr/bin/perl -w

use strict;

use utf8;

use Test::More tests => 8;

use_ok('Rose::HTML::Form::Field::Integer');
use_ok('Rose::HTML::Object::Message::Localized');

use Rose::HTML::Object::Messages qw(NUM_INVALID_INTEGER);

my $field = Rose::HTML::Form::Field::Integer->new;

my $msg = 
  Rose::HTML::Object::Message::Localized->new(
    parent => $field,
    id     => NUM_INVALID_INTEGER,
    args   => { label => 'XYZ' });

is($msg->localized_text, 'XYZ must be an integer.', 'text (en) 1');

$msg->locale('fr');

is($msg->localized_text, 'XYZ doit être un entier.', 'text (fr) 1');

Rose::HTML::Form::Field::Integer->load_all_messages;

$msg = 
  Rose::HTML::Object::Message::Localized->new(
    id     => NUM_INVALID_INTEGER,
    args   => { label => 'XYZ' });

is($msg->localized_text, 'XYZ must be an integer.', 'text (en) 2');

$msg->locale('fr');

is($msg->localized_text, 'XYZ doit être un entier.', 'text (fr) 2');

my $localizer = Rose::HTML::Object::Message::Localized->default_localizer;

my $label_id =
  $localizer->add_localized_message(name => 'LABEL_SIBLINGS',
                                    text =>
                                    {
                                      en => 'Siblings',
                                      fr => 'Les frères et sœurs',
                                    });

my $label = 
  Rose::HTML::Object::Message::Localized->new(id => $label_id);    

$msg = 
  Rose::HTML::Object::Message::Localized->new(
    id   => NUM_INVALID_INTEGER,
    args => { label => $label });

is($msg->localized_text, 'Siblings must be an integer.', 'text (en) 1');

$label->parent($msg);
$msg->locale('fr');

is($msg->localized_text, 'Les frères et sœurs doit être un entier.', 'text (fr) 1');
