package Quiq::Html::Table::List;
use base qw/Quiq::Html::Table::Base/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Table::List - HTML-Tabelle zum Anzeigen einer Liste von Elementen

=head1 BASE CLASS

L<Quiq::Html::Table::Base>

=head1 DESCRIPTION

Die Klasse erzeugt eine HTML-Tabelle aus einer Liste von
Objekten. Jedes Objekt wird durch eine Zeile dargestellt. Alle
Zeilen- (tr-Elemente) und Zellenattribute (td-Elemente) können
gesetzt werden. Die Klasse ist daher sehr flexibel.

Für jedes Objekt wird die Methode $e->rowCallback() gerufen (falls
nicht angegeben, werden die Daten ohne Verarbeitung kopiert).  Die
Methode bekommt das Objekt und seine (0-basierte) Position in der
Liste der Objekte (Attribut "rows") übergeben. Die Methode liefert
die Spezifikation für die Zeile (tr) und ihre Zellen (td) zurück,
wobei jede Spezifikation ein Array ist, das unmittelbar an die
Methode tag() übergeben wird.

=head1 ATTRIBUTES

Zusätzlich zu den Attributen der Basisklasse definiert die Klasse
folgende Attribute:

=over 4

=item align => \@arr (Default: [])

Ausrichtung des Kolumneninhalts.

=item allowHtml => $bool|\@titles (Default: 0)

Erlaube HTML insgesamt oder auf den Kolumnen in @titles,
d.h. ersetze die Werte der Kolumnen &, <, > I<nicht> automatisch
durch HTML-Entities.

=item empty => $str (Default: '&nbsp;')

HTML-Code, der im Body der Tabelle gesetzt wird, wenn die Liste
der Elemente leer ist. Wenn auf Leerstring, undef oder 0 gesetzt,
wird kein Body angezeigt.

=item footer => $bool (Default: 0)

Setze die Titel @titles auch als Footer.

=item rowCallback => $sub (Default: undef)

Referenz auf eine Subroutine, die für jedes Element die
darzustellende Zeileninformation (für tr- und td-Tag) liefert.
Ist kein rowCallback definiert, werden die Row-Daten
unverändert verwendet.

=item rowCallbackArguments => \@args (Default: [])

Liste von Argumenten, die I<zusätzlich> zu den Standardargumenten
an die Subroutine rowCallback() übergeben werden.

=item rows => \@rows (Default: [])

Liste der Elemente. Für jedes Element wird die Callback-Methode
(Attribut rowCallback) aufgerufen.

=item titles => \@titles (Default: [])

Liste der Kolumnentitel.

=back

=head1 EXAMPLES

Attribute von tr- und td-Elemeten setzen. Für jedes Element
wird eine Arrayreferenz geliefert:

    $e = Quiq::Html::Table::List->new(
        titles => [qw/Id Name Vorname/],
        align => [qw/right left left/],
        rows => \@obj,
        rowCallback => sub {
            my ($row,$i) = @_;
    
            my $trA = [class=>'TRCLASS'];
            push my @tds,[class=>'TDCLASS',$row->get('ATTRIBUTE')];
            ...
    
            return ($trA,@tds);
        },
    );
    $html = $e->html($h);

Lediglich Werte ausgeben. Für das tr-Element wird C<undef> geliefert,
für die td-Elemente ein skalarer Wert (der Content des Elements):

    $e = Quiq::Html::Table::List->new(
        titles => [qw/Id Name Vorname/],
        align => [qw/right left left/],
        rows => \@obj,
        rowCallback => sub {
            my ($row,$i) = @_;
    
            push @arr,$row->get('ATTRIBUTE');
            ...
    
            return (undef,@arr);
        },
    );
    $html = $e->html($h);

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

    $e = $class->new(@keyVal);

=head4 Description

Instantiiere ein Tabellenobjekt mit den Eingenschaften @keyVal und
liefere eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    # Defaultwerte

    my $self = $class->SUPER::new(
        align => [],
        allowHtml => 0,
        empty => '&nbsp;',
        footer => 0,
        rowCallback => undef,
        rowCallbackArguments => [],
        rows => [],
        titles => [],
    );

    # Werte Konstruktoraufruf
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML

=head4 Synopsis

    $html = $e->html($h);
    $html = $class->html($h,@keyVal);

=head4 Description

Generiere HTML-Code für Tabellenobjekt $e und liefere diesen zurück.
Bei Aufruf als Klassenmethode wird das Tabellenobjekt von
der Methode aus den Argumenten @keyVal instantiiert.

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;
    # @_: @keyVal

    my $self = ref $this? $this: $this->new(@_);

    # Attribute

    my ($align,$allowHtml,$empty,$footer,$rowCallback,$rowCallbackArgumentA,
        $rowA,$titleA) = $self->get(qw/align allowHtml empty footer
        rowCallback rowCallbackArguments rows titles/);

    return '' if !@$titleA && !@$rowA;

    my %allowHtml;
    @allowHtml{@$titleA} = (0) x @$titleA;
    if (ref $allowHtml) {
        # $allowHtml als Referenz auf Array von bestimmten Kolumnen
        @allowHtml{@$allowHtml} = (1) x @$allowHtml;
    }
    elsif ($allowHtml) {
        # $allowHtml als boolscher Wert für alle Kolumnen
        @allowHtml{@$titleA} = (1) x @$titleA;
    }

    # Tabelleninhalt

    my $html = '';

    # Kopf

    my $ths;
    if (@$titleA) {
        my $i = 0;
        for my $title (@$titleA) {
            $ths .= $h->tag('th',
                -text => !$allowHtml{$title},
                align => $align->[$i++],
                '-',
                $title
            );
        }
        $html .= $h->tag('thead',
            $h->tag('tr',$ths),
        );
    }

    # Rumpf

    my $trs;
    my $i = 0;
    for my $row (@$rowA) {
        my ($trA,@tds);
        if ($rowCallback) {
            ($trA,@tds) = $rowCallback->($row,$i++,@$rowCallbackArgumentA);
        }
        else {
            @tds = @$row;
        }
        if (!@tds) {
            # Werden keine Kolumnen geliefert, erzeugen wir keine
            # Tabellenzeile. Auf diese Weise kann in der Callback-Methode
            # gefiltert werden.
            next;
        }
        my $tds;
        my $j = 0;
        for my $tdA (@tds) {
            $tds .= $h->tag('td',
                -text => !(@$titleA? $allowHtml{$titleA->[$j]}: $allowHtml),
                align => $align->[$j++],
                ref $tdA? @$tdA: $tdA # Array oder skalarer Wert
            );
        }

        $trs .= $h->tag('tr',
            @$trA,
            $tds
        )
    }
    if (!$trs && $empty) {
        # Keine Objekte vorhanden
        $trs = $h->tag('tr',
            $h->tag('td',
                align => 'center',
                colspan => scalar(@$titleA),
                '-',
                $empty,
            )
        );
    }
    if ($trs) {
        $html .= $h->tag('tbody',$trs);
    }

    # Fuß

    if ($footer && $ths) {
        $html .= $h->tag('tfoot',
            $h->tag('tr',$ths),
        );
    }

    return $self->SUPER::html($h,$html);
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.148

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
