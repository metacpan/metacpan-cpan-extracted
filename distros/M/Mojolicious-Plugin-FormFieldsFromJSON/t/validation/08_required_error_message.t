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
  my ($field,$msg) = $c->validate_form_fields( $config_name );
  $c->render(text => $msg || '');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('text is required');
$t->get_ok('/?name=tester')->status_is(200)->content_is('');

done_testing();

