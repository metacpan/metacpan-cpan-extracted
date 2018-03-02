package Prty::LaTeX::Figure;
use base qw/Prty::Hash/;

use strict;
use warnings;

our $VERSION = 1.124;

use Prty::Reference;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::LaTeX::Figure - Erzeuge LaTeX Figure

=head1 BASE CLASS

L<Prty::Hash>

=head1 SYNOPSIS

Der Code

    use Prty::LaTeX::Figure;
    use Prty::LaTeX::Code;
    
    my $doc = Prty::LaTeX::Figure->new(
        FIXME
    );
    
    my $l = Prty::LaTeX::Code->new;
    my $code = $tab->latex($l);

produziert

    FIXME

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere LaTeX Figure-Objekt

=head4 Synopsis

    $doc = $class->new(@keyVal);

=head4 Arguments

=over 4

=item align => 'l' | 'c' (Default: 'c')

Ausrichtung der Abbildung auf der Seite: l=links, c=zentriert.

=item border => $bool (Default: 0)

Zeichne einen Rahmen um die Abbildung.

=item borderMargin => $length (Default: '0mm')

Zeichne den Rahmen (Attribut C<border>) mit dem angegebenen
Abstand um die Abbildung.

=item caption => $text

Beschriftung der Abbldung. Diese erscheint unter der Abbildung.

=item file => $path

Pfad der Bilddatei.

=item height => $height

Höhe (ohne Angabe einer Einheit), auf die das Bild skaliert wird.

=item indent => $length

Länge, mit der die Abbildung vom linken Rand eingerückt wird,
wenn sie links (Attribut C<align>) gesetzt wird.

=item inline => $bool (Default: 0)

Anstelle von Code für eine alleinstehende Abbildung wird Code
für eine Inline-Grafik erzeugt.

=item label => $str

Anker der Abbildung.

=item options => $str | \@arr

Optionen, die an das Makro C<\includegraphics> übergeben werden.

=item position => 'H','h','t','b','p' (Default: 'H')

Positioniergspräferenz für das Gleitobjekt. Details siehe
LaTeX-Package C<float>, das geladen werden muss.

=item postVSpace => $length

Vertikaler Leerraum, der nach der Abbildung hinzugefügt (positiver
Wert) oder abgezogen (negativer Wert) wird.

=item link => $latex,

Versieh das Bild mit einem Verweis. Übergeben wird der fertige
LaTeX-Code für den Verweis auf das interne bzw. externe Ziel.  Der
Code muss %s an der Stelle enthalten, wo die Methode den Code für
das Bild eingesetzen soll.

=item scale => $factor

Skalierungsfaktor. Der Skalierungsfaktor hat Priorität gegenüber
der Angabe von C<width> und C<height>.

=item url => $url

Versieh das Bild mit einem Verweis auf eine externe Ressource.
Ist auch Attribut C<ref> gesetzt, hat dieses Priorität.

=item width => $width

Breite (ohne Angabe einer Einheit), auf die das Bild skaliert
wird.

=back

=head4 Returns

Figure-Objekt

=head4 Description

Instantiiere ein LaTeX Figure-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyval

    my $self = $class->SUPER::new(
        align => 'c',
        border => 0,
        borderMargin => '0mm',
        caption => undef,
        file => undef,
        height => undef,
        indent => undef,
        inline => 0,
        label => undef,
        link => undef,
        options => undef, # $str | \@opt
        position => 'H',
        postVSpace => undef,
        scale => undef,
        width => undef,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $fig->latex($l);
    $code = $class->latex($l,@keyVal);

=head4 Description

Generiere den LaTeX-Code des Objekts und liefere diesen
zurück. Als Klassenmethode gerufen, wird das Objekt intern erzeugt
und mit den Attributen @keyVal instantiiert.

=cut

# -----------------------------------------------------------------------------

sub latex {
    my $this = shift;
    my $l = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($align,$border,$borderMargin,$caption,$file,$height,$indent,$inline,
        $label,$link,$options,$position,$postVSpace,$scale,$width) =
        $self->get(qw/align border borderMargin caption file height indent
        inline label link options position postVSpace scale width/);

    if (!$file) {
        return '';
    }

    my @opt;
    if ($scale) {
        # $scale hat Priorität gegenüber width und height
        push @opt,"scale=$scale";
    }
    elsif ($width && $height) {
        # Fallback, wenn scale nicht angegeben ist
        push @opt,"width=${width}px";
        push @opt,"height=${height}px";
    }
    if (defined $options) {
        if (Prty::Reference->isArrayRef($options)) {
            @opt = @$options;
        }
        else {
            @opt = split /,/,$options;
        }
    }

    my $code = $l->macro('\includegraphics',
        -o => \@opt,
        -p => $file,
        -nl => 0,
    );
    if ($border) {
        $code = $l->ci('{\fboxsep%s\fbox{%s}}',$borderMargin,$code);
    }
    if ($link) {
        # $link muss %s enthalten
        $code = sprintf $link,$code;
    }
    if ($indent && $align ne 'c') {
        $code = $l->ci('\hspace*{%s}',$indent).$code;
    }

    # Inline Abbildung

    if ($inline) {
        return $code;
    }

    # Alleinstehende Abbildung

    if (!$inline) {
        if ($align eq 'c') {
            $code = $l->c('\centering').$code;
        }
    }

    if ($caption) {
        my @opt;
        if ($align ne 'c') {
            push @opt,'singlelinecheck=off';
            if ($indent) {
                push @opt,"margin=$indent";
            }
        }
        if (@opt) {
            $code .= $l->c('\captionsetup{%s}',\@opt);
        }
        $code .= $l->c('\caption{%s}',$caption);
    }
    if ($label) {
        $code .= $l->c('\label{%s}',$label);
    }

    $code = $l->env('figure',$code,
        -o => $position,
    );

    if (my $postVSpace = $self->postVSpace) {
        $code .= $l->c('\vspace{%s}','--',$postVSpace);
    }
    
    return $code;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.124

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2018 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
