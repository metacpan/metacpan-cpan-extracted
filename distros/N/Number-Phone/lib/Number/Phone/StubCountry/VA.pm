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
our $VERSION = 1.20220601185320;

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
            0878\\d{3}|
            89(?:
              2\\d|
              3[04]|
              4(?:
                [0-4]|
                [5-9]\\d\\d
              )|
              5[0-4]
            )
          )\\d\\d|
          (?:
            1(?:
              44|
              6[346]
            )|
            89(?:
              38|
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
$areanames{it} = {"39010", "Genova",
"390346", "Clusone",
"390421", "San\ Donà\ di\ Piave",
"39055", "Firenze",
"39081", "Napoli",
"390462", "Cavalese",
"390322", "Arona",
"390964", "Locri",
"390883", "Andria",
"390185", "Rapallo",
"390345", "San\ Pellegrino\ Terme",
"39041", "Venezia",
"390785", "Macomer",
"390871", "Chieti",
"390566", "Follonica",
"390884", "Manfredonia",
"390565", "Piombino",
"390471", "Bolzano",
"390982", "Paola",
"390731", "Jesi",
"390385", "Stradella",
"390976", "Muro\ Lucano",
"390524", "Fidenza",
"390122", "Susa",
"390934", "Caltanissetta",
"390573", "Pistoia",
"390331", "Busto\ Arsizio",
"390386", "Ostiglia",
"390975", "Sala\ Consilina",
"390942", "Taormina",
"390746", "Rieti",
"390925", "Sciacca",
"390536", "Sassuolo",
"390535", "Mirandola",
"390722", "Urbino",
"390761", "Viterbo",
"390933", "Caltagirone",
"390172", "Savigliano",
"390445", "Schio",
"390744", "Terni",
"390973", "Lagonegro",
"390534", "Porretta\ Terme",
"390383", "Voghera",
"390861", "Teramo",
"390362", "Seregno",
"390924", "Alcamo",
"390143", "Novi\ Ligure",
"390967", "Soverato",
"390974", "Vallo\ della\ Lucania",
"390533", "Comacchio",
"390968", "Lamezia\ Terme",
"390935", "Enna",
"390872", "Lanciano",
"390743", "Spoleto",
"390525", "Fornovo\ di\ Taro",
"390981", "Castrovillari",
"390732", "Fabriano",
"390384", "Mortara",
"390472", "Bressanone",
"390144", "Acqui\ Terme",
"390923", "Trapani",
"390542", "Imola",
"390121", "Pinerolo",
"390578", "Chianciano\ Terme",
"390431", "Cervignano\ del\ Friuli",
"390885", "Cerignola",
"390771", "Formia",
"390343", "Chiavenna",
"390564", "Grosseto",
"390789", "Olbia",
"390831", "Brindisi",
"390332", "Varese",
"390784", "Nuoro",
"39011", "Torino",
"390184", "Sanremo",
"3906698", "Città\ del\ Vaticano",
"390344", "Menaggio",
"390941", "Patti",
"390965", "Reggio\ di\ Calabria",
"390966", "Palmi",
"390721", "Pesaro",
"390465", "Tione\ di\ Trento",
"390571", "Empoli",
"390438", "Conegliano",
"390437", "Belluno",
"390584", "Viareggio",
"390182", "Albenga",
"390163", "Borgosesia",
"390782", "Lanusei",
"390931", "Siracusa",
"390375", "Casalmaggiore",
"390763", "Orvieto",
"390985", "Scalea",
"390376", "Mantova",
"390435", "Pieve\ di\ Cadore",
"390125", "Ivrea",
"3906", "Roma",
"390549", "Repubblica\ di\ San\ Marino",
"390474", "Brunico",
"390363", "Treviglio",
"390775", "Frosinone",
"390836", "Maglie",
"390544", "Ravenna",
"390142", "Casale\ Monferrato",
"390423", "Montebelluna",
"390835", "Matera",
"390972", "Melfi",
"390776", "Cassino",
"390436", "Cortina\ d\'Ampezzo",
"390473", "Merano",
"390364", "Breno",
"390543", "Forlì",
"390377", "Codogno",
"390429", "Este",
"390175", "Saluzzo",
"390873", "Vasto",
"390742", "Foligno",
"390424", "Bassano\ del\ Grappa",
"390833", "Gallipoli",
"390442", "Legnago",
"390572", "Montecatini\ Terme",
"390174", "Mondovì",
"390433", "Tolmezzo",
"390123", "Lanzo\ Torinese",
"390426", "Adria",
"390773", "Latina",
"390365", "Salò",
"390587", "Pontedera",
"390781", "Iglesias",
"390875", "Termoli",
"390932", "Ragusa",
"390736", "Ascoli\ Piceno",
"390173", "Alba",
"390588", "Volterra",
"390546", "Faenza",
"390439", "Feltre",
"390545", "Lugo",
"390774", "Tivoli",
"390434", "Pordenone",
"390735", "San\ Benedetto\ del\ Tronto",
"390522", "Reggio\ nell\'Emilia",
"390124", "Rivarolo\ Canavese",
"390882", "San\ Severo",
"390165", "Aosta",
"390428", "Tarvisio",
"390381", "Vigevano",
"390863", "Avezzano",
"39019", "Savona",
"390984", "Cosenza",
"390427", "Spilimbergo",
"390323", "Baveno",
"390463", "Cles",
"390828", "Battipaglia",
"390374", "Soresina",
"390971", "Potenza",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390166", "Saint\-Vincent",
"390983", "Rossano",
"3902", "Milano",
"390324", "Domodossola",
"390766", "Civitavecchia",
"390585", "Massa",
"390921", "Cefalù",
"390864", "Sulmona",
"390737", "Camerino",
"390464", "Rovereto",
"390373", "Crema",
"390765", "Poggio\ Mirteto",
"390547", "Cesena",};
$areanames{en} = {"39039", "Monza",
"390924", "Trapani",
"390362", "Cremona\/Monza",
"390825", "Avellino",
"390426", "Rovigo",
"390321", "Novara",
"390341", "Lecco",
"390365", "Brescia",
"390445", "Vicenza",
"390425", "Rovigo",
"39031", "Como",
"390461", "Trento",
"390575", "Arezzo",
"390422", "Treviso",
"39013", "Alessandria",
"390774", "Rome",
"390732", "Ancona",
"390545", "Ravenna",
"390522", "Reggio\ Emilia",
"390735", "Ascoli\ Piceno",
"390974", "Salerno",
"390371", "Lodi",
"39035", "Bergamo",
"39080", "Bari",
"390789", "Sassari",
"39011", "Turin",
"39095", "Catania",
"390166", "Aosta\ Valley",
"390141", "Asti",
"390882", "Foggia",
"39040", "Trieste",
"390165", "Aosta\ Valley",
"390183", "Imperia",
"39075", "Perugia",
"390577", "Siena",
"390343", "Sondrio",
"390171", "Cuneo",
"39050", "Pisa",
"39091", "Palermo",
"39079", "Sassari",
"390783", "Oristano",
"390586", "Livorno",
"39015", "Biella",
"390737", "Macerata",
"390373", "Cremona",
"39071", "Ancona",
"3902", "Milan",
"3906698", "Vatican\ City",
"39099", "Taranto",
"390962", "Crotone",
"390324", "Verbano\-Cusio\-Ossola",
"390344", "Como",
"390921", "Palermo",
"39033", "Varese",
"390585", "Massa\-Carrara",
"39048", "Gorizia",
"390965", "Reggio\ Calabria",
"390322", "Novara",
"390865", "Isernia",
"390342", "Sondrio",
"390185", "Genoa",
"39089", "Salerno",
"390883", "Andria\ Barletta\ Trani",
"390862", "L\'Aquila",
"39041", "Venice",
"39010", "Genoa",
"390421", "Venice",
"39055", "Florence",
"390346", "Bergamo",
"39081", "Naples",
"39049", "Padova",
"390541", "Rimini",
"390521", "Parma",
"39045", "Verona",
"390884", "Foggia",
"390471", "Bolzano\/Bozen",
"390565", "Livorno",
"390376", "Mantua",
"390731", "Ancona",
"39070", "Cagliari",
"390583", "Lucca",
"39059", "Modena",
"390963", "Vibo\ Valentia",
"39085", "Pescara",
"390372", "Cremona",
"39051", "Bologna",
"39090", "Messina",
"390187", "La\ Spezia",
"390423", "Treviso",
"390776", "Frosinone",
"390934", "Caltanissetta\ and\ Enna",
"39030", "Brescia",
"390832", "Lecce",
"390874", "Campobasso",
"390975", "Potenza",
"390161", "Vercelli",
"390823", "Caserta",
"390734", "Fermo",
"390549", "San\ Marino",
"3906", "Rome",
"390125", "Turin",
"390432", "Udine",
"390382", "Pavia",
"390122", "Turin",
"390881", "Foggia",
"390363", "Bergamo",
"390444", "Vicenza",
"390424", "Vicenza",
"390574", "Prato",
"390532", "Ferrara",
"390933", "Caltanissetta",
"390543", "Forlì\-Cesena",
"390922", "Agrigento",
"390523", "Piacenza",
"390942", "Catania",
"390364", "Brescia",
"390961", "Catanzaro",
"390824", "Benevento",
"390733", "Macerata",
"390925", "Agrigento",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;