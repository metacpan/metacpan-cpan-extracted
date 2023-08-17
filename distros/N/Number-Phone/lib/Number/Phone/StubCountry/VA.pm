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
our $VERSION = 1.20230614174404;

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
$areanames{it} = {"390343", "Chiavenna",
"390436", "Cortina\ d\'Ampezzo",
"390984", "Cosenza",
"390774", "Tivoli",
"390324", "Domodossola",
"390863", "Avezzano",
"390383", "Voghera",
"39010", "Genova",
"390165", "Aosta",
"390923", "Trapani",
"390736", "Ascoli\ Piceno",
"390331", "Busto\ Arsizio",
"390474", "Brunico",
"390332", "Varese",
"390345", "San\ Pellegrino\ Terme",
"390121", "Pinerolo",
"390122", "Susa",
"390536", "Sassuolo",
"390925", "Sciacca",
"390163", "Borgosesia",
"390385", "Stradella",
"390771", "Formia",
"390982", "Paola",
"390549", "Repubblica\ di\ San\ Marino",
"390981", "Castrovillari",
"390789", "Olbia",
"390322", "Arona",
"390376", "Mantova",
"390185", "Rapallo",
"390547", "Cesena",
"390363", "Treviglio",
"390935", "Enna",
"390942", "Taormina",
"390883", "Andria",
"39055", "Firenze",
"390571", "Empoli",
"390941", "Patti",
"390572", "Montecatini\ Terme",
"390964", "Locri",
"390587", "Pontedera",
"390365", "Salò",
"390471", "Bolzano",
"390472", "Bressanone",
"390831", "Brindisi",
"390426", "Adria",
"390143", "Novi\ Ligure",
"390124", "Rivarolo\ Canavese",
"390933", "Caltagirone",
"390885", "Cerignola",
"390473", "Merano",
"390182", "Albenga",
"390833", "Gallipoli",
"390985", "Scalea",
"390968", "Lamezia\ Terme",
"390775", "Frosinone",
"390828", "Battipaglia",
"390142", "Casale\ Monferrato",
"390737", "Camerino",
"390932", "Ragusa",
"390931", "Siracusa",
"390323", "Baveno",
"390766", "Civitavecchia",
"390864", "Sulmona",
"390773", "Latina",
"390983", "Rossano",
"390835", "Matera",
"390362", "Seregno",
"3906", "Roma",
"390344", "Menaggio",
"390573", "Pistoia",
"390566", "Follonica",
"390437", "Belluno",
"390882", "San\ Severo",
"390924", "Alcamo",
"390384", "Mortara",
"390439", "Feltre",
"390578", "Chianciano\ Terme",
"390184", "Sanremo",
"39041", "Venezia",
"390934", "Caltanissetta",
"390123", "Lanzo\ Torinese",
"390965", "Reggio\ di\ Calabria",
"390429", "Este",
"390427", "Spilimbergo",
"390144", "Acqui\ Terme",
"390364", "Breno",
"390861", "Teramo",
"390746", "Rieti",
"390381", "Vigevano",
"390921", "Cefalù",
"390976", "Muro\ Lucano",
"390125", "Ivrea",
"390546", "Faenza",
"390884", "Manfredonia",
"390377", "Codogno",
"390975", "Sala\ Consilina",
"390545", "Lugo",
"390785", "Macomer",
"390172", "Savigliano",
"390731", "Jesi",
"390585", "Massa",
"390732", "Fabriano",
"390424", "Bassano\ del\ Grappa",
"390524", "Fidenza",
"390543", "Forlì",
"390973", "Lagonegro",
"390966", "Palmi",
"390431", "Cervignano\ del\ Friuli",
"390374", "Soresina",
"390445", "Schio",
"390871", "Chieti",
"390743", "Spoleto",
"390872", "Lanciano",
"390174", "Mondovì",
"390565", "Piombino",
"390588", "Volterra",
"390534", "Porretta\ Terme",
"390463", "Cles",
"390765", "Poggio\ Mirteto",
"390421", "San\ Donà\ di\ Piave",
"390836", "Maglie",
"390522", "Reggio\ nell\'Emilia",
"390776", "Cassino",
"390763", "Orvieto",
"390465", "Tione\ di\ Trento",
"390721", "Pesaro",
"390722", "Urbino",
"390434", "Pordenone",
"390974", "Vallo\ della\ Lucania",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390544", "Ravenna",
"390784", "Nuoro",
"390761", "Viterbo",
"390584", "Viareggio",
"39081", "Napoli",
"390744", "Terni",
"3906698", "Città\ del\ Vaticano",
"390373", "Crema",
"390967", "Soverato",
"390438", "Conegliano",
"390525", "Fornovo\ di\ Taro",
"39011", "Torino",
"390462", "Cavalese",
"390375", "Casalmaggiore",
"390423", "Montebelluna",
"390175", "Saluzzo",
"390386", "Ostiglia",
"390428", "Tarvisio",
"390781", "Iglesias",
"390972", "Melfi",
"390564", "Grosseto",
"390542", "Imola",
"390535", "Mirandola",
"390971", "Potenza",
"390782", "Lanusei",
"390433", "Tolmezzo",
"390346", "Clusone",
"390873", "Vasto",
"390735", "San\ Benedetto\ del\ Tronto",
"390742", "Foligno",
"390533", "Comacchio",
"390173", "Alba",
"390166", "Saint\-Vincent",
"390875", "Termoli",
"39019", "Savona",
"3902", "Milano",
"390464", "Rovereto",
"390435", "Pieve\ di\ Cadore",
"390442", "Legnago",};
$areanames{en} = {"39091", "Palermo",
"390183", "Imperia",
"39030", "Brescia",
"39045", "Verona",
"390365", "Brescia",
"390471", "Bolzano\/Bozen",
"390426", "Rovigo",
"390832", "Lecce",
"390522", "Reggio\ Emilia",
"390521", "Parma",
"390776", "Frosinone",
"390874", "Campobasso",
"390933", "Caltanissetta",
"390372", "Cremona",
"39040", "Trieste",
"39033", "Varese",
"39035", "Bergamo",
"390371", "Lodi",
"390789", "Sassari",
"390322", "Novara",
"390549", "San\ Marino",
"390321", "Novara",
"39075", "Perugia",
"390824", "Benevento",
"390363", "Bergamo",
"390376", "Mantua",
"390185", "Genoa",
"390565", "Livorno",
"39050", "Pisa",
"39055", "Florence",
"390942", "Catania",
"390883", "Andria\ Barletta\ Trani",
"390734", "Fermo",
"390422", "Treviso",
"39070", "Cagliari",
"390421", "Venice",
"39080", "Bari",
"390865", "Isernia",
"390543", "Forlì\-Cesena",
"390783", "Oristano",
"390445", "Vicenza",
"390432", "Udine",
"390122", "Turin",
"39099", "Taranto",
"390583", "Lucca",
"390925", "Agrigento",
"39085", "Pescara",
"390187", "La\ Spezia",
"390532", "Ferrara",
"390545", "Ravenna",
"390975", "Potenza",
"390343", "Sondrio",
"390324", "Verbano\-Cusio\-Ossola",
"390774", "Rome",
"39015", "Biella",
"390171", "Cuneo",
"39013", "Alessandria",
"390732", "Ancona",
"390424", "Vicenza",
"390585", "Massa\-Carrara",
"390165", "Aosta\ Valley",
"390731", "Ancona",
"39010", "Genoa",
"390574", "Prato",
"390962", "Crotone",
"390961", "Catanzaro",
"390342", "Sondrio",
"390341", "Lecco",
"390823", "Caserta",
"390364", "Brescia",
"39071", "Ancona",
"390586", "Livorno",
"390166", "Aosta\ Valley",
"390862", "L\'Aquila",
"390382", "Pavia",
"3902", "Milan",
"390921", "Palermo",
"390922", "Agrigento",
"390733", "Macerata",
"390884", "Foggia",
"39051", "Bologna",
"390125", "Turin",
"390963", "Vibo\ Valentia",
"39089", "Salerno",
"390825", "Avellino",
"39095", "Catania",
"39041", "Venice",
"390541", "Rimini",
"390965", "Reggio\ Calabria",
"390346", "Bergamo",
"39090", "Messina",
"390577", "Siena",
"39031", "Como",
"390934", "Caltanissetta\ and\ Enna",
"390735", "Ascoli\ Piceno",
"390161", "Vercelli",
"39011", "Turin",
"39059", "Modena",
"390344", "Como",
"3906", "Rome",
"390362", "Cremona\/Monza",
"390444", "Vicenza",
"390882", "Foggia",
"390461", "Trento",
"390881", "Foggia",
"39079", "Sassari",
"39048", "Gorizia",
"390423", "Treviso",
"390924", "Trapani",
"39039", "Monza",
"390974", "Salerno",
"390523", "Piacenza",
"390425", "Rovigo",
"3906698", "Vatican\ City",
"390737", "Macerata",
"39081", "Naples",
"390141", "Asti",
"390575", "Arezzo",
"39049", "Padova",
"390373", "Cremona",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ country_code => '39', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;