#!/usr/bin/env perl

package Quiq::Record::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Record');
}

# -----------------------------------------------------------------------------

sub test_fromString1 : Test(1) {
    my $self = shift;

    my @arr = Quiq::Record->fromString;
    $self->isDeeply(\@arr,[]);
}

sub test_fromString2 : Test(1) {
    my $self = shift;

    my @Rec = (A=>'Dies',B=>"ist\nein",C=>'Test');
    my $Str = "A:\n    Dies\nB:\n    ist\n    ein\nC:\n    Test\n";

    my @arr = Quiq::Record->fromString(\$Str);
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

    my $val = Quiq::Record->toString(@Rec1);
    $self->is($val,$Str1);

    $val = Quiq::Record->toString(\@Rec1);
    $self->is($val,$Str1);

    $val = Quiq::Record->toString(\@Rec2);
    $self->is($val,$Str2);

    $val = Quiq::Record->toString(\@Rec2,-ignoreNull=>1);
    $self->is($val,$Str1);

    $val = Quiq::Record->toString(\@Rec3);
    $self->is($val,$Str1);

    $val = Quiq::Record->toString(\@Rec3,-strip=>0);
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

    Quiq::Record->toFile($file,@Rec1);
    my $val = Quiq::Path->read($file);
    $self->is($val,$Str1);

    Quiq::Record->toFile($file,\@Rec1);
    $val = Quiq::Path->read($file);
    $self->is($val,$Str1);

    Quiq::Record->toFile($file,\@Rec2);
    $val = Quiq::Path->read($file);
    $self->is($val,$Str2);

    Quiq::Record->toFile($file,\@Rec2,-ignoreNull=>1);
    $val = Quiq::Path->read($file);
    $self->is($val,$Str1);

    Quiq::Record->toFile($file,\@Rec3);
    $val = Quiq::Path->read($file);
    $self->is($val,$Str1);

    Quiq::Record->toFile($file,\@Rec3,-strip=>0);
    $val = Quiq::Path->read($file);
    $self->is($val,$Str3);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Record::Test->runTests;

# eof
