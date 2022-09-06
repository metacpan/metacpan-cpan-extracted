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
our $VERSION = 1.20220903144944;

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
$areanames{it} = {"390332", "Varese",
"390828", "Battipaglia",
"390966", "Palmi",
"390721", "Pesaro",
"390932", "Ragusa",
"390144", "Acqui\ Terme",
"390428", "Tarvisio",
"390185", "Rapallo",
"390125", "Ivrea",
"390462", "Cavalese",
"390436", "Cortina\ d\'Ampezzo",
"390781", "Iglesias",
"390836", "Maglie",
"390971", "Potenza",
"390543", "Forlì",
"390547", "Cesena",
"3906", "Roma",
"390566", "Follonica",
"390343", "Chiavenna",
"390571", "Empoli",
"390742", "Foligno",
"390885", "Cerignola",
"390737", "Camerino",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390123", "Lanzo\ Torinese",
"390427", "Spilimbergo",
"390545", "Lugo",
"390584", "Viareggio",
"390524", "Fidenza",
"390735", "San\ Benedetto\ del\ Tronto",
"390172", "Savigliano",
"390384", "Mortara",
"390774", "Tivoli",
"390883", "Andria",
"390872", "Lanciano",
"390345", "San\ Pellegrino\ Terme",
"390984", "Cosenza",
"390472", "Bressanone",
"390431", "Cervignano\ del\ Friuli",
"390423", "Montebelluna",
"390376", "Mantova",
"390924", "Alcamo",
"390324", "Domodossola",
"390831", "Brindisi",
"390976", "Muro\ Lucano",
"39081", "Napoli",
"390522", "Reggio\ nell\'Emilia",
"390835", "Matera",
"390377", "Codogno",
"39041", "Venezia",
"390435", "Pieve\ di\ Cadore",
"390174", "Mondovì",
"390941", "Patti",
"390965", "Reggio\ di\ Calabria",
"390573", "Pistoia",
"390365", "Salò",
"390438", "Conegliano",
"390731", "Jesi",
"390322", "Arona",
"390968", "Lamezia\ Terme",
"390973", "Lagonegro",
"390565", "Piombino",
"390982", "Paola",
"390373", "Crema",
"390426", "Adria",
"39011", "Torino",
"390474", "Brunico",
"390464", "Rovereto",
"39055", "Firenze",
"390363", "Treviglio",
"390736", "Ascoli\ Piceno",
"390864", "Sulmona",
"390546", "Faenza",
"390833", "Gallipoli",
"390934", "Caltanissetta",
"390421", "San\ Donà\ di\ Piave",
"390142", "Casale\ Monferrato",
"390433", "Tolmezzo",
"390375", "Casalmaggiore",
"390785", "Macomer",
"390578", "Chianciano\ Terme",
"390744", "Terni",
"390975", "Sala\ Consilina",
"390437", "Belluno",
"390121", "Pinerolo",
"390442", "Legnago",
"390967", "Soverato",
"390534", "Porretta\ Terme",
"3906698", "Città\ del\ Vaticano",
"390346", "Clusone",
"390465", "Tione\ di\ Trento",
"390122", "Susa",
"390935", "Enna",
"390173", "Alba",
"390182", "Albenga",
"390873", "Vasto",
"390374", "Soresina",
"390429", "Este",
"390784", "Nuoro",
"390761", "Viterbo",
"390974", "Vallo\ della\ Lucania",
"390882", "San\ Severo",
"390473", "Merano",
"390165", "Aosta",
"390776", "Cassino",
"390386", "Ostiglia",
"390535", "Mirandola",
"390732", "Fabriano",
"390933", "Caltagirone",
"390921", "Cefalù",
"390766", "Civitavecchia",
"390549", "Repubblica\ di\ San\ Marino",
"390175", "Saluzzo",
"390434", "Pordenone",
"39010", "Genova",
"390463", "Cles",
"390542", "Imola",
"390964", "Locri",
"390771", "Formia",
"390381", "Vigevano",
"390863", "Avezzano",
"390364", "Breno",
"390981", "Castrovillari",
"390163", "Borgosesia",
"390533", "Comacchio",
"390942", "Taormina",
"390743", "Spoleto",
"390564", "Grosseto",
"3902", "Milano",
"390875", "Termoli",
"390471", "Bolzano",
"390763", "Orvieto",
"390544", "Ravenna",
"390439", "Feltre",
"390362", "Seregno",
"390585", "Massa",
"390871", "Chieti",
"390525", "Fornovo\ di\ Taro",
"390143", "Novi\ Ligure",
"390385", "Stradella",
"390775", "Frosinone",
"390344", "Menaggio",
"390985", "Scalea",
"390588", "Volterra",
"390536", "Sassuolo",
"390166", "Saint\-Vincent",
"390925", "Sciacca",
"390746", "Rieti",
"390184", "Sanremo",
"390124", "Rivarolo\ Canavese",
"39019", "Savona",
"390572", "Montecatini\ Terme",
"390765", "Poggio\ Mirteto",
"390789", "Olbia",
"390424", "Bassano\ del\ Grappa",
"390587", "Pontedera",
"390331", "Busto\ Arsizio",
"390323", "Baveno",
"390923", "Trapani",
"390722", "Urbino",
"390931", "Siracusa",
"390782", "Lanusei",
"390983", "Rossano",
"390861", "Teramo",
"390884", "Manfredonia",
"390383", "Voghera",
"390972", "Melfi",
"390773", "Latina",
"390445", "Schio",};
$areanames{en} = {"390363", "Bergamo",
"390161", "Vercelli",
"390881", "Foggia",
"390575", "Arezzo",
"390963", "Vibo\ Valentia",
"390523", "Piacenza",
"39055", "Florence",
"390583", "Lucca",
"390421", "Venice",
"390934", "Caltanissetta\ and\ Enna",
"39050", "Pisa",
"39049", "Padova",
"390824", "Benevento",
"39035", "Bergamo",
"39095", "Catania",
"39089", "Salerno",
"390789", "Sassari",
"390424", "Vicenza",
"390975", "Potenza",
"390445", "Vicenza",
"39030", "Brescia",
"390461", "Trento",
"3906698", "Vatican\ City",
"390346", "Bergamo",
"39090", "Messina",
"390372", "Cremona",
"390884", "Foggia",
"390962", "Crotone",
"39041", "Venice",
"390362", "Cremona\/Monza",
"390585", "Massa\-Carrara",
"39081", "Naples",
"390522", "Reggio\ Emilia",
"390471", "Bolzano\/Bozen",
"390965", "Reggio\ Calabria",
"390365", "Brescia",
"39033", "Varese",
"390341", "Lecco",
"390432", "Udine",
"390734", "Fermo",
"390832", "Lecce",
"390731", "Ancona",
"39075", "Perugia",
"390166", "Aosta\ Valley",
"390922", "Agrigento",
"390322", "Novara",
"390344", "Como",
"390577", "Siena",
"390426", "Rovigo",
"390925", "Agrigento",
"39011", "Turin",
"39070", "Cagliari",
"39048", "Gorizia",
"390541", "Rimini",
"390565", "Livorno",
"390382", "Pavia",
"390373", "Cremona",
"390783", "Oristano",
"390874", "Campobasso",
"390171", "Cuneo",
"390545", "Ravenna",
"390549", "San\ Marino",
"390933", "Caltanissetta",
"390732", "Ancona",
"390921", "Palermo",
"390321", "Novara",
"39015", "Biella",
"39059", "Modena",
"390183", "Imperia",
"390364", "Brescia",
"390735", "Ascoli\ Piceno",
"39010", "Genoa",
"39071", "Ancona",
"390521", "Parma",
"39080", "Bari",
"390774", "Rome",
"390961", "Catanzaro",
"390883", "Andria\ Barletta\ Trani",
"39040", "Trieste",
"390187", "La\ Spezia",
"390376", "Mantua",
"390924", "Trapani",
"390324", "Verbano\-Cusio\-Ossola",
"39085", "Pescara",
"390823", "Caserta",
"39099", "Taranto",
"390942", "Catania",
"3902", "Milan",
"39045", "Verona",
"390423", "Treviso",
"39039", "Monza",
"390342", "Sondrio",
"390865", "Isernia",
"390574", "Prato",
"390185", "Genoa",
"390122", "Turin",
"390733", "Macerata",
"390862", "L\'Aquila",
"390371", "Lodi",
"390543", "Forlì\-Cesena",
"390125", "Turin",
"39091", "Palermo",
"39031", "Como",
"390586", "Livorno",
"390825", "Avellino",
"390532", "Ferrara",
"390425", "Rovigo",
"3906", "Rome",
"390974", "Salerno",
"390882", "Foggia",
"390444", "Vicenza",
"390737", "Macerata",
"39051", "Bologna",
"390776", "Frosinone",
"390141", "Asti",
"390422", "Treviso",
"390165", "Aosta\ Valley",
"39013", "Alessandria",
"390343", "Sondrio",
"39079", "Sassari",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;