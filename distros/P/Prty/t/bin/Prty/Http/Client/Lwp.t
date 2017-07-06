#!/usr/bin/env perl

package Prty::Http::Client::Lwp::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Http::Client::Lwp');
}

# -----------------------------------------------------------------------------

sub test_get : Ignore(2) {
    my $self = shift;

    my $data = Prty::Http::Client::Lwp->get('http://localhost');
    $self->like($data,qr/<html>/i);

    $data = eval { Prty::Http::Client::Lwp->get('http://unknownhostx.de') };
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
Prty::Http::Client::Lwp::Test->runTests;

# eof
