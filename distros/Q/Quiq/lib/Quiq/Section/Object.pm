package Quiq::Section::Object;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.149';

use Quiq::Path;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Section::Object - Abschnitts-Objekt

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen "Abschnitt". Abschnitte werden
von C<< Quiq::Section::Parser >> geparst und instantiiert.

Ein Abschnittsobjekt gibt Auskunft über den Inhalt des Abschnitts
und dessen "Ort" (Dateiname und Zeilennummer). Das Objekt ist readonly,
d.h. die Objekteigenschaften können gelesen aber nicht gesetzt werden.

Abschnittsobjekte können in einer hierarchischen Beziehung stehen.
Ein Abschnitts-Objekt kann Unter-Abschnitte haben.

=head1 ATTRIBUTES

=over 4

=item [0] type

Abschnitts-Bezeichner.

=item [1] brackets

Klammerung des Abschnittsbezeichners.

=item [2] keyA

Liste der Schlüssel.

=item [3] keyValH

Attribut-Hash.

=item [4] content

Inhalt des Abschnitts.

=item [5] source

Quelltext des Abschnitts.

=item [6] file

Name der Quelldatei.

=item [7] line

Zeilennummer in Quelldatei.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $sec = $class->new($type,$keyValH);
    $sec = $class->new($type,$keyValH,$keyA,$content,$source,$file,$line);

=head4 Arguments

=over 4

=item $type

Abschnitts-Typ einschließlich Klammern (sofern vorhanden).

=item $keyValH

Referenz auf Schlüssel/Wert-Hash.

=item $keyA

Referenz auf Schlüssel-Array.

=item $content

Inhalt.

=item $source

Quelltext des Abschnitts.

=item $file

Name der Datei, die den Abschnitt enthält. Im Falle von STDIN ist
ist der Dateiname "-", im Falle einer In-Memory-Datei ist der
Dateiname "C<(source)>".

=item $line

Zeilennummer, an der der Abschnitt in der Datei beginnt.

=back

=head4 Returns

Referenz auf Abschnitts-Objekt

=head4 Description

Instantiiere ein Abschnittsobjekt und liefere eine Referenz
auf das Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$type,$keyValH,$keyA,$content,$source,$file,$line) = @_;

    # Abschnittsbezeichner in eigentlichen Bezeichner und
    # Klammerung zerlegen

    my $brackets = '';
    if ($type =~ /^(\W)(\w+)(\W)$/) {
        $type = $2;
        $brackets = "$1$3";
    }

    if (!defined $keyA) {
        $keyA = [keys %$keyValH];
    }

    if (!defined $content) {
        $content = '';
    }
    if (!defined $source) {
        $source = '';
    }
    if (!defined $file) {
        $file = '(internal)';
    }
    if (!defined $line) {
        $line = 0;
    }

    # Objekt instantiieren

    return bless [
        $type,     # [0]
        $brackets, # [1]
        $keyA,     # [2]
        $keyValH,  # [3]
        $content,  # [4]
        $source,   # [5]
        $file,     # [6]
        $line,     # [7]
    ],$class;
}

# -----------------------------------------------------------------------------

=head2 Abschnittsinformation

=head3 type() - Liefere/Setze Abschnittsbezeichner

=head4 Synopsis

    $type = $sec->type;
    $type = $sec->type($type);

=head4 Returns

Abschnittsbezeichner (String)

=head4 Description

Liefere den Abschnittsbezeichner. Ist Parameter $type angegeben, setze
den Abschnittsbezeichner auf diesen Wert.

=cut

# -----------------------------------------------------------------------------

sub type {
    my $self = shift;
    # @_: $type

    if (@_) {
        $self->[0] = shift;
    }
    
    return $self->[0];
}

# -----------------------------------------------------------------------------

=head3 brackets() - Liefere/setze Klammerung

=head4 Synopsis

    $brackets = $sec->brackets;
    $brackets = $sec->brackets($brackets);

=head4 Returns

Klammerpaar (String)

=head4 Description

Liefere die Klammerung um den Abschnittsbezeichner, sofern vorhanden.
Ist der Abschnittsbezeichner nicht geklammert, liefere einen Leerstring.
Ist Parameter $brackets angegeben, setze die Klammerung auf diesen Wert.

=head4 Details

Die Klamerung um den Abschnitts-Bezeichner ist optional.
Sie besteht aus der öffnenden und schließenden Klammer,
ist also "[]", "<>" oder "()" oder "{}".

=cut

# -----------------------------------------------------------------------------

sub brackets {
    my $self = shift;
    # @_: $brackets

    if (@_) {
        $self->[1] = shift;
    }
    
    return $self->[1];
}

# -----------------------------------------------------------------------------

=head3 fullType() - Liefere Abschnittsbezeichner mit Klammerung

=head4 Synopsis

    $fullType = $sec->fullType;

=head4 Description

Liefere den vollständigen Abschnittsbezeichner einschließlich
der Klammern.

=cut

# -----------------------------------------------------------------------------

sub fullType {
    my $self = shift;
    return substr($self->[1],0,1).$self->[0].substr($self->[1],1,1);
}

# -----------------------------------------------------------------------------

=head3 keys() - Liefere die Liste der Schlüssel

=head4 Synopsis

    $keyA|@keys = $sec->keys;

=head4 Description

Liefere die Liste der Schlüssel. Im Skalarkontext liefere eine
Referenz auf die Liste.

=cut

# -----------------------------------------------------------------------------

sub keys {
    my $self = shift;
    return wantarray? @{$self->[2]}: $self->[2];
}

# -----------------------------------------------------------------------------

=head3 keyValHash() - Liefere den Attributhash

=head4 Synopsis

    $hash|@arr = $sec->keyValHash;

=head4 Returns

Im Sklarkontext liefere eine Referenz auf den Attribut-Hash.
Im Arraykontext liefere die Liste der Attribut/Wert-Paare.

=cut

# -----------------------------------------------------------------------------

sub keyValHash {
    my $self = shift;
    return wantarray? %{$self->[3]}: $self->[3];
}

# -----------------------------------------------------------------------------

=head3 content() - Liefere/Setze Inhalt

=head4 Synopsis

    $content = $sec->content;
    $content = $sec->content($content);

=head4 Returns

Inhalt (String)

=cut

# -----------------------------------------------------------------------------

sub content {
    my $self = shift;

    if (@_) {
        $self->[4] = shift;
    }

    return $self->[4];
}

# -----------------------------------------------------------------------------

=head3 contentRef() - Liefere Referenz auf den Inhalt

=head4 Synopsis

    $ref = $sec->contentRef;

=head4 Returns

Referenz auf Inhalt (String-Referenz)

=cut

# -----------------------------------------------------------------------------

sub contentRef {
    return \shift->[4];
}

# -----------------------------------------------------------------------------

=head3 contentNL() - Liefere Inhalt mit Newline

=head4 Synopsis

    $contentN = $sec->contentNL;

=head4 Returns

Inhalt mit Newline (String)

=cut

# -----------------------------------------------------------------------------

sub contentNL {
    my $self = shift;
    return $self->[4] eq ''? '': $self->[4]."\n";
}

# -----------------------------------------------------------------------------

=head3 file() - Liefere Dateiname

=head4 Synopsis

    $file = $sec->file;

=head4 Returns

Dateiname (String)

=cut

# -----------------------------------------------------------------------------

sub file {
    return shift->[6];
}

# -----------------------------------------------------------------------------

=head3 mtime() - Liefere Zeitpunkt der letzten Änderung der Datei

=head4 Synopsis

    $mtime = $sec->mtime;

=head4 Returns

Integer (Epoch-Wert)

=cut

# -----------------------------------------------------------------------------

sub mtime {
    my $self = shift;

    my $file = $self->file;
    if ($file eq '-' && $file eq '(source)') {
        return 0;
    }
    
    return Quiq::Path->mtime($file);
}

# -----------------------------------------------------------------------------

=head3 line() - Liefere Zeilennummer

=head4 Synopsis

    $n = $sec->line;

=head4 Returns

Zeilennummer (Integer)

=cut

# -----------------------------------------------------------------------------

sub line {
    return shift->[7];
}

# -----------------------------------------------------------------------------

=head3 fileInfo() - Liefere Dateiname und Zeilennummer in einem Aufruf

=head4 Synopsis

    ($file,$line) = $sec->fileInfo;

=head4 Returns

Dateiname (String) und Zeilennummer (Integer)

=cut

# -----------------------------------------------------------------------------

sub fileInfo {
    my $self = shift;
    return ($self->[6],$self->[7]);
}

# -----------------------------------------------------------------------------

=head2 Quelltext

=head3 source() - Liefere Quelltext

=head4 Synopsis

    $source = $sec->source;

=head4 Returns

Quelltext (String)

=cut

# -----------------------------------------------------------------------------

sub source {
    return shift->[5];
}

# -----------------------------------------------------------------------------

=head3 sourceRef() - Liefere Referenz auf Quelltext

=head4 Synopsis

    $ref = $sec->sourceRef;

=head4 Returns

Skalar-Referenz

=cut

# -----------------------------------------------------------------------------

sub sourceRef {
    return \shift->[5];
}

# -----------------------------------------------------------------------------

=head3 deleteSource() - Lösche Quelltext

=head4 Synopsis

    $sec->deleteSource;

=head4 Returns

nichts

=cut

# -----------------------------------------------------------------------------

sub deleteSource {
    shift->[5] = undef;
    return;
}

# -----------------------------------------------------------------------------

=head3 transferSource() - Übertrage Quelltext von Sub-Abschnitten auf Abschnitt

=head4 Synopsis

    $sec->transferSource;

=head4 Returns

nichts

=head4 Description

Füge die Quelltexte aller Sub-Abschnitte von Abschnitt $sec zum
Abschnitt hinzu. Die Quelltexte der Sub-Abschnitte werden von
diesen gelöscht.

=cut

# -----------------------------------------------------------------------------

sub transferSource {
    my $self = shift;

    if (defined $self->[5]) {
        for my $sec (@{$self->[9]}) {
            if (@{$sec->[9]}) {
                $sec->transferSource;
            }
            $self->[5] .= $sec->[5];
            $sec->[5] = undef;
        }
    }
    
    return;
}

# -----------------------------------------------------------------------------

=head3 removeEofMarker() - Entferne "# eof" von Quelltext und Content

=head4 Synopsis

    $sec->removeEofMarker;

=head4 Returns

nichts

=cut

# -----------------------------------------------------------------------------

sub removeEofMarker {
    my $self = shift;

    $self->[4] =~ s/\s*^# eof\n*$//m;
    $self->[5] =~ s/\n+^# eof\n*$/\n\n/m;

    return;
}

# -----------------------------------------------------------------------------

=head2 Attribute

=head3 append() - Füge Zeichenkette zu Wert hinzu

=head4 Synopsis

    $val = $sec->append($key=>$str);

=head4 Arguments

=over 4

=item $key

Schlüssel, dessen Wert ergänzt wird.

=back

=head4 Returns

Wert (String)

=head4 Description

Füge Zeichenkette $str zum Wert des Schlüssels $key hinzu
und liefere den resultierenden Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub append {
    my ($self,$key,$str) = @_;
    my $ref = $self->getRef($key);
    $$ref .= $str;
    return $$ref;
}

# -----------------------------------------------------------------------------

=head3 get() - Liefere Wert zu Schlüssel

=head4 Synopsis

    $val = $sec->get($key);
    @vals = $sec->get(@keys);

=head4 Arguments

=over 4

=item $key bzw. @keys

Schlüssel, deren Wert geliefert wird.

=back

=head4 Returns

Wert (Skalar-Kontext) oder Wertliste (Array-Kontext)

=head4 Description

Liefere den Wert zu Schlüssel $key bzw. die liste der Werte zu den
Schlüsseln @keys. Beginnt der $key mit einem Großbuchstaben, ist
es ein fataler Fehler, wenn zu dem Schlüssel mehrere Werte existieren.
Solche Schlüssel müssen mit $obj->L<getArray|"getArray() - Liefere Wertliste zu Schlüssel">() abgefragt werden.

=cut

# -----------------------------------------------------------------------------

sub get {
    my $self = shift;
    # @_: $key -or- @keys

    my @arr;
    while (@_) {
        my $key = shift;

        my $val = $self->[3]->{$key};
        if (ref($val) && $key =~ /^[A-Z]/) {
            $self->throw(
                'SECOBJ-00001: Schlüssel besitzt mehrere Werte',
                Key => $key,
                Values => '['.join(',',@$val).']',
            );
        }
        push @arr,$val;
    }
    
    return wantarray? @arr: $arr[0];
}

# -----------------------------------------------------------------------------

=head3 getArray() - Liefere Wertliste zu Schlüssel

=head4 Synopsis

    $arr|@arr = $sec->getArray($key);

=head4 Arguments

=over 4

=item $key

Schlüssel dessen Wertliste geliefert wird.

=back

=head4 Returns

Wert bzw. Werte

=head4 Description

Liefere die Wertliste von Schlüssel $key.

=cut

# -----------------------------------------------------------------------------

sub getArray {
    my ($self,$key) = @_;

    my $s = $self->[3]->{$key};
    if (ref $s) {
        return wantarray? @$s: $s;
    }
    elsif (defined $s && $s ne '') {
        return wantarray? ($s): [$s];
    }
    else {
        return wantarray? (): [];
    }
}

# -----------------------------------------------------------------------------

=head3 getBool() - Liefere boolschen Wert zu Schlüssel

=head4 Synopsis

    $bool = $sec->getBool($key);
    $bool = $sec->getBool($key,$default);

=head4 Arguments

=over 4

=item $key

Schlüssel, dessen Wert geliefert wird.

=item $default

Defaultwert, wenn Attribut nicht gesetzt

=back

=head4 Returns

Wert (Skalar)

=head4 Description

Liefere boolschen Wert zu Schlüssel $key.

=cut

# -----------------------------------------------------------------------------

sub getBool {
    my ($self,$key,$default) = @_;

    my $val = lc($self->get($key) // $default // '');
    if ($val eq '' || $val eq 'no' || $val eq '0') {
        $val = 0;
    }
    elsif ($val eq 'yes' || $val eq '1') {
        $val = 1;
    }
    else {
        $self->throw(
            'COTEDO-00001: Illegal attribute value. Only Yes/No allowed.',
            Attribute => $key,
            Value => $val,
            File => $self->file,
            Line => $self->line,
            -stacktrace => 0,
        );
    }

    return $val;
}

# -----------------------------------------------------------------------------

=head3 getMandatory() - Liefere Wert eines Pflichtattributs

=head4 Synopsis

    $val = $sec->getMandatory($key);

=head4 Arguments

=over 4

=item $key

Schlüssel, dessen Wert geliefert wird.

=back

=head4 Returns

Wert (Skalar)

=head4 Description

Wie $sec->L<get|"get() - Liefere Wert zu Schlüssel">(), nur dass ein Wert existieren muss, sonst
wird eine Exception geworfen.

=cut

# -----------------------------------------------------------------------------

sub getMandatory {
    my ($self,$key) = @_;

    my $val = $self->get($key);
    if (!defined $val || $val eq '') { 
        $self->throw(
            'SECOBJ-00002: Attribute has no value',
            Key => $key,
            File => $self->file,
            Line => $self->line,
            -stacktrace => 0,
        );
    }

    return $val;
}

# -----------------------------------------------------------------------------

=head3 getRef() - Liefere Referenz auf Schlüsselwert

=head4 Synopsis

    $ref = $sec->getRef($key);

=cut

# -----------------------------------------------------------------------------

sub getRef {
    my ($self,$key) = @_;
    return \$self->[3]->{$key};
}

# -----------------------------------------------------------------------------

=head3 search() - Suche Attributwert

=head4 Synopsis

    ($key,$val) = $sec->search(\@sections,\@keys);

=head4 Description

Durchsuche die Liste der Abschnitts-Objekte ($self,@sections)
nach dem ersten Attribut aus @keys, das einen Wert besitzt und
liefere das Schlüssel/Wert-Paar zurück. Ist der Wert 'NULL',
wird '' (Leerstring) geliefert. Auf diese Weise kann auf "höherer Ebene"
definierter Wert außer Kraft gesetzt werden.

=cut

# -----------------------------------------------------------------------------

sub search {
    my $self = shift;
    my $sectionA = shift;
    my $keyA = [];

    my $key = '';
    my $text = '';
    SECTION: for my $sec ($self,@$sectionA) {
        for (@$keyA) {
            if ($text = $sec->get($_)) {
                $key = $_;
                last SECTION;
            }
        }
    }
    if ($text eq 'NULL') {
        $text = '';
    }

    return ($key,$text);
}

# -----------------------------------------------------------------------------

=head3 try() - Werte abfragen ohne Exception

=head4 Synopsis

    $val = $sec->try($key);
    @vals = $sec->try(@keys);

=head4 Description

Wie L<get|"get() - Liefere Wert zu Schlüssel">(), nur dass im Falle eines unerlaubten Schlüssels
keine Exception geworfen, sondern C<undef> geliefert wird.

=cut

# -----------------------------------------------------------------------------

sub try {
    my ($self,$key) = @_;
    return $self->[3]->try($key);
}

# -----------------------------------------------------------------------------

=head3 memoize() - Ermittele Wert und cache ihn auf Attribut

=head4 Synopsis

    $val = $sec->memoize($key,$sub);

=head4 Description

Die Methode liefert den Wert des Attributs $key. Ist kein Wert
definiert (Wert ist C<undef>), wird die Methode $sec->$sub($key)
gerufen, der Wert berechnet und auf dem Attribut $key gespeichert.
Weitere Aufrufe liefern diesen Wert, ohne dass er neu berechnet wird.

Die Methode ist nützlich, um in Objektmethoden eingebettet zu werden,
die einen berechneten Wert liefern, der nicht immer wieder neu
gerechnet werden soll.

=head4 Example

    sub name {
        return shift->memoize('name',sub {
            my ($self,$key) = @_;
            my $name = $self->get(ucfirst $key);
            $name =~ s/^\W+//;
            $name =~ s|\W+|/|g;
            return $name;
        });
    }

=cut

# -----------------------------------------------------------------------------

sub memoize {
    my ($self,$key,$sub) = @_;

    my $val = $self->[3]->{$key};
    if (!defined $val) {
        $val = $self->$sub($key);
        $self->[3]->{$key} = $val;
    }

    return $val;
}

# -----------------------------------------------------------------------------

=head3 memoizeWeaken() - Ermittele schwache Referenz

=head4 Synopsis

    $val = $sec->memoizeWeaken($key,$sub);

=head4 Description

Die Methode ist identisch zu $sec->L<memoize|"memoize() - Ermittele Wert und cache ihn auf Attribut">(), nur dass eine
Referenz ermittelt und automatisch zu einer schwachen Referenz
gemacht wird.

=cut

# -----------------------------------------------------------------------------

sub memoizeWeaken {
    my ($self,$key,$sub) = @_;

    my $val = $self->[3]->{$key};
    if (!defined $val) {
        $val = $self->$sub($key);
        $self->[3]->{$key} = $val;
        $self->[3]->weaken($key);
    }

    return $val;
}

# -----------------------------------------------------------------------------

=head3 set() - Setze Schlüssel auf Wert

=head4 Synopsis

    $sec->set(@keyVal);

=head4 Arguments

=over 4

=item @keyVal

Schlüssel/Wert-Paare, die gesetzt werden.

=back

=head4 Returns

nichts

=cut

# -----------------------------------------------------------------------------

sub set {
    my $self = shift;
    # @_: @keyVal
    $self->[3]->set(@_);
    return;
}

# -----------------------------------------------------------------------------

=head3 setDefault() - Setze Defaultwert

=head4 Synopsis

    $sec->setDefault(@keyVal);

=head4 Arguments

=over 4

=item @keyVal

Liste der Schlüssel/Wert-Paare.

=back

=head4 Returns

I<nichts>

=head4 Description

Setze Schlüssel ohne Wert, d.h. wenn der Wert ein Leerstring ist,
setze ihn auf den angegebenen Defaultwert.

=head4 Example

    $sec->setDefault(
        Width => 1000,
        EntityMenuWidth => 345,
        BorderWidth => 1,
        PackageMenuHeight => 34,
    );

=cut

# -----------------------------------------------------------------------------

sub setDefault {
    my $self = shift;
    # @_: @keyVal

    my $h = $self->[3];
    for (my $i = 0; $i < @_; $i += 2) {
        if ($h->{$_[$i]} eq '') {
            $h->{$_[$i]} = $_[$i+1];
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 add() - Füge Schlüssel und Wert hinzu

=head4 Synopsis

    $sec->add(@keyVal);

=head4 Arguments

=over 4

=item @keyVal

Schlüssel/Wert-Paare, die gesetzt werden.

=back

=head4 Returns

nichts

=cut

# -----------------------------------------------------------------------------

sub add {
    my $self = shift;
    # @_: @keyVal
    $self->[3]->add(@_);
    return;
}

# -----------------------------------------------------------------------------

=head3 push() - Füge Element zu Arraykomponente hinzu

=head4 Synopsis

    $sec->push($key,$val);

=head4 Arguments

=over 4

=item $key

Arraykomponente.

=item $val

Wert, der zum Array am Ende hinzugefügt wird.

=back

=head4 Description

Füge Wert $val zur Arraykomponente $key hinzu. Die Methode liefert keinen
Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub push {
    my ($self,$key,$val) = @_;
    CORE::push @{$self->[3]->{$key}},$val;
    return;
}

# -----------------------------------------------------------------------------

=head3 weaken() - Erzeuge schwache Referenz

=head4 Synopsis

    $ref = $sec->weaken($key);
    $ref = $sec->weaken($key=>$ref);

=head4 Description

Mache die Referenz von Schlüssel $key zu einer schwachen Referenz
und liefere sie zurück. Ist eine Referenz $ref als Parameter angegeben,
setze die Referenz zuvor.

=cut

# -----------------------------------------------------------------------------

sub weaken {
    return shift->[3]->weaken(@_);
}

# -----------------------------------------------------------------------------

=head3 validate() - Prüfe und ergänze Attribute

=head4 Synopsis

    $sec->validate($contentAllowed,\@keys);

=head4 Arguments

=over 4

=item $contentAllowed

Wenn falsch, erlaubt der Abschnitt keinen Content (außer "# eof"
als Dateiende-Markierung).

=item @keys

Liste der zulässigen Abschnittsattribute

=back

=head4 Returns

Nichts

=head4 Description

Die Methode finalisiert das Abschnittsobjekt in folgender Weise:

=over 2

=item *

Sie prüft, dass wenn kein Content erlaubt ist, keiner existiert.

=item *

Sie prüft, dass nur Schlüssel im Objekt vorkommen, die in @keys
vorkommen. Kommt ein anderer Schlüssel im Objekt vor, wird eine
Exception geworfen.

=item *

Sie fügt Schlüssel aus @keys zum Objekt hinzu, die das Objekt nicht hat.

=back

=cut

# -----------------------------------------------------------------------------

sub validate {
    my $self = shift;
    my $contentAllowed = shift;
    my $keyA = shift; # erlaubte Attribute

    # Prüfung Content

    if (!$contentAllowed && $self->[4] ne '' && $self->[4] ne '# eof') {
        $self->throw(
            'SECTION-00001: Inhalt ist nicht erlaubt',
            Section => $self->type,
            Content => $self->[4],
            File => $self->file,
            Line => $self->line,
            -stacktrace => 0,
        );
    }

    # Ergänzung fehlender Attribute

    my $h = $self->[3];
    for my $key (@$keyA) {
        if (!exists $h->{$key}) {
            $h->{$key} = '';
        }
    }

    if ($h->hashSize > @$keyA) {
        # Wenn im Hash mehr Schlüssel als erwartet vorkommen,
        # fehlerhafte Schlüssel ermitteln und Exception werfen

        my %h;
        @h{@$keyA} = (1) x @$keyA;
        my @keys;
        for my $key ($self->[3]->keys) {
            if (!exists $h{$key}) {
                CORE::push @keys,$key;
            }
        }

        $self->throw(
            'SECTION-00001: Unknown section attributes',
            Section => $self->type,
            Keys => join(', ',@keys),
            File => $self->file,
            Line => $self->line,
            -stacktrace => 0,
        );
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 lockKeys() - Locke die Keys des Attribut-Hash

=head4 Synopsis

    $sec->lockKeys;

=cut

# -----------------------------------------------------------------------------

sub lockKeys {
    my $self = shift;
    $self->[3]->lockKeys;
    return;
}

# -----------------------------------------------------------------------------

=head2 Fehler

=head3 error() - Wirf eine Exception mit Dateiname und Zeilennummer

=head4 Synopsis

    $sec->error($msg,@keyVal);

=head4 Arguments

=over 4

=item $msg

Die Fehlermeldung.

=item @keyVal

Detailinformation zum Fehler.

=back

=head4 Returns

Die Methode kehrt nicht zurück

=head4 Description

Die Methode wirft eine Exception mit dem Fehlertext $msg und den
als Schlüssel/Wert-Paare angegebenen Informationen @keyVal. Ferner
wird von der Methode der Dateiname und die Zeilennummer des
Abschnitts ergnzt. Die Exception beinhaltet keinen Stacktrace.

=cut

# -----------------------------------------------------------------------------

sub error {
    my ($self,$msg) = splice @_,0,2;
    # @_: @keyVal

    $self->throw(
        $msg,
        @_,
        File => $self->file,
        Line => $self->line,
        -stacktrace => 0,
    );
}

# -----------------------------------------------------------------------------

=head2 Automatische Akzessor-Methoden

=head3 AUTOLOAD() - Erzeuge Akzessor-Methode

=head4 Synopsis

    $val = $this->AUTOLOAD;
    $val = $this->AUTOLOAD($val);

=head4 Description

Erzeuge beim ersten Aufruf eine Akzessor-Methode für einen Schlüssel
des Schlüssel/Wert-Hashs und führe den betreffenden Methodenaufruf
durch.

=cut

# -----------------------------------------------------------------------------

sub AUTOLOAD {
    my $this = shift;
    # @_: Methodenargumente

    my ($key) = our $AUTOLOAD =~ /::(\w+)$/;
    return if $key !~ /[^A-Z]/;

    # Klassenmethoden generieren wir nicht

    if (!ref $this) {
        $this->throw(
            'HASH-00002: Klassen-Methode existiert nicht',
            Method => $key,
        );
    }

    # Methode nur generieren, wenn Attribut existiert

    if (!exists $this->[3]->{$key}) {
        $this->throw(
            'HASH-00001: Schlüssel existiert nicht',
            Attribute => $key,
            Class => ref($this)? ref($this): $this,
        );
    }

    # Attribut-Methode generieren. Wenn der Hash $self->[3] gelockt ist,
    # führt ein unerlaubter Zugriff zu einer Exception.

    no strict 'refs';
    *{$AUTOLOAD} = sub {
        my $self = shift;
        # @_: $val

        if (@_) {
            return $self->[3]->{$key} = shift;
        }

        return $self->[3]->{$key};
    };

    # Methode aufrufen
    return $this->$key(@_);
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
