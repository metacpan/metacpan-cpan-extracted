#!/usr/bin/perl

use Carp;
use Nagios::Plugin::DieNicely qw/UNKNOWN/; 

confess "confessed and Nagios can detect me";
