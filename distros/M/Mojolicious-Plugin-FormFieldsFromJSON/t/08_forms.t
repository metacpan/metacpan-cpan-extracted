#!/usr/bin/perl

use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use File::Basename;
use File::Spec;

plugin 'FormFieldsFromJSON' => {
  dir => File::Spec->catdir( dirname( __FILE__ ) || '.', 'formsconf' ),
};

get '/' => sub {
  my $c = shift;
  my @forms = $c->forms;

  $c->render(text => join ' .. ', @forms );
};

my $t = Test::Mojo->new;
$t->get_ok('/')
  ->status_is(200)
  ->content_is('template .. template_configured_in_json .. template_twofields');

done_testing();
