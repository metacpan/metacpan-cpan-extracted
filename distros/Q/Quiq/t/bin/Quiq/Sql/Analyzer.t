#!/usr/bin/env perl

package Quiq::Sql::Analyzer::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Sql::Analyzer');
}

# -----------------------------------------------------------------------------

sub test_isCreateFunction : Test(4) {
    my $self = shift;

    my $aly = Quiq::Sql::Analyzer->new('postgresql');

    my $bool = $aly->isCreateFunction('SELECT * FROM test');
    $self->is($bool,0);

    $bool = $aly->isCreateFunction('CREATE FUNCTION');
    $self->is($bool,1);

    $bool = $aly->isCreateFunction('Create Function');
    $self->is($bool,1);

    $bool = $aly->isCreateFunction("CREATE\n or\n\nREPLACE   FUNCTION");
    $self->is($bool,1);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Sql::Analyzer::Test->runTests;

# eof
