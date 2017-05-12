#!/usr/bin/env perl
use strict;
use warnings;

BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More tests => 36;

# testing code starts here
use Mojolicious::Lite;
use Test::Mojo;

plugin 'CountryDropDown';

app->log->level('debug');

get '/de' => sub {
    my $self = shift;

    my $code = $self->country2code( 'Deutschland', 'de' );
    $self->render( text => $code );
};

get '/en' => sub {
    my $self = shift;

    my $code = $self->country2code('Germany');
    $self->render( text => $code );
};

get '/de_conf' => sub {
    my $self = shift;

    $self->csf_conf( { language => 'de', codeset => 'NUMERIC' } );
    my $code = $self->country2code('Deutschland');
    $self->render( text => $code );
};

get '/fr' => sub {
    my $self = shift;

    my $code = $self->country2code( 'Allemagne', 'fr' );
    $self->render( text => $code );
};

get '/conf_de' => sub {
    my $self = shift;

    $self->csf_conf( { language => 'de', codeset => undef } );
    my $code = $self->country2code('Deutschland');
    $self->render( text => $code );
};

get '/stored_conf' => sub {
    my $self = shift;

    my $code = $self->country2code('Deutschland');
    $self->render( text => $code );
};

get '/fr_a2' => sub {
    my $self = shift;

    my $code = $self->country2code( 'Allemagne', 'fr', 'ALPHA_2' );
    $self->render( text => $code );
};

get '/fr_a2b' => sub {
    my $self = shift;

    my $code = $self->country2code( 'Allemagne', 'fr', 'LOCALE_CODE_ALPHA_2' );
    $self->render( text => $code );
};

get '/fr_a3' => sub {
    my $self = shift;

    my $code = $self->country2code( 'Allemagne', 'fr', 'ALPHA_3' );
    $self->render( text => $code );
};

get '/fr_a3b' => sub {
    my $self = shift;

    my $code = $self->country2code( 'Allemagne', 'fr', 'LOCALE_CODE_ALPHA_3' );
    $self->render( text => $code );
};

get '/fr_n' => sub {
    my $self = shift;

    my $code = $self->country2code( 'Allemagne', 'fr', 'NUMERIC' );
    $self->render( text => $code );
};

get '/fr_nb' => sub {
    my $self = shift;

    my $code = $self->country2code( 'Allemagne', 'fr', 'LOCALE_CODE_NUMERIC' );
    $self->render( text => $code );
};

my $t = Test::Mojo->new;

$t->get_ok('/de')->status_is(200)->content_is('DE');

$t->get_ok('/en')->status_is(200)->content_is('DE');

$t->get_ok('/de_conf')->status_is(200)->content_is('276');

$t->get_ok('/fr')->status_is(200)->content_is('276');

$t->get_ok('/conf_de')->status_is(200)->content_is('DE');

$t->get_ok('/stored_conf')->status_is(200)->content_is('DE');

$t->get_ok('/fr_a2')->status_is(200)->content_is('DE');

$t->get_ok('/fr_a2b')->status_is(200)->content_is('DE');

$t->get_ok('/fr_a3')->status_is(200)->content_is('DEU');

$t->get_ok('/fr_a3b')->status_is(200)->content_is('DEU');

$t->get_ok('/fr_n')->status_is(200)->content_is('276');

$t->get_ok('/fr_nb')->status_is(200)->content_is('276');

