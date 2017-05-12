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

get '/' => sub {
  my $c = shift;

  my $config =   [
    {
      "type" => "select",
      "name" => "language",
      "data" => [
        "de",
        "en"
      ]
    },
    {
      "label" => "Name",
      "type" => "text",
      "name" => "name"
    }
  ];

  my $fields = $c->form_fields( $config );
  $c->render(text => $fields);
};

my $close = Mojolicious->VERSION >= 5.73 ? '' : " /";

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is(join '',
  '<select id="language" name="language">',
  '<option value="de">de</option>',
  '<option value="en">en</option>',
  '</select>',
  "\n\n",
  qq~<input id="name" name="name" type="text" value=""$close>~
);

done_testing();

