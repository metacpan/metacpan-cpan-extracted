#!/usr/bin/perl

use Nagios::Plugin::DieNicely qw/UNKNOWN/;
use Carp;

croak "croaked and Nagios can detect me";
