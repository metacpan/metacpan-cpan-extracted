package Quiq::Html::Image;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Image - Image-Block in HTML

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Image-Block. Ein
Image-Block stellt ein Bild alleinstehend dar, optional mit
Link und Bildunterschrift.

Aufbau eines Image-Blocks:

    [<div [class="CLASS"] [id="ID"] [style="STYLE"]>]
      [<a href="URL">]
      <img src="URL" width="WIDTH" height="HEIGHT" alt="ALT" />
      [<p>
        <span class="prefix">PREFIX:</span> <span class="caption">CAPTION</span>
      </p>]
      [</a>]
    [</div>]

Die in eckige Klammern eingefassten Bestandteile ([...]) sind
optional.

Das Aussehen des Image-Block kann via CSS gestaltet werden. Hier
einige Selektoren, mit denen Bestandteile des Konstrukts in CSS
angesprochen werden können:

=over 4

=item .CLASS

Der gesamte Block.

=item .CLASS .prefix

Der Präfix-Text der Bildunterschrift ("Abbildung N:").

=item .CLASS .caption

Der Text der Bildunterschrift.

=back

Hierbei ist CLASS der über das Attribut C<class> setzbare
CSS-Klassenname.

=head1 ATTRIBUTES

=over 4

=item alt => $text

Alternativ-Text, wenn Bild nicht angezeigt wird.

=item caption => $text

Text der Bildunterschrift.

=item captionPrefix => $text

Präfix-Text der Bildunterschrift, z.B. "Abbildung 1:".

=item class => $name

CSS-Klasse des Image-Blocks.

=item height => $n

Höhe des Bildes in Pixeln.

=item href => $url

Hinterlege Bild mit einem Link auf URL $url.

=item id => $id

Die CSS-Id des Image-Blocks.

=item src => $url

Der URL des Bildes. Ist kein URL angegeben oder der Wert leer
(undef oder Leerstring), wird von der Methode html() kein
Image-Block erzeugt, sondern ein Leerstring geliefert.

=item style => $style

CSS-Properties des Image-Blocks (d.h. des <div>).

=item width => $n

Die Breite des Bildes.

=back

=head1 EXAMPLES

B<Leerer Block, wenn kein Bild-URL>

    $class->html($h,
        src => '', # oder undef
    );

produziert:

    ''

B<Block nur mit Bild>

    $class->html($h,
        src => 'illusion.png',
        width => 100,
        height => 100,
    );

produziert:

    <div>
      <img src="img/illusion.png" width="100" height="100" alt="">
    </div>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Verbatim-Block-Objekt

=head4 Synopsis

    $e = $class->new(@keyVal);

=head4 Arguments

=over 4

=item @keyVal

Liste von Attribut/Wert-Paaren. Die Werte werden auf dem Objekt
gesetzt. Siehe Abschnitt ATTRIBUTES.

=back

=head4 Returns

=over 4

=item $e

Image-Block-Objekt (Referenz)

=back

=head4 Description

Instantiiere ein Image-Block-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        alt => undef,
        caption => undef,
        captionPrefix => undef,
        class => undef,
        height => undef,
        href => undef,
        id => undef,
        src => undef,
        style => undef,
        width => undef,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML-Code

=head4 Synopsis

    $html = $e->html($h);
    $html = $class->html($h,@keyVal);

=head4 Arguments

=over 4

=item $h

Objekt für die HTML-Generierung, d.h. eine Instanz der Klasse
Quiq::Html::Tag.

=item @keyVal

Siehe Konstruktor.

=back

=head4 Returns

HTML-Code (String)

=head4 Description

Generiere den HTML-Code des Image-Blocks und liefere diesen
zurück. Als Klassenmethode gerufen, wird das Objekt intern
mit den Attributen @keyVal instantiiert.

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;
    # @_: @keyVal

    my $self = ref $this? $this: $this->new(@_);

    my ($alt,$caption,$captionPrefix,$class,$height,$href,$id,$src,$style,
        $width) = $self->get(qw/alt caption captionPrefix class height href
        id src style width/);

    if (!defined($src) || $src eq '') {
        # Wenn kein Bild-URL gegeben ist, wird kein Code generiert
        return '';
    }

    return $h->tag('div',
        class => $class,
        id => $id,
        style => $style,
        '-',
        $h->tag('a',
            -fmt => 'v',
            -ignoreTagIf => !$href,
            href => $href,
            '-',
            $h->tag('img',
                -fmt => 'e',
                src => $src,
                alt => $alt,
                width => $width,
                height => $height,
            ),
        ),
        $h->tag('p',
            '-',
            $h->tag('span',
                class => 'prefix',
                $captionPrefix
            ),
            $h->tag('span',
                class => 'caption',
                $caption
            ),
        ),
    );
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
