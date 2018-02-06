#!/usr/bin/env perl

package Prty::Socket::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Socket');
}

# -----------------------------------------------------------------------------

sub test_unitTest: Test(3) {
    my $self = shift;

    # Verbindung aufbauen

    my $sock = Prty::Socket->new('google.de',80,-sloppy=>1);
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
Prty::Socket::Test->runTests;

# eof
