#!/usr/bin/perl

use Nagios::Plugin::DieNicely qw/WARNING/;
use Carp;

croak "croaked and Nagios can detect me";
