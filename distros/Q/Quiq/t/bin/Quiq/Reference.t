#!/usr/bin/env perl

package Quiq::Reference::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Reference');
}

# -----------------------------------------------------------------------------

sub test_refType : Test(8) {
    my $self = shift;

    my $ref = \'';
    my $val = Quiq::Reference->refType($ref);
    $self->is($val,'SCALAR','refType: String-Referenz, nicht geblesst');

    $ref = [];
    $val = Quiq::Reference->refType($ref);
    $self->is($val,'ARRAY','refType: Array-Referenz, nicht geblesst');

    $ref = {};
    $val = Quiq::Reference->refType($ref);
    $self->is($val,'HASH','refType: Hash-Referenz, nicht geblesst');

    $ref = sub {};
    $val = Quiq::Reference->refType($ref);
    $self->is($val,'CODE','refType: Code-Referenz, nicht geblesst');

    my $str = '';
    $ref = bless \$str,'X';
    $val = Quiq::Reference->refType($ref);
    $self->is($val,'SCALAR','refType: String-Referenz, geblesst');

    $ref = bless [],'X';
    $val = Quiq::Reference->refType($ref);
    $self->is($val,'ARRAY','refType: Array-Referenz, geblesst');

    $ref = bless {},'X';
    $val = Quiq::Reference->refType($ref);
    $self->is($val,'HASH','refType: Code-Referenz, geblesst');

    $ref = bless sub {},'X';
    $val = Quiq::Reference->refType($ref);
    $self->is($val,'CODE','refType: Code-Referenz, geblesst');
}

# -----------------------------------------------------------------------------

sub test_isBlessedRef : Test(6) {
    my $self = shift;

    my $ref = \'';
    my $bool = Quiq::Reference->isBlessedRef($ref);
    $self->is($bool,0,'isBlessedRef: String-Referenz, nicht geblesst');

    $ref = [];
    $bool = Quiq::Reference->isBlessedRef($ref);
    $self->is($bool,0,'isBlessedRef: Array-Referenz, nicht geblesst');

    $ref = {};
    $bool = Quiq::Reference->isBlessedRef($ref);
    $self->is($bool,0,'isBlessedRef: Hash-Referenz, nicht geblesst');

    my $str = '';
    $ref = bless \$str,'X';
    $bool = Quiq::Reference->isBlessedRef($ref);
    $self->is($bool,1,'isBlessedRef: String-Referenz, geblesst');

    $ref = bless [],'X';
    $bool = Quiq::Reference->isBlessedRef($ref);
    $self->is($bool,1,'isBlessedRef: Array-Referenz, geblesst');

    $ref = bless {},'X';
    $bool = Quiq::Reference->isBlessedRef($ref);
    $self->is($bool,1,'isBlessedRef: Hash-Referenz, geblesst');
}

# -----------------------------------------------------------------------------

sub test_isArrayRef : Test(3) {
    my $self = shift;

    my $ref = \'x';
    my $bool = Quiq::Reference->isArrayRef($ref);
    $self->is($bool,0,'isArrayRef: keine Array-Referenz');

    $ref = [];
    $bool = Quiq::Reference->isArrayRef($ref);
    $self->is($bool,1,'isArrayRef: Array-Referenz');

    $ref = bless [],'X';
    $bool = Quiq::Reference->isArrayRef($ref);
    $self->is($bool,1,'isArrayRef: geblesste Array-Referenz');
}

# -----------------------------------------------------------------------------

sub test_isCodeRef : Test(3) {
    my $self = shift;

    my $ref = \'x';
    my $bool = Quiq::Reference->isCodeRef($ref);
    $self->is($bool,0,'isCodeRef: keine Code-Referenz');

    $ref = sub { 'x' };
    $bool = Quiq::Reference->isCodeRef($ref);
    $self->is($bool,1,'isCodeRef: Code-Referenz');

    $ref = sub { 'x' };
    $ref = bless $ref,'X';
    $bool = Quiq::Reference->isCodeRef($ref);
    $self->is($bool,1,'isCodeRef: geblesste Code-Referenz');
}

# -----------------------------------------------------------------------------

sub test_isRegexRef : Test(3) {
    my $self = shift;

    my $ref = \'x';
    my $bool = Quiq::Reference->isRegexRef($ref);
    $self->is($bool,0,'isRegexRef: keine Regex-Referenz');

    $ref = qr/x/;
    $bool = Quiq::Reference->isRegexRef($ref);
    $self->is($bool,1,'isRegexRef: Regex-Referenz');

    $ref = qr/x/;
    $ref = bless $ref,'X';
    $bool = Quiq::Reference->isRegexRef($ref);
    $self->is($bool,0,
        'isRegexRef: geblesste Regex-Referenz funktioniert nicht!');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Reference::Test->runTests;

# eof
