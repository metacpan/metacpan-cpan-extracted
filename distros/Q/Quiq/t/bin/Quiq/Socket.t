#!/usr/bin/env perl

package Quiq::Socket::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Socket');
}

# -----------------------------------------------------------------------------

sub test_unitTest: Test(3) {
    my $self = shift;

    # Verbindung aufbauen

    my $sock = Quiq::Socket->new('google.de',80,-sloppy=>1);
    if (!$sock) {
        $self->skipAll('Verbindung kann nicht aufgebaut werden');
        return;
    }
    $self->ok($sock,'Verbindung aufgebaut');

    # Request senden
    print $sock "GET /\n";

    # Antwort lesen

    my $data;
    while (<$sock>) {
        $data .= $_;
    }
    $self->like($data,qr/^Content-Type/im,'Header Content-Type empfangen');
    $self->like($data,qr/<HTML/i,'HTML-Content empfangen');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Socket::Test->runTests;

# eof
