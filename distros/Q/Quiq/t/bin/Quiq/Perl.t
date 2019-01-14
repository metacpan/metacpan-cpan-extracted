#!/usr/bin/env perl

package Quiq::Perl::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Perl');
}

# -----------------------------------------------------------------------------

sub test_print : Test(2) {
    my $self = shift;

    my $testFile = '/tmp/print.tst';
    my $testData = "Test $$\n";

    local *F;
    open F,'>',$testFile or die "open fehlgeschlagen";

    Quiq::Perl->print(*F,$testData);
    $self->ok(1,'Daten geschrieben');

    close F;

    my $val = Quiq::Path->read($testFile);
    $self->is($val,$testData,'Dateiinhalt ok');    
    Quiq::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_sigilToType : Test(4) {
    my $self = shift;

    my $val = Quiq::Perl->sigilToType('$');
    $self->is($val,'SCALAR');

    $val = Quiq::Perl->sigilToType('@');
    $self->is($val,'ARRAY');

    $val = Quiq::Perl->sigilToType('%');
    $self->is($val,'HASH');

    eval { Quiq::Perl->sigilToType('!') };
    $self->like($@,qr/PERL-00001:/);
}

# -----------------------------------------------------------------------------

sub test_stash : Test(3) {
    my $self = shift;

    my $ref = Quiq::Perl->stash('main');
    $self->is(ref($ref),'HASH');

    $ref = Quiq::Perl->stash('UNIVERSAL');
    $self->is(ref($ref),'HASH');

    my $package = ucfirst "stash$$"; # Zufallsname
    $ref = Quiq::Perl->stash($package);
    $self->is($ref,undef);
}

# -----------------------------------------------------------------------------

sub test_ : Startup(0) {
    my $self = shift;

    #   Pkg1
    #    |
    #   Pkg2
    #   / \
    # Pkg3 Pkg4
    #   \ /
    #   Pkg5

    Quiq::Perl->createClass('Pkg1');
    Quiq::Perl->createClass('Pkg2','Pkg1');
    Quiq::Perl->createClass('Pkg3','Pkg2');
    Quiq::Perl->createClass('Pkg4','Pkg2');
    Quiq::Perl->createClass('Pkg5','Pkg3','Pkg4');
}

# -----------------------------------------------------------------------------

sub test_packages : Test(4) {
    my $self = shift;

    my @arr = Quiq::Perl->packages('main');
    $self->ok(grep { $_ eq 'main' } @arr);
    $self->ok(grep { $_ eq 'UNIVERSAL' } @arr);

    @arr = Quiq::Perl->packages(ref($self));
    $self->isDeeply(\@arr,['Quiq::Perl::Test']);

    my $package = uc "packages$$"; # Zufallsname
    @arr = Quiq::Perl->packages($package);
    $self->isDeeply(\@arr,[]);
}

# -----------------------------------------------------------------------------

sub test_createClass1 : Test(3) {
    my $self = shift;

    my $bool = Quiq::Perl->classExists('MyNewClass1');
    $self->ok(!$bool);
    Quiq::Perl->createClass('MyNewClass1');
    $bool = Quiq::Perl->classExists('MyNewClass1');
    $self->ok($bool);
    my $a = Quiq::Perl->getVar('MyNewClass1','@','ISA');
    $self->is($a,undef);
}

# -----------------------------------------------------------------------------

sub test_createClass2 : Test(3) {
    my $self = shift;

    my $bool = Quiq::Perl->classExists('MyNewClass2');
    $self->ok(!$bool);
    Quiq::Perl->createClass('MyNewClass2','Quiq::Object');
    $bool = Quiq::Perl->classExists('MyNewClass2');
    $self->ok($bool);
    my $a = Quiq::Perl->getVar('MyNewClass2','@','ISA');
    $self->isDeeply($a,['Quiq::Object']);
}

# -----------------------------------------------------------------------------

sub test_classExists : Test(2) {
    my $self = shift;

    my $pkg = uc "classExists$$"; # Zufallsname

    # Package existiert nicht

    my $bool = Quiq::Perl->classExists($pkg);
    $self->ok(!$bool,'Package existiert nicht');

    # Package existiert

    $bool = Quiq::Perl->classExists('Quiq::Perl');
    $self->ok($bool,'Package existiert');
}

# -----------------------------------------------------------------------------

sub test_baseClasses : Test(1) {
    my $self = shift;

    # UNIVERSAL
    #
    #   Pkg1
    #    |
    #   Pkg2
    #   / \
    # Pkg3 Pkg4
    #   \ /
    #   Pkg5

    my @arr = Quiq::Perl->baseClasses('Pkg5');
    @arr = splice @arr,0,5; # es können weitere Packages folgen
    $self->isDeeply(\@arr,[qw/Pkg3 Pkg2 Pkg1 Pkg4 UNIVERSAL/]);
}

# -----------------------------------------------------------------------------

sub test_baseClassesISA : Test(3) {
    my $self = shift;

    #   Pkg1
    #    |
    #   Pkg2
    #   / \
    # Pkg3 Pkg4
    #   \ /
    #   Pkg5

    my @arr = Quiq::Perl->baseClassesISA('Pkg2');
    $self->isDeeply(\@arr,['Pkg1']);

    @arr = Quiq::Perl->baseClassesISA('Pkg3');
    $self->isDeeply(\@arr,[qw/Pkg2 Pkg1/]);

    @arr = Quiq::Perl->baseClassesISA('Pkg5');
    $self->isDeeply(\@arr,[qw/Pkg3 Pkg2 Pkg1 Pkg4/]);
}

# -----------------------------------------------------------------------------

sub test_hierarchyISA : Test(3) {
    my $self = shift;

    #   Pkg1
    #    |
    #   Pkg2
    #   / \
    # Pkg3 Pkg4
    #   \ /
    #   Pkg5

    my @arr = Quiq::Perl->hierarchyISA('Pkg2');
    $self->isDeeply(\@arr,['Pkg1']);

    @arr = Quiq::Perl->hierarchyISA('Pkg3');
    $self->isDeeply(\@arr,[qw/Pkg2 Pkg1/]);

    @arr = Quiq::Perl->hierarchyISA('Pkg5');
    $self->isDeeply(\@arr,[qw/Pkg3 Pkg2 Pkg1 Pkg4 Pkg2 Pkg1/]);
}

# -----------------------------------------------------------------------------

sub test_subClasses : Test(2) {
    my $self = shift;

    #   Pkg1
    #    |
    #   Pkg2
    #   / \
    # Pkg3 Pkg4
    #   \ /
    #   Pkg5

    my $arr = Quiq::Perl->subClasses('Pkg1')->sort;
    $self->isDeeply($arr,[qw/Pkg2 Pkg3 Pkg4 Pkg5/]);

    my @arr = Quiq::Perl->subClasses('Pkg4');
    $self->isDeeply(\@arr,['Pkg5']);
}

# -----------------------------------------------------------------------------

sub test_nextMethod : Test(6) {
    my $self = shift;

    my ($pkg,$meth) = Quiq::Perl->nextMethod('Pkg5','f2','Pkg3');
    $self->is($pkg,undef);
    $self->is($meth,undef);

    Quiq::Perl->createAlias('Pkg2',m=>sub{2});
    Quiq::Perl->createAlias('Pkg4',m=>sub{4});

    ($pkg,$meth) = Quiq::Perl->nextMethod('Pkg5','m','Pkg5');
    $self->is($pkg,'Pkg2');
    $self->is($meth->(),2);

    ($pkg,$meth) = Quiq::Perl->nextMethod('Pkg5','m',$pkg); # Fortsetzung
    $self->is($pkg,'Pkg4');
    $self->is($meth->(),4);
}

# -----------------------------------------------------------------------------

sub test_classNameToPath : Test(1) {
    my $self = shift;

    my $val = Quiq::Perl->classNameToPath('A::B::C');
    $self->is($val,'A/B/C');
}

# -----------------------------------------------------------------------------

sub test_classPathToName : Test(2) {
    my $self = shift;

    my $val = Quiq::Perl->classPathToName('A/B/C');
    $self->is($val,'A::B::C');

    $val = Quiq::Perl->classPathToName('A/B/C.pm');
    $self->is($val,'A::B::C');
}

# -----------------------------------------------------------------------------

sub test_createAlias : Test(1) {
    my $self = shift;

    Quiq::Perl->createAlias('Pkg1',m1=>sub{$_[1]});

    my $val = Pkg1->m1(5);
    $self->is($val,5,'createAlias');
}

# -----------------------------------------------------------------------------

sub test_createHash : Test(2) {
    my $self = shift;

    my $ref = Quiq::Perl->createHash(Pkg1=>'H');
    $ref->{'a'} = 4711;

    no warnings 'once';
    my $val = $Pkg1::H{'a'};
    $self->is($val,4711);

    bless $ref,'Quiq::Hash';
    my @arr = $ref->keys;
    $self->isDeeply(\@arr,['a']);
}

# -----------------------------------------------------------------------------

sub test_getHash : Test(1) {
    my $self = shift;

    my $package = ucfirst "getHash$$"; # Zufallsname

    my $ref1 = Quiq::Perl->createHash($package,'H');
    my $ref2 = Quiq::Perl->getHash($package,'H');
    $self->is($ref2,$ref1);
}

# -----------------------------------------------------------------------------

sub test_setHash : Test(4) {
    my $self = shift;

    my $pkg = ucfirst "setHash$$"; # Zufallsname

    my $hash1 = {qw/a 1 b 2 c 3/};
    my $ref1 = Quiq::Perl->setHash($pkg,'x',$hash1);
    $self->is(ref($ref1),'HASH');
    $self->isDeeply($ref1,$hash1);

    my $hash2 = {qw/d 4 e 5 f 6/};
    my $ref2 = Quiq::Perl->setHash($pkg,'x',$hash2);
    $self->isDeeply($ref2,$hash2);
    $self->is($ref2,$ref1);
}

# -----------------------------------------------------------------------------

sub test_createArray : Test(2) {
    my $self = shift;

    my $ref = Quiq::Perl->createArray('Pkg1','A');
    $ref->[0] = 4711;

    no warnings 'once';
    my $val = $Pkg1::A[0];
    $self->is($val,4711);

    bless $ref,'Quiq::Array';
    $val = $ref->min;
    $self->is($val,4711);
}

# -----------------------------------------------------------------------------

sub test_getArray : Test(1) {
    my $self = shift;

    my $package = ucfirst "getArray$$"; # Zufallsname

    my $ref1 = Quiq::Perl->createArray($package,'A');
    my $ref2 = Quiq::Perl->getArray($package,'A');
    $self->is($ref2,$ref1);
}

# -----------------------------------------------------------------------------

sub test_setArray : Test(4) {
    my $self = shift;

    my $pkg = ucfirst "setArray$$"; # Zufallsname

    my $arr1 = [qw/a b c/];
    my $ref1 = Quiq::Perl->setArray($pkg,'x',$arr1);
    $self->is(ref($ref1),'ARRAY');
    $self->isDeeply($ref1,$arr1);

    my $arr2 = [qw/d e f/];
    my $ref2 = Quiq::Perl->setArray($pkg,'x',$arr2);
    $self->isDeeply($ref2,$arr2);
    $self->is($ref2,$ref1);
}

# -----------------------------------------------------------------------------

sub test_setScalar : Test(4) {
    my $self = shift;

    my $pkg = ucfirst "setScalar$$"; # Zufallsname

    # Skalar

    my $ref1 = Quiq::Perl->setScalar($pkg,x=>99);
    $self->is(ref($ref1),'SCALAR');
    $self->is($$ref1,99);

    my $ref2 = Quiq::Perl->setScalar($pkg,x=>100);
    $self->is($$ref2,100);
    $self->is($$ref2,$$ref1);
}

# -----------------------------------------------------------------------------

sub test_getScalarValue : Test(1) {
    my $self = shift;

    my $pkg = ucfirst "getScalarValue$$"; # Zufallsname

    Quiq::Perl->setScalar($pkg,x=>99);
    my $val = Quiq::Perl->getScalarValue($pkg,'x');
    $self->is($val,99);
}

# -----------------------------------------------------------------------------

sub test_setVar : Test(12) {
    my $self = shift;

    my $pkg = ucfirst "setVar$$"; # Zufallsname

    # Skalar

    my $ref1 = Quiq::Perl->setVar($pkg,'$','x',\99);
    $self->is(ref($ref1),'SCALAR');
    $self->is($$ref1,99);

    my $ref2 = Quiq::Perl->setVar($pkg,'$','x',\100);
    $self->is($$ref2,100);
    $self->is($$ref2,$$ref1);

    # Array

    my $arr1 = [qw/a b c/];
    $ref1 = Quiq::Perl->setVar($pkg,'@','x',$arr1);
    $self->is(ref($ref1),'ARRAY');
    $self->isDeeply($ref1,$arr1);

    my $arr2 = [qw/d e f/];
    $ref2 = Quiq::Perl->setVar($pkg,'@','x',$arr2);
    $self->isDeeply($ref2,$arr2);
    $self->is($ref2,$ref1);

    # Hash

    my $hash1 = {qw/a 1 b 2 c 3/};
    $ref1 = Quiq::Perl->setVar($pkg,'%','x',$hash1);
    $self->is(ref($ref1),'HASH');
    $self->isDeeply($ref1,$hash1);

    my $hash2 = {qw/d 4 e 5 f 6/};
    $ref2 = Quiq::Perl->setVar($pkg,'%','x',$hash2);
    $self->isDeeply($ref2,$hash2);
    $self->is($ref2,$ref1);
}

# -----------------------------------------------------------------------------

sub test_getVar : Test(72) {
    my $self = shift;

    my $pkg = 'P1';
    unshift @INC,$self->testPath('t/data/class');
    require P1;

    my $test = [
        0,1,1,0,0,1,1,0,
        0,0,1,1,0,0,1,1,
        0,0,0,1,0,0,0,1,
    ];

    # abfragen

    my $i = 0;
    for my $sigil (qw/$ @ %/) {
        for my $name (qw/w1 x1 y1 z1 w2 x2 y2 z2/) {
            my $ref = Quiq::Perl->getVar($pkg,$sigil,$name);
            if ($test->[$i++]) {
                $self->ok($ref,"Variable vorhanden (P1,$sigil,$name)");
            }
            else {
                $self->ok(!$ref,"Variable nicht vorhanden (P1,$sigil,$name)");
            }
        }
    }

    # erzeugen

    $i = 0;
    for my $sigil (qw/$ @ %/) {
        for my $name (qw/w1 x1 y1 z1 w2 x2 y2 z2/) {
            my $ref = Quiq::Perl->getVar($pkg,$sigil,$name,-create=>1);
            $self->ok($ref,"Variable vorhanden (P1,$sigil,$name)");
            if ($sigil eq '$') {
                if ($name eq 'x1' || $name eq 'y1') {
                    $self->is($$ref,1,'Skalar: 1');
                }
                else {
                    $self->ok(!defined $$ref,'Skalar: undef');
                }
            }
            elsif ($sigil eq '@') {
                $self->ok(!@$ref,'Array: leer');
            }
            if ($sigil eq '%') {
                $self->ok(!%$ref,'Hash: leer');
            }
        }
    }
}

# -----------------------------------------------------------------------------

sub test_setSubroutine : Test(4) {
    my $self = shift;

    my $pkg = ucfirst "setSubroutine$$"; # Zufallsname

    # Methode hinzufügen

    my $ref = Quiq::Perl->setSubroutine($pkg,f=>sub {4711});

    my $val = $ref->();
    $self->is($val,4711);

    $val = $pkg->f;
    $self->is($val,4711);

    # Methode ersetzen

    $ref = Quiq::Perl->setSubroutine($pkg,f=>sub {4712});

    $val = $ref->();
    $self->is($val,4712);

    $val = $pkg->f;
    $self->is($val,4712);
}

# -----------------------------------------------------------------------------

sub test_getSubroutine : Ignore(7) {
    my $self = shift;

    my $sub = Quiq::Perl->getSubroutine(Pkg5=>'f');
    $self->is($sub,undef);

    Quiq::Perl->createAlias('Pkg2',f=>sub{'Pkg2'});
    Quiq::Perl->createAlias('Pkg4',f=>sub{'Pkg4'});
    Quiq::Perl->createAlias(f=>sub{'Quiq::Perl'});
    Quiq::Perl->setScalar('Pkg1',f=>'abc'); # Keine Verwechslung mit Variablen

    # 6 Tests
    for my $pkg (Quiq::Perl->baseClassesISA('Pkg5'),'UNIVERSAL','Quiq::Perl') {
        my $ref = Quiq::Perl->getSubroutine($pkg,'f');
        if (grep { $_ eq $pkg } qw/Pkg2 Pkg4 Quiq::Perl/) {
            $self->is($ref->(),$pkg);
        }
        else {
            $self->is($ref,undef);
        }
    }
}

# -----------------------------------------------------------------------------

sub test_basicIncPaths : Test(1) {
    my $self = shift;

    my @paths = Quiq::Perl->basicIncPaths;
    $self->ok($paths[-1]);
}

# -----------------------------------------------------------------------------

my $Pod = <<'__POD__';
aaa

=pod

qqq

=cut

bbb

=pod

rrr

=cut

ccc
__POD__

my $PodResult = <<'__POD__';
aaa

bbb

ccc
__POD__

sub test_removePod_1 : Test(1) {
    my $self = shift;

    my $code = Quiq::Perl->removePod($Pod);
    $self->is($code,$PodResult);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Perl::Test->runTests;

# eof
