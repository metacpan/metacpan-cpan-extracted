# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Stopwatch - Zeitmesser

=head1 BASE CLASS

L<Quiq::Object>

=head1 SYNOPSIS

Eine Stoppuhr:

  use Quiq::Stopwatch;
  
  my $stw = Quiq::Stopwatch->new;
  ...
  printf "%.2f\n",$stw->elapsed;

Zwei Stoppuhren für Gesamtzeit und Zwischenzeiten:

  use Quiq::Stopwatch;
  
  my $stw = Quiq::Stopwatch->new(2); # Start von zwei Timern
  ...
  printf "%.2f\n",$stw->restart(1); # Abschnittszeit (Timer 1)
  ...
  printf "%.2f\n",$stw->restart(1); # Abschnittszeit (Timer 1)
  ...
  printf "%.2f\n",$stw->elapsed; # Gesamtzeit (Timer 0)

=head1 DESCRIPTION

Die  Klasse implementiert einen einfachen hochauflösenden Zeitmesser.
Mit Aufruf des Konstruktors wird die Zeitmessung gestartet. Mit der
Methode elapsed() kann die seitdem vergangene Zeit abgefragt werden.
Mit der Methode start() wird der Zeitmesser neu gestartet und
die seit dem letzten Start vergangene Zeit zurückgeliefert.
Mittels letzterer Methode ist es möglich, einzelne Codeabschnitte
zu messen, ohne einen neuen Zeitmesser instantiieren zu müssen.
Die Zeit wird in Sekunden gemessen. Die Genauigkeit (d.h. die maximale
Anzahl der Nachkommastellen) ist systemabhängig.
Es können $n Zeitmessungen gleichzeitig geführt werden.

=head1 SEE ALSO

Klasse Quiq::Duration

=cut

# -----------------------------------------------------------------------------

package Quiq::Stopwatch;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Time::HiRes ();
use Quiq::Duration;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $stw = $class->new;
  $stw = $class->new($n);

=head4 Arguments

=over 4

=item $n (Default: 1)

Anzahl der Timer. Diese werden mit 0 .. $n-1 bezeichnet.

=back

=head4 Returns

Stopwatch-Objekt

=head4 Description

Instantiiere eine Stopwatch mit $n Timern und setze sie auf den
aktuellen Zeitpunkt.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $n = shift // 1;

    my $t0 = Time::HiRes::gettimeofday;

    return bless [($t0) x $n],$class;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 elapsed() - Vergangene Zeit in Sekunden

=head4 Synopsis

  $sec = $stw->elapsed;
  $sec = $stw->elapsed($i);

=head4 Arguments

=over 4

=item $i (Default: 0)

Index des abgefragten Timers.

=back

=head4 Returns

Sekunden (Float)

=head4 Description

Liefere die Zeit, die auf Timer $i seit dem (letzten) Start vergangen ist.

=cut

# -----------------------------------------------------------------------------

sub elapsed {
    my $self = shift;
    my $i = shift // 0;
    return Time::HiRes::gettimeofday-$self->[$i];
}

# -----------------------------------------------------------------------------

=head3 elapsedReadable() - Vergangene Zeit in lesbarer Darstellung

=head4 Synopsis

  $duration = $stw->elapsedReadable;
  $duration = $stw->elapsedReadable($i);

=head4 Arguments

=over 4

=item $i (Default: 0)

Index des abgefragten Timers.

=back

=head4 Returns

Dauer (String)

=head4 Description

Liefere die Zeit, die auf Timer $i seit dem (letzten) Start vergangen ist,
in der lesbaren Darstellung DdHhMmSs.

=cut

# -----------------------------------------------------------------------------

sub elapsedReadable {
    my $self = shift;
    my $i = shift // 0;

    my $sec = Time::HiRes::gettimeofday-$self->[$i];
    return Quiq::Duration->new($sec)->asString;
}

# -----------------------------------------------------------------------------

=head3 restart() - Starte Timer neu und liefere vergangene Zeit

=head4 Synopsis

  $sec = $stw->restart;
  $sec = $stw->restart($i);

=head4 Arguments

=over 4

=item $i (Default: 0)

Index des gestarteten Timers.

=back

=head4 Returns

Sekunden (Float)

=head4 Description

Starte Timer $i (setze ihn auf den aktuellen Zeitpunkt) und liefere
die seit dem letzten Start vergangene Zeit zurück.

=cut

# -----------------------------------------------------------------------------

sub restart {
    my $self = shift;
    my $i = shift // 0;

    my $now = Time::HiRes::gettimeofday;
    my $start = $self->[$i];
    $self->[$i] = $now;

    return $now-$start;
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
