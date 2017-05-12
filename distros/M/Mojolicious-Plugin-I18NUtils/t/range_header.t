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

    my $lang    = $self->param('lang');
    my @numbers = (1,2000);

    $self->render( text => $self->range( @numbers ) );
};

## Webapp END

my $t = Test::Mojo->new;

my %tests = (
    de    => "1\x{2013}2.000",
    en_CA => "1\x{2013}2,000",
    en_GB => "1\x{2013}2,000",
    en    => "1\x{2013}2,000",
    es    => '1-2000',
    es_MX => '1-2,000',
    zh_CN => "1\x{2013}2,000",
    bn    => "1\x{2013}2,000",
    ar    => "\x{0661}\x{2013}\x{0662}\x{066c}" . "\x{0660}" x 3,
);

my %headers = (
    de    => { 'Accept-Language' => 'de-DE' },
    en    => { 'Accept-Language' => 'en' },
    en_CA => { 'Accept-Language' => 'en-CA' },
    es    => { 'Accept-Language' => 'es' },
    ar    => { 'Accept-Language' => 'ar' },
    es_MX => { 'Accept-Language' => 'es-MX' },
);

for my $lang ( sort keys %tests ) {
    $t->get_ok( "/" => ( $headers{$lang} || $headers{en} ) )->status_is( 200 )->content_is( $tests{$lang}, "test language $lang" );
}

done_testing();

