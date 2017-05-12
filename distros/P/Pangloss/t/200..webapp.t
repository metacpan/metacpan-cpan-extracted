#!/usr/bin/perl

##
## Tests for Pangloss::Apache::Handler
##

use blib;
use strict;
#use warnings;

use Test::More 'no_plan';

use Pangloss::Config;
use File::Spec::Functions qw( catfile rel2abs );

BEGIN { use_ok("Pangloss::WebApp") }

local %ENV = (PG_HOME        => '.',
	      PG_PIXIE_DSN   => 'memory',
	      PG_CONFIG_FILE => catfile(qw( t data no_config.yml )));

my $webapp = Pangloss::WebApp->new;

isa_ok( $webapp, 'Pangloss::WebApp', 'new' );

is( Pangloss::Config->new->{PG_HOME},      '.',      'got expected PG_HOME' );
is( Pangloss::Config->new->{PG_PIXIE_DSN}, 'memory', 'got expected PG_PIXIE_DSN' );

ok    ( $webapp->frozen_controller, 'frozen_controller' );
isa_ok( $webapp->config,     'Pangloss::Config',      'config' );
isa_ok( $webapp->app,        'Pangloss::Application', 'app' );
isa_ok( $webapp->ufactory,   'OpenFrame::WebApp::User::Factory',     'ufactory' );
isa_ok( $webapp->tfactory,   'OpenFrame::WebApp::Template::Factory', 'ufactory' );
isa_ok( $webapp->sfactory,   'OpenFrame::WebApp::Session::Factory',  'ufactory' );

