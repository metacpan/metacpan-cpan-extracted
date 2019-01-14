#!/usr/bin/env perl

package Quiq::PersistentHash::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

use Quiq::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::PersistentHash');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(4) {
    my $self = shift;

    my $file = '/tmp/hash.db';
    Quiq::Path->delete($file);

    # Persistenten Hash erzeugen

    my $h = Quiq::PersistentHash->new($file,'rw');
    $self->is(ref($h),'Quiq::PersistentHash');

    # Daten schreiben

    $h->set(a=>1,b=>2);
    my @arr = $h->get(qw/a b/);
    $self->isDeeply(\@arr,[1,2]);

    # schließen

    $h->close;
    $self->is($h,undef);

    # erneut öffnen, die Daten müssen noch da sein

    $h = Quiq::PersistentHash->new($file,'rw');
    @arr = $h->get(qw/a b/);
    $self->isDeeply(\@arr,[1,2]);

    Quiq::Path->delete($file);
}

# -----------------------------------------------------------------------------

package main;
Quiq::PersistentHash::Test->runTests;

# eof
