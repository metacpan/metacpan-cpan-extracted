#!/usr/bin/perl

use FindBin qw($Bin);
use lib ("$Bin/lib");
use MooseX::Getopt::Usage::Formatter::Test;
Test::Class->runtests;
