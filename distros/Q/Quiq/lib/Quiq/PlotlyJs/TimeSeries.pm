# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::PlotlyJs::TimeSeries - Zeitreihen-Plot auf Basis von Plotly.js

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Diese Klasse ist ein Perl-Wrapper für die Erzeugung für
Zeitreihen-Plots auf Basis von Plotly.js.

Dokumentation und Beispiele: L<https://plotly.com/javascript/>

Zeitformate: L<https://github.com/d3/d3/blob/master/API.md#time-formats-d3-time-format>

=head2 Leeres Diagramm

Ein Konstuktoraufruf ohne jegliche Angaben, also auch ohne Daten,
ergibt ein leeres Diagramm. Die X-Achse umfasst den (willkürlich
gewählten) Zeitbereich von C<2000-01-01 00:00:00> bis C<2001-01-01
00:00:00>. Die Y-Achse umfasst den (willkürlich gewählten)
Wertebereich C<-1> bis C<4>.

=head2 Diagramm-Höhe

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

=head2 Unterer Rand

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

=head2 Titel-Positionierung

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

=head2 Raum unter der Achse einfärben

Ist beim Trace-Layout das Füllen unter der Achse angegeben mit

  fill: 'tozeroy',
  fillcolor: '#e0e0e0',

wird der Y-Wertebereich nach unten bis 0 ausgedehnt, wenn kein
Y-Wertebereich explizit vorgegeben ist. Ist für die Y-Achse
(Diagramm-Layout!) explizit ein Wertebereich vorgegeben

  range => [900,1000],

findet die Ausdehnung bis 0 nicht statt, der Raum unter der
Kurve wird dennoch wie gewünscht gefüllt.

=head1 EXAMPLE

(Folgendes Diagramm erscheint in HTML - außer auf meta::cpan, da der
HTML-Code dort gestrippt wird - es zeigt 720 Messwerte einer
Windgeschwindigkeits-Messung)

=begin html

<script type="text/javascript" src="https://code.jquery.com/jquery-latest.min.js"></script>
<script type="text/javascript" src="https://cdn.plot.ly/plotly-latest.min.js"></script>
<div id="plot" class="plotly-timeseries" style="height: 400px; border: 1px dotted #b0b0b0;"></div>
<script type="text/javascript">
  $(function() {
    var plot = Plotly.newPlot('plot',[{
      type: 'scatter',
      mode: 'lines',
      fill: 'tozeroy',
      fillcolor: '#e0e0e0',
      line: {
        width: 1,
        color: '#ff0000',
        shape: 'linear',
      },
      marker: {
        size: 3,
        color: '#ff0000',
        symbol: 'circle',
      },
      x: [1573167600000,1573168200000,1573168800000,1573169400000,1573170000000,1573170600000,1573171200000,1573171800000,1573172400000,1573173000000,1573173600000,1573174200000,1573174800000,1573175400000,1573176000000,1573176600000,1573177200000,1573177800000,1573178400000,1573179000000,1573179600000,1573180200000,1573180800000,1573181400000,1573182000000,1573182600000,1573183200000,1573183800000,1573184400000,1573185000000,1573185600000,1573186200000,1573186800000,1573187400000,1573188000000,1573188600000,1573189200000,1573189800000,1573190400000,1573191000000,1573191600000,1573192200000,1573192800000,1573193400000,1573194000000,1573194600000,1573195200000,1573195800000,1573196400000,1573197000000,1573197600000,1573198200000,1573198800000,1573199400000,1573200000000,1573200600000,1573201200000,1573201800000,1573202400000,1573203000000,1573203600000,1573204200000,1573204800000,1573205400000,1573206000000,1573206600000,1573207200000,1573207800000,1573208400000,1573209000000,1573209600000,1573210200000,1573210800000,1573211400000,1573212000000,1573212600000,1573213200000,1573213800000,1573214400000,1573215000000,1573215600000,1573216200000,1573216800000,1573217400000,1573218000000,1573218600000,1573219200000,1573219800000,1573220400000,1573221000000,1573221600000,1573222200000,1573222800000,1573223400000,1573224000000,1573224600000,1573225200000,1573225800000,1573226400000,1573227000000,1573227600000,1573228200000,1573228800000,1573229400000,1573230000000,1573230600000,1573231200000,1573231800000,1573232400000,1573233000000,1573233600000,1573234200000,1573234800000,1573235400000,1573236000000,1573236600000,1573237200000,1573237800000,1573238400000,1573239000000,1573239600000,1573240200000,1573240800000,1573241400000,1573242000000,1573242600000,1573243200000,1573243800000,1573244400000,1573245000000,1573245600000,1573246200000,1573246800000,1573247400000,1573248000000,1573248600000,1573249200000,1573249800000,1573250400000,1573251000000,1573251600000,1573252200000,1573252800000,1573253400000,1573254000000,1573254600000,1573255200000,1573255800000,1573256400000,1573257000000,1573257600000,1573258200000,1573258800000,1573259400000,1573260000000,1573260600000,1573261200000,1573261800000,1573262400000,1573263000000,1573263600000,1573264200000,1573264800000,1573265400000,1573266000000,1573266600000,1573267200000,1573267800000,1573268400000,1573269000000,1573269600000,1573270200000,1573270800000,1573271400000,1573272000000,1573272600000,1573273200000,1573273800000,1573274400000,1573275000000,1573275600000,1573276200000,1573276800000,1573277400000,1573278000000,1573278600000,1573279200000,1573279800000,1573280400000,1573281000000,1573281600000,1573282200000,1573282800000,1573283400000,1573284000000,1573284600000,1573285200000,1573285800000,1573286400000,1573287000000,1573287600000,1573288200000,1573288800000,1573289400000,1573290000000,1573290600000,1573291200000,1573291800000,1573292400000,1573293000000,1573293600000,1573294200000,1573294800000,1573295400000,1573296000000,1573296600000,1573297200000,1573297800000,1573298400000,1573299000000,1573299600000,1573300200000,1573300800000,1573301400000,1573302000000,1573302600000,1573303200000,1573303800000,1573304400000,1573305000000,1573305600000,1573306200000,1573306800000,1573307400000,1573308000000,1573308600000,1573309200000,1573309800000,1573310400000,1573311000000,1573311600000,1573312200000,1573312800000,1573313400000,1573314000000,1573314600000,1573315200000,1573315800000,1573316400000,1573317000000,1573317600000,1573318200000,1573318800000,1573319400000,1573320000000,1573320600000,1573321200000,1573321800000,1573322400000,1573323000000,1573323600000,1573324200000,1573324800000,1573325400000,1573326000000,1573326600000,1573327200000,1573327800000,1573328400000,1573329000000,1573329600000,1573330200000,1573330800000,1573331400000,1573332000000,1573332600000,1573333200000,1573333800000,1573334400000,1573335000000,1573335600000,1573336200000,1573336800000,1573337400000,1573338000000,1573338600000,1573339200000,1573339800000,1573340400000,1573341000000,1573341600000,1573342200000,1573342800000,1573343400000,1573344000000,1573344600000,1573345200000,1573345800000,1573346400000,1573347000000,1573347600000,1573348200000,1573348800000,1573349400000,1573350000000,1573350600000,1573351200000,1573351800000,1573352400000,1573353000000,1573353600000,1573354200000,1573354800000,1573355400000,1573356000000,1573356600000,1573357200000,1573357800000,1573358400000,1573359000000,1573359600000,1573360200000,1573360800000,1573361400000,1573362000000,1573362600000,1573363200000,1573363800000,1573364400000,1573365000000,1573365600000,1573366200000,1573366800000,1573367400000,1573368000000,1573368600000,1573369200000,1573369800000,1573370400000,1573371000000,1573371600000,1573372200000,1573372800000,1573373400000,1573374000000,1573374600000,1573375200000,1573375800000,1573376400000,1573377000000,1573377600000,1573378200000,1573378800000,1573379400000,1573380000000,1573380600000,1573381200000,1573381800000,1573382400000,1573383000000,1573383600000,1573384200000,1573384800000,1573385400000,1573386000000,1573386600000,1573387200000,1573387800000,1573388400000,1573389000000,1573389600000,1573390200000,1573390800000,1573391400000,1573392000000,1573392600000,1573393200000,1573393800000,1573394400000,1573395000000,1573395600000,1573396200000,1573396800000,1573397400000,1573398000000,1573398600000,1573399200000,1573399800000,1573400400000,1573401000000,1573401600000,1573402200000,1573402800000,1573404000000,1573404600000,1573405200000,1573405800000,1573406400000,1573407000000,1573407600000,1573408200000,1573408800000,1573409400000,1573410000000,1573410600000,1573411200000,1573411800000,1573412400000,1573413000000,1573413600000,1573414200000,1573414800000,1573415400000,1573416000000,1573416600000,1573417200000,1573417800000,1573418400000,1573419000000,1573419600000,1573420200000,1573420800000,1573421400000,1573422000000,1573422600000,1573423200000,1573423800000,1573424400000,1573425000000,1573425600000,1573426200000,1573426800000,1573427400000,1573428000000,1573428600000,1573429200000,1573429800000,1573430400000,1573431000000,1573431600000,1573432200000,1573432800000,1573433400000,1573434000000,1573434600000,1573435200000,1573435800000,1573436400000,1573437000000,1573437600000,1573438200000,1573438800000,1573439400000,1573440000000,1573440600000,1573441200000,1573441800000,1573442400000,1573443000000,1573443600000,1573444200000,1573444800000,1573445400000,1573446000000,1573446600000,1573447200000,1573447800000,1573448400000,1573449000000,1573449600000,1573450200000,1573450800000,1573451400000,1573452000000,1573452600000,1573453200000,1573453800000,1573454400000,1573455000000,1573455600000,1573456200000,1573456800000,1573457400000,1573458000000,1573458600000,1573459200000,1573459800000,1573460400000,1573461000000,1573461600000,1573462200000,1573462800000,1573463400000,1573464000000,1573464600000,1573465200000,1573465800000,1573466400000,1573467000000,1573467600000,1573468200000,1573468800000,1573469400000,1573470000000,1573470600000,1573471200000,1573471800000,1573472400000,1573473000000,1573473600000,1573474200000,1573474800000,1573475400000,1573476000000,1573476600000,1573477200000,1573477800000,1573478400000,1573479000000,1573479600000,1573480200000,1573480800000,1573481400000,1573482000000,1573482600000,1573483200000,1573483800000,1573484400000,1573485000000,1573485600000,1573486200000,1573486800000,1573487400000,1573488000000,1573488600000,1573489200000,1573489800000,1573490400000,1573491000000,1573491600000,1573492200000,1573492800000,1573493400000,1573494000000,1573494600000,1573495200000,1573495800000,1573496400000,1573497000000,1573497600000,1573498200000,1573498800000,1573499400000,1573500000000,1573500600000,1573501200000,1573501800000,1573502400000,1573503000000,1573503600000,1573504200000,1573504800000,1573505400000,1573506000000,1573506600000,1573507200000,1573507800000,1573508400000,1573509000000,1573509600000,1573510200000,1573510800000,1573511400000,1573512000000,1573512600000,1573513200000,1573513800000,1573514400000,1573515000000,1573515600000,1573516200000,1573516800000,1573517400000,1573518000000,1573518600000,1573519200000,1573519800000,1573520400000,1573521000000,1573521600000,1573522200000,1573522800000,1573523400000,1573524000000,1573524600000,1573525200000,1573525800000,1573526400000,1573527000000,1573527600000,1573528200000,1573528800000,1573529400000,1573530000000,1573530600000,1573531200000,1573531800000,1573532400000,1573533000000,1573533600000,1573534200000,1573534800000,1573535400000,1573536000000,1573536600000,1573537200000,1573537800000,1573538400000,1573539000000,1573539600000,1573540200000,1573540800000,1573541400000,1573542000000,1573542600000,1573543200000,1573543800000,1573544400000,1573545000000,1573545600000,1573546200000,1573546800000,1573547400000,1573548000000,1573548600000,1573549200000,1573549800000,1573550400000,1573551000000,1573551600000,1573552200000,1573552800000,1573553400000,1573554000000,1573554600000,1573555200000,1573555800000,1573556400000,1573557000000,1573557600000,1573558200000,1573558800000,1573559400000,1573560000000,1573560600000,1573561200000,1573561800000,1573562400000,1573563000000,1573563600000,1573564200000,1573564800000,1573565400000,1573566000000,1573566600000,1573567200000,1573567800000,1573568400000,1573569000000,1573569600000,1573570200000,1573570800000,1573571400000,1573572000000,1573572600000,1573573200000,1573573800000,1573574400000,1573575000000,1573575600000,1573576200000,1573576800000,1573577400000,1573578000000,1573578600000,1573579200000,1573579800000,1573580400000,1573581000000,1573581600000,1573582200000,1573582800000,1573583400000,1573584000000,1573584600000,1573585200000,1573585800000,1573586400000,1573587000000,1573587600000,1573588200000,1573588800000,1573589400000,1573590000000,1573590600000,1573591200000,1573591800000,1573592400000,1573593000000,1573593600000,1573594200000,1573594800000,1573595400000,1573596000000,1573596600000,1573597200000,1573597800000,1573598400000,1573599000000,1573599600000],
      y: [11.142,11.524,10.343,10.604,11.824,11.266,10.642,10.093,9.1365,8.6981,8.5784,8.83,8.9365,8.6053,8.0124,9.2907,8.8921,8.4226,8.361,8.3603,9.092,8.8321,9.0572,8.076,8.0475,8.5653,8.5676,7.909,8.3279,8.9462,8.2227,7.4135,7.1417,6.1413,6.1684,6.2048,6.0224,5.8958,6.21,6.0992,6.102,5.7212,5.757,5.6007,5.2626,6.162,6.5931,7.0725,7.9139,7.9366,7.7247,8.1006,8.5755,8.3681,8.9414,8.9655,8.6273,8.8311,8.5993,8.4938,9.0882,8.9791,9.151,8.9804,9.9322,10.229,10.446,9.6706,9.3077,9.2482,9.4737,9.4784,9.4391,10.082,9.593,10.762,12.304,12.765,12.355,12.684,12.551,13.121,12.812,12.482,11.992,12.023,11.725,11.585,10.989,11.135,10.723,11.035,10.564,11.13,11.677,12.908,12.973,12.511,11.842,11.4,11.058,11.949,12.081,12.505,13.937,12.72,13.891,11.878,9.9409,8.8398,8.2837,7.7194,8.6815,9.6036,11.517,14.246,14.132,15.098,13.865,14.74,12.647,12.552,15.178,14.983,13.649,13.731,12.781,15.184,12.77,13.275,13.662,16.822,12.808,12.394,10.968,12.761,17.678,11.119,15.816,15.469,12.171,13.475,14.389,12.486,13.798,15.288,14.633,13.796,14.099,16.695,16.372,13.929,12.818,14.77,14.347,11.71,14.4,14.35,14.865,13.146,13.731,13.54,17.228,13.228,14.566,16.707,13.462,12.916,16.215,15.192,14.956,17.472,17.036,17.063,17.796,18.718,17.825,17.535,17.69,15.962,16.488,17.399,18.279,18.915,17.873,16.229,16.082,19.299,19.502,19.92,19.444,17.233,19.616,19.508,17.576,18.238,18.105,18.993,18.873,17.888,18.362,19.393,17.357,17.944,18.254,19.015,19.95,18.13,18.068,21.423,17.46,18.824,19.862,18.221,17.964,18.402,18.338,17.944,16.168,19.031,20.231,17.822,18.44,20.05,19.13,17.994,16.714,18.015,18.616,18.65,18.101,19.864,18.401,18.731,17.925,18.968,18.625,18.227,20.501,20.798,15.676,16.109,17.362,19.106,17.976,14.419,14.536,18.113,16.115,17.646,18.004,18.452,19.881,16.999,17.11,20.107,16.814,17.585,17.425,17.067,16.98,15.499,16.694,17.567,15.407,16.808,16.86,16.744,15.839,16.125,15.56,17.977,17.873,16.315,14.065,15.391,15.549,15.902,15.84,14.739,14.045,14.311,14.263,13.989,13.39,12.862,12.374,13.646,13.27,12.996,11.484,11.654,12.04,11.471,9.4777,12.092,12.036,12.325,11.26,11.003,11.056,12.653,11.933,13.471,12.743,13.574,12.158,11.509,12.311,12.17,10.343,11.65,13.315,11.003,11.416,12.245,12.275,13.134,12.73,13.051,13.945,11.899,12.51,12.716,10.324,10.266,10.547,9.6788,11.616,10.614,9.5814,9.2896,8.8913,9.8219,10.57,9.1744,11.363,12.469,11.539,12.978,10.694,10.633,11.753,10.084,12.639,13.16,11.916,11.474,11.495,12.465,12.596,12.72,9.3058,10.476,14.968,15.779,12.325,10.371,9.4045,13.507,14.068,10.316,8.244,10.688,14.432,12.589,8.4581,7.2494,12.972,9.4151,10.434,10.813,10.198,8.5745,9.2283,11.764,12.336,11.829,10.962,11.088,11.763,14.134,8.094,7.6789,8.6084,9.0337,9.9814,9.9403,9.6462,10.67,6.4388,3.6575,2.921,9.8455,10.405,7.5777,6.7923,8.4932,7.1617,5.3501,7.4563,7.8523,6.0806,6.4744,6.9166,8.0283,8.3801,7.0883,6.886,7.1645,6.4038,10.769,6.8063,6.3469,5.8389,6.818,7.9767,9.4294,7.7969,6.8951,6.3056,5.4468,4.9926,4.7008,5.1699,5.5655,5.2003,4.3514,4.0715,4.0116,4.9238,5.2118,5.5992,5.3924,5.325,4.3683,5.2034,5.4291,5.9364,6.6686,6.1789,6.8653,7.21,7.7114,9.1491,7.4224,6.8293,9.8983,13.272,14.243,16.132,16.343,17.22,12.471,8.2292,5.1487,3.236,2.6038,1.7618,2.1459,2.0727,1.4333,1.0696,2.7428,4.9414,3.7368,5.319,7.2735,9.6245,9.9489,8.7062,7.7889,8.3732,7.5769,8.6453,8.5449,7.7641,7.8346,7.3066,6.763,7.3616,7.1119,6.4413,6.699,6.5204,6.2435,6.632,5.8984,6.2509,6.5763,7.7363,6.8599,6.7808,8.2888,9.0233,5.3644,7.0148,8.4653,8.5078,9.2944,9.3122,7.9084,8.2096,9.5056,8.0469,6.7035,7.3514,8.2602,13.666,12.81,13.158,11.648,12.011,12.867,11.672,9.1638,8.7104,12.806,15.737,15.89,9.3137,8.025,8.5042,9.5073,9.5958,11.346,8.4166,10.219,11.514,16.394,15.26,13.288,13.135,14.123,13.037,12.673,12.968,12.848,14.419,14.979,15.234,13.138,9.6594,8.2285,7.1744,7.3132,11.892,11.252,11.26,13.4,13.312,12.276,12.161,11.632,11.975,11.783,11.861,11.747,11.193,13.527,14.698,11.937,15.2,13.353,10.386,10.991,10.444,9.6877,9.1259,6.8962,5.8379,8.2692,7.3411,16.74,16.519,12.494,11.721,12.382,13.003,13.546,13.636,10.835,15.534,16.669,14.253,15.002,14.85,16.415,15.733,15.974,14.421,14.208,14.385,16.308,16.622,14.814,13.628,17.777,15.583,16.752,17.047,17.543,17.943,17.24,17.781,18.481,17.531,19.057,19.985,18.644,18.364,15.942,16.249,17.714,18.363,17.126,17.548,14.776,16.845,16.468,15.058,13.342,13.838,15.281,14.377,15.716,15.602,15.187,14.808,13.92,13.606,14.298,15.136,14.49,13.24,11.313,9.1919,8.7701,8.9702,8.8606,7.8012,7.9557,7.4307,11.543,11.374,11.287,7.2281,4.4993,4.9059,10.826,12.45,9.4174,7.4316,8.9589,8.1305,4.4854,5.9888,9.2665,9.6626,9.9196,9.9101,8.8638,9.4765,9.0699,9.6093,9.1072,7.1331,5.7111,4.5949,5.2524,5.1016,7.2966,10.125,10.476,9.26,6.9813,7.2153,7.5221,5.3857,7.3752,7.1289,7.5026,5.7992,5.2273,5.0211,5.1433,5.8475,6.3824,4.7445,4.695,5.0794,4.103,4.5129,4.4942,5.2719,6.5797,6.5465,5.843,5.1389,5.8237,5.1551,4.3657,5.0073,7.0279,7.5665,7.2244,7.0065,5.1047,4.7981,5.6936,6.5205,6.8074,9.2159,9.7935,9.3623,9.6505,10.112,10.003,10.03,8.2422],
    }],{
      plot_bgcolor: '#ffffff',
      paper_bgcolor: '#f8f8f8',
      title: {
        text: 'Windspeed',
        font: {
          color: '#ff0000',
        },
        yref: 'container',
        yanchor: 'top',
        y: 0.9625,
      },
      spikedistance: -1,
      height: 400,
      margin: {
        t: 45,
        b: 130,
        autoexpand: false,
      },
      xaxis: {
        type: 'date',
        fixedrange: false,
        mirror: true,
        linecolor: '#d0d0d0',
        autorange: true,
        gridcolor: '#e8e8e8',
        hoverformat: '%Y-%m-%d %H:%M:%S',
        ticklen: 5,
        tickcolor: '#d0d0d0',
        showspikes: true,
        spikethickness: 1,
        spikesnap: 'data',
        spikecolor: '#000000',
        spikedash: 'dot',
        rangeslider: {
          autorange: true,
          bordercolor: '#e0e0e0',
          borderwidth: 1,
          thickness: 0.2,
        },
        zeroline: true,
        zerolinecolor: '#b0b0b0',
      },
      yaxis: {
        type: 'linear',
        fixedrange: true,
        automargin: true,
        mirror: true,
        linecolor: '#d0d0d0',
        autorange: true,
        ticklen: 4,
        tickcolor: '#d0d0d0',
        gridcolor: '#e8e8e8',
        showspikes: true,
        side: 'left',
        spikethickness: 1,
        spikesnap: 'data',
        spikecolor: '#000000',
        spikedash: 'dot',
        title: {
          text: 'm/s',
          font: {
            color: '#ff0000',
          },
        },
        zeroline: true,
        zerolinecolor: '#d0d0d0',
      },
    },{
      displayModeBar: false,
      doubleClickDelay: 1000,
      responsive: true,
    });
    $('#plot').attr('originalHeight',400);
    $('#plot').attr('originalBottomMargin',130);
  });
</script>

=end html

=cut

# -----------------------------------------------------------------------------

package Quiq::PlotlyJs::TimeSeries;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Json::Code;
use Quiq::Template;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $plt = $class->new(@attVal);

=head4 Attributes

=over 4

=item class => $class (Default: 'plotly-timeseries')

CSS-Klasse des div-Containers. Kann zur Definition eines Rahmens,
von Außenabständen usw. genutzt werden.

=item color => $color (Default: '#ff0000')

Farbe der Kurve und Titel (Haupttitel, Titel Y-Achse). Alle
Schreibweisen, die in CSS erlaubt sind, sind zulässig,
also NAME, #XXXXXX oder rgb(NNN,NNN,NNN). Dies gilt für alle Farben.

=item height => $n (Default: 400)

Höhe des (gesamten) Diagramms in Pixeln.

=item name => $name (Default: 'plot')

Name des Plot. Der Name wird als CSS-Id für den Div-Container
und als Variablenname für die JavaScript-Instanz verwendet.

=item title => $str

Titel des Plot. Wird über das Diagramm gesetzt. Typischerweise
der Name des gemessenen Parameters.

=item x => \@x (Default: [])

Referenz auf Array der Zeit-Werte (bevorzugt in JavaScript-Epoch).

=item y => \@y (Default: [])

Referenz auf Array der Y-Werte (in Weltkoordinaten).

=item yTitle => $str

Beschriftung an der Y-Achse. Typischerweise die Einheit des
gemessenen Parameters.

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
        class => 'plotly-timeseries',
        color => '#ff0000',
        height => 400,
        name => 'plot',
        title => undef,
        x => [],
        xMin => undef,
        xMax => undef,
        y => [],
        yMin => undef,
        yMax => undef,
        yTitle => undef,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Klassenmethoden

=head3 cdnUrl() - Liefere CDN URL

=head4 Synopsis

  $url = $this->cdnUrl;

=head4 Returns

URL (String)

=head4 Description

Liefere den CDN URL der neusten Version von Plotly.js.

=head4 Example

  $url = Quiq::PlotlyJs::TimeSeries->cdnUrl;
  ==>
  https://cdn.plot.ly/plotly-latest.min.js

=cut

# -----------------------------------------------------------------------------

sub cdnUrl {
    my $this = shift;
    return 'https://cdn.plot.ly/plotly-latest.min.js';
    #return 'https://cdn.plot.ly/plotly-1.30.0.min.js';
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML

=head4 Synopsis

  $html = $ch->html($h);

=head4 Returns

HTML-Code (String)

=head4 Description

Liefere den HTML-Code der Plot-Instanz.

=cut

# -----------------------------------------------------------------------------

sub html {
    my ($self,$h) = @_;

    # Objektattribute
    my ($class,$height,$name) = $self->get(qw/class height name/);

    # MEMO: Wir setzen die Höhe im div und nicht im Layout, damit
    # das div bereits den Raum einnimmt, welcher später durch
    # Plotly befüllt wird

    return $h->tag('div',
        id => $name,
        class => $class,
        style => [
            height => "${height}px",
            border => '1px dotted #b0b0b0',
        ],
    );
}

# -----------------------------------------------------------------------------

=head3 js() - Generiere JavaScript

=head4 Synopsis

  $js = $ch->js;

=head4 Returns

JavaScript-Code (String)

=head4 Description

Liefere den JavaScript-Code für die Erzeugung Plot-Instanz.

=cut

# -----------------------------------------------------------------------------

sub js {
    my $self = shift;

    # Zusatz-Attribute (die Plotly nicht kennt)

    my $name = $self->get('name');

    # Multi-Attribute (betreffen mehrere Plotly-Attribute)

    my $color = $self->get('color');
    # ---
    my $axisBox = 1; # Zeichne eine Box um den Plotbereich. Die Box hat
        # die Farbe der Achsen (siehe axisColor).

    # Einzel-Attribute (betreffen einzelnes Plotly-Attribut)

    my $height = $self->get('height'); # Höhe des gesamten Diagramms
    my $title = $self->get('title');
    my $xA = $self->get('x');
    my $yA = $self->get('y');
    my $yTitle = $self->get('yTitle');
    my $xMin = $self->get('xMin'); # Kleinster Wert auf der X-Achse.
        # Der Default 'undefined' bedeutet, dass der Wert aus den Daten
        # ermittelt wird.
    my $xMax = $self->get('xMax'); # Größter Wert auf der X-Achse.
        # Der Default 'undefined' bedeutet, dass der Wert aus den Daten
        # ermittelt wird.
    my $yMin = $self->get('yMin'); # Kleinster Wert auf der Y-Achse.
        # Der Default 'undefined' bedeutet, dass der Wert aus den Daten
        # ermittelt wird.
    my $yMax = $self->get('yMax'); # Größter Wert auf der Y-Achse.
        # Der Default 'undefined' bedeutet, dass der Wert aus den Daten
        # ermittelt wird.

    # Maße für die Ränder

    my $topMargin = 45;

    # 250->100,300->110,350->120,400->130,450->140,...
    my $bottomMargin = ($height-300)/50*10+110;

    # ---
    my $axisColor = '#d0d0d0'; # Farbe der Achsenlinien
    my $fillColor = '#e0e0e0'; # Farbe zwischen Kurve und X-Achse
    my $gridColor = '#e8e8e8'; # Farbe des Gitters
    my $lineColor = $color;
    my $lineShape = 'linear'; # Linienform: 'spline'|'linear'|'hv'|
        # 'vh'|'hvh'|'vhv'
    my $lineWidth = 1;
    my $margin = [$topMargin,undef,$bottomMargin,undef];
    my $markerColor = $color;
    my $markerSize = 3;
    my $markerSymbol = 'circle';
    my $mode = 'lines'; # Kurvendarstellung: 'lines', 'markers',
        # 'text', 'none'. Die ersteren drei können auch mit '+' verbunden
        # werden.
    my $paperBackground = '#f8f8f8'; # Hintergrund Diagrammbereich
    my $plotBackground = '#ffffff'; # Hintergrund Plotbereich
    my $rangeSliderBorderColor = '#e0e0e0';
    my $xAxisHoverFormat = '%Y-%m-%d %H:%M:%S'; # Format der
        # Spike-Beschriftung für die X-Koordinate. Siehe:
        # https://github.com/d3/d3-3.x-api-reference/blob/master/\
        # Time-Formatting.md#format
    my $xAxisTickFormat = '%Y-%m-%d %H:%M'; # Format der
        # Zeitachsen-Beschriftung
    my $xTickLen = 5;
    my $ySide = 'left'; # Seite, auf der die Y-Achse gezeichnet wird
    my $yTickLen = 4;
    my $zeroLineColor = '#d0d0d0';

    # Instantiiere Objekt zum Erzeugen von JSON-Code
    my $j = Quiq::Json::Code->new;

    # Traces

    push my @traces,$j->o(
        type => 'scatter',
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
            color => $markerColor, # [....] Einzelfarben
            symbol => $markerSymbol,
        ),
        x => $xA,
        y => $yA,
    );

    # Layout

    my $layout = $j->o(
        plot_bgcolor => $plotBackground,
        paper_bgcolor => $paperBackground,
        title => $j->o(
            text => $title,
            font => $j->o(
                color => $color,
            ),
            yref => 'container', # container, paper
            yanchor => 'top',
            y => 1-(15/$height),
        ),
        spikedistance => -1,
        height => $height,
        margin => $j->o(
            l => $margin->[3],
            r => $margin->[1],
            t => $margin->[0],
            b => $margin->[2],
            autoexpand => \'false',
        ),
        xaxis => $j->o(
            type => 'date',
            fixedrange => \'false', # Zoom erlauben
            mirror => $axisBox? \'true': undef,
            linecolor => $axisColor,
            defined($xMin) && defined($xMax)? (range => [$xMin,$xMax]):
                (autorange => \'true'),
            # autorange => \'true',
            gridcolor => $gridColor,
            hoverformat => $xAxisHoverFormat,
            # tickformat => $xAxisTickFormat,
            # tickangle => 30,
            ticklen => $xTickLen,
            tickcolor => $axisColor,
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
                thickness => 0.20,
            ),
            zeroline => \'true',
            zerolinecolor => '#b0b0b0',
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
                ),
            ),
            zeroline => \'true',
            zerolinecolor => $zeroLineColor,
        ),
    );

    # Config

    my $config = $j->o(
        displayModeBar => \'false',
        doubleClickDelay => 1000, # 1000ms
        responsive => \'true',
    );

    # Erzeuge JavaScript-Code

    return Quiq::Template->combine(
        placeholders => [
            __NAME__ => $name,
            __HEIGHT__ => $height,
            __BOTTOM_MARGIN__ => $bottomMargin,
            __TRACES__ => \@traces,
            __LAYOUT__ => $layout,
            __CONFIG__ => $config,
        ],
        template => q~
            var __NAME__ = Plotly.newPlot('__NAME__',[__TRACES__],__LAYOUT__,__CONFIG__);
            $('#__NAME__').attr('originalHeight',__HEIGHT__);
            $('#__NAME__').attr('originalBottomMargin',__BOTTOM_MARGIN__);
            // __NAME__.then(plot => {console.log(plot._fullLayout)});
        ~,
    );
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
