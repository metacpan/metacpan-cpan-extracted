package Quiq::Epoch;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.151';

use Time::HiRes ();
use Time::Local ();
use POSIX ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Epoch - Ein Zeitpunkt

=head1 BASE CLASS

L<Quiq::Object>

=head1 GLOSSARY

=over 4

=item Epoch-Wert

Anzahl der Sekunden seit 1.1.1970, 0 Uhr UTC in hoher Auflösung,
also mit Nachkommastellen.

=item ISO-Zeitangabe

Zeitangabe in der Darstellung C<YYYY-MM-DD HH:MI:SS.X>.

=back

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Zeitpunkt. Die Klasse
implementiert Operationen auf einem solchen Zeitpunkt. Der
Zeitpunkt ist hochauflösend, umfasst also auch Sekundenbruchteile.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $t = $class->new;
    $t = $class->new($epoch);
    $t = $class->new($iso);

=head4 Description

Instantiiere ein Zeitpunkt-Objekt für Epoch-Wert $epoch bzw.
ISO-Zeitangabe $iso, interpretiert in der lokalen Zeitzone, und
liefere dieses Objekt zurück. Ist kein Argument angegeben, wird
der aktuelle Zeitpunkt genommen.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $epoch = shift // scalar(Time::HiRes::gettimeofday);

    if ($epoch !~ /^[\d.]+$/) {
        # ISO Zeitangabe

        my @arr = reverse split /\D+/,$epoch;
        $arr[4]--;
        $epoch = Time::Local::timelocal(@arr);
    }

    return bless \$epoch,$class;
} 

# -----------------------------------------------------------------------------

=head2 Externe Repräsentation

=head3 epoch() - Liefere Epoch-Wert

=head4 Synopsis

    $epoch = $t->epoch;

=head4 Description

Liefere den Epoch-Wert des Zeitpunkts.

=head4 Example

    Quiq::Epoch->new->epoch;
    =>
    1464342621.73231

=cut

# -----------------------------------------------------------------------------

sub epoch {
    return ${(shift)}
} 

# -----------------------------------------------------------------------------

=head3 localtime() - Zeitkomponenten in lokaler Zeit

=head4 Synopsis

    ($s,$mi,$h,$d,$m,$y) = $t->localtime;

=head4 Description

Liefere die Zeitkomponenten Sekunden, Minuten, Stunden, Tag, Monat, Jahr
in lokaler Zeit. Im Unterschied zu localtime() aus dem Perl Core sind
Monat ($m) und Jahr (y) "richtig" wiedergegeben. d.h die Komponente $m
muss nicht inkrementiert und die Komponente $y muss nicht um 1900
erhöht werden.

=head4 Example

    Quiq::Epoch->new(1559466751)->localtime;
    =>
    (31,12,11,2,6,2019) # 2019-06-02 11:12:31
    
    (in Zeitzone MESZ)

=cut

# -----------------------------------------------------------------------------

sub localtime {
    my $self = shift;

    my @arr = CORE::localtime $$self;
    $arr[4]++;
    $arr[5] += 1900;

    return @arr;
} 

# -----------------------------------------------------------------------------

=head3 as() - Erzeuge String-Darstellung

=head4 Synopsis

    $str = $t->as($fmt);

=head4 Description

Liefere eine externe Repräsentation gemäß Formatangabe $fmt. Der
Zeitpunkt wird in der lokalen Zeitzone interpretiert.

=head4 Example

    Quiq::Epoch->new->as('YYYY-MM-DD HH:MI:SS');
    =>
    2016-05-27 11:50:21

=cut

# -----------------------------------------------------------------------------

sub as {
    my ($self,$fmt) = @_;

    my $strFmt;
    if ($fmt eq 'YYYY-MM-DD HH:MI:SS') {
        $strFmt = '%Y-%m-%d %H:%M:%S';
    }
    else {
        $self->throw;
    }
    
    return POSIX::strftime($strFmt,CORE::localtime $$self);
} 

# -----------------------------------------------------------------------------

=head1 VERSION

1.151

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
