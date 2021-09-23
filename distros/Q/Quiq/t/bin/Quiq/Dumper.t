#!/usr/bin/env perl

package Quiq::Dumper::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Dumper');
}

# -----------------------------------------------------------------------------

sub test_dump : Test(4) {
    my $self = shift;

    my $str = Quiq::Dumper->dump(undef);
    $self->is($str,'undef');

    $str = Quiq::Dumper->dump('abc');
    $self->is($str,'"abc"');

    $str = Quiq::Dumper->dump(\undef);
    $self->is($str,'\undef');

    $str = Quiq::Dumper->dump(\'abc');
    $self->is($str,'\"abc"');

    $str = Quiq::Dumper->dump({a=>1,b=>2,c=>3});
    # warn $str;

    $str = Quiq::Dumper->dump([1,2,3]);
    # warn $str;

    $str = Quiq::Dumper->dump(qr/^(abc|def)/);
    # warn $str;
}

# -----------------------------------------------------------------------------

package main;
Quiq::Dumper::Test->runTests;

# eof
