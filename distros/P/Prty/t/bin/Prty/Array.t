#!/usr/bin/env perl

package Prty::Array::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Array');
}

# -----------------------------------------------------------------------------

sub test_extractKeyVal : Test(2) {
    my $self = shift;

    my @arr = (a=>1,b=>2,c=>3);

    my $val = Prty::Array->extractKeyVal(\@arr,'b');
    $self->is($val,2);
    $self->isDeeply(\@arr,[a=>1,c=>3]);

}

# -----------------------------------------------------------------------------

sub test_findPairValue : Test(3) {
    my $self = shift;

    my $obj = Prty::Array->new([a=>1,b=>2,c=>3]);

    my $val = $obj->findPairValue('b');
    $self->is($val,2);
    $self->isDeeply($obj,[a=>1,b=>2,c=>3]);

    $val = $obj->findPairValue('z');
    $self->is($val,undef);
}

# -----------------------------------------------------------------------------

sub test_index : Test(5) {
    my $self = shift;

    my $arr = Prty::Array->new([qw/p e r l m o n g e r s/]);

    my $n = $arr->index('p');
    $self->is($n,0,'erstes Element');

    $n = $arr->index('r');
    $self->is($n,2,'Element mehrfach');

    $n = Prty::Array->index($arr,'r');
    $self->is($n,2,'Element mehrfach (Klassenmethode)');

    $n = $arr->index('s');
    $self->is($n,10,'letztes Element');

    $n = $arr->index('z');
    $self->is($n,-1,'nicht gefunden');
}

# -----------------------------------------------------------------------------

sub test_last : Test(3) {
    my $self = shift;

    my $obj = Prty::Array->new;

    my $val = $obj->last;
    $self->is($val,undef);

    my @arr = qw/eins zwei drei/;
    $obj = Prty::Array->new(\@arr);

    $val = $obj->last;
    $self->is($val,'drei');

    $val = Prty::Array->last(\@arr);
    $self->is($val,'drei');
}

# -----------------------------------------------------------------------------

sub test_maxLength : Test(3) {
    my $self = shift;

    my $obj = Prty::Array->new;
    my $l = $obj->maxLength;
    $self->is($l,0);

    my @arr = qw/Dies ist ein kleiner Test/;
    $obj = Prty::Array->new(\@arr);
    $l = $obj->maxLength;
    $self->is($l,7);

    $l = Prty::Array->maxLength(\@arr);
    $self->is($l,7);
}

# -----------------------------------------------------------------------------

sub test_push : Test(2) {
    my $self = shift;

    my $obj = Prty::Array->new;

    $obj->push('eins');
    $self->is($obj->[-1],'eins');

    my @arr = qw/eins zwei drei/;
    $obj = Prty::Array->new(\@arr);

    $obj->push('vier');
    $self->is($obj->[-1],'vier');
}

# -----------------------------------------------------------------------------

sub test_select_1 : Test(2) {
    my $self = shift;

    my @arr = Prty::Array->select([qw/patch001 blubb gaga patch002/],
        qr/patch\d+/);
    $self->isDeeply(\@arr,[qw/patch001 patch002/]);

    my $arr2 = Prty::Array->select([qw/patch001 blubb gaga patch002/],
        sub {$_[0] !~ qr/\d+/});
    $self->isDeeply($arr2,[qw/blubb gaga/]);
}

# -----------------------------------------------------------------------------

sub test_select_2 : Test(2) {
    my $self = shift;

    my $arr = Prty::Array->new([qw/patch001 blubb gaga patch002/]);
    my @arr = $arr->select(qr/patch\d+/);
    $self->isDeeply(\@arr,[qw/patch001 patch002/]);

    my $arr2 = $arr->select(sub {$_[0] !~ qr/\d+/});
    $self->isDeeply($arr2,[qw/blubb gaga/]);
}

# -----------------------------------------------------------------------------

sub test_sort : Test(3) {
    my $self = shift;

    my $obj = Prty::Array->new([qw/rot gelb blau/])->sort;
    $self->isDeeply($obj,[qw/blau gelb rot/]);

    $obj = Prty::Array->new([qw/rot gelb blau/]);
    my @arr = $obj->sort;
    $self->isDeeply(\@arr,[qw/blau gelb rot/]);
    $self->isDeeply($obj,[qw/rot gelb blau/]);
}

# -----------------------------------------------------------------------------

sub test_gcd : Test(5) {
    my $self = shift;

    my $gcd = Prty::Array->gcd([]);
    $self->is($gcd,undef);

    $gcd = Prty::Array->gcd([77]);
    $self->is($gcd,77);

    $gcd = Prty::Array->gcd([4,8,12]);
    $self->is($gcd,4);

    $gcd = Prty::Array->gcd([18,9,0]);
    $self->is($gcd,9);

    $gcd = Prty::Array->gcd([23,11,19,43]);
    $self->is($gcd,1);
}

# -----------------------------------------------------------------------------

sub test_min : Test(3) {
    my $self = shift;

    my $arr = Prty::Array->new;
    my $x = $arr->min;
    $self->ok(!defined $x);

    $arr = Prty::Array->new([qw/18 21 21 27 46 27 27 30 31 45/]);
    $x = $arr->min;
    $self->is($x,18);

    Prty::Array->min([qw/18 21 21 27 46 27 27 30 31 45/]);
    $x = $arr->min;
    $self->is($x,18);
}

# -----------------------------------------------------------------------------

sub test_max : Test(3) {
    my $self = shift;

    my $arr = Prty::Array->new;
    my $x = $arr->max;
    $self->ok(!defined $x);

    $arr = Prty::Array->new([qw/18 21 21 27 46 27 27 30 31 45/]);
    $x = $arr->max;
    $self->is($x,46);

    Prty::Array->max([qw/18 21 21 27 46 27 27 30 31 45/]);
    $x = $arr->max;
    $self->is($x,46);
}

# -----------------------------------------------------------------------------

sub test_minMax : Test(6) {
    my $self = shift;

    my $arr = Prty::Array->new;
    my ($min,$max) = $arr->minMax;
    $self->ok(!defined $min);
    $self->ok(!defined $max);

    $arr = Prty::Array->new([qw/18 21 21 27 46 27 27 30 31 45/]);
    ($min,$max) = $arr->minMax;
    $self->is($min,18);
    $self->is($max,46);

    Prty::Array->minMax([qw/18 21 21 27 46 27 27 30 31 45/]);
    ($min,$max) = $arr->minMax;
    $self->is($min,18);
    $self->is($max,46);
}

# -----------------------------------------------------------------------------

sub test_meanValue : Test(3) {
    my $self = shift;

    my $arr = Prty::Array->new;
    my $x = $arr->meanValue;
    $self->ok(!defined $x);

    $arr = Prty::Array->new([qw/18 21 21 27 27 27 30 31 45/]);
    $x = $arr->meanValue;
    $x = Prty::Formatter->roundTo($x,2);
    $self->is($x,27.44);

    $x = Prty::Array->meanValue([qw/18 21 21 27 27 27 30 31 45/]);
    $x = Prty::Formatter->roundTo($x,2);
    $self->is($x,27.44);
}

# -----------------------------------------------------------------------------

sub test_standardDeviation : Test(4) {
    my $self = shift;

    my $arr = Prty::Array->new;
    my $x = $arr->standardDeviation;
    $self->ok(!defined $x);

    $arr = Prty::Array->new([18]);
    $x = $arr->standardDeviation;
    $self->is($x,0);

    $arr = Prty::Array->new([qw/18 21 21 27 27 27 30 31 45/]);
    $x = $arr->standardDeviation;
    $x = Prty::Formatter->roundTo($x,2);
    $self->is($x,7.91);

    $x = Prty::Array->standardDeviation([qw/18 21 21 27 27 27 30 31 45/]);
    $x = Prty::Formatter->roundTo($x,2);
    $self->is($x,7.91);
}

# -----------------------------------------------------------------------------

sub test_variance : Test(4) {
    my $self = shift;

    my $x = Prty::Array->new->variance;
    $self->ok(!defined $x);

    $x = Prty::Array->new([18])->variance;
    $self->is($x,0);

    $x = Prty::Array->new([qw/18 21 21 27 27 27 30 31 45/])->variance;
    $x = Prty::Formatter->roundTo($x,2);
    $self->is($x,62.53);

    $x = Prty::Array->variance([qw/18 21 21 27 27 27 30 31 45/]);
    $x = Prty::Formatter->roundTo($x,2);
    $self->is($x,62.53);
}

# -----------------------------------------------------------------------------

sub test_median : Test(5) {
    my $self = shift;

    my $x = Prty::Array->new->median;
    $self->ok(!defined $x);

    $x = Prty::Array->new([7])->median;
    $self->is($x,7);

    $x = Prty::Array->new([qw/7 5/])->median;
    $self->is($x,6);

    $x = Prty::Array->new([qw/4 1 37 2 1/])->median;
    $self->is($x,2);

    $x = Prty::Array->median([qw/4 1 37 2 1/]);
    $self->is($x,2);
}

# -----------------------------------------------------------------------------

sub test_dump : Test(3) {
    my $self = shift;

    my $arr = Prty::Array->new(['a'..'d']);
    my $val = $arr->dump;
    $self->is($val,'a|b|c|d');

    $arr = Prty::Array->new(['\\','|',"\n","\r",undef]);
    $val = $arr->dump;
    $self->is($val,'\\\\|\!|\n|\r|');

    $val = Prty::Array->dump(['a'..'d']);
    $self->is($val,'a|b|c|d');
}

# -----------------------------------------------------------------------------

sub test_restore : Test(4) {
    my $self = shift;

    my $arr = Prty::Array->restore('');
    $self->isDeeply($arr,[]);

    $arr = Prty::Array->restore('a|b|c|d');
    $self->isDeeply($arr,['a'..'d']);

    $arr = Prty::Array->restore("a\tb\tc\td","\t");
    $self->isDeeply($arr,['a'..'d']);

    $arr = Prty::Array->restore('a\\nb|c\!d');
    $self->isDeeply($arr,["a\nb",'c|d']);
}

# -----------------------------------------------------------------------------

package main;
Prty::Array::Test->runTests;

# eof
