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
  my ($field) = $c->form_fields( $config_name );
  $c->render(text => $field);
};

get '/set' => sub {
  my $c = shift;
  my ($field) = $c->form_fields( $config_name, language => { disabled => 'de' } );
  $c->render(text => $field);
};

get '/set_multi' => sub {
  my $c = shift;
  my ($field) = $c->form_fields( $config_name, language => { disabled => ['de', 'en'] } );
  $c->render(text => $field );
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is(join '',
  '<select id="language" name="language">',
  '<option value="cn">cn</option>',
  '<option value="de">de</option>',
  '<option disabled="disabled" value="en">en</option>',
  '</select>',
);

$t->get_ok('/?language=de')->status_is(200)->content_is(join '',
  '<select id="language" name="language">',
  '<option value="cn">cn</option>',
  qq~<option selected$selected value="de">de</option>~,
  '<option disabled="disabled" value="en">en</option>',
  '</select>',
);

$t->get_ok('/set')->status_is(200)->content_is(join '',
  '<select id="language" name="language">',
  '<option value="cn">cn</option>',
  '<option disabled="disabled" value="de">de</option>',
  '<option value="en">en</option>',
  '</select>',
);

$t->get_ok('/set_multi')->status_is(200)->content_is(join '',
  '<select id="language" name="language">',
  '<option value="cn">cn</option>',
  '<option disabled="disabled" value="de">de</option>',
  '<option disabled="disabled" value="en">en</option>',
  '</select>',
);

done_testing();

