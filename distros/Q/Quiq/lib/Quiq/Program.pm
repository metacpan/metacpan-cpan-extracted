# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Program - Basisklasse für Programme

=head1 BASE CLASSES

=over 2

=item *

L<Quiq::Process>

=item *

L<Quiq::Hash>

=back

=head1 SYNOPSIS

Programm:

  #!/usr/bin/env perl
  
  use Quiq::Program;
  exit Quiq::Program->run('MyProg')->exitCode;
  
  # eof

Programm-Klasse:

  package MyProg;
  use base 'Quiq::Program';
  
  sub main {
      my $self = shift;
      ...
      return;
  }
  
  # eof

Optionen und Argumente:

  my ($error,$opt,$argA) = $self->options(
      ...
      -help => 0,
  );
  if ($error) {
      $self->help(10,"ERROR: $error");
  }
  elsif ($opt->help) {
      $self->help;
  }
  elsif (@$argA != 1) {
      $self->help(11,'ERROR: Falsche Anzahl Argumente');
  }
  my $myArg = shift @$argA;
  ...

=cut

# -----------------------------------------------------------------------------

package Quiq::Program;
use base qw/Quiq::Process Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Perl;
use Encode ();
use Quiq::Parameters;
use Quiq::Assert;
use Quiq::Option;
use Time::HiRes ();
use Quiq::FileHandle;
use PerlIO::encoding;
use Quiq::System;
use Quiq::Hash;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Programmsteuerung

=head3 run() - Führe Programm-Klassen aus

=head4 Synopsis

  $prg = Quiq::Program->run($programClass,@options);

=head4 Options

Siehe Methode L<new|"new() - Instantiiere Programm-Objekt">()

=cut

# -----------------------------------------------------------------------------

sub run {
    my $class = shift;
    my $programClass = shift || $class;
    # @_: @options

    # Änderungen an STD*-Dateihandles lokal beschränken

    local *STDIN = *STDIN;
    local *STDOUT = *STDOUT;
    local *STDERR = *STDERR;

    my $self = $class->new(@_);
    eval {
        Quiq::Perl->loadClass($programClass);
        $self->rebless($programClass);

        my @arr = $self->main;
        while (@arr) {
            my $key = shift @arr;
            if ($key eq 'programClass') {
                my $subProgramClass = shift @arr;
                Quiq::Perl->loadClass($subProgramClass);
                $self->rebless($subProgramClass);
            }
            elsif ($key eq 'methods') {
                my $methodA = shift @arr;
                for my $meth (@$methodA) {
                    $self->$meth;
                }
            }
            else {
                die "Unbekannte Direktive: $key\n";
            }
        }
    };
    if ($@ && $@ !~ /^exit: \d+$/) {
        $self->catch($@);
    }
    $self->finish;

    return $self;
}

# -----------------------------------------------------------------------------

=head3 exit() - Terminiere das Programm

=head4 Synopsis

  $prg->exit;
  $prg->exit($exitCode);

=head4 Description

Terminiere das Programm mit Exitcode $exitCode. Ist kein Exitcode
angegeben, terminiere mit dem Exitcode der auf dem Programmobjekt
gesetzt ist. Die Methode kehrt nicht zurück. Nach ihrem Aufruf wird
die Methode L<finish|"finish() - Abschließender Code vor Programmende">() ausgeführt.

=cut

# -----------------------------------------------------------------------------

sub exit {
    my $self = shift;
    # @_: $exitCode

    if (@_) {
        $self->exitCode(shift);
    }
    
    die sprintf "exit: %s\n",$self->exitCode;
}

# -----------------------------------------------------------------------------

=head2 Getter/Setter

=head3 exitCode() - Liefere/Setze Exitcode

=head4 Synopsis

  $exitCode = $prg->exitCode;
  $exitCode = $prg->exitCode($exitCode);

=cut

# -----------------------------------------------------------------------------

sub exitCode {
    my $self = shift;
    # @_: $exitCode

    if (@_) {
        $self->{'exitCode'} = shift;
    }

    return $self->{'exitCode'};
}

# -----------------------------------------------------------------------------

=head3 name() - Name des Programms

=head4 Synopsis

  $name = $this->name;

=head4 Description

Liefere den Namen des Programms. Der Programmname ist die letzte
Pfadkomponente von $0.

=cut

# -----------------------------------------------------------------------------

sub name {
    my $this = shift;
    (my $name = $0) =~ s|.*/||;
    return $name;
}

# -----------------------------------------------------------------------------

=head2 Programmcode

=head3 main() - Hauptprogramm

=head4 Synopsis

  $prg->main;

=cut

# -----------------------------------------------------------------------------

sub main {
    my $self = shift;
    return;
}

# -----------------------------------------------------------------------------

=head3 catch() - Fange und behandle unbehandelte Exception

=head4 Synopsis

  $prg->catch($exception);

=head4 Description

Exception-Handler, der unbehandelte Exceptions der Anwendung fängt.
Kann von der Programmklasse bei Bedarf überschrieben werden.
Das Default-Verhalten ist, dass der Exception-Text auf STDERR
ausgegeben und der Exitcode auf 99 gesetzt wird.

Das Programm terminiert nicht sofort, sondern die Methode
L<finish|"finish() - Abschließender Code vor Programmende">() wird noch ausgeführt.

=cut

# -----------------------------------------------------------------------------

sub catch {
    my ($self,$exception) = @_;

    warn $exception;
    $self->exitCode(99);

    return;
}

# -----------------------------------------------------------------------------

=head3 finish() - Abschließender Code vor Programmende

=head4 Synopsis

  $prg->finish;

=cut

# -----------------------------------------------------------------------------

sub finish {
    my $self = shift;
    return;
}

# -----------------------------------------------------------------------------

=head2 Umgebung

=head3 env() - Liefere/Setze Environment-Hash

=head4 Synopsis

  $envH = $this->env;
  $envH = $this->env(\%env);

=cut

# -----------------------------------------------------------------------------

sub env {
    my $this = shift;
    # @_: $envH

    if (@_) {
        %ENV = %{(shift)};
    }

    return \%ENV;
}

# -----------------------------------------------------------------------------

=head3 argv() - Liefere/Setze Argument-Array

=head4 Synopsis

  $argA|@args = $this->argv;
  $argA|@args = $this->argv(\@argv);

=cut

# -----------------------------------------------------------------------------

sub argv {
    my $this = shift;
    # @_: $argA

    if (@_) {
        @ARGV = @{(shift)};
    }

    return wantarray? @ARGV: \@ARGV;
}

# -----------------------------------------------------------------------------

=head3 stdin() - Liefere/Setze STDIN Filehandle

=head4 Synopsis

  $fh = $this->stdin;
  $fh = $this->stdin($fh);

=cut

# -----------------------------------------------------------------------------

sub stdin {
    my $this = shift;
    # @_: $fh

    if (@_) {
        *STDIN = shift;
    }

    return \*STDIN;
}

# -----------------------------------------------------------------------------

=head3 stdout() - Liefere/Setze STDOUT Filehandle

=head4 Synopsis

  $fh = $this->stdout;
  $fh = $this->stdout($fh);

=cut

# -----------------------------------------------------------------------------

sub stdout {
    my $this = shift;
    # @_: $fh

    if (@_) {
        *STDOUT = shift;
    }

    return \*STDOUT;
}

# -----------------------------------------------------------------------------

=head3 stderr() - Liefere/Setze STDERR Filehandle

=head4 Synopsis

  $fh = $this->stderr;
  $fh = $this->stderr($fh);

=cut

# -----------------------------------------------------------------------------

sub stderr {
    my $this = shift;
    # @_: $fh

    if (@_) {
        *STDERR = shift;
    }

    return \*STDERR;
}

# -----------------------------------------------------------------------------

=head2 Character Encoding

=head3 encoding() - Standard-Encoding

=head4 Synopsis

  $encoding = $prg->encoding;

=head4 Description

Liefere das Standard-Encoding, das in der Systemumgebung eingestellt ist.
Im Konstruktor werden STDIN, STDOUT und STDERR auf dieses Encoding
eingestellt, d.h. Eingaben und Ausgaben automatisch gemäß dieses
Encodings gewandelt.

=cut

# -----------------------------------------------------------------------------

sub encoding {
    return shift->{'encoding'};
}

# -----------------------------------------------------------------------------

=head3 decode() - Dekodiere Zeichenkette gemäß Standard-Encoding

=head4 Synopsis

  $str = $prg->decode($str);

=cut

# -----------------------------------------------------------------------------

sub decode {
    my $self = shift;
    # @_: $str
    return Encode::decode($self->encoding,$_[0]);
}

# -----------------------------------------------------------------------------

=head3 encode() - Enkodiere Zeichenkette gemäß Standard-Encoding

=head4 Synopsis

  $str = $prg->encode($str);

=cut

# -----------------------------------------------------------------------------

sub encode {
    my $self = shift;
    # @_: $str
    return Encode::encode($self->encoding,$_[0]);
}

# -----------------------------------------------------------------------------

=head2 Parameter

=head3 parameters() - Argumente und Optionen des Programmaufrufs

=head4 Synopsis

  [1] ($argA,$opt) = $prg->parameters($sloppy,$minArgs,$maxArgs,@optVal);
  [2] $opt = $prg->parameters($sloppy,0,0,@optVal);
  [3] $argA = $prg->parameters($sloppy,$minArgs,$maxArgs,@optVal);

=head4 Arguments

=over 4

=item $sloppy

Wirf keine Exception, wenn unerwartete Parameter (also Optionen und
Arumente) in @ARGV enthalten sind. Diese Parameter bleiben in @ARGV
stehen.

=item $minArgs

Mindestanzahl an Argumenten.

=item $maxArgs

Maximale Anzahl an Argumenten.

=item @optVal

Liste der Optionen und ihrer Defaultwerte.

=back

=head4 Returns

=over 4

=item $opt

Hash-Objekt mit den Optionen.

=item $argA

Referenz auf Array mit mindestens $minArgs und höchstens
$maxArgs Argumenten.

=back

=head4 Description

Liefere die Argumente und Optionen des Programmaufs. Werden weniger als
$minArgs oder mehr als $maxArgs Argumente oder nicht deklarierte
Optionen übergeben, wird eine Exception geworfen. Ist $sloppy gesetzt,
wird im Falle überzähliger Parameter I<keine> Exception geworfen.
Die überzähligen Parameter bleiben in @ARGV erhalten.

Im Skalarkontext wird nur $opt geliefert, wenn keine Argumente erwartet
werden ($minArgs und $maxArgs sind 0), andernfalls $argA. Letzteres
ist nützlich, wenn C<-help> die einzige Option ist.

=cut

# -----------------------------------------------------------------------------

sub parameters {
    my ($self,$sloppy,$minArgs,$maxArgs) = splice @_,0,4;

    my ($argA,$opt) = Quiq::Parameters->extract(0,0,
        $self->encoding,\@ARGV,$maxArgs,@_);
    if ($opt->exists('help') && $opt->help) {
        $self->help;
    }
    elsif (@$argA < $minArgs) {
        $self->help(11,'ERROR: Missing arguments');
    }
    elsif (@ARGV && !$sloppy) {
        $self->help(12,"ERROR: Unexpected parameter(s): @ARGV");
    }

    return wantarray? ($argA,$opt):
        defined($maxArgs) && $maxArgs == 0? $opt: $argA;
}

# -----------------------------------------------------------------------------

=head2 Zusicherungen

=head3 assert() - Prüfe Werte

=head4 Synopsis

  $prg->assert(sub {...});

=head4 Description

Prüfe Werte durch Methoden der Klasse Quiq::Assert. Ist eine
Zusicherung verletzt, wird die betreffende Exception in die
Ausgabe der Programm-Hilfeseite umgesetzt. Die Subroutine
erhält als Argument ein instantiiertes Quiq::Assert-Objekt.

=head4 Example

  Prüfe die Werte der Variablen $system und $user gegen eine Menge
  möglicher Werte:
  
      $self->assert(sub {
          my $a = shift;
          $a->isEnumValue($system,['test','prod'],
              -name=>'SYSTEM',
          );
          $a->isEnumValue($user,[qw/etlt etls etlr etlp/],
              -name=>'USER',
          );
      });

=cut

# -----------------------------------------------------------------------------

sub assert {
    my ($self,$sub) = @_;

    my $a = Quiq::Assert->new(
        stacktrace => 0,
        nameSection => 'Parameter',
    );

    eval {$sub->($a)};
    if ($@) {
        $@ =~ s/ASSERT-\d+: //;
        $self->help(10,$@);
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Optionen

=head3 options() - Verarbeite Programmoptionen (DEPRECATED)

=head4 Synopsis

  ($error,$optH,$argA) = $prg->options(@keyVal);

=head4 Description

FIXME: Veraltete Methode. Alle Stellen, wo die Methode options()
genutzt wird, auf parameters() portieren.

=cut

# -----------------------------------------------------------------------------

sub options {
    my $self = shift;
    # @_: @keyVal

    my $argA = $self->argv;

    # Dekodiere die Programmargumente (2017-06-06)
    # ACHTUNG: älterer Code dekodiert möglicherweise selbst!

    my $enc = $self->encoding;
    for my $arg (@$argA) {
        $arg = Encode::decode($enc,$arg);
    }

    my $optH = eval{Quiq::Option->extract(
        -simpleMessage => 1,
        # -mode => 'sloppy',
        $argA,
        @_
    )};
    if (!$@) {
        $self->set(optH=>$optH);
    }

    return ($@,$optH,$argA);
}

# -----------------------------------------------------------------------------

=head3 opt() - Liefere Optionsobjekt oder Optionswerte

=head4 Synopsis

  $val = $prg->opt($key);   # [1]
  @vals = $prg->opt(@keys); # [2]
  $optH = $prg->opt;        # [3]

=cut

# -----------------------------------------------------------------------------

sub opt {
    my $self = shift;
    # @_: $key -or- @keys -or- ()

    my $optH = $self->{'optH'};
    if (!@_) {
        return $optH;
    }

    return $optH->get(@_);
}

# -----------------------------------------------------------------------------

=head2 Verzeichnisse

=head3 projectDir() - Projektverzeichnis

=head4 Synopsis

  $dir = $prg->projectDir($depth);

=head4 Description

Liefere den Verzeichnispfad, der $depth Stufen oberhalb des
Verzeichnisses endet, in dem das Programm installiert ist.

Der Installationspfad wird anhand von $0 ermittelt. Wurde das
Programm mit einem relativen Pfad aufgerufen, wird dieser zu einem
absoluten Pfad komplettiert.

=head4 Example

Wurde das Programm myprog unter dem Pfad

  /opt/myapp/bin/myprog

installiert, dann liefert $prg->projectDir(1) den Pfad

  /opt/myapp

als Projektverzeichnis.

=cut

# -----------------------------------------------------------------------------

sub projectDir {
    my ($self,$depth) = @_;

    my $path = $0;
    if ($path !~ m|^/|) {
        # Einen relativen Pfad machen wir zu einem absoluten
        # Pfad, indem wir ihn um das aktuelle Verzeichnis ergänzen.

        $path =~ s|^./||;
        $path = sprintf '%s/%s',$self->cwd,$path;
    }

    # InstallDir bestimmen, indem wir das Programm und $depth
    # Verzeichnisse darüber vom Pfad entfernen

    my @path = split m|/|,$path;
    splice @path,-($depth+1);
    my $dir = join '/',@path;

    return $dir;
}

# -----------------------------------------------------------------------------

=head2 Zeit

=head3 elapsed() - Vergangene Zeit in Sekunden

=head4 Synopsis

  $sec = $prg->elapsed;

=head4 Returns

Sekunden (Float)

=head4 Description

Ermittele die vergangene Zeit in Sekunden und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub elapsed {
    my $self = shift;
    return Time::HiRes::gettimeofday-$self->{'t0'};
}

# -----------------------------------------------------------------------------

=head2 Logging

=head3 log() - Schreibe Meldung nach STDERR

=head4 Synopsis

  $prg->log($fmt,@args);
  $prg->log($level,$fmt,@args);

=head4 Description

Schreibe eine Logmeldung nach STDERR, wenn $level größer oder gleich
dem eingestellten Loglevel ($prg->logLevel) ist. Ist $level nicht
angegeben, wird 1 angenommen.

Die Logmeldung wird per

  printf STDERR $fmt,@args;

erzeugt. Endet $fmt nicht mit einem Newline, wird es hinzugefügt.

Per Default ist der LogLevel 0. Er wird mit

  $prg->logLevel($n); # $n > 0

eingestellt.

=head4 Caveats

=over 2

=item *

Ist $fmt eine Zahl, muss der Level $level explizit angegeben werden.

=item *

Die Argumente der Methode werden I<immer> ausgewertet, auch wenn
kein Logging erfolgt. Ist damit ein größerer Aufwand verbunden,
kann es sinnvoll sein, eine Bedingung zu formulieren:

  if ($level >= $prg->logLevel) {
      # $msg mit großem Aufwand erzeugen
      $prg->log($level,$msg);
  }

=back

=cut

# -----------------------------------------------------------------------------

sub log {
    my $self = shift;
    my $level = $_[0] =~ /^\d+$/? shift: 1;
    # @_: $fmt,@args

    if ($self->logLevel >= $level) {
        my $fmt = shift;
        if (substr($fmt,-1,1) ne "\n") {
            $fmt .= "\n";
        }
        printf STDERR $fmt,@_;
    }

    return;    
}

# -----------------------------------------------------------------------------

=head2 Hilfe

=head3 help() - Gib Hilfetext aus und beende Programm

=head4 Synopsis

  $self->help;
  $self->help($exitCode);
  $self->help($exitCode,$msg);

=head4 Description

Der Hilfetext wird aus der POD-Dokumentation des Programms generiert.

=over 2

=item *

Ist $exitCode == 0, wird der Hilfetext auf STDOUT ausgegeben.
Ist $exitCode != 0, wird der Hilfetext auf STDERR ausgegeben.

=item *

Ist $msg angegeben, wird die Hilfeseite oben und unten um Text $msg
ergänzt (jeweils mit Leerzeile abgetrennt).

=item *

Ist $exitCode == 0 und STDOUT mit einem Terminal verbunden, wird
der Hilfetext im Pager dargestellt (Environment-Variable $PAGER
oder less).

=back

=cut

# -----------------------------------------------------------------------------

sub help {
    my $self = shift;
    my $exitCode = shift || 0;
    my $msg = shift || '';

    # Encoding des POD-Dokuments ermitteln

    my $podEncoding = 'iso-8859-1';
    my $fh = Quiq::FileHandle->new('<',$0);
    while (<$fh>) {
        chomp;
        if (/^=encoding\s+(\S+)/) {
            $podEncoding = $1;
            last;
        }
    }
    $fh->close;

    # Doku erzeugen und dekodieren

    my $text = -t STDOUT? qx/pod2text --overstrike $0/: qx/pod2text $0/;
    $text = Encode::decode($podEncoding,$text);

    if ($msg) {
        $msg =~ s/\n+$//;
        $text =~ s/\n+$//;
        $text = "$msg\n-----\n$text\n-----\n$msg\n";
    }

    # Doku anzeigen

    if ($exitCode) {
        # Ausgabe auf STDERR
        print STDERR $text;
    }
    elsif (-t STDOUT) {
        # Anzeige im Pager

        my $pager = $ENV{'PAGER'} || 'less -i';
        my $encoding = $self->encoding;
        my $fh = Quiq::FileHandle->new('|-',
            "LESSCHARSET=$encoding $pager");
        $fh->binmode(":encoding($encoding)");
        $fh->print($text);
        $fh->close;
    }
    else {
        # Ausgabe auf STDOUT
        print $text;
    }

    $self->exit($exitCode);
}

# -----------------------------------------------------------------------------

=head2 Instantiierung

=head3 new() - Instantiiere Programm-Objekt

=head4 Synopsis

  $prg = $class->new(@options);

=head4 Options

=over 4

=item -argv=>\@arr (Default: \@ARGV)

Setze Programm-Argumente auf @arr.

=item -env=>\%hash (Default: \%ENV)

Setze Programm-Environment auf %hash.

=item -stdin=>$fh (Default: \*STDIN)

Setze STDIN des Programms auf $fh.

=item -stdout=>$fh (Default: \*STDOUT)

Setze STDOUT des Programms auf $fh.

=item -stderr=>$fh (Default: \*STDERR)

Setze STDERR des Programms auf $fh.

=back

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @options

    # Optionen

    while (@_) {
        my $key = shift;
        if ($key =~ /^(-env|-argv|-stdin|-stdout|-stderr)$/) {
            $key = substr $key,1;
            $class->$key(shift);
        }
        else {
            $class->throw(
                'PROG-00001: Unbekannte Option',
                Option => $key,
            );
        }
    }

    # STDIN, STDOUT, STDERR auf Systemencoding einstellen

    my $encoding = Quiq::System->encoding;
    Quiq::Perl->binmode(*STDIN,":encoding($encoding)");
    Quiq::Perl->binmode(*STDOUT,":encoding($encoding)");
    Quiq::Perl->binmode(*STDERR,":encoding($encoding)");

    # Objekt instantiieren

    return $class->SUPER::new(
        encoding => $encoding,
        exitCode => 0,
        logLevel => 0,
        optH => Quiq::Hash->new,
        t0 => Time::HiRes::gettimeofday,
    );
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
