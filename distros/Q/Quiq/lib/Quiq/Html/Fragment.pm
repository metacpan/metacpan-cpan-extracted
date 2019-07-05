package Quiq::Html::Fragment;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

use Quiq::Css;
use Quiq::JavaScript;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Fragment - Fragment aus HTML-, CSS- und JavaScript-Code

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Die Klasse dient der Erzeugung eines Abschnitts aus HTML-, CSS-
und JavaScript-Code. Anwendungsfall ist z.B. eine Ajax-Antwort,
die in ein bestehendes HTML-Dokument eingebettet wird.

Der generierte Code hat den Aufbau:

    [<DOCTYPE>]
    
    <STYLE CODE>
    <HTML CODE>
    <JAVASCRIPT CODE>

Über dem Code kann eine globale Platzhalter-Ersetzung durchgeführt
werden.

=head1 ATTRIBUTES

=over 4

=item doctype => $bool (Default: 0)

Füge <DOCTYPE> am Anfang des Fragments hinzu. Dies ist nützlich,
wenn das Fragment die Antwort eines Ajax-Requests ist.

=item html => $html (Default: '')

Der HTML-Code der Komponente.

=item javaScript => $js|\@js (Default: undef)

Ein oder mehrere Der JavaScript-Code der Komponente. Siehe Methode
Quiq::JavaScript->code(). Das Attribut kann mehrfach
vorkommen, z.B. für die getrennte Angabe von JavaScript-URLs und
JavaScript-Code.

=item placeholders => \@keyVal (Default: undef)

Ersetze im generierten Code die angegebenen Platzhalter durch ihre
Werte.

=item styleSheet => $css|\@css (Default: undef)

Der CSS-Code der Komponente. Siehe Methode
Quiq::Css->style(). Das Attribut kann mehrfach vorkommen,
z.B. für die getrennte Angabe von CSS-URLs und CSS-Definitionen.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

    $c = $class->new(@keyVal);

=head4 Description

Instantiiere ein Fragment-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        doctype => 0,
        html => '',
        javaScript => [],
        placeholders => undef,
        styleSheet => [],
    );
    while (@_) {
        my $key = shift;
        my $val = shift;

        if ($key eq 'styleSheet' || $key eq 'javaScript') {
            my $arr = $self->get($key);
            push @$arr,ref $val? @$val: $val;
        }
        else {
            $self->set($key=>$val);
        }
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML

=head4 Synopsis

    $html = $obj->html($h);
    $html = $class->html($h,@keyVal);

=head4 Description

Generiere den HTML-Code des Fragment-Objekts und liefere
diesen zurück. Als Klassenmethode gerufen, wird das Objekt intern
erzeugt und mit den Attributen @keyVal instantiiert.

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($doctype,$html,$javaScript,$placeholders,$styleSheet) =
        $self->get(qw/doctype html javaScript placeholders styleSheet/);

    return $h->cat(
        -placeholders => $placeholders,
        '-',
        $doctype? $h->doctype: '',
        Quiq::Css->style($h,$styleSheet),
        $html,
        Quiq::JavaScript->script($h,$javaScript),
    );
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
