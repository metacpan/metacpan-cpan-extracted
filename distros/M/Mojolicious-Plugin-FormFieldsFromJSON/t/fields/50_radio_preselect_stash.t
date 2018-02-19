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
  $c->stash( article_type => 'internal' );
  my ($textfield) = $c->form_fields( $config_name );
  $c->render(text => $textfield);
};

my $close   = Mojolicious->VERSION >= 5.73 ? '' : " /";
my $checked = Mojolicious->VERSION <= 6.16 ? 'checked="checked"' : "checked";

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is(qq~<input $checked id="article_type" name="article_type" type="radio" value="internal"$close>~ . "\n");

done_testing();

