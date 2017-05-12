#!/usr/bin/env perl

use Mojolicious::Lite;

use utf8;
use open qw( :encoding(UTF-8) :std );
use Test::More;
use Test::Mojo;

use_ok 'Mojolicious::Plugin::I18NUtils';

## Webapp START

plugin('I18NUtils');

any '/'      => sub {
    my $self = shift;

    my $lang   = $self->param('lang');
    my $method = $self->param('method');

    $self->render( text => $self->locale_obj( $lang )->$method() );
};

## Webapp END

my $t = Test::Mojo->new;

my %tests = (
  en => {
    l => 'en',
    lr => 'en',
    rl => 'en',
    ls => 'en',
    s  => '',
  },
  en_EN => {
    l => 'en',
    lr => 'en-EN',
    rl => 'EN-en',
    s  => '',
  },
  sk_Latn => {
    l  => 'sk',
    ls => 'sk-Latn',
    sl => 'Latn-sk',
    s  => 'Latn',
  },
);

for my $locale ( sort keys %tests ) {
    my $obj = Mojolicious::Plugin::I18NUtils::Locale->new( locale => $locale );
    for my $method ( sort keys %{ $tests{$locale} } ) {
        my $check = $tests{$locale}->{$method};

        $t->get_ok( "/?lang=$locale&method=$method" )->status_is( 200 )->content_is( $check, "test language $locale // $method" );
    }
}

done_testing();

