#!/usr/bin/env perl

use Mojolicious::Lite;

use utf8;
use open qw( :encoding(UTF-8) :std );
use Test::More;
use Test::Mojo;

use Mojo::Util qw(url_escape);

use_ok 'Mojolicious::Plugin::I18NUtils';

## Webapp START

plugin('I18NUtils');

any '/'      => sub {
    my $self = shift;

    my $lang = $self->param('lang');
    my $date = $self->param('date');

    $self->render( text => $self->date_from_to( $date, $lang, 'iso' ) );
};

## Webapp END

my $t = Test::Mojo->new;

my %tests = (
    de    => '10.12.2014',
    en_CA => '2014-12-10',
    en_GB => '10/12/2014',
    en    => '12/10/2014',
    es    => '10/12/2014',
    es_MX => '10/12/2014',
    zh_CN => '2014.12.10',
    en_ca => '2014-12-10',
    en_gb => '10/12/2014',
    es_co => '10/12/2014',
    zh_cn => '2014.12.10',
);

for my $lang ( sort keys %tests ) {
    my $date = url_escape( $tests{$lang} );
    $t->get_ok( "/?lang=$lang&date=$date" )->status_is( 200 )->content_is( '2014-12-10', "test language $lang" );
}

{
    my $c = $t->app->build_controller;
    my $date = $c->date_from_to( '10.12.2014', 'de', 'us');
    is $date, '10/12/2014';
}

done_testing();

