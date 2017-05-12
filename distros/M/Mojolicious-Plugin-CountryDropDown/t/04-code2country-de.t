#!/usr/bin/env perl
use strict;
use warnings;

BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More tests => 9;

# testing code starts here
use Mojolicious::Lite;
use Test::Mojo;

plugin 'CountryDropDown', { language => 'DE', codeset => 'NUMERIC' };

# codeset config should make no difference

app->log->level('debug');

get '/de' => sub {
    my $self = shift;

    # use config language
    my $country = $self->code2country('DE');
    $self->render( text => $country );
};

get '/en' => sub {
    my $self = shift;

    # override config value
    my $country = $self->code2country( 'DE', 'en' );
    $self->render( text => $country );
};

get '/conf' => sub {
    my $self = shift;

    # replace config value and use new value
    $self->csf_conf( { language => 'fr' } );
    my $country = $self->code2country('DE');
    $self->render( text => $country );
};

my $t = Test::Mojo->new;

$t->get_ok('/de')->status_is(200)->content_is('Deutschland');

$t->get_ok('/en')->status_is(200)->content_is('Germany');

$t->get_ok('/conf')->status_is(200)->content_is('Allemagne');

