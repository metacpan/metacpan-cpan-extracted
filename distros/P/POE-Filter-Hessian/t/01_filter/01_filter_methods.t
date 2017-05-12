#!/usr/bin/perl

use strict;
use warnings;

use lib qw{./t/lib};
use TestSuite::Filter::V1;
TestSuite::Filter::V1->runtests();
