#!/usr/bin/perl

use Nagios::Plugin::DieNicely qw/CRITICAL/;
use Carp;

croak "croaked and Nagios can detect me";
