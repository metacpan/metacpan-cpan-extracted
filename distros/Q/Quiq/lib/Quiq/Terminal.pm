# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Terminal - Ein- und Ausgabe aufs Terminal

=head1 BASE CLASS

L<Quiq::Object>

=cut

# -----------------------------------------------------------------------------

package Quiq::Terminal;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Option;
use Quiq::FileHandle;
use Time::HiRes ();
use Term::ANSIColor ();
use Quiq::Exit;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 askUser() - Erfrage vom Benutzer einen Wert

=head4 Synopsis

  $val = $class->askUser($text,@opt);

=head4 Options

=over 4

=item -automatic => $bool (Default: 0)

Stelle keine Frage an den Benutzer, sondern liefere den Defaultwert.
Ist kein Defaultwert angegeben, wirf eine Exception. Diese Option ist
für Programme nützlich, die auch ohne Benutzerinteraktion ablaufen
können.

=item -default => $default (Default: keiner)

Liefere $default, wenn der Benutzer keinen Wert eingibt. An den
Prompt wird die Zeichenkette " ($default) " angehängt.

=item -inHandle => $fh (Default: *STDIN)

Filehandle, von der die Benutzereingabe gelesen wird.

=item -outHandle => $fh (Default: *STDOUT)

Filehandle, auf die der Prompt geschrieben wird.

=item -sloppy => $bool (Default: 0)

Beschränke die möglichen Antworten nicht auf die Liste $valSpec.

=item -timer => \$t (Default: undef)

Addiere Antwortzeit des Benutzer zu Zeitvariable $t hinzu. Dieses
Feature kann genutzt werden, um aus einer Zeitmessung des rufenden
Code die (langsame) Antwortzeit des Benutzers herauszunehmen.

  my $t0 = Time::HiRes::gettimeofday;
  ...
  Quiq::Terminal->askUser($prompt,
      -timer=>\$t0,
      ...
  );
  ...
  printf "Elapsed: %.2f\n",Time::HiRes::gettimeofday-$t0;

Achtung: Der Wert der Zeitvariable wird in die Zukunft verschoben
und sollte daher nur zur Zeitdauermessung verwendet werden.

=item -timeout => $n

Liefere den Defaultwert nach $n Sekunden. Ist kein Defaultwert
angegeben, wirf eine Exception. Diese Option ist für Programme
nützlich, die einen automatischen Default-Ablauf haben, in den
der Benutzer aber eingreifen kann, wenn er das Programm bedient.

=item -ttyIn => $bool (Default: 0)

Lies Eingabe vom Terminal. Der Terminal-Eingabekanal (/dev/tty)
wird mit jedem Aufruf geöffnet und geschlossen.

=item -ttyOut => $bool (Default: 0)

Schreibe Ausgabe auf Terminal. Der Terminal-Ausgabekanal (/dev/tty)
wird mit jedem Aufruf geöffnet und geschlossen.

=item -values => $valSpec (Default: keiner)

Liste der zulässigen Antworten. Ist die Antwort nicht in der Liste
enthalten, wird die Frage erneut gestellt.

=back

=head4 Description

Fordere den Benutzer mit Prompt $text zur Eingabe eines
Werts auf. Der vom Benutzer eingegebene Wert wird zurückgeliefert.
Whitespace am Anfang und am Ende des Werts werden entfernt.

=head4 Example

Eingabe vom Terminal statt von STDIN per Filehandle:

  my $tty = Quiq::FileHandle->new('<','/dev/tty');
  my $val = Quiq::Terminal->askUser($prompt,-inHandle=>$tty);
  $tty->close;

Dasselbe per Option:

  my $val = Quiq::Terminal->askUser($prompt,-ttyIn=>1);

=cut

# -----------------------------------------------------------------------------

sub askUser {
    my $class = shift;
    my $prompt = shift;
    # @_: @opt

    # Optionen

    my $automatic = 0;
    my $color = '';
    my $default = undef;
    my $in = *STDIN;
    my $out = *STDOUT;
    my $sloppy = 0;
    my $timer = undef;
    my $timeout = undef;
    my $ttyIn = 0;
    my $ttyOut = 0;
    my $values = undef;

    if (@_) {
        Quiq::Option->extract(\@_,
            -automatic => \$automatic,
            -color => \$color,
            -default => \$default,
            -inHandle => \$in,
            -outHandle => \$out,
            -sloppy => \$sloppy,
            -timer => \$timer,
            -timeout => \$timeout,
            -ttyIn => \$ttyIn,
            -ttyOut => \$ttyOut,
            -values => \$values,
        );
    }

    if ($automatic) {
        if (defined $default) {
            return $default;
        }
        else {
            $class->throw(
                'ASK-00001: Option -automatic without option -default',
            );
        }
    }

    if ($timeout && !defined $default) {
        $class->throw(
            'ASK-00002: Option -timeout without option -default',
        );
    }

    my $reset = '';
    if ($color) {
        $color = $class->ansiEsc($color);
        $reset = $class->ansiEsc('reset');
    }    

    # Prompt generieren: "$prompt [$val1,$val2,...] ($def)"

    $prompt = sprintf '%s%s%s',$color,$prompt,$reset;

    my (@values,$valuesText);
    if ($values) {
        for my $val (split m|[/,]|,$values) {
            my $text = $val;
            if ($val =~ /\((.+)\)/) {
                # (y)es,(a)bort
                $val = $1;
                $text = sprintf '%s(%s%s%s)%s',$`,$color,$val,$reset,$';
            }
            elsif ($val =~ /^(.*?)=(.*)/) {
                # y=yes,a=abort
                $val = $1;
                $text = sprintf '%s%s%s=%s',$color,$val,$reset,$2;
            }
            push @values,$val;

            $valuesText .= ',' if $valuesText;
            $valuesText .= $text;
        }
    }

    $prompt .= " [$valuesText]" if defined $valuesText;
    $prompt .= " ($default)" if defined $default;
    $prompt .= " " if $valuesText || defined $default;

    # Eingabe lesen und prüfen (falls -values)

    my $t0 = Time::HiRes::gettimeofday;

    my $answ;
    while (1) {
        if ($ttyOut) {
            $out = Quiq::FileHandle->new('>','/dev/tty');
        }
        print $out $prompt;

        if ($ttyIn) {
            $in = Quiq::FileHandle->new('<','/dev/tty');
        }

        if ($timeout) {
            eval {
                local $SIG{ALRM} = sub {die "alarm\n"}; # \n erforderlich
                alarm $timeout;
                $answ = <$in>;
                alarm 0;
            };
            if ($@) {
                # Timeout abgelaufen

                if ($@ ne "alarm\n") {
                    # Unerwarteten Fehler weiterleiten
                    die;
                }
                say $answ = $default;
            }
        }
        else {
            $answ = <$in>;
        }

        if ($ttyIn) {
            $in->close;
        }

        if (defined $answ) {
            # Wert bereinigen

            $answ =~ s/^\s+//;
            $answ =~ s/\s+$//;
            $answ = $default if $answ eq '' && defined $default;
        }
        else { # eof
            print $out "\n";
        }
        if ($ttyOut) {
            $out->close;
        }

        if (@values) {
           next if !defined $answ; # kein Ausstieg mit ^D
           next if !$sloppy && !grep { $_ eq $answ } @values;
        }
        last; # Ausstieg
    }

    if ($timer) {
        $$timer += Time::HiRes::gettimeofday-$t0;
    }

    return $answ;
}

# -----------------------------------------------------------------------------

=head3 ansiEsc() - Liefere ANSI Terminal Escape-Sequenz

=head4 Synopsis

  $esc = $class->ansiEsc($str);

=head4 Description

Liefere die Terminal Escape-Sequenz $esc für die in $str angegebenen
Terminal-Eigenschaften. Es kann eine Kombination aus Eigenschaften
angegeben werden. Die Eigenschaften werden durch Leerzeichen getrennt.

Beginnt $str mit ESC, d.h. ist $str bereits eine Escape-Sequenz,
wird $str unverändert zurückgeliefert.

B<Terminal-Eigenschaften>

  Allgemein    Vordergrund  Hintergrund
  -----------  -----------  -----------
  dark         black        on_black
  bold         red          on_red
  underline    green        on_green
  blink        yellow       on_yellow
  reverse      blue         on_blue
  concealed    magenta      on_magenta
  reset        cyan         on_cyan
               white        on_white

=head4 Example

Rote Schrift:

  $esc = Quiq::Terminal->ansiEsc('red');

Fette weiße Schrift auf rotem Grund:

  $esc = Quiq::Terminal->ansiEsc('bold white on_red');

Terminal in den Anfangszustand zurückversetzen:

  $esc = Quiq::Terminal->ansiEsc('reset');

=cut

# -----------------------------------------------------------------------------

sub ansiEsc {
    my ($class,$str) = @_;
    return substr($str,0,1) eq "\e"? $str: Term::ANSIColor::color($str);
}

# -----------------------------------------------------------------------------

=head3 width() - Liefere die Breite des Terminals

=head4 Synopsis

  $width = $this->width;

=head4 Returns

Integer

=head4 Description

Ermittele die Anzahl der Spalten des Terminals und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub width {
    my $this = shift;

    my $cmd = 'tput cols';
    my $width = `$cmd`;
    Quiq::Exit->check($?,$cmd);
    chomp $width;

    return $width;
}

# -----------------------------------------------------------------------------

=head3 height() - Liefere die Höhe des Terminals

=head4 Synopsis

  $height = $this->height;

=head4 Returns

Integer

=head4 Description

Ermittele die Anzahl der Zeilen des Terminals und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub height {
    my $this = shift;

    my $cmd = 'tput lines';
    my $height = `$cmd`;
    Quiq::Exit->check($?,$cmd);
    chomp $height;

    return $height;
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
