# automatically generated file, don't edit



# Copyright 2011 David Cantrell, derived from data from libphonenumber
# http://code.google.com/p/libphonenumber/
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
package Number::Phone::StubCountry::VA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200427120032;

my $formatters = [];

my $validators = {
                'fixed_line' => '06698\\d{1,6}',
                'geographic' => '06698\\d{1,6}',
                'mobile' => '
          3[1-9]\\d{8}|
          3[2-9]\\d{7}
        ',
                'pager' => '',
                'personal_number' => '
          1(?:
            78\\d|
            99
          )\\d{6}
        ',
                'specialrate' => '(
          84(?:
            [08]\\d{3}|
            [17]
          )\\d{3}
        )|(
          (?:
            0878\\d\\d|
            89(?:
              2|
              4[5-9]\\d
            )
          )\\d{3}|
          89[45][0-4]\\d\\d|
          (?:
            1(?:
              44|
              6[346]
            )|
            89(?:
              5[5-9]|
              9
            )
          )\\d{6}
        )',
                'toll_free' => '
          80(?:
            0\\d{3}|
            3
          )\\d{3}
        ',
                'voip' => '55\\d{8}'
              };
my %areanames = ();
$areanames{it}->{39010} = "Genova";
$areanames{it}->{39011} = "Torino";
$areanames{it}->{390121} = "Pinerolo";
$areanames{it}->{390122} = "Susa";
$areanames{it}->{390123} = "Lanzo\ Torinese";
$areanames{it}->{390124} = "Rivarolo\ Canavese";
$areanames{it}->{390125} = "Ivrea";
$areanames{it}->{39013} = "Alessandria";
$areanames{it}->{390141} = "Asti";
$areanames{it}->{390142} = "Casale\ Monferrato";
$areanames{it}->{390143} = "Novi\ Ligure";
$areanames{it}->{390144} = "Acqui\ Terme";
$areanames{it}->{39015} = "Biella";
$areanames{it}->{390161} = "Vercelli";
$areanames{it}->{390163} = "Borgosesia";
$areanames{it}->{390165} = "Aosta";
$areanames{it}->{390166} = "Saint\-Vincent";
$areanames{it}->{390171} = "Cuneo";
$areanames{it}->{390172} = "Savigliano";
$areanames{it}->{390173} = "Alba";
$areanames{it}->{390174} = "Mondovì";
$areanames{it}->{390175} = "Saluzzo";
$areanames{it}->{390182} = "Albenga";
$areanames{it}->{390183} = "Imperia";
$areanames{it}->{390184} = "Sanremo";
$areanames{it}->{390185} = "Rapallo";
$areanames{it}->{390187} = "La\ Spezia";
$areanames{it}->{39019} = "Savona";
$areanames{it}->{3902} = "Milano";
$areanames{it}->{39030} = "Brescia";
$areanames{it}->{39031} = "Como";
$areanames{it}->{390321} = "Novara";
$areanames{it}->{390322} = "Arona";
$areanames{it}->{390323} = "Baveno";
$areanames{it}->{390324} = "Domodossola";
$areanames{it}->{390331} = "Busto\ Arsizio";
$areanames{it}->{390332} = "Varese";
$areanames{it}->{390341} = "Lecco";
$areanames{it}->{390342} = "Sondrio";
$areanames{it}->{390343} = "Chiavenna";
$areanames{it}->{390344} = "Menaggio";
$areanames{it}->{390345} = "San\ Pellegrino\ Terme";
$areanames{it}->{390346} = "Clusone";
$areanames{it}->{39035} = "Bergamo";
$areanames{it}->{390362} = "Seregno";
$areanames{it}->{390363} = "Treviglio";
$areanames{it}->{390364} = "Breno";
$areanames{it}->{390365} = "Salò";
$areanames{it}->{390371} = "Lodi";
$areanames{it}->{390372} = "Cremona";
$areanames{it}->{390373} = "Crema";
$areanames{it}->{390374} = "Soresina";
$areanames{it}->{390375} = "Casalmaggiore";
$areanames{it}->{390376} = "Mantova";
$areanames{it}->{390377} = "Codogno";
$areanames{it}->{390381} = "Vigevano";
$areanames{it}->{390382} = "Pavia";
$areanames{it}->{390383} = "Voghera";
$areanames{it}->{390384} = "Mortara";
$areanames{it}->{390385} = "Stradella";
$areanames{it}->{390386} = "Ostiglia";
$areanames{it}->{39039} = "Monza";
$areanames{it}->{39040} = "Trieste";
$areanames{it}->{39041} = "Venezia";
$areanames{it}->{390421} = "San\ Donà\ di\ Piave";
$areanames{it}->{390422} = "Treviso";
$areanames{it}->{390423} = "Montebelluna";
$areanames{it}->{390424} = "Bassano\ del\ Grappa";
$areanames{it}->{390425} = "Rovigo";
$areanames{it}->{390426} = "Adria";
$areanames{it}->{390427} = "Spilimbergo";
$areanames{it}->{390428} = "Tarvisio";
$areanames{it}->{390429} = "Este";
$areanames{it}->{390431} = "Cervignano\ del\ Friuli";
$areanames{it}->{390432} = "Udine";
$areanames{it}->{390433} = "Tolmezzo";
$areanames{it}->{390434} = "Pordenone";
$areanames{it}->{390435} = "Pieve\ di\ Cadore";
$areanames{it}->{390436} = "Cortina\ d\'Ampezzo";
$areanames{it}->{390437} = "Belluno";
$areanames{it}->{390438} = "Conegliano";
$areanames{it}->{390439} = "Feltre";
$areanames{it}->{390442} = "Legnago";
$areanames{it}->{390444} = "Vicenza";
$areanames{it}->{390445} = "Schio";
$areanames{it}->{39045} = "Verona";
$areanames{it}->{390461} = "Trento";
$areanames{it}->{390462} = "Cavalese";
$areanames{it}->{390463} = "Cles";
$areanames{it}->{390464} = "Rovereto";
$areanames{it}->{390465} = "Tione\ di\ Trento";
$areanames{it}->{390471} = "Bolzano";
$areanames{it}->{390472} = "Bressanone";
$areanames{it}->{390473} = "Merano";
$areanames{it}->{390474} = "Brunico";
$areanames{it}->{39048} = "Gorizia";
$areanames{it}->{39049} = "Padova";
$areanames{it}->{39050} = "Pisa";
$areanames{it}->{39051} = "Bologna";
$areanames{it}->{390521} = "Parma";
$areanames{it}->{390522} = "Reggio\ nell\'Emilia";
$areanames{it}->{390523} = "Piacenza";
$areanames{it}->{390524} = "Fidenza";
$areanames{it}->{390525} = "Fornovo\ di\ Taro";
$areanames{it}->{390532} = "Ferrara";
$areanames{it}->{390533} = "Comacchio";
$areanames{it}->{390534} = "Porretta\ Terme";
$areanames{it}->{390535} = "Mirandola";
$areanames{it}->{390536} = "Sassuolo";
$areanames{it}->{390541} = "Rimini";
$areanames{it}->{390542} = "Imola";
$areanames{it}->{390543} = "Forlì";
$areanames{it}->{390544} = "Ravenna";
$areanames{it}->{390545} = "Lugo";
$areanames{it}->{390546} = "Faenza";
$areanames{it}->{390547} = "Cesena";
$areanames{it}->{390549} = "Repubblica\ di\ San\ Marino";
$areanames{it}->{39055} = "Firenze";
$areanames{it}->{390564} = "Grosseto";
$areanames{it}->{390565} = "Piombino";
$areanames{it}->{390566} = "Follonica";
$areanames{it}->{390571} = "Empoli";
$areanames{it}->{390572} = "Montecatini\ Terme";
$areanames{it}->{390573} = "Pistoia";
$areanames{it}->{390574} = "Prato";
$areanames{it}->{390575} = "Arezzo";
$areanames{it}->{390577} = "Siena";
$areanames{it}->{390578} = "Chianciano\ Terme";
$areanames{it}->{390583} = "Lucca";
$areanames{it}->{390584} = "Viareggio";
$areanames{it}->{390585} = "Massa";
$areanames{it}->{390586} = "Livorno";
$areanames{it}->{390587} = "Pontedera";
$areanames{it}->{390588} = "Volterra";
$areanames{it}->{39059} = "Modena";
$areanames{it}->{3906} = "Roma";
$areanames{it}->{3906698} = "Città\ del\ Vaticano";
$areanames{it}->{39070} = "Cagliari";
$areanames{it}->{39071} = "Ancona";
$areanames{it}->{390721} = "Pesaro";
$areanames{it}->{390722} = "Urbino";
$areanames{it}->{390731} = "Jesi";
$areanames{it}->{390732} = "Fabriano";
$areanames{it}->{390733} = "Macerata";
$areanames{it}->{390734} = "Fermo";
$areanames{it}->{390735} = "San\ Benedetto\ del\ Tronto";
$areanames{it}->{390736} = "Ascoli\ Piceno";
$areanames{it}->{390737} = "Camerino";
$areanames{it}->{390742} = "Foligno";
$areanames{it}->{390743} = "Spoleto";
$areanames{it}->{390744} = "Terni";
$areanames{it}->{390746} = "Rieti";
$areanames{it}->{39075} = "Perugia";
$areanames{it}->{390761} = "Viterbo";
$areanames{it}->{390763} = "Orvieto";
$areanames{it}->{390765} = "Poggio\ Mirteto";
$areanames{it}->{390766} = "Civitavecchia";
$areanames{it}->{390771} = "Formia";
$areanames{it}->{390773} = "Latina";
$areanames{it}->{390774} = "Tivoli";
$areanames{it}->{390775} = "Frosinone";
$areanames{it}->{390776} = "Cassino";
$areanames{it}->{390781} = "Iglesias";
$areanames{it}->{390782} = "Lanusei";
$areanames{it}->{390783} = "Oristano";
$areanames{it}->{390784} = "Nuoro";
$areanames{it}->{390785} = "Macomer";
$areanames{it}->{390789} = "Olbia";
$areanames{it}->{39079} = "Sassari";
$areanames{it}->{39080} = "Bari";
$areanames{it}->{39081} = "Napoli";
$areanames{it}->{390823} = "Caserta";
$areanames{it}->{390824} = "Benevento";
$areanames{it}->{390825} = "Avellino";
$areanames{it}->{390827} = "Sant\'Angelo\ dei\ Lombardi";
$areanames{it}->{390828} = "Battipaglia";
$areanames{it}->{390831} = "Brindisi";
$areanames{it}->{390832} = "Lecce";
$areanames{it}->{390833} = "Gallipoli";
$areanames{it}->{390835} = "Matera";
$areanames{it}->{390836} = "Maglie";
$areanames{it}->{39085} = "Pescara";
$areanames{it}->{390861} = "Teramo";
$areanames{it}->{390862} = "L\'Aquila";
$areanames{it}->{390863} = "Avezzano";
$areanames{it}->{390864} = "Sulmona";
$areanames{it}->{390865} = "Isernia";
$areanames{it}->{390871} = "Chieti";
$areanames{it}->{390872} = "Lanciano";
$areanames{it}->{390873} = "Vasto";
$areanames{it}->{390874} = "Campobasso";
$areanames{it}->{390875} = "Termoli";
$areanames{it}->{390881} = "Foggia";
$areanames{it}->{390882} = "San\ Severo";
$areanames{it}->{390883} = "Andria";
$areanames{it}->{390884} = "Manfredonia";
$areanames{it}->{390885} = "Cerignola";
$areanames{it}->{39089} = "Salerno";
$areanames{it}->{39090} = "Messina";
$areanames{it}->{39091} = "Palermo";
$areanames{it}->{390921} = "Cefalù";
$areanames{it}->{390922} = "Agrigento";
$areanames{it}->{390923} = "Trapani";
$areanames{it}->{390924} = "Alcamo";
$areanames{it}->{390925} = "Sciacca";
$areanames{it}->{390931} = "Siracusa";
$areanames{it}->{390932} = "Ragusa";
$areanames{it}->{390933} = "Caltagirone";
$areanames{it}->{390934} = "Caltanissetta";
$areanames{it}->{390935} = "Enna";
$areanames{it}->{390941} = "Patti";
$areanames{it}->{390942} = "Taormina";
$areanames{it}->{39095} = "Catania";
$areanames{it}->{390961} = "Catanzaro";
$areanames{it}->{390962} = "Crotone";
$areanames{it}->{390963} = "Vibo\ Valentia";
$areanames{it}->{390964} = "Locri";
$areanames{it}->{390965} = "Reggio\ di\ Calabria";
$areanames{it}->{390966} = "Palmi";
$areanames{it}->{390967} = "Soverato";
$areanames{it}->{390968} = "Lamezia\ Terme";
$areanames{it}->{390971} = "Potenza";
$areanames{it}->{390972} = "Melfi";
$areanames{it}->{390973} = "Lagonegro";
$areanames{it}->{390974} = "Vallo\ della\ Lucania";
$areanames{it}->{390975} = "Sala\ Consilina";
$areanames{it}->{390976} = "Muro\ Lucano";
$areanames{it}->{390981} = "Castrovillari";
$areanames{it}->{390982} = "Paola";
$areanames{it}->{390983} = "Rossano";
$areanames{it}->{390984} = "Cosenza";
$areanames{it}->{390985} = "Scalea";
$areanames{en}->{39010} = "Genoa";
$areanames{en}->{39011} = "Turin";
$areanames{en}->{390122} = "Turin";
$areanames{en}->{390125} = "Turin";
$areanames{en}->{39013} = "Alessandria";
$areanames{en}->{390141} = "Asti";
$areanames{en}->{39015} = "Biella";
$areanames{en}->{390161} = "Vercelli";
$areanames{en}->{390165} = "Aosta\ Valley";
$areanames{en}->{390166} = "Aosta\ Valley";
$areanames{en}->{390171} = "Cuneo";
$areanames{en}->{390183} = "Imperia";
$areanames{en}->{390185} = "Genoa";
$areanames{en}->{390187} = "La\ Spezia";
$areanames{en}->{3902} = "Milan";
$areanames{en}->{39030} = "Brescia";
$areanames{en}->{39031} = "Como";
$areanames{en}->{390321} = "Novara";
$areanames{en}->{390322} = "Novara";
$areanames{en}->{390324} = "Verbano\-Cusio\-Ossola";
$areanames{en}->{39033} = "Varese";
$areanames{en}->{390341} = "Lecco";
$areanames{en}->{390342} = "Sondrio";
$areanames{en}->{390343} = "Sondrio";
$areanames{en}->{390344} = "Como";
$areanames{en}->{390346} = "Bergamo";
$areanames{en}->{39035} = "Bergamo";
$areanames{en}->{390362} = "Cremona\/Monza";
$areanames{en}->{390363} = "Bergamo";
$areanames{en}->{390364} = "Brescia";
$areanames{en}->{390365} = "Brescia";
$areanames{en}->{390371} = "Lodi";
$areanames{en}->{390372} = "Cremona";
$areanames{en}->{390373} = "Cremona";
$areanames{en}->{390376} = "Mantua";
$areanames{en}->{390382} = "Pavia";
$areanames{en}->{39039} = "Monza";
$areanames{en}->{39040} = "Trieste";
$areanames{en}->{39041} = "Venice";
$areanames{en}->{390421} = "Venice";
$areanames{en}->{390422} = "Treviso";
$areanames{en}->{390423} = "Treviso";
$areanames{en}->{390424} = "Vicenza";
$areanames{en}->{390425} = "Rovigo";
$areanames{en}->{390426} = "Rovigo";
$areanames{en}->{390432} = "Udine";
$areanames{en}->{390444} = "Vicenza";
$areanames{en}->{390445} = "Vicenza";
$areanames{en}->{39045} = "Verona";
$areanames{en}->{390461} = "Trento";
$areanames{en}->{390471} = "Bolzano\/Bozen";
$areanames{en}->{39048} = "Gorizia";
$areanames{en}->{39049} = "Padova";
$areanames{en}->{39050} = "Pisa";
$areanames{en}->{39051} = "Bologna";
$areanames{en}->{390521} = "Parma";
$areanames{en}->{390522} = "Reggio\ Emilia";
$areanames{en}->{390523} = "Piacenza";
$areanames{en}->{390532} = "Ferrara";
$areanames{en}->{390541} = "Rimini";
$areanames{en}->{390543} = "Forlì\-Cesena";
$areanames{en}->{390545} = "Ravenna";
$areanames{en}->{390549} = "San\ Marino";
$areanames{en}->{39055} = "Florence";
$areanames{en}->{390565} = "Livorno";
$areanames{en}->{390574} = "Prato";
$areanames{en}->{390575} = "Arezzo";
$areanames{en}->{390577} = "Siena";
$areanames{en}->{390583} = "Lucca";
$areanames{en}->{390585} = "Massa\-Carrara";
$areanames{en}->{390586} = "Livorno";
$areanames{en}->{39059} = "Modena";
$areanames{en}->{3906} = "Rome";
$areanames{en}->{3906698} = "Vatican\ City";
$areanames{en}->{39070} = "Cagliari";
$areanames{en}->{39071} = "Ancona";
$areanames{en}->{390731} = "Ancona";
$areanames{en}->{390732} = "Ancona";
$areanames{en}->{390733} = "Macerata";
$areanames{en}->{390734} = "Fermo";
$areanames{en}->{390735} = "Ascoli\ Piceno";
$areanames{en}->{390737} = "Macerata";
$areanames{en}->{39075} = "Perugia";
$areanames{en}->{390774} = "Rome";
$areanames{en}->{390776} = "Frosinone";
$areanames{en}->{390783} = "Oristano";
$areanames{en}->{390789} = "Sassari";
$areanames{en}->{39079} = "Sassari";
$areanames{en}->{39080} = "Bari";
$areanames{en}->{39081} = "Naples";
$areanames{en}->{390823} = "Caserta";
$areanames{en}->{390824} = "Benevento";
$areanames{en}->{390825} = "Avellino";
$areanames{en}->{390832} = "Lecce";
$areanames{en}->{39085} = "Pescara";
$areanames{en}->{390862} = "L\'Aquila";
$areanames{en}->{390865} = "Isernia";
$areanames{en}->{390874} = "Campobasso";
$areanames{en}->{390881} = "Foggia";
$areanames{en}->{390882} = "Foggia";
$areanames{en}->{390883} = "Andria\ Barletta\ Trani";
$areanames{en}->{390884} = "Foggia";
$areanames{en}->{39089} = "Salerno";
$areanames{en}->{39090} = "Messina";
$areanames{en}->{39091} = "Palermo";
$areanames{en}->{390921} = "Palermo";
$areanames{en}->{390922} = "Agrigento";
$areanames{en}->{390924} = "Trapani";
$areanames{en}->{390925} = "Agrigento";
$areanames{en}->{390933} = "Caltanissetta";
$areanames{en}->{390934} = "Caltanissetta\ and\ Enna";
$areanames{en}->{390942} = "Catania";
$areanames{en}->{39095} = "Catania";
$areanames{en}->{390961} = "Catanzaro";
$areanames{en}->{390962} = "Crotone";
$areanames{en}->{390963} = "Vibo\ Valentia";
$areanames{en}->{390965} = "Reggio\ Calabria";
$areanames{en}->{390974} = "Salerno";
$areanames{en}->{390975} = "Potenza";
$areanames{en}->{39099} = "Taranto";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;