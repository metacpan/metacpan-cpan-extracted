#!/usr/bin/env perl

use lib 't';
use lib 'lib';
use lib '../lib';

use TestKeyValueCoding;
use TestKeyValueCodingSimple;
use TestKeyValueCodingOnPlainObject;
use TestKeyValueCodingUniversal;
use TestKeyValueCodingInheritance;
use TestKeyValueCodingNaming;

BEGIN {
    eval { require Moose };
    unless ($@) {
        eval "use TestKeyValueCodingOnMooseObject";
        eval "use TestKeyValueCodingWithMooseRole";
    }
    eval { require Moo };
    unless ($@) {
        eval "use TestKeyValueCodingOnMooObject";
    }
    eval { require Mouse };
    unless ($@) {
        eval "use TestKeyValueCodingOnMouseObject";
    }
}

Test::Class->runtests;