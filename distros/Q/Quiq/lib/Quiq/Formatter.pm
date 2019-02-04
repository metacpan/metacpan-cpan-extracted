package Quiq::Formatter;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.132;

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

=head1 VERSION

1.132

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
