#!/usr/bin/env perl

use Mojolicious::Lite;

use utf8;
use open qw( :encoding(UTF-8) :std );
use Test::More;
use Test::Mojo;

use_ok 'Mojolicious::Plugin::I18NUtils';

## Webapp START

plugin('I18NUtils' => { format => '%d.%m.%Y %H:%M:%S' });

any '/'      => sub {
    my $self = shift;

    my $lang = $self->param('lang');
    my $date = '10.12.2014 01:23:45';

    $self->render( text => $self->date_loc( $date, $lang ) );
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
);

for my $lang ( sort keys %tests ) {
    $t->get_ok( "/?lang=$lang" )->status_is( 200 )->content_is( $tests{$lang}, "test language $lang" );
}

done_testing();

