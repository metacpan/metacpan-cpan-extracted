package Quiq::Properties;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::Parameters;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Properties - Eigenschaften einer Menge von skalaren Werten

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Ein Objekt der Klasse ist Träger von Information über eine
Menge von skalaren Werten (Integer, Float, String). Die Information
ist nützlich, wenn die Menge der Werte tabellarisch dargestellt werden
soll.

=head1 ATTRIBUTES

=over 4

=item type

Typ der Wertemenge: s (Text), f (Float), d (Integer).

=item width

Breite des breitesten Werts der Wertemenge.

=item floatPrefix

Maximale Anzahl an Zeichen einer Fließkommazahl vor und einschließlich
dem Punkt. Dieses Attribut wird nur intern gebraucht, um die maximale
Breite einer Fließkommazahl zu bestimmen.

=item scale

Maximale Anzahl an Nachkommastellen im Falle einer Wertemenge
vom Typ f (Float).

=item align

Ausrichtung der Werte der Wertemenge: l (left), r (right).

=back

=head1 EXAMPLE

Erzeuge eine formatierte Liste von Float-Werten:

    my @values = (
        234.567,
          5.45,
      92345.6,
         42.56739,
    );
    
    my $prp = Quiq::Properties->new(\@values);
    
    my $text;
    for (@values) {
        $text .= $prp->format('text',$_)."\n";
    }
    print $text;
    
    __END__
      234.56700
        5.45000
    92345.60000
       42.56739

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

    $prp = $class->new(@opt);
    $prp = $class->new(\@values,@opt);

=head4 Arguments

=over 4

=item @arr

Array von skalaren Werten (Integers, Floats, Strings)

=back

=head4 Options

=over 4

=item -noTrailingZeros => $bool (Default: 0)

Entferne bei Floats nach dem Dezimalpunkt 0-en am Ende.

=back

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück. Ist als Parameter eine Referenz auf ein Array
angegeben, werden dessen Werte analysiert.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @opt -or- $valueA,@opt

    # Argumente und Optionen

    my $noTrailingZeros = 0;

    my $argA = Quiq::Parameters->extractToVariables(\@_,0,1,
        -noTrailingZeros => \$noTrailingZeros,
    );
    my $valueA = shift(@$argA) // [];

    # Instantiiere Objekt

    #                 0 type
    #                 |   1 width
    #                 |   | 2 floatPrefix
    #                 |   | | 3 scale
    #                 |   | | | 4 align
    #                 |   | | | |   5 Option $noTrailingZeros
    #                 |   | | | |   |
    my $self = bless ['d',0,0,0,'r',$noTrailingZeros],$class;

    # Analysiere Werte

    for (@$valueA) {
        $self->analyze($_);
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Akzessoren

=head3 align() - Setze/Liefere Ausrichtung der Werte

=head4 Synopsis

    $align = $prp->align;
    $align = $prp->align($align);

=head4 Returns

Ausrichtung (Zeichen)

=head4 Description

Setze/Liefere die Ausrichtung der Werte, falls sie tabellarisch
angezeigt werden sollen.

=over 2

=item *

Eine Wertemenge vom Typ d oder f hat die Ausrichtung r.

=item *

Eine Wertemenge vom Typ s hat per Default die Ausrichtung l,
die aber auf r geändert werden werden kann.

=back

=cut

# -----------------------------------------------------------------------------

sub align {
    my $self = shift;
    # @_ $align

    if (@_) {
        $self->[4] = shift;
    }

    return $self->type eq 's'? ($self->[1] == 0? 'l': $self->[4]): 'r';
}

# -----------------------------------------------------------------------------

=head3 scale() - Maximale Anzahl Nachkommastellen

=head4 Synopsis

    $scale = $prp->scale;

=head4 Returns

Integer

=head4 Description

Liefere die Maximale Anzahl an Nachkommastellen. Diese Information
hat nur im Falle des Typs f (Float) eine Bedeutung.

=cut

# -----------------------------------------------------------------------------

sub scale {
    my $self = shift;
    return $self->type eq 'f'? $self->[3]: 0;
}

# -----------------------------------------------------------------------------

=head3 type() - Liefere/Setze Typ der Kolumne

=head4 Synopsis

    $type = $prp->type;
    $type = $prp->type($type);

=head4 Returns

Typbezeichner (Zeichen)

=head4 Description

Liefere den Typ der Kolumne.

=over 2

=item *

Eine Wertmenge hat den Typ d, wenn sie ausschließlich aus
Integern (und Leerstrings) besteht.

=item *

Eine Wertmenge hat den Typ f, wenn sie ausschließlich aus numerischen
Werten (und Leerstrings) besteht und wenigstens ein numerischer
Wert einen Dezimalpunkt enthält, also Nachkommastellen besitzt.

=item *

Eine Wertmenge hat den Typ s, wenn sie leer ist, nur aus Leerstrings
besteht oder wenigsténs einen nichtnumerischen Wert enthält.

=back

=cut

# -----------------------------------------------------------------------------

sub type {
    my $self = shift;
    # @_: $type

    if (@_) {
        $self->[0] = shift;
    }

    return $self->[1] == 0? 's': $self->[0];
}

# -----------------------------------------------------------------------------

=head3 width() - Länge des längsten Werts

=head4 Synopsis

    $width = $prp->width;

=head4 Returns

Integer

=head4 Description

Liefere die Länge des längsten Werts.

=over 2

=item *

Die Breite einer Wertemenge des Typs d oder s ist die Länge des
längsten Werts.

=item *

Die Breite einer Wertemenge des Typs f ist die
Summe aus der maximalen Anzahl an Nachkommastellen plus der
maximalen Anzahl an Zeichen vor und einschließlich des Kommas.

=back

=cut

# -----------------------------------------------------------------------------

sub width {
    my $self = shift;

    if ($self->type eq 'f') {
        return $self->[2]+$self->scale;
    }

    return $self->[1];
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 analyze() - Füge Wert zur Analysemenge hinzu

=head4 Synopsis

    $prp->analyze($value);

=head4 Arguments

=over 4

=item $value

Skalarer Wert (Integer, Float, String)

=back

=head4 Description

Analysiere Wert $value hinsichtlich seiner Eigenschaften und passe
die Eigenschaften der Menge entsprechend an. Ein leerer Wert (undef oder
Leerstring) ändert die Eigenschaften nicht.

=cut

# -----------------------------------------------------------------------------

sub analyze {
    my ($self,$val) = @_;

    if (!defined($val) || $val eq '') {
        # Ein leerer Wert beeinflusst die Eigenschaften nicht
        return;
    }

    # Bisherige Information holen
    my ($type,$width,$floatPrefix,$scale,$align,$opt) = @$self;

    # Typ behandeln

    if ($type ne 's') {
        while (1) {
            if ($type eq 'd' && $val !~ /^[+-]?\d+$/) {
                $type = 'f';
                $floatPrefix = $width+1; # +1 wg. Dezimalpunkt
                redo;
            }
            elsif ($type eq 'f') {
                # MEMO: Die Ziffer vor dem Dezimalpunkt kann fehlen (Oracle)

                if ($val !~ /^[+-]?(\d*\.(\d+)$|\d+)$/) {
                    $type = 's';
                    $align = 'l';
                    $floatPrefix = 0;
                    $scale = 0;
                }
                else {
                    # Maximale Anzahl Nachkommastellen

                    my $n = defined($2)? length $2: 0;
                    if ($n > $scale) {
                        $scale = $n;
                    }

                    # Anzahl Zeichen vor den Nachkommastellen,
                    # einschließlich Punkt und Vorzeichen.
                    # Korrektur für Oracle-Zahlen zw. 1 und -1
                    # und Integer, die zwischen Float auftauchen.
                    # .N oder -.N (Oracle-Fix)
    
                    my $m = length($val)-$n;
                    if ($1 eq '' || $n == 0) {
                        $m++;
                    }
                    if ($m > $floatPrefix) {
                        $floatPrefix = $m;
                    }
                }
            }
            last;
        }
    }

    # Width ermitteln

    my $l = length $val;
    if ($l > $width) {
        $width = $l;
    }

    # Neue Information setzen
    @$self = ($type,$width,$floatPrefix,$scale,$align,$opt);

    return;
}

# -----------------------------------------------------------------------------

=head3 format() - Formatiere Wert

=head4 Synopsis

    $str = $prp->format($format,$val);

=head4 Arguments

=over 4

=item $format

Formatierung, die auf den Wert angewendet wird.
Mögliche Werte: 'text', 'html'.

=item $val

Skalarer Wert (Integer, Float, String) aus der Wertemenge.

=back

=head4 Description

Formatiere Wert $val gemäß Format $format und liefere das Resultat zurück.

=cut

# -----------------------------------------------------------------------------

sub format {
    my ($self,$format,$val) = @_;

    my $type = $self->type;
    my $width = $self->width;

    if ($format eq 'text') {
        if (!defined($val) || $val eq '') {
            return ' ' x abs($width);
        }

        if (($type eq 'd' || $type eq 'f') && $val =~ /[^-+\d.]/) {
            # Einen nicht-numerischen Wert in einer numerischen Kolumne
            # (z.B. Überschrift) formatieren wir als String
            $type = 's';
        }

        if ($type eq 's') {
            $val = sprintf '%*s',$self->[4] eq 'l'? -$width: $width,$val;
        }
        elsif ($type eq 'd') {
            # %d funktioniert bei großen Zahlen mit z.B. 24 Stellen nicht.
            # Es wird dann fälschlicherweise -1 als Wert angezeigt.
            # $val = sprintf '%*d',$width,$val;
            $val = sprintf '%*s',$width,$val;
        }
        elsif ($type eq 'f') {
            $val = sprintf '%*.*f',$width,$self->scale,$val;
            if ($self->[5]) { # noTrailingZeros
                if ($val =~ s/(0+)$/' ' x length($1)/e) {
                    $val =~ s/\.$/ /;
                }
            }
        }
        else {
            $self->throw(
                'PROP-00099: Unknown type',
                Type => $type,
            );
        }
    }
    elsif ($format eq 'html') {
        if (!defined($val) || $val eq '') {
            return '';
        }
        elsif ($type eq 'f') {
            $val = sprintf '%*.*f',$width,$self->scale,$val;
            $val =~ s/^ +//g;
            if ($self->[5]) { # noTrailingZeros
                if ($val =~ s/(0+)$/'&nbsp;' x length($1)/e) {
                    $val =~ s/\.$/&nbsp;/;
                }
            }
        }
        elsif ($type eq 's') {
            $val =~ s/&/&amp;/g;
            $val =~ s/</&lt;/g;
            $val =~ s/>/&gt;/g;
        }
    }
    else {
        $self->throw(
            'PROP-00099: Unknown format',
            Format => $format,
        );
    }

    return $val;
}

# -----------------------------------------------------------------------------

=head3 set() - Setze Eigenschaften explizit

=head4 Synopsis

    $prp->set($type,$align);

=head4 Arguments

=over 4

=item $type

Typ der Wertemenge: s (Text)

=item $align

Ausrichtung der Werte der Wertemenge: l (left), r (right).

=back

=cut

# -----------------------------------------------------------------------------

sub set {
    my ($self,$type,$align) = @_;

    if (defined $type) {
        $self->type($type);
    }
    if (defined $align) {
        $self->align($align);
    }

    return;
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
