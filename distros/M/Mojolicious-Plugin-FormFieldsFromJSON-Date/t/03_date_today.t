#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Time::Piece;
use File::Basename;
use File::Spec;

plugin 'FormFieldsFromJSON::Date';
plugin 'FormFieldsFromJSON' => {
  dir   => File::Spec->catdir( dirname( __FILE__ ) || '.', 'conf' ),
  types => {
    date => 1,
  }
};

my $config_name = basename __FILE__;
$config_name    =~ s{\A \d+_ }{}xms;
$config_name    =~ s{\.t \z }{}xms;

get '/' => sub {
  my $c = shift;
  my ($textfield) = $c->form_fields( $config_name );
  $c->render(text => $textfield);
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200);

my $content = $t->tx->res->body;

my $today = localtime;

my $year  = sprintf "%04d", $today->year;
my $month = sprintf "%02d", $today->mon;
my $mon   = $today->mon;
my $day   = sprintf "%02d", $today->mday;
my $mday  = $today->mday;

like $content, qr/selected="selected" value="$year">$year</;
like $content, qr/selected="selected" value="$month">$mon</;
like $content, qr/selected="selected" value="$day">$mday</;

done_testing();

