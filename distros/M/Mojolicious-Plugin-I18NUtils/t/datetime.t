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

    my $lang = $self->param('lang');
    my $date = '2014-12-10 01:23:45';

    $self->render( text => $self->datetime_loc( $date, $lang ) );
};

## Webapp END

my $t = Test::Mojo->new;

my %tests = (
    de    => '10.12.2014 01:23:45',
    en_CA => '2014-12-10 01:23:45',
    en_GB => '10/12/2014 01:23:45',
    en    => '12/10/2014 01:23:45',
    es    => '10/12/2014 - 01:23:45',
    es_MX => '10/12/2014 - 01:23:45',
    zh_CN => '2014.12.10 01:23:45',
    en_ca => '2014-12-10 01:23:45',
    en_gb => '10/12/2014 01:23:45',
    es_co => '10/12/2014 - 01:23:45',
    zh_cn => '2014.12.10 01:23:45',
);

for my $lang ( sort keys %tests ) {
    $t->get_ok( "/?lang=$lang" )->status_is( 200 )->content_is( $tests{$lang}, "test language $lang" );
}

{
    my $c = $t->app->build_controller;
    is $c->datetime_loc( undef, 'de' ), '';
}

{
    my $c = $t->app->build_controller;
    $c->req->headers->accept_language('de');
    is $c->datetime_loc( undef, undef ), '';
}

{
    my $c = $t->app->build_controller;
    is $c->datetime_loc( undef, undef ), '';
}

done_testing();

