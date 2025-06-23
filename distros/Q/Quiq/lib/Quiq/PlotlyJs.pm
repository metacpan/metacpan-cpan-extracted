# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::PlotlyJs - Basisfunktionalität/Notizen zu Plotly.js

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Diese Modul enthält Basisfunktionalität und Notizen zur JavaScript
Plot-Bibliothek Plotly.js.

=head2 Verweise

=over 2

=item *

L<Plotly.js|https://plotly.com/javascript/> - Dokumentation zur Plot-Bibliothek

=item *

L<Time Formats|https://github.com/d3/d3/blob/master/API.md#time-formats-d3-time-format> - Formatierung von Zeitangaben

=item *

L<Change the Default Locale|https://plotly.com/javascript/configuration-options/#change-the-default-locale> - Locale Umstellung

=item *

L<Axis hover formatting|https://community.plotly.com/t/axis-hover-formatting-with-function/1349> - Beliebige Hover-Texte

=item *

L<Empty graph with message|https://community.plotly.com/t/replacing-an-empty-graph-with-a-message/31497> - Plot mit Meldung

=item *

L<Get state of chart|https://community.plotly.com/t/get-state-of-current-chart/5827> - Zugriff auf trace, layout usw.

=item *

L<Error Bars|https://plotly.com/javascript/error-bars/> - Fehlerbalken

=back

=head2 Notizen

=head3 Umschaltung einzelne Marker-Farbe, Array von Markerfarben

Ist der Plot auf eine einzelne Markerfarbe eingestellt worden,
kann nicht auf ein Array von Markerfarben umgeschaltet werden,
ohne die gesamte Marker-Struktur zu setzen. Die Komponente
B<color> von einem String auf ein Array umzusetzen reicht nicht!

Falsch:

  'marker.color': [...],

Richtig:

  marker: {
      color: [...],
      ...
  },

=head3 Beliebige Hover-Texte definieren

Hover-Texte können ohne Events nicht dynamisch berechnet werden,
da Plotly.js nur JSON-serialisierare Strukturkomponenten besitzt und
keine Funktionsattribute vorgesehen sind. Das Trace-Attribut
B<text: [...]> kann aber genutzt werden, um jedem Wert
ein individuelles Label zuzuweisen (L<Axis hover formatting|https://community.plotly.com/t/axis-hover-formatting-with-function/1349>).

=head3 Zeit-Werte

Zeit-Werte werden am besten als Strings der Form C<YYYY-MM-DD
HH:MM:SS> an Plotly.js übergeben. Nur dann ist gesichert, dass
diese Zeit auch im Plot erscheint. Übergibt man die Zeit als
Epoch-Wert (Millisekunden seit 01.01.1970) oder JavaScript
Date-Objekt, wird diese von UTC in die Zeitzone des Browsers
umgerechnet. Darauf kann laut der Plotly-Entwickler kein Einfluss
genommen werden, da Plotly keine Zeitzonen kennt:
L<Issue 1532|https://github.com/plotly/plotly.js/issues/1532>.

=head3 Diagramm-Höhe

Die Diagramm-Höhe kann im div-Container, in der Layout-Konfiguration
oder in beiden gesetzt werden. Die Auswirkungen:

=over 2

=item *

Wird die Höhe nur beim div-Container gesetzt, füllt Plotly
die Höhe immer ganz aus. Wird z.B. der Rangeslider entfernt, rendert
Plotly das Diagramm neu, so dass es wieder die gesamte Höhe ausfüllt.
D.h. der Plotbereich wird höher. Der Inhalt des Diagramms ist
nicht statisch. Das wollen wir nicht.

=item *

Wird die Höhe nur in der Layout-Konfiguration gesetzt, hat der
div-Container zunächst die Höhe 0, bis das Diagramm
(typischerweise im ready-Handler) aufgebaut wird. Das wollen wir
auch nicht.

=item *

Wird die Höhe im div-Container I<und> in der Layout-Konfiguration
gesetzt, ist der Bereich des Diagramms auf der Seite sofort
sichtbar, der Inhalt kann aber aber statisch gehalten werden,
indem beide Angaben gemeinsam geändert werden.

=back

=head3 Unterer Rand

Im unteren Rand ist die Beschriftung der X-Achse und der
Rangeslider angesiedelt. Die Beschriftung hat einen Platzbedarf von
55 Pixeln, die Dicke des Rangesliders ist auf 20% der Plothöhe
eingestellt. Wir nutzen folgende Formel, um aus der Höhe des
Diagramms die Höhe des unteren Rands zu berechnen:

  bottomMargin = (height - 300) / 50 * 10 + 110;

Das ergibt folgende Werte (height->marginBottom):

  250->100, 300->110, 350->120, 400->130, 450->140,...

Wenn wir den Rangeslider entfernen, reduzieren wir die Höhe des
Diagramms und den unteren Rand um

  marginBottom - 55

=head3 Titel-Positionierung

Der Diagramm-Titel wird per Default leider ungünstig positioniert,
daher positionieren wir ihn selbst. Damit der Titel
oberhalb des Plot-Bereichs positioniert werden kann, muss
im Layout C<container> als Bezugsbereich vereinbart werden:

  title: {
      yref: 'container',
      yanchor => 'top',
      y => $y0,
  }

Hierbei ist $y0 ein Wert zwischen 0 und 1, der die vertikale
Position innerhalb des Diagramms festlegt. 1 -> ganz oben unter dem
Rand, 0 -> ganz unten unter (!) dem Rand.

Ändert sich die Höhe des Diagramms, muss der Wert y auf
die neue Höhe y1 umgerechnet werden:

  y1 = 1 - (height0 * (1 - y0) / height1);

=head3 Raum unter der Achse einfärben

Ist beim Trace-Layout das Füllen unter der Achse angegeben mit

  fill: 'tozeroy',
  fillcolor: '#e0e0e0',

wird der Y-Wertebereich nach unten bis 0 ausgedehnt, wenn kein
Y-Wertebereich explizit vorgegeben ist. Ist für die Y-Achse
(im Diagramm-Layout!) explizit ein Wertebereich vorgegeben, z.B.

  range => [900,1000],

findet die Ausdehnung bis 0 nicht statt, der Raum unter der
Kurve wird dennoch wie gewünscht gefüllt.

=cut

# -----------------------------------------------------------------------------

package Quiq::PlotlyJs;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 cdnUrl() - Liefere CDN URL

=head4 Synopsis

  $url = $this->cdnUrl;

=head4 Returns

URL (String)

=head4 Description

Liefere den CDN URL der neusten Version von Plotly.js.

=head4 Example

  $url = Quiq::PlotlyJs->cdnUrl;
  ==>
  https://cdn.plot.ly/plotly-latest.min.js

=cut

# -----------------------------------------------------------------------------

sub cdnUrl {
    my $this = shift;
    return 'https://cdn.plot.ly/plotly-latest.min.js';
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
