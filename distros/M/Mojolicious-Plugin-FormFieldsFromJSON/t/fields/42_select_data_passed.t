#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use File::Basename;
use File::Spec;

Test::More::diag( Mojolicious->VERSION );

plugin 'FormFieldsFromJSON' => {
  dir => File::Spec->catdir( dirname( __FILE__ ) || '.', 'conf' ),
};

my $selected = Mojolicious->VERSION < 6.16 ? '="selected"' : '';

my $config_name = basename __FILE__;
$config_name    =~ s{\A \d+_ }{}xms;
$config_name    =~ s{\.t \z }{}xms;

get '/' => sub {
  my $c = shift;
  my ($field) = $c->form_fields( $config_name, language => { data => [qw/de en cn/] } );
  $c->render(text => $field);
};

get '/test' => sub {
  my $c = shift;

  $c->param( language => 'de' );

  my ($field) = $c->form_fields( $config_name, language => { data => [qw/de en cn/] } );
  $c->render(text => $field);
};

get '/set' => sub {
  my $c = shift;
  my ($field) = $c->form_fields( $config_name, language => { data => [qw/cn de en/], selected => 'de' } );
  $c->render(text => $field);
};

get '/reset' => sub {
  my $c = shift;
  my ($field) = $c->form_fields( $config_name, language => { data => [qw/cn de en/], selected => 'de' } );
  $c->render(text => $c->param('language') . $field );
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is(join '',
  '<select id="language" name="language">',
  '<option value="cn">cn</option>',
  '<option value="de">de</option>',
  qq~<option selected$selected value="en">en</option>~,
  '</select>',
);

$t->get_ok('/?language=de')->status_is(200)->content_is(join '',
  '<select id="language" name="language">',
  '<option value="cn">cn</option>',
  qq~<option selected$selected value="de">de</option>~,
  '<option value="en">en</option>',
  '</select>',
);

$t->get_ok('/test')->status_is(200)->content_is(join '',
  '<select id="language" name="language">',
  '<option value="cn">cn</option>',
  qq~<option selected$selected value="de">de</option>~,
  '<option value="en">en</option>',
  '</select>',
);

$t->get_ok('/set')->status_is(200)->content_is(join '',
  '<select id="language" name="language">',
  '<option value="cn">cn</option>',
  qq~<option selected$selected value="de">de</option>~,
  '<option value="en">en</option>',
  '</select>',
);

$t->get_ok('/reset?language=en')->status_is(200)->content_is(join '',
  'en',
  '<select id="language" name="language">',
  '<option value="cn">cn</option>',
  qq~<option selected$selected value="de">de</option>~,
  '<option value="en">en</option>',
  '</select>',
);

done_testing();

