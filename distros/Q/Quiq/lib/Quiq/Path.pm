# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Path - Dateisystem-Operationen

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Die Klasse definiert alle grundlegenden (link, mkdir, rename, symlink
usw.) und komplexen (copy, glob, find usw.) Dateisystem-Operationen.
Eine Dateisystem-Operation ist eine Operation auf einem I<Pfad>.

=cut

# -----------------------------------------------------------------------------

package Quiq::Path;
BEGIN {
    $INC{'Quiq/Path.pm'} ||= __FILE__;
}
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;
use utf8;

our $VERSION = '1.228';

use Quiq::Option;
use Quiq::FileHandle;
use Quiq::TempFile;
use Quiq::Shell;
use Quiq::Terminal;
use Encode::Guess ();
use Quiq::String;
use Encode ();
use Digest::SHA ();
use Time::HiRes ();
use Quiq::Unindent;
use Fcntl qw/:DEFAULT/;
use Quiq::Perl;
use Quiq::DirHandle;
use File::Find ();
use Quiq::Exit;
use Quiq::TempDir;
use Cwd ();
use POSIX ();
use Quiq::Time;
use Quiq::Process;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $p = $class->new;

=head4 Returns

Path-Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück. Da die Klasse ausschließlich Klassenmethoden
enthält, hat das Objekt ausschließlich die Funktion, eine abkürzende
Aufrufschreibweise zu ermöglichen.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    return bless \(my $dummy),$class;
}

# -----------------------------------------------------------------------------

=head2 Datei-Operationen

=head3 append() - Hänge Daten an Datei an

=head4 Synopsis

  $this->append($file,$data,@opt);

=head4 Arguments

=over 4

=item $file

Pfad der Datei.

=item $data

Daten, die auf die Datei geschrieben werden.

=back

=head4 Options

=over 4

=item -lock => $bool (Default: 0)

Locke die Datei während des Schreibens exklusiv.

=back

=head4 Description

Hänge Daten $data an Datei $file an.

=cut

# -----------------------------------------------------------------------------

sub append {
    shift->write(@_,-append=>1);
    return;
}

# -----------------------------------------------------------------------------

=head3 checkFileSecurity() - Prüfe, ob Datei geschützt ist

=head4 Synopsis

  $this->checkFileSecurity($file); # nur Owner darf schreiben und lesen
  $this->checkFileSecurity($file,$readableByOthers); # nur Owner darf schreiben

=head4 Arguments

=over 4

=item $file

Datei, deren Rechte geprüft werden.

=item $readableByOthers

Wenn wahr, dürfen auch andere die Datei lesen.

=back

=head4 Description

Prüfe, ob die Datei $file vor unerlaubtem Zugriff geschützt ist.
Wenn nicht, wirf eine Exception.

Per Default darf die Datei nur für ihren Owner lesbar und schreibbar
sein, muss also die Zugriffsrechte rw------- besitzen.

Ist $readable wahr, darf die Datei von der Gruppe und anderen
gelesen werden, darf also die Zugriffsrechte rw-r--r-- besitzen.

=cut

# -----------------------------------------------------------------------------

sub checkFileSecurity {
    my ($this,$file,$readable) = @_;

    my $mode = $this->mode($file);

    # Die Datei darf nur für ihren Owner schreibbar sein

    if ($mode & 00022) {
        $this->throw(
            'PATH-00099: File is writeable by others',
            File => $file,
        );
    }

    if (!$readable) {
        # Die Datei darf nur für ihren Owner lesbar sein

        if ($mode & 00044) {
            $this->throw(
                'PATH-00099: File is readable by others',
                File => $file,
            );
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 compare() - Prüfe, ob Inhalt differiert

=head4 Synopsis

  $bool = $class->compare($file1,$file2);

=head4 Description

Prüfe, ob der Inhalt der Dateien $file1 und $file2 differiert.
Ist dies der Fall, liefere I<wahr> (1 oder 2), andernfalls I<falsch> (0).
Differiert $file2, wird 1 geliefert, existiert $file2 nicht,
wird 2 geliefert.

=cut

# -----------------------------------------------------------------------------

sub compare {
    my $class = shift;
    my $file1 = $class->expandTilde(shift);
    my $file2 = $class->expandTilde(shift);

    if (!-e $file2) {
        return 2;
    }

    if (-s $file1 != -s $file2) {
        return 1;
    }

    return $class->read($file1) eq $class->read($file2)? 0: 1;
}

# -----------------------------------------------------------------------------

=head3 compareData() - Prüfe, ob Datei-Inhalt von Daten differiert

=head4 Synopsis

  $bool = $class->compareData($file,$data);
  $bool = $class->compareData($file,$data,$encoding);

=head4 Alias

different()

=head4 Description

Prüfe, ob der Inhalt der Datei $file von $data differiert. Ist dies
der Fall, liefere I<wahr>, andernfalls I<falsch>. Die Datei $file muss
nicht existieren.

=cut

# -----------------------------------------------------------------------------

sub compareData {
    my ($class,$file,$data,$encoding) = @_;

    require bytes;
    if (!-e $file || -s $file != bytes::length($data)) {
        return 1;
    }

    my $fileData = $class->read($file,-decode=>$encoding);
    return $fileData eq $data? 0: 1;
}

{
    no warnings 'once';
    *different = \&compareData;
}

# -----------------------------------------------------------------------------

=head3 convertEncoding() - Wandele Character Encoding

=head4 Synopsis

  $this->convertEncoding($from,$to,$file);

=head4 Arguments

=over 4

=item $from

Aktuelles Encoding der Datei

=item $to

Zukünftiges Encoding der Datei

=item $file

Datei, deren Encoding gewandelt wird

=back

=head4 Description

Wandele das Encoding der Datei $file von Encoding $from in Encoding $to.
Die Wandelung findet "in place" statt.

=cut

# -----------------------------------------------------------------------------

sub convertEncoding {
    my $this = shift;
    my $from = shift;
    my $to = shift;
    my $file = $this->expandTilde(shift);

    my $data = $this->read($file,-decode=>$from);
    $this->write($file,$data,-encode=>$to);

    return;
}

# -----------------------------------------------------------------------------

=head3 copy() - Kopiere Datei

=head4 Synopsis

  $this->copy($srcPath,$destPath,@opt);

=head4 Options

=over 4

=item -createDir => $bool (Default: 0)

Erzeuge Zielverzeichnis, falls es nicht existiert.

=item -move => $bool (Default: 0)

Lösche Quelldatei $srcPath nach dem Kopieren.

=item -overwrite => $bool (Default: 1)

Wenn gesetzt, wird die Zieldatei $destPath überschrieben, falls sie
existiert. Andernfalls wird eine Exception geworfen.

=item -preserve => $bool (Default: 0)

Behalte den Zeitpunkt der letzten Änderung bei.

=back

=head4 Description

Kopiere Datei $srcPath nach $destPath. Ist eine Nulloperation,
wenn die Ziledatei existiert und identisch zur Quelldatei ist
(gleicher Inode).

=cut

# -----------------------------------------------------------------------------

sub copy {
    my $this = shift;
    my $srcPath = $this->expandTilde(shift);
    my $destPath = $this->expandTilde(shift);
    # @_: @opt

    # Optionen

    my $createDir = 0;
    my $move = 0;
    my $overwrite = 1;
    my $preserve = 0;

    if (@_) {
        Quiq::Option->extract(\@_,
            -createDir => \$createDir,
            -move => \$move,
            -overwrite => \$overwrite,
            -preserve => \$preserve,
        );
    }

    # Operation ausführen

    if (-e $destPath) {
        if ($this->sameFile($srcPath,$destPath)) {
            # Wenn Quell- und Zieldatei identisch sind
            # (gleicher Inode), machen wir nichts
            return;
        }
        if (!$overwrite) {
            $this->throw(
                'PATH-00099: Destination path already exists',
                Path => $destPath,
            );
        }
    }

    my $fh1 = Quiq::FileHandle->new('<',$srcPath);

    if ($createDir) {
        my ($destDir) = $this->split($destPath);
        $this->mkdir($destDir,-recursive=>1);
    }

    my $fh2 = Quiq::FileHandle->new('>',$destPath);
    while (<$fh1>) {
        print $fh2 $_ or $this->throw(
            'PATH-00007: Write failed',
            SourcePath => $srcPath,
            DestinationPath => $destPath,
        );
    }
    $fh2->close;
    $fh1->close;

    if ($preserve) {
        $this->mtime($destPath,$this->mtime($srcPath));
    }

    if ($move) {
        $this->delete($srcPath);
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 copyToDir() - Kopiere Datei in Verzeichnis

=head4 Synopsis

  $class->copyToDir($srcFile,$destDir,@opt);

=head4 Options

=over 4

=item -createDir => $bool (Default: 0)

Erzeuge Zielverzeichnis, falls es nicht existiert.

=item -move => $bool (Default: 0)

Lösche Quelldatei $srcPath nach dem Kopieren.

=item -overwrite => $bool (Default: 1)

Wenn gesetzt, wird die Zieldatei $destPath überschrieben, falls sie
existiert. Andernfalls wird eine Exception geworfen.

=item -preserve => $bool (Default: 0)

Behalte den Zeitpunkt der letzten Änderung bei.

=back

=head4 Description

Kopiere Datei $srcPath nach $destPath.

=cut

# -----------------------------------------------------------------------------

sub copyToDir {
    my $class = shift;
    my $srcFile = shift;
    my $destDir = shift;
    # @_: @opt

    my $destFile = sprintf '%s/%s',$destDir,$class->filename($srcFile);
    $class->copy($srcFile,$destFile,@_);

    return;
}

# -----------------------------------------------------------------------------

=head3 duplicate() - Kopiere, bewege, linke oder symlinke Datei

=head4 Synopsis

  $class->duplicate($method,$srcPath,$destPath,@opt);

=head4 Arguments

=over 4

=item $method

Anzuwendende Pfadoperation:

  copy
  move -or- rename
  link
  symlink

=item $srcPath

(String) Quellpfad

=item $destPath

(String) Zielpfad

=back

=head4 Options

=over 4

=item -preserve => $bool (Default: 0)

Behalte den Zeitpunkt der letzten Änderung bei (nur bei 'copy'
relevant).

=back

=head4 Description

Mache Datei $srcPath nach Methode $method unter $destPath verfügbar.
Werte für $method:

  copy
  move -or- rename
  link
  symlink

=cut

# -----------------------------------------------------------------------------

sub duplicate {
    my $class = shift;
    my $method = shift;
    my $srcPath = shift;
    my $destPath = shift;
    # @_: @opt

    # Optionen

    my $preserve = 0;

    if (@_) {
        Quiq::Option->extract(\@_,
            -preserve => \$preserve,
        );
    }

    # Operation ausführen

    if ($method eq 'copy') {
        $class->copy($srcPath,$destPath,-preserve=>1);
    }
    elsif ($method eq 'move' || $method eq 'rename') {
        $class->rename($srcPath,$destPath);
    }
    elsif ($method eq 'link') {
        $class->link($srcPath,$destPath);
    }
    elsif ($method eq 'symlink') {
        $class->symlinkRelative($srcPath,$destPath);
    }
    else {
        $class->throw;
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 edit() - Bearbeite Datei oder Daten im Editor

=head4 Synopsis

  $changed = $this->edit($file,@opt);
  $changed = $this->edit(\$data,@opt);

=head4 Arguments

=over 4

=item $file

Datei, die bearbeitet werden soll.

=item $data

Daten, die bearbeitet werden sollen.

=back

=head4 Returns

Boolschen Wert, der anzeigt, ob die Datei oder die Daten
verändert wurden.

=head4 Description

Öffne Datei $file oder Daten $data im Editor, so dass diese vom
Benutzer bearbeitet werden können. Die Methode prüft nach
Verlassen des Editors, ob die Datei bzw. Daten geändert
wurden. Falls ja, wird der Benutzer gefragt, ob er die Änderungen
beibehalten möchte. Falls ja, liefert die Methode wahr,
andernfalls falsch.

=cut

# -----------------------------------------------------------------------------

sub edit {
    my $this = shift;
    my ($file,$dataR) = ref $_[0]? (undef,shift): (shift,undef);
    # @_: $file -or- \$data

    my $encoding = 'utf-8';
    my $changed = 0;
    my $tmpFile = Quiq::TempFile->new;

    if ($file) {
        # Erzeuge eine temporäre Kopie
        $this->copy($file,$tmpFile);
    }
    else { # $dataR
        # Schreibe Daten auf temporäre Datei
        $this->write($tmpFile,$$dataR,-encode=>$encoding);
    }

    # Öffne Tempdatei im Editor

    my $editor = $ENV{'EDITOR'} || 'vi';
    Quiq::Shell->exec("$editor $tmpFile");

    my $ask = 0;
    if ($file) {    
        if ($this->compare($tmpFile,$file)) {
            $ask = 1;
        }
    }
    else {
        if ($this->compareData($tmpFile,$$dataR,$encoding)) {
            $ask = 1;
        }
    }

    if ($ask) {
        # Rückfrage an Benutzer

        my $answ = Quiq::Terminal->askUser(
            "Confirm changes?",
            -values => 'y/n',
            -default => 'y',
        );
        if ($answ eq 'y') {
            # Schreibe die Änderungen auf die Datei

            if ($file) {
                $this->copy($tmpFile,$file);
            }
            else {
                $$dataR = $this->read($tmpFile,-decode=>'utf-8');
            }
            $changed = 1;
        }
    }

    return $changed;
}

# -----------------------------------------------------------------------------

=head3 detectEncoding() - Liefere das Encoding der Datei

=head4 Synopsis

  $encoding = $class->detectEncoding($path,$altEncoding);

=head4 Alias

encoding()

=head4 Description

Analysiere Datei $path hinsichtlich ihres Character-Encodings
und liefere den Encoding-Bezeichner zurück. Unterschieden werden:

=over 2

=item *

ASCII

=item *

UTF-8

=item *

UTF-16/32 mit BOM

=back

und $altEncoding. Ist $altEncoding nicht angegeben, wird
'ISO-8859-1' angenommen.

Anmerkung: Die Datei wird zur Zeichensatz-Analyse vollständig eingelesen.
Bei großen Dateien kann dies ineffizient sein.

=cut

# -----------------------------------------------------------------------------

sub detectEncoding {
    my $class = shift;
    my $path = shift;
    my $altEncoding = shift // 'ISO-8859-1';

    my $data = $class->read($path);
    my $dec = Encode::Guess->guess($data);
    if (ref $dec) {
        return $dec->name;
    }
    elsif ($dec =~ /No appropriate encodings found/i) {
        return $altEncoding;
    }

    # Unerwarteter Fehler

    $class->throw(
        'PATH-00099: Can\'t decode file content',
        Path => $path,
        Message => $dec,
    );
}

{
    no warnings 'once';
    *encoding = \&detectEncoding;
}

# -----------------------------------------------------------------------------

=head3 link() - Erzeuge (Hard)Link

=head4 Synopsis

  $this->link($path,$link);

=head4 Options

=over 4

=item -force => $bool (Default: 0)

Lösche die Datei $link, falls sie bereits existiert.

=back

=head4 Description

Erzeuge einen Hardlink $link auf Pfad $path.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub link {
    my $this = shift;

    my $force = 0;

    my $argA = $this->parameters(2,2,\@_,
        -force => \$force,
    );
    my $path = $this->expandTilde(shift @$argA);
    my $link = $this->expandTilde(shift @$argA);

    if (-f $link && $force) {
        $this->delete($link);
    }
    
    CORE::link $path,$link or do {
        $this->throw(
            'FS-00002: Kann Link nicht erzeugen',
            Path => $path,
            Link => $link,
            Error => $!,
        );
    };

    return;
}

# -----------------------------------------------------------------------------

=head3 newlineStr() - Ermittele Zeilentrenner

=head4 Synopsis

  $nl = $class->newlineStr($file);

=head4 Description

Ermittele den physischen Zeilentrenner (CR, LF oder CRLF) der Datei
$file und liefere diesen zurück. Wird kein Zeilentrenner gefunden,
liefere undef.

=head4 Example

  local $/ = Quiq::Path->newlineStr($file);
  
  while (<$fh>) {
      chomp;
      # Zeile verarbeiten
  }

=cut

# -----------------------------------------------------------------------------

sub newlineStr {
    my ($class,$file) = @_;

    my $fh = Quiq::FileHandle->new('<',$file);
    $fh->binmode;

    my $nl;
    while (defined(my $c = getc $fh)) {
        if ($c eq "\cM") {
            $c = getc $fh;
            if (defined($c) && $c eq "\cJ") {
                $nl = "\cM\cJ";
                last;
            }
            $nl = "\cM";
            last;
        }
        elsif ($c eq "\cJ") {
            $nl = "\cJ";
            last;
        }
    }
    $fh->close;

    return $nl;
}

# -----------------------------------------------------------------------------

=head3 nextFile() - Generiere nächsten Dateinamen

=head4 Synopsis

  $file = $this->nextFile($name,$n,$ext);

=head4 Arguments

=over 4

=item $name

Grundname der Datei. Kann leer (Leerstring oder C<undef>) sein,
dann besteht der Dateiname nur aus aus der laufenden Nummer.

=item $n

Anzahl der Stellen der laufenden Nummer.

=item $ext

Extension der Datei. Kann leer (Leerstring oder C<undef>) sein.

=back

=head4 Description

Ermittele und liefere den nächsten Namen einer Datei. Der Dateiname
hat den Aufbau

  NAME-NNNN.EXT

Die laufende Nummer NNNN (deren Breite durch den zweiten Parameter
festgelegt) wird anhand der vorhandenen Dateien im Dateisystem
ermittelt und um 1 erhöht.

=head4 Example

Es liegt noch keine Datei vor:

  $file = Quiq::Path->nextFile('myfile',3,'log');
  =>
  myfile-001.log

Die Datei mit der höchsten Nummer ist myfile-031.log:

  $file = Quiq::Path->nextFile('myfile',3,'log');
  =>
  myfile-032.log

=cut

# -----------------------------------------------------------------------------

sub nextFile {
    my ($this,$name,$n,$ext) = @_;

    my @files = sort $this->glob("$name-*.$ext");
    my $file = $files[-1] // sprintf '%s-%0*d.%s',$name,$n,0,$ext;
    my ($i) = $file =~ /^\Q$name\E-(\d+).\Q$ext\E/;
    $file = sprintf "%s-%0*d.%s",$name,$n,++$i,$ext;
    
    return $file;
}

# -----------------------------------------------------------------------------

=head3 nextNumber() - Generiere nächste Dateinamen-Nummer

=head4 Synopsis

  $num = $this->nextNumber($dir,$width);

=head4 Arguments

=over 4

=item $dir

Verzeichnis mit nummierten Dateien.

=item $width

Anzahl der Stellen der Nummer.

=back

=head4 Returns

Nummer mit der angegebenen Anzahl Stellen, ggf. mit führenden 0en
aufgefüllt.

=head4 Description

Ermittele und liefere die nächste Nummer eines Verzeichnisses mit
nummerierten Dateien. Die Dateinamen haben einen beliebigen
Aufbau, müssen aber eine Nummer mit genau $width Stellen
besitzen. Die laufende Nummer NNNN (deren Breite durch den zweiten
Parameter festgelegt ist) wird anhand der vorhandenen Dateien
im Verzeichnis $dir ermittelt und um 1 erhöht.

=head4 Example

Es liegt noch keine Datei mit einer dreistelligen Nummer NNN vor:

  $num = Quiq::Path->nextNumber($dir,3);
  =>
  001

Die Datei mit der höchsten dreistelligen Nummer NNN enthält 031:

  $num = Quiq::Path->nextNumber($dir,3);
  =>
  032

=cut

# -----------------------------------------------------------------------------

sub nextNumber {
    my ($this,$dir,$width) = @_;

    my $n = 0;
    for my $file ($this->glob("$dir/*")) {
        if ($file =~ /(?:^|\D)(\d{$width})(?:$|\D)/) {
            if ($1 > $n) {
                $n = $1+0;
            }
        }
    }

    return sprintf '%0*d',$width,++$n;
}

# -----------------------------------------------------------------------------

=head3 read() - Lies Datei

=head4 Synopsis

  $data = $class->read($file,@opt);

=head4 Options

=over 4

=item -autoDecode => $bool (Default: 0)

Auto-Dekodiere die gelesenen Daten als Text und entscheide selbständig,
ob es sich um UTF-8 oder ISO-8859-1 Encoding handelt.

=item -decode => $encoding (Default: undef)

Decodiere die Datei gemäß dem Encoding $encoding.

=item -delete => $bool (Default: 0)

Lösche Datei nach dem Lesen.

=item -maxLines => $n (Default: 0)

Lies höchstens $n Zeilen. Die Zählung beginnt nach den
Skiplines (s. Option -skipLines). 0 bedeutet, lies alle Zeilen.

=item -skip => $regex (Default: keiner)

Überlies alle Zeilen, die das Muster $regex erfüllen. $regex
wird als Zeichenkette angegeben. Die Option kann beispielsweise dazu
verwendet werden, um Kommentarzeilen zu überlesen.

=item -skipLines => $n (Default: 0)

Überlies die ersten $n Zeilen.

=item -sloppy => $bool (Default: 0)

Existiert die Datei nicht, liefere C<undef> und wirf keine Exception.

=back

=head4 Description

Lies den Inhalt der Datei und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub read {
    my $class = shift;
    my $file = shift;
    # @_: Optionen

    # Optionen

    my $autoDecode = 0;
    my $decode = undef;
    my $delete = 0;
    my $maxLines = 0;
    my $skip = undef;
    my $skipLines = 0;
    my $sloppy = 0;

    if (@_) {
        Quiq::Option->extract(\@_,
            -autoDecode => \$autoDecode,
            -decode => \$decode,
            -delete => \$delete,
            -maxLines => \$maxLines,
            -skip => \$skip,
            -skipLines => \$skipLines,
            -sloppy => \$sloppy,
        );
    }

    # Datei lesen

    $file = $class->expandTilde($file);
    if ($sloppy && !-e $file) {
        return undef;
    }

    my $fh = Quiq::FileHandle->new('<',$file);

    my $data = '';
    if ($maxLines || $skip || $skipLines) {
        my $i = 0;
        my $j = 0;
        while (<$fh>) {
            next if $skipLines && $i++ < $skipLines;
            last if $maxLines && ++$j > $maxLines;
            next if $skip && /$skip/; # Zeile überlesen
            $data .= $_;
        }
    }
    else {
        local $/ = undef;
        $data = <$fh>;
    }

    $fh->close;

    if ($delete) {
        $class->delete($file);
    }

    if ($decode) {
        $data = Encode::decode($decode,$data);
    }
    elsif ($autoDecode) {
        $data = Quiq::String->autoDecode($data);
    }

    return $data;
}

# -----------------------------------------------------------------------------

=head3 sha1() - SHA1 Hex Digest

=head4 Synopsis

  $this->sha1($file);

=head4 Arguments

=over 4

=item $file

Pfad der Datei.

=back

=head4 Description

Ermittele den SHA1 Hex Digest der Datei $file und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub sha1 {
    my $this = shift;
    my $file = $this->expandTilde(shift);

    my $sha = Digest::SHA->new(1);
    $sha->addfile($file);

    return $sha->hexdigest;;
}

# -----------------------------------------------------------------------------

=head3 size() - Größe der Datei in Bytes

=head4 Synopsis

  $size = $this->size($file);

=head4 Arguments

=over 4

=item $file

Pfad der Datei.

=back

=head4 Description

Ermittele die Größe der Datei in Bytes und liefere diesen Wert zurück.
Im Unterschied zu

  -s $file

führt die Methode eine Tilde-Expansion durch.

=cut

# -----------------------------------------------------------------------------

sub size {
    my $this = shift;
    my $file = $this->expandTilde(shift);

    if (!-f $file) {
        $this->throw(
            'PATH-00099: File not found',
            Path => $file,
        );
    }

    return -s $file;
}

# -----------------------------------------------------------------------------

=head3 tail() - Überwache Datei und gib hinzugefügte Daten kontinuierlich aus

=head4 Synopsis

  $data = $this->tail($file,@opt);

=head4 Arguments

=over 4

=item $file

(String) Pfad der Datei.

=back

=head4 Options

=over 4

=item -offset => $pos (Default: 0)

Beginne die Überwachung bei Datei-Offset $pos.

=item -sleepInterval => $s (Default: 0.1)

Zeitraum, der zwischen den Prüfungen auf Änderung gewartet wird.

=item -timeout => $s (Default: I<überwache unendlich lange>)

Beende die Überwachung der Datei, wenn $s Sekunden (Sekundenbruchteile
erlaubt, z.B. C<0.5>) lang keine Änderung an der Datei erfolgt ist.
Der Werte sollte größer sein als das Sleep Interval (s. C{-sleepInterval).

=back

=head4 Returns

(String) Die während der Überwachung hinzugefügte Daten.

=head4 Description

Überwache Datei $file und gib die am Ende hinzugefügten Daten
kontinuierlich aus. Die Überwachung endet, wenn der Datiinhalt sich
$s Sekunden lang nicht geändert hat (Option C<--timeout>).
Liefere die hinzugefügten Daten zurück.

=cut

# -----------------------------------------------------------------------------

sub tail {
    my $this = shift;
    my $file = $this->expandTilde(shift);

    # Options

    my $offset = 0;
    my $sleepInterval = 0.1;
    my $timeout = undef;

    $this->parameters(\@_,
        -offset => \$offset,
        -timeout => \$timeout,
    );

    my $str = '';
    my $lastChange = Time::HiRes::gettimeofday;
    while (1) {
        my $size = -s $file;
        if ($size > $offset) {
            my $fh = Quiq::FileHandle->new('<',$file);
            $fh->seek($offset);
            $fh->setEncoding('UTF-8');
            my $data = $fh->slurp;
            $str .= $data;
            print $data;
            $offset = $fh->tell;
            $fh->close;
            $lastChange = Time::HiRes::gettimeofday;
        }
        elsif (defined $timeout) {
            my $now = Time::HiRes::gettimeofday;
            if ($now-$lastChange > $timeout) {
                last; # Ende der Überwachung
            }
        }
        Time::HiRes::usleep(int $sleepInterval*1000_000);
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head3 truncate() - Kürze Datei

=head4 Synopsis

  $this->truncate($file);

=head4 Arguments

=over 4

=item $file

Pfad der Datei.

=back

=head4 Description

Kürze Datei $file auf Länge 0, falls sie existiert. Existiert die
Datei nicht, geschieht nichts.

=cut

# -----------------------------------------------------------------------------

sub truncate {
    my $this = shift;
    my $file = $this->expandTilde(shift);

    if ($this->exists($file)) {
        Quiq::FileHandle->new('>',$file)->truncate;
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 tempFile() - Erzeuge temporäre Datei

=head4 Synopsis

  $file = $this->tempFile(@opt);
  $file = $this->tempFile($data,@opt);

=head4 Arguments

Daten, die in die temporäre Datei geschrieben werden.

=head4 Options

Siehe Quiq::TempFile->new().

=head4 Returns

=over 4

=item $file

Tempdatei-Objekt

=back

=head4 Description

Erzeuge eine temporäre Datei, beschreibe sie mit den Daten $data und
liefere eine Referenz auf das Objekt zurück.

=head4 See Also

Quiq::TempFile

=cut

# -----------------------------------------------------------------------------

sub tempFile {
    my $this = shift;
    return Quiq::TempFile->new(@_);
}

# -----------------------------------------------------------------------------

=head3 unindent() - Entferne Einrückung

=head4 Synopsis

  $this->unindent($file);

=head4 Arguments

=over 4

=item $file

Pfad der Datei.

=back

=head4 Description

Lies den Inhalt der Datei $file, entferne dessen Einrückung (per
Quiq::Unindent->hereDoc) und schreibe den uneingerückten Inhalt auf
die Datei zurück. Besitzt der Dateiinhalt keine Einrückung, findet keine
Änderung des Dateiinhalts statt.

=cut

# -----------------------------------------------------------------------------

sub unindent {
    my ($this,$file) = @_;

    my $data1 = $this->read($file);
    my $data2 = Quiq::Unindent->hereDoc($data1);
    if ($data1 ne $data2) {
        $this->write($file,$data2);
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 write() - Schreibe Datei

=head4 Synopsis

  $class->write($file); # leere Datei
  $class->write($file,$data,@opt);
  $class->write($file,\$data,@opt);

=head4 Options

=over 4

=item -append => $bool (Default: 0)

Öffne die Datei im Append-Modus, d.h. hänge die Daten an die Datei an.

=item -encode => $encoding (Default: keiner)

Encodiere $data gemäß dem Encoding $encoding.

=item -lock => $bool (Default: 0)

Setze während des Schreibens einen Exclusive-Lock auf die Datei.
Dies kann im Falle von -append sinnvoll sein.

=item -log => $stream (Default: undef)

Schreibe Meldung auf Dateihandle. Beispiel:

  -log => \*STDOUT

=item -mode => $mode (Default: keiner)

Setze die Permissions der Datei auf $mode. Beispiel: -mode=>0775

=item -recursive => $bool (Default: 1)

Erzeuge übergeordnete Verzeichnisse, wenn nötig.

=item -unindent => $bool (Default: 0)

Wende Quiq::Unindent->trimNl() auf die Daten $data an. Dies ist für
inline geschriebenen Text nützlich.

=back

=cut

# -----------------------------------------------------------------------------

sub write {
    my $class = shift;
    my $file = shift;
    my $data = shift;
    # @_: @opt

    # Optionen

    my $append = 0;
    my $encode = undef;
    my $lock = 0;
    my $log = undef;
    my $mode = undef;
    my $recursive = 1;
    my $unindent = 0;

    if (@_) {
        Quiq::Option->extract(\@_,
            -append => \$append,
            -encode => \$encode,
            -lock => \$lock,
            -log => \$log,
            -mode => \$mode,
            -recursive => \$recursive,
            -unindent => \$unindent,
        );
    }

    my $ref = ref $data? $data: \$data;

    # Tilde-Expansion
    $file = $class->expandTilde($file);

    # Erzeuge Verzeichnis, wenn nötig

    if ($recursive) {
        my $dir = ($class->split($file))[0];
        if ($dir && !-d $dir) {
            $class->mkdir($dir,-recursive=>1);
        }
    }

    my $flags = Fcntl::O_WRONLY|Fcntl::O_CREAT;
    $flags |= $append? Fcntl::O_APPEND: Fcntl::O_TRUNC;

    local *F;
    sysopen(F,$file,$flags) || do {
        $class->throw(
            'PATH-00006: Datei kann nicht zum Schreiben geöffnet werden',
            Path => $file,
            Error => "$!",
        );
    };

    if ($lock) {
        flock(F,Fcntl::LOCK_EX) || do {
            $class->throw(
                'PATH-00099: Can\'t get exclusive lock',
                Path => $file,
                Error => "$!",
            );
        };
    }

    if ($encode) {
        Quiq::Perl->binmode(*F,":encoding($encode)");
    }

    # Wenn keine Daten zu schreiben sind, print auslassen,
    # da sonst eine Exception ausgelöst wird.

    if (defined($$ref) && $$ref ne '') {
        # Unindent

        if ($unindent) {
            $$ref = Quiq::Unindent->trimNl($$ref);
        }

        print F $$ref or do {
            my $errStr = "$!";
            close F;
            $class->throw(
                'PATH-00007: Schreiben auf Datei fehlgeschlagen',
                Path => $file,
                Error => $errStr,
            );
        };

        if ($log) {
            print $log "$file written\n";
        }
    }

    close F;

    if (defined $mode) {
        # Permissions setzen
        $class->chmod($file,$mode);
    }
    
    return;
}

# -----------------------------------------------------------------------------

=head3 writeIfDifferent() - Schreibe Datei, wenn Inhalt differiert

=head4 Synopsis

  $class->writeIfDifferent($file,$data);

=cut

# -----------------------------------------------------------------------------

sub writeIfDifferent {
    my $class = shift;
    my $file = shift;
    # @_: $data

    if ($class->compareData($file,$_[0])) {
        $class->write($file,$_[0]);
        return 1;
    }

    return 0;
}

# -----------------------------------------------------------------------------

=head3 writeInline() - Schreibe Inline-Daten in Datei

=head4 Synopsis

  $class->writeInline($file,<<'__EOT__',@opt);
  DATA
  ...
  __EOT__

=cut

# -----------------------------------------------------------------------------

sub writeInline {
    my ($class,$file,$data) = splice @_,0,3;
    # @_: @opt

    $data = Quiq::Unindent->hereDoc($data);
    $class->write($file,$data,@_);
    
    return;
}

# -----------------------------------------------------------------------------

=head2 Verzeichnis-Operationen

=head3 count() - Anzahl der Verzeichniseinträge

=head4 Synopsis

  $n = $this->count($dir);

=head4 Arguments

=over 4

=item $dir

Pfad des Verzeichnisses.

=back

=head4 Returns

Anzahl Verzeichniseinträge (Integer)

=head4 Description

Ermittele die Anzahl Einträge des Verzeichnisses $dir und liefere diese
zurück. Die Einträge C<.> und C<..> werden I<nicht> mitgezählt.

=cut

# -----------------------------------------------------------------------------

sub count {
    my $this = shift;
    my $dir = $this->expandTilde(shift);

    my $n = 0;
    my $dh = Quiq::DirHandle->new($dir);
    while (my $entry = $dh->next) {
        if ($entry eq '.' || $entry eq '..') {
            next;
        }
        $n++;
    }
    $dh->close;

    return $n;
}

# -----------------------------------------------------------------------------

=head3 deleteContent() - Lösche Inhalt des Verzeichnis

=head4 Synopsis

  $this->deleteContent($dir);

=head4 Arguments

=over 4

=item $dir

Pfad des Verzeichnisses

=back

=head4 Description

Lösche den Inhalt des Verzeichnisses $dir.

=cut

# -----------------------------------------------------------------------------

sub deleteContent {
    my ($this,$dir) = @_;

    for my $entry ($this->entries($dir)) {
        $this->delete("$dir/$entry");
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 entries() - Liste der Verzeichniseinträge

=head4 Synopsis

  @paths | $pathA = $this->entries($dir,@opt);

=head4 Arguments

=over 4

=item $dir

Pfad des Verzeichnisses.

=back

=head4 Options

=over 4

=item -encoding => $charset (Default: 'utf-8')

Dekodiere die Verzeichniseinträge gemäß Zeichensatz $charset.

=back

=head4 Returns

Liste der Verzeichniseinträge (Array of Strings). Im Skalarkontext
eine Referenz auf die Liste.

=head4 Description

Ermittele die Einträge des Verzeichnisses $dir und liefere diese
als Liste zurück. Die Liste umfasst alle Verzeichniseinträge
außer "." und "..".

=cut

# -----------------------------------------------------------------------------

sub entries {
    my $this = shift;
    # @_: $dir,@opt

    # Options

    my $encoding = 'utf-8';

    my $argA = $this->parameters(1,1,\@_,
        -encoding => \$encoding,
    );
    my $dir = $this->expandTilde(shift @$argA);

    # Operation ausführen

    my @arr;
    my $dh = Quiq::DirHandle->new($dir);
    while (my $entry = $dh->next) {
        if ($entry eq '.' || $entry eq '..') {
            next;
        }
        push @arr,$encoding? Encode::decode($encoding,$entry): $entry;
    }
    $dh->close;

    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head3 find() - Liefere Pfade innerhalb eines Verzeichnisses

=head4 Synopsis

  @paths|$pathA = $class->find($path,@opt);

=head4 Options

=over 4

=item -decode => $encoding

Dekodiere die Dateinamen gemäß dem angegebenen Encoding.

=item -exclude => $regex (Default: keiner)

Schließe alle Pfade aus, die Muster $regex erfüllen. Directories
werden gepruned, d.h. sie werden nicht durchsucht. Matcht ein Pfad
die Pattern sowohl von -pattern als auch -exclude, hat der
exclude-Pattern Vorrang, d.h. die Datei wird ausgeschlossen.

=item -excludeRoot => $bool (Default: 0)

Nimm das Wurzelverzeichnis $path nicht in die Pfadliste mit auf.

=item -follow => $bool (Default: 1)

Folge Symbolic Links.

=item -followSkip => $val (Default: 2)

Definiert, was geschehen soll, wenn einem Symbolischen Link
ein zweites Mal gefolgt wird. Siehe Doku.

=item -leavesOnly => $bool (Default: 0)

Liefere nur Pfade, die kein Anfang eines anderen Pfads sind.
Anwendungsfall: nur die Blatt-Verzeichnisse eines Verzeichnisbaums.

=item -olderThan => $seconds (Default: 0)

Liefere nur Dateien, die vor mindestens $seconds zuletzt geändert
wurden. Diese Option ist z.B. nützlich, um veraltete temporäre Dateien
zu finden.

=item -outHandle => $fh (Default: \*STDOUT)

Filehandle, auf die die Ausgabe im Falle von -verbose=>1 geschrieben
werden.

=item -pattern => $regex (Default: keiner)

Schränke die Treffer auf jene Pfade ein, die Muster $regex
erfüllen.  Matcht ein Pfad die Pattern sowohl von -pattern als
auch -exclude, hat der exclude-Pattern Vorrang, d.h. die Datei
wird ausgeschlossen.

=item -slash => $bool (Default: 0)

Füge einen Slash (/) am Ende von Directory-Namen hinzu.

=item -sloppy => $bool (Default: 0)

Wirf keine Exception, wenn $path nicht existiert, sondern liefere
undef bzw. eine leere Liste.

=item -sort = $bool (Default: 0)

Sortiere die Pfade alphanumerisch.

=item -subPath => $bool (Default: 0)

Liefere nur den Subpfad, entferne also $path am Anfang.

=item -testSub => sub {} (Default: undef)

Subroutine, die den Pfad als Argument erhält und einen boolschen
Wert liefert, der angibt, ob der Pfad zur Ergebnismenge gehört
oder nicht.

=item -type => 'd' | 'f' | undef (Default: undef)

Liefere nur Verzeichnisse ('d') oder nur, was kein Verzeichnis ist ('f'),
oder liefere alles (undef).

=item -verbose => $bool (Default: 0)

Schreibe Meldungen auf Ausgabe-Handle (s. Option -outHandle).

=back

=head4 Description

Finde alle Dateien und Verzeichnisse unterhalb von und einschließlich
Verzeichnis $path und liefere die Liste der gefundenen Pfade
zurück. Im Skalarkontext liefere eine Referenz auf die Liste.

Ist $dir Null (Leerstring oder undef), wird das aktuelle Verzeichnis
('.') durchsucht.

Die Reihenfolge der Dateien ist undefiniert.

=cut

# -----------------------------------------------------------------------------

sub find {
    my $class = shift;
    my $dir = $class->expandTilde(shift);
    # @_: @opt

    # Optionen

    my $decode = undef;
    my $exclude = undef;
    my $excludeRoot = 0;
    my $follow = 1;
    my $followSkip = 2;
    my $leavesOnly = 0;
    my $olderThan = 0;
    my $outHandle = \*STDOUT;
    my $pattern = undef;
    my $slash = 0;
    my $sloppy = 0;
    my $sort = 0;
    my $subPath = 0;
    my $testSub = undef;
    my $type = undef;
    my $verbose = 0;

    if (@_) {
        Quiq::Option->extract(\@_,
            -decode => \$decode,
            -exclude => \$exclude,
            -excludeRoot => \$excludeRoot,
            -follow => \$follow,
            -followSkip => \$followSkip,
            -leavesOnly => \$leavesOnly,
            -olderThan => \$olderThan,
            -outHandle => \$outHandle,
            -pattern => \$pattern,
            -slash => \$slash,
            -sloppy => \$sloppy,
            -sort => \$sort,
            -subPath => \$subPath,
            -testSub => \$testSub,
            -type => \$type,
            -verbose => \$verbose,
        );
    }

    # Parameter-Tests

    if (!defined $dir || $dir eq '') {
        $dir = '.';
    }
    elsif (!-e $dir) {
        if ($sloppy) {
            return wantarray? (): undef;
        }
        $class->throw('PATH-00011: Verzeichnis existiert nicht',
            Dir => $dir,
        );
    }
    elsif (!-d $dir) {
        $class->throw('PATH-00013: Pfad ist kein Verzeichnis',
            Path => $dir,
        );
    }

    # Liste der Pfade
    my @paths;

    # Zeitpunkt der Suche (für Zeitvergleich bei -olderThan)
    my $time = time;

    my $sub = sub {
        $File::Find::name =~ s|^\./||; # ./ am Anfang entfernen

        if ($excludeRoot && $File::Find::name eq $dir) {
            return;
        }

        if ($exclude && $File::Find::name =~ /$exclude/) {
            if (-d) {
                # warn "PRUNE: $File::Find::name\n";
                $File::Find::prune = 1;
            }
            return;
        }

        if ($pattern && $File::Find::name !~ /$pattern/) {
            return;
        }

        if ($type || $slash || $olderThan) {
            # Test muss auf $_ erfolgen, da abgestiegen wird!
            my $isDir = -d;

            if ($type) {
                if ($type eq 'd' && !$isDir || $type eq 'f' && $isDir) {
                    return;
                }
            }
            if ($olderThan) { 
                # Datei ist jünger als $olderThan Sekunden
                return if (stat $File::Find::name)[9] > $time-$olderThan;
            }
            if ($slash && $isDir) {
                $File::Find::name .= '/';
            }       
        }

        if ($testSub && !$testSub->($File::Find::name)) {
            return;
        }

        if ($subPath) {
            # Pfadanfang entfernen
            $File::Find::name =~ s|^\Q$dir/||;
        }

        # $File::Find::name =~ s|^\./||; # ./ am Anfang entfernen

        if ($verbose) {
            print $outHandle $File::Find::name,"\n";
        }

        if ($decode) {
            push @paths,Encode::decode($decode,$File::Find::name);
        }
        else {
            push @paths,$File::Find::name;
        }
    };
    File::Find::find({
            wanted=>$sub,
            follow=>$follow,
            follow_skip=>$followSkip,
        },$dir);

    if ($leavesOnly) {
        my @arr;
        for (my $i = 0; $i < @paths; $i++) {
            my $ok = 1;
            for (my $j = 0; $j < @paths; $j++) {
                if ($j != $i && index($paths[$j],$paths[$i]) == 0) {
                    $ok = 0;
                    last;
                }
            }
            if ($ok) {
                push @arr,$paths[$i];
            }
        }
        @paths = @arr;
    }

    if ($sort) {
        @paths = sort @paths;
    }

    return wantarray? @paths: \@paths;
}

# -----------------------------------------------------------------------------

=head3 findProgram() - Ermittele Pfad zu Programm

=head4 Synopsis

  $path = $class->findProgram($program);
  $path = $class->findProgram($program,$sloppy);

=head4 Arguments

=over 4

=item $program

Name des Programms.

=item $sloppy

Wenn wahr, wird keine Exception geworfen, wenn das Programm nicht
gefunden wird, sondern undef zurück geliefert.

=back

=head4 Returns

Programmpfad (String)

=head4 Description

Suche Programm $program über den Suchpfad der Shell und liefere
den vollständigen Pfad zurück. Wird das Programm nicht gefunden,
wird eine Exception geworfen.

=cut

# -----------------------------------------------------------------------------

sub findProgram {
    my ($class,$program,$sloppy) = @_;

    # FIXME: PATH selbst absuchen

    my $cmd = "which $program 2>/dev/null";
    my $path = qx/$cmd/;
    chomp $path;
    if (!$sloppy) {
        # Quiq::Shell->checkError($?,$!,$cmd);
        Quiq::Exit->check($?,$cmd);
    }

    return $path eq ''? undef: $path;
}

# -----------------------------------------------------------------------------

=head3 maxFilename() - Liefere den lexikalisch größten Dateinamen

=head4 Synopsis

  $max = $class->maxFilename($dir);

=head4 Description

Liefere den lexikalisch größten Dateinamen aus Verzeichnis $dir.

=cut

# -----------------------------------------------------------------------------

sub maxFilename {
    my ($class,$dir) = @_;

    my $max;
    my $dh = Quiq::DirHandle->new($dir);
    while (my $file = $dh->next) {
        if ($file eq '.' || $file eq '..') {
            next;
        }
        if (!defined($max) || $file gt $max) {
            $max = $file;
        }
    }
    $dh->close;

    return $max;
}

# -----------------------------------------------------------------------------

=head3 maxFileNumber() - Liefere den numerisch größten Dateinamen

=head4 Synopsis

  $max = $class->maxFileNumber($dir,@opt);

=head4 Options

=over 4

=item -sloppy => $bool (Default: 0)

Wirf keine Exception, wenn ein Dateiname nicht mit einer Nummer
beginnt.

=back

=head4 Description

Liefere den numerisch größten Dateinamen aus Verzeichnis $dir.
Die Methode ist nützlich, wenn die Dateinamen mit einer Zahl
NNNNNN beginnen und man die Datei mit der größten Zahl ermitteln
möchte um einer neu erzeugten Datei die nächsthöhere Nummer
zuzuweisen.

=cut

# -----------------------------------------------------------------------------

sub maxFileNumber {
    my ($class,$dir) = splice @_,0,2;
    # @_: @opt

    # Options

    my $sloppy = 0;
    
    Quiq::Option->extract(\@_,
        -sloppy => \$sloppy,
    );

    # Verarbeitung
    
    my $max = 0;
    my $dh = Quiq::DirHandle->new($dir);
    while (my $file = $dh->next) {
        if ($file eq '.' || $file eq '..') {
            next;
        }
        my ($n) = $file =~ /^(\d+)/;
        if (!defined($n)) {
            if ($sloppy) {
                next;
            }
            $class->throw(
                'PATH-00099: Dateiname beginnt nicht mit Ziffernfolge',
                File => $file,
            );
        }
        if ($n+0 > $max) {
            $max = $n+0;
        }
    }
    $dh->close;

    return $max;
}

# -----------------------------------------------------------------------------

=head3 minFileNumber() - Liefere den numerisch größten Dateinamen

=head4 Synopsis

  $min = $class->minFileNumber($dir,$max,@opt);

=head4 Arguments

=over 4

=item $dir

Pfad des Verzeichnisses

=item $max

Der Wert, mit dem die Zählung beginnt.

=back

=head4 Options

=over 4

=item -sloppy => $bool (Default: 0)

Wirf keine Exception, wenn ein Dateiname nicht mit einer Nummer
beginnt.

=back

=head4 Description

Liefere den numerisch kleinsten Dateinamen aus Verzeichnis $dir.
Die Methode ist nützlich, wenn die Dateinamen mit einer Zahl
NNNNNN beginnen und man die Datei mit der kleinsten Zahl ermitteln
möchte um einer neu erzeugten Datei die nächstniedrigere Nummer
zuzuweisen.

=cut

# -----------------------------------------------------------------------------

sub minFileNumber {
    my ($class,$dir,$max) = splice @_,0,3;
    # @_: @opt

    # Options

    my $sloppy = 0;
    
    Quiq::Option->extract(\@_,
        -sloppy => \$sloppy,
    );

    # Verarbeitung

    my $min = $max;
    my $dh = Quiq::DirHandle->new($dir);
    while (my $file = $dh->next) {
        if ($file eq '.' || $file eq '..') {
            next;
        }
        my ($n) = $file =~ /^(\d+)/;
        if (!defined($n)) {
            if ($sloppy) {
                next;
            }
            $class->throw(
                'PATH-00099: Dateiname beginnt nicht mit Ziffernfolge',
                File => $file,
            );
        }
        if ($n+0 < $min) {
            $min = $n+0;
        }
    }
    $dh->close;

    return $min;
}

# -----------------------------------------------------------------------------

=head3 mkdir() - Erzeuge Verzeichnis

=head4 Synopsis

  $dir = $class->mkdir($dir,@opt);

=head4 Options

=over 4

=item -createParent => $bool (Default: 0)

Erzeuge nicht den angegebenen Pfad, sondern den Parent-Pfad.
Dies ist nützlich, wenn der übergebene Pfad ein Dateiname ist,
dessen Verzeichnis bei Nicht-Existenz erzeugt werden soll.
Impliziert -recursive=>1, wenn nicht explizit -recursive=>0
gesetzt ist.

=item -forceMode => $mode (Default: keiner)

Setze Verzeichnisrechte auf $mode ohne Berücksichtigung
der umask des Prozesses.

=item -mode => $mode (Default: 0775)

Setze Verzeichnisrechte auf $mode mit Berücksichtigung
der umask des Prozesses.

=item -mustNotExist => $bool (Default: 0)

Das Verzeichnis darf nicht existieren. Wenn es existiert, wird
eine Exception geworfen.

=item -recursive => 0 | 1 (Default: 0)

Erzeuge übergeordnete Verzeichnisse, wenn nötig.

=back

=head4 Returns

(String) Pfad des erzeugten Verzeichnisses.

=head4 Description

Erzeuge Verzeichnis $dir. Existiert das Verzeichnis bereits, hat
der Aufruf keinen Effekt. Kann das Verzeichnis nicht angelegt
werden, wird eine Exception ausgelöst.

=cut

# -----------------------------------------------------------------------------

sub mkdir {
    my $class = shift;
    my $dir = $class->expandTilde(shift);
    # @_: @opt

    my $createParent = 0;
    my $forceMode = undef;
    my $mode = 0755;
    my $mustNotExist = 0;
    my $recursive = undef;

    if (@_) {
        Quiq::Option->extract(-dontExtract=>1,\@_,
            -createParent => \$createParent,
            -forceMode => \$forceMode,
            -mode => \$mode,
            -mustNotExist => \$mustNotExist,
            -recursive => \$recursive,
        );
    }

    if ($createParent) {
        ($dir) = $class->split($dir);
        if (!defined $recursive) {
            $recursive = 1;
        }
    }

    return $dir if !defined($dir) || $dir eq '';

    if (-d $dir) {
        if ($mustNotExist) {
            $class->throw(
                'PATH-00005: Verzeichnis existiert bereits',
                Dir => $dir,
            );
        }    
        return $dir;
    }

    if ($recursive) {
        my ($parentDir) = $class->split($dir);
        $class->mkdir($parentDir,
            @_,
            -createParent => 0,
            -mustNotExist => 0,
            -recursive => 1,
        );
    }

    if (-d $dir) {
        # Hack, damit rekursiv erzeugte Pfade wie /tmp/a/b/c/..
        # angelegt werden können. Ohne diesen zusätzlichen
        # Existenz-Test schlägt sonst das folgende mkdir fehl.
        return $dir;
    }

    CORE::mkdir($dir,$mode) || do {
        $class->throw(
            'PATH-00004: Kann Verzeichnis nicht erzeugen',
            Path => $dir,
        );
    };

    if ($forceMode) {
        $class->chmod($dir,$forceMode);
    }

    return $dir;
}

# -----------------------------------------------------------------------------

=head3 mtimeDir() - Jüngste Modifikationszeit

=head4 Synopsis

  $mtime = $this->mtimeDir($dir);

=head4 Arguments

=over 4

=item $dir

Pfad des Verzeichnisses.

=back

=head4 Returns

Zeit in Unix Epoch (Integer)

=head4 Description

Ermittele über allen Pfaden in und einschließlch $dir den jüngsten
Modifikationszeitpunkt (mtime) und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub mtimeDir {
    my ($this,$dir) = @_;

    my $mtime = 0;
    for my $path ($this->find($dir)) {
        my $time = $this->mtime($path);
        if ($time > $mtime) {
            $mtime = $time;
        }
    }

    return $mtime;
}

# -----------------------------------------------------------------------------

=head3 rmdir() - Lösche Verzeichnis

=head4 Synopsis

  $class->rmdir($dir);

=head4 Arguments

=over 4

=item $dir

Pfad des Verzeichnisses

=back

=head4 Returns

nichts

=head4 Description

Lösche Verzeichnis $dir, falls dieses leer ist. Kann das
Verzeichnis nicht gelöscht werden, wird eine Exception ausgelöst.

=cut

# -----------------------------------------------------------------------------

sub rmdir {
    my $class = shift;
    my $dir = shift;

    CORE::rmdir($dir) || do {
        $class->throw(
            'PATH-00005: Verzeichnis kann nicht gelöscht werden',
            Path => $dir,
        );
    };

    return;
}

# -----------------------------------------------------------------------------

=head3 tempDir() - Erzeuge temporäres Verzeichnis

=head4 Synopsis

  $dir = $this->tempDir(@opt);

=head4 Options

I<< siehe Quiq::TempDir >>

=head4 Returns

=over 4

=item $dir

Tempdir-Objekt

=back

=head4 Description

Erzeuge ein temporäres Verzeichnis und liefere eine Referenz auf
das Objekt zurück.

=head4 See Also

Quiq::TempDir

=cut

# -----------------------------------------------------------------------------

sub tempDir {
    my $this = shift;
    return Quiq::TempDir->new(@_);
}

# -----------------------------------------------------------------------------

=head2 Pfad-Operationen

=head3 absolute() - Expandiere Pfad zu absolutem Pfad

=head4 Synopsis

  $absolutePath = $this->absolute($path);

=head4 Alias

realPath()

=head4 Description

Ist $path ein relativer Pfad, expandiere ihn zu einem absolutem Pfad
und liefere diesen zurück. Ist $path bereits absolut, liefere ihn
unverändert.

=cut

# -----------------------------------------------------------------------------

sub absolute {
    my $this = shift;
    my $path = shift // '';

    $path = $this->expandTilde($path);
    return Cwd::realpath($path);
}

{
    no warnings 'once';
    *realPath = \&absolute;
}

# -----------------------------------------------------------------------------

=head3 age() - Alter der letzten Modifikation

=head4 Synopsis

  $duration = $this->age($path);

=head4 Arguments

=over 4

=item $path

Pfad.

=back

=head4 Returns

Anzahl Sekunden (Integer)

=head4 Description

Ermittele das Alter der letzten Modifiktion des Pfad-Objekts in
Sekunden und liefere diesen Wert zurück. Existiert der Pfad nicht,
wird eine Exception geworfen.

=cut

# -----------------------------------------------------------------------------

sub age {
    my $this = shift;
    my $path = $this->expandTilde(shift);

    if (!-e $path) {
        $this->throw(
            'PATH-00099: Path does not exist',
            Path => $path,
        );
    }

    return time-$this->mtime($path);
}

# -----------------------------------------------------------------------------

=head3 basename() - Grundname eines Pfads

=head4 Synopsis

  $basename = $class->basename($path,@opt);

=head4 Alias

baseName()

=head4 Options

=over 4

=item -all => $bool (Default: 0)

Entferne alle, nicht nur die erste Extension.

=back

=head4 Description

Liefere den Grundnamen des Pfads, d.h. ohne Pfadanfang und Extension.

=cut

# -----------------------------------------------------------------------------

sub basename {
    my $class = shift;
    my $path = shift;

    # Optionen

    my $all = 0;

    if (@_) {
        Quiq::Option->extract(\@_,
            -all => \$all,
        );
    }

    my $basename = ($class->split($path))[2];
    if ($all) {
        $basename =~ s/\..*//;
    }

    return $basename;
}

{
    no warnings 'once';
    *baseName = \&basename;
}

# -----------------------------------------------------------------------------

=head3 basePath() - Pfad ohne Extension

=head4 Synopsis

  $basePath = $class->basePath($path);

=head4 Description

Entferne eine etwaig vorhandene Extension von $path und liefere das
Resultat zurück.

=cut

# -----------------------------------------------------------------------------

sub basePath {
    my ($class,$path) = @_;
    $path =~ s/\.([^.]+)$//;
    return $path;
}

# -----------------------------------------------------------------------------

=head3 chmod() - Setze Zugriffsrechte

=head4 Synopsis

  $this->chmod($path,$mode);

=head4 Description

Setze Zugriffsrechte $mode auf Pfad $path.

=cut

# -----------------------------------------------------------------------------

sub chmod {
    my $this = shift;
    my $path = $this->expandTilde(shift);
    my $mode = shift;

    CORE::chmod $mode,$path or do {
        $this->throw(
            'PATH-00003: Setzen von Zugriffsrechten fehlgeschlagen',
            Path => $path,
            Mode => $mode,
        );
    };

    return;
}

# -----------------------------------------------------------------------------

=head3 delete() - Lösche Pfad (rekursiv)

=head4 Synopsis

  $this->delete($path);

=head4 Options

=over 4

=item -sloppy => $bool (Default: 0)

Wirf keine Exception, wenn das Verzeichnis oder die Datei nicht
gelöscht werden kann.

=back

=head4 Description

Lösche den Pfad aus dem Dateisystem, also die Datei oder das Verzeichnis
einschließlich Inhalt. Es ist kein Fehler, wenn der Pfad nicht existiert.

=cut

# -----------------------------------------------------------------------------

sub delete {
    my $this = shift;
    my $path = $this->expandTilde(shift);

    # Options

    my $sloppy = 0;
    
    Quiq::Option->extract(\@_,
        -sloppy => \$sloppy,
    );

    # Operation ausführen

    if (!defined($path) || $path eq '' || !-e $path && !-l $path) {
        # Bei Nichtexistenz nichts tun, aber nur, wenn es
        # kein Symlink ist. Bei Symlinks schlägt -e fehl, wenn
        # das Ziel nicht existiert!
    }
    elsif (-d $path) {
        # Verzeichnis löschen
        (my $dir = $path) =~ s/'/\\'/g; # ' quoten
        # eval {Quiq::Shell->exec("/bin/rm -r --interactive=never".
        #     " '$dir' >/dev/null 2>&1")};
        eval {Quiq::Shell->exec("/bin/rm -r '$dir' >/dev/null 2>&1")};
        if ($@ && !$sloppy) {
            $this->throw(
                'PATH-00002: Can\'t delete directory',
                Error => $@,
                Path => $path,
            );
        }
    }
    else {
        # Datei löschen
        if (!CORE::unlink($path) && !$sloppy) {
            $this->throw(
                'PATH-00003: Can\'t delete file',
                Path => $path,
            );
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 dir() - Pfad ohne letzten Bestandteil

=head4 Synopsis

  $dir = $class->dir($path);

=head4 Returns

String

=head4 Description

Entferne den letzten Pfadbestandteil von $path und liefere
den Rest zurück. Enthält $path keinen Slash (/), wird ein Leerstring
geliefert.

=cut

# -----------------------------------------------------------------------------

sub dir {
    my ($class,$path) = @_;
    return $path =~ m|(.*)/|? $1: '';
}

# -----------------------------------------------------------------------------

=head3 exists() - Prüfe Existenz

=head4 Synopsis

  $bool = $this->exists($path);

=head4 Description

Prüfe, ob Pfad $path existiert und liefere den entsprechenden
Wahrheitswert zurück. Die Methode expandiert ~ am Pfadanfang.

=cut

# -----------------------------------------------------------------------------

sub exists {
    my ($this,$path) = @_;
    return -e $this->expandTilde($path)? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 expandTilde() - Expandiere Tilde

=head4 Synopsis

  $path = $class->expandTilde($path);

=head4 Returns

Pfad (String)

=head4 Description

Ersetze eine Tilde am Pfadanfang durch das Home-Verzeichnis des
Benutzers und liefere den resultierenden Pfad zurück.

=cut

# -----------------------------------------------------------------------------

sub expandTilde {
    my ($class,$path) = @_;

    # Unter einem Daemon ist $HOME typischerweise nicht gesetzt, daher
    # prüfen wir zunächst, ob wir $HOME überhaupt expandieren müssen

    if ($path && substr($path,0,1) eq '~') {
        if (!exists $ENV{'HOME'}) {
            $class->throw(
                'PATH-00016: Envvar HOME does not exist',
            );
        }
        substr($path,0,1) = $ENV{'HOME'};
    }
    
    return $path;
}

# -----------------------------------------------------------------------------

=head3 extension() - Extension des Pfads

=head4 Synopsis

  $ext = $class->extension($path);

=head4 Description

Ermittele die Extension des Pfads $path und liefere diese zurück.
Besitzt der Pfad keine Extension, liefere einen Leerstring ('').

=cut

# -----------------------------------------------------------------------------

sub extension {
    my ($class,$path) = @_;
    return $path =~ /\.([^.]+)$/? $1: '';
}

# -----------------------------------------------------------------------------

=head3 filename() - Letzte Pfadkomponente

=head4 Synopsis

  $filename = $class->filename($path);

=head4 Alias

lastName()

=head4 Description

Liefere die letzte Komponente des Pfads.

=cut

# -----------------------------------------------------------------------------

sub filename {
    my ($class,$path) = @_;
    $path =~ s|.*/||;
    return $path;
}

{
    no warnings 'once';
    *lastName = \&filename;
}

# -----------------------------------------------------------------------------

=head3 getFirst() - Liefere ersten existenten Pfad

=head4 Synopsis

  $path = $this->getFirst(@patterns);

=head4 Arguments

=over 4

=item @patterns

Liste an Shell-Patterns (wie sie glob() erwartet)

=back

=head4 Description

Durchlaufe die Pfad-Pattern @patterns und liefere den ersten existenten
Pfad zurück. Ist I<kein> Pattern erfüllt oder erfüllt ein Pattern
I<mehrere> Pfade, wirf eine Exception.

=cut

# -----------------------------------------------------------------------------

sub getFirst {
    my $this = shift;

    # Argumente und Optionen

    my $sloppy = 0;

    my $argA = $this->parameters(1,undef,\@_,
        -sloppy => \$sloppy,
    );
    # @$argA MEMO: Hier ist keine Tilde-Expansion nötig

    # Operation ausführen

    for my $pattern (@$argA) {
        my @paths = CORE::glob $pattern;
        if (@paths == 1 && $this->exists($paths[0])) {
            return $paths[0];
        }
        elsif (@paths > 1) {
            $this->throw(
                'PATH-00099: Pattern matches more than one path',
                Pattern => $pattern,
                Paths => join(', ',@paths),
            );
        }
    }

    if (!$sloppy) {
        $this->throw(
            'PATH-00099: No pattern matches a path',
            Patterns => join(', ',@_),
        );
    }

    return undef;
}

# -----------------------------------------------------------------------------

=head3 glob() - Liefere Pfade, die Shell-Pattern erfüllen

=head4 Synopsis

  $path = $this->glob($pat);
  @paths = $this->glob($pat);

=head4 Description

Liefere die Pfad-Objekte, die Shell-Pattern $pat erfüllen.
Im Skalarkontext liefere den ersten Pfad, der dann
der einzig erfüllbare Pfad sein muss, sonst wird eine Exception
geworfen.

=cut

# -----------------------------------------------------------------------------

sub glob {
    my ($this,$pat) = @_; # MEMO: Hier ist keine Tilde-Expansion nötig

    my @arr = CORE::glob $pat;
    if (wantarray) {
        return @arr;
    }

    if (!@arr) {
        $this->throw(
            'PATH-00014: Path does not exist',
            Pattern => $pat,
        );
    }
    elsif (@arr > 1) {
        $this->throw(
            'PATH-00015: More than one path matches pattern',
            Pattern => $pat,
        );
    }

    return $arr[0];
}

# -----------------------------------------------------------------------------

=head3 globExists() - Prüfe, ob Shell-Pattern erfüllt ist

=head4 Synopsis

  $bool = $this->globExists($pat);

=head4 Description

Prüfe, ob Pfad-Objekte existieren, die Shell-Pattern $pat erfüllen.
Wenn ja, liefere I<wahr>, sonst I<falsch>.

=cut

# -----------------------------------------------------------------------------

sub globExists {
    my ($this,$pat) = @_; # MEMO: Hier ist keine Tilde-Expansion nötig

    my @arr = CORE::glob $pat;
    return @arr? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isEmpty() - Prüfe, ob Datei oder Verzeichnis leer ist

=head4 Synopsis

  $bool = $class->isEmpty($path);

=cut

# -----------------------------------------------------------------------------

sub isEmpty {
    my ($class,$path) = @_;

    if (-d $path) {
        local *D;

        my $i = 0;
        unless (opendir D,$path) {
            $class->throw(
                'PATH-00005: Verzeichnis kann nicht geöffnet werden',
                Path => $path,
                Error => "$!",
            );
        }
        while (readdir D) {
            last if ++$i > 2;
        }
        closedir D;

        return $i <= 2? 1: 0;
    }
    else {
        return -z $path? 1: 0;
    }
}

# -----------------------------------------------------------------------------

=head3 mode() - Liefere Zugriffsrechte

=head4 Synopsis

  $mode = $this->mode($path);

=head4 Description

Liefere die Zugriffsrechte des Pfads $path.

=head4 Examples

=over 2

=item *

Permissions oktal anzeigen

  printf "%04o\n",Quiq::Path->mode('/etc/passwd');
  0644

=item *

Prüfen, ob eine Datei für andere lesbar oder schreibbar ist

  if ($mode & 00066) {
      die "ERROR: File ist readable or writable for others\n";
  }

=back

=cut

# -----------------------------------------------------------------------------

sub mode {
    my ($this,$path) = @_;

    $path = $this->expandTilde($path);

    my @stat = CORE::stat $path;
    unless (@stat) {
        $this->throw(
            'PATH-00001: stat ist fehlgeschlagen',
            Path => $path,
        );
    }

    return $stat[2] & 07777;
}

# -----------------------------------------------------------------------------

=head3 moveToDateSubDir() - Verschiebe Pfad in Datums-Subverzeichnis

=head4 Synopsis

  $this->moveToDateSubDir($path);
  $this->moveToDateSubDir($path,$rootDir);

=head4 Arguments

=over 4

=item $path

Pfad, der verschoben wird.

=item $rootDir (Default: '.')

Verzeichnis, in dem das Datums-Subverzeichnis angelegt wird.

=back

=head4 Options

=over 4

=item -verbose => $bool (Default: 1)

Gib Information aus.

=item -dirSuffix => $suffix

Füge an das Datums-Subverzeichnis den Suffix $suffix an. Beispiel:

  Quiq::Path->moveToDateSubDir($_,-dirSuffix=>'.tmp')

=back

=head4 Description

Ermitte das Modifikationsdatum des Pfads $path, erzeuge ein Subverzeichnis
C<YYYY-MM-DD> in $rootDir und verschiebe den Pfad dorthin. Diese Methode
ist nützlich, wenn der Inhalt eines großen Verzeichnisses, der sich
nach-und-nach aufgebaut hat, auf Subverzeichnisse aufgeteilt werden soll.

=head4 Example

Innerhalb eines Verzeichnisses:

  $ perl -MQuiq::Path -E 'Quiq::Path->moveToDateSubDir($_) for glob("*.jpg")'

Mit Zielverzeichnis ("dest"):

  $ perl -MQuiq::Path -E 'Quiq::Path->moveToDateSubDir($_,"dest") for glob("src/*.jpg")'

=cut

# -----------------------------------------------------------------------------

sub moveToDateSubDir {
    my $this = shift;

    # Optionen und Argumente

    my $verbose = 1;
    my $dirSuffix = undef;

    my $argA = $this->parameters(1,2,\@_,
        -verbose => \$verbose,
        -dirSuffix => \$dirSuffix,
    );
    my ($path,$rootDir) = @$argA;

    my $date = POSIX::strftime('%Y-%m-%d',localtime $this->mtime($path));
    my $destDir = $rootDir? "$rootDir/$date": $date;
    if ($dirSuffix) {
        $destDir .= $dirSuffix;
    }
    my $name = $this->filename($path);
    if ($verbose) {
        say "$path => $destDir/$name";
    }
    $this->mkdir($destDir,-recursive=>1);
    $this->duplicate('move',$path,"$destDir/$name");

    return;
}

# -----------------------------------------------------------------------------

=head3 mtime() - Setze/Liefere Modifikationszeit

=head4 Synopsis

  $mtime = $class->mtime($path);
  $mtime = $class->mtime($path,$mtime);

=head4 Description

Liefere die Zeit der letzten Modifikation des Pfads $path. Wenn der
Pfad nicht existiert, liefere 0.

Ist ein zweiter Parameter $mtime angegeben, setze die Zeit auf den
angegebenen Wert. In dem Fall muss der Pfad existieren.

=cut

# -----------------------------------------------------------------------------

sub mtime {
    my $class = shift;
    my $path = $class->expandTilde(shift);
    # @_: $mtime

    if (@_) {
        my $mtime = shift;

        if (!-e $path) {
            $class->throw(
                'PATH-00011: Pfad existiert nicht',
                Path => $path,
            );
        }
        my $atime = (stat($path))[8]; # atime lesen, die nicht ändern
        if (!utime $atime,$mtime,$path) {
            $class->throw(
                'PATH-00012: Kann mtime nicht setzen',
                Path => $path,
                Error => "$!",
            );
        }
    }

    return defined($path) && -e $path? (stat($path))[9]: 0;
}

# -----------------------------------------------------------------------------

=head3 mtimePaths() - Setze mtime inkrementierend

=head4 Synopsis

  $this->mtimePaths(\@paths,$startTime,$step);

=head4 Arguments

=over 4

=item @path

Die Pfade, die zu nummerieren sind.

=item $startTime

Startzeitpunkt im Format "YYYY-MM-DD HH:MM:SS".

=item $step

Schrittweite in Sekunden.

=back

=head4 Example

  $ perl -MQuiq::Path -E '$p = Quiq::Path->new; $p->mtimePaths([$p->glob("*.jpg")],"2019-10-08 20:00:00",60)'

=cut

# -----------------------------------------------------------------------------

sub mtimePaths {
    my ($this,$pathA,$startTime,$step) = splice @_,0,4;

    my $mtime = Quiq::Time->new(ymdhms=>$startTime)->epoch;

    for my $path (@$pathA) {
         $this->mtime($path,$mtime);
         $mtime += $step;
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 newer() - Vergleiche Modifikationsdatum zweier Pfade

=head4 Synopsis

  $bool = $class->newer($path1,$path2);

=head4 Description

Prüfe, ob Pfad $path1 ein jüngeres Modifikationsdatum besitzt als
$path2. Ist dies der Fall, liefere 1, andernfalls 0. Liefere
ebenfalls 1, wenn Datei $path2 nicht existiert. Pfad
$path1 muss existieren.

Pfad $path2 kann eine Zeichenkette oder ein Pfad-Objekt sein.

Dieser Test ist nützlich, wenn $path2 aus $path1 erzeugt wird
und geprüft werden soll, ob eine Neuerzeugung notwendig ist.

=cut

# -----------------------------------------------------------------------------

sub newer {
    my ($class,$path1,$path2) = @_;

    if (!-e $path1) {
        $class->throw(
            'PATH-00011: Pfad existiert nicht',
            Path => $path1,
        );
    }

    my $t1 = (stat $path1)[9];
    my $t2 = (stat $path2)[9] || 0;

    return $t1 > $t2? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 newExtension() - Setze eine neue Extension

=head4 Synopsis

  $newPath = $this->newExtension($path,$ext);

=head4 Description

Entferne die bestehende Extension von Pfad $path und füge $ext als
neue Extension hinzu. Besitzt $path keine Extension, wird
$ext hinzugefügt. Etension $ext kann mit oder ohne Punkt am Anfang
angegeben werden.

=cut

# -----------------------------------------------------------------------------

sub newExtension {
    my ($this,$path,$ext) = @_;

    $ext =~ s/^\.//;         # Wir entfernen einen optionalen .
    $path =~ s/\.([^.]+)$//; # Wir entfernen die bestehende Extension
    $path .= ".$ext";        # Wir fügen die neue Extension hinzu

    return $path;
}

# -----------------------------------------------------------------------------

=head3 readlink() - Liefere Ziel des Symlink

=head4 Synopsis

  $path = $class->readlink($symlinkPath);

=head4 Alias

readLink()

=head4 Description

Liefere den Pfad, auf den der Symlink $symlinkPath zeigt.

=cut

# -----------------------------------------------------------------------------

sub readlink {
    my $class = shift;
    my $symlinkPath = shift;

    return readlink($symlinkPath) // do {
            $class->throw(
                'PATH-00099: Kann Symlink-Zielpfad nicht ermitteln',
                Path => $symlinkPath,
                Error => "$!",
            );
    }; 
}

{
    no warnings 'once';
    *readLink = \&readlink;
}

# -----------------------------------------------------------------------------

=head3 reduceToTilde() - Ersetze Pfandanfang durch Tilde

=head4 Synopsis

  $pathNew = $class->reduceToTilde($path);

=head4 Arguments

=over 4

=item $path

Ein Pfad

=back

=head4 Returns

Pfad (String)

=head4 Description

Ersetze das Homedir am Pfadanfang durch eine Tilde und liefere den
resultierenden Pfad zurück. Beginnt der Pfad nicht mit dem Homedir,
bleibt er unverändert.

=cut

# -----------------------------------------------------------------------------

sub reduceToTilde {
    my ($class,$path) = @_;

    if (!exists $ENV{'HOME'}) {
        $class->throw(
            'PATH-00016: Envar HOME does not exist',
        );
    }

    $path =~ s#^$ENV{'HOME'}#~#;
    
    return $path;
}

# -----------------------------------------------------------------------------

=head3 removeExtension() - Entferne Extension

=head4 Synopsis

  $newPath = $class->removeExtension($path);

=head4 Description

Entferne die Extension von Pfad $path und liefere den
resultierenden Pfad zurück. Besitzt $path keine Extension, sind
$path und $newPath identisch.

=cut

# -----------------------------------------------------------------------------

sub removeExtension {
    my ($class,$path) = @_;
    $path =~ s|\.[^./]+$||;
    return $path;
}

# -----------------------------------------------------------------------------

=head3 rename() - Benenne Pfad um

=head4 Synopsis

  $this->rename($oldPath,$newPath,@opt);

=head4 Options

=over 4

=item -overwrite => $bool (Default: 1)

Wenn gesetzt, wird die Datei $newPath überschrieben, falls sie
existiert. Wenn nicht gesetzt, wird eine Exception geworfen,
falls sie existiert.

=item -recursive => 0 | 1 (Default: 0)

Erzeuge nicht-existente Verzeichnisse des Zielpfads
und entferne leere Verzeichnisse des Quellpfads.

=back

=head4 Description

Benenne Pfad $oldPath in $newPath um. Die Methode liefert keinen
Wert zurück.

=head4 Example

Zielpfad erzeugen, Quellpfad entfernen mit -recursive=>1.
Ausgangslage: Unterhalb von /tmp existieren weder a noch x.

  my $srcPath = '/tmp/a/b/c/d/f';
  my $destPath = '/tmp/x/b/c/d/f';
  Quiq::Path->write($srcPath,'',-recursive=>1);
  Quiq::Path->rename($srcPath,$destPath,-recursive=>1);

Nach Ausführung existiert der der Pfad /tmp/x/b/c/d/f, aber der Pfad
/tmp/a nicht mehr.

=cut

# -----------------------------------------------------------------------------

sub rename {
    my $this = shift;
    my $oldPath = $this->expandTilde(shift);
    my $newPath = $this->expandTilde(shift);
    # @_: @opt

    # Nichts tun, wenn die Pfade identisch sind

    if ($oldPath eq $newPath) {
        return;
    }

    # Optionen

    my $overwrite = 1;
    my $recursive = 0;

    Quiq::Option->extract(\@_,
        -overwrite => \$overwrite,
        -recursive => \$recursive,
    );

    if (!$overwrite && -e $newPath) {
        $this->throw(
            'PATH-00099: Zieldatei existiert bereits',
            Path => $newPath,
        );
    }

    # Erzeuge Zielverzeichnis, wenn nicht vorhanden

    if ($recursive) {
        my $newDir = (Quiq::Path->split($newPath))[0];
        if ($newDir && !-d $newDir) {
            $this->mkdir($newDir,-recursive=>1);
        }
    }

    CORE::rename $oldPath,$newPath or do {
        $this->throw(
            'PATH-00010: Kann Pfad nicht umbenennen',
            Error => "$!",
            OldPath => $oldPath,
            NewPath => $newPath,
        );
    };

    # Lösche Quellverzeichnisse, sofern sie leer sind

    if ($recursive) {
        while (1) {
            ($oldPath) = Quiq::Path->split($oldPath);
            eval {Quiq::Path->rmdir($oldPath)};
            if ($@) {
                last;
            }
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 numberBasePaths() - Nummeriere die (kurzen) Basisnamen der Pfade

=head4 Synopsis

  $this->numberBasePaths(\@paths,$width,$step,@opts);

=head4 Arguments

=over 4

=item @path

Die Menge der Pfade.

=item $width

Die Breite (Anzahl der Stellen) der Nummer.

=item $step

Die Schrittweite der Nummerierung.

=back

=head4 Options

=over 4

=item -start => $n (Default: $step)

Startwert.

=item -verbose => $bool (Default: 0)

Gib Information aus.

=back

=head4 Description

Sortiere die (kurzen) Basisnamen der Pfade B<@paths> lexikalisch und
nummeriere ihre Basisnamen durch, beginnend mit Nummer B<$step> und
Schrittweite B<$step>. Pfade mit dem gleichen (kurzen) Basisnamen aber
unterschiedlichen (lange) Extensions erhalten die gleiche Nummer, behalten
aber ihre unterschiedliche (lange) Extension.

=head4 Example

  $ ls
  a.jpg
  a.xcf
  x.jpg
  
  $ perl -MQuiq::Path -E 'Quiq::Path->numberBasePaths([$p->glob("*")],5,10)'
  
  $ ls
  00010.jpg
  00010.xcf
  00020.jpg

=cut

# -----------------------------------------------------------------------------

sub numberBasePaths {
    my $this = shift;

    # Optionen und Argumente

    my $start = undef;
    my $verbose = 0;

    my $argA = $this->parameters(3,3,\@_,
        -start => \$start,
        -verbose => \$verbose,
    );
    my ($pathA,$width,$step) = @$argA;
    $start //= $step;

    # Baue Liste der Basisnamen auf

    my %basePath;
    for my $path (@$pathA) {
        # my ($dir,undef,$base,$ext) = $this->split($path);
        my ($dir,undef,undef,undef,$base,$ext) = $this->split($path);

        my $l = length $base;
        if ($l != $width) {
            $this->throw(
                'PATH-00099: Wrong base width',
                Path => $path,
                Base => $base,
                AllowedWidth => $width,
            );
        }

        if ($dir ne '') {
            $base = "$dir/$base";
        }
        my $arr = $basePath{$base} //= [];
        push @$arr,$ext;
    }

    my $n = $start;
    my @newPaths;
    for (sort keys %basePath) {
        my $oldBasePath = $_;
        my ($dir) = $this->split($oldBasePath);
        
        my $newBasePath;
        if ($dir ne '') {
            $newBasePath = "$dir/";
        }
        $newBasePath .= sprintf '%0*d',$width,$n;
        if ($verbose) {
            say "$oldBasePath => $newBasePath";
        }
        for my $ext (@{$basePath{$oldBasePath}}) {
            my $oldPath = $oldBasePath;
            my $newPath = $newBasePath;
            if ($ext eq '') {
                $newPath .= ".tmp";
            }
            else {
                $oldPath .= ".$ext";
                $newPath .= ".$ext.tmp";
            }
            if ($verbose) {
                say "  $oldPath => $newPath";
            }
            $this->rename($oldPath,$newPath,-overwrite=>0);
            push @newPaths,$newPath;
        }

        $n += $step;
    }

    # Entferne Endung .tmp

    for my $tmpPath (@newPaths) {
        (my $newPath = $tmpPath) =~ s/\.tmp$//;
        $this->rename($tmpPath,$newPath,-overwrite=>0);
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 numberPaths() - Nummeriere Pfade

=head4 Synopsis

  $this->numberPaths(\@paths,$width,$step,@opts);

=head4 Arguments

=over 4

=item @path

Die Pfade, die zu nummerieren sind.

=item $width

Die Breite (Anzahl der Stellen) der Nummer.

=item $step

Die Schrittweite der Nummerierung.

=back

=head4 Options

=over 4

=item -move => [$after,$from,$to]

Ordne alle Pfade von $from bis $to (lexikalisch sortiert) nach der
Datei $after ein. Ist $after leer (Leerstring oder undef), werden
die Pfade an den Anfang gestellt. Alle Angaben I<vor> der
Nummerierung.

=item -start => $n (Default: $step)

Verwende $n als Startwert.

=back

=head4 Description

Nummeriere die Pfade @paths, gemäß der gegebenen Reihenfolge.
Der Basisname der jeweiligen Datei/des Directory aus @paths wird
hierbei durch eine Nummer der Breite $width ersetzt. Die Extension
(sofern vorhanden) bleibt erhalten. Die Nummerierung erfolgt mit
Schrittweite $width.

=head4 Example

Der Aufruf

  $ perl -MQuiq::Path -E '$p = Quiq::Path->new; $p->numberPaths([$p->glob("*")],5,10)'

benennt alle Dateien, gleichgültig wie sie heißen, im aktuellen
Verzeichnis um in

  00010.EXT
  00020.EXT
  00030.EXT
  ...

wobei EXT die Extension ist, die die Datei vorher hatte, d.h. diese
bleibt als einziges vom ursprünglichen Dateinamen erhalten.

=cut

# -----------------------------------------------------------------------------

sub numberPaths {
    my $this = shift;
    # @_: $pathA,$width,$step,@opts

    # Optionen

    my $moveA = undef;
    my $start = undef;

    my $argA = $this->parameters(3,3,\@_,
        -move => \$moveA,
        -start => \$start,
    );
    my ($pathA,$width,$step) = @$argA;

    if ($moveA) {
        my ($after,$from,$to) = @$moveA;

        # Prüfe Angaben

        scalar $this->glob("$after.*");
        my $fromPath = $this->glob("$from.*");
        my $toPath =  $this->glob("$to.*");

        if ($fromPath gt $toPath) {
            $this->throw(
                'PATH-00099: fromPath must be less than toPath',
                FromPath => $fromPath,
                ToPath => $toPath,
            );
        }

        # Pfadliste neu aufbauen
        my @paths = @$pathA;

        # Pfade $from bis $to von @paths nach @movePaths bewegen

        my ($pos,@movePaths);
        if (!defined $after || $after eq '') {
            $pos = 0;
        }
        for (my $i = 0; $i < @paths; $i++) {
            my $path = $this->removeExtension($paths[$i]);
            if (!defined $pos && $after eq $path) {
                $pos = $i+1;
                next;
            }
            if ($path ge $from && $path le $to) {
                push @movePaths,splice @paths,$i--,1;
            }
        }
        if (!defined $pos) {
            $this->throw(
                'PATH-00099: Path (after) not found',
                Path => $after,
            );
        }
        splice @paths,$pos,0,@movePaths;

        # Umgeschriebene Pfadliste einsetzen
        $pathA = \@paths;
    }

    # Nummeriere Dateien mit Endung .tmp

    my $n = defined $start? $start: $step;
    my @tmpPath;
    for my $path (@$pathA) {
        my ($dir,undef,$base,$ext) = $this->split($path);

        my $tmpPath;
        if ($dir ne '') {
            $tmpPath = "$dir/";
        }
        $tmpPath .= sprintf '%0*d',$width,$n;
        if ($ext ne '') {
            $tmpPath .= ".$ext";
        }
        $tmpPath .= '.tmp';

        push @tmpPath,$tmpPath;

        $this->rename($path,$tmpPath,-overwrite=>0);

        $n += $step;
    }

    # Entferne Endung .tmp

    for my $tmpPath (@tmpPath) {
        (my $newPath = $tmpPath) =~ s/\.tmp$//;
        $this->rename($tmpPath,$newPath,-overwrite=>0);
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 sameFile() - Prüfe auf identische Datei

=head4 Synopsis

  $bool = $this->sameFile($path1,$path2);

=head4 Arguments

=over 4

=item $path1

Erster Pfad

=item $path2

Zweiter Pfad

=back

=head4 Returns

(Integer)

=head4 Description

Prüfe, ob die beiden Pfade $path1 und $path2 auf dieselbe
Datei (deselben Inode) verweisen. Wenn ja, liefere 1, sonst 0.
Funktioniert auch bei Symlinks.

=cut

# -----------------------------------------------------------------------------

sub sameFile {
    my ($this,$path1,$path2) = @_;
    return ($this->stat($path1))[1] == ($this->stat($path2))[1]? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 split() - Zerlege Pfad in seine Komponenten

=head4 Synopsis

  ($dir,$file,$base,$ext,$shortBase,$longExt) = $class->split($path);

=head4 Description

Zerlege Pfad in die vier Komponenten Verzeichnisname, Dateiname,
Basisname (= Dateiname ohne Extension) und Extension und liefere diese
zurück.

Für eine Komponente, die nicht existiert, wird ein Leerstring
geliefert.

=cut

# -----------------------------------------------------------------------------

sub split {
    my ($class,$path) = @_;

    my ($dir,$file,$base,$ext,$shortBase,$longExt) = ('') x 6;

    $dir = $1 if $path =~ s|(.*)/||;
    $file = $path;

    $ext = $1 if $path =~ s/\.([^.]+)$//;
    $base = $path;

    $longExt = $ext;
    if (($shortBase = $base) =~ s/\.(.+)$//) {
        $longExt = "$1.$longExt";
    }

    return ($dir,$file,$base,$ext,$shortBase,$longExt);
}

# -----------------------------------------------------------------------------

=head3 spreadToSubDirs() - Kopiere, bewege, linke oder symlinke Dateien in Subverzeichnisse

=head4 Synopsis

  $this->%METHOD($method,$destDir,$maxPerDir);

=head4 Arguments

=over 4

=item $method

Anzuwendende Pfadoperation (siehe Methode duplicate()):

  copy
  move -or- rename
  link
  symlink

=item $destDir

(String) Verzeichnis, in dem die Subverzeichnisse angelegt werden.
Das Verzeichnis muss existieren.

=item $maxPerDir

(Integer) Maximale Anzahl Dateien pro Unterverzeichnis.

=back

=head4 Description

Lies Pfade von <STDIN> und verteile die Pfade auf dynamisch erzeugte
Subverzeichnisse.

=head4 Example

  $ find SRCDIR -type f | sort | perl -MQuiq::Path -E 'Quiq::Path->spreadToSubDirs("link",$destDir,100)'

=cut

# -----------------------------------------------------------------------------

sub spreadToSubDirs {
    my $this = shift;
    my $method = shift;
    my $destDir = $this->expandTilde(shift);
    my $maxPerDir = shift;

    my $i = 0;
    my $dir;
    while (<STDIN>) {
        chomp;
        if ($i%$maxPerDir == 0) {
            $dir = sprintf '%s/%04d',$destDir,int($i/$maxPerDir)+1;
            $this->mkdir($dir);
            say $dir;
        }
        $i++;
        my $file = $this->filename($_);
        $this->duplicate($method,$_,"$dir/$file");
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 stat() - Statusinformation eines Pfads

=head4 Synopsis

  @arr = $class->%METHOD($path);

=head4 Arguments

=over 4

=item $path

Datei- oder Verzeichnispfad.

=back

=head4 Returns

Statusinformation (List)

=head4 Description

Ermittele die Statusinformation eines Pfads und liefere diese
Information als 13-elementige Liste zurück.

Der Aufruf ist äquivalent zu

  stat $path

mit dem Unterschied, dass

=over 2

=item *

eine Tilde-Expansion stattfindet

=item *

eine Exception geworfen, wird, wenn $path nicht existiert

=back

=head4 See Also

=over 2

=item *

perldoc -f stat

=back

=cut

# -----------------------------------------------------------------------------

sub stat {
    my $class = shift;
    my $path = $class->expandTilde(shift);

    if (!-e $path) {
        $class->throw(
            'PATH-00099: Path does not exist',
            Path => $path,
        );
    }

    return stat $path;
}

# -----------------------------------------------------------------------------

=head3 swap() - Vertausche in einem Verzeichnis zwei Namen

=head4 Synopsis

  $this->%METHOD($dir,$glob1,$glob2);

=head4 Arguments

=over 4

=item $dir

Pfad des Verzeichnisses

=item $glob1

Datei oder Verzeichnisname

=item $glob2

Datei oder Verzeichnisname

=back

=head4 Description

Vertausche in Verzeichnis $dir die beiden (Datei- oder Verzeichnis-)Namen
$glob1 und $glob2.

=head4 Example

  $ perl -MQuiq::Path -E 'Quiq::Path->swap("06-album","0000940.*","0010200.*")'

=cut

# -----------------------------------------------------------------------------

sub swap {
    my $this = shift;
    my $dir = $this->expandTilde(shift);
    my $glob1 = shift;
    my $glob2 = shift;

    my @paths1 = $this->glob("$dir/$glob1");
    if (!@paths1) {
        $this->throw(
            'PATH-00099: Glob pattern not found',
            Pattern => "$dir/$glob1",
        );
    }
    my @paths2 = $this->glob("$dir/$glob2");
    if (!@paths2) {
        $this->throw(
            'PATH-00099: Glob pattern not found',
            Pattern => "$dir/$glob2",
        );
    }

    (my $name1 = $glob1) =~ s/\*//g;
    (my $name2 = $glob2) =~ s/\*//g;

    my @newPaths;

    # $name1 in $name2 umbenennen und Endung .tmp hinzufügen

    for my $path (@paths1) {
        (my $newPath = $path) =~ s/$name1/$name2/;
        $newPath .= '.tmp';
        $this->rename($path,$newPath);
        push @newPaths,$newPath;
    }

    # $name2 in $name1 umbenennen und Endung .tmp hinzufügen

    for my $path (@paths2) {
        (my $newPath = $path) =~ s/$name2/$name1/;
        $newPath .= '.tmp';
        $this->rename($path,$newPath);
        push @newPaths,$newPath;
    }

    # Endung .tmp entfernen

    for my $path (@newPaths) {
        (my $newPath = $path) =~ s/\.tmp//;
        $this->rename($path,$newPath);
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 symlink() - Erzeuge Symlink

=head4 Synopsis

  $class->symlink($path,$symlink);

=head4 Description

Erzeuge Symlink $symlink für Pfad $path.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub symlink {
    my ($class,$path,$symlink) = splice @_,0,3;

    # Optionen

    my $force = 0;

    Quiq::Option->extract(\@_,
        -force => \$force,
    );

    if ($force && -l $symlink) {
        $class->delete($symlink);
    }

    CORE::symlink $path,$symlink or do {
        $class->throw(
            'FS-00001: Kann Symlink nicht erzeugen',
            Path => $path,
            Symlink => $symlink,
            Error => $!,
        );
    };

    return;
}

# -----------------------------------------------------------------------------

=head3 symlinkRelative() - Erzeuge Symlink mit relativem Zielpfad

=head4 Synopsis

  $class->symlinkRelative($path,$symlink,@opt);

=head4 Options

=over 4

=item -createDir => $bool (Default: 0)

Erzeuge nicht-existente Verzeichnisse des Zielpfads.

=item -dryRun => $bool (Default: 0)

Führe das Kommando nicht aus. Speziell Verbindung mit
-verbose=>1 sinnvoll, um Code zu testen.

=item -verbose => $bool (Default: 0)

Gib Informationen über die erzeugten Symlinks auf STDOUT aus.

=back

=head4 Description

Erzeuge einen Symlink $symlink, der auf den Pfad $path verweist.
Die Methode liefert keinen Wert zurück.

Die Methode zeichnet sich gegenüber der Methode symlink() dadurch
aus, dass sie, wenn $path ein relativer Pfad ist, diesen so korrigiert,
dass er von $symlink aus korrekt ist. Denn der Pfad $path múss als
relativer Pfad als Fortsetzung von $symlink gesehen werden.

=head4 Example

  Quiq::Path->symlinkRelative('a','x')
  # x => a
  
  Quiq::Path->symlinkRelative('a/b','x')
  # x => a/b
  
  Quiq::Path->symlinkRelative('a/b','x/y')
  # x/y => ../a/b
  
  Quiq::Path->symlinkRelative('a/b','x/y/z')
  # x/y/z => ../../a/b

=cut

# -----------------------------------------------------------------------------

sub symlinkRelative {
    my $class = shift;
    my $path = shift;
    my $symlink = shift;
    my %opt = @_;

    my $createDir = delete $opt{'-createDir'};
    my $dryRun = delete $opt{'-dryRun'};
    my $verbose = delete $opt{'-verbose'};
    if (%opt) {
        $class->throw(
            'FILESYS-00001: Unbekannte Option(en)',
            Options => join(', ',keys %opt),
        );
    }

    # Erzeuge den Zielpfad, falls er nicht existiert

    if ($createDir) {
        my $dir = (Quiq::Path->split($symlink))[0];
        if ($dir && !-d $dir) {
            $class->mkdir($dir,-recursive=>1);
        }
    }

    # Sonderbehandlung, wenn der Pfad $path, auf den der Symlink zeigt,
    # relativ ist. Da der Pfad $path relativ zum Symlink gilt
    # und nicht relativ zum aktuellen Verzeichnis des Aufrufers
    # interpretiert wird, muss der Zielpfad ergänzt werden,
    # wenn der Symlink-Pfad nicht im aktuellen Verzeichnis liegt.
    # Die Pfad-Umschreibung nimmt diese Methode vor.

    if ($path !~ m|^/| && $symlink =~ m|/|) {
        if ($symlink !~ m|^/|) {
            # Wenn $symlink relativ ist, $path die Anzahl der
            # $symlink-Directories voranstellen

            my $n = $symlink =~ tr|/||;
            my $prefix = '';
            for (my $i = 0; $i < $n; $i++) {
                $prefix .= '../';
            }
            $path = "$prefix$path";
        }
        else {
            # Wenn $symlink absolut ist, $path das aktuelle
            # Verzeichnis voranstellen.
            $path = sprintf '%s/%s',Quiq::Process->cwd,$path;
        }
    }
    if ($verbose) {
        print "$symlink => $path\n";
    }
    if (!$dryRun) {
        $class->symlink($path,$symlink);
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 touch() - Setze Modifikationszeit auf aktuellen Zeitpunkt

=head4 Synopsis

  $mtime = $this->touch($path);

=head4 Arguments

=over 4

=item $path

Pfad der Datei oder des Verzeichnisses, dessen mtime gesetzt werden soll.

=back

=head4 Returns

Modifikationszeit in Unix Epoch (Integer)

=head4 Description

Setze den Zeitpunkt der letzten Modifikation (mtime) des Pfades $path
auf den aktuellen Zeitpunkt.

=cut

# -----------------------------------------------------------------------------

sub touch {
    my ($this,$path) = @_;
    return $this->mtime($path,time);
}

# -----------------------------------------------------------------------------

=head3 uid() - UID des Owners der Datei

=head4 Synopsis

  $uid = $this->%METHOD($path);

=head4 Description

Ermittele die UID des Owners der Datei und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub uid {
    my ($this,$path) = @_;
    return ($this->stat($path))[4];
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
