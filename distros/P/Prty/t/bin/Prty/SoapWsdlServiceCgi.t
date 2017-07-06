#!/usr/bin/env perl

package Prty::SoapWsdlServiceCgi::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::SoapWsdlServiceCgi');
}

# -----------------------------------------------------------------------------

sub test_run : Test(0) {
    my $self = shift;

    # Generiere WSDL-Spezifikation für einen "leeren" Service.
    # Die Spezifikation wird nach STDOUT geschrieben und
    # ist daher beim Testen normalerweise nicht sichtbar.

    $ENV{'SCRIPT_URI'} = 'http://my-soap-test';
    $ENV{'QUERY_STRING'} = 'wsdl';
    Prty::SoapWsdlServiceCgi->run;
}

# -----------------------------------------------------------------------------

package main;
Prty::SoapWsdlServiceCgi::Test->runTests;

# eof
