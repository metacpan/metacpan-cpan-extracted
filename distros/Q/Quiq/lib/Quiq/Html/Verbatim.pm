package Quiq::Html::Verbatim;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

use Quiq::Html::Table::Simple;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Verbatim - Verbatim-Block in HTML

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Verbatim-Block in
HTML. Ein Verbatim-Block gibt einen Text TEXT in
Festbreitenschrift mit allen Leerzeichen und Zeilenumbrüchen
identisch wieder. Innerhalb von TEXT ist HTML erlaubt. Der
Verbatim-Block kann mit Zeilennummern ausgestattet werden.
In dem Fall wird das HTML-Konstrukt um eine <table> ergänzt
und dadurch komplexer.

Aufbau eines Verbatim-Blocks I<ohne> Zeilennummern:

    <div class="CLASS" [id="ID"] [style="STYLE"]>
      <pre>TEXT</pre>
    </div>

Aufbau eines Verbatim-Blocks I<mit> Zeilennummern:

    <div class="CLASS" [id="ID"] [style="STYLE"]>
      <table>
      <tr>
        <td class="ln">
          <pre>ZEILENNUMMERN</pre>
        </td>
        <td class="margin"></td>
        <td class="text">
          <pre>TEXT</pre>
        </td>
      </tr>
      </table>
    </div>

Die in eckige Klammern eingefassten Bestandteile ([...]) sind
optional.

Das umgebende C<div> klammert das gesamte Konstrukt und ermöglicht
auch im Falle von Zeilennummer, dass der Hintergrund des Blocks
über die gesamte Breite der Seite farbig hinterlegt werden kann.

Das Aussehen des Verbatim-Block kann via CSS gestaltet werden.
Hier die Selektoren, mit denen einzelne Bestandteile des
Konstrukts in CSS angesprochen werden können:

=over 4

=item .CLASS

Der gesamte Block.

=item .CLASS > pre

Der Verbatim-Text im Falle einer Darstellung ohne Zeilennummern.

=item .CLASS table

Die Tabelle im Falle von Zeilennummern.

=item .CLASS .ln

Die Zeilennummern-Spalte.

=item .CLASS .margin

Die Trenn-Spalte zwischen Zeilennummer- und Text-Spalte.

=item .CLASS .text

Die Text-Spalte.

=back

Hierbei ist CLASS der über das Attribut C<class> änderbare
CSS-Klassenname. Default-Klassenname ist 'verbatim'.

=head1 ATTRIBUTES

=over 4

=item class => $name (Default: 'verbatim')

CSS-Klasse des Verbatim-Blocks.

=item id => $id

Die CSS-Id des Verbatim-Blocks.

=item ln => $n (Default: 0)

Wenn ungleich 0, wird jeder Zeile eine Zeilennummer vorangestellt,
beginnend Zeilennummer $n.

=item style => $style

CSS-Properties des Verbatim-Blocks (<div>).

=item text => $text

Der dargestellte Text. Ist $text leer (C<undef> oder Leerstring),
wird kein Verbatim-Block erzeugt, d.h. die Methode $obj->html()
liefert einen Leerstring.

=back

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

Verbatim-Abschnitts-Objekt (Referenz)

=back

=head4 Description

Instantiiere ein Verbatim-Block-Objekt und liefere eine
Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        class => 'verbatim',
        id => undef,
        ln => 0,
        style => undef,
        text => undef,
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

Generiere den HTML-Code des Verbatim-Blocks und liefere diesen
zurück. Als Klassenmethode gerufen, wird das Objekt intern
mit den Attributen @keyVal instantiiert.

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($class,$id,$ln,$style,$text) = $self->get(qw/class id ln style text/);

    if (!defined($text) || $text eq '') {
        # Wenn kein Text gegeben ist, wird kein Code generiert
        return '';
    }

    my $html;
    if ($ln) {
        # Zeilennummern-, Margin, Code-Kolumne

        my $lnCount = $text =~ tr/\n//;
        if (substr($text,-1,1) ne "\n") {
            # Wenn die letzte Zeile nicht mit einem Newline endet,
            # haben wir eine Zeilennummer mehr
            $lnCount++;
        }
        my $lnLast = $ln + $lnCount - 1;

        my $tmp;
        my $lnMaxWidth = length $lnLast;
        for (my $i = $ln; $i <= $lnLast; $i++) {
            if ($tmp) {
                $tmp .= "\n";
            }
            $tmp .= sprintf '%*d',$lnMaxWidth,$i;
        }
        push my @cols,
            [class=>"ln",$h->tag('pre',$tmp)],
            [class=>"margin",''],
        ;

        # Text-Kolumne
        push @cols,[class=>"text",$h->tag('pre',$text)];

        # Erzeuge Tabelle

        $html = Quiq::Html::Table::Simple->html($h,
            border => undef,
            cellpadding => undef,
            cellspacing => undef,
            rows => [
                [@cols],
            ],
        );
    }
    else {
        $html = $h->tag('pre',
            $text
        );
    }

    return $h->tag('div',
        class => $class,
        id => $id,
        style => $style,
        '-',
        $html
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
