#!/usr/bin/perl -w                                         # -*- perl -*-
# $Id: 10-features.t 4114 2009-03-04 22:28:43Z andrew $

use strict;
use Cwd qw(abs_path);
use FindBin qw($Bin);
use lib ($Bin, "$Bin/../lib");
use PodPOMTestLib;

run_tests(View => 'Text');

