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

my $app = $t->app;

{
    # no file - should croak
    my $error = '';
    eval {
        FieldInfoTest::fi();
    } or $error = $@;

    like $error, qr/fi\.yml does not exist/;
}

{
    # an invalid YAML file - should croak
    my $error = '';
    eval {
        FieldInfoTest::finfo();
    } or $error = $@;

    like $error, qr/YAML::Tiny failed to classify line/;
}

is $app->fieldinfo('test', 'Unittest'), undef;

done_testing();

{
    package
        FieldInfoTest;

    sub finfo {
        $app->fieldinfo(@_);
    }

    sub fi {
        $app->fieldinfo(@_);
    }
}
