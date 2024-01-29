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
our $VERSION = 1.20231210185946;

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
$areanames{en} = {"390574", "Prato",
"39048", "Gorizia",
"390371", "Lodi",
"39011", "Turin",
"390882", "Foggia",
"39099", "Taranto",
"390832", "Lecce",
"390963", "Vibo\ Valentia",
"390187", "La\ Spezia",
"390522", "Reggio\ Emilia",
"390364", "Brescia",
"390942", "Catania",
"390965", "Reggio\ Calabria",
"390432", "Udine",
"39075", "Perugia",
"390924", "Trapani",
"390341", "Lecco",
"39051", "Bologna",
"390734", "Fermo",
"39090", "Messina",
"390161", "Vercelli",
"390421", "Venice",
"390933", "Caltanissetta",
"390862", "L\'Aquila",
"39035", "Bergamo",
"390445", "Vicenza",
"390122", "Turin",
"390883", "Andria\ Barletta\ Trani",
"39055", "Florence",
"390737", "Macerata",
"390424", "Vicenza",
"390824", "Benevento",
"39071", "Ancona",
"39040", "Trieste",
"390921", "Palermo",
"390171", "Cuneo",
"39031", "Como",
"390523", "Piacenza",
"390731", "Ancona",
"390962", "Crotone",
"390541", "Rimini",
"390344", "Como",
"39080", "Bari",
"390774", "Rome",
"39089", "Salerno",
"390322", "Novara",
"390549", "San\ Marino",
"39015", "Biella",
"39049", "Padova",
"390577", "Siena",
"390865", "Isernia",
"390141", "Asti",
"390975", "Potenza",
"390789", "Sassari",
"390125", "Turin",
"390363", "Bergamo",
"3906698", "Vatican\ City",
"390365", "Brescia",
"390874", "Campobasso",
"390342", "Sondrio",
"39079", "Sassari",
"390575", "Arezzo",
"390422", "Treviso",
"390532", "Ferrara",
"3906", "Rome",
"39039", "Monza",
"390461", "Trento",
"390372", "Cremona",
"39030", "Brescia",
"39081", "Naples",
"39095", "Catania",
"39041", "Venice",
"390934", "Caltanissetta\ and\ Enna",
"390783", "Oristano",
"390881", "Foggia",
"390444", "Vicenza",
"390543", "Forlì\-Cesena",
"39070", "Cagliari",
"390925", "Agrigento",
"39013", "Alessandria",
"390521", "Parma",
"390324", "Verbano\-Cusio\-Ossola",
"390733", "Macerata",
"390735", "Ascoli\ Piceno",
"390545", "Ravenna",
"390321", "Novara",
"390585", "Massa\-Carrara",
"39045", "Verona",
"390343", "Sondrio",
"390583", "Lucca",
"39085", "Pescara",
"39091", "Palermo",
"390362", "Cremona\/Monza",
"390376", "Mantua",
"390823", "Caserta",
"390425", "Rovigo",
"390165", "Aosta\ Valley",
"39050", "Pisa",
"390884", "Foggia",
"390825", "Avellino",
"390423", "Treviso",
"390776", "Frosinone",
"390183", "Imperia",
"390346", "Bergamo",
"390974", "Salerno",
"390373", "Cremona",
"39059", "Modena",
"39033", "Varese",
"390185", "Genoa",
"390586", "Livorno",
"390382", "Pavia",
"390922", "Agrigento",
"390471", "Bolzano\/Bozen",
"390166", "Aosta\ Valley",
"390426", "Rovigo",
"390565", "Livorno",
"390961", "Catanzaro",
"3902", "Milan",
"390732", "Ancona",
"39010", "Genoa",};
$areanames{it} = {"390985", "Scalea",
"390427", "Spilimbergo",
"390784", "Nuoro",
"390933", "Caltagirone",
"390966", "Palmi",
"390972", "Melfi",
"390587", "Pontedera",
"390445", "Schio",
"390122", "Susa",
"390578", "Chianciano\ Terme",
"390462", "Cavalese",
"390873", "Vasto",
"390771", "Formia",
"390522", "Reggio\ nell\'Emilia",
"390965", "Reggio\ di\ Calabria",
"390942", "Taormina",
"390377", "Codogno",
"390549", "Repubblica\ di\ San\ Marino",
"390564", "Grosseto",
"390722", "Urbino",
"390828", "Battipaglia",
"390123", "Lanzo\ Torinese",
"390463", "Cles",
"390571", "Empoli",
"390374", "Soresina",
"390436", "Cortina\ d\'Ampezzo",
"390932", "Ragusa",
"390184", "Sanremo",
"390973", "Lagonegro",
"390424", "Bassano\ del\ Grappa",
"390885", "Cerignola",
"390584", "Viareggio",
"390921", "Cefalù",
"390381", "Vigevano",
"390872", "Lanciano",
"390344", "Menaggio",
"390435", "Pieve\ di\ Cadore",
"390731", "Jesi",
"390833", "Gallipoli",
"390437", "Belluno",
"390785", "Macomer",
"39041", "Venezia",
"390173", "Alba",
"390766", "Civitavecchia",
"390831", "Brindisi",
"390984", "Cosenza",
"390324", "Domodossola",
"390543", "Forlì",
"390923", "Trapani",
"390383", "Voghera",
"390941", "Patti",
"390363", "Treviglio",
"390474", "Brunico",
"390964", "Locri",
"3906698", "Città\ del\ Vaticano",
"390971", "Potenza",
"390573", "Pistoia",
"390121", "Pinerolo",
"390742", "Foligno",
"390765", "Poggio\ Mirteto",
"390143", "Novi\ Ligure",
"3906", "Roma",
"390864", "Sulmona",
"390375", "Casalmaggiore",
"390346", "Clusone",
"390967", "Soverato",
"390185", "Rapallo",
"390732", "Fabriano",
"390172", "Savigliano",
"390426", "Adria",
"390166", "Saint\-Vincent",
"390871", "Chieti",
"390773", "Latina",
"390565", "Piombino",
"390542", "Imola",
"390585", "Massa",
"39019", "Savona",
"390376", "Mantova",
"390434", "Pordenone",
"390345", "San\ Pellegrino\ Terme",
"390362", "Seregno",
"390743", "Spoleto",
"390572", "Montecatini\ Terme",
"390721", "Pesaro",
"390566", "Follonica",
"390165", "Aosta",
"390533", "Comacchio",
"390142", "Casale\ Monferrato",
"390931", "Siracusa",
"390884", "Manfredonia",
"390384", "Mortara",
"390924", "Alcamo",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390174", "Mondovì",
"390323", "Baveno",
"390983", "Rossano",
"390544", "Ravenna",
"390421", "San\ Donà\ di\ Piave",
"390935", "Enna",
"39011", "Torino",
"390144", "Acqui\ Terme",
"390429", "Este",
"390882", "San\ Severo",
"390875", "Termoli",
"390364", "Breno",
"390473", "Merano",
"390982", "Paola",
"390322", "Arona",
"390774", "Tivoli",
"390588", "Volterra",
"390975", "Sala\ Consilina",
"390836", "Maglie",
"390442", "Legnago",
"390125", "Ivrea",
"390465", "Tione\ di\ Trento",
"390761", "Viterbo",
"390863", "Avezzano",
"390428", "Tarvisio",
"390789", "Olbia",
"390737", "Camerino",
"390547", "Cesena",
"39055", "Firenze",
"390781", "Iglesias",
"390883", "Andria",
"390744", "Terni",
"390331", "Busto\ Arsizio",
"390534", "Porretta\ Terme",
"390525", "Fornovo\ di\ Taro",
"390433", "Tolmezzo",
"390835", "Matera",
"390472", "Bressanone",
"390976", "Muro\ Lucano",
"39081", "Napoli",
"390934", "Caltanissetta",
"390182", "Albenga",
"390968", "Lamezia\ Terme",
"390925", "Sciacca",
"390385", "Stradella",
"390545", "Lugo",
"390175", "Saluzzo",
"390431", "Cervignano\ del\ Friuli",
"390735", "San\ Benedetto\ del\ Tronto",
"390439", "Feltre",
"390365", "Salò",
"390546", "Faenza",
"390736", "Ascoli\ Piceno",
"390861", "Teramo",
"390763", "Orvieto",
"390386", "Ostiglia",
"390782", "Lanusei",
"390974", "Vallo\ della\ Lucania",
"390332", "Varese",
"390124", "Rivarolo\ Canavese",
"390464", "Rovereto",
"390373", "Crema",
"390536", "Sassuolo",
"390775", "Frosinone",
"390471", "Bolzano",
"390438", "Conegliano",
"390746", "Rieti",
"3902", "Milano",
"39010", "Genova",
"390343", "Chiavenna",
"390524", "Fidenza",
"390981", "Castrovillari",
"390163", "Borgosesia",
"390776", "Cassino",
"390535", "Mirandola",
"390423", "Montebelluna",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ country_code => '39', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;