#!/usr/bin/perl

##
## Tests for Pangloss::Apache::Handler
##

use blib;
use strict;
#use warnings;

use Test::More;
BEGIN {
    eval "use Apache; use Apache::libapreq;";
    if ($@) { plan skip_all => 'mod_perl/libapreq not installed'; }
    else    { plan no_plan => 1; }
}

use Pangloss::Config;
use File::Spec::Functions qw( catfile rel2abs );

BEGIN { use_ok("Pangloss::Apache::Handler") }

ok( Pangloss::Apache::Handler->can( 'handler' ), 'can handler()' );

local %ENV = (PG_HOME        => '.',
	      PG_PIXIE_DSN   => 'memory',
	      PG_CONFIG_FILE => catfile(qw( conf controller.yml )));

ok( Pangloss::Apache::Handler->new, 'new' );
is( Pangloss::Config->new->{PG_PIXIE_DSN}, 'memory', 'expected PG_PIXIE_DSN' );

SKIP: {
    skip "not testing handler() method - run under apache instead", 1;
}
