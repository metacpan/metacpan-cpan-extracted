package Quiq::ColumnFormat;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.135;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::ColumnFormat - Format einer Text-Kolumne

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Ein Objekt der Klasse ist Träger von Formatinformation über einer
Menge von Werten, die tabellarisch dargestellt werden sollen,
z.B. in einer Text- oder HTML-Tabelle.

Die Methoden der Klasse formatieren die Werte der Wertemenge
entsprechend und liefern Information über die Ausrichtung.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

    $fmt = $class->new($type,$width,$scale,$null,$mask);

=head4 Description

Die übergebenen Parameter enthalten folgende Information:

=over 4

=item $type

Typ ('t', 's', 'd' oder 'f').

=item $width

Länge des längsten Werts.

=item $scale

Maximale Anzahl an Nachkommastellen (im Falle von Werten vom
Typ f).

=item $null

Anzahl der Nullwerte.

=item $mask

Maximale Anzahl der zu maskierenden Zeichen bei einzeiliger
Darstellung. Maskiert werden die Zeichen \n, \r, \t, \0, \\.

=back

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$type,$width,$scale,$null,$mask) = @_;
    #             0     1       2      3     4
    return bless [$type,$width,$scale,$null,$mask],$class;
}

# -----------------------------------------------------------------------------

=head2 Akzessoren

=head3 width() - Breite des längsten Werts

=head4 Synopsis

    $width = $fmt->width;

=cut

# -----------------------------------------------------------------------------

sub width {
    return shift->[1];
}

# -----------------------------------------------------------------------------

=head2 Formatierung

=head3 asFixedWidthString() - Formatiere Wert auf feste Breite

=head4 Synopsis

    $str = $fmt->asFixedWidthString($value);

=cut

# -----------------------------------------------------------------------------

sub asFixedWidthString {
    my ($self,$value) = @_;

    my $type = $self->[0];
    my $width = $self->[1];
    my $scale = $self->[2];

    if (!defined($value) || $value eq '') {
        return ' ' x $width;
    }

    if (($type eq 'd' || $type eq 'f') && $value =~ /[^-\d.]/) {
        # Einen nicht-numerischen Wert in einer numerischen Kolumne
        # (z.B. Überschrift) formatieren wir als String

        $type = 's';
        $width = $width+$scale;
    }

    if ($type eq 's' || $type eq 't') {
        $value = sprintf '%-*s',$width,$value;
    }
    elsif ($type eq 'd') {
        # %d funktioniert bei großen Zahlen mit z.B. 24 Stellen nicht.
        # Es wird dann fälschlicherweise -1 als Wert angezeigt.
        # $value = sprintf '%*d',$width,$value;
        $value = sprintf '%*s',$width,$value;
    }
    elsif ($type eq 'f') {
        $value = sprintf '%*.*f',$width,$scale,$value;
    }
    else {
        $self->throw(
            q~COL-00001: Unbekanntes Kolumnenformat~,
            Type=>$type,
        );
    }

    return $value;
}

# -----------------------------------------------------------------------------

=head3 asTdContent() - Formatiere Wert für eine HTML td-Zelle

=head4 Synopsis

    $html = $fmt->asTdContent($value);

=cut

# -----------------------------------------------------------------------------

sub asTdContent {
    my ($self,$value) = @_;

    if (!defined($value) || $value eq '') {
        return '';
    }
    elsif ($self->[0] eq 'f') {
        $value = sprintf '%*.*f',$self->[1],$self->[2],$value;
        $value =~ s/^ +//g;
    }
    elsif ($self->[0] eq 's' || $self->[0] eq 't') {
        $value =~ s/&/&amp;/g;
        $value =~ s/</&lt;/g;
        $value =~ s/>/&gt;/g;
    }

    return $value;
}

# -----------------------------------------------------------------------------

=head3 htmlAlign() - Horizontale Ausrichtung in HTML

=head4 Synopsis

    $align = $fmt->htmlAlign;

=head4 Description

Für numerische Kolumnen wird der Wert 'right' geliefert,
für Textkolumnen der Wert 'left';

=cut

# -----------------------------------------------------------------------------

sub htmlAlign {
    my $self = shift;

    my $type = $self->[0];
    if ($type eq 'f' || $type eq 'd') {
        return 'right';
    }
    return 'left';
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.135

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
