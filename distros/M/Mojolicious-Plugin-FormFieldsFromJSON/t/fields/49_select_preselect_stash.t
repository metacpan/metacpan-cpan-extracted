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

my $selected = Mojolicious->VERSION < 6.16 ? '="selected"' : '';

my $config_name = basename __FILE__;
$config_name    =~ s{\A \d+_ }{}xms;
$config_name    =~ s{\.t \z }{}xms;

get '/' => sub {
  my $c = shift;
  $c->stash( language => 'en' );

  my ($field) = $c->form_fields( $config_name );
  $c->render(text => $field);
};

get '/test' => sub {
  my $c = shift;
  $c->stash( language => 'de' );

  my ($field) = $c->form_fields( $config_name, language => { selected => 'en' } );
  $c->render(text => $field);
};

get '/multi' => sub {
  my $c = shift;
  $c->stash( language => ['de', 'en' ] );

  my ($field) = $c->form_fields( $config_name );
  $c->render(text => $field);
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is(join '',
  '<select id="language" name="language">',
  '<option value="cn">cn</option>',
  '<option value="de">de</option>',
  qq~<option selected$selected value="en">en</option>~,
  '</select>',
);

$t->get_ok('/test')->status_is(200)->content_is(join '',
  '<select id="language" name="language">',
  '<option value="cn">cn</option>',
  '<option value="de">de</option>',
  qq~<option selected$selected value="en">en</option>~,
  '</select>',
);

$t->get_ok('/multi')->status_is(200)->content_is(join '',
  '<select id="language" name="language">',
  '<option value="cn">cn</option>',
  qq~<option selected$selected value="de">de</option>~,
  qq~<option selected$selected value="en">en</option>~,
  '</select>',
);

done_testing();

