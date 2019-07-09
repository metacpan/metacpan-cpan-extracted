package Quiq::Html::Table::Base;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.151';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Table::Base - Basisklasse für tabellengenerierende Klassen

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Diese Klasse dient als Basisklasse für speziellere tabellengenerierende
Klassen. Sie organisiert "des Drumherum" einer HTML-Tabelle.
Insbesondere besitzt sie die Attribute des table-Tag und rendert diesen.
Die Zeilen werden von der Klasse nicht behandelt, dies ist Aufgabe
der speziellen, abgeleiteten Klasse.

Abgeleitete Klassen rufen für die Basisfunktionalität den Konstruktor
und die html-Methode dieser Klasse auf.

=head1 ATTRIBUTES

=over 4

=item border => $n (Default: 1)

Wert des border-Attriuts der Tabelle.

=item cellpadding => $n (Default: undef)

Wert des cellpadding-Attriuts der Tabelle.

=item cellspacing => $n (Default: 0)

Wert des cellspacing-Attriuts der Tabelle.

=item class => $class (Default: undef)

CSS Klasse der Tabelle.

=item flat => $bool (Default: 0)

Wenn wahr, wird der HTML-Code der Tabelle einzeilig generiert.

=item id => $id (Default: undef)

CSS-Id der Tabelle.

=item indentPos => $n (Default: 0)

Rücke den HTML-Code bis auf die erste Zeile um $n Leerzeichen ein.
Diese Option ist nützlich, wenn die Tabelle für einen Platzhalter mit
der Einrücktiefe $n in den HTML-Code eingesetzt werden soll.

=item style => $cssCode (Default: undef)

Wert des style-Attributs der Tabelle.

=item width => $width (Default: undef)

Wert des width-Attributs der Tabelle.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $e = $class->new(@keyVal);

=head4 Description

Instantiiere ein Tabellenobjekt mit den Eingenschaften @keyVal und
liefere eine Referenz auf dieses Objekt zurück.

Da der Konstruktor von einer Subklasse gerufen wird, kann die Subklasse
den Umfang der Attribute erweitern.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    # Defaultwerte

    my $self = $class->SUPER::new(
        border => 1,
        cellpadding => undef,
        cellspacing => 0,
        class => undef,
        flat => 0,
        id => undef,
        indentPos => 0,
        style => undef,
        width => undef,
        @_, # Umfang der Attribute kann von Subklasse erweitert werden
    );

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML-Code

=head4 Synopsis

    $html = $e->html($h,$body);
    $html = $class->html($h,$body,@keyVal);

=head4 Arguments

=over 4

=item $h

HTML Tag-Objekt.

=item $body

HTML-Code mit den Zeilen (Kopf und Rumpf) der Tabelle.

=item @keyVal

Attribut-Wert-Paare des Konstruktoraufrufs, wenn die
Methode das Objekt instantiieren soll.

=back

=head4 Description

Generiere den HTML-Code der Tablle und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;
    my $body = shift;
    # @_: @keyVal

    my $self = ref $this? $this: $this->new(@_);

    # Attribute

    my ($border,$cellpadding,$cellspacing,$class,$flat,$id,$indentPos,
        $style,$width) =
        $self->get(qw/border cellpadding cellspacing class flat id indentPos
        style width/);

    # Generierung

    return '' if !defined $body;

    # Nicht-leer

    my $html = $h->tag('table',
        -indPos => $indentPos,
        $flat? (-fmt=>'p',-nl=>0): (-fmt=>'v',-nl=>1),
        class => $class,
        id => $id,
        style => $style,
        border => $border? $border: undef,
        cellpadding => $cellpadding,
        cellspacing => $cellspacing,
        width => $width,
        $body,
    );

    return $html;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.151

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
