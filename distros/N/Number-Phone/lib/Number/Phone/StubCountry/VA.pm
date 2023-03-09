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
our $VERSION = 1.20230307181422;

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
$areanames{it} = {"390322", "Arona",
"390545", "Lugo",
"390184", "Sanremo",
"390831", "Brindisi",
"390383", "Voghera",
"39011", "Torino",
"390381", "Vigevano",
"390935", "Enna",
"390833", "Gallipoli",
"390437", "Belluno",
"390941", "Patti",
"390438", "Conegliano",
"390984", "Cosenza",
"390143", "Novi\ Ligure",
"390344", "Menaggio",
"390533", "Comacchio",
"390776", "Cassino",
"390982", "Paola",
"390761", "Viterbo",
"390121", "Pinerolo",
"390525", "Fornovo\ di\ Taro",
"390923", "Trapani",
"390471", "Bolzano",
"390473", "Merano",
"390182", "Albenga",
"390921", "Cefalù",
"390123", "Lanzo\ Torinese",
"390578", "Chianciano\ Terme",
"390763", "Orvieto",
"390324", "Domodossola",
"390385", "Stradella",
"390931", "Siracusa",
"39055", "Firenze",
"39081", "Napoli",
"390543", "Forlì",
"390462", "Cavalese",
"390884", "Manfredonia",
"390535", "Mirandola",
"390933", "Caltagirone",
"390835", "Matera",
"390346", "Clusone",
"390584", "Viareggio",
"390925", "Sciacca",
"390427", "Spilimbergo",
"390774", "Tivoli",
"390428", "Tarvisio",
"390464", "Rovereto",
"390882", "San\ Severo",
"390765", "Poggio\ Mirteto",
"390332", "Varese",
"390125", "Ivrea",
"390771", "Formia",
"390766", "Civitavecchia",
"3902", "Milano",
"390542", "Imola",
"390439", "Feltre",
"390377", "Codogno",
"390524", "Fidenza",
"390463", "Cles",
"390789", "Olbia",
"390932", "Ragusa",
"390773", "Latina",
"390934", "Caltanissetta",
"390536", "Sassuolo",
"390522", "Reggio\ nell\'Emilia",
"390331", "Busto\ Arsizio",
"390883", "Andria",
"390985", "Scalea",
"390345", "San\ Pellegrino\ Terme",
"390836", "Maglie",
"390386", "Ostiglia",
"390544", "Ravenna",
"390737", "Camerino",
"390185", "Rapallo",
"390124", "Rivarolo\ Canavese",
"390323", "Baveno",
"390474", "Brunico",
"390942", "Taormina",
"390924", "Alcamo",
"390775", "Frosinone",
"390968", "Lamezia\ Terme",
"390967", "Soverato",
"390465", "Tione\ di\ Trento",
"390142", "Casale\ Monferrato",
"390885", "Cerignola",
"390983", "Rossano",
"390144", "Acqui\ Terme",
"390343", "Chiavenna",
"390534", "Porretta\ Terme",
"390585", "Massa",
"390546", "Faenza",
"390472", "Bressanone",
"390384", "Mortara",
"390122", "Susa",
"390429", "Este",
"390981", "Castrovillari",
"390782", "Lanusei",
"390976", "Muro\ Lucano",
"390364", "Breno",
"390163", "Borgosesia",
"390565", "Piombino",
"390549", "Repubblica\ di\ San\ Marino",
"390721", "Pesaro",
"390426", "Adria",
"390375", "Casalmaggiore",
"390434", "Pordenone",
"390743", "Spoleto",
"390872", "Lanciano",
"390362", "Seregno",
"390735", "San\ Benedetto\ del\ Tronto",
"390572", "Montecatini\ Terme",
"390784", "Nuoro",
"390974", "Vallo\ della\ Lucania",
"390165", "Aosta",
"390442", "Legnago",
"390861", "Teramo",
"390174", "Mondovì",
"390373", "Crema",
"390863", "Avezzano",
"390965", "Reggio\ di\ Calabria",
"390424", "Bassano\ del\ Grappa",
"390587", "Pontedera",
"390588", "Volterra",
"390731", "Jesi",
"3906", "Roma",
"390436", "Cortina\ d\'Ampezzo",
"390172", "Savigliano",
"390972", "Melfi",
"39041", "Venezia",
"390547", "Cesena",
"390785", "Macomer",
"39010", "Genova",
"390746", "Rieti",
"3906698", "Città\ del\ Vaticano",
"390435", "Pieve\ di\ Cadore",
"390423", "Montebelluna",
"390966", "Palmi",
"390564", "Grosseto",
"390828", "Battipaglia",
"390971", "Potenza",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390173", "Alba",
"390374", "Soresina",
"390864", "Sulmona",
"390166", "Saint\-Vincent",
"390732", "Fabriano",
"390365", "Salò",
"390973", "Lagonegro",
"390875", "Termoli",
"390421", "San\ Donà\ di\ Piave",
"390736", "Ascoli\ Piceno",
"390722", "Urbino",
"390445", "Schio",
"390431", "Cervignano\ del\ Friuli",
"390433", "Tolmezzo",
"390744", "Terni",
"390781", "Iglesias",
"390571", "Empoli",
"390175", "Saluzzo",
"390964", "Locri",
"390566", "Follonica",
"390376", "Mantova",
"390742", "Foligno",
"390871", "Chieti",
"390975", "Sala\ Consilina",
"390873", "Vasto",
"390363", "Treviglio",
"39019", "Savona",
"390573", "Pistoia",};
$areanames{en} = {"390343", "Sondrio",
"39099", "Taranto",
"390376", "Mantua",
"390425", "Rovigo",
"39035", "Bergamo",
"390922", "Agrigento",
"39031", "Como",
"390585", "Massa\-Carrara",
"390975", "Potenza",
"390363", "Bergamo",
"390183", "Imperia",
"390341", "Lecco",
"390122", "Turin",
"39079", "Sassari",
"390783", "Oristano",
"390445", "Vicenza",
"390382", "Pavia",
"390942", "Catania",
"390924", "Trapani",
"39080", "Bari",
"390832", "Lecce",
"390321", "Novara",
"390532", "Ferrara",
"390962", "Crotone",
"39050", "Pisa",
"390934", "Caltanissetta\ and\ Enna",
"39013", "Alessandria",
"390423", "Treviso",
"39059", "Modena",
"390583", "Lucca",
"390522", "Reggio\ Emilia",
"390883", "Andria\ Barletta\ Trani",
"39089", "Salerno",
"390166", "Aosta\ Valley",
"390171", "Cuneo",
"390575", "Arezzo",
"390881", "Foggia",
"390732", "Ancona",
"390737", "Macerata",
"390365", "Brescia",
"390185", "Genoa",
"39070", "Cagliari",
"390421", "Venice",
"39048", "Gorizia",
"390734", "Fermo",
"3902", "Milan",
"390461", "Trento",
"39041", "Venice",
"39045", "Verona",
"39010", "Genoa",
"390372", "Cremona",
"390862", "L\'Aquila",
"3906698", "Vatican\ City",
"390824", "Benevento",
"390789", "Sassari",
"39090", "Messina",
"390925", "Agrigento",
"390823", "Caserta",
"390731", "Ancona",
"390422", "Treviso",
"390774", "Rome",
"3906", "Rome",
"390523", "Piacenza",
"39049", "Padova",
"390882", "Foggia",
"39030", "Brescia",
"390521", "Parma",
"390125", "Turin",
"390444", "Vicenza",
"390733", "Macerata",
"390974", "Salerno",
"39051", "Bologna",
"390165", "Aosta\ Valley",
"39055", "Florence",
"39085", "Pescara",
"39081", "Naples",
"390371", "Lodi",
"390543", "Forlì\-Cesena",
"390541", "Rimini",
"390884", "Foggia",
"390373", "Cremona",
"390965", "Reggio\ Calabria",
"390933", "Caltanissetta",
"390346", "Bergamo",
"390424", "Vicenza",
"39033", "Varese",
"390342", "Sondrio",
"390776", "Frosinone",
"39071", "Ancona",
"39075", "Perugia",
"390825", "Avellino",
"390471", "Bolzano\/Bozen",
"390187", "La\ Spezia",
"390362", "Cremona\/Monza",
"390735", "Ascoli\ Piceno",
"390921", "Palermo",
"390577", "Siena",
"390324", "Verbano\-Cusio\-Ossola",
"390961", "Catanzaro",
"39091", "Palermo",
"390322", "Novara",
"39095", "Catania",
"390141", "Asti",
"390545", "Ravenna",
"390574", "Prato",
"390874", "Campobasso",
"39039", "Monza",
"390364", "Brescia",
"390565", "Livorno",
"39011", "Turin",
"390549", "San\ Marino",
"390161", "Vercelli",
"39015", "Biella",
"390432", "Udine",
"39040", "Trieste",
"390586", "Livorno",
"390344", "Como",
"390426", "Rovigo",
"390963", "Vibo\ Valentia",
"390865", "Isernia",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ country_code => '39', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;