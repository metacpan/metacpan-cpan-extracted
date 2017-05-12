#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use File::Basename;
use File::Spec;

my $dir;
BEGIN {
    $dir = File::Spec->catdir( dirname( __FILE__ ) || '.', 'lib' );
}
use lib $dir;

plugin 'FormFieldsFromJSON::Test';
plugin 'FormFieldsFromJSON' => {
  dir => File::Spec->catdir( dirname( __FILE__ ) || '.', 'conf' ),
  types => {
    testfield => 1,
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
  qq~<input id="name" name="name" type="test" value=""$close>~
);

done_testing();

