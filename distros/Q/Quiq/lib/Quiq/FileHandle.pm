package Quiq::FileHandle;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.147';

use Quiq::Path;
use Quiq::Option;
use Scalar::Util ();
use Quiq::Perl;
no bytes;
use Fcntl qw(:flock);

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::FileHandle - Datei-Handle

=head1 BASE CLASS

L<Quiq::Object>

=head1 SYNOPSIS

Datei schreiben:

    my $fh = Quiq::FileHandle->new('>',$path);
    $fh->print("Test\n");
    $fh->close;

Datei lesen:

    my $fh = Quiq::FileHandle->new('<',$path);
    while (<$fh>) {
        print;
    }
    $fh->close;

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Dateihandle, über die
Daten gelesen oder geschrieben werden können.

=head1 EXAMPLES

Zähler-Datei mit Locking:

    my $fh = Quiq::FileHandle->open('+>>',$file,-lock=>'EX');
    $fh->seek(0);
    my $count = <$fh> || "0\n";
    chomp $count;
    $fh->truncate;
    $fh->print(++$count,"\n");

Siehe auch Quiq::LockedCounter.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Öffne Dateihandle

=head4 Synopsis

    $fh = $class->new($mode,$path,@opt);
    $fh = $class->new($globRef,@opt);
    $fh = $class->new('<'); # Lesen von STDIN
    $fh = $class->new('>'); # Schreiben nach STDOUT

=head4 Alias

open()

=head4 Options

=over 4

=item -createDir => $bool (Default: 0)

Erzeuge den Verzeichnispfad einer Datei, die geschrieben wird,
falls er nicht existiert.

=item -lock => 'EX'|'SH'|'EXNB'|'SHNB' (Default: kein Lock)

Locke die Dateihandle nach dem Öffnen im angegebenen Lock-Modus.
Folgende Lockmodes werden unterschieden: 'SH' (shared lock), 'EX'
(exclusive lock).  Durch den Zusatz 'NB' (also Lockmode 'SHNB' der 'EXNB')
wird die Operation "non blocking" ausgeführt, d.h. wenn der Lock nicht
sofort erworben werden kann, wird eine Exception ausgelöst.

Wurde die Datei vom Konstruktor geöffnet, schließt er sie, wenn
der Lock nicht erworben werden kann. Andernfalls bleibt die
Dateihandle geöffnet.

=back

=head4 Description

Instantiiere Dateihandle-Objekt und liefere eine Referenz auf dieses
Objekt zurück.

=head4 Examples

Filehandle-Objekt für STDOUT:

    $fh = Quiq::FileHandle->new(\*STDOUT);

Lesen von STDIN:

    $fh = $class->new('<');
    $fh = $class->new('<','');
    $fh = $class->new('<','-');

Schreiben nach STDOUT:

    $fh = $class->new('>');
    $fh = $class->new('>','');
    $fh = $class->new('>','-');

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: ($globRef,@opt) -oder- ($mode,$path,@opt)

    my ($self,$mode,$path);
    if (ref $_[0] eq 'GLOB') {      # GLOB-Referenz
        $self = shift;
    }
    else {                          # Datei öffnen
        $mode = shift;
        $path = Quiq::Path->expandTilde(shift);
    }

    # Optionen

    my $lock;
    my $createDir;

    if (@_) {
        Quiq::Option->extract(\@_,
            -createDir=>\$createDir,
            -lock=>\$lock,
        );
    }

    if ($mode) {
        if ($mode eq '<' && (!$path || $path eq '-')) {
            $self = \*STDIN;
        }
        elsif ($mode eq '>' && (!$path || $path eq '-')) {
            $self = \*STDOUT;
        }
        else {
            if (ref($path) && Scalar::Util::reftype($path) eq 'SCALAR' &&
                    ref($path) ne 'SCALAR') {
                # Wenn $path eine *geblesste* Skalarreferenz ist,
                # müssen wir die Daten kopieren, um eine ungeblesste
                # Referenz zu bekommen, denn open() arbeitet nicht auf
                # auf einer geblessten Referenz
                $path = \(my $tmp = $$path);
            }

            if ($mode eq '>' && $createDir) {
                Quiq::Path->mkdir($path,-createParent=>1);
            }

            unless (open $self,$mode,$path) {
                $class->throw(
                    'FH-00001: Kann Datei nicht öffnen',
                    Path=>$path,
                    Errstr=>$!,
                );
            }
        }
    }
    $self = bless $self,$class;

    # Datei locken

    if ($lock) {
        $self->lock($lock) or do {
            if ($path) {
                # Wir haben die Datei geöffnet und schließen sie gleich wieder
                CORE::close $self;
            }
            $class->throw('FH-00002: Kann Lock nicht setzen',Errstr=>$!);
        };
    }

    return $self;
}

{
    no warnings 'once';
    *open = \&new;
}

# -----------------------------------------------------------------------------

=head3 destroy() - Schließe Dateihandle

=head4 Synopsis

    $fh->destroy;

=head4 Alias

close()

=head4 Description

Schließe Dateihandle. Die Methode liefert keinen Wert zurück.
Nach Aufruf der Methode ist die Objektreferenz ungültig.

=cut

# -----------------------------------------------------------------------------

sub destroy {
    my ($self) = @_; # Nicht ändern!

    CORE::close $self or do {
        $self->throw('FH-00009: FileHandle schließen fehlgeschlagen');
    };
    $_[0] = undef;

    return;
}

{
    no warnings 'once';
    *close = \&destroy;
}

# -----------------------------------------------------------------------------

=head2 Lesen

=head3 read() - Lies Daten von Dateihandle

=head4 Synopsis

    $data = $fh->read($n);

=head4 Description

Lies die nächste die nächsten $n I<Zeichen> von Dateihandle $fh
und liefere diese zurück. Ist das Dateiende erreicht, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub read {
    my ($self,$n) = @_;

    if ($n == 0) {
        # Der Returnwert 0 von read() zeigt nur dann EOF an, wenn
        # mehr als 0 Bytes gelesen werden sollen
        return '';
    }

    undef $!;
    $n = CORE::read($self,my $data,$n);
    if (!defined $n) {
        $self->throw('FH-00012: Read fehlgeschlagen',Errstr=>$!);
    }
    elsif ($n == 0) {
        return undef;
    }

    return $data;
}

# -----------------------------------------------------------------------------

=head3 readData() - Lies Daten mit Längenangabe

=head4 Synopsis

    $data = $fh->readData;

=head4 Description

Lies Daten in der Repräsentation

    <LENGTH><DATA>

und liefere <DATA> zurück. <LENGTH> ist ein 32 Bit Integer und <DATA>
sind beliebige Daten mit <LENGTH> Bytes Länge.

Wurden die Daten in einem Encoding wie UTF-8 geschrieben, müssen diese
nach dem Einlesen anscheinend nicht dekodiert werden. Warum?

Wurden die Daten $data in einem Encoding wie UTF-8 geschrieben, müssen
diese anschließend decodiert werden mit

    Encode::decode('utf-8',$data);

Auf der FileHandle $fh das Encoding zu definieren, ist I<nicht>
richtig, da die Längenangabe diesem Encoding nicht unterliegt!

=head4 See Also

writeData()

=cut

# -----------------------------------------------------------------------------

sub readData {
    my $self = shift;

    my $length = $self->read(4);
    if (!defined $length) {
        return undef;
    }

    return $self->read(unpack 'I',$length);
}

# -----------------------------------------------------------------------------

=head3 readLine() - Lies Zeile von Dateihandle

=head4 Synopsis

    $line = $fh->readLine;

=head4 Description

Lies die nächste Zeile von Dateihandle $fh und liefere diese zurück.
Schlägt dies fehl, wirf eine Exception.

=cut

# -----------------------------------------------------------------------------

sub readLine {
    my $self = shift;

    undef $!;
    my $line = CORE::readline $self;
    if (!defined $line and $!) {
        $self->throw('FH-00011: ReadLine fehlgeschlagen',Errstr=>$!);
    }

    return $line;
}

# -----------------------------------------------------------------------------

=head3 readLines() - Lies mehrere Zeilen von Dateihandle

=head4 Synopsis

    @lines|$lineA = $fh->readLines($n);

=head4 Description

Lies die nächsten $n Zeilen von Dateihandle $fh und liefere diese als
Liste zurück. Der Zeilentrenner am Ende jeder Zeile wird entfernt.
Im Skalarkontext liefere eine Referenz auf die Liste, wenn
Zeilen gelesen wurden, sonst C<undef>.

=head4 Example

Liefere Chunks von 1000 Pfaden:

    my $fh = Quiq::FileHandle->new('-|',"find @$dirA -name '*.xml.gz'");
    while (my $fileA = $fh->readLines(1000)) {
        ...
    }
    $fh->close;

=cut

# -----------------------------------------------------------------------------

sub readLines {
    my ($self,$n) = @_;

    my @lines;
    for (my $i = 0; $i < $n; $i++) {
        my $line = <$self>;
        if (!defined $line) {
            last;
        }
        chomp $line;
        push @lines,$line;
    }

    return wantarray? @lines: @lines? \@lines: undef;
}

# -----------------------------------------------------------------------------

=head3 readLineChomp() - Lies Zeile ohne Zeilentrenner von Dateihandle

=head4 Synopsis

    $line = $fh->readLineChomp;

=head4 Description

Lies die nächste Zeile von Dateihandle $fh, entferne den Zeilentrenner
mit chomp() und liefere das Resultat zurück.

=cut

# -----------------------------------------------------------------------------

sub readLineChomp {
    my $self = shift;

    my $line = $self->readLine;
    if (defined $line) {
        chomp $line;
    }

    return $line;
}

# -----------------------------------------------------------------------------

=head3 readLineNoWhiteSpace() - Lies Zeile und entferne Whitespace am Ende

=head4 Synopsis

    $line = $fh->readLineNoWhiteSpace;

=head4 Description

Lies die nächste Zeile von Dateihandle $fh, entferne
jeglichen Whitespace am Zeilenende (mit s/\s+$//) und liefere
das Resultat zurück.

Diese Funktion ist nützlich, wenn verschiedene Zeilentrenner
CRLF oder LF vorkommen können und Zeilen nur mit Whitespace
zu Leerzeilen reduziert werden sollen.

=cut

# -----------------------------------------------------------------------------

sub readLineNoWhiteSpace {
    my $self = shift;

    my $line = $self->readLine;
    if (defined $line) {
        $line =~ s/\s+$//;
    }

    return $line;
}

# -----------------------------------------------------------------------------

=head3 getc() - Lies nächstes Zeichen

=head4 Synopsis

    $c = $fh->getc;

=cut

# -----------------------------------------------------------------------------

sub getc {
    my $self = shift;

    # MEMO: 'Bad file descriptor' kommt anscheinend immer am Dateiende
    
    undef $!;
    my $c = CORE::getc($self);
    if (!defined($c) && $! ne 'Bad file descriptor') {
        $self->throw('FH-00011: getc() fehlgeschlagen',Errstr=>$!);
    }

    return $c;
}

# -----------------------------------------------------------------------------

=head3 slurp() - Lies Rest der Datei

=head4 Synopsis

    $data = $fh->slurp;

=head4 Returns

String

=head4 Description

Lies den Rest von Dateihandle $fh liefere diesen zurück.

Die Methode ist nützlich, wenn der gesamte Inhalt einer Datei ab einer
bestimmten Position gelesen werden soll.

=head4 Example

Lies gesamten Inhalt einer Datei ab Position $pos:

    my $fh = Quiq::FileHandle->open('<',$logFile);
    $fh->seek($pos);
    my $data = $fh->slurp;

=cut

# -----------------------------------------------------------------------------

sub slurp {
    my $self = shift;
    local $/;
    return <$self>;
}

# -----------------------------------------------------------------------------

=head2 Schreiben

=head3 print() - Schreibe Daten auf Dateihandle

=head4 Synopsis

    $fh->print(@data);

=head4 Alias

write()

=head4 Description

Schreibe Daten @data auf Dateihandle $fh. Die Methode liefert
keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub print {
    my $self = shift;
    # @_: @data
    Quiq::Perl->print($self,@_);
    return;
}

{
    no warnings 'once';
    *write = \&print;
}

# -----------------------------------------------------------------------------

=head3 writeData() - Schreibe Daten mit Längenangabe

=head4 Synopsis

    $fh->writeData($data);

=head4 Description

Schreibe die Daten $data in der Repräsentation

    <LENGTH><DATA>

Hierbei ist <LENGTH> ein 32 Bit Integer, der die Länge der
darauffolgenden Daten <DATA> in Bytes angibt.

Liegen die Daten $data in einem Encoding wie UTF-8 vor, müssen diese
zuvor encodiert werden mit

    Encode::encode('utf-8',$data);

Auf der FileHandle $fh das Encoding zu definieren, ist I<nicht>
richtig, da die Längenangabe diesem Encoding nicht unterliegt!

=head4 See Also

readData()

=cut

# -----------------------------------------------------------------------------

sub writeData {
    my ($self,$str) = @_;
    Quiq::Perl->print($self,pack('I',bytes::length($str)),$str);
    return;
}

# -----------------------------------------------------------------------------

=head3 truncate() - Kürze Datei

=head4 Synopsis

    $fh->truncate;
    $fh->truncate($length);

=head4 Description

Kürze Datei auf Länge $length. Ist $length nicht angegeben, kürze
Datei auf Länge 0.

=cut

# -----------------------------------------------------------------------------

sub truncate {
    my $self = shift;
    my $length = shift || 0;

    unless (CORE::truncate $self,$length) {
        $self->throw(
            'FH-00013: truncate fehlgeschlagen',
            Errstr=>$!,
        );
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Positionieren

=head3 seek() - Setze Position in Datei

=head4 Synopsis

    $fh->seek($pos);
    $fh->seek($pos,$whence);

=head4 Description

Setze die Position der Filehandle in der Datei. Die Methode liefert
keinen Wert zurück. Genaue Funktionsbeschreibung siehe
Perl-Dokumentation (perldoc -f seek).

=cut

# -----------------------------------------------------------------------------

sub seek {
    my $self = shift;
    my $pos = shift;
    my $whence = shift || 0;

    unless (CORE::seek $self,$pos,$whence) {
        $self->throw('FH-00014: seek fehlgeschlagen',Errstr=>$!);
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 tell() - Liefere Position in Datei

=head4 Synopsis

    $pos = $fh->tell;

=head4 Description

Liefere die Position der Filehandle in der Datei. Genaue
Funktionsbeschreibung siehe Perl-Dokumentation (perldoc -f tell).

=cut

# -----------------------------------------------------------------------------

sub tell {
    my $self = shift;

    my $pos = CORE::tell $self;
    if ($pos < 0) {
        $self->throw('FH-00013: tell fehlgeschlagen',Errstr=>$!);
    }

    return $pos;
}

# -----------------------------------------------------------------------------

=head2 Sperren

=head3 lock() - Sperre Datei

=head4 Synopsis

    $fh->lock($lockMode);

=head4 Description

Locke die Datei im Lock-Modus $lockMode. Die Methode liefert keinen
Wert zurück.

Folgende Lockmodes werden unterschieden:

=over 4

=item 'SH'

shared lock

=item 'EX'

exclusive lock

=item 'SHNB'

shared lock, non-blocking

=item 'EXNB'

exclusive lock, non-bloking

=back

Liefere "wahr", wenn der Lock gesetzt werden kann, im Fehlerfall
liefere "falsch".

=cut

# -----------------------------------------------------------------------------

sub lock {
    my ($self,$lockMode) = @_;

    my $lock;
    if ($lockMode eq 'SH') {
        $lock = Fcntl::LOCK_SH;
    }
    elsif ($lockMode eq 'EX') {
        $lock = Fcntl::LOCK_EX;
    }
    elsif ($lockMode eq 'SHNB') {
        $lock = Fcntl::LOCK_SH|Fcntl::LOCK_NB;
    }
    elsif ($lockMode eq 'EXNB') {
        $lock = Fcntl::LOCK_EX|Fcntl::LOCK_NB;
    }
    else {
        $self->throw('FH-00002: Unbekannter Lock-Modus',LockMode=>$lockMode);
    }

    return flock($self,$lock)? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 unlock() - Hebe Sperre auf

=head4 Synopsis

    $fh->unlock;

=head4 Description

Hebe Sperre auf Dateihandle $fh auf. Die Methode liefert keinen
Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub unlock {
    my $self = shift;

    unless (flock $self,Fcntl::LOCK_UN) {
        $self->throw('FH-00003: Kann Lock nicht aufheben',Errstr=>$!);
    };

    return;
}

# -----------------------------------------------------------------------------

=head2 Encoding

=head3 setEncoding() - Setze Encoding

=head4 Synopsis

    $fh = $fh->setEncoding($encoding);

=head4 Returns

FileHandle-Objekt (für Method-Chaining)

=head4 Description

Definiere für Filehandle $fh das Encoding $encoding. D.h. alle Daten
werden automatisch gemäß diesem Encoding beim Schreiben encodiert
bzw. beim Lesen dekodiert.

Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub setEncoding {
    my ($self,$encoding) = @_;
    $self->binmode(sprintf ':encoding(%s)',$encoding);
    return $self;
}

# -----------------------------------------------------------------------------

=head2 Verschiedenes

=head3 autoFlush() - Schalte Filehandle in ungepufferten Modus

=head4 Synopsis

    $fh->autoFlush;
    $fh->autoFlush($bool);

=cut

# -----------------------------------------------------------------------------

sub autoFlush {
    my $self = shift;
    my $bool = @_? shift: 1;

    my $tmp = CORE::select $self;
    $| = $bool;
    CORE::select $tmp;

    return;
}

# -----------------------------------------------------------------------------

=head3 binmode() - Aktiviere Binärmodus oder Layer

=head4 Synopsis

    $fh->binmode;
    $fh->binmode($layer);

=head4 Description

Schalte Filehandle in Binärmodus oder setze Layer $layer. Genaue
Funktionsbeschreibung siehe Perl-Dokumentation (perldoc -f binmode).

=cut

# -----------------------------------------------------------------------------

sub binmode {
    Quiq::Perl->binmode(@_);
    return;
}

# -----------------------------------------------------------------------------

=head2 Klassenmethoden

=head3 captureStderr() - Fange STDERR ab

=head4 Synopsis

    $class->captureStderr(\$str);

=head4 Returns

Die Methode liefert keinen Wert zurrück

=head4 Description

Fange alle Ausgaben auf STDERR ab und lenke sie auf Skalarvariable
$str um.

=cut

# -----------------------------------------------------------------------------

sub captureStderr {
    my ($class,$ref) = @_;

    CORE::close STDERR;
    CORE::open STDERR,'>',$ref or do {
        $class->throw(
            'FH-00001: Abfangen von STDERR fehlgeschlagen',
            Errstr=>$!,
        );
    };

    return;
}

# -----------------------------------------------------------------------------

=head3 slurpFromStdin() - Lies Eingaben von STDIN

=head4 Synopsis

    $data = $class->slurpFromStdin;

=head4 Returns

String

=head4 Description

Lies alle Eingaben von STDIN und liefere diese als eine
Zeichenkette zurück.

=cut

# -----------------------------------------------------------------------------

sub slurpFromStdin {
    return shift->new('<')->slurp;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.147

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
