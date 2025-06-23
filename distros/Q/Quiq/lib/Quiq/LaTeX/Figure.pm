# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::LaTeX::Figure - Erzeuge LaTeX Figure

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

Der Code

  use Quiq::LaTeX::Figure;
  use Quiq::LaTeX::Code;
  
  my $doc = Quiq::LaTeX::Figure->new(
      FIXME
  );
  
  my $l = Quiq::LaTeX::Code->new;
  my $code = $tab->latex($l);

produziert

  FIXME

=cut

# -----------------------------------------------------------------------------

package Quiq::LaTeX::Figure;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Reference;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere LaTeX Figure-Objekt

=head4 Synopsis

  $doc = $class->new(@keyVal);

=head4 Arguments

=over 4

=item align => 'left' | 'center' (Default: 'center')

Ausrichtung der Abbildung auf der Seite. Nur der erste Buchstabe
des Werts wird interpretiert.

=item border => $bool (Default: 0)

Zeichne einen Rahmen um die Abbildung.

=item padding => $length (Default: '0pt')

Zeichne den Rahmen (Attribut C<border>) mit dem angegebenen
Abstand um die Abbildung.

=item caption => $text

Beschriftung der Abbldung. Diese erscheint unter der Abbildung.

=item file => $path

Pfad der Bilddatei.

=item height => $height

Höhe in Pixel (ohne Angabe einer Einheit), auf die das Bild
skaliert wird. Der Wert wird für LaTeX in pt umgerechnet (1px =
0.75pt).

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

Breite in Pixel (ohne Angabe einer Einheit), auf die das Bild
skaliert wird. Der Wert wird für LaTeX in pt umgerechnet (1px =
0.75pt).

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
        align => undef,
        border => 0,
        caption => undef,
        file => undef,
        height => undef,
        indent => undef,
        inline => 0,
        label => undef,
        link => undef,
        options => undef, # $str | \@opt
        padding => '0pt',
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

    my ($align,$border,$caption,$file,$height,$indent,$inline,$label,$link,
        $options,$padding,$position,$postVSpace,$scale,$width) =
        $self->get(qw/align border caption file height indent inline label
        link options padding position postVSpace scale width/);

    $align //= $inline? '': 'center';

    if (!$file) {
        return '';
    }

    my @opt;
    if ($scale) {
        # $scale hat Priorität gegenüber width und height
        push @opt,"scale=$scale";
    }
    else {
        if ($width) {
            push @opt,"width=$width";
        }
        if ($height) {
            push @opt,"height=$height";
        }
    }
    if (defined $options) {
        if (Quiq::Reference->isArrayRef($options)) {
            @opt = @$options;
        }
        else {
            @opt = split /,/,$options;
        }
    }

    my $code;
    if ($inline) {
        $code .= $l->ci('\protect');
    }
    $code .= $l->macro('\includegraphics',
        -o => \@opt,
        -p => $file,
        -nl => 0,
    );
    if ($border) {
        $code = $l->ci('{\fboxsep%s\fbox{%s}}',$padding,$code);
    }
    if ($link) {
        # $link muss %s enthalten
        $code = sprintf $link,$code;
    }
    if ($indent && $align ne 'center') {
        $code = $l->ci('\hspace*{%s}',$indent).$code;
    }

    # Abbildung inline

    if ($inline) {
        return "{$code}";
    }

    # Alleinstehende Abbildung

    if (!$inline) {
        if ($align eq 'center') {
            $code = $l->c('\centering').$code;
        }
    }

    if ($caption) {
        my @opt;
        if ($align ne 'center') {
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
