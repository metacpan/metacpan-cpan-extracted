package Prty::ContentProcessor;
use base qw/Prty::Hash/;

use strict;
use warnings;

our $VERSION = 1.106;

use Prty::Path;
use Prty::Option;
use Time::HiRes ();
use Prty::Perl;
use Prty::Hash;
use Prty::DestinationTree;
use Prty::Terminal;
use Prty::Section::Parser;
use Prty::Section::Object;
use Prty::Formatter;
use Prty::PersistentHash;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::ContentProcessor - Prozessor für Abschnitts-Dateien

=head1 BASE CLASS

L<Prty::Hash>

=head1 SYNOPSIS

    use Prty::ContentProcessor;
    
    $cop = Prty::ContentProcessor->new('.mytool');
    $cop->registerType('MyTool::A','a','A','A');
    $cop->registerType('MyTool::B','b','B','A');
    ...
    $cop->load(@paths)->commit;
    
    for my $ent ($cop->entities) {
        $cop->msg($ent->name);
    }

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Prozessor für
Entitäts-Dateien. Die Dateien bestehen aus einer Folge von
Abschnitten, die von einem Abschnitts-Parser (s. Klasse
Prty::Section::Parser) geparsed und zu Abschnitts-Objekten
instantiiert werden.

Der Prozessor delegiert die Verarbeitung der Abschnitts-Objekte an
die per registerType() registierten Entitäts-Klassen
(Plugin-Schnittstelle). Diese bauen aus den Abschnitts-Objekten
Entitäts-Strukturen auf, aus denen die Ausgabedateien generiert
werden. Die Entitäts-Klassen sind nicht Teil des ContentProzessors.

Bei Anwendung der Operation L</commit>() wird der Quelltext jeder
Entität gegen den Stand im Storage verglichen. Im Falle einer
Änderung wird die Entität als geändert gekennzeichnet, d.h. ihre
Ausgabedateien müssen neu generiert werden.

Das Resultat der Ausführung ist eine Menge von Entitäts-Objekten
plus ihrem Änderungs-Status. Die Menge der Entitäts-Objekte kann
mit der Methode L</entities>() abgefragt werden.

=head2 Universelles Plugin

Ein I<Universelles Plugin> kann definiert werden, indem bei
L</registerType>() nur $pluginClass und $extension als Argumente
angegeben werden. An diese Plugin-Klasse werden alle
(Haupt-)Abschnitts-Objekte delegiert, für die kein Plugin
definiert ist. Logischerweise kann es höchstens ein Universelles
Plugin geben. Für ein Universelles Plugin findet keine
Attribut-Validierung in der Basisklassenmethode create() statt.
Das Konzept ist in erster Linie für allgemeine Programme
wie z.B. Testprogramme gedacht.

=head2 Ausgaben

Der Umfang an Ausgaben wird mit der Konstruktor-Option
-verbosity=>$level eingestellt. Default ist 1.

Die Methode msg() schreibt eine Ausgabe nach STDERR. Der erste
Parameter gibt den Verbosity-Level an. Ist dieser größer als der
eingestellte Verbosity-Level, unterbleibt die Ausgabe.

    $cop->msg(2,$text);

Ist kein Level angegeben, erfolgt die Ausgabe I<immer>:

    $cop->msg($text);

Der Meldungstext $text kann printf-Formatelemente enthalten, diese
werden wie bei printf durch die zusätzlich angegebenen Argumente
ersetzt:

    $cop->msg($text,@args);

=head1 EXAMPLES

Füge alle Entitäts-Definitionen im Storage zu einem einzigen
Datenstrom zusammen und schreibe diesen nach STDOUT (z.B. für
Refactoring):

    $cop->load->fetch('-');

Übertrage alle Entitäts-Definitionen im Storage in Verzeichnis $dir
(das Verzeichnis hat die gleiche Struktur wie das Verzeichnis def
im Storage):

    $cop->load->fetch->($dir);

Liste alle Entitäten vom Typ $type auf:

    $cop->load;
    for my $ent ($cop->entities($type)) {
        $cop->msg($ent->name);
    }

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere ContentProcessor

=head4 Synopsis

    $cop = $class->new($storage,@opt);

=head4 Description

Instantiiere ein ContentProcessor-Objekt und liefere eine Referenz
auf dieses Objekt zurück.

=head4 Arguments

=over 4

=item $storage

Das Storage-Verzeichnis, z.B. '.storage'.

=back

=head4 Options

=over 4

=item -verbosity => 0|1|2 (Default: 1)

Umfang der Laufzeit-Meldungen.

=back

=head4 Returns

ContentProcessor-Objekt

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $storage = Prty::Path->expandTilde(shift);

    my $verbosity = 1;

    Prty::Option->extract(\@_,
        -verbosity=>\$verbosity,
    );

    # Objekt instantiieren

    my $self = $class->SUPER::new(
        t0=>scalar Time::HiRes::gettimeofday,
        verbosity=>$verbosity,
        storage=>$storage,
        pluginA=>[],
        fileA=>[],
        parsedSections=>0,
        parsedLines=>0,
        parsedChars=>0,
        parsedBytes=>0,
        # memoize
        entityA=>undef,
        entityTypeA=>undef,
        extensionRegex=>undef,
        needsUpdateDb=>undef,
        needsTestDb=>undef,
        typeH=>undef,
    );

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Sub-Abschnitte

=head3 processSubSection()

=head4 Synopsis

    $cop->processSubSection($mainEntity,$mainSection,$sec);

=head4 Returns

nichts

=cut

# -----------------------------------------------------------------------------

sub processSubSection {
    my ($self,$mainEntity,$mainSection,$sec) = @_;
    return;
}

# -----------------------------------------------------------------------------

=head2 Plugins

=head3 registerType() - Registriere Entitäts-Typ

=head4 Synopsis

    $cop->registerType($pluginClass,$extension,$entityType,$sectionType,@keyVal);
    $cop->registerType($pluginClass,$extension); # universelles Plugin

=head4 Description

Registriere Plugin-Klasse $pluginClass für Abschnitts-Objekte
des Typs $sectionType und den Eigenschaften @keyVal.

Entsprechende Dateien werden an der Extension $extension erkannt.
Als Typ-Bezeichner für Entitäten dieses Typs vereinbaren wir
$entityType.

Die Plugin-Klasse wird automatisch geladen, falls sie noch nicht
vorhanden ist (sie kann für Tests also auch "inline", d.h. im
Quelltext des rufenden Code, definiert werden).

Die Plugin-Definition wird intern auf einem Hash-Objekt
gespeichert, das vom ContentProcessor mit den instantiierten
Entitäten verbunden wird.

Es kann auch ein I<Universelles Plugin> definiert werden (siehe
Abschnitt L</"Universelles Plugin">).

=head4 Arguments

=over 4

=item $pluginClass

Name der Plugin-Klasse, z.B. 'Program::Shell'.

=item $extension

Datei-Erweiterung für Dateien dieses Typs, ohne Punkt, z.B. 'prg'.

=item $entityType

Entitätstyp-Bezeichner, z.B. 'Program' oder 'Class/Perl'.

=item $sectionType

Abschnitts-Bezeichner ohne Klammerung, z.B. 'Program'.

=item @keyVal

Abschnitts-Attribute, die über den Abschnitts-Bezeichner hinaus
den Dateityp kennzeichnen, z.B. Language=>'Shell'.

=back

=head4 Returns

nichts

=cut

# -----------------------------------------------------------------------------

sub registerType {
    my ($self,$pluginClass,$extension,$entityType,$sectionType,@keyVal) = @_;

    Prty::Perl->loadClass($pluginClass);
    push @{$self->{'pluginA'}},Prty::Hash->new(
        class=>$pluginClass,
        extension=>$extension,
        entityType=>$entityType,
        sectionType=>$sectionType,
        keyValA=>\@keyVal,
    );
        
    return;
}

# -----------------------------------------------------------------------------

=head2 Operationen

=head3 commit() - Übertrage Veränderungen in den Storage

=head4 Synopsis

    $cop = $cop->commit;

=head4 Description

Vergleiche den Quelltext jeder Entität gegen den Quelltext im
Storage und übertrage etwaige Änderungen dorthin. Geänderte
Entitäten werden in der in der Datenbank als geändert
gekennzeichnet.

=head4 Returns

ContentProcessor-Objekt (für Method-Chaining)

=cut

# -----------------------------------------------------------------------------

sub commit {
    my $self = shift;

    $self->msg(1,'%T ==commit==');

    # Gleiche Eingabedateien mit Storage-Dateien ab

    my $defDir = $self->storage('def');

    my $dt = Prty::DestinationTree->new($defDir,
        -quiet=>0,
        -language=>'en',
        -outHandle=>\*STDERR,
    );
    $dt->addDir($defDir);

    for my $ent (@{$self->entities}) {
        # Schreibe Entity-Quelltext-Datei ins def-Verzeichnis,
        # falls sie differiert oder nicht existiert
    
        $dt->addFile($ent->entityFile($defDir),$ent->fullSourceRef,
            -encoding=>'utf-8',
            -skipEmptyFiles=>1, # Sub-Entities übergehen
            -onUpdate=>sub {
                # Entität und alle Entitäten in der gleichen Datei
                # als geändert markieren

                $ent->needsUpdate(1);
                for my $sec ($ent->subSections) {
                    if ($sec->brackets eq '[]') {
                        $sec->needsUpdate(1);
                    }
                }
            },
        );
    }
    $self->needsUpdateDb->sync;

    # Lösche überzählige Storage-Dateien (nach Rückfrage)

    $dt->cleanup(1,$self->getRef('t0'));
    $dt->close;

    return $self;
}
    

# -----------------------------------------------------------------------------

=head3 fetch() - Erzeuge Verzeichnisstruktur mit Entitäts-Definitionen

=head4 Synopsis

    $cop = $cop->fetch($dir,$layout,@opt);

=head4 Description

Übertrage alle Entitäts-Definitionen in Verzeichnis $dir (oder
STDOUT, s.u.) gemäß Layout $layout. Per Differenzbildung wird
dabei ein konsistenter Stand hergestellt. Existiert Verzeichnis
$dir nicht, wird es angelegt. Andernfalls wird eine Rückfrage
gestellt, ob das Verzeichnis überschrieben werden soll (siehe
auch Option --overwrite).

Wird als Verzeichnis ein Bindestrich (-) angegeben, werden die
Entitäts-Definitionen nach STDOUT geschrieben.

Die Methode bezieht die zu schreibenden Dateien von der Methode
L</fetchFiles>(), an die der Parameter $layout weiter gereicht
wird. Die Methode kann in abgeleiteten Klassen überschrieben
werden, um andere Strukturen zu generieren.

=head4 Arguments

=over 4

=item $dir

Verzeichnis, in welches die Entitäts-Definitionen geschrieben
werden.

=item $layout

Bezeichnung für das Verzeichnis-Layout. Dieser Parameter wird von
fetchFiles() der Basisklasse nicht genutzt und ist daher hier
nicht dokumentiert. Siehe Dokumentation bei den Subklassen.

=back

=head4 Options

=over 4

=item -overwrite => $bool (Default: 0)

Stelle keine Rückfrage, wenn Verzeichnis $dir bereits existiert.

=back

=head4 Returns

ContentProcessor-Objekt (für Method-Chaining)

=cut

# -----------------------------------------------------------------------------

sub fetch {
    my ($self,$dir,$layout) = @_;

    $self->msg(1,'%T ==fetch==');

    # Optionen

    my $overwrite = 0;

    Prty::Option->extract(\@_,
        -overwrite=>\$overwrite,
    );

    if ($dir eq '-') {
        for my $e ($self->fetchFiles($layout)) {
            print ref $e->[1]? ${$e->[1]}: $e->[1];
        }
        return $self;
    }
    elsif (-d $dir && !$overwrite) {
        my $answ = Prty::Terminal->askUser(
            "Overwrite directory '$dir'?",
            -values=>'y/n',
            -default=>'y',
            -outHandle=>\*STDERR,
            -timer=>$self->getRef('t0'),
        );
        if ($answ ne 'y') {
            return $self;
        }
    }
    
    my $dt = Prty::DestinationTree->new($dir,
        -quiet=>0,
        -language=>'en',
        -outHandle=>\*STDERR,
    );
    $dt->addDir($dir);

    for my $e ($self->fetchFiles($layout)) {
        $dt->addFile("$dir/$e->[0]",$e->[1],
            -encoding=>'utf-8',
            -skipEmptyFiles=>1, # Sub-Entities übergehen (z.B. ProgramClass)
        );
    }

    # Lösche überzählige Storage-Dateien (nach Rückfrage)

    $dt->cleanup(1,$self->getRef('t0'));
    $dt->close;

    return $self;
}
    

# -----------------------------------------------------------------------------

=head3 init() - Erzeuge Storage

=head4 Synopsis

    $cop = $cop->init;

=head4 Description

Erzeuge den Storage, falls er nicht existiert. Existiert er bereits,
hat der Aufruf keinen Effekt.

=head4 Returns

ContentProcessor-Objekt (für Method-Chaining)

=cut

# -----------------------------------------------------------------------------

sub init {
    my $self = shift;

    $self->msg(1,'%T ==init');

    my $storage = $self->storage;
    if (!-e $storage) {
        for ('','/db','/def','/pure') {
            my $dir = "$storage$_";
            Prty::Path->mkdir($dir);
            $self->msg(1,"$dir -- directory created");
        }
    }
    
    return $self;
}
    

# -----------------------------------------------------------------------------

=head3 load() - Lade Entitäts-Definitionen

=head4 Synopsis

    $cop = $cop->load;
    $cop = $cop->load(@paths);

=head4 Description

Lade die Entitäts-Dateien der Pfade @paths. Ist @path leer, also
kein Path angegeben, werden die Entitäts-Dateien aus dem Storage
geladen.

Die Methode kann beliebig oft aufgerufen werden, aber nur der
erste Aufruf lädt die Dateien. Alle weiteren Aufrufe sind
Null-Operationen.

=head4 Arguments

=over 4

=item @paths

Liste der Verzeichnisse und Dateien. Pfad '-' bedeutet STDIN.

=back

=head4 Returns

ContentProcessor-Objekt (für Method-Chaining)

=cut

# -----------------------------------------------------------------------------

sub load {
    my ($self,@paths) = @_;

    $self->memoize('entityA',sub {
        # Prüfen, ob Storage-Verzeichnis existert

        my $storage = $self->storage;
        if (!-d $storage) {
            die "ERROR: Directory '$storage' does not exist\n";
        }
    
        $self->msg(1,'%T ==find==');

        if (!@paths) {
            # Per Default laden wir die Dateien aus dem Storage
            push @paths,$self->storage('def');
        }

        # Ermittele die zu verarbeitenden Dateien

        my @files;
        for my $path (@paths) {
            push @files,-d $path? $self->findFiles($path): $path;
        }

        my $n = scalar @files;
        if ($n > 1) {
            $self->msg(2,'Files: %N',$n);
        }

        $self->msg(1,'%T ==parse==');

        # Instantiiere Parser

        my $par = Prty::Section::Parser->new(
            encoding=>'utf-8',
        );

        # Parse Dateien zu Entitäten

        my (@entities,$mainEntity,$mainSection);
        for my $file (@files) {
            $par->parse($file,sub {
                my $sec = Prty::Section::Object->new(@_);
                # $sec->removeEofMarker;

                my $brackets = $sec->brackets;
                if ($brackets eq '[]') {
                    $mainEntity = $mainSection = $sec;
                }
                elsif ($brackets eq '()') {
                    $mainSection = $sec;
                }
    
                while (1) {
                    if ($sec->brackets eq '[]') {
                        # Wandele Abschnitts-Objekt in Entität

                        my $plg = $self->plugin($sec);
                        if (!$plg) {
                            # Fehler: Für jeden Haupt-Abschnitt muss ein
                            # Plugin definiert worden sein

                            $sec->error(
                                q{COP-00001: Missing plugin for section},
                                 Section=>$sec->fullType,
                            );
                        }
                        push @entities,$plg->class->create($sec,$self,$plg);
                    }
                    elsif (@entities) {
                        # Verarbeite nächsten Sub-Abschnitt

                        $mainEntity->addSubSection($sec);
                        $self->processSubSection($mainEntity,
                            $mainSection,$sec);
                        if ($sec->brackets eq '[]') {
                            # Sub-Abschnitt als Entität verarbeiten
                            # (Beispiel: ProgramClass => Class)
                            redo;
                        }
                    }
                    else {
                        # Fehler: Erster Abschnitt ist kein []-Abschnitt

                        $sec->error(
                            q{COP-00002: First section must be a []-section},
                             Section=>$sec->fullType,
                        );
                    }
                    last;
                }
    
                # Abschnittsobjekt gegen unabsichtliche Erweiterungen sperren
                $sec->lockKeys;

                return;
            });
        }

        # Statistische Daten sichern

        $self->set(parsedSections=>$par->get('parsedSections'));
        $self->set(parsedLines=>$par->get('parsedLines'));
        $self->set(parsedChars=>$par->get('parsedChars'));
        $self->set(parsedBytes=>$par->get('parsedBytes'));

        return \@entities;
    });
    
    return $self;
}

# -----------------------------------------------------------------------------

=head2 Entitäten

=head3 entities() - Liefere Menge von Entities

=head4 Synopsis

    @entities | $entityA = $cop->entities;
    @entities | $entityA = $cop->entities($type);

=head4 Description

Liefere die Liste aller geladenen Entities oder aller
geladenen Entities vom Typ $type. Bei der Abfrage der Entities
eines Typs werden die Entities nach Name sortiert geliefert.

=head4 Arguments

=over 4

=item $type

Abschnitts-Typ.

=back

=head4 Returns

Liste von Entitäten. Im Skalarkontext eine Referenz auf die Liste.

=cut

# -----------------------------------------------------------------------------

sub entities {
    my ($self,$type) = @_;

    if (!$type) {
        my $entityA = $self->{'entityA'};
        return wantarray? @$entityA: $entityA;
    }

    my $h = $self->memoize('typeH',sub {
        my ($self,$key) = @_;

        my $typeA = $self->entityTypes;
    
        # Hash mit allen Abschnittstypen aufbauen
    
        my %h;
        for my $type (@$typeA) {
            $h{$type} ||= [];
        }

        # Entitäten zuordnen
    
        for my $ent (@{$self->{'entityA'}}) {
            push @{$h{$ent->entityType}},$ent;
        }

        # Entitäten nach Name sortieren
    
        for my $type (@$typeA) {
            @{$h{$type}} = sort {$a->name cmp $b->name} @{$h{$type}};
        }

        return \%h;
    });

    my $a = $h->{$type} || $self->throw(
        q{COP-00000: Unknown type},
        Type=>$type,
    );    
    return wantarray? @$a: $a;
}

# -----------------------------------------------------------------------------

=head2 Dateien

=head3 fetchFiles() - Liste der Dateien für fetch

=head4 Synopsis

    @files = $cop->fetchFiles;
    @files = $cop->fetchFiles($layout);

=head4 Description

Liefere die Liste der Dateien, die von der Methode L</fetch>()
geschrieben werden. Jede Datei wird durch ein zweielementiges
Array repräsentiert, bestehend aus einem Datei-Pfad sowie dem
Datei-Inhalt. Der Datei-Inhalt kann als String oder
String-Referenz angegeben sein.

Diese (Basisklassen-)Methode liefert für jede Entität die
Datei-Definiton

    [$ent->entityFile, $ent->sourceRef]

Damit erzeugt die Methode fetch() die gleiche Struktur wie
der ContentProcessor im Storage-Verzeichnis def.

Die Methode kann in abgeleiteten Klassen überschrieben werden, um
die Verzeichnisstruktur zu ändern und/oder den Inhalt der Dateien
anders zusammenzustellen (z.B. mehrere Entity-Definitionen in
einer Datei zusammenzufassen). In abgeleiteten Klassen können
verschiedene Layouts durch das Argument $layout
unterschieden werden.

=head4 Arguments

=over 4

=item $layout

Bezeichner für eine bestimmte Abfolge und/oder Inhalt der Dateien.

=back

=head4 Returns

Array mit zweielementigen Arrays

=cut

# -----------------------------------------------------------------------------

sub fetchFiles {
    my ($self,$layout) = @_;

    my @files;
    for my $ent (@{$self->entities}) {
        push @files,[$ent->entityFile,$ent->fullSourceRef];
    }
    
    return @files;
}

# -----------------------------------------------------------------------------

=head2 Statistik

=head3 info() - Informationszeile

=head4 Synopsis

    $str = $cop->info;

=head4 Description

Liefere eine Informationszeile mit statistischen Informationen, die
am Ende der Verarbeitung ausgegeben werden kann.

=head4 Returns

Zeichenkette

=cut

# -----------------------------------------------------------------------------

sub info {
    my $self = shift;

    my $entityA = $self->get('entityA');
    my $entityCount = $entityA? @$entityA: 0;
    
    return sprintf '%.3f sec; Entities: %s; Sections: %s; Lines: %s'.
            '; Bytes: %s; Chars: %s',
        Time::HiRes::gettimeofday-$self->get('t0'),
        Prty::Formatter->readableNumber($entityCount,','),
        Prty::Formatter->readableNumber($self->get('parsedSections'),','),
        Prty::Formatter->readableNumber($self->get('parsedLines'),','),
        Prty::Formatter->readableNumber($self->get('parsedBytes'),','),
        Prty::Formatter->readableNumber($self->get('parsedChars'),',');
}

# -----------------------------------------------------------------------------

=head2 Intern

=head3 entityTypes() - Liste der Abschnitts-Typen

=head4 Synopsis

    @types | $typeA = $cop->entityTypes;

=head4 Description

Liefere die Liste der Abschnitts-Typen (Bezeichner), die per
registerType() registriert wurden.

=head4 Returns

Liste von Abschnitts-Typen. Im Skalarkontext eine Referenz auf die
Liste.

=cut

# -----------------------------------------------------------------------------

sub entityTypes {
    my $self = shift;

    my $a = $self->memoize('entityTypeA',sub {
        my ($self,$key) = @_;

        my %h;
        for my $plg (@{$self->{'pluginA'}}) {
            $h{$plg->entityType}++;
        }

        return [sort keys %h];
    });

    return wantarray? @$a: $a;
}

# -----------------------------------------------------------------------------

=head3 extensionRegex() - Regex zum Auffinden von Eingabe-Dateien

=head4 Synopsis

    $regex = $cop->extensionRegex;

=head4 Description

Liefere den regulären Ausdruck, der die Dateinamen matcht, die vom
ContentProcessor verarbeitet werden. Der Regex wird genutzt, wenn
ein I<Verzeichnis> nach Eingabe-Dateien durchsucht wird.

=head4 Returns

Kompilierter Regex

=cut

# -----------------------------------------------------------------------------

sub extensionRegex {
    my $self = shift;

    return $self->memoize('extensionRegex',sub {
        my ($self,$key) = @_;
        
        # Dateinamen-Erweiterungen ermitteln. Verschiedene
        # Plugin-Klassen können identische Datei-Erweiterungen haben,
        # deswegen filtern wir über einen Hash.

        my %extension;
        for my $plg (@{$self->{'pluginA'}}) { # Plugin-Extensions
            $extension{$plg->extension}++;
        }        

        # Regex erstellen

        my $regex;
        for (sort keys %extension) {
            my $ext = $_;
            if ($regex) {
                $regex .= '|';
            }
            $regex .= $ext;
        }

        return qr/\.($regex)$/;
    });
}

# -----------------------------------------------------------------------------

=head3 findFiles() - Finde Entitäts-Dateien in Verzeichnis

=head4 Synopsis

    @files | $fileA = $cop->findFiles($dir);

=head4 Description

Durchsuche Verzeichnis $dir nach Entitäts-Dateien unter Verwendung
des Regex, der von L</extensionRegex>() geliefert wird.

=head4 Arguments

=over 4

=item $dir

Das Verzeichnis, das nach Dateien durchsucht wird.

=back

=head4 Returns

Liste der Datei-Pfade (Strings). Im Skalarkontext eine Referenz
auf die Liste.

=cut

# -----------------------------------------------------------------------------

sub findFiles {
    my ($self,$dir) = @_;

    my @files = Prty::Path->find($dir,
        -type=>'f',
        -pattern=>$self->extensionRegex,
        -sloppy=>1,
    );
    
    return wantarray? @files: \@files;
}

# -----------------------------------------------------------------------------

=head3 msg() - Gib Information aus

=head4 Synopsis

    $cop->msg($text,@args);
    $cop->msg($level,$text,@args);

=head4 Description

Gib Information $text auf STDERR aus, wenn $level kleinergleich
dem beim Konstruktor vorgebenen Verbosity-Level ist. Der Text kann
printf-Platzhalter enthalten, die durch die Argumente @args
ersetzt werden.

Zusätzlich wird der Platzhalter %T durch die aktuelle Ausführungsdauer
in Sekunden ersetzt.

=head4 Arguments

=over 4

=item $level

Der Verbosity-Level, ab dem die Information ausgegeben wird.

=item $text

Text, der ausgegeben werden soll.

=item @args

Argumente, die für printf-Platzhalter in $text eingesetzt werden.

=back

=head4 Returns

nichts

=cut

# -----------------------------------------------------------------------------

sub msg {
    my $self = shift;
    # @_: $level,$text,@args -or- $text,@args

    if ($_[0] =~ /^(\d+)$/ && shift > $self->{'verbosity'}) {
        # Keine Ausgabe, wenn der Meldungslevel höher ist
        # als der vorgegebene Verbosity-Level.
        return;
    }
    my $text = shift;
        
    $text =~ s/%T/sprintf '%.3f',
        Time::HiRes::gettimeofday-$self->get('t0')/e;

    $text =~ s/%N/Prty::Formatter->readableNumber(shift,',')/eg;

    printf STDERR "$text\n",@_;

    return;
}

# -----------------------------------------------------------------------------

=head3 plugin() - Ermittele Plugin zu Abschnitts-Objekt

=head4 Synopsis

    $plg = $cop->plugin($sec);

=head4 Description

Ermittele das Plugin zu Abschnitts-Objekt $sec. Existiert
kein Plugin zu dem Abschnitts-Objekt, liefere C<undef>.

=head4 Arguments

=over 4

=item $sec

Abschnitts-Objekt

=back

=head4 Returns

Plugin-Objekt

=cut

# -----------------------------------------------------------------------------

my %Plugins; # Section-Type => Liste der Plugins
my $Plugin;  # Universelles Plugin (es sollte höchstens eins definiert sein)
    
sub plugin {
    my ($self,$sec) = @_;

    if (!%Plugins) {
        # Indiziere Plugins nach Section-Type

        for my $plg (@{$self->{'pluginA'}}) {
            if (my $type = $plg->sectionType) {
                # Normales Plugin
                push @{$Plugins{$type}},$plg;
            }
            else {
                # Universelles Plugin
                $Plugin = $plg;
            }
        }
    }
        
    # Prüfe Section gemäß Plugin-Kriterien

    if (my $pluginA = $Plugins{$sec->type}) {
        for my $plg (@$pluginA) {
            my $ok = 1;
            my $a = $plg->keyValA;
            for (my $i = 0; $i < @$a; $i += 2) {
                if ($sec->get($a->[$i]) ne $a->[$i+1]) {
                    $ok = 0;
                    last;
                }
            }
            if ($ok) {
                return $plg;
            }
        }
    }
    
    # Kein Plugin zum SectionType gefunden. Wir liefern das
    # universelle Plugin, sofern existent, oder undef

    return $Plugin? $Plugin: undef;
}

# -----------------------------------------------------------------------------

=head3 needsTestDb() - Persistenter Hash für Test-Status

=head4 Synopsis

    $h = $cop->needsTestDb;

=head4 Description

Liefere eine Referenz auf den persistenten Hash, der den Status
von Entitäten speichert.

=head4 Returns

Hash-Referenz (persistenter Hash)

=cut

# -----------------------------------------------------------------------------

sub needsTestDb {
    my $self = shift;

    return $self->memoize('needsTestDb',sub {
        my ($self,$key) = @_;
        
        my $file = $self->storage('db/entity-needsTest.db');
        return Prty::PersistentHash->new($file,'rw');
    });
}

# -----------------------------------------------------------------------------

=head3 needsUpdateDb() - Persistenter Hash für Entitäts-Status

=head4 Synopsis

    $h = $cop->needsUpdateDb;

=head4 Description

Liefere eine Referenz auf den persistenten Hash, der den Status
von Entitäten speichert.

=head4 Returns

Hash-Referenz (persistenter Hash)

=cut

# -----------------------------------------------------------------------------

sub needsUpdateDb {
    my $self = shift;

    return $self->memoize('needsUpdateDb',sub {
        my ($self,$key) = @_;
        
        my $file = $self->storage('db/entity-needsUpdate.db');
        return Prty::PersistentHash->new($file,'rw');
    });
}

# -----------------------------------------------------------------------------

=head3 storage() - Pfad zum oder innerhalb des Storage

=head4 Synopsis

    $path = $cop->storage;
    $path = $cop->storage($subPath);

=head4 Description

Liefere den Pfad des Storage, ggf. ergänzt um den Sub-Pfad
$subPath.

=head4 Arguments

=over 4

=item $subPath

Ein Sub-Pfad innerhalb des Storage.

=back

=head4 Returns

Pfad

=cut

# -----------------------------------------------------------------------------

sub storage {
    my $self = shift;
    # @_: $subPath

    my $path = $self->{'storage'};
    if (@_) {
        $path .= '/'.shift;
    }

    return $path;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.106

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2017 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
