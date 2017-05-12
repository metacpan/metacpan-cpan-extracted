#!/usr/bin/perl

##
## Tests for Pangloss::WebApp::Standalone
##

use blib;
use strict;
#use warnings;

use Test::More;
BEGIN {
    eval "use HTTP::Daemon";
    if ($@) { plan skip_all => 'mod_perl not installed'; }
    else    { plan no_plan => 1; }
}

use Pangloss::Config;
use File::Spec::Functions qw( catfile rel2abs );

BEGIN { use_ok("Pangloss::WebApp::Standalone") }

local %ENV = (PG_HOME        => '.',
	      PG_PIXIE_DSN   => 'memory',
	      PG_CONFIG_FILE => catfile(qw( conf config.yaml )));

my $webapp = Pangloss::WebApp::Standalone->new;

isa_ok( $webapp, 'Pangloss::WebApp::Standalone', 'new' );

SKIP: {
    skip "not starting standalone web server - run `bin/pg_test_server` instead", 1;
}
