package Quiq::Color;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

use Quiq::Reference;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Color - Eine Farbe des RGB-Farbraums

=head1 BASE CLASS

L<Quiq::Object>

=head1 SYNOPSIS

    use Quiq::Color;
    
    # Instantiierung
    
    $col = Quiq::Color->new(255,0,0); # aus dez. RGB-Tripel
    $col = Quiq::Color->new('ff0000'); # aus hex. RGB-String
    
    # Helligkeit
    
    $brightness = $col->brightness; # 0 .. 255
    
    # Farbname
    
    $col->name('red'); # setzen
    $name = $col->name; # abfragen
    
    # Externe Repräsentation
    
    $hex = $col->hexString; # 'ff0000' - hex. RGB-String
    @rgb = $col->rgb; # (255,0,0) - dez. RGB-Tripel

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Farbe des RGB-Farbraums,
also ein Tripel (R, G, B). Das Objekt kann aus verschiedenen
externen Repräsentationen instantiiert werden und seinerseits
verschiedene externe Repräsentationen liefern. Ferner kann die
Helligkeit der Farbe ermittelt werden, was für eine Fontauswahl
nützlich sein kann. Außerdem kann der Farbe ein Name zugewiesen
werden.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $col = $class->new($r,$g,$b);
    $col = $class->new(\@rgb);
    $col = $class->new('rrggbb');
    $col = $class->new('#rrggbb');

=head4 Description

Instantiiere eine RGB-Farbe und liefere eine Referenz
auf das Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: Farbspezifikation

    my (@rgb,$error);
    if (@_ == 3) {
        @rgb = @_;
    }
    elsif (@_ == 1) {
        if (Quiq::Reference->isArrayRef($_[0])) {
            @rgb = @{$_[0]};
        }
        elsif ($_[0] =~ /^#?(\w\w)(\w\w)(\w\w)$/) {
            @rgb = (hex($1),hex($2),hex($3));
        }
        else {
            $error = 1;
        }
    }
    else {
         $error = 1;
    }

    if ($error) {
        $class->throw(
           'COLOR-00001: Unknown color representation',
           Arguments => join(',',@_),
        );
    }

    # [$r,$g,$b],$name
    return bless [\@rgb,undef],$class;
}

# -----------------------------------------------------------------------------

=head2 Farbeigenschaften

=head3 brightness() - Helligkeit der Farbe

=head4 Synopsis

    $brightness = $col->brightness;

=head4 Description

Liefere die Helligkeit der Farbe im Wertebereich 0 (schwarz) bis
255 (weiß). Bei einem Wert < 128 ist die Farbe dunkel, andernfalls hell.

Die Methode kann genutzt werden um zu entscheiden, welche Textfarbe
auf einem Hintergrund mit der Farbe genutzt werden sollte.

Die Helligkeitsberechnung erfolgt auf Grundlage der Heuristik:

    $brightness = sqrt 0.299*$r**2 + 0.587*$g**2 + 0.114*$b**2;

=head4 See Also

=over 2

=item *

L<http://fseitz.de/blog/index.php?/archives/112-Helligkeit-von-Farben-des-RGB-Farbraums-berechnen.html>

=back

=head4 Example

    $col = Quiq::Color->new('ff0000');
    $brightness = $col->brightness;
    -> 139.44

=cut

# -----------------------------------------------------------------------------

sub brightness {
    my $self = shift;

    my ($r,$g,$b) = $self->rgb;
    return sqrt 0.299*$r**2 + 0.587*$g**2 + 0.114*$b**2;
}

# -----------------------------------------------------------------------------

=head3 name() - Setze/Liefere Farbname

=head4 Synopsis

    $name = $col->name($name);
    $name = $col->name;

=head4 Description

Das Farbobjekt besitzt zunächst keinen Namen. Mit dieser Methode
kann der Farbe jedoch ein Name zugewiesen und abgefragt werden.

Wurde dem Farbobjekt kein Name zugewiesen, liefert die Methode
einen Leerstring.

=head4 Example

    my $col = Quiq::Color->new(255,0,0);
    $col->name('red');
    $name = $col->name;
    -> 'red'

=cut

# -----------------------------------------------------------------------------

sub name {
    my $self = shift;
    # @_: $name

    if (@_) {
        $self->[1] = shift;
    }

    return $self->[1] || '';
}

# -----------------------------------------------------------------------------

=head2 Externe Repräsentationen

=head3 hexString() - Farbwert als Hex-String

=head4 Synopsis

    $hexStr = $col->hexString;

=head4 Description

Liefere den Farbwert der Farbe als Hex-String

=head4 Example

    $col = Quiq::Color->new(255,255,255);
    $hexStr = Quiq::Color->hexString;
    -> 'ffffff'

=cut

# -----------------------------------------------------------------------------

sub hexString {
    my $self = shift;
    return sprintf '%02x%02x%02x',$self->rgb;
}

# -----------------------------------------------------------------------------

=head3 rgb() - Farbwert als Liste von dezimalen Werten

=head4 Synopsis

    @rgb | $rgbA = $col->rgb;

=head4 Description

Liefere den Farbwert als Liste von dezimalen Werten mit den Komponenten
R, G, B. Im Skalarkontext liefere eine Referenz auf die Liste.

=head4 Example

    $col = Quiq::Color->new('ffffff');
    @rgb = Quiq::Color->rgb;
    -> (255,255,255)

=cut

# -----------------------------------------------------------------------------

sub rgb {
    my $self = shift;
    return wantarray? @{$self->[0]}: $self->[0];
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.149

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
