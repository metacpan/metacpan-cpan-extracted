# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Schedule - Matrix von zeitlichen Vorgängen

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ordne eine Menge von zeitlichen Vorgängen (z.B. gelaufene Prozesse)
in einer Reihe von Zeitschienen (Matrix) an. Finden Vorgänge parallel
statt (also zeitlich überlappend), hat die Matrix mehr als eine
Zeitschiene.

=cut

# -----------------------------------------------------------------------------

package Quiq::Schedule;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Hash;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $mtx = $class->new(\@objects,$sub);

=head4 Arguments

=over 4

=item @objects

Liste von Objekten, die einen Anfangs- und einen End-Zeitpunkt
besitzen.

=item $sub

Subroutine, die den Anfangs- und den Ende-Zeitpunkt des
Objektes in Unix-Epoch liefert. Signatur:

  sub {
      my $obj = shift;
  
      my $epoch1 = ...;
      my $epoch2 = ...;
  
      return ($epoch1,$epoch2);
  }

=back

=head4 Returns

Matrix-Objekt

=head4 Description

Instantiiere ein Matrix-Objekt für die Vorgänge @objects und
liefere eine Referenz auf dieses Objekt zurück.

B<Algorithmus>

=over 4

=item 1.

Wir beginnen mit einer leeren Liste von Zeitschienen.

=item 2.

Die Objekte @objects werden nach Anfangszeitpunkt aufsteigend
sortiert.

=item 3.

Es wird über die Objekte iteriert. Das aktuelle Objekt wird zu der
ersten Zeitschiene hinzugefügt, die frei ist. Eine Zeitschiene
ist frei, wenn sie leer ist oder der Ende-Zeitpunkt des letzten
Elements vor dem Anfangs-Zeitpunkt des aktuellen Objekts liegt.

=back

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$processA,$sub) = @_;

    # Anfangs- und Endezeit in Epoch ermitteln und zu
    # jedem Objekt einen (temporären) Eintrag bestehend
    # aus [$begin,$end,$obj] erzeugen.

    my (@arr,$minTime,$maxTime);
    for my $obj (@$processA) {
        my ($begin,$end) = $sub->($obj);
        if (!defined($minTime) || $begin && $begin < $minTime) {
            $minTime = $begin;
        }
        if (!defined($maxTime) || $end && $end > $maxTime) {
            $maxTime = $end;
        }
        push @arr,Quiq::Hash->new(
            timeline => undef,
            begin => $begin,
            end => $end,
            object => $obj,
        );
    }

    # Fehlt ein Ende-Zeitpunkt, setzen wir diesen auf $maxTime

    for my $e (@arr) {
        my $end = $e->{'end'};
        if (!defined($end) || $end eq '') {
            $e->end($maxTime);
        }
    }

    # Einträge auf die Zeitschienen verteilen

    my @timelines;
    for my $e (sort {$a->{'begin'} <=> $b->{'begin'}} @arr) {
        for (my $i = 0; $i <= @timelines; $i++) {
            if ($timelines[$i] &&
                    $e->{'begin'} < $timelines[$i]->[-1]->{'end'}) {
                # Zeitschiene ist durch einen anderen Prozess belegt.
                # Wir versuchen es mit der nächsten Zeitschiene.
                next;
            }

            # Freie Zeitschiene gefunden, Eintrag hinzufügen

            $e->{'timeline'} = $i;
            push @{$timelines[$i]},$e;
            last;
        }
    }

    # Matrix-Objekt instantiieren

    return $class->SUPER::new(
         minTime => $minTime,
         maxTime => $maxTime,
         timelineA => \@timelines,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 entries() - Einträge der Prozess-Matrix

=head4 Synopsis

  @entries | $entryA = $mtx->entries;
  @entries | $entryA = $mtx->entries($i);

=head4 Returns

Liste von Prozess-Matrix-Einträgen (Array of Quiq::Hash). Im
Skalarkontext eine Referenz auf die Liste.

=head4 Description

Liefere die Liste der Einträge in der Prozess-Matrix. Ist $i
angegeben, nur die Einträge der Zeitleiste $i. Ein Eintrag ist
ein Quiq:Hash-Objekt mit den Attributen:

=over 4

=item timeline

Index der Zeitleiste.

=item begin

Anfangszeitpunkt in Unix Epoch.

=item end

Ende-Zeitpunkt in Unix Epoch.

=item object

Referenz auf das ursprüngliche Objekt.

=back

=cut

# -----------------------------------------------------------------------------

sub entries {
    my ($self,$i) = @_;

    my $timelineA = $self->{'timelineA'};

    my $arr;
    if (defined $i) {
        $arr = $timelineA->[$i];
    }
    else {
        my $width = $self->width;
        for (my $i = 0; $i < $width; $i++) {
            push @$arr,@{$timelineA->[$i]};
        }
        @$arr = sort {$a->begin <=> $b->begin} @$arr;
    }

    return wantarray? @$arr: $arr;
}

# -----------------------------------------------------------------------------

=head3 maxLength() - Maximale Anzahl Einträge in einer Zeitleiste

=head4 Synopsis

  $n = $mtx->maxLength;

=head4 Returns

Integer

=head4 Description

Liefere die maximale Anzahl an Einträgen in einer Zeitschiene.

=cut

# -----------------------------------------------------------------------------

sub maxLength {
    my $self = shift;

    my $maxLength = 0;

    my $width = $self->width;
    my $timelineA = $self->{'timelineA'};

    for (my $i = 0; $i < $width; $i++) {
        my $n = @{$timelineA->[$i]};
        if ($n > $maxLength) {
            $maxLength = $n;
        }
    }

    return $maxLength;
}

# -----------------------------------------------------------------------------

=head3 minTime() - Frühester Anfangs-Zeitpunkt

=head4 Synopsis

  $epoch = $mtx->minTime;

=head4 Returns

Float

=head4 Description

Liefere den frühesten Anfangs-Zeitpunkt über allen Objekten.

=cut

# -----------------------------------------------------------------------------

sub minTime {
    return shift->{'minTime'};
}

# -----------------------------------------------------------------------------

=head3 maxTime() - Spätester Ende-Zeitpunkt

=head4 Synopsis

  $epoch = $mtx->maxTime;

=head4 Returns

Float

=head4 Description

Liefere den spätesten Ende-Zeitpunkt  über allen Objekten.

=cut

# -----------------------------------------------------------------------------

sub maxTime {
    return shift->{'maxTime'};
}

# -----------------------------------------------------------------------------

=head3 width() - Breite der Matrix

=head4 Synopsis

  $width = $mtx->width;

=head4 Returns

Integer

=head4 Description

Liefere die Anzahl der Kolumnen der Matrix.

=cut

# -----------------------------------------------------------------------------

sub width {
    return scalar @{shift->{'timelineA'}};
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
