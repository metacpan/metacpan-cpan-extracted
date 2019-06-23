package Quiq::Formatter;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::Epoch;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Formatter - Formatierung von Werten

=head1 BASE CLASS

L<Quiq::Object>

=head1 METHODS

=head2 Zahlen

=head3 normalizeNumber() - Normalisiere Zahldarstellung

=head4 Synopsis

    $x = $class->normalizeNumber($x);

=head4 Description

Entferne unnötige Nullen von einer Zahl, forciere als Dezimaltrennzeichen
einen Punkt (anstelle eines Komma) und liefere das Resultat zurück.

=head4 Example

    123.456000 -> 123.456
    70.00 -> 70
    0.0 -> 0
    -0.0 -> 0
    007 -> 7
    23,7 -> 23.7

=cut

# -----------------------------------------------------------------------------

sub normalizeNumber {
    my ($class,$x) = @_;

    # Wandele Komma in Punkt
    $x =~ s/,/./;

    # Entferne führende 0en
    $x =~ s/^(-?)0+(?=\d)/$1/;

    if (index($x,'.') >= 0) {
        # Bei einer Kommazahl entferne 0en und ggf. Punkt am Ende
        $x =~ s/\.?0+$//;
    }

    if ($x eq '-0') {
        $x = 0;
    }

    return $x;
}

# -----------------------------------------------------------------------------

=head3 readableNumber() - Zahl mit Trenner an Tausender-Stellen

=head4 Synopsis

    $str = $class->readableNumber($x);
    $str = $class->readableNumber($x,$sep);

=head4 Description

Formatiere eine Zahl $x mit Tausender-Trennzeichen $sep. Per
Default ist $sep ein Punkt (C<.>). Handelt es sich bei $x um eine
Zahl mit Nachkomma-Stellen, wird der Punkt durch ein Komma (C<,>)
ersetzt.

=head4 Example

    1 -> 1
    12 -> 12
    12345 -> 12.345
    -12345678 -> -12.345.678
    -12345.678 -> -12.345,678

=cut

# -----------------------------------------------------------------------------

sub readableNumber {
    my $class = shift;
    my $x = shift;
    my $sep = shift || '.';

    if ($sep eq '.') {
        $x =~ s/\./,/;
    }
    1 while $x =~ s/^([-+]?\d+)(\d{3})/$1$sep$2/;

    return $x;
}

# -----------------------------------------------------------------------------

=head2 Datums/Zeitangaben

=head3 reducedIsoTime() - Erzeuge reduzierte ISO-Zeitdarstellung

=head4 Synopsis

    $str = $class->reducedIsoTime($now,$time);

=head4 Arguments

=over 4

=item $now

Bezugszeitpunkt in Unix Epoch oder als ISO-Datum.

=item $time

Zeit in Unix Epoch oder als ISO-Datum.

=back

=head4 Returns

Reduzierte ISO-Zeitdarstellung (String)

=head4 Description

Erzeuge eine "reduzierte" ISO-Zeitdarstellung für Zeitpunkt $time
relativ zu Bezugszeitpunkt $now. Die I<unreduzierte> ISO-Zeitdarstellung
hat das Format:

    YYYY-MM-DD HH:MM:SS

Die I<reduzierte> Dastellung ist identisch aufgebaut, nur dass alle
führenden Zeitkomponenten fehlen, die zum Bezugszeitpunkt $now
identisch sind.

Diese Darstellung ist nützlich, um in einer Liste von Zeiten die
nah am aktuellen Zeipunkt liegenden Zeiten leichter erkennen zu können,
z.B. in einer Verzeichnisliste:

    $ quiq-ls ~/dvl
    | rwxr-xr-x | xv882js | rvgroup | 2018-07-07 07:08:17 |  | d | ~/dvl/.cotedo  |
    | rwxr-xr-x | xv882js | rvgroup | 2018-06-29 11:06:38 |  | d | ~/dvl/.jaz     |
    | rwxr-xr-x | xv882js | rvgroup |         17 07:29:51 |  | d | ~/dvl/Blob     |
    | rwxr-xr-x | xv882js | rvgroup |         17 07:29:52 |  | d | ~/dvl/Export   |
    | rwxr-xr-x | xv882js | rvgroup |         17 07:29:52 |  | d | ~/dvl/Language |
    | rwxr-xr-x | xv882js | rvgroup |         17 07:29:52 |  | d | ~/dvl/Library  |
    | rwxr-xr-x | xv882js | rvgroup |               37:47 |  | d | ~/dvl/Package  |

=head4 Examples

Keine gemeinsame Zeitkomponente:

    Quiq::Formatter->reducedIsoTime(1558593179,1530940097);
    ==>
    2018-07-07 07:08:17

Jahr und Monat sind gemeinsam:

    Quiq::Formatter->reducedIsoTime(1558593179,1558070991);
    ==>
    17 07:29:51

Alle Komponenten, bis auf die Sekunden, sind identisch:

    Quiq::Formatter->reducedIsoTime(1558593179,1558593168);
    ==>
    48

(alles in Zeitzone MESZ)

=cut

# -----------------------------------------------------------------------------

sub reducedIsoTime {
    my ($class,$now,$time) = @_;

    my @now = Quiq::Epoch->new($now)->localtime;
    my @time = Quiq::Epoch->new($time)->localtime;

    my $str = '';
    if ($time[5] != $now[5]) {
        $str .= $time[5];
    }
    if ($str || $time[4] != $now[4]) {
        $str .= sprintf '%s%02d',$str? '-': '',$time[4];
    }
    if ($str || $time[3] != $now[3]) {
        $str .= sprintf '%s%02d',$str? '-': '',$time[3];
    }
    if ($str || $time[2] != $now[2]) {
        $str .= sprintf '%s%02d',$str? ' ': '',$time[2];
    }
    if ($str || $time[1] != $now[1]) {
        $str .= sprintf '%s%02d',$str? ':': '',$time[1];
    }
    if ($str || $time[0] != $now[0]) {
        $str .= sprintf '%s%02d',$str? ':': '',$time[0];
    }

    return $str;
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
