#!/usr/bin/perl

use Nagios::Plugin::DieNicely qw/OK/;
use Carp;

croak "croaked and Nagios can detect me";
