# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::PlotlyJs::XY::Diagram - Metadaten eines XY-Diagramms

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse speichert Metadaten zu einem XY-Diagramm,
das von der Klasse B<< Quiq::PlotlyJs::XY::DiagramGroup >>
geplottet wird.

Die zu plottenden Daten können entweder mittels der Komponenten B<x>,
B<y> (und ggf. B<z>) übergeben werden oder sie werden per
Ajax-Aufruf geholt, wenn das Attribut B<url> gesetzt ist.

Es ist sinnvoll, die Wertebereiche B<xMin>, B<xMax>, B<yMin>, B<yMax>
explizit vorzugeben. Dies ist nicht zwingend erforderlich, da
Plotly.js die Wertebereiche auch selbständig setzt, dann aber nach
eigenen Kriterien. Ist kein Y-Wertebereich vorgegeben, wird z.B. bei
B<fill: 'tozeroy'> die Y-Achse bis 0 ausgedeht, auch wenn alle
Y-Werte > 0 sind.

=cut

# -----------------------------------------------------------------------------

package Quiq::PlotlyJs::XY::Diagram;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $par = $class->new(@attVal);

=head4 Attributes

Pflichtangaben sind B<fett> wiedergegeben. Die zu plottenden Daten
werden entweder per B<x>, B<y> (und ggf. B<z>) übergeben oder via
B<url> besorgt.

=over 4

=item color => $color (Default: '#ff0000')

Farbe, in der die Kurve und Titel dargestellt werden. Alle Schreibweisen,
die in CSS erlaubt sind, sind zulässig, also NAME, #XXXXXX
oder rgb(NNN,NNN,NNN,NNN).

=item html => $html

HTML-Code der zum Div-Container des Diagramms hinzugefügt wird,
z.B. um absolut postionierte Divs über den Diagramm-Bereich zu legen.

=item B<< title => $title >>

Diagramm-Titel.

=item x => \@x

Referenz auf Array der X-Werte. Im Falle einer Zeitreihe sollten die
Zeiten als Strings angegeben werden, da Plotly.js Epoch- und
JavaScript Date-Objekte (auch mit Zeitzone) als UTC-Zeiten ansieht
und diese in die Zeitzone des Browsers umgerechnet werden.

=item xMin => $val

Kleinster Wert der X-Achse.

=item xMax => $val

Größter Wert der X-Achse.

=item y => \@y

Referenz auf Array der Y-Werte (Weltkoordinaten).

=item yMin => $val

Kleinster Wert der Y-Achse.

=item yMax => $val

Größter Wert der Y-Achse.

=item B<< yTitle => $str >>

Titel der Y-Achse, typischerweise die Einheit des Parameters.

=item yTitleColor => $color (Default: undef)

Farbe des Titels der Y-Achse. Wenn C<undef>, Default-Farbe von Plotly.

=item url => $url

URL des Ajax-Requests, mit welchem die zu plottenden Daten
(B<x>, B<y>, ggf. B<z>) abgerufen werden.

=item z => \@z

Referenz auf Array von Z-Werten. Dies ist eine Liste von Markerfarben.

=item zName => $name

Name für die Liste der Markerfarben. Wird der Liste der
Markerfarben ein Name gegeben, erscheint eine zusätzliche Option
in der Shape-Auswahlliste.

=back

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @attVal

    my $self = $class->SUPER::new(
        color => '#ff0000',
        html => undef,
        title => undef,
        x => [],
        xMin => undef,
        xMax => undef,
        y => [],
        yMin => undef,
        yMax => undef,
        yTitle => undef,
        yTitleColor => undef,
        url => '',
        z => [],
        zName => undef,
    );
    $self->set(@_);

    return $self;
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
