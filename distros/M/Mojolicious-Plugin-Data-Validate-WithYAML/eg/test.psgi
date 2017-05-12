#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use File::Basename;
use File::Spec;
use Mojolicious::Lite;

my $dir = dirname __FILE__;

plugin('Data::Validate::WithYAML' => {
    conf_path    => File::Spec->catdir( $dir, '..', 't', 'conf' ),
    error_prefix => 'TEST_',
});

any '/' => \&test;

sub test {
    my $self = shift;

    my %errors = $self->validate( 'hello' );
    $self->app->log->debug( Dumper \%errors );
    $self->render( json => { test => 1 } );
};

app->start;
