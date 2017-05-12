#!/usr/bin/env perl
use strict;
use warnings;

BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More tests => 27;

# testing code starts here
use Mojolicious::Lite;
use Test::Mojo;

plugin 'CountryDropDown';

app->log->level('debug');

get '/en' => sub {
    my $self = shift;

    my $country = $self->code2country('DE');
    $self->render( text => $country );
};

get '/de' => sub {
    my $self = shift;

    my $country = $self->code2country( 'DE', 'de' );
    $self->render( text => $country );
};

get '/de_lowercase' => sub {
    my $self = shift;

    my $country = $self->code2country('de');
    $self->render( text => $country );
};

get '/de_en' => sub {
    my $self = shift;

    my $country = $self->code2country( 'DE', 'en' );
    $self->render( text => $country );
};

get '/de_numeric' => sub {
    my $self = shift;

    my $country = $self->code2country( '276', 'de' );
    $self->render( text => $country );
};

get '/de_alpha3' => sub {
    my $self = shift;

    my $country = $self->code2country( 'DEU', 'de' );
    $self->render( text => $country );
};

get '/conf' => sub {
    my $self = shift;

    $self->csf_conf( { language => 'fr' } );
    my $country = $self->code2country('DE');
    $self->render( text => $country );
};

get '/conf2' => sub {
    my $self = shift;

    $self->csf_conf( { language => undef } );
    my $country = $self->code2country('DE');
    $self->render( text => $country );
};

get '/wrong_call' => sub {
	my $self = shift;

	my $country = $self->code2country('');
	$country = 'undef' if not defined $country;
	$self->render( text => $country );
};

my $t = Test::Mojo->new;

$t->get_ok('/en')->status_is(200)->content_is('Germany');

$t->get_ok('/de')->status_is(200)->content_is('Deutschland');

$t->get_ok('/de_lowercase')->status_is(200)->content_is('Germany');

$t->get_ok('/de_en')->status_is(200)->content_is('Germany');

$t->get_ok('/de_numeric')->status_is(200)->content_is('Deutschland');

$t->get_ok('/de_alpha3')->status_is(200)->content_is('Deutschland');

$t->get_ok('/conf')->status_is(200)->content_is('Allemagne');

$t->get_ok('/conf2')->status_is(200)->content_is('Germany');

$t->get_ok('/wrong_call')->status_is(200)->content_is('undef');

