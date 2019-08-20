#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = '';
$::ti = new Test::Inter $0;
require "script.pl";

testScript(
           'mode'   => 'run',
           'dire'   => '/tmp',
           'output' => 'quiet',
           'env'    => [ qw(SC_VAR_1  val_1   SC_VAR_2  val_2) ],
          );

#Local Variables:
#mode: cperl
#indent-tabs-mode: nil
#cperl-indent-level: 3
#cperl-continued-statement-offset: 2
#cperl-continued-brace-offset: 0
#cperl-brace-offset: 0
#cperl-brace-imaginary-offset: 0
#cperl-label-offset: 0
#End:
