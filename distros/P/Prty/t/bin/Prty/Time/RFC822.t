#!/usr/bin/env perl

package Prty::Time::RFC822::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Time::RFC822');
}

# -----------------------------------------------------------------------------

sub test_get : Test(3) {
    my $self = shift;

    my $str = Prty::Time::RFC822->get(0);
    $self->is($str,'Thu, 01-Jan-1970 00:00:00 GMT');

    # kann in seltenene Fällen fehlschlagen
    my $str1 = Prty::Time::RFC822->get('now');
    my $str2 = Prty::Time::RFC822->get(time);
    $self->is($str1,$str2);

    # kann in seltenene Fällen fehlschlagen
    $str1 = Prty::Time::RFC822->get('+1s');
    $str2 = Prty::Time::RFC822->get(time+1);
    $self->is($str1,$str2);
}

# -----------------------------------------------------------------------------

package main;
Prty::Time::RFC822::Test->runTests;

# eof
