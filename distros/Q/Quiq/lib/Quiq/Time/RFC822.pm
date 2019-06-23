package Quiq::Time::RFC822;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use POSIX qw/:locale_h/;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Time::RFC822 - Erzeuge Zeitangabe nach RFC 822

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Die von der Klasse generierte Zeitangabe wird für Expires und
Set-Cookie HTTP-Header verwendet.

=head1 SEE ALSO

=over 2

=item *

Zeitangabe nach RFC 822
(L<http://tools.ietf.org/html/rfc822#section-5>)

=back

=head1 METHODS

=head2 Klassenmethoden

=head3 get() - Liefere Zeitangabe nach RFC 822

=head4 Synopsis

    $str = $class->get($val);

=head4 Description

Konvertiere Argument $val in eine Zeitangabe nach RFC 822 und
liefere diese zurück.

B<Zeitangabe nach RFC 822>

    Wdy, DD-Mon-YYYY HH:MM:SS GMT

B<Arguments>

Als Argument $val ist eine Uhrzeit (des heutigen oder morgigen
Tages im Format HH:MM), ein bestimmter Zeitpunkt in Unix-Zeit
(Sekunden seit 1.1.1970 00:00, GMT), ein Zeitoffset in Sekunden,
Minuten, Stunden, Tagen oder Jahren (relativ zum aktuellen Zeitpunkt)
oder 'now' und 0 zulässig:

    N         (Unix-Zeit)
    HH:MM     (Zeitpunkt in der Zukunft)
    +N[ydhms] (Zeit-Offset)
    now       (jetzt)
    0         (Beginn Unix Epoch)

B<Examples>

    1502795715 (irgendein Zeitpunkt in Unix-Zeit)
    23:00      (heute 23:00 lokale Zeit, wenn akt. lokale Uhrzeit < 23:00)
    8:00       (morgen 8:00 lokale Zeit, wenn akt. lokale Uhrzeit >= 8:00)
    +1y        (plus ein Jahr)
    +7d        (plus sieben Tage)
    +10h       (plus zehn Stunden)
    +30m       (plus eine halbe Stunde)
    +30s       (plus 30 Sekunden)
    now        (jetzt)
    0          (1.1.1970 00:00:00)

=cut

# -----------------------------------------------------------------------------

sub get {
    my ($class,$val) = @_;

    # aktuelles Zeitformat merken
    my $loc = POSIX::setlocale(POSIX::LC_TIME);

    # Amerikanisches Zeitformat einstellen
    POSIX::setlocale(POSIX::LC_TIME,'C'); # Fix: CPAN Testers

    my $format = '%a, %d-%b-%Y %H:%M:%S GMT';

    if (!defined($val) || $val eq 'now') {
        $val = POSIX::strftime($format,gmtime);
    }
    elsif ($val eq '0') {
        $val = POSIX::strftime($format,gmtime 0);
    }
    elsif ($val =~ /^(\d+)$/) {
        $val = POSIX::strftime($format,gmtime $1);
    }
    elsif ($val =~ /^(\d?\d):(\d\d)$/) {
        my @time = localtime(CORE::time);
        @time[0 .. 2] = (0,$2,$1);
        my $time = timelocal(@time);

        # Wenn Zeitlimit innerhalb des Tages erreicht ist,
        # einen Tag draufaddieren
        $time += 86400 if $time <= CORE::time;

        $val = POSIX::strftime($format,gmtime($time));
    }
    elsif ($val =~ /^(\+\d+)([smhdy])$/) {
        my ($delta,$unit) = ($1,$2);

        if ($unit eq 'y') {
            my(@time) = gmtime(CORE::time);
            $time[5] += $delta;

            $val = POSIX::strftime($format,@time);
        }
        else {
            if ($unit eq 'm') { $delta *= 60 }
            elsif ($unit eq 'h') { $delta *= 3600 }
            elsif ($unit eq 'd') { $delta *= 86400 }

            $val = POSIX::strftime($format,gmtime(CORE::time+$delta));
        }
    }

    # Ursprüngliches Zeitformat wiederherstellen
    POSIX::setlocale(POSIX::LC_TIME,$loc);

    return $val;
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
