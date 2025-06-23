# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::PlotlyJs::XY::DiagramGroup - Gruppe von XY-Diagrammen

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Diese Klasse ist ein Perl-Wrapper für die Erzeugung einer Gruppe
von XY-Diagrammen auf Basis von Plotly.js, Beispiel siehe
L<Plotly.js: Plotten und analysieren einer Gruppe von Zeitreihen|http://fseitz.de/blog/index.php?/archives/157-Plotly.js-Plotten-und-analysieren-einer-Gruppe-von-Zeitreihen.html>.

Die Diagrammgruppe zeichnet sich dadurch aus, dass durch alle
Plots der Gruppe synchron gescrollt werden kann. In dem Diagramm,
dessen Rangeslider aktiviert ist, kann mit der linken Maustaste im
Plot ein Zeitbereich ausgewählt und anschließend mit dem
Rangeslider durch den Gesamtbereich gescrollt werden. Das Zoomen
und Scrollen findet dabei über allen Diagrammen synchron
statt. Bei Doppelklick in den Plot-Breich wird der ursprüngliche
Zustand wieder hergestellt. Beim Überfahren der Plots mit der Maus
wird das Koordinatenpaar des nächstgelegenen Punktes
angezeigt. Über das Menü "Shape" kann die Kurvenform eingestellt
und mittels des Buttons "Download as PNG" der aktuelle
Diagramm-Zustand als Grafik heruntergeladen werden.

Es gibt zwei Möglichkeiten, die Plot-Daten in die Diagramme zu
übertragen:

=over 4

=item 1.

Die Arrays B<x>, B<y> (und ggf. B<z>) werden dem Parameter-Objekt
direkt mitgegeben.

=item 2.

Die Arrays B<x>, B<y> (und ggf. B<z>) werden per Ajax-Aufruf
besorgt, wenn beim Parameter-Objekt ein URL definiert ist.
In diesem Fall sind die Daten sind nicht Teil der Seite,
sondern werden per asynchronem Ajax-Request (ggf. via
L<Cross-Origin Resource Sharing|http://fseitz.de/blog/index.php?/archives/159-Ajax-Cross-Origin-Resource-Sharing-CORS-implementieren.html>) geladen.

=back

Das  Laden per Ajax-Request hat den Vorteil, dass das Holen der
Daten parallel geschieht während die Diagramme auf der Seite
schon (leer) angezeigt werden, d.h. der Seitenaufbau ist schneller
und die Daten werden performanter besorgt.

=head2 Parameter-Objekte

Bei der Instantiierung des DiagramGroup-Objekts wird dem Konstruktor
eine Liste von Parameter-Objekten übergeben. Jeder Parameter wird
in ein Diagramm geplottet. Folgende Information wird für die
Darstellung des Diagramms ohne Daten benötigt:

=over 2

=item *

Name (des Parameters)

=item *

Einheit

=item *

Farbe

=item *

Kleinster Wert der X-Achse

=item *

Größter Wert der X-Achse

=item *

Kleinster Wert der Y-Achse

=item *

Größter Wert der Y-Achse

=back

Die Daten selbst werden entweder als Arrays B<x>, B<y> (und ggf. B<z>)
übergeben oder, was vorzuziehen ist, per asynchronem Ajax-Aufruf
geladen, via B<url>.

Beispiel für eine Vorab-Selektion der grundlegenden Diagramm-Daten:

  my $parT = $db->select(qq~
      SELECT
          par_id
          , par_name
          , par_unit
          , par_ymin
          , par_ymax
          , par_color
          , MIN(val_time) AS par_time_min
          , MAX(val_time) AS par_time_max
          , COALESCE(MIN(val_value), par_ymin, 0) AS par_value_min
          , COALESCE(MAX(val_value), par_ymax, 1) AS par_value_max
      FROM
          parameter AS par
          LEFT JOIN value AS val
              ON par_id = val_parameter_id
                  AND val_time >= '__BEGIN__'
                  AND val_time < '__END__'
      WHERE
          par_station_id = __STA_ID__
          AND par_name IN (__PARAMETERS__)
      GROUP BY
          par_id
          , par_name
          , par_unit
          , par_ymin
          , par_ymax
          , par_color
      ~,
      -placeholders =>
          __STA_ID__ => $sta->sta_id,
          __PARAMETERS__ => !@parameters? "''":
              join(', ',map {"'$_'"} @parameters),
          __BEGIN__ => $begin,
          __END__ => $end,
  );
  $parT->normalizeNumber('par_ymin','par_ymax','par_value_min',
      'par_value_max');
  my %parI = $parT->index('par_name');

Vorgegeben ist die Menge der Parameter B<@parameters> und der
Zeitbereich B<$begin> und B<$end>.

Die Instantiierung eines Parameters:

  push @par,Quiq::PlotlyJs::XY::Diagram->new(
      title => $par_name,
      yTitle => Encode::decode('utf-8',$par->par_unit),
      color => '#'.$par->par_color,
      # x => scalar($valT->values('val_time')),
      xMin => $begin, # $par->par_time_min,
      xMax => $end, # $par->par_time_max,
      # y => scalar($valT->values('val_value')),
      yMin => $par_value_min,
      yMax => $par_value_max,
      url => 'http://s31tz.de/timeseries?'.Quiq::Url->queryEncode(
          name => $par->par_name,
      ),
      # z => scalar($valT->values('qua_color')),
      zName => 'Quality',
  );

Die Daten werden per Ajax geladen. Format der text/plain-Antwort:

  2009-02-19 00:00:00<TAB>1025.2<TAB>#0000ff
  ...

=head2 Aufbau HTML

Der HTML-Code der Diagrammgruppe hat folgenden Aufbau. Hierbei ist
B<NAME> der Name der Diagrammgruppe, die beim Konstruktor
angegeben wird, und B<N> die laufende Nummer des Diagramms, beginnend
mit 1.

  <div id="NAME" class="diagramGroup">
    <table ...>
    <tr>
      <td id="NAME-dN" class="diagram" ...></td>
    </tr>
    <tr>
      <td>
        ...
        Rangeslider: <input type="checkbox" id="NAME-rN" class="rangeslider" ... />
        Shape: <select id="NAME-sN" ...>...
      </td>
    </tr>
    </table>
    ...
  </div>

Über die Id kann das jeweilige DOM-Objekt von CSS/JavaScript aus
eindeutig adressiert werden, über die Klasse die Menge der
gleichartigen DOM-Objekte.

=over 4

=item id="NAME"

Id der Diagrammgruppe.

=item class="diagramGroup"

Klasse aller Diagrammgruppen.

=item id="NAME-dN"

Id des Nten Diagramms der Diagrammgruppe.

=item class="diagram"

Klasse aller Diagramme.

=item id="NAME-rN"

Id der Nten Rangeslider-Checkbox.

=item class="rangeslider"

Klasse aller Rangeslider.

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::PlotlyJs::XY::DiagramGroup;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;
use utf8;

our $VERSION = '1.228';

use Quiq::Math;
use Quiq::Json::Code;
use Quiq::JavaScript;
use Quiq::Html::Table::Simple;
use Quiq::JQuery::Function;
use Quiq::Html::Widget::CheckBox;
use Quiq::Html::Widget::SelectMenu;
use Quiq::Html::Widget::Button;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $dgr = $class->new(@attVal);

=head4 Attributes

=over 4

=item debug => $bool (Default: 0)

Zeige über dem Diagramm die Formatierungsgrößen an, die bei
unterschiedlicher Höhe oder Fontgröße angepasst werden müssen.

=item diagrams => \@diagrams

Liste der Diagramm-Objekte. Die Diagramm-Objekte sind vom Typ
B<< Quiq::PlotlyJs::XY::Diagram >> und definieren die Metadaten
für die einzelnen Diagramme der Diagramm-Gruppe.

=item downloadPng => $bool (Default: 1)

Biete einen Button zum Herunterladen der Diagramm-Grafik an.

=item fillArea => $bool (Default: 1)

Biete eine Checkbox zum An- und Abschalten der Fill Area
unter der Kurve an.

=item fontSize => $n

Fontgröße der Achsenbeschriftungen. Aus dieser Größe wird die Größe
der sonstigen Fonts (Titel, Y-Titel) abgeleitet.

=item height => $n (Default: 300)

Höhe eines Diagramms in Pixeln.

=item name => $name (Default: 'dgr')

Name der Diagramm-Gruppe. Der Name wird als CSS-Id für den
äußeren div-Container der Diagramm-Gruppe und als Namespace
für die Funktionen genutzt.

=item scaleY => $bool (Default: 1)

Biete einen Button zur Y-Skalierung der Kurvendaten an.

=item shape => $shape (Default: scatter: 'Spline', scattergl: 'Linear')

Anfangsauswahl des Shape-Menüs auf allen Diagrammen. Der Default
hängt von Attribut type ab. Mögliche Werte: 'Spline', 'Linear', 'Marker'.

=item strict => $bool (Default: 1)

Melde Fehler mittels alert(), nicht nur via console.log().

=item type => 'scatter'|'scattergl' (Default: 'scatter')

Art des Diagramms. Bei 'scattergl' ist der Umgang mit größeren Datenmengen
performanter, insbesondere bei der Anzeige von Markert. Allerdings wird
die Kurvenform 'spline' nicht unterstützt und im Rangeslider
wird keine verkleinerte Form des Graphs angezeigt.

=item xAxisType => 'date'|'linear' (Default: 'date')

Art der X-Achse: date=Zeit, linear=numerisch

=item xTitle => $str

Text unterhalb der X-Achse.

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
        debug => 0,
        diagrams => [],
        downloadPng => 1,
        fillArea => 1,
        fontSize => 11,
        height => 300,
        name => 'dgr',
        scaleY => 1,
        shape => undef,
        strict => 1,
        type => 'scatter',
        width => undef,
        xAxisType => 'date',
        xAxisHoverFormat => '%Y-%m-%d %H:%M:%S', # Format der
            # Spike-Beschriftung für die X-Koordinate. Siehe:
            # https://github.com/d3/d3-3.x-api-reference/blob/master/\
            # Time-Formatting.md#format
        xTitle => undef,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML

=head4 Synopsis

  $html = $dgr->html($h);

=head4 Returns

HTML-Code (String)

=head4 Description

Liefere den HTML-Code der Diagramm-Gruppe.

B<Leere Diagrammgruppe>

Wenn die Liste der Parameter leer ist, liefert die Methode html()
einen Leerstring.

B<Leeres Diagramm>

Besitzt ein Parameter keine Daten (die Arrays x und y sind leer),
wird der Plot-Bereich des betreffenden Diagramms leer dargestellt.
Die Achsen werden gemäß xMin, xMax, yMin, yMax skaliert. Fehlen
auch diese Angaben, nimmt Plotly.js eine Default-Achsen-Skalierung
vor (Zeitbereich: C<2000-01-01 00:00:00> bis C<2001-01-01 00:00:00>,
Y-Wertebereich: C<-1> bis C<4>).

=cut

# -----------------------------------------------------------------------------

sub html {
    my ($self,$h) = @_;

    # Objektattribute

    my ($debug,$diagramA,$fontSize,$height,$name,$shape,$strict,$type,
        $width,$xAxisType,$xAxisHoverFormat,$xTitle) =
        $self->get(qw/debug diagrams fontSize height name shape strict type
        width xAxisType xAxisHoverFormat xTitle/);

    # Default des Attributs shape hängt von type ab

    if (!defined $shape) {
        $shape = $type eq 'scatter'? 'Spline': 'Linear';
        $self->shape($shape);
    }

    # Kein Code, wenn keine Diagram

    if (!@$diagramA) {
        return '';
    }

    # Multi-Attribute (betreffen mehrere Plotly-Attribute)

    my $color = '#ff0000';
    # ---
    my $axisBox = 1; # Zeichne eine Box um den Plotbereich. Die Box hat
        # die Farbe der Achsen (siehe axisColor).

    my ($titleFontSize,$xyTitleFontSize,$titleYOffset,$topMargin,
        $bottomMargin,$leftRightMargin) = @{{
            # pt   ti xy ty t  b   lr
            10 => [14,12,16,43,104,undef,],
            11 => [16,13,18,48,106,undef,],
            12 => [18,14,18,50,110,undef,],
            14 => [20,16,20,55,118,undef,],
            16 => [22,18,20,57,124,  100,],
            18 => [24,20,22,61,134,  110,],
            20 => [26,20,22,63,138,  120,],
            22 => [28,22,22,65,142,  130,],
            24 => [30,24,24,70,150,  140,],
            28 => [35,28,24,75,168,  150,],
            32 => [40,32,24,80,182,  165,],
            36 => [45,36,24,85,196,  180,],
        }->{$fontSize}};

    if ($xAxisType eq 'date') {
        $bottomMargin += $fontSize;
    }
    if (!$xTitle) {
        $bottomMargin -= int $xyTitleFontSize*1.5;
    }

    my $rangeSliderThickness = 25;
    my $height2 = $height-($rangeSliderThickness+18);
    my $bottomMargin2 = $bottomMargin-($rangeSliderThickness+18);

    my $titleY = Quiq::Math->roundTo(
        1-($titleYOffset/$height),4); # Faktor für Titel-Position
    my $titleY2 = Quiq::Math->roundTo(
        1-($height*(1-$titleY)/$height2),4);

    my $rangeSliderThicknessAsFraction = Quiq::Math->roundTo(
        $rangeSliderThickness/($height-$topMargin-$bottomMargin),4);

    # Maße für die Ränder

    my $axisColor = '#d0d0d0'; # Farbe der Achsenlinien
    my $fillColor = '#e0e0e0'; # Farbe zwischen Kurve und X-Achse
    my $gridColor = '#e8e8e8'; # Farbe des Gitters
    my $lineColor = $color;
    my $lineShape = $shape eq 'Linear'? 'linear': 'spline';
        # Linienform: 'spline'|'linear'|'hv'|
        # 'vh'|'hvh'|'vhv'
    my $lineWidth = 1;
    my $margin = [$topMargin,$leftRightMargin,$bottomMargin,$leftRightMargin];
    my $markerColor = $color;
    my $markerSize = 3;
    my $markerSymbol = 'circle';
    my $mode = 'lines'; # Kurvendarstellung: 'lines', 'markers',
        # 'text', 'none'. Die ersteren drei können auch mit '+' verbunden
        # werden.
    my $paperBackground = '#f8f8f8'; # Hintergrund Diagrammbereich
    my $plotBackground = '#ffffff'; # Hintergrund Plotbereich
    my $rangeSliderBorderColor = '#e0e0e0';

    my $xAxisTickFormat;
    if ($xAxisType eq 'date') {
        $xAxisTickFormat = '%Y-%m-%d %H:%M'; # Format der
            # Zeitachsen-Beschriftung
    }

    my $xTickLen = 5;
    my $ySide = 'left'; # Seite, auf der die Y-Achse gezeichnet wird
    my $yTickLen = 4;
    my $zeroLineColor = '#d0d0d0';

    my $yTitle = undef;
    my $xMin = undef;
    my $xMax = undef;
    my $yMin = -1;
    my $yMax = 1;

    # JavaScript-Code

    my $j = Quiq::Json::Code->new;

    # * Namespace mit Datenstrukturen und Funktionen

    my $js = Quiq::JavaScript->code(q°
        var __NAME__ = (function() {
            // Datenstrukturen
            
            let trace = __TRACE__;
            let layout = __LAYOUT__;
            let config = __CONFIG__;
            let vars = __VARS__;

            // Methoden

            let rescaleY = function (dId,yMinOrig,yMaxOrig) {
                let d = $('#'+dId)[0];
                if (d.layout.yaxis.range[0] != yMinOrig ||
                        d.layout.yaxis.range[1] != yMaxOrig) {
                    // Originalen Wertebereich wieder herstellen
                    Plotly.relayout(dId,{'yaxis.range': [yMinOrig,yMaxOrig]});
                    return;
                };
                let x = d.data[0].x;
                if (x.length == 0)
                    return;
                let xMin = Number(d.layout.xaxis.range[0]);
                let xMax = Number(d.layout.xaxis.range[1]);
                let y = d.data[0].y;
                let yMin, yMax;
                for (let i = 0; i < x.length; i++) {
                    if (x[i] >= xMin && x[i] <= xMax) {
                        if (yMin === undefined || y[i] < yMin)
                            yMin = y[i];
                        if (yMax === undefined || y[i] > yMax)
                            yMax = y[i];
                    }
                }
                // console.log(xMin+' '+xMax+' '+yMin+' '+yMax);
                Plotly.relayout(dId,{'yaxis.range': [yMin,yMax]})
            };

            let setRangeSlider = function (groupId,i,bool) {
                let dId = groupId+'-d'+i;
                if (bool) {
                    Plotly.relayout(dId,{
                        'xaxis.rangeslider.visible': true,
                        'xaxis.fixedrange': false,
                        'height': vars.height[0],
                        'margin.b': vars.bottomMargin[0],
                        'title.y': vars.titleY[0],
                    });
                    $('#'+dId).height(vars.height[0]);
                }
                else {
                    Plotly.relayout(dId,{
                        'xaxis.rangeslider.visible': false,
                        'xaxis.fixedrange': true,
                        'height': vars.height[1],
                        'margin.b': vars.bottomMargin[1],
                        'title.y': vars.titleY[1],
                    });
                    $('#'+dId).height(vars.height[1]);
                }
                let cbId = groupId+'-r'+i;
                $('#'+cbId).prop('checked',bool);
                let div = $('#'+dId)[0];
                if (bool) {
                    // Event-Listener auf das aktive (es sollte nur
                    // eins geben) Diagramm setzen. Der Event-Handler
                    // überträgt die Änderungen am xrange auf alle
                    // anderen Diagramme. Probleme hierbei: 1) Der Event wird
                    // nicht nur bei der Bereichsauswahl und beim
                    // Scrollen ausgelöst. 2) Die Erkennung des richtigen
                    // Events am Eventdata-Objekt ed ist schwierig, da
                    // der xrange auf verschiedene Weisen dargestellt wird
                    // (siehe console.log()). Daher nutzen wir
                    // ed['height'] === undefined zur Erkennung.
                    div.on('plotly_relayout',function(ed) {
                        if (ed['yaxis.range']) {
                            // Skalierung Y-Achse leiten wir nicht weiter
                            return;
                        }
                        // console.log(ed+JSON.stringify(ed,null,4));
                        $('#'+groupId+' '+'.diagram').each(function(j) {
                            if (j+1 != i && ed['height'] === undefined) {
                                Plotly.relayout(this,ed);
                            }
                        });
                    });
                }
            };

            let toggleRangeSliders = function (groupId,e) {
                // Event-Listener von allen Diagrammen entfernen
                $('#'+groupId+' .diagram').each(function(i) {
                    this.removeAllListeners('plotly_relayout');
                });
                $('#'+groupId+' .rangeslider').each(function(i) {
                    i++;
                    // Beim angeklickten Rangeslider stellen wir den
                    // gewählten Zustand ein, die anderen schalten wir weg
                    let state = this == e? this.checked: false;
                    setRangeSlider(groupId,i,state);
                });
            };

            // Füge Daten zum Diagramm hinzu. Gibt es keine Daten,
            // zeige "No data found" an und diable Rangeslider
            // und Shape
            let setTrace = function (name,i,trace,layout,shape,x,y,z) {
                trace.x = x;
                trace.y = y;
                if (shape == 'Spline') {
                    trace.mode = 'lines';
                    trace.line.shape = 'spline';
                    trace.marker.color = trace.line.color;
                }
                else if (shape == 'Linear') {
                    trace.mode = 'lines';
                    trace.line.shape = 'linear';
                    trace.marker.color = trace.line.color;
                }
                else if (shape == 'Marker') {
                    trace.mode = 'markers';
                    trace.marker.color = trace.line.color;
                }
                else {
                    trace.mode = 'markers';
                    trace.marker = {
                        color: z,
                        size: 3,
                        symbol: 'circle',
                    }
                }
                if (z.length) {
                    // console.log(z);
                    vars.zArrays[i-1] = z.slice();
                }
                if (!x.length) {
                    layout.annotations = [{
                        text: 'No data found',
                        xref: 'paper',
                        yref: 'paper',
                        showarrow: false,
                        font: {
                            size: 28,
                            color: '#a0a0a0',
                        },
                    }];
                    setRangeSlider(name,i,false);
                    $('#'+name+'-r'+i).prop('disabled',true);
                    $('#'+name+'-s'+i).prop('disabled',true);
                    $('#'+name+'-y'+i).prop('disabled',true);
                }
                let dId = name+'-d'+i;
                Plotly.deleteTraces(dId,0);
                Plotly.addTraces(dId,trace);
                $('#'+name+'-c'+i).html(x.length.toString()+' data points');

                return;
            };

            // Lade Daten asynchron per Ajax und füge sie zum Diagramm hinzu
            let loadDataSetTrace = function (name,i,trace,layout,shape,url) {
                // Daten per Ajax besorgen
                // console.log(url);
                $.ajax({
                    type: 'GET',
                    url: url,
                    async: true,
                    beforeSend: function () {
                        $('body').css('cursor','wait');
                    },
                    complete: function () {
                        $('body').css('cursor','default');
                    },
                    error: function () {
                        let msg = 'ERROR: Ajax request failed: '+url;
                        if (vars.strict) 
                            alert(msg);
                        else
                            console.log(msg);
                    },
                    success: function (data,textStatus,jqXHR) {
                        let x = [];
                        let y = [];
                        let z = [];
                        let rows = data.split('\n');
                        // length ist mindestens 1
                        for (let i = 0; i < rows.length-1; i++) {
                            let arr = rows[i].split('\t');
                            x.push(arr[0]);
                            y.push(parseFloat(arr[1]));
                            if (arr.length > 2)
                                z.push(arr[2]);
                        }
                        setTrace(name,i,trace,layout,shape,x,y,z);
                    },
                });
            };

            let generatePlot = function (name,i,title,yTitle,yTitleColor,~
                    color,xMin,xMax,yMin,yMax,showRangeSlider,shape,url,~
                    x,y,z) {

                let t = $.extend(true,{},trace);
                t.line.color = color;
                t.marker.color = color;

                let l = $.extend(true,{},layout);
                l.title.text = title;
                l.title.font.color = color;
                l.xaxis.range = [xMin,xMax];
                l.yaxis.title.text = yTitle;
                l.yaxis.title.font.color = yTitleColor;
                l.yaxis.range = [yMin,yMax];

                let dId = name+'-d'+i;
                Plotly.newPlot(dId,[t],l,config).then(
                    function() {
                        if (url)
                            loadDataSetTrace(name,i,t,l,shape,url);
                        else
                            setTrace(name,i,t,l,shape,x,y,z);
                    },
                    function() {
                        alert('ERROR: plot creation failed: '+title);
                    }
                );
                setRangeSlider(name,i,showRangeSlider);

                // Bei Doppelklick Y-Skalierung auf allen Diagrammen
                // in Originalzustand zurückversetzen

                let d = $('#'+dId)[0];
                $(d).data('yMinOrig',yMin);
                $(d).data('yMaxOrig',yMax);
                d.on('plotly_doubleclick',function (data) {
                    $('#'+name+' .diagram').each(function(i) {
                        let yMin = $(this).data('yMinOrig');
                        let yMax = $(this).data('yMaxOrig');
                        Plotly.relayout(this,{'yaxis.range': [yMin,yMax]});
                    });
                });
            };

            let getZArray = function (i) {
                // console.log(vars.zArrays[i-1]);
                return vars.zArrays[i-1];
            };

            return {
                getZArray: getZArray,
                generatePlot: generatePlot,
                setRangeSlider: setRangeSlider,
                toggleRangeSliders: toggleRangeSliders,
                rescaleY: rescaleY,
            };
        })();°,
        __NAME__ => $name,
        __TRACE__ => scalar $j->o(
            type => $type,
            mode => $mode, # lines, markers, lines+markers, none,
            fill => 'tozeroy',
            fillcolor => $fillColor,
            line => $j->o(
                width => $lineWidth,
                color => $lineColor,
                shape => $lineShape,
            ),
            marker => $j->o(
                size => $markerSize,
                color => $color, # [....] Einzelfarben
                symbol => $markerSymbol,
                colorscale => undef,
            ),
            x => [],
            y => [],
        ),
        __LAYOUT__ => scalar $j->o(
            plot_bgcolor => $plotBackground,
            paper_bgcolor => $paperBackground,
            # autosize => \'true',
            title => $j->o(
                text => undef,
                font => $j->o(
                    color => $color,
                    size => $titleFontSize,
                ),
                yref => 'container', # container, paper
                yanchor => 'top',
                y => $titleY,
            ),
            spikedistance => -1,
            height => $height,
            width => $width,
            margin => $j->o(
                l => $margin->[3],
                r => $margin->[1],
                t => $margin->[0],
                b => $margin->[2],
                autoexpand => \'false',
            ),
            xaxis => $j->o(
                type => $xAxisType, # 'date', 'linear',
                fixedrange => \'false', # Zoom erlauben
                mirror => $axisBox? \'true': undef,
                linecolor => $axisColor,
                #defined($xMin) && defined($xMax)? (range => [$xMin,$xMax]):
                #    (autorange => \'true'),
                # autorange => \'true',
                gridcolor => $gridColor,
                hoverformat => $xAxisHoverFormat,
                # tickformat => $xAxisTickFormat,
                # tickangle => 30,
                ticklen => $xTickLen,
                tickcolor => $axisColor,
                tickfont => $j->o(
                    size => $fontSize,
                ),
                #tickformatstops => [
                #],
                showspikes => \'true',
                spikethickness => 1,
                spikesnap => 'data',
                spikecolor => '#000000',
                spikedash => 'dot',
                rangeslider => $j->o(
                    autorange => \'true',
                    bordercolor => $rangeSliderBorderColor,
                    borderwidth => 1,
                    thickness => $rangeSliderThicknessAsFraction,
                    # visible => \'false',
                    visible => \'true',
                ),
                title => $j->o(
                    text => $xTitle,
                    font => $j->o(
                        size => $xyTitleFontSize,
                    ),
                ),
                zeroline => \'true',
                zerolinecolor => $zeroLineColor,
                # visible => \'false',
            ),
            yaxis => $j->o(
                type => 'linear',
                fixedrange => \'true', # Zoom verbieten
                automargin => \'true',
                mirror => $axisBox? \'true': undef,
                linecolor => $axisColor,
                defined($yMin) && defined($yMax)? (range => [$yMin,$yMax]):
                    (autorange => \'true'),
                # autorange => \'true',
                ticklen => $yTickLen,
                tickcolor => $axisColor,
                tickfont => $j->o(
                    size => $fontSize,
                ),
                gridcolor => $gridColor,
                showspikes => \'true',
                side => $ySide,
                spikethickness => 1,
                spikesnap => 'data',
                spikecolor => '#000000',
                spikedash => 'dot',
                title => $j->o(
                    text => $yTitle,
                    font => $j->o(
                        color => $color,
                        size => $xyTitleFontSize,
                    ),
                ),
                zeroline => \'true',
                zerolinecolor => $zeroLineColor,
                # visible => \'false',
            ),
        ),
        __CONFIG__ => scalar $j->o(
            displayModeBar => \'false',
            doubleClickDelay => 1000, # 1000ms
            responsive => \'true',
        ),
        __VARS__ => scalar $j->o(
            height => [$height,$height2],
            bottomMargin => [$bottomMargin,$bottomMargin2],
            titleY => [$titleY,$titleY2],
            strict => $strict? \'true': \'false',
            zArrays => [],
        ),
    );

    # Gesamter HTML-Code

    my $debugInfo = '';
    if ($debug) {
        $debugInfo = Quiq::Html::Table::Simple->html($h,
            border => 1,
            cellpadding => 2,
            rows => [
                [[-tag=>'th','height'],[-tag=>'th','fontSize'],
                    [-tag=>'th','rangeSliderThickness'],[-tag=>'th','height2'],
                    [-tag=>'th','xyTitleFontSize'],
                    [-tag=>'th','titleFontSize'],
                    [-tag=>'th','topMargin'],[-tag=>'th','bottomMargin'],
                    [-tag=>'th','bottomMargin2'],[-tag=>'th','titleY'],
                    [-tag=>'th','titleY2'],[-tag=>'th','leftRightMargin']],
                [[$height],[$fontSize],
                    [$rangeSliderThickness.
                        " ($rangeSliderThicknessAsFraction)"],
                    [$height2],[$xyTitleFontSize],[$titleFontSize],
                    [$topMargin],[$bottomMargin],[$bottomMargin2],[$titleY],
                    [$titleY2],[$leftRightMargin]],
            ],
        );
    }

    return $h->cat(
        $debugInfo,
        $h->tag('div',
            id => $name,
            class => 'diagramGroup',
            do {
                # HTML-Code der Diagramme
                
                my $tmp = '';
                my $i = 0;
                for my $par (@$diagramA) {
                    $tmp .= $self->htmlDiagram($h,++$i,$par,
                        $paperBackground,$debug);
                }
                $tmp;
            }
        ),
        $h->tag('script',
            '-',
            $js,do {
                # Ready-Handler

                my $tmp = '';
                my $i = 0;
                for my $par (@$diagramA) {
                    $tmp .= $self->jsDiagram($j,++$i,$par);
                }

# $tmp .= Quiq::JavaScript->code(q~
#     $('#dgr-d1 rect.nsewdrag').bind('mousemove',function(e){   
#         console.log(e);
#     });
# 
#     let e = $.Event('mousemove');
# 
#     // coordinates
#     e.pageX = 250;
#     e.pageY = 250; 
# 
#     // trigger event
#     $('#dgr-d1 rect.nsewdrag').trigger(e);
# ~);

                Quiq::JQuery::Function->ready($tmp);
            },
        ),
    );
}

# -----------------------------------------------------------------------------

=head2 Private Methoden

=head3 htmlDiagram() - Generiere HTML für ein Diagramm

=head4 Synopsis

  $html = $dgr->htmlDiagram($h,$i,$par,$paperBackground,$debug);

=head4 Arguments

=over 4

=item $h

Generator für HTML-Code.

=item $i

Nummer des Diagramms.

=back

=head4 Returns

HTML-Code (String)

=head4 Description

Genererie den HTML-Code für ein Diagramm und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub htmlDiagram {
    my ($self,$h,$i,$par,$paperBackground,$debug) = @_;

    # Objektattribute

    my ($height,$name,$shape,$type,$width) = $self->get(qw/height name
        shape type width/);

    # HTML erzeugen

    my $parameterName = $par->title;
    my $zName = $par->zName // '';
    my $color = $par->color;

    return
        Quiq::Html::Table::Simple->html($h,
        border => $debug? 1: undef,
        width => $width? "${width}px": '100%',
        style => [
            border => '1px dotted #b0b0b0',
           'margin-top' => '0.6em',
           'background-color' => $paperBackground,
            position => 'relative',
        ],
        rows => [
            [[
                id => "$name-d$i",
                class => 'diagram',
                style => [
                    height => "${height}px",
                ],
            ]],
            [[
                $h->tag('span',style=>'margin-left: 10px','Rangeslider:').
                Quiq::Html::Widget::CheckBox->html($h,
                     id =>  "$name-r$i",
                     class => 'rangeslider',
                     option => 1,
                     value => 0,
                     # style => 'vertical-align: middle',
                     title => 'Toggle visibility of range slider',
                     onClick => "$name.toggleRangeSliders('$name',this)",
                ).
                ' | Shape: '.Quiq::Html::Widget::SelectMenu->html($h,
                    id => "$name-s$i",
                    value => $shape,
                    options => [
                        $type eq 'scatter'? ('Spline'): (),
                        'Linear',
                        'Marker',
                        $zName? ($zName): (),
                    ],
                    onChange => Quiq::JavaScript->line(qq~
                        let shape = \$('#$name-s$i').val();
                        if (shape == 'Spline') {
                            Plotly.restyle('$name-d$i',{
                                'mode': 'lines',
                                'line.shape': 'spline',
                            });
                        }
                        else if (shape == 'Linear') {
                            Plotly.restyle('$name-d$i',{
                                'mode': 'lines',
                                'line.shape': 'linear',
                            });
                        }
                        else if (shape == 'Marker') {
                            Plotly.restyle('$name-d$i',{
                                'mode': 'markers',
                                'marker.color': '$color',
                            });
                        }
                        else if (shape == '$zName') {
                            let z = $name.getZArray($i);
                            // console.log(z);
                            Plotly.restyle('$name-d$i',{
                                mode: 'markers',
                                marker: {
                                    color: z,
                                    size: 3,
                                    symbol: 'circle',
                                },
                            });
                        }
                    ~),
                    title => 'Connect data points with straight lines,'.
                        ' splines or show markers',
                ).
                (
                    !$self->fillArea? '':
                        ' | FillArea:'.Quiq::Html::Widget::CheckBox->html(
                             $h,
                             id =>  "$name-f$i",
                             option => 1,
                             value => 1,
                             style => 'vertical-align: middle',
                             title => 'Toggle colored area above or below'.
                                 ' graph',
                             onClick => qq~
                                let fill = this.checked? 'tozeroy': 'none';
                                Plotly.restyle('$name-d$i',{
                                    'fill': fill,
                                });
                             ~,
                        )
                ).(
                    !$self->scaleY? '':
                        ' | '.Quiq::Html::Widget::Button->html($h,
                            id => "$name-y$i",
                            content => 'Scale Y Axis',
                            onClick => sprintf("%s.rescaleY('%s',%s,%s)",
                                $name,"$name-d$i",$par->yMin,$par->yMax),
                            title => 'Rescale Y axis according to visible'.
                                ' data or original state',
                        )
                ).(
                    !$self->downloadPng? '':
                        ' | '.Quiq::Html::Widget::Button->html($h,
                            content => 'Download as PNG',
                            onClick => qq~
                                let plot = \$('#$name-d$i');
                                Plotly.downloadImage(plot[0],{
                                    format: 'png',
                                    width: plot.width(),
                                    height: plot.height(),
                                    filename: '$parameterName',
                                });
                            ~,
                            title => 'Download plot graphic as PNG',
                        )
                ).
                $h->tag('div',
                   id =>  "$name-c$i",
                   style => 'position: absolute; bottom: 7px; right: 10px',
                   ''
                ).
                ($par->get('html') // ''), # optionaler HTML-Code
           ]]
        ]);
}

# -----------------------------------------------------------------------------

=head3 jsDiagram() - Generiere JavaScript für ein Diagramm

=head4 Synopsis

  $js = $dgr->jsDiagram($j,$i,$par);

=head4 Arguments

=over 4

=item $j

JSON-Generator

=item $i

Nummer des Diagramms.

=item $par

Zeitreihen-Objekt.

=back

=head4 Returns

JavaScript-Code (String)

=head4 Description

Genererie den JavaScript-Code für ein Diagramm und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub jsDiagram {
    my ($self,$j,$i,$par) = @_;

    # Objektattribute

    my ($name,$shape) = $self->get('name','shape');

    # JavaScript erzeugen

    my $xMin = $par->xMin;
    if (!defined($xMin) || $xMin eq '') {
        $xMin = 'undefined';
    }
    my $xMax = $par->xMax;
    if (!defined($xMax) || $xMax eq '') {
        $xMax = 'undefined';
    }
    my $yMin = $par->yMin // 'undefined';
    my $yMax = $par->yMax // 'undefined';
    my $showRangeSlider = $i == 1? 'true': 'false';

    my $url = $par->url;
    if ($url) {
        return sprintf("$name.generatePlot('%s',%s,'%s','%s',%s,'%s','%s'".
                ",'%s',%s,%s,%s,'%s','%s');\n",
            $name,$i,$par->title,$par->yTitle//'',
            $j->encode($par->yTitleColor),
            $par->color,$xMin,$xMax,$yMin,$yMax,$showRangeSlider,$shape,$url);
    }
    else {
        # mit x,y,z
        return sprintf("$name.generatePlot('%s',%s,'%s','%s',%s,'%s','%s'".
                ",'%s',%s,%s,%s,'%s','',%s,%s,%s);\n",
            $name,$i,$par->title,$par->yTitle//'',
            $j->encode($par->yTitleColor),
            $par->color,$xMin,$xMax,$yMin,$yMax,$showRangeSlider,$shape,
            scalar($j->encode($par->x)),scalar($j->encode($par->y)),
            scalar($j->encode($par->z)));
    }
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
