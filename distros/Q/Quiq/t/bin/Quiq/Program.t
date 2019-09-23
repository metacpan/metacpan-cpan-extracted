#!/usr/bin/env perl

package Quiq::Program::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::FileHandle;
use Quiq::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Program');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(5) {
    my $self = shift;

    my $prg = Quiq::Program->run;
    $self->is(ref($prg),'Quiq::Program');
    my $envH = {X=>1};
    my $argA = ['--help'];
    my $stdoutFile = '/tmp/stdout.txt';
    my $stdoutText = "**stdout**\n";
    my $stderrFile = '/tmp/stderr.txt';
    my $stderrText = "**stderr**\n";

    Quiq::Program->addMethod(main => sub {
        my $self = shift;
        print $stdoutText;
        warn $stderrText;
        return;
    });

    $prg = Quiq::Program->run(undef,
        -env => $envH,
        -argv => $argA,
        # -stdin => \*STDIN,
        -stdout => Quiq::FileHandle->new('>',$stdoutFile),
        -stderr => Quiq::FileHandle->new('>',$stderrFile),
    );
    my $h = $prg->env;
    $self->is($h->{'X'},1);

    my $a = $prg->argv;
    $self->isDeeply($a,$argA);

    my $data = Quiq::Path->read($stdoutFile,-delete=>1);
    $self->is($data,$stdoutText);

    $data = Quiq::Path->read($stderrFile,-delete=>1);
    $self->is($data,$stderrText);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Program::Test->runTests;

# eof
