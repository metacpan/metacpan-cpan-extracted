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

    my $date = '2014-12-10 01:23:45';

    $self->render( text => $self->date_loc( $date ) );
};

any '/error'      => sub {
    my $self = shift;

    my $date = $self->param('date');

    $self->render( text => $self->date_loc( $date, 'de' ) );
};

## Webapp END

my $t = Test::Mojo->new;

my %headers = (
    de    => { 'Accept-Language' => 'de' },
    en    => { 'Accept-Language' => 'en' },
    en_CA => { 'Accept-Language' => 'en-CA' },
    en_ca => { 'Accept-Language' => 'en-CA' },
    es    => { 'Accept-Language' => 'es' },
    ar    => { 'Accept-Language' => 'ar' },
    es_MX => { 'Accept-Language' => 'es-MX' },
);

my %tests = (
    de    => '10.12.2014',
    en_CA => '2014-12-10',
    en_GB => '12/10/2014',
    en    => '12/10/2014',
    es    => '10/12/2014',
    es_MX => '10/12/2014',
    zh_CN => '12/10/2014',
    en_ca => '2014-12-10',
    en_gb => '12/10/2014',
    es_co => '12/10/2014',
    zh_cn => '12/10/2014',
    test  => '12/10/2014',
);

for my $lang ( sort keys %tests ) {
    $t->get_ok( "/" => ( $headers{$lang} || $headers{en} ) )->status_is( 200 )->content_is( $tests{$lang}, "test language $lang" );
}

my @falses = ( '', undef, '0000-00-00 00:00:00','string');

for my $date ( @falses ) {
    $t->get_ok( "/error?date=" . ( $date || '' ) )->status_is( 200 )->content_is( '', "test error " . ( defined $date ? $date : '<undefined>' ) );
}

done_testing();

