#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;

use Rose::HTML::Object::Messages qw(CUSTOM_MESSAGE);

BEGIN
{
  use_ok('Rose::HTML::Object::Message');
}

my $m = Rose::HTML::Object::Message->new('Foo bar');

is($m->text, 'Foo bar', 'text 1');

$m = Rose::HTML::Object::Message->new(id => 123, text => 'Foo bar');

is($m->id, CUSTOM_MESSAGE, 'id 1');
is($m->text, 'Foo bar', 'text 2');
