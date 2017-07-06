#!/usr/bin/env perl

package Prty::Record::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Record');
}

# -----------------------------------------------------------------------------

sub test_fromString1 : Test(1) {
    my $self = shift;

    my @arr = Prty::Record->fromString;
    $self->isDeeply(\@arr,[]);
}

sub test_fromString2 : Test(1) {
    my $self = shift;

    my @Rec = (A=>'Dies',B=>"ist\nein",C=>'Test');
    my $Str = "A:\n    Dies\nB:\n    ist\n    ein\nC:\n    Test\n";

    my @arr = Prty::Record->fromString(\$Str);
    $self->isDeeply(\@arr,\@Rec);
}

# -----------------------------------------------------------------------------

sub test_toString : Test(6) {
    my $self = shift;

    my @Rec1 = (A=>'Dies',B=>"ist\nein",C=>'Test');
    my $Str1 = "A:\n    Dies\nB:\n    ist\n    ein\nC:\n    Test\n";

    my @Rec2 = (A=>'Dies',B=>"\nist\nein\n",C=>'Test',D=>undef,E=>'');
    my $Str2 = "A:\n    Dies\nB:\n    ist\n    ein\nC:\n    Test\n".
        "D:\n\nE:\n\n";

    my @Rec3 = (A=>'Dies',B=>"\nist\nein\n",C=>'Test');
    my $Str3 = "A:\n    Dies\nB:\n\n    ist\n    ein\n\nC:\n    Test\n";

    my $val = Prty::Record->toString(@Rec1);
    $self->is($val,$Str1);

    $val = Prty::Record->toString(\@Rec1);
    $self->is($val,$Str1);

    $val = Prty::Record->toString(\@Rec2);
    $self->is($val,$Str2);

    $val = Prty::Record->toString(\@Rec2,-ignoreNull=>1);
    $self->is($val,$Str1);

    $val = Prty::Record->toString(\@Rec3);
    $self->is($val,$Str1);

    $val = Prty::Record->toString(\@Rec3,-strip=>0);
    $self->is($val,$Str3);
}

# -----------------------------------------------------------------------------

sub test_toFile : Test(6) {
    my $self = shift;

    my @Rec1 = (A=>'Dies',B=>"ist\nein",C=>'Test');
    my $Str1 = "A:\n    Dies\nB:\n    ist\n    ein\nC:\n    Test\n";

    my @Rec2 = (A=>'Dies',B=>"\nist\nein\n",C=>'Test',D=>undef,E=>'');
    my $Str2 = "A:\n    Dies\nB:\n    ist\n    ein\nC:\n    Test\n".
        "D:\n\nE:\n\n";

    my @Rec3 = (A=>'Dies',B=>"\nist\nein\n",C=>'Test');
    my $Str3 = "A:\n    Dies\nB:\n\n    ist\n    ein\n\nC:\n    Test\n";

    my $file = "/tmp/toFile$$.rec";

    Prty::Record->toFile($file,@Rec1);
    my $val = Prty::Path->read($file);
    $self->is($val,$Str1);

    Prty::Record->toFile($file,\@Rec1);
    $val = Prty::Path->read($file);
    $self->is($val,$Str1);

    Prty::Record->toFile($file,\@Rec2);
    $val = Prty::Path->read($file);
    $self->is($val,$Str2);

    Prty::Record->toFile($file,\@Rec2,-ignoreNull=>1);
    $val = Prty::Path->read($file);
    $self->is($val,$Str1);

    Prty::Record->toFile($file,\@Rec3);
    $val = Prty::Path->read($file);
    $self->is($val,$Str1);

    Prty::Record->toFile($file,\@Rec3,-strip=>0);
    $val = Prty::Path->read($file);
    $self->is($val,$Str3);
}

# -----------------------------------------------------------------------------

package main;
Prty::Record::Test->runTests;

# eof
