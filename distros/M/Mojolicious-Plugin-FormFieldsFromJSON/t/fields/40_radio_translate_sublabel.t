#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use File::Basename;
use File::Spec;

plugin 'FormFieldsFromJSON' => {
  dir => File::Spec->catdir( dirname( __FILE__ ) || '.', 'conf' ),
  translation_method => \&loc,
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
$t->get_ok('/')->status_is(200)->content_is(
  qq~<input id="type" name="type" type="radio" value="internal"$close> intern\n~ .
  qq~<input id="type" name="type" type="radio" value="external"$close> extern\n~
);

done_testing();

  sub loc {
      my ($c, $value) = @_;
  
      my %translation = ( internal => 'intern', external => 'extern' );
      return $translation{$value} // $value;
  };

