#!/usr/bin/perl

use Carp;
use Nagios::Plugin::DieNicely qw/WARNING/; 

confess "confessed and Nagios can detect me";
