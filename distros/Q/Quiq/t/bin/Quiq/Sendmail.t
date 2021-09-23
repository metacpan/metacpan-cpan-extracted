#!/usr/bin/env perl

package Quiq::Sendmail::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Sendmail');
}

# -----------------------------------------------------------------------------

sub test_send_root: Test(0) {
    my $self = shift;

    if (my $to = $ENV{'QUIQ_TEST_MAIL'}) {
        Quiq::Sendmail->send($to,'Test ÄÖÜ','Test ÄÖÜ');
    }
}

# -----------------------------------------------------------------------------

package main;
Quiq::Sendmail::Test->runTests;

# eof
