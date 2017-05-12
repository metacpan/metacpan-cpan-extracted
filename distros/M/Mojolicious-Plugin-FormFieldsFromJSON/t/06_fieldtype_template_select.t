#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use File::Basename;
use File::Spec;

plugin 'FormFieldsFromJSON' => {
  dir       => File::Spec->catdir( dirname( __FILE__ ) || '.', 'conf' ),
  template  => '<label for="<%= $id %>"><%= $label %>:</label><div><%= $field %></div>',
  templates => {
    select => '<%= $label %>: <%= $field %>',
  },
};

my $config_name = basename __FILE__;
$config_name    =~ s{\A \d+_ }{}xms;
$config_name    =~ s{\.t \z }{}xms;

get '/' => sub {
  my $c = shift;
  my ($textfield) = $c->form_fields( $config_name );
  $c->render(text => $textfield);
};

my $close = Mojolicious->VERSION >= 5.73 ? '' : " /";

my $t = Test::Mojo->new;
$t->get_ok('/')
  ->status_is(200)
  ->content_is(
      qq~<label for="name">Name:</label><div><input id="name" name="name" type="text" value=""$close></div>\n\n\n~ .
      'Country: <select id="country" name="country"><option value="au">au</option></select>' . "\n"
  );

done_testing();

