#!/usr/bin/env perl

package Quiq::SoapWsdlServiceCgi::Demo::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::SoapWsdlServiceCgi::Demo');
}

# -----------------------------------------------------------------------------

package main;
Quiq::SoapWsdlServiceCgi::Demo::Test->runTests;

# eof
