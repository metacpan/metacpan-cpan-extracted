#!/usr/bin/perl

use strict;
use warnings;

use Test;
BEGIN { plan tests => 1 }

use ExtUtils::testlib;
use Net::Calais;
ok eval "require Net::Calais";

1;
