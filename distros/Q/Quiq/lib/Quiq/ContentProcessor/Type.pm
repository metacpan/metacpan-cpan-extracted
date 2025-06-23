# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::ContentProcessor::Type - Entität, Basisklasse aller Plugin-Klassen

=head1 BASE CLASS

L<Quiq::ContentProcessor::BaseType>

=head1 DESCRIPTION

Diese Klasse ist die Basisklasse für alle Plugin-Klassen, die
im ContentProcessor mit registerType() definiert werden.

=head2 Definition von Subklassen

Die Plugin-Klassen bilden eine Hierarchie von Klassen, an deren
Spitze eine allgemeine, abstrakte Klasse steht (stehen sollte),
die von der dieser Klasse abgeleitet ist:

  package Jaz::Type;
  use base qw/Quiq::ContentProcessor::Type/;
  
  __PACKAGE__->def(
      ContentAllowed => 0,
      Attributes => [qw/
          Name
      /],
  );

Ob der Abschnitt eines Typs einen Inhalt zulässt und welches die
zulässigen Attribute sind, wird mit den Klassen-Attributen
C<ContentAllowed> und C<Attributes> festgelegt. Obige
Basisklassen-Definition vereinbart, dass I<per Default> kein
Content erlaubt ist und dass das Attribut C<Name> bei
I<allen> (Haupt-)Typen vorkommt.

Die abgeleiteten Klassen ergänzen die Attribut-Liste und
überschreiben u.U. das C<ContentAllowed>-Attribut.

Die Methode L<create|"create() - Erzeuge Entität">()  erzeugt aus einem Abschnitts-Objekt eine
Instanz des betreffenden Typs, eine sog. Entität, und setzt die
für den ContentProcessor essentiellen Attribute (siehe Code der
Methode). Die Methode wird in der Typ-Klasse überschrieben und von
dort aus gerufen:

  package Jaz::Type::Program::Shell;
  use base qw/Jaz::Type::Program/;
  
  __PACKAGE__->def(
      Attributes => [qw/
          <Spezifische Attribute des Typs>
      /],
  );
  
  sub create {
      my ($class,$sec,$cop,$plg) = @_;
  
      return $class->SUPER::create($sec,$cop,$plg,
          <Eigenschaften der Entität>
      );
  }

=head2 Standard-Attribute

Die Basisklassenmethode erweitert das Objekt um grundlegende
Informationen und Verküpfungen:

=over 4

=item processor

Referenz auf die Processor-Instanz. Diese gibt der Entität u.a.
Zugriff auf alle anderen Entitäten.

=item plugin

Referenz auf die Plugin-Definition. Diese wird von der Methode
entityId() herangezogen um die Entity-Id zu generieren.

=item fileSource

Der gesamte Quelltext der Entität, wenn es sich um eine
Datei-Entität [] handelt. Bei Sub-Entitäten () ein Leerstring.

=item testable

Attribut, das anzeigt, ob die Entität Programmcode repräsentiert
und im Änderungsfall getestet werden kann.

=back

=head2 Methoden

Ferner implementiert die Basisklasse folgende Methoden, die
überschrieben werden können:

=over 4

=item entityId()

Liefert den eindeutigen Entitätsbezeichner. Die Basisklassenmethode
setzt diesen aus dem Typ-Bezeichner und den Werten der
@keyVal-Liste des Plugins zusammen. Kann überschrieben werden,
wenn der Entitätsbezeichner anders gebildet werden soll.

=item name()

Liefert den Namen der Entität. Die Basisklassenmethode erzeugt
diesen durch geringfügige Änderungen aus dem Wert des
Abschnitts-Attributs C<Name:>. Kann überschrieben werden,
wenn der Name anders hergeleitet werden soll.

=back

Oder überschrieben werden müssen:

=over 4

=item files()

Liefert die Liste aller Ausgabe-Datei-Objekte der Entität. Die
Basisklassenmethode liefert eine leere Liste. Die Methode wird
überschrieben.

=item pureCode()

Liefert bei einer testbaren Entität (s. Attribut C<testable>)
den Quelltext ohne Inline-Doku und Kommentare. Besteht der
Quelltext aus mehreren Dateien (z.B. im Falle von C++),
werden diese konkateniert geliefert, denn der Code muss nicht
kompilierbar/ausführbar sein. Die Basisklassenmethode liefert
C<undef>. Die Methode wird überschrieben.

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::ContentProcessor::Type;
use base qw/Quiq::ContentProcessor::BaseType/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Erzeugung

=head3 create() - Erzeuge Entität

=head4 Synopsis

  $ent = $class->create($sec,$cop,$plg,@keyVal);

=head4 Arguments

=over 4

=item $sec

Referenz auf Abschnitts-Objekt.

=item $cop

Referenz auf ContentProcessor-Objekt.

=item $plg

Referenz auf Plugin-Definition.

=item @keyVal

Attribute, die der Entität hinzugefügt werden.

=back

=head4 Returns

Zur Entität geblesstes Abschnitts-Objekt.

=head4 Description

Erweitere Abschnitts-Objekt $sec und blesse es zu einer Entität.

=cut

# -----------------------------------------------------------------------------

sub create {
    my ($class,$sec,$cop,$plg) = splice @_,0,4;
    # @_: @keyVal

    # Wenn das Plugin keinen SectionType hat (Universelles Plugin),
    # sind keine Section-Attribute vorgegeben.
    
    if ($plg->sectionType) {
        # Inhalt und Abschnitts-Attribute prüfen
        $sec->validate($class->contentAllowed,scalar $class->attributes);
    }
        
    $sec->set(
        processor => $cop,
        plugin => $plg,
        fileSource => '',
        testable => 0,
        # memoize
        name => undef,
        entityId => undef,
        entityFile => undef,
        entityType => undef,
        # Subklassen-Attribute
        @_,
    );
    $sec->weaken('processor');
    $sec->weaken('plugin');
    
    return bless $sec,$class;
}

# -----------------------------------------------------------------------------

=head2 Entität

=head3 entityId() - Eindeutiger Entitätsbezeichner

=head4 Synopsis

  $entityId = $ent->entityId;

=head4 Description

Liefere einen eindeutigen Bezeichner für die Entität.

=cut

# -----------------------------------------------------------------------------

sub entityId {
    my $self = shift;

    return $self->memoize('entityId',sub {
        my ($self,$key) = @_;

        # Abschnittytyp, z.B. 'Class'
        my $entityId = $self->type;

        # Abschnittskriterien, z.B. 'Perl' von Language=>'Perl'
    
        my $a = $self->plugin->keyValA;
        for (my $i = 0; $i < @$a; $i += 2) {
            $entityId .= '/'.$a->[$i+1];
        }

        # Entitäts-Name (Pflichtangabe)
        $entityId .= '/'.$self->name;

        return $entityId;
    });
}

# -----------------------------------------------------------------------------

=head3 entityType() - Entitäts-Typ

=head4 Synopsis

  $entityType = $ent->entityType;

=head4 Returns

Entitäts-Typ (String)

=head4 Description

Liefere den Typ der Entität, wie er bei der bei der Registrierung
der Entitäts-Klasse angegeben wurde.

=cut

# -----------------------------------------------------------------------------

sub entityType {
    my $self = shift;

    return $self->memoize('entityType',sub {
        my ($self,$key) = @_;
        return $self->plugin->entityType;
    });
}

# -----------------------------------------------------------------------------

=head3 name() - Name der Entität

=head4 Synopsis

  $name = $ent->name;

=head4 Description

Liefere den Namen der Entität. Dies ist der Wert
des Attributs C<Name:>, bereinigt um Besonderheiten:

=over 2

=item *

ein Sigil am Namensanfang (z.B. C<@@>) wird entfernt

=item *

Gleichheitszeichen (C<=>) innerhalb des Namens (z.B. bei Klassen)
werden durch einen Slash (C</>) ersetzt

=back

=cut

# -----------------------------------------------------------------------------

sub name {
    my $self = shift;

    return $self->memoize('name',sub {
        my ($self,$key) = @_;
        
        my ($name) = $self->get('Name');
        if (!$name) {
            $self->throw;
        }
        $name =~ s/^\W+//; # Sigil entfernen
        $name =~ s|=|/|g;

        return $name;
    });
}

# -----------------------------------------------------------------------------

=head3 entityFile() - Name/Pfad der Entitätsdatei

=head4 Synopsis

  $file = $ent->entityFile;
  $file = $ent->entityFile($dir);

=head4 Arguments

=over 4

=item $dir

Verzeichnis, in dem sich die Datei befindet oder in das sie
geschrieben wird.

=back

=head4 Returns

Dateiname

=head4 Description

Liefere den Dateinamen der Entität. Dieser besteht aus der
Entity-Id und der Entity-Extension. Wenn angegeben, wird diesem
Dateinamen der Pfad $dir vorangestellt.

=cut

# -----------------------------------------------------------------------------

sub entityFile {
    my ($self,$dir) = @_;

    my $file = $self->memoize('entityFile',sub {
        my ($self,$key) = @_;
        return sprintf '%s.%s',$self->entityId,$self->plugin->extension;
    });

    if ($dir) {
        $file = sprintf '%s/%s',$dir,$file;
    }

    return $file;
}

# -----------------------------------------------------------------------------

=head2 Quelltext

=head3 fileSource() - Gesamter Quelltext

=head4 Synopsis

  $source = $ent->fileSource;

=head4 Returns

Quelltext (String)

=head4 Description

Liefere den gesamten Quelltext der Entität, wie er in der
Enttitätsdatei steht, einschließlich des Quelltexts der
Sub-Entitäten.

=cut

# -----------------------------------------------------------------------------

sub fileSource {
    return shift->get('fileSource');
}

# -----------------------------------------------------------------------------

=head3 fileSourceRef() - Referenz auf gesamten Quelltext

=head4 Synopsis

  $sourceR = $ent->fileSourceRef;

=head4 Returns

Referenz auf Quelltext

=head4 Description

Wie $ent->L<fileSource|"fileSource">(), nur dass eine Referenz auf den
Quelltext geliefert wird.

=cut

# -----------------------------------------------------------------------------

sub fileSourceRef {
    return shift->getRef('fileSource');
}

# -----------------------------------------------------------------------------

=head3 appendFileSource() - Ergänze Quelltext um Abschnitts-Quelltext

=head4 Synopsis

  $ent->appendFileSource($sec);

=head4 Returns

nichts

=head4 Description

Ergänze Attribut fileSource um den Quelltext des Abschnitts $sec.

=cut

# -----------------------------------------------------------------------------

sub appendFileSource {
    my ($self,$sec) = @_;
    $self->append(fileSource=>$sec->source);
    return;
}

# -----------------------------------------------------------------------------

=head2 Test

=head3 pureCode() - Quelltext ohne Kommentare und Inline-Doku (abstrakt)

=head4 Synopsis

  $str = $ent->pureCode;

=cut

# -----------------------------------------------------------------------------

sub pureCode {
    my $self = shift;
    return;
}

# -----------------------------------------------------------------------------

=head2 Interne Methoden

=head3 needsTest() - Liefere/Setze persistenten Test-Status

=head4 Synopsis

  $needsTest = $ent->needsTest;
  $needsTest = $ent->needsTest($state);

=head4 Arguments

=over 4

=item $state

Test-Status, der gesetzt wird.

=back

=head4 Returns

Test-Status der Entität

=head4 Description

Liefere/Setze den Test-Status der Entität $ent. Der
Test-Status ist persistent und bleibt daher über
Programmaufrufe hinweg erhalten.

Eine Entität besitzt einen von drei Test-Status:

=over 4

=item Z<>0

Nichts zu tun. Die Entität braucht nicht getestet werden.

=item Z<>1

Der Code der Entität hat sich geändert. Die Entität und alle
abhängigen Entitäten müssen getestet werden.

=item Z<>2

Nur die Entität selbst muss getestet werden. Die Entität
selbst wurde nicht geändert, hängt aber von einer Entität ab,
die geändert wurde, oder ihre Testdateien oder Testdaten
wurden geändert, was keinen Test der abhängigen Entitäten
erfordert.

=back

Ohne Parameter aufgerufen, liefert die Methode den aktuellen
Test-Status der Entität. Mit Parameter gerufen, setzt die Methode
den Test-Status, wobei dieser persistent gespeichert wird.

=cut

# -----------------------------------------------------------------------------

sub needsTest {
    my $self = shift;
    # @_: $state

    my $h = $self->processor->needsTestDb;
    my $entityId = $self->entityId;

    if (@_) {
        my $state = shift;
        $h->set($entityId=>$state);
        return $state;
    }

    return $h->get($entityId);
}

# -----------------------------------------------------------------------------

=head3 needsUpdate() - Liefere/Setze persistenten Änderungs-Status

=head4 Synopsis

  $needsUpdate = $ent->needsUpdate;
  $needsUpdate = $ent->needsUpdate($state);

=head4 Arguments

=over 4

=item $state

Änderungs-Status, der gesetzt wird.

=back

=head4 Returns

Änderungs-Status der Entität

=head4 Description

Liefere/Setze den Änderungs-Status der Entität $ent. Der
Änderungs-Status ist persistent und bleibt daher über
Programmaufrufe hinweg erhalten.

Eine Entität besitzt einen von zwei Änderungs-Status:

=over 4

=item Z<>0

Nichts zu tun. Die Entität wurde nicht geändert.

=item Z<>1

Die Entitäts wurde geändert. Die Ausgabe-Dateien der
Entität müssen neu generiert werden.

=back

Ohne Parameter aufgerufen, liefert die Methode den aktuellen
Änderungs-Status der Entität. Mit Parameter gerufen, setzt die
Methode den Änderungs-Status, wobei dieser persistent gespeichert
wird.

=cut

# -----------------------------------------------------------------------------

sub needsUpdate {
    my $self = shift;
    # @_: $state

    my $h = $self->processor->needsUpdateDb;
    my $entityId = $self->entityId;

    if (@_) {
        my $state = shift;
        $h->set($entityId=>$state);
        return $state;
    }

    return $h->get($entityId);
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
