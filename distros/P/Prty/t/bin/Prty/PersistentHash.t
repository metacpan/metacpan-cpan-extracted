#!/usr/bin/env perl

package Prty::PersistentHash::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

use Prty::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::PersistentHash');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(4) {
    my $self = shift;

    my $file = '/tmp/hash.db';
    Prty::Path->delete($file);

    # Persistenten Hash erzeugen

    my $h = Prty::PersistentHash->new($file,'rw');
    $self->is(ref($h),'Prty::PersistentHash');

    # Daten schreiben

    $h->set(a=>1,b=>2);
    my @arr = $h->get(qw/a b/);
    $self->isDeeply(\@arr,[1,2]);

    # schließen

    $h->close;
    $self->is($h,undef);

    # erneut öffnen, die Daten müssen noch da sein

    $h = Prty::PersistentHash->new($file,'rw');
    @arr = $h->get(qw/a b/);
    $self->isDeeply(\@arr,[1,2]);

    Prty::Path->delete($file);
}

# -----------------------------------------------------------------------------

package main;
Prty::PersistentHash::Test->runTests;

# eof
