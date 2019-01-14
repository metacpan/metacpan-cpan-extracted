#!/usr/bin/env perl

package Quiq::SoapWsdlServiceCgi::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::SoapWsdlServiceCgi');
}

# -----------------------------------------------------------------------------

sub test_run : Test(0) {
    my $self = shift;

    # Generiere WSDL-Spezifikation für einen "leeren" Service.
    # Die Spezifikation wird nach STDOUT geschrieben und
    # ist daher beim Testen normalerweise nicht sichtbar.

    $ENV{'SCRIPT_URI'} = 'http://my-soap-test';
    $ENV{'QUERY_STRING'} = 'wsdl';
    Quiq::SoapWsdlServiceCgi->run;
}

# -----------------------------------------------------------------------------

package main;
Quiq::SoapWsdlServiceCgi::Test->runTests;

# eof
