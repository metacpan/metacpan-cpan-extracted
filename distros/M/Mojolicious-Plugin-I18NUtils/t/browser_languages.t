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

    $self->render( text => join ', ', $self->browser_languages );
};

## Webapp END

my $t = Test::Mojo->new;

my @tests = (
    {
        'header' => 'en;q=0.5, ja;q=0.1',
        'result' => 'en, ja',
    },
    {
        'header' => 'en',
        'result' => 'en',
    },
    {
        'header' => 'en, ja;q=0.3, da;q=1, *;q=0.29, ch-tw',
        'result' => 'en, da, ch-tw, ja, *',
    },
    {
        'header' => 'da, en-gb;q=0.8, en;q=0.7',
        'result' => 'da, en-gb, en',
    },
    {
        'header' => 'en-ca,en;q=0.8,en-us;q=0.6,de-de;q=0.4,de;q=0.2',
        'result' => 'en-ca, en, en-us, de-de, de',
    },
);

for my $test ( @tests ) {
    $t->get_ok( "/" => { 'Accept-Language' => $test->{header} } )
      ->status_is( 200 )
      ->content_is( $test->{result}, "test $test->{header}" );
}

done_testing();

