# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::ChartJs::TimeSeries - Erzeuge Zeitreihen-Plot auf Basis von Chart.js

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

=head3 Modul laden

  use Quiq::ChartJs::TimeSeries;

=head3 Objekt instantiieren

  my $ch = Quiq::ChartJs::TimeSeries->new(
      parameter => 'Windspeed',
      unit => 'm/s',
      points => \@rows,
      pointCallback => sub {
           my ($point,$i) = @_;
           my ($iso,$val) = split /\t/,$point,2;
           return [Quiq::Epoch->new($iso)->epoch*1000,$val];
      },
  );

=head3 HTML-Seite mit Diagramm generieren

  my $h = Quiq::Html::Producer->new;
  
  my $html = Quiq::Html::Page->html($h,
      title => 'Chart.js testpage',
      load => [
          js => $ch->cdnUrl('2.8.0'),
      ],
      body => $ch->html($h),
  );

=head3 Diagramm

(Folgendes Diagramm erscheint nur in HTML - außer auf
meta::cpan, da der HTML-Code dort gestrippt wird. Es zeigt 720 Messwerte
einer Windgeschwindigkeits-Messung)

=begin html

<script src="https://code.jquery.com/jquery-3.4.1.min.js" type="text/javascript"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.8.0/Chart.bundle.min.js" type="text/javascript"></script>
<div style="height: 350px">
  <canvas id="plot"></canvas>
</div>
<script type="text/javascript">
  $(function() {
    Chart.defaults.global.defaultFontSize = 12;
    Chart.defaults.global.animation.duration = 1000;
    var plot = new Chart('plot',{
      type: 'line',
      data: {
        datasets: [{
          type: 'line',
          label: 'Windspeed',
          fill: true,
          borderColor: 'rgb(255,0,0,1)',
          borderWidth: 1,
          pointRadius: 0,
          data: [{t:1573167600000,y:11.142},{t:1573168200000,y:11.524},{t:1573168800000,y:10.343},{t:1573169400000,y:10.604},{t:1573170000000,y:11.824},{t:1573170600000,y:11.266},{t:1573171200000,y:10.642},{t:1573171800000,y:10.093},{t:1573172400000,y:9.1365},{t:1573173000000,y:8.6981},{t:1573173600000,y:8.5784},{t:1573174200000,y:8.83},{t:1573174800000,y:8.9365},{t:1573175400000,y:8.6053},{t:1573176000000,y:8.0124},{t:1573176600000,y:9.2907},{t:1573177200000,y:8.8921},{t:1573177800000,y:8.4226},{t:1573178400000,y:8.361},{t:1573179000000,y:8.3603},{t:1573179600000,y:9.092},{t:1573180200000,y:8.8321},{t:1573180800000,y:9.0572},{t:1573181400000,y:8.076},{t:1573182000000,y:8.0475},{t:1573182600000,y:8.5653},{t:1573183200000,y:8.5676},{t:1573183800000,y:7.909},{t:1573184400000,y:8.3279},{t:1573185000000,y:8.9462},{t:1573185600000,y:8.2227},{t:1573186200000,y:7.4135},{t:1573186800000,y:7.1417},{t:1573187400000,y:6.1413},{t:1573188000000,y:6.1684},{t:1573188600000,y:6.2048},{t:1573189200000,y:6.0224},{t:1573189800000,y:5.8958},{t:1573190400000,y:6.21},{t:1573191000000,y:6.0992},{t:1573191600000,y:6.102},{t:1573192200000,y:5.7212},{t:1573192800000,y:5.757},{t:1573193400000,y:5.6007},{t:1573194000000,y:5.2626},{t:1573194600000,y:6.162},{t:1573195200000,y:6.5931},{t:1573195800000,y:7.0725},{t:1573196400000,y:7.9139},{t:1573197000000,y:7.9366},{t:1573197600000,y:7.7247},{t:1573198200000,y:8.1006},{t:1573198800000,y:8.5755},{t:1573199400000,y:8.3681},{t:1573200000000,y:8.9414},{t:1573200600000,y:8.9655},{t:1573201200000,y:8.6273},{t:1573201800000,y:8.8311},{t:1573202400000,y:8.5993},{t:1573203000000,y:8.4938},{t:1573203600000,y:9.0882},{t:1573204200000,y:8.9791},{t:1573204800000,y:9.151},{t:1573205400000,y:8.9804},{t:1573206000000,y:9.9322},{t:1573206600000,y:10.229},{t:1573207200000,y:10.446},{t:1573207800000,y:9.6706},{t:1573208400000,y:9.3077},{t:1573209000000,y:9.2482},{t:1573209600000,y:9.4737},{t:1573210200000,y:9.4784},{t:1573210800000,y:9.4391},{t:1573211400000,y:10.082},{t:1573212000000,y:9.593},{t:1573212600000,y:10.762},{t:1573213200000,y:12.304},{t:1573213800000,y:12.765},{t:1573214400000,y:12.355},{t:1573215000000,y:12.684},{t:1573215600000,y:12.551},{t:1573216200000,y:13.121},{t:1573216800000,y:12.812},{t:1573217400000,y:12.482},{t:1573218000000,y:11.992},{t:1573218600000,y:12.023},{t:1573219200000,y:11.725},{t:1573219800000,y:11.585},{t:1573220400000,y:10.989},{t:1573221000000,y:11.135},{t:1573221600000,y:10.723},{t:1573222200000,y:11.035},{t:1573222800000,y:10.564},{t:1573223400000,y:11.13},{t:1573224000000,y:11.677},{t:1573224600000,y:12.908},{t:1573225200000,y:12.973},{t:1573225800000,y:12.511},{t:1573226400000,y:11.842},{t:1573227000000,y:11.4},{t:1573227600000,y:11.058},{t:1573228200000,y:11.949},{t:1573228800000,y:12.081},{t:1573229400000,y:12.505},{t:1573230000000,y:13.937},{t:1573230600000,y:12.72},{t:1573231200000,y:13.891},{t:1573231800000,y:11.878},{t:1573232400000,y:9.9409},{t:1573233000000,y:8.8398},{t:1573233600000,y:8.2837},{t:1573234200000,y:7.7194},{t:1573234800000,y:8.6815},{t:1573235400000,y:9.6036},{t:1573236000000,y:11.517},{t:1573236600000,y:14.246},{t:1573237200000,y:14.132},{t:1573237800000,y:15.098},{t:1573238400000,y:13.865},{t:1573239000000,y:14.74},{t:1573239600000,y:12.647},{t:1573240200000,y:12.552},{t:1573240800000,y:15.178},{t:1573241400000,y:14.983},{t:1573242000000,y:13.649},{t:1573242600000,y:13.731},{t:1573243200000,y:12.781},{t:1573243800000,y:15.184},{t:1573244400000,y:12.77},{t:1573245000000,y:13.275},{t:1573245600000,y:13.662},{t:1573246200000,y:16.822},{t:1573246800000,y:12.808},{t:1573247400000,y:12.394},{t:1573248000000,y:10.968},{t:1573248600000,y:12.761},{t:1573249200000,y:17.678},{t:1573249800000,y:11.119},{t:1573250400000,y:15.816},{t:1573251000000,y:15.469},{t:1573251600000,y:12.171},{t:1573252200000,y:13.475},{t:1573252800000,y:14.389},{t:1573253400000,y:12.486},{t:1573254000000,y:13.798},{t:1573254600000,y:15.288},{t:1573255200000,y:14.633},{t:1573255800000,y:13.796},{t:1573256400000,y:14.099},{t:1573257000000,y:16.695},{t:1573257600000,y:16.372},{t:1573258200000,y:13.929},{t:1573258800000,y:12.818},{t:1573259400000,y:14.77},{t:1573260000000,y:14.347},{t:1573260600000,y:11.71},{t:1573261200000,y:14.4},{t:1573261800000,y:14.35},{t:1573262400000,y:14.865},{t:1573263000000,y:13.146},{t:1573263600000,y:13.731},{t:1573264200000,y:13.54},{t:1573264800000,y:17.228},{t:1573265400000,y:13.228},{t:1573266000000,y:14.566},{t:1573266600000,y:16.707},{t:1573267200000,y:13.462},{t:1573267800000,y:12.916},{t:1573268400000,y:16.215},{t:1573269000000,y:15.192},{t:1573269600000,y:14.956},{t:1573270200000,y:17.472},{t:1573270800000,y:17.036},{t:1573271400000,y:17.063},{t:1573272000000,y:17.796},{t:1573272600000,y:18.718},{t:1573273200000,y:17.825},{t:1573273800000,y:17.535},{t:1573274400000,y:17.69},{t:1573275000000,y:15.962},{t:1573275600000,y:16.488},{t:1573276200000,y:17.399},{t:1573276800000,y:18.279},{t:1573277400000,y:18.915},{t:1573278000000,y:17.873},{t:1573278600000,y:16.229},{t:1573279200000,y:16.082},{t:1573279800000,y:19.299},{t:1573280400000,y:19.502},{t:1573281000000,y:19.92},{t:1573281600000,y:19.444},{t:1573282200000,y:17.233},{t:1573282800000,y:19.616},{t:1573283400000,y:19.508},{t:1573284000000,y:17.576},{t:1573284600000,y:18.238},{t:1573285200000,y:18.105},{t:1573285800000,y:18.993},{t:1573286400000,y:18.873},{t:1573287000000,y:17.888},{t:1573287600000,y:18.362},{t:1573288200000,y:19.393},{t:1573288800000,y:17.357},{t:1573289400000,y:17.944},{t:1573290000000,y:18.254},{t:1573290600000,y:19.015},{t:1573291200000,y:19.95},{t:1573291800000,y:18.13},{t:1573292400000,y:18.068},{t:1573293000000,y:21.423},{t:1573293600000,y:17.46},{t:1573294200000,y:18.824},{t:1573294800000,y:19.862},{t:1573295400000,y:18.221},{t:1573296000000,y:17.964},{t:1573296600000,y:18.402},{t:1573297200000,y:18.338},{t:1573297800000,y:17.944},{t:1573298400000,y:16.168},{t:1573299000000,y:19.031},{t:1573299600000,y:20.231},{t:1573300200000,y:17.822},{t:1573300800000,y:18.44},{t:1573301400000,y:20.05},{t:1573302000000,y:19.13},{t:1573302600000,y:17.994},{t:1573303200000,y:16.714},{t:1573303800000,y:18.015},{t:1573304400000,y:18.616},{t:1573305000000,y:18.65},{t:1573305600000,y:18.101},{t:1573306200000,y:19.864},{t:1573306800000,y:18.401},{t:1573307400000,y:18.731},{t:1573308000000,y:17.925},{t:1573308600000,y:18.968},{t:1573309200000,y:18.625},{t:1573309800000,y:18.227},{t:1573310400000,y:20.501},{t:1573311000000,y:20.798},{t:1573311600000,y:15.676},{t:1573312200000,y:16.109},{t:1573312800000,y:17.362},{t:1573313400000,y:19.106},{t:1573314000000,y:17.976},{t:1573314600000,y:14.419},{t:1573315200000,y:14.536},{t:1573315800000,y:18.113},{t:1573316400000,y:16.115},{t:1573317000000,y:17.646},{t:1573317600000,y:18.004},{t:1573318200000,y:18.452},{t:1573318800000,y:19.881},{t:1573319400000,y:16.999},{t:1573320000000,y:17.11},{t:1573320600000,y:20.107},{t:1573321200000,y:16.814},{t:1573321800000,y:17.585},{t:1573322400000,y:17.425},{t:1573323000000,y:17.067},{t:1573323600000,y:16.98},{t:1573324200000,y:15.499},{t:1573324800000,y:16.694},{t:1573325400000,y:17.567},{t:1573326000000,y:15.407},{t:1573326600000,y:16.808},{t:1573327200000,y:16.86},{t:1573327800000,y:16.744},{t:1573328400000,y:15.839},{t:1573329000000,y:16.125},{t:1573329600000,y:15.56},{t:1573330200000,y:17.977},{t:1573330800000,y:17.873},{t:1573331400000,y:16.315},{t:1573332000000,y:14.065},{t:1573332600000,y:15.391},{t:1573333200000,y:15.549},{t:1573333800000,y:15.902},{t:1573334400000,y:15.84},{t:1573335000000,y:14.739},{t:1573335600000,y:14.045},{t:1573336200000,y:14.311},{t:1573336800000,y:14.263},{t:1573337400000,y:13.989},{t:1573338000000,y:13.39},{t:1573338600000,y:12.862},{t:1573339200000,y:12.374},{t:1573339800000,y:13.646},{t:1573340400000,y:13.27},{t:1573341000000,y:12.996},{t:1573341600000,y:11.484},{t:1573342200000,y:11.654},{t:1573342800000,y:12.04},{t:1573343400000,y:11.471},{t:1573344000000,y:9.4777},{t:1573344600000,y:12.092},{t:1573345200000,y:12.036},{t:1573345800000,y:12.325},{t:1573346400000,y:11.26},{t:1573347000000,y:11.003},{t:1573347600000,y:11.056},{t:1573348200000,y:12.653},{t:1573348800000,y:11.933},{t:1573349400000,y:13.471},{t:1573350000000,y:12.743},{t:1573350600000,y:13.574},{t:1573351200000,y:12.158},{t:1573351800000,y:11.509},{t:1573352400000,y:12.311},{t:1573353000000,y:12.17},{t:1573353600000,y:10.343},{t:1573354200000,y:11.65},{t:1573354800000,y:13.315},{t:1573355400000,y:11.003},{t:1573356000000,y:11.416},{t:1573356600000,y:12.245},{t:1573357200000,y:12.275},{t:1573357800000,y:13.134},{t:1573358400000,y:12.73},{t:1573359000000,y:13.051},{t:1573359600000,y:13.945},{t:1573360200000,y:11.899},{t:1573360800000,y:12.51},{t:1573361400000,y:12.716},{t:1573362000000,y:10.324},{t:1573362600000,y:10.266},{t:1573363200000,y:10.547},{t:1573363800000,y:9.6788},{t:1573364400000,y:11.616},{t:1573365000000,y:10.614},{t:1573365600000,y:9.5814},{t:1573366200000,y:9.2896},{t:1573366800000,y:8.8913},{t:1573367400000,y:9.8219},{t:1573368000000,y:10.57},{t:1573368600000,y:9.1744},{t:1573369200000,y:11.363},{t:1573369800000,y:12.469},{t:1573370400000,y:11.539},{t:1573371000000,y:12.978},{t:1573371600000,y:10.694},{t:1573372200000,y:10.633},{t:1573372800000,y:11.753},{t:1573373400000,y:10.084},{t:1573374000000,y:12.639},{t:1573374600000,y:13.16},{t:1573375200000,y:11.916},{t:1573375800000,y:11.474},{t:1573376400000,y:11.495},{t:1573377000000,y:12.465},{t:1573377600000,y:12.596},{t:1573378200000,y:12.72},{t:1573378800000,y:9.3058},{t:1573379400000,y:10.476},{t:1573380000000,y:14.968},{t:1573380600000,y:15.779},{t:1573381200000,y:12.325},{t:1573381800000,y:10.371},{t:1573382400000,y:9.4045},{t:1573383000000,y:13.507},{t:1573383600000,y:14.068},{t:1573384200000,y:10.316},{t:1573384800000,y:8.244},{t:1573385400000,y:10.688},{t:1573386000000,y:14.432},{t:1573386600000,y:12.589},{t:1573387200000,y:8.4581},{t:1573387800000,y:7.2494},{t:1573388400000,y:12.972},{t:1573389000000,y:9.4151},{t:1573389600000,y:10.434},{t:1573390200000,y:10.813},{t:1573390800000,y:10.198},{t:1573391400000,y:8.5745},{t:1573392000000,y:9.2283},{t:1573392600000,y:11.764},{t:1573393200000,y:12.336},{t:1573393800000,y:11.829},{t:1573394400000,y:10.962},{t:1573395000000,y:11.088},{t:1573395600000,y:11.763},{t:1573396200000,y:14.134},{t:1573396800000,y:8.094},{t:1573397400000,y:7.6789},{t:1573398000000,y:8.6084},{t:1573398600000,y:9.0337},{t:1573399200000,y:9.9814},{t:1573399800000,y:9.9403},{t:1573400400000,y:9.6462},{t:1573401000000,y:10.67},{t:1573401600000,y:6.4388},{t:1573402200000,y:3.6575},{t:1573402800000,y:2.921},{t:1573404000000,y:9.8455},{t:1573404600000,y:10.405},{t:1573405200000,y:7.5777},{t:1573405800000,y:6.7923},{t:1573406400000,y:8.4932},{t:1573407000000,y:7.1617},{t:1573407600000,y:5.3501},{t:1573408200000,y:7.4563},{t:1573408800000,y:7.8523},{t:1573409400000,y:6.0806},{t:1573410000000,y:6.4744},{t:1573410600000,y:6.9166},{t:1573411200000,y:8.0283},{t:1573411800000,y:8.3801},{t:1573412400000,y:7.0883},{t:1573413000000,y:6.886},{t:1573413600000,y:7.1645},{t:1573414200000,y:6.4038},{t:1573414800000,y:10.769},{t:1573415400000,y:6.8063},{t:1573416000000,y:6.3469},{t:1573416600000,y:5.8389},{t:1573417200000,y:6.818},{t:1573417800000,y:7.9767},{t:1573418400000,y:9.4294},{t:1573419000000,y:7.7969},{t:1573419600000,y:6.8951},{t:1573420200000,y:6.3056},{t:1573420800000,y:5.4468},{t:1573421400000,y:4.9926},{t:1573422000000,y:4.7008},{t:1573422600000,y:5.1699},{t:1573423200000,y:5.5655},{t:1573423800000,y:5.2003},{t:1573424400000,y:4.3514},{t:1573425000000,y:4.0715},{t:1573425600000,y:4.0116},{t:1573426200000,y:4.9238},{t:1573426800000,y:5.2118},{t:1573427400000,y:5.5992},{t:1573428000000,y:5.3924},{t:1573428600000,y:5.325},{t:1573429200000,y:4.3683},{t:1573429800000,y:5.2034},{t:1573430400000,y:5.4291},{t:1573431000000,y:5.9364},{t:1573431600000,y:6.6686},{t:1573432200000,y:6.1789},{t:1573432800000,y:6.8653},{t:1573433400000,y:7.21},{t:1573434000000,y:7.7114},{t:1573434600000,y:9.1491},{t:1573435200000,y:7.4224},{t:1573435800000,y:6.8293},{t:1573436400000,y:9.8983},{t:1573437000000,y:13.272},{t:1573437600000,y:14.243},{t:1573438200000,y:16.132},{t:1573438800000,y:16.343},{t:1573439400000,y:17.22},{t:1573440000000,y:12.471},{t:1573440600000,y:8.2292},{t:1573441200000,y:5.1487},{t:1573441800000,y:3.236},{t:1573442400000,y:2.6038},{t:1573443000000,y:1.7618},{t:1573443600000,y:2.1459},{t:1573444200000,y:2.0727},{t:1573444800000,y:1.4333},{t:1573445400000,y:1.0696},{t:1573446000000,y:2.7428},{t:1573446600000,y:4.9414},{t:1573447200000,y:3.7368},{t:1573447800000,y:5.319},{t:1573448400000,y:7.2735},{t:1573449000000,y:9.6245},{t:1573449600000,y:9.9489},{t:1573450200000,y:8.7062},{t:1573450800000,y:7.7889},{t:1573451400000,y:8.3732},{t:1573452000000,y:7.5769},{t:1573452600000,y:8.6453},{t:1573453200000,y:8.5449},{t:1573453800000,y:7.7641},{t:1573454400000,y:7.8346},{t:1573455000000,y:7.3066},{t:1573455600000,y:6.763},{t:1573456200000,y:7.3616},{t:1573456800000,y:7.1119},{t:1573457400000,y:6.4413},{t:1573458000000,y:6.699},{t:1573458600000,y:6.5204},{t:1573459200000,y:6.2435},{t:1573459800000,y:6.632},{t:1573460400000,y:5.8984},{t:1573461000000,y:6.2509},{t:1573461600000,y:6.5763},{t:1573462200000,y:7.7363},{t:1573462800000,y:6.8599},{t:1573463400000,y:6.7808},{t:1573464000000,y:8.2888},{t:1573464600000,y:9.0233},{t:1573465200000,y:5.3644},{t:1573465800000,y:7.0148},{t:1573466400000,y:8.4653},{t:1573467000000,y:8.5078},{t:1573467600000,y:9.2944},{t:1573468200000,y:9.3122},{t:1573468800000,y:7.9084},{t:1573469400000,y:8.2096},{t:1573470000000,y:9.5056},{t:1573470600000,y:8.0469},{t:1573471200000,y:6.7035},{t:1573471800000,y:7.3514},{t:1573472400000,y:8.2602},{t:1573473000000,y:13.666},{t:1573473600000,y:12.81},{t:1573474200000,y:13.158},{t:1573474800000,y:11.648},{t:1573475400000,y:12.011},{t:1573476000000,y:12.867},{t:1573476600000,y:11.672},{t:1573477200000,y:9.1638},{t:1573477800000,y:8.7104},{t:1573478400000,y:12.806},{t:1573479000000,y:15.737},{t:1573479600000,y:15.89},{t:1573480200000,y:9.3137},{t:1573480800000,y:8.025},{t:1573481400000,y:8.5042},{t:1573482000000,y:9.5073},{t:1573482600000,y:9.5958},{t:1573483200000,y:11.346},{t:1573483800000,y:8.4166},{t:1573484400000,y:10.219},{t:1573485000000,y:11.514},{t:1573485600000,y:16.394},{t:1573486200000,y:15.26},{t:1573486800000,y:13.288},{t:1573487400000,y:13.135},{t:1573488000000,y:14.123},{t:1573488600000,y:13.037},{t:1573489200000,y:12.673},{t:1573489800000,y:12.968},{t:1573490400000,y:12.848},{t:1573491000000,y:14.419},{t:1573491600000,y:14.979},{t:1573492200000,y:15.234},{t:1573492800000,y:13.138},{t:1573493400000,y:9.6594},{t:1573494000000,y:8.2285},{t:1573494600000,y:7.1744},{t:1573495200000,y:7.3132},{t:1573495800000,y:11.892},{t:1573496400000,y:11.252},{t:1573497000000,y:11.26},{t:1573497600000,y:13.4},{t:1573498200000,y:13.312},{t:1573498800000,y:12.276},{t:1573499400000,y:12.161},{t:1573500000000,y:11.632},{t:1573500600000,y:11.975},{t:1573501200000,y:11.783},{t:1573501800000,y:11.861},{t:1573502400000,y:11.747},{t:1573503000000,y:11.193},{t:1573503600000,y:13.527},{t:1573504200000,y:14.698},{t:1573504800000,y:11.937},{t:1573505400000,y:15.2},{t:1573506000000,y:13.353},{t:1573506600000,y:10.386},{t:1573507200000,y:10.991},{t:1573507800000,y:10.444},{t:1573508400000,y:9.6877},{t:1573509000000,y:9.1259},{t:1573509600000,y:6.8962},{t:1573510200000,y:5.8379},{t:1573510800000,y:8.2692},{t:1573511400000,y:7.3411},{t:1573512000000,y:16.74},{t:1573512600000,y:16.519},{t:1573513200000,y:12.494},{t:1573513800000,y:11.721},{t:1573514400000,y:12.382},{t:1573515000000,y:13.003},{t:1573515600000,y:13.546},{t:1573516200000,y:13.636},{t:1573516800000,y:10.835},{t:1573517400000,y:15.534},{t:1573518000000,y:16.669},{t:1573518600000,y:14.253},{t:1573519200000,y:15.002},{t:1573519800000,y:14.85},{t:1573520400000,y:16.415},{t:1573521000000,y:15.733},{t:1573521600000,y:15.974},{t:1573522200000,y:14.421},{t:1573522800000,y:14.208},{t:1573523400000,y:14.385},{t:1573524000000,y:16.308},{t:1573524600000,y:16.622},{t:1573525200000,y:14.814},{t:1573525800000,y:13.628},{t:1573526400000,y:17.777},{t:1573527000000,y:15.583},{t:1573527600000,y:16.752},{t:1573528200000,y:17.047},{t:1573528800000,y:17.543},{t:1573529400000,y:17.943},{t:1573530000000,y:17.24},{t:1573530600000,y:17.781},{t:1573531200000,y:18.481},{t:1573531800000,y:17.531},{t:1573532400000,y:19.057},{t:1573533000000,y:19.985},{t:1573533600000,y:18.644},{t:1573534200000,y:18.364},{t:1573534800000,y:15.942},{t:1573535400000,y:16.249},{t:1573536000000,y:17.714},{t:1573536600000,y:18.363},{t:1573537200000,y:17.126},{t:1573537800000,y:17.548},{t:1573538400000,y:14.776},{t:1573539000000,y:16.845},{t:1573539600000,y:16.468},{t:1573540200000,y:15.058},{t:1573540800000,y:13.342},{t:1573541400000,y:13.838},{t:1573542000000,y:15.281},{t:1573542600000,y:14.377},{t:1573543200000,y:15.716},{t:1573543800000,y:15.602},{t:1573544400000,y:15.187},{t:1573545000000,y:14.808},{t:1573545600000,y:13.92},{t:1573546200000,y:13.606},{t:1573546800000,y:14.298},{t:1573547400000,y:15.136},{t:1573548000000,y:14.49},{t:1573548600000,y:13.24},{t:1573549200000,y:11.313},{t:1573549800000,y:9.1919},{t:1573550400000,y:8.7701},{t:1573551000000,y:8.9702},{t:1573551600000,y:8.8606},{t:1573552200000,y:7.8012},{t:1573552800000,y:7.9557},{t:1573553400000,y:7.4307},{t:1573554000000,y:11.543},{t:1573554600000,y:11.374},{t:1573555200000,y:11.287},{t:1573555800000,y:7.2281},{t:1573556400000,y:4.4993},{t:1573557000000,y:4.9059},{t:1573557600000,y:10.826},{t:1573558200000,y:12.45},{t:1573558800000,y:9.4174},{t:1573559400000,y:7.4316},{t:1573560000000,y:8.9589},{t:1573560600000,y:8.1305},{t:1573561200000,y:4.4854},{t:1573561800000,y:5.9888},{t:1573562400000,y:9.2665},{t:1573563000000,y:9.6626},{t:1573563600000,y:9.9196},{t:1573564200000,y:9.9101},{t:1573564800000,y:8.8638},{t:1573565400000,y:9.4765},{t:1573566000000,y:9.0699},{t:1573566600000,y:9.6093},{t:1573567200000,y:9.1072},{t:1573567800000,y:7.1331},{t:1573568400000,y:5.7111},{t:1573569000000,y:4.5949},{t:1573569600000,y:5.2524},{t:1573570200000,y:5.1016},{t:1573570800000,y:7.2966},{t:1573571400000,y:10.125},{t:1573572000000,y:10.476},{t:1573572600000,y:9.26},{t:1573573200000,y:6.9813},{t:1573573800000,y:7.2153},{t:1573574400000,y:7.5221},{t:1573575000000,y:5.3857},{t:1573575600000,y:7.3752},{t:1573576200000,y:7.1289},{t:1573576800000,y:7.5026},{t:1573577400000,y:5.7992},{t:1573578000000,y:5.2273},{t:1573578600000,y:5.0211},{t:1573579200000,y:5.1433},{t:1573579800000,y:5.8475},{t:1573580400000,y:6.3824},{t:1573581000000,y:4.7445},{t:1573581600000,y:4.695},{t:1573582200000,y:5.0794},{t:1573582800000,y:4.103},{t:1573583400000,y:4.5129},{t:1573584000000,y:4.4942},{t:1573584600000,y:5.2719},{t:1573585200000,y:6.5797},{t:1573585800000,y:6.5465},{t:1573586400000,y:5.843},{t:1573587000000,y:5.1389},{t:1573587600000,y:5.8237},{t:1573588200000,y:5.1551},{t:1573588800000,y:4.3657},{t:1573589400000,y:5.0073},{t:1573590000000,y:7.0279},{t:1573590600000,y:7.5665},{t:1573591200000,y:7.2244},{t:1573591800000,y:7.0065},{t:1573592400000,y:5.1047},{t:1573593000000,y:4.7981},{t:1573593600000,y:5.6936},{t:1573594200000,y:6.5205},{t:1573594800000,y:6.8074},{t:1573595400000,y:9.2159},{t:1573596000000,y:9.7935},{t:1573596600000,y:9.3623},{t:1573597200000,y:9.6505},{t:1573597800000,y:10.112},{t:1573598400000,y:10.003},{t:1573599000000,y:10.03},{t:1573599600000,y:8.2422}],
        }],
      },
      options: {
        maintainAspectRatio: false,
        title: {
          display: true,
          text: 'Windspeed',
          fontSize: 16,
          fontStyle: 'normal',
        },
        tooltips: {
          intersect: false,
          displayColors: false,
          backgroundColor: 'rgb(0,0,0,0.6)',
          titleMarginBottom: 2,
          callbacks: {
            label: function(tooltipItem,data) {
              var i = tooltipItem.datasetIndex;
              var label = data.datasets[i].label || '';
              if (label)
                label += ': ';
              label += tooltipItem.value + ' m/s';
              return label;
            },
          },
        },
        legend: {
          display: false,
        },
        scales: {
          xAxes: [{
            type: 'time',
            ticks: {
              minRotation: 45,
              maxRotation: 45,
            },
            time: {
              minUnit: 'second',
              displayFormats: {
                year: 'YYYY',
                quarter: 'YYYY [Q]Q',
                month: 'YYYY-MM',
                week: 'YYYY-MM-DD',
                day: 'YYYY-MM-DD',
                hour: 'YYYY-MM-DD HH',
                minute: 'YYYY-MM-DD HH:mm',
                second: 'YYYY-MM-DD HH:mm:ss',
              },
              tooltipFormat: 'YYYY-MM-DD HH:mm:ss',
            },
          }],
          yAxes: [{
            ticks: {
              min: 0,
            },
            scaleLabel: {
              display: true,
              labelString: 'm/s',
            },
          }],
        },
      },
    });
  });
</script>

=end html

=head1 DESCRIPTION

Diese Klasse ist ein Perl-Wrapper für die Erzeugung für
Zeitreihen-Plots auf Basis von Chart.js. Chart.js ist
eine JavaScript-Bibliothek, die Diagramme auf einem
HTML5 <canvas> darstellt. Chart.js bietet viele Möglichkeiten der
Diagramm-Generierung. Die Einstellungen werden per Datenstruktur
an den Chart-Konstruktor übergeben. Die Perl-Klasse ist darauf
optimiert, einen speziellen Typ von Diagramm zu erzeugen: einen
Zeitreihen-Plot. In einem Zeitreihen-Plot werden die Werte eines
I<Parameters> einer bestimmten I<Einheit> (unit) gegen die
Zeit geplottet. Die X-Achse ist die Zeitachse und die Y-Achse
die Werteachse.

=head2 Diagramm-Eigenschaften und wie sie in Chart.js konfiguriert werden

=head3 Übergabe der Daten

Zeitreihendaten werden als Array von Punkten übergeben:

  data: {
      datasets: [{
          type: 'line',
          data: [__POINTS__],
      }],
  }

Jeder Punkt in __POINTS__ ist ein JS-Objekt mit der Struktur:

  {
      t: __JAVASCRIPT_EPOCH__,
      y: __VALUE__,
  }

Hierbei ist __JAVASCRIPT_EPOCH__ der Zeitpunkt in Unix Epoch
mal 1000 (also in Millisekunden-Auflösung).

=head3 Diagramm mit konstanter Höhe und variabler Breite

Das <canvas>-Element wird in ein Parent-Element eingebettet, welches
die Höhe __HEIGHT__ zugewiesen bekommt:

  <div style="height: __HEIGHT__px">
      <canvas id="__NAME__"></canvas>
  </div>

In den Chart-Optionen wird definiert:

  options: {
       maintainAspectRatio: false,
  }

Damit ist das Diagramm fest auf __HEIGHT__ Pixel Höhe eingestellt,
passt sich in der Breite aber dem zur Verfügung stehenden Raum an,
auch nach einem Resize.

=head3 Konfiguration der Zeitachse

Eine Zeitachse bedarf einiger Konfigurationsarbeit, da die Defaults
von Chart.js nicht besonders sinnvoll sind.

  options: {
      scales: {
          xAxes: [{
              type: 'time',
              ticks: {
                  minRotation: 30,
                  maxRotation: 60,
              },
              time: {
                  min: __T_MIN__,
                  max: __T_MAX__,
                  minUnit: 'second',
                  displayFormats: {
                      second: 'YYYY-MM-DD HH:mm:ss',
                      minute: 'YYYY-MM-DD HH:mm',
                      hour: 'YYYY-MM-DD HH',
                      day: 'YYYY-MM-DD',
                      week: 'YYYY-MM-DD',
                      month: 'YYYY-MM',
                      quarter: 'YYYY [Q]Q',
                      year: 'YYYY',
                  },
                  tooltipFormat: 'YYYY-MM-DD HH:mm:ss',
              },
          }],
      },
  }

=over 2

=item *

Die X-Achse wird zu einer Zeitachse, wenn C<type: 'time'>
gesetzt ist.

=item *

Eine Zeitachse wird speziell über die Unterstruktur C<time: ...>
konfiguriert.

=item *

Anders als bei numerischen Achsen werden Minimum und Maximum
dort und I<nicht> in der Unterstruktur C<ticks: ...> festgelegt.

=item *

Werden C<min:> und C<max:> nicht oder auf C<undefined> gesetzt,
werden die Grenzen aus den Daten ermittelt.

=item *

Die Skalierung ergibt sich aus dem zur Verfügung stehenden Raum.
Chart.js entscheidet sich für eine Auflösung aus den 9 Kategorien
C<millisecond> .. C<year>.

=item *

Die Tick-Beschriftung für die einzelnen Kategorien wird durch
die Substuktur C<displayFormats: ...> definiert. Diese sollte
komplett durchdefiniert werden, da Defaults von Chart.js nicht
besonders sinnvoll sind.

=item *

Wie die Zeit im Tooltip dargestellt wird, definiert C<tooltipFormat:>.

=item *

Bei längeren Tick-Beschriftungen kann Chart.js diese gekippt
darstellen. Da Zeitangaben länger sind, sollte die gekippte
Darstellung forciert werden. Die gekippte Darstellung wird forciert,
wenn C<minRotation:> I<und> C<maxRotation> definiert werden. Dann
unterbleibt eine gerade Beschriftung, denn ein Wechsel zwischen
gerader und gekippter Beschriftung wirkt uneinheitlich.

=back

=head3 Raum unter dem Graph einfärben

  data: {
      datasets: [{
          fill: true;
      }],
  }

=head3 Konfigurations-Datenstruktur insgesamt

Die Perl-Klasse übergibt folgende Datenstruktur an den Konstruktor
der JavaScript-Klasse Chart, wobei die Platzhalter __XXXX__
ersetzt werden, meist durch den Wert des betreffenden Klassen-Attributs
xxxx. Die Liste aller Attribute siehe Abschnitt L<Attributes|"Attributes">.

  type: 'line',
  data: {
      datasets: [{
          type: 'line',
          lineTension: __LINE_TENSION__,
          fill: true,
          borderColor: '__LINE_COLOR__',
          borderWidth: 1,
          pointRadius: __POINT_RADIUS__,
          data: [__POINTS__],
      }],
  },
  options: {
      maintainAspectRatio: false,
      title: {
          display: true,
          text: '__TITLE__',
          fontSize: 16,
          fontStyle: 'normal',
      },
      tooltips: {
          intersect: false,
          displayColors: false,
          backgroundColor: 'rgb(0,0,0,0.6)',
          titleMarginBottom: 2,
          callbacks: {
              label: function(tooltipItem,data) {
                  return '__PARAMETER__: ' + tooltipItem.value + ' __UNIT__';
              },
          },
      },
      legend: {
          display: false,
      },
      scales: {
          xAxes: [{
              type: 'time',
              ticks: {
                  minRotation: 30,
                  maxRotation: 60,
              },
              time: {
                  min: __T_MIN__,
                  max: __T_MAX__,
                  minUnit: 'second',
                  displayFormats: {
                      second: 'YYYY-MM-DD HH:mm:ss',
                      minute: 'YYYY-MM-DD HH:mm',
                      hour: 'YYYY-MM-DD HH',
                      day: 'YYYY-MM-DD',
                      week: 'YYYY-MM-DD',
                      month: 'YYYY-MM',
                      quarter: 'YYYY [Q]Q',
                      year: 'YYYY',
                  },
                  tooltipFormat: 'YYYY-MM-DD HH:mm:ss',
              },
          }],
          yAxes: [{
              ticks: {
                  min: __Y_MIN__,
                  max: __Y_MAX__,
              },
              scaleLabel: {
                  display: true,
                  labelString: '__UNIT__',
              },
          }],
      },
  }

=head1 SEE ALSO

=over 2

=item *

L<https://www.chartjs.org>

=item *

L<https://github.com/chartjs/Chart.js>

=item *

L<Everything you need to know to create great looking charts using Chart.js|http://www.shilling.co.uk/survey/Charts/docs/>

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::ChartJs::TimeSeries;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Json::Code;
use Quiq::Array;
use Quiq::Template;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $ch = $class->new(@attVal);

=head4 Attributes

=over 4

=item t => \@y (Default: [])

Referenz auf Array der Zeit-Werte (in JavaScript-Epoch).

=item y => \@y (Default: [])

Referenz auf Array der Y-Werte (Weltkoordinaten).

=item tMin => $jsEpoch (Default: 'undefined')

Kleinster Wert auf der Zeitachse. Der Default 'undefined' bedeutet,
dass der Wert aus den Daten ermittelt wird.

=item tMax => $jsEpoch (Default: 'undefined')

Größter Wert auf der Zeitachse. Der Default 'undefined' bedeutet,
dass der Wert aus den Daten ermittelt wird.

=item yMin => $val (Default: 'undefined')

Kleinster Wert auf der Y-Achse. Der Default 'undefined' bedeutet,
dass der Wert aus den Daten ermittelt wird.

=item yMax => $val (Default: 'undefined')

Größter Wert auf der Y-Achse. Der Default 'undefined' bedeutet,
dass der Wert aus den Daten ermittelt wird.

=item height => $height (Default: 300)

Die Höhe des Diagramms. Eine Breite wird nicht angegeben, diese passt
sich dem zur Verfügung stehenden Raum an.

=item lineColor => $color (Default: 'rgb(255,0,0,1)')

Die Linienfarbe.

=item lineTension => $n (Default: 'undefined')

"Bezier curve tension of the line." Wenn 0, werden die Punkte
gerade verbunden. Der Default 'undefined' bedeutet, dass der
von Chart.js voreingestellte Wert 0.4 verwendet wird.

=item name => $name (Default: 'plot')

Name des Plot. Der Name wird als CSS-Id für die Zeichenfläche
(Canvas) und als Variablenname für die Instanz verwendet.

=item parameter => $name

Der Name des dargestellten Parameters.

=item points => \@points (Default: [])

Liste der Datenpunkte oder - alternativ - der Elemente, aus denen
die Datenpunkte mittels der Methode pointCallback (s.u.) gewonnen
werden.  Ein Datenpunkt ist ein Array mit zwei numerischen Werten
[$x, $y], wobei $x ein JavaScript Epoch-Wert (Unix Epoch in
Millisekunden) ist und $y ein beliebiger Y-Wert.

=item pointCallback => $sub (Default: undef)

Referenz auf eine Subroutine, die fr jedes Element der Liste @points
einen Datenpunkt liefert, wie ihn die Klasse erwartet (s.o.). Ist kein
rowCallback definiert, werden die Elemente aus @points unverändert
verwendet.

=item pointRadius => $n (Default: 0)

Kennzeichne die Datenpunkte mit einem Kreis des Radius $n. 0 bedeutet,
dass die Datenpunkte nicht gekennzeichnet werden.

=item showAverage => $bool (Default: 0)

Zeige das arithmetische Mittel an.

=item showMedian => $bool (Default: 0)

Zeige den Median an.

=item title => $str (Default: I<Name des Parameters>)

Titel, der über das Diagramm geschrieben wird.

=item unit => $str

Einheit des Parameters. Mit der Einheit wird die Y-Achse beschriftet und
sie erscheint im Tooltip.

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
        height => 300,
        lineColor => 'rgb(255,0,0,1)',
        lineTension => undef,
        minRotation => 30,
        maxRotation => 60,
        name => 'plot',
        parameter => undef,
        pointRadius => 0,
        showAverage => 0,
        showMedian => 0,
        t => [],
        title => undef,
        tMin => undef,
        tMax => undef,
        unit => undef,
        y => [],
        yMin => undef,
        yMax => undef,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Klassenmethoden

=head3 cdnUrl() - Liefere CDN URL

=head4 Synopsis

  $url = $ch->cdnUrl($version);

=head4 Returns

URL (String)

=head4 Description

Liefere einen CDN URL für Chart.js in der Version $version.

=cut

# -----------------------------------------------------------------------------

sub cdnUrl {
    my ($this,$version) = @_;

    return "https://cdnjs.cloudflare.com/ajax/libs/Chart.js/$version".
        '/Chart.bundle.min.js';
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML

=head4 Synopsis

  $html = $ch->html($h);

=head4 Returns

HTML-Code (String)

=head4 Description

Liefere den HTML-Code der Chart-Instanz.

=cut

# -----------------------------------------------------------------------------

sub html {
    my ($self,$h) = @_;

    # Objektattribute
    my ($height,$name) = $self->get(qw/height name/);

    return $h->tag('div',
        style => "height: ${height}px",
        $h->tag('canvas',
             id => $name,
        ),
    );
}

# -----------------------------------------------------------------------------

=head3 js() - Generiere JavaScript

=head4 Synopsis

  $js = $ch->js;

=head4 Returns

JavaScript-Code (String)

=head4 Description

Liefere den JavaScript-Code der Chart-Instanz.

=cut

# -----------------------------------------------------------------------------

sub js {
    my $self = shift;

    # Objektattribute

    my ($height,$lineColor,$lineTension,$minRotation,$maxRotation,
        $name,$parameter,$pointRadius,$showAverage,$showMedian,$title,$tA,
        $tMin,$tMax,$unit,$yA,$yMin,$yMax) =
        $self->get(qw/height lineColor lineTension minRotation maxRotation
        name parameter pointRadius showAverage showMedian title t
        tMin tMax unit y yMin yMax/);

    # Defaultwerte

    $title //= $parameter;

    # Konfiguration erzeugen

    my $j = Quiq::Json::Code->new;

    my @dataSets = $j->o(
        type => 'line',
        label => $parameter,
        lineTension => $lineTension,
        fill => \'true',
        borderColor => $lineColor,
        borderWidth => 1,
        pointRadius => $pointRadius,
        data => [do {
            my $points = '';
            for (my $i = 0; $i < @$tA; $i++) {
                 if ($i) {
                     $points .= ',';
                 }
                 $points .= sprintf '{t:%s,y:%s}',$tA->[$i],$yA->[$i];
            }
            \$points;
        }],
    );

    if ($showAverage && @$tA) {
        # Arithmetisches Mittel

        my $average = Quiq::Array->meanValue($yA);
        push @dataSets,$j->o(
            type => 'line',
            label => 'Average',
            lineTension => 0,
            fill => \'true',
            borderColor => 'rgb(0,255,0,0.3)',
            borderWidth => 1,
            pointRadius => 0,
            data => [\"{t:$tA->[0],y:$average},{t:$tA->[-1],y:$average}"],
        );
    }

    if ($showMedian && @$tA) {
        # Median

        my $median = Quiq::Array->median($yA);
        push @dataSets,$j->o(
            type => 'line',
            label => 'Median',
            lineTension => 0,
            fill => \'true',
            borderColor => 'rgb(0,0,0,0.3)',
            borderWidth => 1,
            pointRadius => 0,
            data => [\"{t:$tA->[0],y:$median},{t:$tA->[-1],y:$median}"],
        );
    }

    my $config = $j->o(
        type => 'line',
        data => $j->o(
            datasets => \@dataSets,
        ),
        options => $j->o(
            maintainAspectRatio => \'false',
            title => $j->o(
                display => \'true',
                text => $title,
                fontSize => 16,
                fontStyle => 'normal',
            ),
            tooltips => $j->o(
                intersect => \'false',
                displayColors => \'false',
                backgroundColor => 'rgb(0,0,0,0.6)',
                titleMarginBottom => 2,
                callbacks => $j->o(
                    label => $j->c(qq~
                        function(tooltipItem,data) {
                            var i = tooltipItem.datasetIndex;
                            var label = data.datasets[i].label || '';
                            if (label)
                                label += ': ';
                            label += tooltipItem.value + ' $unit';
                            return label;
                        }
                    ~),
                ),
            ),
            legend => $j->o(
                display => \'false',
            ),
            scales => $j->o(
                xAxes => [$j->o(
                    type => 'time',
                    ticks => $j->o(
                        minRotation => $minRotation,
                        maxRotation => $maxRotation,
                    ),
                    time => $j->o(
                        min => $tMin,
                        max => $tMax,
                        minUnit => 'second',
                        displayFormats => $j->o(
                            year => 'YYYY',
                            quarter => 'YYYY [Q]Q',
                            month => 'YYYY-MM',
                            week => 'YYYY-MM-DD',
                            day => 'YYYY-MM-DD',
                            hour => 'YYYY-MM-DD HH',
                            minute => 'YYYY-MM-DD HH:mm',
                            second => 'YYYY-MM-DD HH:mm:ss',
                        ),
                        tooltipFormat => 'YYYY-MM-DD HH:mm:ss',
                    ),
                )],
                yAxes => [$j->o(
                    ticks => $j->o(
                        min => $yMin,
                        max => $yMax,
                    ),
                    scaleLabel => $j->o(
                        display => \'true',
                        labelString => $unit,
                    ),
                )],
            ),
        ),
    );

    # Erzeuge JavaScript-Code

    return Quiq::Template->combine(
        placeholders => [
            __NAME__ => $name,
            __CONFIG__ => $config,
        ],
        template => q~
            Chart.defaults.global.defaultFontSize = 12;
            Chart.defaults.global.animation.duration = 1000;
            var __NAME__ = new Chart('__NAME__',__CONFIG__);
    ~);
}

# -----------------------------------------------------------------------------

=head1 IDEAS

=over 2

=item *

minRotation, maxRotation auf einen festen Wert einstellen, z.B. 45,
damit alle Diagramme gleich aussehen (?)

=item *

Höhe des Diagramms per JS setzen statt im HTML?

=item *

JS-Code in Ready-Handler setzen

=item *

L<Daten per Ajax laden|https://stackoverflow.com/questions/19894952/draw-a-chart-js-with-ajax-data-and-responsive-a-few-problems-and-questions>

=item *

Tick-Label der Zeitachse berechnen, so dass wiederholende Teile
ausgeblendet sind

=item *

Zoomen in die Daten. Wie? Plugin?

=back

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
