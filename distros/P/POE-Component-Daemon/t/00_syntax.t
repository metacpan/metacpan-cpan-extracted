#!/usr/bin/perl -w

use strict;

use Test::More ( tests => 2 );


use_ok( "POE::Component::Daemon" );
use_ok( "POE::Component::Daemon::Scoreboard" );
