# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Test::Class - Basisklasse für Testklassen

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Quiq::Test::Class ist eine Basisklasse für Testklassen (Unit-Tests). Als
Vorbild diente Test::Class, welches nicht zu den Perl Kernmodulen
zählt. Einige Details sind anders, etliche Funktionalität ist
nicht implementiert, da sie (noch) nicht gebraucht wird.

=head2 Testmethoden

Quiq::Test::Class definiert sechs Typen von Testmethoden: Init(N), Foreach,
Startup(N), Shutdown(N), Setup(N), Teardown(N) und Test(N). Der Typ der
Testmethode wird als Subroutine-Attribut angegeben. Eine Testmethode
besitzt folgenden Aufbau:

  sub NAME : TYPE(N) {
      my $self = shift;
      ...
      return;
  }

Hierbei ist NAME der Name der Testmethode, TYPE der Typ der
Testmethode und N die Anzahl der Tests innerhalb der Methode.
Der Typ Forech hat keinen Parameter N. Jede Testmethode besitzt einen
Parameter - das Testobjekt, das an alle Testmethoden übergeben wird
(Beschreibung siehe unten). Die Methode liefert keinen Wert zurück.

=head2 Aufrufreihenfolge

MEMO: Die Foreach-Methoden werden entgegen der unten stehenden Beschreibung
zuerst aufgerufen! Die Testzählung muss anders implementiert werden,
Test::More erlaubt die Angabe der Gesamtanzahl nun auch am Ende
(Funktion done_testing()).

=over 2

=item *

Init(N)

Zunächst werden alle Methoden vom Typ Init(N) aufgerufen. In diesen
Methoden können jegliche Vorabprüfungen vor Ausführung des eigentlichen
Testcodes durchgeführt werden, z.B. ob die Systemumgebung die Ausführung
der Tests überhaupt gestattet oder ob das Modul überhaupt ladbar ist.

=item *

Foreach

Danach werden die Methoden vom Typ Foreach aufgerufen. Diese führen
selbst keine Tests durch, sondern liefern jeweils eine Liste, über
deren Elementen der anschließende
Startup/Setup/Test/Teardown/Shutdown-Zyklus
wiederholt durchlaufen wird. Bei jedem Iterationsschritt wird der
nächste Wert als zweiter Parameter (erster ist das Testobjekt) an die
Testmethoden übergeben.

=item *

Test(N)

Die normale Testmethode ist vom Typ Test(N), sie wird im Zuge des
Gesamttests genau einmal aufgerufen.

=item *

Setup(N), Teardown(N)

Vor jeder Testmethode vom Typ Test(N) werden alle Methoden vom
Typ Setup(N) aufgerufen und danach alle Methoden vom Typ Teardown(N).

=item *

Startup(N), Shutdown(N)

Mit jedem Iterationsschritt werden alle Testmethoden vom Typ Startup(N)
aufgerufen, am Ende alle Testmethoden vom Typ Shutdown(N).

=item *

Ignore...

Beginnt der Typ mit der Zeichenkette "Ignore", wird die betreffende
Testmethode ignoriert, also nicht ausgeführt. Dies kann angewendet
werden, um Testmethoden als Ganzes auszukommentieren, z.B. wenn
eine Reihe von Tests umgearbeitet werden.

=back

=head2 Testobjekt

Das Testobjekt wird vor Aufruf der ersten Testmethode instaniiert
und nach Aufruf der letzten Testmethode destrukturiert, es wird
also an alle Testmethoden, unabhängig von ihrem Typ, übergeben.

Mittels der Methoden set() und get() können Schlüssel/Wert-Paare
auf dem Test gesetzt und abgefragt werden. Auf diese Weise
können Objekte von den Startup- und Setup-Methoden an die
Test-Methoden weitergegeben und dort abgefragt werden.

=head2 Gruppierung von Testmethoden

Testmethoden können mittels des Subroutine-Attributs Group(Regex)
gruppiert werden. Diese Möglichkeit kann dazu genutzt werden,
um bestimmte Setup-, Test- und Teardown-Methoden zu einer Einheit
zusammenzufassen.

=head2 Folgende Tests überspringen

Mitunter sind die Testmethoden einer Testklasse ganz oder ab einem
bestimmten Punkt nicht anwendbar, weil bestimmte Voraussetzungen auf
dem System nicht vorhanden sind, z.B. ein bestimmtes Modul. In dem Fall
sollen alle folgenden Tests übergangen werden.

Eine Überprüfung der Voraussetzungen in der ersten Testmethode
kann folgendermaßen vorgenommen werden:

  sub initMethod : Init(0) {
      my $self = shift;
  
      if (...auf Eigenschaft testen...) {
          $self->skipAllTests('...Meldung...');
          return;
      }
  }

=head2 Klasse oder Programm von Tests ausnehmen

Ist eine Klasse oder ein Programm nicht testbar, z.B. weil auf dem
lokalen Rechner die erforderlichen Perl-Module nicht vorhanden sind,
kann die der gesamte Code von Tests ausgenommen werden.

=over 4

=item 1.

Unter CoTeDo wird für die Klasse oder das Programm definiert:

  TestProcedure:
      Minimal

=item 2.

Als Testmethode wird definiert:

  # <Test> ----------------------------------------------
  
  sub initMethod : Init(1) {
      my $self = shift;
  
      my $host = '<host>'; # Wir prüfen auf den Hostnamen
  
      if (Quiq::System->hostname ne $host) {
          $self->skipAllTests("Not on $host");
          return;
      }
      $self->ok(1);
  
      $self->useOk('<class>');
  }

=back

Hierbei ist C<< <host> >> der Name des Hosts, auf dem der Code läuft,
C<< <class> >> ist die Name der (Programm-)Klasse, die getestet werden soll.

=cut

# -----------------------------------------------------------------------------

package Quiq::Test::Class;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;
use utf8;

our $VERSION = '1.228';

use Test::Builder ();
use Quiq::Option;
use Quiq::Path;
use Quiq::Object;
use Quiq::Converter;
use Test::More ();
use Quiq::System;
use Quiq::Assert;
use Quiq::Unindent;
use Quiq::Test::Class::Method;

# -----------------------------------------------------------------------------

# Liste der Test-Methoden
our @Methods;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstuktor

=head4 Synopsis

  $test = $class->new;

=head4 Description

Instantiiere ein Testobjekt und liefere eine Referenz auf dieses
Objekt zurück.

Das Testobjekt kennt die Testmethoden, die zur Klasse $class und
ihren Basisklassen gehören. Ferner ist es Träger der Attribut/Wert-Paare,
die mittels set() und get() gesetzt und abgefragt werden können.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;

    my %meth;
    for my $m (@Methods) {
        # Nur Methoden berücksichtigen, die zur Klasse und
        # ihren Basisklassen gehören.

        my $code;
        if (($code = $class->can($m->name)) && $code == $m->code) {
            push @{$meth{$m->type} ||= []},$m;
        }
    }

    my $builder = Test::Builder->new;
    $builder->exported_to($class);

    # Encoding der Umgebung setzen

    my $encoding = Quiq::System->encoding;
    binmode $builder->output,":encoding($encoding)";
    binmode $builder->failure_output,":encoding($encoding)";
    binmode $builder->todo_output,":encoding($encoding)";

    # Test::Builder-Objekt, Testmethoden, Testobjekt-Attribute,
    # SkipAll-Meldung, Skip-Meldung
    return bless [$builder,\%meth,{},'',''],$class;
}

# -----------------------------------------------------------------------------

=head2 Getter/Setter

=head3 get() - Liefere Attributwerte

=head4 Synopsis

  $val = $test->get($key);
  @vals = $test->get(@keys);

=head4 Description

Liefere die Werte @vals zu den Attributen @keys. Existiert ein
Attribut nicht, wird eine Exception geworfen.

=cut

# -----------------------------------------------------------------------------

sub get {
    my $self = shift;

    # FIXME: Klasse auf resticted Hash umstellen

    my $hash = $self->[2];
    my @arr;
    for my $key (@_) {
        if (!exists $hash->{$key}) {
            $self->throw('TEST-00002: Unbekanntes Attribut',Key=>$key);
        }
        push @arr,$hash->{$key};
    }
    return wantarray? @arr: $arr[0];
}

# -----------------------------------------------------------------------------

=head3 set() - Setze Attribut/Wert-Paare

=head4 Synopsis

  $test->set(@keyVal);

=head4 Description

Setze die angegebenen Attribut/Wert-Paare auf dem Testobjekt. Die Methode
liefert keinen Wert zurück.

Die Methode ermöglicht Startup- und Setup-Methoden, Attribute auf dem
Testobjekt zu setzen, die in den Test-, Shutdown- und
Teardown-Methoden abgefragt werden können.

=cut

# -----------------------------------------------------------------------------

sub set {
    my $self = shift;
    while (@_) {
        my $key = shift;
        my $val = shift;
        $self->[2]->{$key} = $val;
    }
    return;
}

# -----------------------------------------------------------------------------

=head2 Directories

=head3 fixtureDir() - Liefere Pfad zum Fixture-Verzeichnis

=head4 Synopsis

  $dir = $this->fixtureDir(@opt);
  $dir = $this->fixtureDir($subpath,@opt);

=head4 Options

=over 4

=item -create => $bool (Default: 0)

Erzeuge Verzeichnis, falls es nicht existiert.

=back

=head4 Description

Liefere den Pfad zum Fixture-Verzeichnis der Testklasse. Ist Parameter
$subpath angegeben, wird diese Zeichenkette, per / getrennt, zum Pfad
hinzugefügt.

=cut

# -----------------------------------------------------------------------------

sub fixtureDir {
    my $this = shift;
    # @_: $subPath,@opt

    my $create = 0;
    Quiq::Option->extract(-mode=>'sloppy',\@_,
        -create => \$create,
    );

    my $dir = $this->testDir('fixture');
    if (@_) {
        my $subPath = shift;
        $dir .= "/$subPath";
    }

    if ($create) {
        Quiq::Path->mkdir($dir,-recursive=>1);
    }

    return $dir;
}

# -----------------------------------------------------------------------------

=head3 testDir() - Liefere Pfad zum Testverzeichnis

=head4 Synopsis

  $dir = $this->testDir;
  $dir = $this->testDir($subPath);

=head4 Description

Liefere den Pfad zum Testverzeichnis. Ist Parameter $subPath
angegeben, wird diese Zeichenkette, per / getrennt, zum Pfad
hinzugefügt.

Das Testverzeichnis ist das Verzeichnis, in dem die Datei Test.pm
(Definition der Testklasse) liegt. Die Methode kann als Objekt- oder
als Klassemethode gerufen werden. Der Aufruf als Klassenmethode ist
nützlich, wenn auf die Testverzeichnisse anderer Testklassen
zugegriffen werden soll.

=cut

# -----------------------------------------------------------------------------

sub testDir {
    my $class = Quiq::Object->this(shift);
    my $subPath = shift;

    my $dir = $0;
    $dir =~ s/\.[^.]*$//; # Endung entfernen

    $dir .= "/$subPath" if $subPath;

    return $dir;
}

# -----------------------------------------------------------------------------

=head3 testPath() - Liefere vollständigen Pfad zu Testverzeichnis/datei

=head4 Synopsis

  $fullPath = $this->testPath($file);

=cut

# -----------------------------------------------------------------------------

sub testPath {
    my ($this,$path) = @_;

    if (-d 't') {
        # Wir sind in einem Modulverzeichnis. Per Konvention beginnen
        # die Testdateien mit <package>/test. Diesen Präfix
        # reduzieren zu t.
        $path =~ s|^\w+/test|t|;
    }
    else {
        # Übler Hack. FIXME: Beheben.
        my $dir = '.cotedo/root/file'; 
        $path = "$dir/$path";
    }

    return $path;
}

# -----------------------------------------------------------------------------

=head2 Methoden

=head3 methods() - Liefere Liste von Testmethoden

=head4 Synopsis

  @arr = $test->methods($type);

=head4 Description

Liefere die Liste der Testmethoden von Typ $type.

Folgende Typen von Testmethoden sind definiert:

  Init
  Foreach
  Startup
  Setup
  Test
  Teardown
  Shutdown

=cut

# -----------------------------------------------------------------------------

sub methods {
    my $self = shift;
    my $type = shift;

    my $arr = $self->[1]->{$type} || [];

    return @$arr;
}

# -----------------------------------------------------------------------------

=head3 runTests() - Führe Testmethoden aus

=head4 Synopsis

  $this->runTests;

=head4 Description

Führe die Tests der Testklasse bzw. des Testobjekts $this aus.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub runTests {
    my ($class,$self) = Quiq::Object->this(shift);

    # Test-Objekt instantiieren, wenn als Klassenmethode gerufen
    $self ||= $class->new;

    my @calls;     # Liste der Testmethoden
    my $tests = 0; # Anzahl der Tests insgesamt

    # Init-Methoden

    for my $meth ($self->methods('Init')) {
        push @calls,[$meth];
        $tests += $meth->tests;
    }

    # Foreach-Methoden. Diese werden sofort aufgerufen und liefern
    # die Werte, mit denen die restlichen Methoden aufgerufen werden.

    my @vals;
    for my $meth ($self->methods('Foreach')) {
        my $name = $meth->name;
        push @vals,eval { $self->$name };
        if ($@) {
            # FIXME: Erstmal rausbomben, später verbessern
            $class->throw(
                'TEST-00005: Foreach-Testmethode fehlgeschlagen',
                Error => $@,
            );
        }
    }
    push @vals,undef if !@vals;

    # Startup/Setup/Test/Teardown/Shutdown-Methoden für jeden
    # Wert aus @val aufrufen

    # FIXME: Als Testanzahl undef erlauben, was bedeutet, dass die
    # Anzahl der Tests unbekannt ist. Wenn wenigstens eine Methode
    

    for my $val (@vals) {
        # Startup

        for my $meth ($self->methods('Startup')) {
            push @calls,[$meth,$val];
            $tests += $meth->tests;
        }

        for my $meth ($self->methods('Test')) {
            my $name = $meth->name;

            # Setup

            my $group;
            for my $setup ($self->methods('Setup')) {
                next if ($group = $setup->group) && $name !~ /$group/;
                push @calls,[$setup,$val];
                $tests += $setup->tests;
            }

            # Test

            push @calls,[$meth,$val];
            $tests += $meth->tests;

            # Teardown

            for my $teardown ($self->methods('Teardown')) {
                next if ($group = $teardown->group) && $name !~ /$group/;
                push @calls,[$teardown,$val];
                $tests += $teardown->tests;
            }
        }

        # Shutdown

        for my $meth ($self->methods('Shutdown')) {
            push @calls,[$meth,$val];
            $tests += $meth->tests;
        }
    }

    my $builder = $self->[0];
    $builder->plan(tests=>$tests);

    my $i = 0;
    for (@calls) {
        my ($meth,$arg) = @$_;

        my $name = $meth->name;
        my $n = $builder->current_test+$meth->tests;

        if ($ENV{'TEST_VERBOSE'}) {
            my $nl = $i++? "\n": '';
            # Klasse/Methode ausgeben
            # $builder->_print("$nl$class->$name");
        }

        eval { $self->$name($arg) };
        if ($@) {
            # Exception melden und alle weiteren Tests
            # in der Methode übergehen

            $builder->ok(0,$@);
            for ($builder->current_test+1 .. $n) {
                $builder->skip('Exception');
            }
        }
        elsif (my $skipAllMsg = $self->[3]) {
            # Alle weiteren Tests aller Testmethoden übergehen

            for ($builder->current_test+1 .. $tests) {
                $builder->skip($skipAllMsg);
            }
            last;
        }
        elsif (my $skipMsg = $self->[4]) {
            # Alle weiteren Tests der Testmethode übergehen

            if (defined $self->[5]) {
                $n = $builder->current_test+$self->[5];
            }

            for ($builder->current_test+1 .. $n) {
                $builder->skip($skipMsg);
            }
            $self->[4] = '';   # FIXME: Abschaltung besser machen
            $self->[5] = undef;
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 skipAllTests() - Übergehe alle folgenden Tests

=head4 Synopsis

  $test->skipAllTests($msg);

=head4 Alias

skipAll()

=head4 Description

Setze Abbruchmeldung $msg auf dem Testobjekt und übergehe alle
folgenden Tests aller Testmethoden. Die Methode
liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub skipAllTests {
    my $self = shift;
    my $msg = shift;

    # Um Warnungen à la "does not map to ascii" zu verhindern
    $self->[3] = Quiq::Converter->umlautToAscii($msg);

    return;
}

{
    no warnings 'once';
    *skipAll = \&skipAllTests;
}

# -----------------------------------------------------------------------------

=head3 skipTest() - Brich Test-Methode ab

=head4 Synopsis

  $test->skipTest($msg);
  $test->skipTest($n,$msg);

=head4 Description

Setze Abbruchmeldung $msg auf dem Testobjekt und übergehe alle
folgenden Tests bzw. die nächsten $n Tests der aktuellen Testmethode.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub skipTest {
    my $self = shift;
    # @_: $n,$msg -or- $msg

    if ($_[0] =~ /^\d+$/) {
        $self->[5] = shift;
    }

    # Um Warnungen à la "does not map to ascii" zu verhindern
    $self->[4] = Quiq::Converter->umlautToAscii(shift);

    return;
}

# -----------------------------------------------------------------------------

=head2 Testmethoden

Die Methoden

=over 2

=item *

C<ok>

=item *

C<is>

=item *

C<isnt>

=item *

C<like>

=item *

C<unlike>

=back

haben jeweils einen Alias C<okTest>, C<isTest> usw., der verwendet werden
kann, wenn in der Testklasse das Modul C<Test::More> genutzt wird.
Der Nameclash zwischen den C<Test::More>-Funktionen und den
gleich benannten C<< Quiq::Test::Class >>-Methoden kann damit umgangen werden.
Alte Testklassen, die C<Test::More> direkt benutzen, sollten portiert
werden. Wenn dies vollständig passiert ist, können die Aliase entfallen.

=head3 useOk() - Prüfe, ob Modul geladen werden kann

=head4 Synopsis

  $bool = $test->useOk($module);

=cut

# -----------------------------------------------------------------------------

sub useOk {
    my $self = shift;
    my $module = shift;
    # @_: @imports

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return Test::More::use_ok($module,@_);    
}

# -----------------------------------------------------------------------------

=head3 syntaxOk() - Prüfe Syntax eines Perl-Programms

=head4 Synopsis

  $bool = $test->syntaxOk($program);
  $bool = $test->syntaxOk($program,$text);

=head4 Arguments

=over 4

=item $program

Name oder Pfad des Programms. Ist kein absoluter Pfad angegeben,
wird das Programm über die Environment-Variable PATH gesucht.

=back

=head4 Returns

nichts

=cut

# -----------------------------------------------------------------------------

sub syntaxOk {
    my ($self,$program,$text) = @_;

    # Um Warnungen à la "does not map to ascii" zu verhindern
    $text = Quiq::Converter->umlautToAscii($text);

    # Suche Programm via PATH, wenn kein absoluter Pfad
    $program = Quiq::System->searchProgram($program);

    # Prüfe Syntax per "perl -c FILE"

    my $cmd = "perl -c $program 2>&1 >/dev/null | grep -v OK";
    my $out = `$cmd`;
    my $bool = $? == 256 && $out eq '';

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::ok($bool,$text || 'SYNTAX ERROR');
    if (!$bool) {  
        my $msg = qq|COMMAND: "$cmd"\n|;
        $msg .= "--- OUTPUT ---\n";
        $msg .= $out;
        $msg .= "---- END -----\n";
        $msg =~ s/^/  /mg;
        Test::More::diag($msg);
    }

    return $bool;
}

# -----------------------------------------------------------------------------

=head3 ok() - Prüfe, ob boolscher Wert wahr ist

=head4 Synopsis

  $bool = $test->ok($bool);
  $bool = $test->ok($bool,$text);

=head4 Alias

okTest()

=cut

# -----------------------------------------------------------------------------

sub ok {
    my ($self,$bool,$text) = @_;

    # Um Warnungen à la "does not map to ascii" zu verhindern
    $text = Quiq::Converter->umlautToAscii($text);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return Test::More::ok($bool,$text);    
}

{
    no warnings 'once';
    *okTest = \&ok;
}

# -----------------------------------------------------------------------------

=head3 in() - Prüfe, ob Wert dem erwarteten Wert entspricht

=head4 Synopsis

  $bool = $test->in($got,\@expected);
  $bool = $test->in($got,\@expected,$text);

=head4 Alias

inTest()

=cut

# -----------------------------------------------------------------------------

sub in {
    my ($self,$got,$expectedA,$text) = @_;

    my $bool = Quiq::Assert->isEnumValue($got,$expectedA);

    # Um Warnungen à la "does not map to ascii" zu verhindern
    $text = Quiq::Converter->umlautToAscii($text);

    # MEMO: So implementiert man einen speziellen Test

    my $tb = Test::More->builder; # Test::Builder-Objekt besorgen
    $tb->ok($bool,$text);         # Testergebnis protokollieren
    if (!$bool) {                 # Im Fehlerfall Diagnose protokollieren
        my @arr = @$expectedA;
        my $last = pop @arr;
        my $expected = join ', ',map {"'$_'"} @arr;
        if ($expected) {
            $expected .= ' or ';
        }
        $expected .= "'$last'";
        # Konform zu Test::Builder krautig formatiert
        $tb->diag("    got: '$got'\n    expected: $expected");
    }

    return $bool;                 # Testergebnis zurückliefern
}

sub in_orig {
    my ($self,$got,$expectedA,$text) = @_;

    my $bool = Quiq::Assert->isEnumValue($got,$expectedA);

    # Um Warnungen à la "does not map to ascii" zu verhindern
    $text = Quiq::Converter->umlautToAscii($text);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return Test::More::ok($bool,$text);    
}

{
    no warnings 'once';
    *inTest = \&in;
}

# -----------------------------------------------------------------------------

=head3 is() - Prüfe, ob Wert dem erwarteten Wert entspricht

=head4 Synopsis

  $bool = $test->is($got,$expected);
  $bool = $test->is($got,$expected,$text);

=head4 Alias

isTest()

=cut

# -----------------------------------------------------------------------------

sub is {
    my ($self,$got,$expected,$text) = @_;

    # Um Warnungen à la "does not map to ascii" zu verhindern
    $text = Quiq::Converter->umlautToAscii($text);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return Test::More::is($got,$expected,$text);    
}

{
    no warnings 'once';
    *isTest = \&is;
}

# -----------------------------------------------------------------------------

=head3 isnt() - Prüfe, ob Wert vom erwarteten Wert abweicht

=head4 Synopsis

  $bool = $test->isnt($got,$expected);
  $bool = $test->isnt($got,$expected,$text);

=head4 Alias

isntTest()

=cut

# -----------------------------------------------------------------------------

sub isnt {
    my ($self,$got,$expected,$text) = @_;

    # Um Warnungen à la "does not map to ascii" zu verhindern
    $text = Quiq::Converter->umlautToAscii($text);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return Test::More::isnt($got,$expected,$text);
}

{
    no warnings 'once';
    *isntTest = \&isnt;
}

# -----------------------------------------------------------------------------

=head3 isText() - Prüfe, ob Wert dem erwarteten Wert entspricht

=head4 Synopsis

  $bool = $test->isText($got,$expected);
  $bool = $test->isText($got,$expected,$text);

=head4 Description

Im Unterschied zur Methode is(), wird auf das Argument $expected
die Methode Quiq::Unindent->trimNl() angewendet. Dies ermöglicht
den einfachen Vergleich im Falle eines mehrzeiligen Textes.

=cut

# -----------------------------------------------------------------------------

sub isText {
    my ($self,$got,$expected,$text) = @_;

    # Um Warnungen à la "does not map to ascii" zu verhindern
    $text = Quiq::Converter->umlautToAscii($text);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return Test::More::is($got,Quiq::Unindent->trimNl($expected),$text);
}

# -----------------------------------------------------------------------------

=head3 floatIs() - Prüfe, ob Float-Wert dem erwarteten Wert entspricht

=head4 Synopsis

  $bool = $test->floatIs($got,$expected);
  $bool = $test->floatIs($got,$expected,$places);
  $bool = $test->floatIs($got,$expected,$places,$text);

=head4 Description

Vergleiche die Float-Werte $got und $expected nachdem beide Werte
auf $places Nachkommastellen gerundet wurden. Ist $places nicht
angegeben oder C<undef>, wird die Anzahl der Nachkommastellen
von $expected genommen.

=cut

# -----------------------------------------------------------------------------

sub floatIs {
    my ($self,$got,$expected,$places,$text) = @_;

    # Um Warnungen à la "does not map to ascii" zu verhindern
    $text = Quiq::Converter->umlautToAscii($text);

    # Runde auf die Nachkommastellen des erwarteten Werts

    if (!defined $places) {
        $expected =~ /\.(\d+)/;
        $places = length($1);
    }
    if ($places) {
        $got = sprintf '%.*f',$places,$got;
        $expected = sprintf '%.*f',$places,$expected;
    }

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return Test::More::is($got,$expected,$text);    
}

# -----------------------------------------------------------------------------

=head3 isClass() - Prüfe, ob Referenz zur erwarteten Klasse gehört

=head4 Synopsis

  $bool = $test->isClass($ref,$class);
  $bool = $test->isClass($ref,$class,$text);

=head4 Description

Vergleiche die die Klasse von $ref gegen $class. Der Test ist
erfolgreich, wenn ref($ref) und $class identisch sind.

=cut

# -----------------------------------------------------------------------------

sub isClass {
    my ($self,$ref,$class,$text) = @_;

    $text ||= "Object is a $class";

    # Um Warnungen à la "does not map to ascii" zu verhindern
    $text = Quiq::Converter->umlautToAscii($text);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return Test::More::ok($ref->isa($class),$text);    
}

# -----------------------------------------------------------------------------

=head3 isDeeply() - Prüfe, ob Datenstrukturen identisch sind

=head4 Synopsis

  $bool = $test->isDeeply($gotRef,$expectedRef);
  $bool = $test->isDeeply($gotref,$expectedRef,$text);

=cut

# -----------------------------------------------------------------------------

sub isDeeply {
    my ($self,$gotRef,$expectedRef,$text) = @_;

    # Um Warnungen à la "does not map to ascii" zu verhindern
    $text = Quiq::Converter->umlautToAscii($text);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return Test::More::is_deeply($gotRef,$expectedRef,$text);    
}

# -----------------------------------------------------------------------------

=head3 like() - Prüfe, ob Wert regulären Ausdruck matcht

=head4 Synopsis

  $bool = $test->like($got,qr/$expected/);
  $bool = $test->like($got,qr/$expected/,$text);

=head4 Alias

likeTest()

=cut

# -----------------------------------------------------------------------------

sub like {
    my ($self,$got,$regex,$text) = @_;

    # Um Warnungen à la "does not map to ascii" zu verhindern
    $text = Quiq::Converter->umlautToAscii($text);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return Test::More::like($got,$regex,$text);    
}

{
    no warnings 'once';
    *likeTest = \&like;
}

# -----------------------------------------------------------------------------

=head3 unlike() - Prüfe, ob Wert regulären Ausdruck nicht matcht

=head4 Synopsis

  $bool = $test->unlike($got,qr/$expected/);
  $bool = $test->unlike($got,qr/$expected/,$text);

=head4 Alias

unlikeTest()

=cut

# -----------------------------------------------------------------------------

sub unlike {
    my ($self,$got,$regex,$text) = @_;

    # Um Warnungen à la "does not map to ascii" zu verhindern
    $text = Quiq::Converter->umlautToAscii($text);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return Test::More::unlike($got,$regex,$text);    
}

{
    no warnings 'once';
    *unlikeTest = \&unlike;
}

# -----------------------------------------------------------------------------

=head3 cmpOk() - Prüfe, ob Vergleich wahr ist

=head4 Synopsis

  $bool = $test->cmpOk($this,$op,$that);
  $bool = $test->cmpOk($this,$op,$that,$text);

=head4 Example

Vergleich auf numerische Verschiedenheit:

  $test->cmpOk($bigNum,'!=',$otherBigNum);

=cut

# -----------------------------------------------------------------------------

sub cmpOk {
    my ($self,$this,$op,$that,$text) = @_;

    # Um Warnungen à la "does not map to ascii" zu verhindern
    $text = Quiq::Converter->umlautToAscii($text);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return Test::More::cmp_ok($this,$op,$that,$text);    
}

# -----------------------------------------------------------------------------

=head2 Ausgabe

=head3 diag() - Gib Diagnose-Nachricht aus

=head4 Synopsis

  $bool = $test->diag(@msg);

=cut

# -----------------------------------------------------------------------------

sub diag {
    return shift->[0]->diag(@_);
}

# -----------------------------------------------------------------------------

=head2 Private Methoden

=head3 MODIFY_CODE_ATTRIBUTES() - Callback für Subroutines mit Attributen

=head4 Synopsis

  @attrib = $class->MODIFY_CODE_ATTRIBUTES($ref,@attrib);

=head4 Description

Methode, die von Perl zur Compilezeit für jede Subroutine mit
Attributen gerufen wird.

Die Methode instantiiert ein Methodenobjekt für jede Testmethode und
speichert sie zur späteren Analyse in der klassenglobalen Liste
@Methods.

=cut

# -----------------------------------------------------------------------------

sub MODIFY_CODE_ATTRIBUTES {
    my $class = shift;
    my $ref = shift;

    my ($type,$tests,$group);
    for (@_) {
        if (/^(Init|Startup|Setup|Test|Teardown|Shutdown)\((\d+)\)$/) {
            $type = $1;
            $tests = $2;
        }
        elsif (/^Group\((.*?)\)/) {
            $group = $1;
        }
        elsif (/^(Foreach)$/) {
            $type = $1;
        }
        elsif (/^Ignore/) {
            next;
        }
        else {
            $class->throw(
                'TEST-00001: Unbekanntes Code-Attribut',
                Attribute => $_,
            );
        }
    }
    if ($type) {
        push @Methods,Quiq::Test::Class::Method->new(
            $class,$ref,$type,$tests,$group);
    }

    return;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.228

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2025 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
