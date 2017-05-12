#!/usr/bin/perl -w

use strict;

use Test::More 'no_plan'; # tests => 123;

BEGIN
{
  use_ok('Rose::HTML::Object::Message::Localizer');
}

my $l = Rose::HTML::Object::Message::Localizer->new;

is($l->locale, ref($l)->default_locale, 'default locale');
