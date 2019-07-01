package Quiq::Html::Widget::SelectMenuColor;
use base qw/Quiq::Html::Widget::SelectMenu/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

use Quiq::Color;
use Quiq::String;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Widget::SelectMenuColor - Selectmenü mit farbigen Einträgen

=head1 BASE CLASS

L<Quiq::Html::Widget::SelectMenu>

=head1 ATTRIBUTES

Siehe Basisklasse. Zusätzlich:

=over 4

=item applyColorsTo => 'fg' | 'bg' (Default: 'fg')

Wende die Farben (siehe Attribut C<colors>) auf den Vordergrund oder
auf den Hintergrund an.

=item colors=> \@colors (Default: [])

Liste der Farbwerte für die Elemente der Auswahlliste. Es sind
alle Farbwerte (außer ($r,$g,$b)) möglich, die der Konstruktor
der Klasse Quiq::Color akzeptiert.

=back

=head1 EXAMPLES

Erzeuge Auswahlmenü mit farbigen Texten:

    $w = Quiq::Html::Widget::SelectMenuColor->new(
        id => 'smc1',
        name => 'smc1',
        applyColorsTo => 'fg',
        options => [qw/Apfel Birne Orange/],
        colors => [qw/ff0000 006400 ff8c00/],
        value => 'Birne',
    );
    print $w->html($h);

Erzeuge Auswahlmenü mit farbigen Hintergründen:

    $w = Quiq::Html::Widget::SelectMenuColor->new(
        id => 'smc1',
        name => 'smc1',
        applyColorsTo => 'bg',
        options => [qw/Apfel Birne Orange/],
        colors => [qw/ff0000 006400 ff8c00/],
        value => 'Birne',
    );
    print $w->html($h);

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $e = $class->new(@keyVal);

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    # Defaultwerte

    my $self = $class->SUPER::new;
    $self->add(
        applyColorsTo => 'fg', # 'bg' -or- 'fg'
        colors => [],
    );

    # Werte Konstruktoraufruf
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML-Code

=head4 Synopsis

    $html = $e->html($h);
    $html = $class->html($h,@keyVal);

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;
    # @_: @keyVal

    my $self = ref $this? $this: $this->new(@_);

    # Attribute

    my ($applyColorsTo,$colors,$id,$javaScript,$onChange,$styles) =
       $self->get(qw/applyColorsTo colors id javaScript onChange styles/);

    for (my $i = 0; $i < @$colors; $i++) {
        my $color = $colors->[$i] || next;
        my $col = Quiq::Color->new($color);
        my $rgb = $col->hexString;

        if ($styles->[$i]) {
            $styles->[$i] .= ';';
        }
        if ($applyColorsTo eq 'fg') {
            $styles->[$i] .= "color: #$rgb";
        }
        elsif ($applyColorsTo eq 'bg') {
            my $fgColor = $col->brightness < 128? 'white': 'black';
            $styles->[$i] .= "background: #$rgb; color: $fgColor";
        }
        else {
            $self->throw;
        }
    }

    if (!$id) {
        $self->throw;
    }
    if ($javaScript) {
        $javaScript .= ";\n\n";
    }
    $javaScript .= Quiq::String->removeIndentation(<<"    __JS__");
        var e = document.getElementById('$id');
        e.setColors = function () {
            var i = this.selectedIndex;
            this.style.background = this.options[i].style.background;
            this.style.color = this.options[i].style.color;
        }
        e.setColors();
    __JS__
    $self->set(javaScript=>$javaScript);

    if ($onChange) {
        $onChange .= '; ';
    }
    $onChange .= 'this.setColors()';
    $self->set(onChange=>$onChange);

    return $self->SUPER::html($h);
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
