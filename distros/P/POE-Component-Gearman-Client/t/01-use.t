#!/usr/bin/perl

use strict;
use warnings;

use Test;
BEGIN { plan tests => 1 }

use ExtUtils::testlib;
use POE::Component::Gearman::Client;
ok eval "require POE::Component::Gearman::Client";

1;
