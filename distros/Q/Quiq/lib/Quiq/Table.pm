package Quiq::Table;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::Hash;
use Quiq::Properties;
use Quiq::TableRow;
use Quiq::AnsiColor;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Table - Tabelle

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

Mit Kolumnennamen:

    use Quiq::Table;
    
    # Daten
    
    @rows = (
        [1,  'A',  76.253],
        [12, 'AB', 1.7   ],
        [123,'ABC',9999  ],
    );
    
    # Objekt instantiieren
    $tab = Quiq::Table->new(['a','b','c'],\@rows);
    
    # Werte der Kolumne b
    
    @values = $tab->values('b');
    say "@values";
    ==>
    A AB ABC
    
    # Ausgabe als Text-Tabelle
    
    print $tab->asText;
    ==>
    |   1 | A   |   76.253 |
    |  12 | AB  |    1.700 |
    | 123 | ABC | 9999.000 |

Ohne Kolumnennamen:

    use Quiq::Table;
    
    # Daten
    
    @rows = (
        [1,  'A',  76.253],
        [12, 'AB', 1.7   ],
        [123,'ABC',9999  ],
    );
    
    # Objekt instantiieren
    $tab = Quiq::Table->new(3,\@rows);
    
    # Werte der Kolumne 1 (0-basierte Zählung)
    
    @values = $tab->values(1);
    say "@values";
    ==>
    A AB ABC
    
    # Ausgabe als Text-Tabelle
    
    print $tab->asText;
    ==>
    |   1 | A   |   76.253 |
    |  12 | AB  |    1.700 |
    | 123 | ABC | 9999.000 |

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Tabelle, also eine Liste
von Arrays identischer Größe. Die Kolumnen können über ihre Position
oder ihren Namen (sofern definiert) angesprochen werden.
Die Klasse kann die Daten in verschiedenen Formaten tabellarisch
ausgegeben.

=head1 EXAMPLE

Siehe quiq-ls

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

    $tab = $class->new($width);
    $tab = $class->new($width,\@rows);
    $tab = $class->new(\@columns);
    $tab = $class->new(\@columns,\@rows);

=head4 Arguments

=over 4

=item $width

Anzahl der Kolumnen (Integer).

=item @columns

Liste von Kolumnennamen (Array of Strings).

=item @rows

Liste von Zeilen (Array of Arrays).

=back

=head4 Returns

Referenz auf Tabellen-Objekt

=head4 Description

Instantiiere ein Tabellen-Objekt und liefere eine Referenz auf dieses
Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$arg,$rowA) = @_;

    # Objekt instantiieren

    my $self = $class->SUPER::new(
        columnA => [],
        columnH => {},
        propertyA => undef,
        rowA => [],
        width => 0,
    );

    # Kolumnen

    if (ref $arg) {
        # \@columns

        my $i = 0;
        $self->set(
            width => scalar @$arg,
            columnA => $arg,
            columnH => Quiq::Hash->new({map {$_ => $i++} @$arg}),
        );
    }
    else {
        # $width
        $self->set(width=>$arg);
    }

    # Zeilen

    for my $row (@$rowA) {
        $self->push($row);
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 columns() - Liste der Kolumnennamen

=head4 Synopsis

    @columns | $columnA = $tab->columns;

=head4 Returns

Liste der Kolumnennamen (Strings). Im Skalarkontext eine Referenz
auf die Liste.

=head4 Description

Liefere die Liste der Kolumnennamen der Tabelle.

=cut

# -----------------------------------------------------------------------------

sub columns {
    my $self = shift;

    my $columnA = $self->{'columnA'};
    if (!@$columnA) {
        $self->throw(
            'TABLE-00099: No column names defined',
        );
    }
    return wantarray? @$columnA: $columnA;
}

# -----------------------------------------------------------------------------

=head3 count() - Anzahl der Zeilen

=head4 Synopsis

    $count = $tab->count;

=head4 Returns

Integer

=head4 Description

Liefere die Anzahl der Zeilen der Tabelle.

=cut

# -----------------------------------------------------------------------------

sub count {
    my $self = shift;
    return scalar @{$self->{'rowA'}};
}

# -----------------------------------------------------------------------------

=head3 pos() - Position einer Kolumne

=head4 Synopsis

    $pos = $tab->pos($column);
    $pos = $tab->pos($pos);

=head4 Arguments

=over 4

=item $column

Kolumnenname (String).

=item $pos

Kolumnenposition (Integer).

=back

=head4 Returns

Integer

=head4 Description

Liefere die Position der Kolumne $column in den Zeilen-Arrays.
Die Position ist 0-basiert. Ist das Argument eine Zahl (Position),
liefere diese unverändert zurück.

=cut

# -----------------------------------------------------------------------------

sub pos {
    my ($self,$arg) = @_;

    if ($arg =~ /^[0-9]+$/) {
        return $arg;
    }

    my $columnH = $self->{'columnH'};
    if (!%$columnH) {
        $self->throw(
            'TABLE-00099: No column names defined',
        );
    }

    return $columnH->{$arg};
}

# -----------------------------------------------------------------------------

=head3 properties() - Eigenschaften einer Kolumne

=head4 Synopsis

    $prp = $tab->properties($pos);
    $prp = $tab->properties($column);

=head4 Arguments

=over 4

=item $column

Kolumnenname (String).

=back

=head4 Returns

Properties-Objekt (Quiq::Properties)

=head4 Description

Ermittele die Eigenschaften der Werte der Kolumne $column und liefere
ein Objekt, das diese Eigenschaften abfragbar zur Verfügung stellt,
zurück. Die Eigenschaften werden gecacht, so dass bei einem wiederholten
Aufruf die Eigenschaften nicht erneut ermittelt werden müssen. Wird die
Tabelle mit push() erweitert, wird der Cache automatisch gelöscht.

=cut

# -----------------------------------------------------------------------------

sub properties {
    my ($self,$arg) = @_;

    my $pos = $self->pos($arg);
    my $prp = $self->{'propertyA'}->[$pos];
    if (!$prp) {
        $prp = Quiq::Properties->new;
        for my $val ($self->values($pos,-distinct=>1)) {
            $prp->analyze($val);
        }
        $self->{'propertyA'}->[$pos] = $prp;
    }

    return $prp;
}

# -----------------------------------------------------------------------------

=head3 push() - Füge Zeile hinzu

=head4 Synopsis

    $tab->push(\@arr);

=head4 Arguments

=over 4

=item @arr

Liste von Zeilendaten (Strings).

=back

=head4 Description

Füge eine Zeile mit den Kolumnenwerten @arr zur Tabelle hinzu. Die Anzahl der
Elemente in @arr muss mit der Anzahl der Kolumnen übereinstimmen,
sonst wird eine Exception geworfen. Durch das Hinzufügen einer Zeile
werden die gecachten Kolumneneigenschaften - sofern vorhanden -
gelöscht (siehe Methode L<properties|"properties() - Eigenschaften einer Kolumne">()).

=cut

# -----------------------------------------------------------------------------

sub push {
    my ($self,$valueA) = @_;

    my $row = Quiq::TableRow->new($self,$valueA);
    $self->SUPER::push('rowA',$row);
    $self->{'propertyA'} = undef; # Kolumneneigenschaften löschen

    return;
}

# -----------------------------------------------------------------------------

=head3 rows() - Liste der Zeilen

=head4 Synopsis

    @rows | $rowA = $tab->rows;

=head4 Returns

Liste der Zeilen (Objekte der Klasse Quiq::TableRow). Im Skalarkontext
eine Referenz auf die Liste.

=head4 Description

Liefere die Liste der Zeilen der Tabelle.

=cut

# -----------------------------------------------------------------------------

sub rows {
    my $self = shift;

    my $rowA = $self->{'rowA'};
    return wantarray? @$rowA: $rowA;
}

# -----------------------------------------------------------------------------

=head3 values() - Werte einer Kolumne

=head4 Synopsis

    @values | $valueA = $tab->values($pos,@opt);
    @values | $valueA = $tab->values($column,@opt);

=head4 Arguments

=over 4

=item $column

Kolumnenname (String).

=back

=head4 Options

=over 4

=item -distinct => $bool (Default: 0)

Liste der I<verschiedenen> Werte.

=back

=head4 Returns

Liste der Werte (Strings). Im Skalarkontext eine Referenz auf die Liste.

=head4 Description

Liefere die Liste der Werte der Kolumne $column. Per Default wird die
Liste I<aller> Werte geliefert, auch wenn sie mehrfach vorkommen. Siehe
auch Option C<-distinct>.

=cut

# -----------------------------------------------------------------------------

sub values {
    my ($self,$arg) = splice @_,0,2;
    # @_: @opt

    # Optionen

    my $distinct = 0;

    $self->parameters(\@_,
        -distinct => \$distinct,
    );

    # Operation ausführen

    my (@arr,%seen);
    my $pos = $self->pos($arg);
    for my $row (@{$self->{'rowA'}}) {
        my $val = $row->[1][$pos];
        if ($distinct && $seen{$val//''}++) {
            next;
        }
        CORE::push @arr,$val;
    }

    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head3 width() - Anzahl der Kolumnen

=head4 Synopsis

    $width = $tab->width;

=head4 Returns

Integer

=head4 Description

Liefere die Anzahl der Kolumnen der Tabelle.

=cut

# -----------------------------------------------------------------------------

sub width {
    return shift->{'width'};
}

# -----------------------------------------------------------------------------

=head2 Formatierung

=head3 asText() - Tabelle als Text

=head4 Synopsis

    $text = $tab->asText(@opt);

=head4 Options

=over 4

=item -colorize => $sub

Callback-Funktion, die für jede Zelle gerufen wird und eine Termnal-Farbe
für die jeweilige Zelle liefert. Die Funktion hat die Struktur:

    sub {
        my ($tab,$row,$pos,$val) = @_;
        ...
        return $color;
    }

Die Terminal-Farbe ist eine Zeichenkette, wie sie Quiq::AnsiColor
erwartet. Anwendungsbeispiel siehe quiq-ls.

=back

=head4 Returns

Text-Tabelle (String)

=cut

# -----------------------------------------------------------------------------

sub asText {
    my $self = shift;

    # Optionen

    my $colorizeS = undef;

    $self->parameters(\@_,
        -colorize => \$colorizeS,
    );

    # Kolumneneigenschaften
    my @properties = map {$self->properties($_)} 0 .. $self->width-1;

    # Terminal-Farben
    my $a = Quiq::AnsiColor->new;

    # Erzeuge Tabellenzeile

    my $str = '';
    for my $row ($self->rows) {
        my @row;
        my $valueA = $row->values;
        for (my $i = 0; $i < @$valueA; $i++) {
            my $val = sprintf $properties[$i]->format('text',$valueA->[$i]);
            if ($colorizeS) {
                if (my $color = $colorizeS->($self,$row,$i,$val)) {
                    $val = $a->str($color,$val);
                }
            }
            CORE::push @row,$val;
        }
        $str .= '| '.join(' | ',@row)." |\n";
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
