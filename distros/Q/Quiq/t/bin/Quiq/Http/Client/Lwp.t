#!/usr/bin/env perl

package Quiq::Http::Client::Lwp::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Http::Client::Lwp');
}

# -----------------------------------------------------------------------------

sub test_get : Ignore(2) {
    my $self = shift;

    my $data = Quiq::Http::Client::Lwp->get('http://localhost');
    $self->like($data,qr/<html>/i);

    $data = eval { Quiq::Http::Client::Lwp->get('http://unknownhostx.de') };
    if ($@) {
        $self->like($@,qr/HTTP-00001/);
    }
    else {
        # like $data,qr/Forbidden/;
        $self->ok($data);
    }
}

# -----------------------------------------------------------------------------

package main;
Quiq::Http::Client::Lwp::Test->runTests;

# eof
