package Quiq::Html::Table::Simple;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Table::Simple - HTML-Tabelle

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Die Klasse dient der Generierung von HTML-Tabellen mit einer
freien Struktur, wie Formulartabellen. Die Definition erfolgt
zeilenweise wie in HTML, wobei die C<tr>- und C<td>-Information
durch Listen angegeben werden.

Der Wert des Objekt-Attributs C<rows>, das den Inhalt der Tabelle
definiert, hat den Aufbau:

    [[@keyValTr,[@keyValTd,$content],...],...]
    ^^          ^                   ^    ^
    ||          |                   |    weitere Zeilen
    ||          |                   weitere Kolumnen
    ||          erste Kolumne
    |erste Zeile mit Attributen @keyValTr
    Array der Zeilen

Die Listen C<@keyValTr> und C<@KeyValTd> definieren die Attribute
der C<tr>- bzw. C<td>-Tags. Besteht C<@keyValTr> aus einer
ungeraden Anzahl an Elementen, wird das erste Element C<$val> als
Klassenname interpretiert und zu C<< class=>$val >> expandiert.

=head1 ATTRIBUTES

=over 4

=item border => $n (Default: undef)

C<border>-Attribut der Tabelle.

=item cellpadding => $n (Default: undef)

C<cellpadding>-Attribut der Tabelle.

=item cellspacing => $n (Default: 0)

C<cellspacing>-Attribut der Tabelle.

=item class => $class (Default: undef)

C<class>-Attribut der Tabelle.

=item data => \@keyVal (Default: [])

C<data-*> Attribute der Tabelle.

=item id => $id (Default: undef)

DOM-Id der Tabelle.

=item rows => \@rows (Default: [])

Liste der Zeilen (und Kolumnen).

=item style => $cssCode (Default: undef)

C<style>-Attribut der Tabelle.

=item width => $width (Default: undef)

C<width>-Attribut der Tabelle.

=back

=head1 EXAMPLE

Klasse:

    $html = Quiq::Html::Table::Simple->html($h,
        class => 'my-table',
        border => 1,
        rows => [
            ['my-title',['A'],[colspan=>2,'B']],
            [[rowspan=>2,'a1'],['de'],['Text1_de']],
            [['en'],['Text1_en']],
            [[rowspan=>2,'a2'],['de'],['Text2_de']],
            [['en'],['Text2_en']],
        ],
    );

=over 2

=item *

tr-Angabe C<'my-title'> ist äquivalent zu C<< class=>'my-title' >>

=item *

mit -tag=>'th' wird aus einer beliebigen Zelle eine Head-Zelle
gemacht.

=back

Aussehen:

    +--+-----------+
    |A |B          |
    +--+--+--------+
    |  |de|Text1_de|
    |a1+--+--------+
    |  |en|Text1_en|
    +--+--+--------+
    |  |de|Text2_de|
    |a2+--+--------+
    |  |en|Text2_wn|
    +--+--+--------+

HTML:

    <table class="my-table" border="1" cellspacing="0">
    <tr class="my-title">
      <td>A</td>
      <td colspan="2">B</td>
    </tr>
    <tr>
      <td rowspan="2">a1</td>
      <td>de</td>
      <td>Text1_de</td>
    </tr>
    <tr>
      <td>en</td>
      <td>Text1_en</td>
    </tr>
    <tr>
      <td rowspan="2">a2</td>
      <td>de</td>
      <td>Text2_de</td>
    </tr>
    <tr>
      <td>en</td>
      <td>Text2_en</td>
    </tr>
    </table>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

    $e = $class->new(@keyVal);

=head4 Description

Instantiiere ein Tabellen-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        border => undef,
        cellpadding => undef,
        cellspacing => 0,
        class => undef,
        data => [],
        id => undef,
        rows => [],
        style => undef,
        width => undef,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML

=head4 Synopsis

    $html = $e->html($h);
    $html = $class->html($h,@keyVal);

=head4 Description

Generiere den HTML-Code des Tabellen-Objekts und liefere diesen
zurück. Als Klassenmethode gerufen, wird das Objekt intern erzeugt
und mit den Attributen @keyVal instantiiert.

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($border,$cellpadding,$cellspacing,$class,$dataA,$id,$rowA,$style,
        $width) = $self->get(qw/border cellpadding cellspacing class data
        id rows style width/);

    return $h->tag('table',
        class => $class,
        id => $id,
        style => $style,
        data => $dataA,
        border => $border,
        width => $width,
        cellpadding => $cellpadding,
        cellspacing => $cellspacing,
        $h->tag('tbody',
            -ignoreTagIf => 1, # kein tbody per Default
            do {
                my $tbody;
                for my $trA (@$rowA) {
                    # Elemente des Zeilen-Array auswerten

                    my (@keyVal,@td);
                    for (my $i = 0; $i < @$trA; $i++) {
                        my $e = $trA->[$i];
                        if (ref $e) {
                            push @td,$e;
                        }
                        else {
                            push @keyVal,$e;
                        }
                    }
                    if (@keyVal == 1) {
                        unshift @keyVal,'class';
                    }

                    # HTML-Code der Zeile generieren und
                    # zum tbody hinzufügen

                    $tbody .= $h->tag('tr',
                        @keyVal,
                        do {
                            my $tr;
                            for my $tdA (@td) {
                                $tr .= $h->tag('td',
                                    @$tdA
                                );
                            }
                            $tr;
                        },
                    );
                }
                $tbody;
            },
        )
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
