#!/usr/bin/perl

use Carp;
use Nagios::Plugin::DieNicely qw/CRITICAL/; 

confess "confessed and Nagios can detect me";
