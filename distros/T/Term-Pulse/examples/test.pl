#!/usr/bin/perl
#===============================================================================
#        USAGE:  
#       AUTHOR:  Alec Chen <ylchenzr.tsmc.com>
#===============================================================================

use warnings;
use strict;
use Term::Pulse;

pulse_start( name => 'Checking', rotate => 1, time => 1 );
sleep 3;
pulse_stop()                                              
