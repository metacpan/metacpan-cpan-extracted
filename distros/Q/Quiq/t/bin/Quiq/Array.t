#!/usr/bin/env perl

package Quiq::Array::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Array');
}

# -----------------------------------------------------------------------------

sub test_compare : Test(12) {
    my $self = shift;

    my $arr1 = Quiq::Array->new;
    my $arr2 = Quiq::Array->new;
    my $arr1_res = [];
    my $arr2_res = [];
    my $arr_res = [];

    my ($a1,$a2,$a) = $arr1->compare($arr2);
    # warn "\n@$a1\n@$a2\n@$a\n";

    $self->ok($a1->eq($arr1_res));
    $self->ok($a2->eq($arr2_res));
    $self->ok($a->eq($arr_res));

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $arr1 = Quiq::Array->new;
    $arr2 = Quiq::Array->new([qw/a b c/]);
    $arr1_res = [];
    $arr2_res = [qw/a b c/];
    $arr_res = [];

    ($a1,$a2,$a) = $arr1->compare($arr2);
    # warn "\n@$a1\n@$a2\n@$a\n";

    $self->ok($a1->eq($arr1_res));
    $self->ok($a2->eq($arr2_res));
    $self->ok($a->eq($arr_res));

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $arr1 = Quiq::Array->new([qw/a b c d/]);
    $arr2 = Quiq::Array->new([qw/e b d f g/]);
    $arr1_res = [qw/a c/];
    $arr2_res = [qw/e f g/];
    $arr_res = [qw/b d/];

    ($a1,$a2,$a) = $arr1->compare($arr2);
    # warn "\n@$a1\n@$a2\n@$a\n";

    $self->ok($a1->eq($arr1_res));
    $self->ok($a2->eq($arr2_res));
    $self->ok($a->eq($arr_res));

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Aufruf als Klassenmethode

    ($a1,$a2,$a) = Quiq::Array->compare($arr1,$arr2);

    $self->ok($a1->eq($arr1_res));
    $self->ok($a2->eq($arr2_res));
    $self->ok($a->eq($arr_res));
}

# -----------------------------------------------------------------------------

sub test_decode : Test(2) {
    my $self = shift;

    my $encoding = 'utf-8';
    my @arr = do {
        no utf8;
        qw/Ä Ö Ü/;
    };
    my $expected = [qw/Ä Ö Ü/];

    Quiq::Array->decode(\@arr,$encoding);
    $self->isDeeply(\@arr,$expected);

    @arr = do {
        no utf8;
        qw/Ä Ö Ü/;
    };
    my $arr = Quiq::Array->new(\@arr);
    $arr->decode($encoding);
    $self->isDeeply($arr,$expected);
}

# -----------------------------------------------------------------------------

sub test_exists : Test(5) {
    my $self = shift;

    my $obj = Quiq::Array->new([qw/p e r l m o n g e r s/]);

    my $bool = $obj->exists('p');
    $self->is($bool,1,'erstes Element');

    $bool = $obj->exists('r');
    $self->is($bool,1,'Element mehrfach');

    $bool = Quiq::Array->exists($obj,'r');
    $self->is($bool,1,'Element mehrfach (Klassenmethode)');

    $bool = $obj->exists('s');
    $self->is($bool,1,'letztes Element');

    $bool = $obj->exists('z');
    $self->is($bool,0,'nicht gefunden');
}

# -----------------------------------------------------------------------------

sub test_extractKeyVal : Test(2) {
    my $self = shift;

    my @arr = (a=>1,b=>2,c=>3);

    my $val = Quiq::Array->extractKeyVal(\@arr,'b');
    $self->is($val,2);
    $self->isDeeply(\@arr,[a=>1,c=>3]);

}

# -----------------------------------------------------------------------------

sub test_eq : Test(4) {
    my $self = shift;

    my $arr = Quiq::Array->new([qw/a b c/]);
    my @arr = qw/a b/;
    my $bool = $arr->eq(\@arr);
    $self->ok(!$bool);

    $arr = Quiq::Array->new([qw/a b c/]);
    @arr = qw/a b c d/;
    $bool = $arr->eq(\@arr);
    $self->ok(!$bool);

    $arr = Quiq::Array->new([qw/a b c/]);
    @arr = qw/a b c/;
    $bool = $arr->eq(\@arr);
    $self->ok($bool);

    $bool = Quiq::Array->eq($arr,\@arr);
    $self->ok($bool);
}

# -----------------------------------------------------------------------------

sub test_findPairValue : Test(3) {
    my $self = shift;

    my $obj = Quiq::Array->new([a=>1,b=>2,c=>3]);

    my $val = $obj->findPairValue('b');
    $self->is($val,2);
    $self->isDeeply($obj,[a=>1,b=>2,c=>3]);

    $val = $obj->findPairValue('z');
    $self->is($val,undef);
}

# -----------------------------------------------------------------------------

sub test_index : Test(5) {
    my $self = shift;

    my $arr = Quiq::Array->new([qw/p e r l m o n g e r s/]);

    my $n = $arr->index('p');
    $self->is($n,0,'erstes Element');

    $n = $arr->index('r');
    $self->is($n,2,'Element mehrfach');

    $n = Quiq::Array->index($arr,'r');
    $self->is($n,2,'Element mehrfach (Klassenmethode)');

    $n = $arr->index('s');
    $self->is($n,10,'letztes Element');

    $n = $arr->index('z');
    $self->is($n,-1,'nicht gefunden');
}

# -----------------------------------------------------------------------------

sub test_last : Test(3) {
    my $self = shift;

    my $obj = Quiq::Array->new;

    my $val = $obj->last;
    $self->is($val,undef);

    my @arr = qw/eins zwei drei/;
    $obj = Quiq::Array->new(\@arr);

    $val = $obj->last;
    $self->is($val,'drei');

    $val = Quiq::Array->last(\@arr);
    $self->is($val,'drei');
}

# -----------------------------------------------------------------------------

sub test_maxLength : Test(3) {
    my $self = shift;

    my $obj = Quiq::Array->new;
    my $l = $obj->maxLength;
    $self->is($l,0);

    my @arr = qw/Dies ist ein kleiner Test/;
    $obj = Quiq::Array->new(\@arr);
    $l = $obj->maxLength;
    $self->is($l,7);

    $l = Quiq::Array->maxLength(\@arr);
    $self->is($l,7);
}

# -----------------------------------------------------------------------------

sub test_pick : Test(6) {
    my $self = shift;

    my $arr = Quiq::Array->new;

    my $arr2 = $arr->pick(2);
    $self->isDeeply($arr2,[],'leer');

    $arr2 = Quiq::Array->pick($arr,2);
    $self->isDeeply($arr2,[],'leer');

    $arr = Quiq::Array->new([qw/x a t q c c d/]);

    $arr2 = $arr->pick(2);
    $self->isDeeply($arr2,[qw/x t c d/],'pick 2');

    $arr2 = Quiq::Array->pick($arr,2);
    $self->isDeeply($arr2,[qw/x t c d/],'pick 2');

    $arr2 = $arr->pick(2,1);
    $self->isDeeply($arr2,[qw/a q c/],'pick 2,1');

    $arr2 = Quiq::Array->pick($arr,2,1);
    $self->isDeeply($arr2,[qw/a q c/],'pick 2,1');
}

# -----------------------------------------------------------------------------

sub test_push : Test(2) {
    my $self = shift;

    my $obj = Quiq::Array->new;

    $obj->push('eins');
    $self->is($obj->[-1],'eins');

    my @arr = qw/eins zwei drei/;
    $obj = Quiq::Array->new(\@arr);

    $obj->push('vier');
    $self->is($obj->[-1],'vier');
}

# -----------------------------------------------------------------------------

sub test_select_1 : Test(2) {
    my $self = shift;

    my @arr = Quiq::Array->select([qw/patch001 blubb gaga patch002/],
        qr/patch\d+/);
    $self->isDeeply(\@arr,[qw/patch001 patch002/]);

    my $arr2 = Quiq::Array->select([qw/patch001 blubb gaga patch002/],
        sub {$_[0] !~ qr/\d+/});
    $self->isDeeply($arr2,[qw/blubb gaga/]);
}

# -----------------------------------------------------------------------------

sub test_select_2 : Test(2) {
    my $self = shift;

    my $arr = Quiq::Array->new([qw/patch001 blubb gaga patch002/]);
    my @arr = $arr->select(qr/patch\d+/);
    $self->isDeeply(\@arr,[qw/patch001 patch002/]);

    my $arr2 = $arr->select(sub {$_[0] !~ qr/\d+/});
    $self->isDeeply($arr2,[qw/blubb gaga/]);
}

# -----------------------------------------------------------------------------

sub test_sort : Test(3) {
    my $self = shift;

    my $obj = Quiq::Array->new([qw/rot gelb blau/])->sort;
    $self->isDeeply($obj,[qw/blau gelb rot/]);

    $obj = Quiq::Array->new([qw/rot gelb blau/]);
    my @arr = $obj->sort;
    $self->isDeeply(\@arr,[qw/blau gelb rot/]);
    $self->isDeeply($obj,[qw/rot gelb blau/]);
}

# -----------------------------------------------------------------------------

sub test_gcd : Test(5) {
    my $self = shift;

    my $gcd = Quiq::Array->gcd([]);
    $self->is($gcd,undef);

    $gcd = Quiq::Array->gcd([77]);
    $self->is($gcd,77);

    $gcd = Quiq::Array->gcd([4,8,12]);
    $self->is($gcd,4);

    $gcd = Quiq::Array->gcd([18,9,0]);
    $self->is($gcd,9);

    $gcd = Quiq::Array->gcd([23,11,19,43]);
    $self->is($gcd,1);
}

# -----------------------------------------------------------------------------

sub test_min : Test(3) {
    my $self = shift;

    my $arr = Quiq::Array->new;
    my $x = $arr->min;
    $self->ok(!defined $x);

    $arr = Quiq::Array->new([qw/18 21 21 27 46 27 27 30 31 45/]);
    $x = $arr->min;
    $self->is($x,18);

    Quiq::Array->min([qw/18 21 21 27 46 27 27 30 31 45/]);
    $x = $arr->min;
    $self->is($x,18);
}

# -----------------------------------------------------------------------------

sub test_max : Test(3) {
    my $self = shift;

    my $arr = Quiq::Array->new;
    my $x = $arr->max;
    $self->ok(!defined $x);

    $arr = Quiq::Array->new([qw/18 21 21 27 46 27 27 30 31 45/]);
    $x = $arr->max;
    $self->is($x,46);

    Quiq::Array->max([qw/18 21 21 27 46 27 27 30 31 45/]);
    $x = $arr->max;
    $self->is($x,46);
}

# -----------------------------------------------------------------------------

sub test_minMax : Test(6) {
    my $self = shift;

    my $arr = Quiq::Array->new;
    my ($min,$max) = $arr->minMax;
    $self->ok(!defined $min);
    $self->ok(!defined $max);

    $arr = Quiq::Array->new([qw/18 21 21 27 46 27 27 30 31 45/]);
    ($min,$max) = $arr->minMax;
    $self->is($min,18);
    $self->is($max,46);

    Quiq::Array->minMax([qw/18 21 21 27 46 27 27 30 31 45/]);
    ($min,$max) = $arr->minMax;
    $self->is($min,18);
    $self->is($max,46);
}

# -----------------------------------------------------------------------------

sub test_meanValue : Test(3) {
    my $self = shift;

    my $arr = Quiq::Array->new;
    my $x = $arr->meanValue;
    $self->ok(!defined $x);

    $arr = Quiq::Array->new([qw/18 21 21 27 27 27 30 31 45/]);
    $x = $arr->meanValue;
    $x = Quiq::Math->roundTo($x,2);
    $self->is($x,27.44);

    $x = Quiq::Array->meanValue([qw/18 21 21 27 27 27 30 31 45/]);
    $x = Quiq::Math->roundTo($x,2);
    $self->is($x,27.44);
}

# -----------------------------------------------------------------------------

sub test_standardDeviation : Test(4) {
    my $self = shift;

    my $arr = Quiq::Array->new;
    my $x = $arr->standardDeviation;
    $self->ok(!defined $x);

    $arr = Quiq::Array->new([18]);
    $x = $arr->standardDeviation;
    $self->is($x,0);

    $arr = Quiq::Array->new([qw/18 21 21 27 27 27 30 31 45/]);
    $x = $arr->standardDeviation;
    $x = Quiq::Math->roundTo($x,2);
    $self->is($x,7.91);

    $x = Quiq::Array->standardDeviation([qw/18 21 21 27 27 27 30 31 45/]);
    $x = Quiq::Math->roundTo($x,2);
    $self->is($x,7.91);
}

# -----------------------------------------------------------------------------

sub test_variance : Test(4) {
    my $self = shift;

    my $x = Quiq::Array->new->variance;
    $self->ok(!defined $x);

    $x = Quiq::Array->new([18])->variance;
    $self->is($x,0);

    $x = Quiq::Array->new([qw/18 21 21 27 27 27 30 31 45/])->variance;
    $x = Quiq::Math->roundTo($x,2);
    $self->is($x,62.53);

    $x = Quiq::Array->variance([qw/18 21 21 27 27 27 30 31 45/]);
    $x = Quiq::Math->roundTo($x,2);
    $self->is($x,62.53);
}

# -----------------------------------------------------------------------------

sub test_median : Test(5) {
    my $self = shift;

    my $x = Quiq::Array->new->median;
    $self->ok(!defined $x);

    $x = Quiq::Array->new([7])->median;
    $self->is($x,7);

    $x = Quiq::Array->new([qw/7 5/])->median;
    $self->is($x,6);

    $x = Quiq::Array->new([qw/4 1 37 2 1/])->median;
    $self->is($x,2);

    $x = Quiq::Array->median([qw/4 1 37 2 1/]);
    $self->is($x,2);
}

# -----------------------------------------------------------------------------

sub test_dump : Test(3) {
    my $self = shift;

    my $arr = Quiq::Array->new(['a'..'d']);
    my $val = $arr->dump;
    $self->is($val,'a|b|c|d');

    $arr = Quiq::Array->new(['\\','|',"\n","\r",undef]);
    $val = $arr->dump;
    $self->is($val,'\\\\|\!|\n|\r|');

    $val = Quiq::Array->dump(['a'..'d']);
    $self->is($val,'a|b|c|d');
}

# -----------------------------------------------------------------------------

sub test_restore : Test(4) {
    my $self = shift;

    my $arr = Quiq::Array->restore('');
    $self->isDeeply($arr,[]);

    $arr = Quiq::Array->restore('a|b|c|d');
    $self->isDeeply($arr,['a'..'d']);

    $arr = Quiq::Array->restore("a\tb\tc\td","\t");
    $self->isDeeply($arr,['a'..'d']);

    $arr = Quiq::Array->restore('a\\nb|c\!d');
    $self->isDeeply($arr,["a\nb",'c|d']);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Array::Test->runTests;

# eof
