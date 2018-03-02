#!/usr/bin/env perl

package Prty::Reference::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Reference');
}

# -----------------------------------------------------------------------------

sub test_refType : Test(8) {
    my $self = shift;

    my $ref = \'';
    my $val = Prty::Reference->refType($ref);
    $self->is($val,'SCALAR','refType: String-Referenz, nicht geblesst');

    $ref = [];
    $val = Prty::Reference->refType($ref);
    $self->is($val,'ARRAY','refType: Array-Referenz, nicht geblesst');

    $ref = {};
    $val = Prty::Reference->refType($ref);
    $self->is($val,'HASH','refType: Hash-Referenz, nicht geblesst');

    $ref = sub {};
    $val = Prty::Reference->refType($ref);
    $self->is($val,'CODE','refType: Code-Referenz, nicht geblesst');

    my $str = '';
    $ref = bless \$str,'X';
    $val = Prty::Reference->refType($ref);
    $self->is($val,'SCALAR','refType: String-Referenz, geblesst');

    $ref = bless [],'X';
    $val = Prty::Reference->refType($ref);
    $self->is($val,'ARRAY','refType: Array-Referenz, geblesst');

    $ref = bless {},'X';
    $val = Prty::Reference->refType($ref);
    $self->is($val,'HASH','refType: Code-Referenz, geblesst');

    $ref = bless sub {},'X';
    $val = Prty::Reference->refType($ref);
    $self->is($val,'CODE','refType: Code-Referenz, geblesst');
}

# -----------------------------------------------------------------------------

sub test_isBlessedRef : Test(6) {
    my $self = shift;

    my $ref = \'';
    my $bool = Prty::Reference->isBlessedRef($ref);
    $self->is($bool,0,'isBlessedRef: String-Referenz, nicht geblesst');

    $ref = [];
    $bool = Prty::Reference->isBlessedRef($ref);
    $self->is($bool,0,'isBlessedRef: Array-Referenz, nicht geblesst');

    $ref = {};
    $bool = Prty::Reference->isBlessedRef($ref);
    $self->is($bool,0,'isBlessedRef: Hash-Referenz, nicht geblesst');

    my $str = '';
    $ref = bless \$str,'X';
    $bool = Prty::Reference->isBlessedRef($ref);
    $self->is($bool,1,'isBlessedRef: String-Referenz, geblesst');

    $ref = bless [],'X';
    $bool = Prty::Reference->isBlessedRef($ref);
    $self->is($bool,1,'isBlessedRef: Array-Referenz, geblesst');

    $ref = bless {},'X';
    $bool = Prty::Reference->isBlessedRef($ref);
    $self->is($bool,1,'isBlessedRef: Hash-Referenz, geblesst');
}

# -----------------------------------------------------------------------------

sub test_isArrayRef : Test(3) {
    my $self = shift;

    my $ref = \'x';
    my $bool = Prty::Reference->isArrayRef($ref);
    $self->is($bool,0,'isArrayRef: keine Array-Referenz');

    $ref = [];
    $bool = Prty::Reference->isArrayRef($ref);
    $self->is($bool,1,'isArrayRef: Array-Referenz');

    $ref = bless [],'X';
    $bool = Prty::Reference->isArrayRef($ref);
    $self->is($bool,1,'isArrayRef: geblesste Array-Referenz');
}

# -----------------------------------------------------------------------------

sub test_isCodeRef : Test(3) {
    my $self = shift;

    my $ref = \'x';
    my $bool = Prty::Reference->isCodeRef($ref);
    $self->is($bool,0,'isCodeRef: keine Code-Referenz');

    $ref = sub { 'x' };
    $bool = Prty::Reference->isCodeRef($ref);
    $self->is($bool,1,'isCodeRef: Code-Referenz');

    $ref = sub { 'x' };
    $ref = bless $ref,'X';
    $bool = Prty::Reference->isCodeRef($ref);
    $self->is($bool,1,'isCodeRef: geblesste Code-Referenz');
}

# -----------------------------------------------------------------------------

sub test_isRegexRef : Test(3) {
    my $self = shift;

    my $ref = \'x';
    my $bool = Prty::Reference->isRegexRef($ref);
    $self->is($bool,0,'isRegexRef: keine Regex-Referenz');

    $ref = qr/x/;
    $bool = Prty::Reference->isRegexRef($ref);
    $self->is($bool,1,'isRegexRef: Regex-Referenz');

    $ref = qr/x/;
    $ref = bless $ref,'X';
    $bool = Prty::Reference->isRegexRef($ref);
    $self->is($bool,0,
        'isRegexRef: geblesste Regex-Referenz funktioniert nicht!');
}

# -----------------------------------------------------------------------------

package main;
Prty::Reference::Test->runTests;

# eof
