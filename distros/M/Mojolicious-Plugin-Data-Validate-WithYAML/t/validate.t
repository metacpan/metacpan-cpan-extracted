#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::Data::Validate::WithYAML';

## Webapp START

plugin('Data::Validate::WithYAML' => {
    conf_path    => app->home->child( 'conf' )->to_string,
    error_prefix => 'TEST_',
});

any '/' => sub {
    my $self = shift;

    my %errors = $self->validate( 'test' );
    $self->render( json => \%errors );
};

any '/hello' => \&hello;

sub hello {
    my $self = shift;

    my %errors = $self->validate;
    $self->render( json => \%errors );
}

## Webapp END

my $t = Test::Mojo->new;

my %positive_check = ();
my %positive       = (
    email   => 'test@test.de',
    plz     => 'hallo',
    country => 'DE',
    age2    => 20,
    admin   => 'superuser',
);

$t->post_ok( '/', form => \%positive )->status_is( 200 )->json_is( \%positive_check );
$t->post_ok( '/hello', form => \%positive )->status_is( 200 )->json_is( \%positive_check );

my %negative_check = ( TEST_email => 'Email is not correct', TEST_age => 'age must be either 1 or 2' );
my %negative       = (
    email   => 'test@test.de235235',
    plz     => 'hallo',
    country => 'DE',
    age     => 3,
    age2    => 20,
    admin   => 'superuser',
);

$t->post_ok( '/', form => \%negative )->status_is( 200 )->json_is( \%negative_check );
$t->post_ok( '/hello', form => \%negative )->status_is( 200 )->json_is( \%negative_check );

done_testing();
