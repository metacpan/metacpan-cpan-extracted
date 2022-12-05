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
our $VERSION = 1.20221202211028;

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
$areanames{en} = {"390732", "Ancona",
"390371", "Lodi",
"390376", "Mantua",
"390963", "Vibo\ Valentia",
"390874", "Campobasso",
"390574", "Prato",
"390934", "Caltanissetta\ and\ Enna",
"390445", "Vicenza",
"390586", "Livorno",
"390924", "Trapani",
"390881", "Foggia",
"390577", "Siena",
"39090", "Messina",
"39079", "Sassari",
"390961", "Catanzaro",
"390583", "Lucca",
"39015", "Biella",
"390382", "Pavia",
"390565", "Livorno",
"39099", "Taranto",
"390865", "Isernia",
"39070", "Cagliari",
"390737", "Macerata",
"390883", "Andria\ Barletta\ Trani",
"390734", "Fermo",
"390373", "Cremona",
"390922", "Agrigento",
"39031", "Como",
"390545", "Ravenna",
"390166", "Aosta\ Valley",
"390942", "Catania",
"390884", "Foggia",
"390921", "Palermo",
"390975", "Potenza",
"390733", "Macerata",
"390161", "Vercelli",
"39095", "Catania",
"390825", "Avellino",
"390962", "Crotone",
"3902", "Milan",
"39041", "Venice",
"390122", "Turin",
"390141", "Asti",
"39048", "Gorizia",
"390365", "Brescia",
"390882", "Foggia",
"390471", "Bolzano\/Bozen",
"390425", "Rovigo",
"39013", "Alessandria",
"390372", "Cremona",
"390731", "Ancona",
"390933", "Caltanissetta",
"39051", "Bologna",
"39010", "Genoa",
"390185", "Genoa",
"39075", "Perugia",
"39081", "Naples",
"390549", "San\ Marino",
"39080", "Bari",
"390362", "Cremona\/Monza",
"390783", "Oristano",
"390824", "Benevento",
"390585", "Massa\-Carrara",
"39011", "Turin",
"39050", "Pisa",
"390432", "Udine",
"390974", "Salerno",
"390422", "Treviso",
"390789", "Sassari",
"39049", "Padova",
"390342", "Sondrio",
"390321", "Novara",
"390543", "Forlì\-Cesena",
"39035", "Bergamo",
"390461", "Trento",
"390522", "Reggio\ Emilia",
"390541", "Rimini",
"39040", "Trieste",
"390532", "Ferrara",
"390424", "Vicenza",
"390832", "Lecce",
"390364", "Brescia",
"390965", "Reggio\ Calabria",
"39089", "Salerno",
"390187", "La\ Spezia",
"390774", "Rome",
"390171", "Cuneo",
"390125", "Turin",
"39059", "Modena",
"390344", "Como",
"3906698", "Vatican\ City",
"390363", "Bergamo",
"390862", "L\'Aquila",
"390324", "Verbano\-Cusio\-Ossola",
"39030", "Brescia",
"390423", "Treviso",
"39033", "Varese",
"390575", "Arezzo",
"390444", "Vicenza",
"390925", "Agrigento",
"39071", "Ancona",
"390343", "Sondrio",
"390521", "Parma",
"39085", "Pescara",
"390183", "Imperia",
"39055", "Florence",
"390165", "Aosta\ Valley",
"390322", "Novara",
"39091", "Palermo",
"390341", "Lecco",
"390523", "Piacenza",
"390735", "Ascoli\ Piceno",
"390776", "Frosinone",
"390823", "Caserta",
"390346", "Bergamo",
"3906", "Rome",
"390426", "Rovigo",
"39045", "Verona",
"390421", "Venice",
"39039", "Monza",};
$areanames{it} = {"390435", "Pieve\ di\ Cadore",
"390882", "San\ Severo",
"390471", "Bolzano",
"390365", "Salò",
"39081", "Napoli",
"390964", "Locri",
"390163", "Borgosesia",
"390933", "Caltagirone",
"390775", "Frosinone",
"390573", "Pistoia",
"390731", "Jesi",
"390923", "Trapani",
"390721", "Pesaro",
"390124", "Rivarolo\ Canavese",
"390587", "Pontedera",
"390921", "Cefalù",
"39019", "Savona",
"390525", "Fornovo\ di\ Taro",
"390884", "Manfredonia",
"390931", "Siracusa",
"390571", "Empoli",
"390975", "Sala\ Consilina",
"390535", "Mirandola",
"390374", "Soresina",
"390386", "Ostiglia",
"390122", "Susa",
"390473", "Merano",
"390588", "Volterra",
"390121", "Pinerolo",
"390883", "Andria",
"390175", "Saluzzo",
"390565", "Piombino",
"390763", "Orvieto",
"390373", "Crema",
"390932", "Ragusa",
"390572", "Montecatini\ Terme",
"390474", "Brunico",
"390465", "Tione\ di\ Trento",
"390746", "Rieti",
"390722", "Urbino",
"390732", "Fabriano",
"390934", "Caltanissetta",
"390123", "Lanzo\ Torinese",
"390472", "Bressanone",
"390924", "Alcamo",
"390761", "Viterbo",
"390776", "Cassino",
"390833", "Gallipoli",
"3906", "Roma",
"390784", "Nuoro",
"390864", "Sulmona",
"390442", "Legnago",
"390544", "Ravenna",
"390982", "Paola",
"390436", "Cortina\ d\'Ampezzo",
"390426", "Adria",
"3906698", "Città\ del\ Vaticano",
"390385", "Stradella",
"390782", "Lanusei",
"390984", "Cosenza",
"39055", "Firenze",
"390976", "Muro\ Lucano",
"390875", "Termoli",
"390536", "Sassuolo",
"390831", "Brindisi",
"390343", "Chiavenna",
"390542", "Imola",
"390427", "Spilimbergo",
"390437", "Belluno",
"390438", "Conegliano",
"390861", "Teramo",
"390428", "Tarvisio",
"390566", "Follonica",
"390344", "Menaggio",
"390184", "Sanremo",
"390781", "Iglesias",
"390983", "Rossano",
"390863", "Avezzano",
"39011", "Torino",
"390549", "Repubblica\ di\ San\ Marino",
"390585", "Massa",
"390981", "Castrovillari",
"390182", "Albenga",
"390789", "Olbia",
"390543", "Forlì",
"390143", "Novi\ Ligure",
"390968", "Lamezia\ Terme",
"390383", "Voghera",
"390185", "Rapallo",
"390967", "Soverato",
"390736", "Ascoli\ Piceno",
"390873", "Vasto",
"39010", "Genova",
"390742", "Foligno",
"390345", "San\ Pellegrino\ Terme",
"390835", "Matera",
"390871", "Chieti",
"390584", "Viareggio",
"390942", "Taormina",
"390166", "Saint\-Vincent",
"39041", "Venezia",
"390744", "Terni",
"390377", "Codogno",
"390381", "Vigevano",
"3902", "Milano",
"390142", "Casale\ Monferrato",
"390966", "Palmi",
"390737", "Camerino",
"390785", "Macomer",
"390872", "Lanciano",
"390941", "Patti",
"390743", "Spoleto",
"390545", "Lugo",
"390376", "Mantova",
"390384", "Mortara",
"390578", "Chianciano\ Terme",
"390144", "Acqui\ Terme",
"390445", "Schio",
"390766", "Civitavecchia",
"390985", "Scalea",
"390462", "Cavalese",
"390346", "Clusone",
"390564", "Grosseto",
"390322", "Arona",
"390735", "San\ Benedetto\ del\ Tronto",
"390973", "Lagonegro",
"390533", "Comacchio",
"390771", "Formia",
"390174", "Mondovì",
"390332", "Varese",
"390547", "Cesena",
"390421", "San\ Donà\ di\ Piave",
"390431", "Cervignano\ del\ Friuli",
"390433", "Tolmezzo",
"390324", "Domodossola",
"390423", "Montebelluna",
"390172", "Savigliano",
"390464", "Rovereto",
"390363", "Treviglio",
"390165", "Aosta",
"390429", "Este",
"390439", "Feltre",
"390971", "Potenza",
"390836", "Maglie",
"390935", "Enna",
"390773", "Latina",
"390925", "Sciacca",
"390463", "Cles",
"390364", "Breno",
"390546", "Faenza",
"390323", "Baveno",
"390434", "Pordenone",
"390522", "Reggio\ nell\'Emilia",
"390424", "Bassano\ del\ Grappa",
"390972", "Melfi",
"390774", "Tivoli",
"390125", "Ivrea",
"390965", "Reggio\ di\ Calabria",
"390524", "Fidenza",
"390885", "Cerignola",
"390173", "Alba",
"390534", "Porretta\ Terme",
"390974", "Vallo\ della\ Lucania",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390362", "Seregno",
"390765", "Poggio\ Mirteto",
"390828", "Battipaglia",
"390331", "Busto\ Arsizio",
"390375", "Casalmaggiore",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;