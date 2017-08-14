#!/usr/bin/env perl

package Prty::Perl::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Perl');
}

# -----------------------------------------------------------------------------

sub test_print : Test(2) {
    my $self = shift;

    my $testFile = '/tmp/print.tst';
    my $testData = "Test $$\n";

    local *F;
    open F,'>',$testFile or die "open fehlgeschlagen";

    Prty::Perl->print(*F,$testData);
    $self->ok(1,'Daten geschrieben');

    close F;

    my $val = Prty::Path->read($testFile);
    $self->is($val,$testData,'Dateiinhalt ok');    
    Prty::Path->delete($testFile);
}

# -----------------------------------------------------------------------------

sub test_sigilToType : Test(4) {
    my $self = shift;

    my $val = Prty::Perl->sigilToType('$');
    $self->is($val,'SCALAR');

    $val = Prty::Perl->sigilToType('@');
    $self->is($val,'ARRAY');

    $val = Prty::Perl->sigilToType('%');
    $self->is($val,'HASH');

    eval { Prty::Perl->sigilToType('!') };
    $self->like($@,qr/PERL-00001:/);
}

# -----------------------------------------------------------------------------

sub test_stash : Test(3) {
    my $self = shift;

    my $ref = Prty::Perl->stash('main');
    $self->is(ref($ref),'HASH');

    $ref = Prty::Perl->stash('UNIVERSAL');
    $self->is(ref($ref),'HASH');

    my $package = ucfirst "stash$$"; # Zufallsname
    $ref = Prty::Perl->stash($package);
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

    Prty::Perl->createClass('Pkg1');
    Prty::Perl->createClass('Pkg2','Pkg1');
    Prty::Perl->createClass('Pkg3','Pkg2');
    Prty::Perl->createClass('Pkg4','Pkg2');
    Prty::Perl->createClass('Pkg5','Pkg3','Pkg4');
}

# -----------------------------------------------------------------------------

sub test_packages : Test(4) {
    my $self = shift;

    my @arr = Prty::Perl->packages('main');
    $self->ok(grep { $_ eq 'main' } @arr);
    $self->ok(grep { $_ eq 'UNIVERSAL' } @arr);

    @arr = Prty::Perl->packages(ref($self));
    $self->isDeeply(\@arr,['Prty::Perl::Test']);

    my $package = uc "packages$$"; # Zufallsname
    @arr = Prty::Perl->packages($package);
    $self->isDeeply(\@arr,[]);
}

# -----------------------------------------------------------------------------

sub test_createClass1 : Test(3) {
    my $self = shift;

    my $bool = Prty::Perl->classExists('MyNewClass1');
    $self->ok(!$bool);
    Prty::Perl->createClass('MyNewClass1');
    $bool = Prty::Perl->classExists('MyNewClass1');
    $self->ok($bool);
    my $a = Prty::Perl->getVar('MyNewClass1','@','ISA');
    $self->is($a,undef);
}

# -----------------------------------------------------------------------------

sub test_createClass2 : Test(3) {
    my $self = shift;

    my $bool = Prty::Perl->classExists('MyNewClass2');
    $self->ok(!$bool);
    Prty::Perl->createClass('MyNewClass2','Prty::Object');
    $bool = Prty::Perl->classExists('MyNewClass2');
    $self->ok($bool);
    my $a = Prty::Perl->getVar('MyNewClass2','@','ISA');
    $self->isDeeply($a,['Prty::Object']);
}

# -----------------------------------------------------------------------------

sub test_classExists : Test(2) {
    my $self = shift;

    my $pkg = uc "classExists$$"; # Zufallsname

    # Package existiert nicht

    my $bool = Prty::Perl->classExists($pkg);
    $self->ok(!$bool,'Package existiert nicht');

    # Package existiert

    $bool = Prty::Perl->classExists('Prty::Perl');
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

    my @arr = Prty::Perl->baseClasses('Pkg5');
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

    my @arr = Prty::Perl->baseClassesISA('Pkg2');
    $self->isDeeply(\@arr,['Pkg1']);

    @arr = Prty::Perl->baseClassesISA('Pkg3');
    $self->isDeeply(\@arr,[qw/Pkg2 Pkg1/]);

    @arr = Prty::Perl->baseClassesISA('Pkg5');
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

    my @arr = Prty::Perl->hierarchyISA('Pkg2');
    $self->isDeeply(\@arr,['Pkg1']);

    @arr = Prty::Perl->hierarchyISA('Pkg3');
    $self->isDeeply(\@arr,[qw/Pkg2 Pkg1/]);

    @arr = Prty::Perl->hierarchyISA('Pkg5');
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

    my $arr = Prty::Perl->subClasses('Pkg1')->sort;
    $self->isDeeply($arr,[qw/Pkg2 Pkg3 Pkg4 Pkg5/]);

    my @arr = Prty::Perl->subClasses('Pkg4');
    $self->isDeeply(\@arr,['Pkg5']);
}

# -----------------------------------------------------------------------------

sub test_nextMethod : Test(6) {
    my $self = shift;

    my ($pkg,$meth) = Prty::Perl->nextMethod('Pkg5','f2','Pkg3');
    $self->is($pkg,undef);
    $self->is($meth,undef);

    Prty::Perl->createAlias('Pkg2',m=>sub{2});
    Prty::Perl->createAlias('Pkg4',m=>sub{4});

    ($pkg,$meth) = Prty::Perl->nextMethod('Pkg5','m','Pkg5');
    $self->is($pkg,'Pkg2');
    $self->is($meth->(),2);

    ($pkg,$meth) = Prty::Perl->nextMethod('Pkg5','m',$pkg); # Fortsetzung
    $self->is($pkg,'Pkg4');
    $self->is($meth->(),4);
}

# -----------------------------------------------------------------------------

sub test_classNameToPath : Test(1) {
    my $self = shift;

    my $val = Prty::Perl->classNameToPath('A::B::C');
    $self->is($val,'A/B/C');
}

# -----------------------------------------------------------------------------

sub test_classPathToName : Test(2) {
    my $self = shift;

    my $val = Prty::Perl->classPathToName('A/B/C');
    $self->is($val,'A::B::C');

    $val = Prty::Perl->classPathToName('A/B/C.pm');
    $self->is($val,'A::B::C');
}

# -----------------------------------------------------------------------------

sub test_createAlias : Test(1) {
    my $self = shift;

    Prty::Perl->createAlias('Pkg1',m1=>sub{$_[1]});

    my $val = Pkg1->m1(5);
    $self->is($val,5,'createAlias');
}

# -----------------------------------------------------------------------------

sub test_createHash : Test(2) {
    my $self = shift;

    my $ref = Prty::Perl->createHash(Pkg1=>'H');
    $ref->{'a'} = 4711;

    no warnings 'once';
    my $val = $Pkg1::H{'a'};
    $self->is($val,4711);

    bless $ref,'Prty::Hash';
    my @arr = $ref->keys;
    $self->isDeeply(\@arr,['a']);
}

# -----------------------------------------------------------------------------

sub test_getHash : Test(1) {
    my $self = shift;

    my $package = ucfirst "getHash$$"; # Zufallsname

    my $ref1 = Prty::Perl->createHash($package,'H');
    my $ref2 = Prty::Perl->getHash($package,'H');
    $self->is($ref2,$ref1);
}

# -----------------------------------------------------------------------------

sub test_setHash : Test(4) {
    my $self = shift;

    my $pkg = ucfirst "setHash$$"; # Zufallsname

    my $hash1 = {qw/a 1 b 2 c 3/};
    my $ref1 = Prty::Perl->setHash($pkg,'x',$hash1);
    $self->is(ref($ref1),'HASH');
    $self->isDeeply($ref1,$hash1);

    my $hash2 = {qw/d 4 e 5 f 6/};
    my $ref2 = Prty::Perl->setHash($pkg,'x',$hash2);
    $self->isDeeply($ref2,$hash2);
    $self->is($ref2,$ref1);
}

# -----------------------------------------------------------------------------

sub test_createArray : Test(2) {
    my $self = shift;

    my $ref = Prty::Perl->createArray('Pkg1','A');
    $ref->[0] = 4711;

    no warnings 'once';
    my $val = $Pkg1::A[0];
    $self->is($val,4711);

    bless $ref,'Prty::Array';
    $val = $ref->min;
    $self->is($val,4711);
}

# -----------------------------------------------------------------------------

sub test_getArray : Test(1) {
    my $self = shift;

    my $package = ucfirst "getArray$$"; # Zufallsname

    my $ref1 = Prty::Perl->createArray($package,'A');
    my $ref2 = Prty::Perl->getArray($package,'A');
    $self->is($ref2,$ref1);
}

# -----------------------------------------------------------------------------

sub test_setArray : Test(4) {
    my $self = shift;

    my $pkg = ucfirst "setArray$$"; # Zufallsname

    my $arr1 = [qw/a b c/];
    my $ref1 = Prty::Perl->setArray($pkg,'x',$arr1);
    $self->is(ref($ref1),'ARRAY');
    $self->isDeeply($ref1,$arr1);

    my $arr2 = [qw/d e f/];
    my $ref2 = Prty::Perl->setArray($pkg,'x',$arr2);
    $self->isDeeply($ref2,$arr2);
    $self->is($ref2,$ref1);
}

# -----------------------------------------------------------------------------

sub test_setScalar : Test(4) {
    my $self = shift;

    my $pkg = ucfirst "setScalar$$"; # Zufallsname

    # Skalar

    my $ref1 = Prty::Perl->setScalar($pkg,x=>99);
    $self->is(ref($ref1),'SCALAR');
    $self->is($$ref1,99);

    my $ref2 = Prty::Perl->setScalar($pkg,x=>100);
    $self->is($$ref2,100);
    $self->is($$ref2,$$ref1);
}

# -----------------------------------------------------------------------------

sub test_getScalarValue : Test(1) {
    my $self = shift;

    my $pkg = ucfirst "getScalarValue$$"; # Zufallsname

    Prty::Perl->setScalar($pkg,x=>99);
    my $val = Prty::Perl->getScalarValue($pkg,'x');
    $self->is($val,99);
}

# -----------------------------------------------------------------------------

sub test_setVar : Test(12) {
    my $self = shift;

    my $pkg = ucfirst "setVar$$"; # Zufallsname

    # Skalar

    my $ref1 = Prty::Perl->setVar($pkg,'$','x',\99);
    $self->is(ref($ref1),'SCALAR');
    $self->is($$ref1,99);

    my $ref2 = Prty::Perl->setVar($pkg,'$','x',\100);
    $self->is($$ref2,100);
    $self->is($$ref2,$$ref1);

    # Array

    my $arr1 = [qw/a b c/];
    $ref1 = Prty::Perl->setVar($pkg,'@','x',$arr1);
    $self->is(ref($ref1),'ARRAY');
    $self->isDeeply($ref1,$arr1);

    my $arr2 = [qw/d e f/];
    $ref2 = Prty::Perl->setVar($pkg,'@','x',$arr2);
    $self->isDeeply($ref2,$arr2);
    $self->is($ref2,$ref1);

    # Hash

    my $hash1 = {qw/a 1 b 2 c 3/};
    $ref1 = Prty::Perl->setVar($pkg,'%','x',$hash1);
    $self->is(ref($ref1),'HASH');
    $self->isDeeply($ref1,$hash1);

    my $hash2 = {qw/d 4 e 5 f 6/};
    $ref2 = Prty::Perl->setVar($pkg,'%','x',$hash2);
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
            my $ref = Prty::Perl->getVar($pkg,$sigil,$name);
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
            my $ref = Prty::Perl->getVar($pkg,$sigil,$name,-create=>1);
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

    my $ref = Prty::Perl->setSubroutine($pkg,f=>sub {4711});

    my $val = $ref->();
    $self->is($val,4711);

    $val = $pkg->f;
    $self->is($val,4711);

    # Methode ersetzen

    $ref = Prty::Perl->setSubroutine($pkg,f=>sub {4712});

    $val = $ref->();
    $self->is($val,4712);

    $val = $pkg->f;
    $self->is($val,4712);
}

# -----------------------------------------------------------------------------

sub test_getSubroutine : Ignore(7) {
    my $self = shift;

    my $sub = Prty::Perl->getSubroutine(Pkg5=>'f');
    $self->is($sub,undef);

    Prty::Perl->createAlias('Pkg2',f=>sub{'Pkg2'});
    Prty::Perl->createAlias('Pkg4',f=>sub{'Pkg4'});
    Prty::Perl->createAlias(f=>sub{'Prty::Perl'});
    Prty::Perl->setScalar('Pkg1',f=>'abc'); # Keine Verwechslung mit Variablen

    # 6 Tests
    for my $pkg (Prty::Perl->baseClassesISA('Pkg5'),'UNIVERSAL','Prty::Perl') {
        my $ref = Prty::Perl->getSubroutine($pkg,'f');
        if (grep { $_ eq $pkg } qw/Pkg2 Pkg4 Prty::Perl/) {
            $self->is($ref->(),$pkg);
        }
        else {
            $self->is($ref,undef);
        }
    }
}

# -----------------------------------------------------------------------------

sub test_refType : Test(8) {
    my $self = shift;

    my $ref = \'';
    my $val = Prty::Perl->refType($ref);
    $self->is($val,'SCALAR','refType: String-Referenz, nicht geblesst');

    $ref = [];
    $val = Prty::Perl->refType($ref);
    $self->is($val,'ARRAY','refType: Array-Referenz, nicht geblesst');

    $ref = {};
    $val = Prty::Perl->refType($ref);
    $self->is($val,'HASH','refType: Hash-Referenz, nicht geblesst');

    $ref = sub {};
    $val = Prty::Perl->refType($ref);
    $self->is($val,'CODE','refType: Code-Referenz, nicht geblesst');

    my $str = '';
    $ref = bless \$str,'X';
    $val = Prty::Perl->refType($ref);
    $self->is($val,'SCALAR','refType: String-Referenz, geblesst');

    $ref = bless [],'X';
    $val = Prty::Perl->refType($ref);
    $self->is($val,'ARRAY','refType: Array-Referenz, geblesst');

    $ref = bless {},'X';
    $val = Prty::Perl->refType($ref);
    $self->is($val,'HASH','refType: Code-Referenz, geblesst');

    $ref = bless sub {},'X';
    $val = Prty::Perl->refType($ref);
    $self->is($val,'CODE','refType: Code-Referenz, geblesst');
}

# -----------------------------------------------------------------------------

sub test_isBlessedRef : Test(6) {
    my $self = shift;

    my $ref = \'';
    my $bool = Prty::Perl->isBlessedRef($ref);
    $self->is($bool,0,'isBlessedRef: String-Referenz, nicht geblesst');

    $ref = [];
    $bool = Prty::Perl->isBlessedRef($ref);
    $self->is($bool,0,'isBlessedRef: Array-Referenz, nicht geblesst');

    $ref = {};
    $bool = Prty::Perl->isBlessedRef($ref);
    $self->is($bool,0,'isBlessedRef: Hash-Referenz, nicht geblesst');

    my $str = '';
    $ref = bless \$str,'X';
    $bool = Prty::Perl->isBlessedRef($ref);
    $self->is($bool,1,'isBlessedRef: String-Referenz, geblesst');

    $ref = bless [],'X';
    $bool = Prty::Perl->isBlessedRef($ref);
    $self->is($bool,1,'isBlessedRef: Array-Referenz, geblesst');

    $ref = bless {},'X';
    $bool = Prty::Perl->isBlessedRef($ref);
    $self->is($bool,1,'isBlessedRef: Hash-Referenz, geblesst');
}

# -----------------------------------------------------------------------------

sub test_isArrayRef : Test(3) {
    my $self = shift;

    my $ref = \'x';
    my $bool = Prty::Perl->isArrayRef($ref);
    $self->is($bool,0,'isArrayRef: keine Array-Referenz');

    $ref = [];
    $bool = Prty::Perl->isArrayRef($ref);
    $self->is($bool,1,'isArrayRef: Array-Referenz');

    $ref = bless [],'X';
    $bool = Prty::Perl->isArrayRef($ref);
    $self->is($bool,1,'isArrayRef: geblesste Array-Referenz');
}

# -----------------------------------------------------------------------------

sub test_isCodeRef : Test(3) {
    my $self = shift;

    my $ref = \'x';
    my $bool = Prty::Perl->isCodeRef($ref);
    $self->is($bool,0,'isCodeRef: keine Code-Referenz');

    $ref = sub { 'x' };
    $bool = Prty::Perl->isCodeRef($ref);
    $self->is($bool,1,'isCodeRef: Code-Referenz');

    $ref = sub { 'x' };
    $ref = bless $ref,'X';
    $bool = Prty::Perl->isCodeRef($ref);
    $self->is($bool,1,'isCodeRef: geblesste Code-Referenz');
}

# -----------------------------------------------------------------------------

sub test_isRegexRef : Test(3) {
    my $self = shift;

    my $ref = \'x';
    my $bool = Prty::Perl->isRegexRef($ref);
    $self->is($bool,0,'isRegexRef: keine Regex-Referenz');

    $ref = qr/x/;
    $bool = Prty::Perl->isRegexRef($ref);
    $self->is($bool,1,'isRegexRef: Regex-Referenz');

    $ref = qr/x/;
    $ref = bless $ref,'X';
    $bool = Prty::Perl->isRegexRef($ref);
    $self->is($bool,0,
        'isRegexRef: geblesste Regex-Referenz funktioniert nicht!');
}

# -----------------------------------------------------------------------------

sub test_basicIncPaths : Test(1) {
    my $self = shift;

    my @paths = Prty::Perl->basicIncPaths;
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

    my $code = Prty::Perl->removePod($Pod);
    $self->is($code,$PodResult);
}

# -----------------------------------------------------------------------------

package main;
Prty::Perl::Test->runTests;

# eof
