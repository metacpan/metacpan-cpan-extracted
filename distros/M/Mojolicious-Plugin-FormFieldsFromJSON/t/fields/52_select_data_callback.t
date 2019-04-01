#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use File::Basename;
use File::Spec;

sub testdata {
    return [ 1, 2, 3];
}

{
    package
        MY::TestData;

    sub testdata {
        return +{
            1 => 'Hello',
            2 => 'World',
        };
    }
}

use Mojolicious::Lite;

plugin 'FormFieldsFromJSON' => {
  dir => File::Spec->catdir( dirname( __FILE__ ) || '.', 'conf' ),
};

my $config_name = basename __FILE__;
$config_name    =~ s{\A \d+_ }{}xms;
$config_name    =~ s{\.t \z }{}xms;

get '/' => sub {
  my $c = shift;
  my ($field) = $c->form_fields( $config_name );
  $c->render(text => $field);
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is(join '',
  '<select id="language" name="language">',
  '<option value="1">Hello</option>',
  '<option value="2">World</option>',
  '</select>',
);

done_testing();

