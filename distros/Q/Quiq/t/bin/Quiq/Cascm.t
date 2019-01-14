#!/usr/bin/env perl

package Quiq::Cascm::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Cascm');
}

# -----------------------------------------------------------------------------

sub test_new: Test(9) {
    my $self = shift;

    my $user = 'xv882js';
    my $password = '*secret*';
    my $broker = 'cascm';
    my $projectContext = 'S6800_DSS-PG_2014_N';
    my $viewPath = 'S6800_DSS_PG';
    my $workspace = sprintf '%s/var/workspace',Quiq::Process->homeDir;
    my $defaultState = 'Entwicklung';
    my $keepTempFiles = 0;
    my $verbose = 1;

    my $scm = Quiq::Cascm->new(
        user => $user,
        password => $password,
        broker => $broker,
        projectContext => $projectContext,
        viewPath => $viewPath,
        workspace => $workspace,
        defaultState => $defaultState,
        keepTempFiles => $keepTempFiles,
        verbose => $verbose,
    );

    $self->is(ref($scm),'Quiq::Cascm');
    $self->is($scm->user,$user);
    $self->is($scm->password,$password);
    $self->is($scm->broker,$broker);
    $self->is($scm->projectContext,$projectContext);
    $self->is($scm->workspace,$workspace);
    $self->is($scm->defaultState,$defaultState);
    $self->is($scm->keepTempFiles,0);
    $self->is($scm->verbose,1);

    $self->set(scm=>$scm);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Cascm::Test->runTests;

# eof
