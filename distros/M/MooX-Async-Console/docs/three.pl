#!/usr/bin/env perl

use Modern::Perl '2017';
use strictures 2;

use Three;
use Log::Any::Adapter 'Stderr',
  log_level => 'inform';

$| = 1;

if (1) { # getop daemonise
  exit 0+! daemonise ();
}
