#!/usr/bin/env perl

# $Id: runtests.t 7899 2012-04-10 17:41:21Z jonasbn $

use strict;
use warnings;

use lib qw(t);

use Test::Class::RequirePackageNamePattern;

Test::Class->runtests;