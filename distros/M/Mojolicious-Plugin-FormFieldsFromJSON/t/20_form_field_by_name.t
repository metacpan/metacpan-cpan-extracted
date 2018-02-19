#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use File::Basename;
use File::Spec;

plugin 'FormFieldsFromJSON' => {
  dir      => File::Spec->catdir( dirname( __FILE__ ) || '.', 'conf/' ),
};

my $config_name = basename __FILE__;
$config_name    =~ s{\A \d+_ }{}xms;
$config_name    =~ s{\.t \z }{}xms;

get '/text' => sub {
  my $c = shift;
  my ($textfield) = $c->form_field_by_name( $config_name, 'name' );
  $c->render(text => $textfield);
};

get '/select' => sub {
  my $c = shift;
  my ($select) = $c->form_field_by_name( $config_name, 'language' );
  $c->render(text => $select);
};

my $close = Mojolicious->VERSION >= 5.73 ? '' : " /";

my $t = Test::Mojo->new;
$t->get_ok('/text')
  ->status_is(200)
  ->content_is(qq~<input id="name" name="name" type="text" value=""$close>~);

$t->get_ok('/select')
  ->status_is(200)
  ->content_is(join '',
  '<select id="language" name="language">',
  '<option value="de">de</option>',
  qq~<option value="en">en</option>~,
  '</select>'
);

done_testing();

