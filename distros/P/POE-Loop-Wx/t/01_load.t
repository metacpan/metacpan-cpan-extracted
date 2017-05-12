#! /usr/bin/perl
# $Id: 01_load.t,v 1.1 2007/11/29 16:45:41 mike Exp $

use strict;
use warnings;

use Test::More tests => 3;

use_ok('Wx');
use_ok('POE');
use_ok('POE::Loop::Wx');
