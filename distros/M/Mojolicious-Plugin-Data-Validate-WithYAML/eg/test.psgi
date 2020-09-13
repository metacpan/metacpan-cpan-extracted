#!/usr/bin/perl

use strict;
use warnings;

use Mojolicious::Lite;

plugin('Data::Validate::WithYAML' => {
    conf_path    => app->home->child( '..', 't', 'conf' )->to_string,
    error_prefix => 'TEST_',
});

any '/' => \&test;

sub test {
    my $self = shift;

    my %errors = $self->validate( 'hello' );
    $self->app->log->debug( $self->dumper( \%errors ) );
    $self->render( json => { test => 1 } );
};

app->start;
