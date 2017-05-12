#! /usr/bin/perl
# $Id: 01_load.t,v 1.1 2007/08/10 13:36:09 dk Exp $

use strict;
use warnings;

use Test::More tests => 3;

use_ok('Prima::noX11');
use_ok('POE');
use_ok('POE::Loop::Prima');
