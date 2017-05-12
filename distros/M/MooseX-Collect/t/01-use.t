#!/usr/bin/perl

use strict;
use warnings;

use Test;
BEGIN { plan tests => 1 }

use ExtUtils::testlib;
use MooseX::Collect;
ok eval "require MooseX::Collect";

1;
