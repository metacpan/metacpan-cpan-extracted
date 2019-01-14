#!/usr/bin/env perl

use Test::More tests=>5;

use_ok 'Quiq::ClassLoader';

# (my $classPath = $0) =~ s/\.t$//;
# push @INC,$classPath; # Verzeichnis mit Testklassen

# FIXME: von Quiq::Test::Class unabhängig machen
push @INC,Quiq::Test::Class->testPath('t/data/class');
    
eval { InexistentClass->new };
like $@,qr/CLASSLOADER-00001/,'Klassen-Modul existiert nicht';

my $obj = MyClass1->new;
is ref($obj),'MyClass1','Klassen-Modul erfolgreich geladen';

eval { MyClass1->xxx };
# warn "\n---\n$@---\n";
like $@,qr/CLASSLOADER-00002/,'Methode fehlt in zuvor geladener Klasse';

eval { MyClass2->xxx };
# warn "\n---\n$@---\n";
like $@,qr/CLASSLOADER-00002/,'Methode fehlt in gerade geladener Klasse';

# FIXME: Test mit Modul, das einen Syntaxfehler enthält

# eof
