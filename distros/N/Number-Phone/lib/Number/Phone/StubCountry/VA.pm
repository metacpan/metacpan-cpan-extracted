# automatically generated file, don't edit



# Copyright 2023 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20230903131448;

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
$areanames{en} = {"390865", "Isernia",
"390824", "Benevento",
"39041", "Venice",
"390922", "Agrigento",
"390774", "Rome",
"390575", "Arezzo",
"390372", "Cremona",
"390445", "Vicenza",
"39090", "Messina",
"39099", "Taranto",
"390776", "Frosinone",
"390565", "Livorno",
"390362", "Cremona\/Monza",
"390965", "Reggio\ Calabria",
"390924", "Trapani",
"39059", "Modena",
"390961", "Catanzaro",
"39050", "Pisa",
"39015", "Biella",
"390321", "Novara",
"39080", "Bari",
"390577", "Siena",
"39089", "Salerno",
"390432", "Udine",
"390975", "Potenza",
"390522", "Reggio\ Emilia",
"390376", "Mantua",
"390963", "Vibo\ Valentia",
"390364", "Brescia",
"390583", "Lucca",
"390426", "Rovigo",
"390342", "Sondrio",
"390733", "Macerata",
"390789", "Sassari",
"390545", "Ravenna",
"39051", "Bologna",
"390881", "Foggia",
"3902", "Milan",
"390541", "Rimini",
"390471", "Bolzano\/Bozen",
"390125", "Turin",
"390731", "Ancona",
"390424", "Vicenza",
"39081", "Naples",
"390735", "Ascoli\ Piceno",
"390166", "Aosta\ Valley",
"39035", "Bergamo",
"390461", "Trento",
"390543", "Forlì\-Cesena",
"390382", "Pavia",
"390883", "Andria\ Barletta\ Trani",
"390585", "Massa\-Carrara",
"39040", "Trieste",
"39049", "Padova",
"390832", "Lecce",
"390737", "Macerata",
"390344", "Como",
"390934", "Caltanissetta\ and\ Enna",
"390346", "Bergamo",
"390422", "Treviso",
"39091", "Palermo",
"39075", "Perugia",
"390532", "Ferrara",
"39030", "Brescia",
"390185", "Genoa",
"390574", "Prato",
"390444", "Vicenza",
"39039", "Monza",
"390523", "Piacenza",
"390825", "Avellino",
"390962", "Crotone",
"39011", "Turin",
"390823", "Caserta",
"390141", "Asti",
"390322", "Novara",
"390874", "Campobasso",
"390183", "Imperia",
"390521", "Parma",
"390921", "Palermo",
"3906698", "Vatican\ City",
"39070", "Cagliari",
"39033", "Varese",
"39079", "Sassari",
"390925", "Agrigento",
"390862", "L\'Aquila",
"390371", "Lodi",
"390363", "Bergamo",
"390365", "Brescia",
"390324", "Verbano\-Cusio\-Ossola",
"39045", "Verona",
"390187", "La\ Spezia",
"390974", "Salerno",
"390373", "Cremona",
"3906", "Rome",
"390586", "Livorno",
"39071", "Ancona",
"390423", "Treviso",
"390165", "Aosta\ Valley",
"39048", "Gorizia",
"39095", "Catania",
"390161", "Vercelli",
"390884", "Foggia",
"390783", "Oristano",
"390549", "San\ Marino",
"390421", "Venice",
"390734", "Fermo",
"390942", "Catania",
"39013", "Alessandria",
"390425", "Rovigo",
"390171", "Cuneo",
"390341", "Lecco",
"390122", "Turin",
"39031", "Como",
"39085", "Pescara",
"390882", "Foggia",
"390732", "Ancona",
"390343", "Sondrio",
"39055", "Florence",
"39010", "Genoa",
"390933", "Caltanissetta",};
$areanames{it} = {"390882", "San\ Severo",
"390472", "Bressanone",
"390542", "Imola",
"390935", "Enna",
"390427", "Spilimbergo",
"390122", "Susa",
"390343", "Chiavenna",
"390732", "Fabriano",
"39010", "Genova",
"390385", "Stradella",
"390173", "Alba",
"390884", "Manfredonia",
"390474", "Brunico",
"390544", "Ravenna",
"390423", "Montebelluna",
"390165", "Aosta",
"390831", "Brindisi",
"390124", "Rivarolo\ Canavese",
"390781", "Iglesias",
"390942", "Taormina",
"390535", "Mirandola",
"390833", "Gallipoli",
"390421", "San\ Donà\ di\ Piave",
"390549", "Repubblica\ di\ San\ Marino",
"390572", "Montecatini\ Terme",
"390442", "Legnago",
"3906698", "Città\ del\ Vaticano",
"390921", "Cefalù",
"390966", "Palmi",
"390373", "Crema",
"390974", "Vallo\ della\ Lucania",
"390324", "Domodossola",
"390923", "Trapani",
"390365", "Salò",
"390864", "Sulmona",
"390763", "Orvieto",
"390438", "Conegliano",
"390185", "Rapallo",
"390775", "Frosinone",
"390566", "Follonica",
"390143", "Novi\ Ligure",
"390435", "Pieve\ di\ Cadore",
"390828", "Battipaglia",
"390377", "Codogno",
"390761", "Viterbo",
"390972", "Melfi",
"390322", "Arona",
"390386", "Ostiglia",
"390737", "Camerino",
"390344", "Menaggio",
"390985", "Scalea",
"390172", "Savigliano",
"390782", "Lanusei",
"390547", "Cesena",
"390941", "Patti",
"390588", "Volterra",
"390429", "Este",
"390471", "Bolzano",
"390536", "Sassuolo",
"3902", "Milano",
"390121", "Pinerolo",
"390789", "Olbia",
"390585", "Massa",
"390883", "Andria",
"390784", "Nuoro",
"390174", "Mondovì",
"390473", "Merano",
"390543", "Forlì",
"390166", "Saint\-Vincent",
"390424", "Bassano\ del\ Grappa",
"39081", "Napoli",
"390746", "Rieti",
"390465", "Tione\ di\ Trento",
"390731", "Jesi",
"390123", "Lanzo\ Torinese",
"390973", "Lagonegro",
"390374", "Soresina",
"390924", "Alcamo",
"390323", "Baveno",
"390965", "Reggio\ di\ Calabria",
"390971", "Potenza",
"390522", "Reggio\ nell\'Emilia",
"390142", "Casale\ Monferrato",
"390968", "Lamezia\ Terme",
"390861", "Teramo",
"390436", "Cortina\ d\'Ampezzo",
"390571", "Empoli",
"390863", "Avezzano",
"390565", "Piombino",
"390776", "Cassino",
"390524", "Fidenza",
"390875", "Termoli",
"390573", "Pistoia",
"390144", "Acqui\ Terme",
"390383", "Voghera",
"390984", "Cosenza",
"390345", "San\ Pellegrino\ Terme",
"390931", "Siracusa",
"390462", "Cavalese",
"390381", "Vigevano",
"39055", "Firenze",
"390933", "Caltagirone",
"39019", "Savona",
"390982", "Paola",
"390533", "Comacchio",
"390835", "Matera",
"390428", "Tarvisio",
"390736", "Ascoli\ Piceno",
"390464", "Rovereto",
"390546", "Faenza",
"390163", "Borgosesia",
"390332", "Varese",
"390743", "Spoleto",
"390584", "Viareggio",
"390175", "Saluzzo",
"390785", "Macomer",
"390964", "Locri",
"390363", "Treviglio",
"390925", "Sciacca",
"390976", "Muro\ Lucano",
"390437", "Belluno",
"390375", "Casalmaggiore",
"3906", "Roma",
"390872", "Lanciano",
"390722", "Urbino",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390771", "Formia",
"390433", "Tolmezzo",
"390773", "Latina",
"390525", "Fornovo\ di\ Taro",
"390765", "Poggio\ Mirteto",
"390564", "Grosseto",
"390431", "Cervignano\ del\ Friuli",
"39011", "Torino",
"390981", "Castrovillari",
"390742", "Foligno",
"390934", "Caltanissetta",
"390587", "Pontedera",
"390983", "Rossano",
"390384", "Mortara",
"390346", "Clusone",
"390331", "Busto\ Arsizio",
"390463", "Cles",
"390125", "Ivrea",
"390426", "Adria",
"390744", "Terni",
"390932", "Ragusa",
"390545", "Lugo",
"390885", "Cerignola",
"390534", "Porretta\ Terme",
"390735", "San\ Benedetto\ del\ Tronto",
"390836", "Maglie",
"390182", "Albenga",
"390364", "Breno",
"390376", "Mantova",
"390975", "Sala\ Consilina",
"390439", "Feltre",
"390766", "Civitavecchia",
"390873", "Vasto",
"390774", "Tivoli",
"390184", "Sanremo",
"390445", "Schio",
"39041", "Venezia",
"390871", "Chieti",
"390362", "Seregno",
"390967", "Soverato",
"390578", "Chianciano\ Terme",
"390434", "Pordenone",
"390721", "Pesaro",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ country_code => '39', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;