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

    my $lang     = $self->param('lang');
    my $price    = '999999.99';

    $self->render( text => $self->decimal( $price, $lang ) );
};

## Webapp END

my $t = Test::Mojo->new;

my %tests = (
    de    => '999.999,99',
    en_CA => '999,999.99',
    en_GB => '999,999.99',
    en    => '999,999.99',
    es    => '999.999,99',
    es_MX => '999,999.99',
    zh_CN => '999,999.99',
    bn    => "\x{09ef}," . ( "\x{09ef}" x 2 ) . "," . ( "\x{09ef}" x 3 ) . "." . "\x{09ef}" x 2,
    ar    => ( "\x{0669}" x 3 ) . "\x{066c}" . ( "\x{0669}" x 3 ) . "\x{066b}" . "\x{0669}" x 2,
);

for my $lang ( sort keys %tests ) {
    $t->get_ok( "/?lang=$lang" )->status_is( 200 )->content_is( $tests{$lang}, "test language $lang" );
}

done_testing();

