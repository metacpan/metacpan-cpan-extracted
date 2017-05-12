#!/usr/bin/perl

use Nagios::Plugin::DieNicely qw/CRITICAL/;

die "died and Nagios can detect me";
