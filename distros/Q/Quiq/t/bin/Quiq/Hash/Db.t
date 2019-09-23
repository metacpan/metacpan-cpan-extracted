#!/usr/bin/env perl

package Quiq::Hash::Db::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

use Quiq::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Hash::Db');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(4) {
    my $self = shift;

    my $file = '/tmp/hash.db';
    Quiq::Path->delete($file);

    # Persistenten Hash erzeugen

    my $h = Quiq::Hash::Db->new($file,'rw');
    $self->is(ref($h),'Quiq::Hash::Db');

    # Daten schreiben

    $h->set(a=>1,b=>2);
    my @arr = $h->get(qw/a b/);
    $self->isDeeply(\@arr,[1,2]);

    # schließen

    $h->close;
    $self->is($h,undef);

    # erneut öffnen, die Daten müssen noch da sein

    $h = Quiq::Hash::Db->new($file,'rw');
    @arr = $h->get(qw/a b/);
    $self->isDeeply(\@arr,[1,2]);

    Quiq::Path->delete($file);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Hash::Db::Test->runTests;

# eof
