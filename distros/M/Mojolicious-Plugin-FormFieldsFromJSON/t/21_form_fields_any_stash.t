#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use File::Basename;
use File::Spec;

plugin 'FormFieldsFromJSON' => {
  dir => File::Spec->catdir( dirname( __FILE__ ) || '.', 'conf/' ),
};

my $config_name = basename __FILE__;
$config_name    =~ s{\A \d+_ }{}xms;
$config_name    =~ s{\.t \z }{}xms;

get '/text' => sub {
  my $c = shift;
  $c->stash( any_name => { name => 'test' } );
  my ($textfield) = $c->form_fields( $config_name, from_stash => 'any_name', fields => [ 'name' ] );
  $c->render(text => $textfield);
};

get '/select' => sub {
  my $c = shift;
  $c->stash( any_name => { language => 'de' } );
  my ($select) = $c->form_fields( $config_name, from_stash => 'any_name', fields => ['language'] );
  $c->render(text => $select);
};

my $close    = Mojolicious->VERSION >= 5.73 ? '' : " /";
my $selected = Mojolicious->VERSION < 6.16 ? '="selected"' : '';

my $t = Test::Mojo->new;
$t->get_ok('/text')
  ->status_is(200)
  ->content_is(qq~<input id="name" name="name" type="text" value="test"$close>~);

$t->get_ok('/select')
  ->status_is(200)
  ->content_is(join '',
  '<select id="language" name="language">',
  qq~<option selected$selected value="de">de</option>~,
  qq~<option value="en">en</option>~,
  '</select>'
);

done_testing();

