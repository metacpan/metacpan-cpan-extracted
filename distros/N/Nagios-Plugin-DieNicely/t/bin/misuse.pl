#!/usr/bin/perl

use Nagios::Plugin::DieNicely 'NOTANAGIOSSTATE';

die "died and Nagios can detect me";
