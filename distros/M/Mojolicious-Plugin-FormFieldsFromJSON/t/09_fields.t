#!/usr/bin/perl

use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use File::Basename;
use File::Spec;
use Data::Dumper;

plugin 'FormFieldsFromJSON' => {
  dir => File::Spec->catdir( dirname( __FILE__ ) || '.', 'formsconf' ),
};

get '/' => sub {
  my $c = shift;

  my %opts;
  $opts{hash} = 1 if $c->param('hash');

  my @fields = $c->fields('template_twofields', \%opts);

  if ( $opts{hash} ) {
      return $c->render(json => \@fields);
  }

  $c->render(text => join ' .. ', @fields );
};

my $t = Test::Mojo->new;
$t->get_ok('/')
  ->status_is(200)
  ->content_is('Name .. Password');

$t->get_ok('/?hash=1')
  ->status_is(200)
  ->json_is([ { label => 'Name', name => 'name' }, { label => 'Password', name => 'password' } ] );

done_testing();
