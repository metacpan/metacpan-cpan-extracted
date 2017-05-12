#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use Data::Dumper;
use File::Basename;
use File::Spec;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::Data::Validate::WithYAML';

## Webapp START

my $dir = dirname __FILE__;

plugin('Data::Validate::WithYAML' => {
    conf_path    => File::Spec->catdir( $dir, 'conf' ),
    error_prefix => 'TEST_',
});

any '/:field/:subinfo' => sub {
    my $self = shift;

    my $info = $self->fieldinfo( 'test', $self->param('field'), $self->param('subinfo') );
    $self->render( json => $info );
};

any '/:field' => sub {
    my $self = shift;

    my $info = $self->fieldinfo( 'test', $self->param('field') );
    $self->render( json => $info );
};

## Webapp END

my $t = Test::Mojo->new;

my @infos = (
    { url => 'country',  check => { type => 'required', regex => '^[A-Z]{2,3}$' } },
    { url => 'age/enum', check => [1,2] },
);

for my $info ( @infos ) {
    $t->get_ok( '/' . $info->{url} )->status_is( 200 )->json_is( $info->{check} );
}

done_testing();
