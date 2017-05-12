#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use File::Basename;
use File::Spec;

plugin 'FormFieldsFromJSON' => {
  dir => File::Spec->catdir( dirname( __FILE__ ) || '.', 'conf' ),
  global_attributes => {
    class => 'test',
  },
};

my $config_name = basename __FILE__;
$config_name    =~ s{\A \d+_ }{}xms;
$config_name    =~ s{\.t \z }{}xms;

get '/' => sub {
  my $c = shift;
  my $fields = $c->form_fields( $config_name );
  $c->render(text => $fields);
};

my $close = Mojolicious->VERSION >= 5.73 ? '' : " /";

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is(
  '<select class="c1 test" id="language" name="language">' .
  '<option value="de">de</option>' .
  '<option value="en">en</option>' .
  '</select>' .
  "\n\n" .
  qq~<input class="c2 test" id="name" name="name" type="text" value=""$close>~ .
  "\n\n" .
  qq~<input id="id" name="id" type="hidden" value="hello"$close>~ .
  "\n\n" .
  qq~<input class="c3 test" id="pwd" name="pwd" type="password" value=""$close>~ .
  "\n\n" .
  qq~<input class="c4 test" id="filter" name="filter" type="checkbox" value="age"$close>~ .
  "\n\n\n" .
  qq~<input class="c5 test" id="type" name="type" type="radio" value="internal"$close>~ .
  "\n" .
  qq~<input class="c5 test" id="type" name="type" type="radio" value="external"$close>~ .
  "\n\n\n" .
  '<textarea class="c6 test" id="comment" name="comment"></textarea>'
);

done_testing();

