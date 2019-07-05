package Quiq::Perl;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.149';

use Quiq::Object;
use Cwd ();
use Quiq::Array;
use Quiq::Perl;
use Quiq::Option;
use Quiq::FileHandle;
use Encode ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Perl - Erweiterte und abgesicherte Perl-Operationen

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Die Klasse implementiert grundlegende Perl-Operationen, die
Erweiterungen darstellen und/oder durch Exception-Behandlung
abgesichert sind.

=head1 METHODS

=head2 I/O

=head3 autoFlush() - Aktiviere/Deaktiviere Pufferung auf Dateihandle

=head4 Synopsis

    $this->autoFlush($fh);
    $this->autoFlush($fh,$bool);

=head4 Description

Schalte Pufferung auf Dateihandle ein oder aus.

Der Aufruf ist äquivalent zu

    $oldFh = select $fh;
    $| = $bool;
    select $oldFh;

=head4 See Also

perldoc -f select

=head4 Example

    Quiq::Perl->autoFlush(*STDOUT);

=cut

# -----------------------------------------------------------------------------

sub autoFlush {
    my $class = shift;
    my $fh = shift;
    my $bool = @_? shift: 1;

    my $oldFh = CORE::select $fh;
    $ | = $bool;
    CORE::select $oldFh;

    return;
}

# -----------------------------------------------------------------------------

=head3 binmode() - Aktiviere Binärmodus oder setze Layer

=head4 Synopsis

    $class->binmode($fh);
    $class->binmode($fh,$layer);

=head4 Description

Schalte Filehandle $fh in Binärmodus oder setze Layer $layer.
Die Methode ist eine Überdeckung der Perl-Funktion binmode und prüft
deren Returnwert. Im Fehlerfall wirft die Methode eine Exception.

=head4 See Also

perldoc -f binmode

=head4 Example

    Quiq::Perl->binmode(*STDOUT,':encoding(utf-8)');

=cut

# -----------------------------------------------------------------------------

sub binmode {
    my $class = shift;
    my $fh = shift;
    # @_: $layer

    my $r = @_? CORE::binmode($fh,$_[0]): CORE::binmode($fh);
    if (!defined $r) {
        $class->throw(
            'FH-00012: binmode fehlgeschlagen',
            Errstr => $!,
        );
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 print() - Schreibe auf Dateihandle

=head4 Synopsis

    Quiq::Perl->print($fh,@data);

=head4 Description

Schreibe Daten @data auf Dateihandle $fh. Die Methode ist eine
Überdeckung der Perl-Funktion print und prüft deren Returnwert.
Im Fehlerfall wirft die Methode eine Exception.

=head4 See Also

perldoc -f print

=head4 Example

    Quiq::Perl->print($fh,"Hello world\n");

=cut

# -----------------------------------------------------------------------------

sub print {
    my $class = shift;
    my $fh = shift;
    # @_: @data

    # Wir unterdrücken Warnungen auf STDERR, die z.B. auftreten,
    # wenn die Handle nicht geöffnet ist. Solche Fehler generieren
    # hier sowieso eine Exception.
    no warnings;

    unless (CORE::print $fh @_) {
        $class->throw(
            'PERL-00002: print fehlgeschlagen',
            Errstr => $!,
        );
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 use() - Lade Klasse per use

=head4 Synopsis

    $class->use($class,$sloppy);

=head4 Description

Lade Klasse $class per use. Im Fehlerfall wirft die Methdoe eine Exception.
Ist $sloppy wahr, wird keine Exception geworfen, sondern ein boolscher
Wert: 1 für erfolgreiche Ausführung, 0 für fehlgeschlagen. Die globale
Variable $@ gibt den Grund an.

=head4 See Also

L<loadClass|"loadClass() - Lade Klasse, falls nicht existent">()

=cut

# -----------------------------------------------------------------------------

sub use {
    my ($class,$useClass,$sloppy) = @_;

    eval "CORE::use $useClass ()";
    if ($@) {
        if ($sloppy) {
            return 0;
        }
        $@ =~ s/ at .*//s; # unnütze/störende Information abschneiden
        $class->throw(
            'PERL-00001: use fehlgeschlagen',
            Class => $useClass,
            Error => $@,
        );
    }

    return 1;
}

# -----------------------------------------------------------------------------

=head2 Sonstige Operationen

=head3 perlDoFile() - Überdeckung für do()

=head4 Synopsis

    @arr|$val = Quiq::Perl->perlDoFile($file);

=head4 Description

Überdeckung für die Perl-Funktion do() in der Variante do($file). Die
Funktion liefert den Wert des letzten ausgewerteten Ausdrucks bei
Ausführung der Datei $file. Im Fehlerfall wirft die Funktion
eine Exception.

Genaue Funktionsbeschreibung siehe Perl-Dokumentation.

=head4 Example

Laden einer Konfigurationsdatei:

    %cfg = Quiq::Perl->perlDoFile($file);

Inhalt Konfigurationsdatei:

    host => 'localhost',
    datenbank => 'entw1',
    benutzer => ['sys','system']

=cut

# -----------------------------------------------------------------------------

sub perlDoFile {
    my ($class,$file) = @_;

    my @arr = CORE::do($file);
    if ($@) {
        Quiq::Object->throw(
            'PERL-00001: Datei kann nicht von do() geparst werden',
            File => $file,
            Cwd => Cwd::getcwd,
            InternalError => $@,
        );
    }
    elsif (@arr == 1 && !defined $arr[0]) {
        Quiq::Object->throw(
            'PERL-00002: Dateiladen per do() fehlgeschlagen',
            File => $file,
            Cwd => Cwd::getcwd,
            Error => $!,
        );
    }

    return wantarray? @arr: $arr[0];
}

# -----------------------------------------------------------------------------

=head2 Sigil

=head3 sigilToType() - Wandele Sigil in Datentyp-Bezeichner

=head4 Synopsis

    $type = $this->sigilToType($sigil);

=head4 Description

Wandele $sigil ('$', '@' oder '%') in Datentyp-Bezeichner ('SCALAR',
'ARRAY' oder 'HASH') und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub sigilToType {
    my ($this,$sigil) = @_;

    if ($sigil eq '$') { return 'SCALAR' }
    elsif ($sigil eq '@') { return 'ARRAY' }
    elsif ($sigil eq '%') { return 'HASH' }

    $this->throw(
        'PERL-00001: Ungültiger Sigil',
        Sigil => $sigil,
    );
}

# -----------------------------------------------------------------------------

=head2 Symboltabellen

=head3 stash() - Referenz auf Symboltabelle eines Package

=head4 Synopsis

    $refH = $this->stash($package);

=head4 Description

Liefere eine Referenz auf den "Symbol Table Hash" (Stash) des
Package $package. Der Hash enthält für jede globale Variable und
jedes Unterpackage einen Eintrag. Existiert der Stash nicht (und
damit auch nicht das Package), liefere undef.

=cut

# -----------------------------------------------------------------------------

sub stash {
    my ($this,$package) = @_;

    # o main:: verweist unter Key 'main::' auf sich selbst
    # o $stash->{$key} ist ein Tyeglob. Im Falle eines Verweises auf
    #   einen Unter-Stash findet sich der Unter-Stash auf dem Hash-Slot.
    #   Daher als Returnwert \%{$stash}, nicht $stash!
    # o Wir zerlegen den Package-Namen in seine Bestandteile und
    #   folgen den Stash-Verweisen

    my $stash = \%main::;
    for my $key (split /::/,$package) {
        $key .= '::';
        if (!exists $stash->{$key}) {
            return undef;
        }
        $stash = $stash->{$key};
    }

    return \%{$stash}; 
}

# -----------------------------------------------------------------------------

=head2 Packages/Klassen

=head3 packages() - Liste der existierenden Packages

=head4 Synopsis

    @arr|$arr = $this->packages;
    @arr|$arr = $this->packages($package);

=head4 Description

Liefere die Liste der existierenden Packages, die im Stash
des Package $package und darunter enthalten sind, einschließlich
Package $package selbst. Im Skalarkontext liefere eine Referenz
auf die Liste. Wird die Methode ohne Argument aufgerufen
wird Package 'main' angenommen.

B<Anmerkung>

Packages entstehen zur Laufzeit. Die Liste der Packages wird
nicht gecacht, sondern mit jedem Aufruf neu ermittelt.

=head4 Example

=over 2

=item *

Liste aller Packages, die das Programm aktuell geladen hat:

    @arr = Quiq::Perl->packages;

=item *

Liste in sortierter Form

    @arr = Quiq::Perl->packages->sort;

=item *

Liste, eingeschränkt auf Packages, deren Name einen Regex erfüllt:

    @arr = Quiq::Perl->packages->select(qr/patch\d+/);

=item *

Liste aller Packages unterhalb und einschließlich Package X:

    @arr = Quiq::Perl->packages('X');

=back

=cut

# -----------------------------------------------------------------------------

sub packages {
    my $this = shift;
    my $package = shift || 'main';

    my $stash = $this->stash($package);
    if (!$stash) {
        # Wenn Stash nicht existiert, liefere leere Liste bzw. undef
        return;
    }

    push my(@arr),$package;
    for (keys %$stash) {
        if (/::$/) {
            s/::$//; # :: am Ende entfernen

            my $subPackage;
            if ($package eq 'main') {
                # Der Stash main:: enthält zwei Einträge, die wir ignorieren:
                # 1) die Referenz auf sich selbst
                # 2) einen Eintrag "<none>", der kein gültiger Paketname ist

                next if $_ eq 'main' || $_ eq '<none>';
                $subPackage = $_; # wir wollen main:: am Anfang nicht
            }
            else {
                $subPackage = "$package\::$_";
            }

            push @arr,$this->packages($subPackage);
        }
    }

    return wantarray? @arr: Quiq::Array->new(\@arr);
}

# -----------------------------------------------------------------------------

=head3 createClass() - Erzeuge Klasse

=head4 Synopsis

    $class->createClass($newClass,@baseClasses);

=head4 Description

Erzeuge Klasse $newClass, falls sie noch nicht existiert, und
definiere die Klassen @baseClasses als deren Basisklassen. Die
Methode liefert keinen Wert zurück.

Die Basisklassen werden per "use base" geladen.

=cut

# -----------------------------------------------------------------------------

sub createClass {
    my ($class,$newClass,@baseClasses) = @_;

    no strict 'refs';
    if (!defined *{"$newClass\::"}) {
        my $code = "package $newClass";
        if (@baseClasses) {
            $code .= "; use base qw/@baseClasses/";
        }

        eval $code;
        if ($@) {
            $class->throw(
                'PERL-00003: Klasse erzeugen fehlgeschlagen',
                Code => $code,
                Error => $@,
            );
        }
    }
    
    return;
}

# -----------------------------------------------------------------------------

=head3 classExists() - Prüfe Existenz von Klasse/Package

=head4 Synopsis

    $bool = $class->classExists($class);

=head4 Alias

packageExists()

=head4 Description

Prüfe, ob die Perl-Klasse bzw. das Package $class in-memory
existiert, also von Perl bereits geladen wurde. Liefere I<wahr>,
wenn Klasse existiert, andernfalls I<falsch>.

=head4 Example

    Quiq::Perl->classExists('Quiq::Object');
    ==>
    1

=cut

# -----------------------------------------------------------------------------

sub classExists {
    my ($class,$testClass) = @_;
    no strict 'refs';
    return defined *{"$testClass\::"}? 1: 0;
}

{
    no warnings 'once';
    *packageExists = \&classExists;
}

# -----------------------------------------------------------------------------

=head3 loadClass() - Lade Klasse, falls nicht existent

=head4 Synopsis

    $class->loadClass($class);

=head4 Description

Lade Klasse $class. Im Unterschied zu Methode L<use|"use() - Lade Klasse per use">() wird die
Moduldatei nur zu laden versucht, wenn es den Namensraum (Package)
der Klasse noch nicht gibt.

=head4 Example

    Quiq::Perl->loadClass('My::Application');

=cut

# -----------------------------------------------------------------------------

sub loadClass {
    my ($class,$useClass) = @_;

    if (!$class->classExists($useClass)) {
        $class->use($useClass);
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 baseClasses() - Liefere Liste aller Basisklassen (einschl. UNIVERSAL)

=head4 Synopsis

    @arr | $arr = $this->baseClasses($class);

=head4 Description

Liefere die Liste der *aller* Basisklassen der Klasse $class,
einschließlich UNIVERSAL und deren Basisklassen.

=head4 Example

Gegeben folgende Vererbungshierarchie:

    Pkg6  Pkg7
      \   /
     UNIVERSAL
    
       Pkg1
        |
       Pkg2
       / \
     Pkg3 Pkg4
       \ /
       Pkg5

Der Aufruf Quiq::Perl->baseClasses('Pkg5') liefert ein Array
mit den Elementen

    Pkg3 Pkg2 Pkg1 Pkg4 UNIVERSAL Pkg6 Pkg7

Die Klassen Pkg2 und Pkg1 werden nicht wiederholt.

=cut

# -----------------------------------------------------------------------------

sub baseClasses {
    my ($this,$class) = @_;

    my (@arr,%seen);
    for ($this->baseClassesISA($class),'UNIVERSAL',
            $this->baseClassesISA('UNIVERSAL')) {
        push @arr,$_ if !$seen{$_}++;
    }

    return wantarray? @arr: Quiq::Array->new(\@arr);
}

# -----------------------------------------------------------------------------

=head3 baseClassesISA() - Liefere Liste der ISA-Basisklassen

=head4 Synopsis

    @arr | $arr = $this->baseClassesISA($class);

=head4 Description

Liefere die Liste der Basisklassen der Klasse $class.
Jede Basisklasse kommt in der Liste genau einmal vor.

=head4 Example

Gegeben folgende Vererbungshierarchie:

      Pkg1
       |
      Pkg2
      / \
    Pkg3 Pkg4
      \ /
      Pkg5

Der Aufruf Quiq::Perl->baseClassesISA('Pkg5') liefert ein Array
mit den Elementen

    Pkg3 Pkg2 Pkg1 Pkg4

Die Klassen Pkg2 und Pkg1 werden nicht wiederholt.

=cut

# -----------------------------------------------------------------------------

sub baseClassesISA {
    my ($this,$class) = @_;

    my (@arr,%seen);
    for (Quiq::Perl->hierarchyISA($class)) {
        push @arr,$_ if !$seen{$_}++;
    }

    return wantarray? @arr: Quiq::Array->new(\@arr);
}

# -----------------------------------------------------------------------------

=head3 hierarchyISA() - Liefere ISA-Hierarchie

=head4 Synopsis

    @arr | $arr = $this->hierarchyISA($class);

=head4 Description

Liefere die ISA-Hierarchie der Klasse $class. Kommt eine Basisklasse
in der Hierarchie mehrfach vor, erscheint sie mehrfach in der Liste.

=head4 Example

Gegeben folgende Vererbungshierarchie:

      Pkg1
       |
      Pkg2
      / \\
    Pkg3 Pkg4
      \ /
      Pkg5

Der Aufruf Quiq::Perl->hierarchyISA('Pkg5') liefert ein Array
mit den Elementen

    Pkg3 Pkg2 Pkg1 Pkg4 Pkg2 Pkg1

Die Basisklassen Pkg2 und Pkg1 erscheinen zweimal.

=cut

# -----------------------------------------------------------------------------

sub hierarchyISA {
    my ($this,$class) = @_;

    my @arr;
    if (my $ref = $this->getVar($class,'@','ISA')) {
        for my $base (@$ref) {
            push @arr,$base,$this->hierarchyISA($base);
        }
    }

    return wantarray? @arr: Quiq::Array->new(\@arr);
}

# -----------------------------------------------------------------------------

=head3 subClasses() - Liefere Liste aller Subklassen

=head4 Synopsis

    @arr | $arr = $this->subClasses($class);

=head4 Description

Liefere die Liste der Subklassen der Klasse $class.

=head4 Example

Gegeben folgende Vererbungshierarchie:

      Pkg1
       |
      Pkg2
      / \
    Pkg3 Pkg4
      \ /
      Pkg5

Der Aufruf Quiq::Perl->subClasses('Pkg1') liefert ein Array
mit den Elementen:

    Pkg2 Pkg3 Pkg4 Pkg5

Die Reihenfolge der Elemente ist nicht definiert.

=over 2

=item *

Liste in sortierter Form

    @arr = Quiq::Perl->subClasses('Pkg1')->sort;

=item *

Liste, eingeschränkt auf Klassen, deren Name einen Regex erfüllt:

    @arr = Quiq::Perl->subClasses('Pkg1')->select(qr/[45]/);

=back

=cut

# -----------------------------------------------------------------------------

sub subClasses {
    my ($this,$class) = @_;

    my (@arr,%seen);
    for my $pkg ($this->packages) {
        if (!$seen{$pkg}++ && $pkg ne $class && $pkg->isa($class)) {
            push @arr,$pkg;
        }
    }

    return wantarray? @arr: Quiq::Array->bless(\@arr);
}

# -----------------------------------------------------------------------------

=head3 nextMethod() - Finde nächste Methoden-Instanz

=head4 Synopsis

    ($nextClass,$nextMeth) = $this->nextMethod($class,$name,$startClass);

=cut

# -----------------------------------------------------------------------------

sub nextMethod {
    my ($this,$class,$name,$startClass) = @_;

    my ($search,$nextClass,$nextMeth);
    for my $package ($class,$this->baseClasses($class)) {
        if ($search) {
            if (my $sub = $this->getSubroutine($package,$name)) {
                return wantarray? ($package,$sub): $sub;
            }
        }
        elsif ($package eq $startClass) {
            $search = 1;
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 classNameToPath() - Übersetze Klassenname in Klassenpfad

=head4 Synopsis

    $classPath = $class->classNameToPath($className);

=head4 Description

Übersetze den Klassennamen $className in den entsprechenden
Klassenpfad (ohne Dateiendung) und liefere diesen zurück.

=head4 Example

    'A::B::C' => 'A/B/C'

=cut

# -----------------------------------------------------------------------------

sub classNameToPath {
    my ($class,$str) = @_;
    $str =~ s|::|/|g;
    return $str;
}

# -----------------------------------------------------------------------------

=head3 classPathToName() - Übersetze Klassenpfad in Klassenname

=head4 Synopsis

    $className = $class->classPathToName($classPath);

=head4 Description

Übersetze Klassenpfad $classPath (ist eine Endung vorhanden, wird
sie entfernt) in den entsprechenden Klassennamen und liefere
diesen zurück.

=head4 Example

    'A/B/C' ==> 'A::B::C'
    'A/B/C.pm' ==> 'A::B::C'

=cut

# -----------------------------------------------------------------------------

sub classPathToName {
    my ($class,$str) = @_;

    $str =~ s/\.(.*)$//;
    $str =~ s|/|::|g;

    return $str;
}

# -----------------------------------------------------------------------------

=head2 Typeglobs

=head3 createAlias() - Setze Typeglob-Eintrag

=head4 Synopsis

    $this->createAlias($package,$sym=>$ref);
    $this->createAlias($sym=>$ref);

=head4 Description

Weise dem Typeglob-Eintrag $sym in der Symboltabelle des Package
$package die Referenz $ref zu. Die Methode liefert keinen Wert
zurück.

Der Aufruf ist äquivalent zu:

    no strict 'refs';
    *{"$package\::$sym"} = $ref;

Ist $package nicht angegeben wird das Package des Aufrufers
(d.h. das Package, aus dem heraus der Aufruf erfolgt) genommen.

=head4 Example

=over 2

=item *

Alias für Subroutine aus anderer Klasse:

    Quiq::Perl->createAlias('MyClass',mySub=>\&MyClass1::mySub1);

=item *

Eintrag einer Closure in die Symboltabelle:

    Quiq::Perl->createAlias(__PACKAGE__,mySub=>sub { <code> });

=back

=cut

# -----------------------------------------------------------------------------

sub createAlias {
    my $this = shift;
    my $package = @_ == 3? shift: caller;
    my $sym = shift;
    my $ref = shift;

    no strict 'refs';
    *{"$package\::$sym"} = $ref;

    return;
}

# -----------------------------------------------------------------------------

=head3 createHash() - Erzeuge Package-globalen Hash

=head4 Synopsis

    $ref = $this->createHash($package,$sym);

=head4 Description

Erzeuge einen globalen Hash in Package $package und liefere eine Referenz
diesen zurück.

=head4 Example

=over 2

=item *

Erzeuge in $class den Hash %H:

    $ref = $this->createHash($class,'H');

=item *

die Referenz kann geblesst werden:

    bless $ref,'Quiq::Hash';

=back

=cut

# -----------------------------------------------------------------------------

sub createHash {
    my ($this,$package,$sym) = @_;

    no strict 'refs';
    *{"$package\::$sym"} = {};

    return *{"$package\::$sym"}{HASH};
}

# -----------------------------------------------------------------------------

=head3 getHash() - Liefere Referenz auf Package-Hash

=head4 Synopsis

    $ref = $this->getHash($package,$name);

=head4 Example

    $ref = Quiq::Perl->getHash($package,'H');

=cut

# -----------------------------------------------------------------------------

sub getHash {
    my ($this,$package,$sym) = @_;

    no strict 'refs';
    my $ref = *{"$package\::$sym"}{HASH};
    if (!$ref) {
        $this->throw(
            'PERL-00001: Hash existiert nicht',
            Error => $@,
        );
    }

    return $ref;
}

# -----------------------------------------------------------------------------

=head3 setHash() - Setze Package-Hash auf Wert

=head4 Synopsis

    $ref = $this->setHash($package,$name,$ref);

=head4 Description

Setze Package-Hash mit dem Namen $name auf den von $ref
referenzierten Wert, also auf %$ref und liefere eine Referenz
auf die Variable zurück.

Die Methode kopiert den Wert, sie erzeugt keinen Alias!

=head4 Example

=over 2

=item *

Setze Paket-Hash 'h' auf den Wert %hash:

    $ref = Quiq::Perl->setHash($package,'h',\%hash);

=back

=cut

# -----------------------------------------------------------------------------

sub setHash {
    my ($this,$package,$sym,$ref) = @_;

    no strict 'refs';
    %{"$package\::$sym"} = %$ref;

    return *{"$package\::$sym"}{HASH};
}

# -----------------------------------------------------------------------------

=head3 createArray() - Erzeuge Package-globales Array

=head4 Synopsis

    $ref = $this->createArray($package,$sym);

=head4 Description

Erzeuge ein globales Array in Package $package und liefere eine
Referenz dieses zurück.

=head4 Example

=over 2

=item *

Erzeuge in $class das Array @A:

    $ref = Quiq::Perl->createArray($class,'A');

=item *

die Referenz kann geblesst werden:

    bless $ref,'Quiq::Array';

=back

=cut

# -----------------------------------------------------------------------------

sub createArray {
    my ($this,$package,$sym) = @_;

    no strict 'refs';
    *{"$package\::$sym"} = [];

    return *{"$package\::$sym"}{ARRAY};
}

# -----------------------------------------------------------------------------

=head3 getArray() - Liefere Referenz auf Package-Array

=head4 Synopsis

    $ref = $this->getArray($package,$name);

=head4 Example

    $ref = Quiq::Perl->getArray($package,'A');

=cut

# -----------------------------------------------------------------------------

sub getArray {
    my ($this,$package,$sym) = @_;

    no strict 'refs';
    my $ref = *{"$package\::$sym"}{ARRAY};
    if (!$ref) {
        $this->throw(
            'PERL-00001: Array existiert nicht',
            Error => $@,
        );
    }

    return $ref;
}

# -----------------------------------------------------------------------------

=head3 setArray() - Setze Package-Array auf Wert

=head4 Synopsis

    $ref = $this->setArray($package,$name,$ref);

=head4 Description

Setze Package-Array mit dem Namen $name auf den von $ref
referenzierten Wert, also auf @$ref und liefere eine Referenz
auf die Variable zurück.

Die Methode kopiert den Wert, sie erzeugt keinen Alias!

=head4 Example

=over 2

=item *

Setze Paket-Array 'a' auf den Wert @arr:

    $ref = Quiq::Perl->setArray($package,'a',\@arr);

=back

=cut

# -----------------------------------------------------------------------------

sub setArray {
    my ($this,$package,$sym,$ref) = @_;

    no strict 'refs';
    @{"$package\::$sym"} = @$ref;

    return *{"$package\::$sym"}{ARRAY};
}

# -----------------------------------------------------------------------------

=head3 setScalar() - Setze Package-Skalar auf Wert

=head4 Synopsis

    $ref = $this->setScalar($package,$name,$val);

=head4 Description

Setze Package-Skalar mit dem Namen $name auf den Wert $val
und liefere eine Referenz auf die Variable zurück.

=head4 Example

=over 2

=item *

Setze Paket-Skalar 'n' auf den Wert 99:

    $ref = $this->setScalar($package,n=>99);

=back

=cut

# -----------------------------------------------------------------------------

sub setScalar {
    my ($this,$package,$sym,$val) = @_;

    no strict 'refs';
    ${"$package\::$sym"} = $val;

    return *{"$package\::$sym"}{'SCALAR'};
}

# -----------------------------------------------------------------------------

=head3 setScalarValue() - Setze Package-Skalar auf Wert

=head4 Synopsis

    $this->setScalarValue($package,$name=>$val);

=head4 Description

Setze Package-Skalar mit dem Namen $name auf den Wert $val.

=head4 Example

=over 2

=item *

Setze Paket-Skalar 'n' auf den Wert 99:

    $ref = Quiq::Perl->setScalarValue($package,n=>99);

=back

=cut

# -----------------------------------------------------------------------------

sub setScalarValue {
    my ($this,$package,$sym,$val) = @_;

    no strict 'refs';
    no warnings 'once';
    ${"$package\::$sym"} = $val;

    return;
}

# -----------------------------------------------------------------------------

=head3 getScalarValue() - Liefere Wert von Package-Skalar

=head4 Synopsis

    $val = $this->getScalarValue($package,$name);

=head4 Example

=over 2

=item *

Ermittele Wert von Paket-Skalar 'n':

    $val = Quiq::Perl->getScalarValue($package,'n');

=back

=cut

# -----------------------------------------------------------------------------

sub getScalarValue {
    my ($this,$package,$name) = @_;

    no strict 'refs';
    no warnings 'once';
    return ${"$package\::$name"};
}

# -----------------------------------------------------------------------------

=head3 setVar() - Setze Package-Variable auf Wert

=head4 Synopsis

    $ref = $this->setVar($package,$sigil,$name,$ref);

=head4 Description

Setze Paketvariable vom Typ $sigil ('$', '@' oder '%') mit dem Namen
$name auf den von $ref referenzierten Wert (also $$ref
(falls Skalar) oder @$ref (falls Array) oder %$ref (falls Hash))
und liefere eine Referenz auf die Variable zurück.

Die Subroutine kopiert den Wert, sie erzeugt keinen Alias!

=head4 Example

=over 2

=item *

Skalar

    $ref = Quiq::Perl->setVar($package,'$','s',\99);

=item *

Array

    $ref = Quiq::Perl->setVar($package,'@','a',\@arr);

=item *

Hash

    $ref = Quiq::Perl->setVar($package,'%','h',\%hash);

=back

=cut

# -----------------------------------------------------------------------------

sub setVar {
    my ($this,$package,$sigil,$sym,$ref) = @_;

    # Exception, wenn Sigil nicht korrekt
    my $type = Quiq::Perl->sigilToType($sigil);

    no strict 'refs';
    if ($sigil eq '$') {
        ${"$package\::$sym"} = $$ref;
    }
    elsif ($sigil eq '@') {
        @{"$package\::$sym"} = @$ref;
    }
    elsif ($sigil eq '%') {
        %{"$package\::$sym"} = %$ref;
    }

    return *{"$package\::$sym"}{$type};
}

# -----------------------------------------------------------------------------

=head3 getVar() - Liefere Referenz auf Package-Variable

=head4 Synopsis

    $ref = $this->getVar($package,$sigil,$name,@opt);

=head4 Options

=over 4

=item -create => $bool (Default: 0)

Erzeuge Variable, falls sie nicht existiert.

=back

=head4 Description

Liefere eine Referenz auf Package-Variable $name vom Typ $sigil
('$','@' oder '%'). Existiert die Variable nicht, liefere undef.

=head4 Caveats

=over 2

=item *

Skalare Variable

=back

Skalare Paketvariable, die mit "our" vereinbart sind und den Wert undef
haben, werden von der Funktion nicht erkannt bzw. nicht sicher
erkannt (Grund ist unklar). Mit "our" vereinbarte skalare
Paketvariable mit definiertem Wert werden sicher erkannt. Workaround:
Skalare Paketvariable, die mit der Methode abgefragt werden sollen,
auch wenn sie den Wert undef haben, mit "use vars" vereinbaren.

=cut

# -----------------------------------------------------------------------------

sub getVar {
    my $this = shift;
    my $package = shift;
    my $sigil = shift;
    my $name = shift;

    my $type = Quiq::Perl->sigilToType($sigil);

    my $create = 0;
    if (@_) {
        Quiq::Option->extract(\@_,
            -create => \$create,
        );
    }

    no strict 'refs';

    if (!$create) {
        # Zunächst auf Symboltabelleneintrag testen. Wenn keiner
        # existiert, gibt es die Variable nicht. Ohne diesen Test
        # würden Symboltabelleneinträge durch den darauffolgenden Code
        # angelegt werden.

        return undef if !exists ${"$package\::"}{$name};

        if ($type eq 'SCALAR') {
            if (!defined ${"$package\::$name"}) {
                use strict;
                # Unterdrücke 'Variable "..." not imported' Warnungen,
                # die neben der Exception generiert werden.
                local $SIG{__WARN__} = sub {};
                eval "package $package; \$$name";
                return undef if $@;
            }
        }
    }

    my $ref = *{"$package\::$name"}{$type};

    # Wenn $create "wahr", Variable erzeugen, falls nicht existent

    if (!$ref && $create) {
        $ref = $this->setVar($package,$sigil,$name,
            {'$'=>\undef,'@'=>[],'%'=>{}}->{$sigil});
    }

    return $ref;
}

# -----------------------------------------------------------------------------

=head3 setSubroutine() - Setze Package-Subroutine auf Wert

=head4 Synopsis

    $ref = $this->setSubroutine($package,$name=>$ref);

=head4 Returns

Referenz auf die Subroutine.

=head4 Description

Füge Subroutine $ref zu Package $package unter dem Namen $name hinzu.
Existiert eine Package-Subroutine mit dem Namen bereits,
wird diese ersetzt.

=head4 Examples

Definition:

    $ref = Quiq::Perl->setSubroutine('My::Class',m=>sub {...});

Aufruf:

    My::Class->m(...);

oder

    $ref->(...);

=cut

# -----------------------------------------------------------------------------

sub setSubroutine {
    my ($this,$package,$name,$ref) = @_;

    no strict 'refs';
    no warnings 'redefine';
    return *{"$package\::$name"} = $ref;
}

# -----------------------------------------------------------------------------

=head3 getSubroutine() - Liefere Referenz auf Subroutine

=head4 Synopsis

    $ref = $this->getSubroutine($package,$name);

=head4 Description

Liefere Referenz auf Subroutine $name in Package $package. Enthält
das Package keine Subroutine mit dem Namen $name, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub getSubroutine {
    my ($this,$package,$name) = @_;

    no strict 'refs';
    if (defined *{"$package\::$name"}) {
        return *{"$package\::$name"}{CODE};
    }

    return undef;
}

# -----------------------------------------------------------------------------

=head2 Suchpfade

=head3 basicIncPaths() - Grundlegende Modul-Suchpfade

=head4 Synopsis

    @paths|$pathA = $class->basicIncPaths;

=head4 Description

Liefere die Liste der I<grundlegenden> Suchpfade des aktuell laufenden
Perl-Interpreters. Ergänzungen durch

=over 2

=item *

-II<path>

=item *

PERLLIB

=item *

PERL5LIB

=item *

use lib (I<@paths>)

=item *

usw.

=back

sind I<nicht> enthalten.

Die Liste entspricht dem Ergebnis des Aufrufs

    $ PERLLIB= PERL5LIB= perl -le 'print join "\n",@INC'

=head4 See Also

=over 2

=item *

L<additionalIncPaths|"additionalIncPaths() - Zusätzliche Modul-Suchpfade">()

=item *

L<incPaths|"incPaths() - Alle Modul-Suchpfade">()

=back

=head4 Example

    Quiq::Perl->basicIncPaths;
    ==>
    /etc/perl
    /usr/local/lib/x86_64-linux-gnu/perl/5.20.2
    /usr/local/share/perl/5.20.2
    /usr/lib/x86_64-linux-gnu/perl5/5.20
    /usr/share/perl5
    /usr/lib/x86_64-linux-gnu/perl/5.20
    /usr/share/perl/5.20
    /usr/local/lib/site_perl
    .

=cut

# -----------------------------------------------------------------------------

my @Paths;

sub basicIncPaths {
    my $class = shift;

    if (!@Paths) {
        my $cmd = qq|PERLLIB= PERL5LIB= $^X -e 'print join "\n",\@INC'|;
        @Paths = split /\n/,qx/$cmd/;
    }

    return wantarray? @Paths: \@Paths;
}

# -----------------------------------------------------------------------------

=head3 additionalIncPaths() - Zusätzliche Modul-Suchpfade

=head4 Synopsis

    @paths|$pathA = $class->additionalIncPaths;

=head4 Description

Liefere die zusätzlichen Suchpfade des aktuell laufenden
Perl-Programms, also die Suchpfade, die über die grundlegenden
Suchpfade des Perl_interpreters hinausgehen.

=head4 See Also

=over 2

=item *

L<basicIncPaths|"basicIncPaths() - Grundlegende Modul-Suchpfade">()

=item *

L<incPaths|"incPaths() - Alle Modul-Suchpfade">()

=back

=cut

# -----------------------------------------------------------------------------

sub additionalIncPaths {
    my $class = shift;

    my %path;
    @path{@INC} = (1) x @INC;
    for ($class->basicIncPaths) {
        delete $path{$_};
    }
    my @paths = keys %path;

    return wantarray? @paths: \@paths;
}

# -----------------------------------------------------------------------------

=head3 incPaths() - Alle Modul-Suchpfade

=head4 Synopsis

    @paths|$pathA = $class->incPaths;

=head4 Description

Liefere I<alle> Suchpfade des aktuell laufenden Perl-Programms,
also die Werte des @INC-Arrays Im Skalar-Kontext liefere eine
Referenz auf das Array.

=head4 See Also

=over 2

=item *

L<basicIncPaths|"basicIncPaths() - Grundlegende Modul-Suchpfade">()

=item *

L<additionalIncPaths|"additionalIncPaths() - Zusätzliche Modul-Suchpfade">()

=back

=cut

# -----------------------------------------------------------------------------

sub incPaths {
    my $class = shift;
    return wantarray? @INC: \@INC;
}

# -----------------------------------------------------------------------------

=head2 POD

=head3 getPod() - Extrahiere POD-Dokumentation aus Perl-Quelltext

=head4 Synopsis

    $pod = $this->getPod($file);
    $pod = $this->getPod(\$text);
    
    ($pod,$encoding) = $this->getPod($file);
    ($pod,$encoding) = $this->getPod(\$text);

=head4 Description

Lies den POD-Code aus Datei $file bzw. Quelltext $text und liefere
diesen zurück. Ist ein Encoding definiert, dekodiere den
gelieferten POD-Code entsprechend. Im Array-Kontext liefere
zusätzlich zum POD-Code das Encoding.

=cut

# -----------------------------------------------------------------------------

sub getPod {
    my ($this,$input) = @_;

    my $pod = '';

    my $inPod = 0;
    my $fh = Quiq::FileHandle->new('<',$input);
    while (<$fh>) {
        if (/^=cut/) {
            $inPod = 0;
            next;
        }
        elsif (/^=[a-z]/) {
            $inPod = 1;
        }
        if ($inPod) {
            $pod .= $_;
        }
    }
    $fh->close;

    $pod =~ s/\s+$//;
    $pod .= "\n";

    my ($encoding) = $pod =~ /^=encoding\s+(\S+)/m;
    if ($encoding) {
        $pod = Encode::decode($encoding,$pod);
    }

    return wantarray? ($pod,$encoding): $pod;
}

# -----------------------------------------------------------------------------

=head3 getPodValues() - Liefere Content von POD-Abschnitten

=head4 Synopsis

    $this->getPodValues($file,@keyRef);
    $this->getPodValues(\$text,@keyRef);

=cut

# -----------------------------------------------------------------------------

sub getPodValues {
    my ($this,$input,%keyRef) = @_;

    my $pod = $this->getPod($input);
    for my $key (keys %keyRef) {
        my $ref = $keyRef{$key};
        if ($$ref) {
            next;
        }
        my ($val) = $pod =~ /(?:^|\n\n)=head1 $key\n\n(.*?)(\n\n=head1|$)/s;
        if (defined($val) && $val ne '') {
            $$ref = $val;
        }
    }
    
    return;
}

# -----------------------------------------------------------------------------

=head3 removePod() - Entferne POD-Abschnitte aus Quelltext

=head4 Synopsis

    $newCode = $this->removePod($code);
    $this->removePod(\$code);

=head4 Description

Entferne alle POD-Abschnitte aus dem Quelltext $code und liefere
den resultierenden Quelltext zurück. Wird eine Referenz auf
den Quelltext übergeben, erfolgt die Manipulation in-place.

Auf den POD-Abschnitt folgende Leerzeilen (die außerhalb des
POD-Code liegen) werden ebenfalls entfernt.

=cut

# -----------------------------------------------------------------------------

sub removePod {
    my $this = shift;
    my $ref = ref $_[0]? shift: \shift;

    $$ref =~ s/^=[a-z].*?^=cut\n*//msg;

    return $$ref;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.149

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2019 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
