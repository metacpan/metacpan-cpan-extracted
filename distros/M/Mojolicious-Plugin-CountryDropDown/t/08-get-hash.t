#!/usr/bin/env perl
use strict;
use warnings;

BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More tests => 21;

# testing code starts here
use Mojolicious::Lite;
use Test::Mojo;

plugin 'CountryDropDown';

app->log->level('debug');

get '/ref' => sub {
    my $self = shift;

    my $hash = $self->csf_country_list();
    $self->render( text => ref($hash) );
};

get '/val' => sub {
    my $self = shift;

    my $hash = $self->csf_country_list();
    $self->render( text => $hash->{'DE'} );
};

get '/val_lang' => sub {
    my $self = shift;

    my $hash = $self->csf_country_list( { language => 'fr' } );
    $self->render( text => $hash->{'DE'} );
};

get '/conf_lang' => sub {
    my $self = shift;

    $self->csf_conf( { language => 'de' } );
    my $hash = $self->csf_country_list();
    $self->render( text => $hash->{'DE'} );
};

get '/conf_lang2' => sub {
    my $self = shift;

    $self->csf_conf( { codeset => 'ALPHA_3' } );
    my $hash = $self->csf_country_list();

    $self->render( text => $hash->{'DEU'} );
};

get '/conf_lang3' => sub {
    my $self = shift;

    $self->csf_conf( { codeset => 'NUMERIC' } );
    my $hash = $self->csf_country_list( { exclude => ['276'] } );

    $self->render( text => '|' . $hash->{'250'} . '|' . ( $hash->{'276'} // '_undef_' ) . '|' );
};

my $t = Test::Mojo->new;

$t->get_ok('/ref')->status_is(200)->content_is('HASH');

$t->get_ok('/val')->status_is(200)->content_is('Germany');

$t->get_ok('/val_lang')->status_is(200)->content_is('Allemagne');

$t->get_ok('/val')->status_is(200)->content_is('Germany');

$t->get_ok('/conf_lang')->status_is(200)->content_is('Deutschland');

$t->get_ok('/conf_lang2')->status_is(200)->content_is('Deutschland');

$t->get_ok('/conf_lang3')->status_is(200)->content_like(qr/\A\|Frankreich\|_undef_\|\Z/);

