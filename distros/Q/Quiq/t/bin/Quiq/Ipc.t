#!/usr/bin/env perl

package Quiq::Ipc::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Ipc');
}

# -----------------------------------------------------------------------------

sub test_filter : Test(3) {
    my $self = shift;

    my ($out,$err) = Quiq::Ipc->filter('/bin/cat','Ein Test');
    $self->is($out,'Ein Test');

    # Fix: CPAN Testers
    eval { Quiq::Ipc->filter('false') };
    $self->like($@,qr/ExitCode:\s+1\s+/);

    # Dieser Test schlägt unter Perl 5.8.8 fehl, da $? (Exitcode) 0 ist
    eval { Quiq::Ipc->filter('/bin/unknown_command','Ein Test') };
    $self->like($@,qr/open3:/);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Ipc::Test->runTests;

# eof
