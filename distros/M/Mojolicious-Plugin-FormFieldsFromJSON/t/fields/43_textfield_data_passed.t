#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use File::Basename;
use File::Spec;

plugin 'FormFieldsFromJSON' => {
  dir => File::Spec->catdir( dirname( __FILE__ ) || '.', 'conf' ),
};

my $config_name = basename __FILE__;
$config_name    =~ s{\A \d+_ }{}xms;
$config_name    =~ s{\.t \z }{}xms;

get '/' => sub {
  my $c = shift;
  my ($textfield) = $c->form_fields( $config_name, name => { data => 'default value' } );
  $c->render(text => $textfield);
};

get '/stash' => sub {
  my $c = shift;
  $c->stash( name => 'stashvalue' );
  my ($textfield) = $c->form_fields( $config_name, name => { data => 'test' } );
  $c->render(text => $textfield);
};

my $close = Mojolicious->VERSION >= 5.73 ? '' : " /";

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is(qq~<input id="name" name="name" type="text" value="default value"$close>~);
$t->get_ok('/?name=test')->status_is(200)->content_is(qq~<input id="name" name="name" type="text" value="test"$close>~);
$t->get_ok('/stash')->status_is(200)->content_is(qq~<input id="name" name="name" type="text" value="test"$close>~);

done_testing();

