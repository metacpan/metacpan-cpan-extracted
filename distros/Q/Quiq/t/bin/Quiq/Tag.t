#!/usr/bin/env perl

package Quiq::Tag::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Tag');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(5) {
    my $self = shift;

    # Instantiierung

    my $p = Quiq::Tag->new;
    $self->is(ref $p,'Quiq::Tag');

    # Generierung

    # 1.

    my $code = $p->tag('person',
        firstname => 'Lieschen',
        lastname => 'Müller',
    );
    $self->is($code,qq|<person firstname="Lieschen" lastname="Müller" />\n|);

    # 2.

    $code = $p->tag('bold','sehr schön');
    $self->is($code,"<bold>sehr schön</bold>\n");

    # 3.

    $code = $p->tag('descr',"Dies ist\nein Test\n");
    $self->isText($code,q~
        <descr>
          Dies ist
          ein Test
        </descr>
    ~);

    # 4.

    $code = $p->tag('person','-',
        $p->tag('firstname','Lieschen'),
        $p->tag('lastname','Müller'),
    );
    $self->isText($code,q~
        <person>
          <firstname>Lieschen</firstname>
          <lastname>Müller</lastname>
        </person>
    ~);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Tag::Test->runTests;

# eof
