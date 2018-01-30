#!/usr/bin/env perl

package Prty::Program::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

use Prty::FileHandle;
use Prty::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Program');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(5) {
    my $self = shift;

    my $prg = Prty::Program->run;
    $self->is(ref($prg),'Prty::Program');
    my $envH = {X=>1};
    my $argA = ['--help'];
    my $stdoutFile = '/tmp/stdout.txt';
    my $stdoutText = "**stdout**\n";
    my $stderrFile = '/tmp/stderr.txt';
    my $stderrText = "**stderr**\n";

    Prty::Program->addMethod(main=>sub {
        my $self = shift;
        print $stdoutText;
        warn $stderrText;
        return;
    });

    $prg = Prty::Program->run(undef,
        -env=>$envH,
        -argv=>$argA,
        # -stdin=>\*STDIN,
        -stdout=>Prty::FileHandle->new('>',$stdoutFile),
        -stderr=>Prty::FileHandle->new('>',$stderrFile),
    );
    my $h = $prg->env;
    $self->is($h->{'X'},1);

    my $a = $prg->argv;
    $self->isDeeply($a,$argA);

    my $data = Prty::Path->read($stdoutFile,-delete=>1);
    $self->is($data,$stdoutText);

    $data = Prty::Path->read($stderrFile,-delete=>1);
    $self->is($data,$stderrText);
}

# -----------------------------------------------------------------------------

package main;
Prty::Program::Test->runTests;

# eof
