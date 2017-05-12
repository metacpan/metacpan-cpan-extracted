#!/usr/bin/perl

use Carp;
use Nagios::Plugin::DieNicely qw/OK/; 

confess "confessed and Nagios can detect me";
