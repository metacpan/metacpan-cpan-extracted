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
our $VERSION = 1.20220305001844;

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
$areanames{it} = {"390433", "Tolmezzo",
"390343", "Chiavenna",
"390831", "Brindisi",
"390564", "Grosseto",
"390143", "Novi\ Ligure",
"390571", "Empoli",
"39011", "Torino",
"390524", "Fidenza",
"390423", "Montebelluna",
"390473", "Merano",
"390737", "Camerino",
"390785", "Macomer",
"390871", "Chieti",
"390547", "Cesena",
"390782", "Lanusei",
"390861", "Teramo",
"390744", "Terni",
"39019", "Savona",
"390463", "Cles",
"390864", "Sulmona",
"390534", "Porretta\ Terme",
"390972", "Melfi",
"390743", "Spoleto",
"390377", "Codogno",
"390464", "Rovereto",
"390863", "Avezzano",
"390533", "Comacchio",
"390975", "Sala\ Consilina",
"390925", "Sciacca",
"390474", "Brunico",
"390424", "Bassano\ del\ Grappa",
"390429", "Este",
"390965", "Reggio\ di\ Calabria",
"390471", "Bolzano",
"390421", "San\ Donà\ di\ Piave",
"390873", "Vasto",
"390932", "Ragusa",
"390144", "Acqui\ Terme",
"390385", "Stradella",
"390573", "Pistoia",
"390935", "Enna",
"390434", "Pordenone",
"390344", "Menaggio",
"390185", "Rapallo",
"390439", "Feltre",
"390431", "Cervignano\ del\ Friuli",
"390182", "Albenga",
"390833", "Gallipoli",
"390383", "Voghera",
"390572", "Montecatini\ Terme",
"390522", "Reggio\ nell\'Emilia",
"390525", "Fornovo\ di\ Taro",
"390933", "Caltagirone",
"390546", "Faenza",
"390588", "Volterra",
"390835", "Matera",
"390736", "Ascoli\ Piceno",
"390565", "Piombino",
"3906698", "Città\ del\ Vaticano",
"390535", "Mirandola",
"390742", "Foligno",
"390587", "Pontedera",
"390973", "Lagonegro",
"390923", "Trapani",
"390766", "Civitavecchia",
"390784", "Nuoro",
"390872", "Lanciano",
"390789", "Olbia",
"390781", "Iglesias",
"390875", "Termoli",
"390776", "Cassino",
"390472", "Bressanone",
"390964", "Locri",
"390921", "Cefalù",
"390971", "Potenza",
"390465", "Tione\ di\ Trento",
"390924", "Alcamo",
"390974", "Vallo\ della\ Lucania",
"390462", "Cavalese",
"390184", "Sanremo",
"390435", "Pieve\ di\ Cadore",
"390345", "San\ Pellegrino\ Terme",
"390384", "Mortara",
"390931", "Siracusa",
"390381", "Vigevano",
"390142", "Casale\ Monferrato",
"390934", "Caltanissetta",
"390166", "Saint\-Vincent",
"390376", "Mantova",
"390584", "Viareggio",
"3906", "Roma",
"390732", "Fabriano",
"390545", "Lugo",
"390836", "Maglie",
"390735", "San\ Benedetto\ del\ Tronto",
"390542", "Imola",
"390566", "Follonica",
"390746", "Rieti",
"390536", "Sassuolo",
"390765", "Poggio\ Mirteto",
"390722", "Urbino",
"390884", "Manfredonia",
"390775", "Frosinone",
"390426", "Adria",
"390883", "Andria",
"390941", "Patti",
"39010", "Genova",
"390442", "Legnago",
"390332", "Varese",
"390985", "Scalea",
"390982", "Paola",
"390968", "Lamezia\ Terme",
"390445", "Schio",
"390967", "Soverato",
"3902", "Milano",
"390172", "Savigliano",
"390122", "Susa",
"390362", "Seregno",
"390436", "Cortina\ d\'Ampezzo",
"390346", "Clusone",
"390365", "Salò",
"390175", "Saluzzo",
"390125", "Ivrea",
"390322", "Arona",
"39055", "Firenze",
"390165", "Aosta",
"390375", "Casalmaggiore",
"390731", "Jesi",
"390549", "Repubblica\ di\ San\ Marino",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390544", "Ravenna",
"390123", "Lanzo\ Torinese",
"390173", "Alba",
"390363", "Treviglio",
"390578", "Chianciano\ Terme",
"390585", "Massa",
"390323", "Baveno",
"390373", "Crema",
"390163", "Borgosesia",
"390721", "Pesaro",
"390771", "Formia",
"390885", "Cerignola",
"390774", "Tivoli",
"390882", "San\ Severo",
"39041", "Venezia",
"390983", "Rossano",
"390761", "Viterbo",
"390828", "Battipaglia",
"390331", "Busto\ Arsizio",
"390428", "Tarvisio",
"390984", "Cosenza",
"390981", "Castrovillari",
"390976", "Muro\ Lucano",
"390763", "Orvieto",
"39081", "Napoli",
"390773", "Latina",
"390966", "Palmi",
"390942", "Taormina",
"390437", "Belluno",
"390438", "Conegliano",
"390386", "Ostiglia",
"390374", "Soresina",
"390324", "Domodossola",
"390121", "Pinerolo",
"390543", "Forlì",
"390174", "Mondovì",
"390124", "Rivarolo\ Canavese",
"390427", "Spilimbergo",
"390364", "Breno",};
$areanames{en} = {"390426", "Rovigo",
"39085", "Pescara",
"390883", "Andria\ Barletta\ Trani",
"39030", "Brescia",
"390922", "Agrigento",
"390187", "La\ Spezia",
"390461", "Trento",
"390975", "Potenza",
"390925", "Agrigento",
"39071", "Ancona",
"390962", "Crotone",
"39010", "Genoa",
"390424", "Vicenza",
"390445", "Vicenza",
"390823", "Caserta",
"390965", "Reggio\ Calabria",
"390471", "Bolzano\/Bozen",
"390421", "Venice",
"390362", "Cremona\/Monza",
"39079", "Sassari",
"390346", "Bergamo",
"3902", "Milan",
"390122", "Turin",
"390523", "Piacenza",
"390125", "Turin",
"39013", "Alessandria",
"390382", "Pavia",
"390141", "Asti",
"390365", "Brescia",
"390185", "Genoa",
"39055", "Florence",
"390583", "Lucca",
"39090", "Messina",
"390344", "Como",
"390372", "Cremona",
"390322", "Novara",
"39033", "Varese",
"390341", "Lecco",
"390165", "Aosta\ Valley",
"39070", "Cagliari",
"390343", "Sondrio",
"39031", "Como",
"3906", "Rome",
"390521", "Parma",
"39099", "Taranto",
"390586", "Livorno",
"390545", "Ravenna",
"390732", "Ancona",
"390574", "Prato",
"390735", "Ascoli\ Piceno",
"39011", "Turin",
"39039", "Monza",
"390737", "Macerata",
"390423", "Treviso",
"390824", "Benevento",
"390874", "Campobasso",
"390884", "Foggia",
"390881", "Foggia",
"39045", "Verona",
"39091", "Palermo",
"390425", "Rovigo",
"390961", "Catanzaro",
"390783", "Oristano",
"39075", "Perugia",
"39081", "Naples",
"390444", "Vicenza",
"390422", "Treviso",
"39059", "Modena",
"390921", "Palermo",
"390942", "Catania",
"390974", "Salerno",
"390924", "Trapani",
"390161", "Vercelli",
"390371", "Lodi",
"390321", "Novara",
"39089", "Salerno",
"390342", "Sondrio",
"390324", "Verbano\-Cusio\-Ossola",
"390432", "Udine",
"390543", "Forlì\-Cesena",
"390171", "Cuneo",
"39051", "Bologna",
"390376", "Mantua",
"390364", "Brescia",
"39040", "Trieste",
"39048", "Gorizia",
"390733", "Macerata",
"390166", "Aosta\ Valley",
"390934", "Caltanissetta\ and\ Enna",
"39080", "Bari",
"390522", "Reggio\ Emilia",
"39035", "Bergamo",
"390549", "San\ Marino",
"390731", "Ancona",
"390541", "Rimini",
"390363", "Bergamo",
"390734", "Fermo",
"390575", "Arezzo",
"390933", "Caltanissetta",
"390832", "Lecce",
"39015", "Biella",
"390585", "Massa\-Carrara",
"390183", "Imperia",
"39049", "Padova",
"390565", "Livorno",
"390373", "Cremona",
"3906698", "Vatican\ City",
"390532", "Ferrara",
"390862", "L\'Aquila",
"390882", "Foggia",
"390865", "Isernia",
"390774", "Rome",
"39050", "Pisa",
"390789", "Sassari",
"390577", "Siena",
"39041", "Venice",
"39095", "Catania",
"390963", "Vibo\ Valentia",
"390776", "Frosinone",
"390825", "Avellino",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;