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
our $VERSION = 1.20211206222447;

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
$areanames{en} = {"39055", "Florence",
"390549", "San\ Marino",
"390934", "Caltanissetta\ and\ Enna",
"39090", "Messina",
"390532", "Ferrara",
"390324", "Verbano\-Cusio\-Ossola",
"390364", "Brescia",
"390924", "Trapani",
"39030", "Brescia",
"390522", "Reggio\ Emilia",
"390961", "Catanzaro",
"39015", "Biella",
"390577", "Siena",
"39048", "Gorizia",
"390933", "Caltanissetta",
"390925", "Agrigento",
"39013", "Alessandria",
"390365", "Brescia",
"390166", "Aosta\ Valley",
"390789", "Sassari",
"390963", "Vibo\ Valentia",
"390321", "Novara",
"39039", "Monza",
"390471", "Bolzano\/Bozen",
"390732", "Ancona",
"390832", "Lecce",
"390921", "Palermo",
"39099", "Taranto",
"39075", "Perugia",
"390122", "Turin",
"390363", "Bergamo",
"3902", "Milan",
"39085", "Pescara",
"390862", "L\'Aquila",
"390965", "Reggio\ Calabria",
"390733", "Macerata",
"390165", "Aosta\ Valley",
"39033", "Varese",
"390825", "Avellino",
"390922", "Agrigento",
"390362", "Cremona\/Monza",
"39035", "Bergamo",
"390731", "Ancona",
"390322", "Novara",
"390445", "Vicenza",
"39050", "Pisa",
"3906", "Rome",
"390735", "Ascoli\ Piceno",
"390823", "Caserta",
"39089", "Salerno",
"390125", "Turin",
"39095", "Catania",
"39079", "Sassari",
"390161", "Vercelli",
"390962", "Crotone",
"390865", "Isernia",
"39059", "Modena",
"390521", "Parma",
"390565", "Livorno",
"39041", "Venice",
"390187", "La\ Spezia",
"39080", "Bari",
"390734", "Fermo",
"390523", "Piacenza",
"390444", "Vicenza",
"39070", "Cagliari",
"39010", "Genoa",
"390824", "Benevento",
"3906698", "Vatican\ City",
"39091", "Palermo",
"390774", "Rome",
"390586", "Livorno",
"390575", "Arezzo",
"390874", "Campobasso",
"39031", "Como",
"390344", "Como",
"390422", "Treviso",
"390882", "Foggia",
"390426", "Rovigo",
"390171", "Cuneo",
"390574", "Prato",
"390343", "Sondrio",
"390432", "Udine",
"390376", "Mantua",
"39045", "Verona",
"390372", "Cremona",
"390341", "Lecco",
"390371", "Lodi",
"390342", "Sondrio",
"390425", "Rovigo",
"390461", "Trento",
"390776", "Frosinone",
"390346", "Bergamo",
"390975", "Potenza",
"390183", "Imperia",
"390373", "Cremona",
"390423", "Treviso",
"390883", "Andria\ Barletta\ Trani",
"390783", "Oristano",
"39051", "Bologna",
"390382", "Pavia",
"390942", "Catania",
"390141", "Asti",
"390881", "Foggia",
"39049", "Padova",
"390421", "Venice",
"390185", "Genoa",
"390737", "Macerata",
"390583", "Lucca",
"39071", "Ancona",
"390545", "Ravenna",
"39081", "Naples",
"39040", "Trieste",
"39011", "Turin",
"390541", "Rimini",
"390974", "Salerno",
"390585", "Massa\-Carrara",
"390424", "Vicenza",
"390884", "Foggia",
"390543", "Forlì\-Cesena",};
$areanames{it} = {"390428", "Tarvisio",
"39055", "Firenze",
"390536", "Sassuolo",
"390566", "Follonica",
"390324", "Domodossola",
"390924", "Alcamo",
"390522", "Reggio\ nell\'Emilia",
"390933", "Caltagirone",
"390365", "Salò",
"390931", "Siracusa",
"390442", "Legnago",
"390471", "Bolzano",
"390732", "Fabriano",
"390935", "Enna",
"390439", "Feltre",
"390363", "Treviglio",
"390473", "Merano",
"390965", "Reggio\ di\ Calabria",
"390331", "Busto\ Arsizio",
"390524", "Fidenza",
"39019", "Savona",
"390121", "Pinerolo",
"390123", "Lanzo\ Torinese",
"390322", "Arona",
"390966", "Palmi",
"390547", "Cesena",
"390125", "Ivrea",
"390721", "Pesaro",
"390864", "Sulmona",
"390565", "Piombino",
"39041", "Venezia",
"390535", "Mirandola",
"390427", "Spilimbergo",
"390533", "Comacchio",
"390573", "Pistoia",
"390174", "Mondovì",
"390542", "Imola",
"390571", "Empoli",
"390774", "Tivoli",
"390344", "Menaggio",
"390976", "Muro\ Lucano",
"390985", "Scalea",
"390882", "San\ Severo",
"390782", "Lanusei",
"390383", "Voghera",
"390381", "Vigevano",
"390983", "Rossano",
"390385", "Stradella",
"390376", "Mantova",
"390436", "Cortina\ d\'Ampezzo",
"390746", "Rieti",
"390981", "Castrovillari",
"390182", "Albenga",
"390433", "Tolmezzo",
"390743", "Spoleto",
"390463", "Cles",
"390975", "Sala\ Consilina",
"390872", "Lanciano",
"390431", "Cervignano\ del\ Friuli",
"390373", "Crema",
"390435", "Pieve\ di\ Cadore",
"390544", "Ravenna",
"390942", "Taormina",
"390971", "Potenza",
"390172", "Savigliano",
"390973", "Lagonegro",
"390465", "Tione\ di\ Trento",
"390143", "Novi\ Ligure",
"390375", "Casalmaggiore",
"390386", "Ostiglia",
"390184", "Sanremo",
"390737", "Camerino",
"390784", "Nuoro",
"390585", "Massa",
"390884", "Manfredonia",
"390424", "Bassano\ del\ Grappa",
"390964", "Locri",
"390549", "Repubblica\ di\ San\ Marino",
"390934", "Caltanissetta",
"390474", "Brunico",
"390438", "Conegliano",
"390364", "Breno",
"390323", "Baveno",
"390722", "Urbino",
"390925", "Sciacca",
"390166", "Saint\-Vincent",
"390429", "Este",
"390789", "Olbia",
"390766", "Civitavecchia",
"390923", "Trapani",
"390921", "Cefalù",
"390736", "Ascoli\ Piceno",
"390122", "Susa",
"390836", "Maglie",
"390588", "Volterra",
"3902", "Milano",
"390861", "Teramo",
"390332", "Varese",
"390165", "Aosta",
"390761", "Viterbo",
"390833", "Gallipoli",
"390763", "Orvieto",
"390831", "Brindisi",
"390362", "Seregno",
"390587", "Pontedera",
"390863", "Avezzano",
"390731", "Jesi",
"390472", "Bressanone",
"390534", "Porretta\ Terme",
"390445", "Schio",
"390163", "Borgosesia",
"390735", "San\ Benedetto\ del\ Tronto",
"3906", "Roma",
"390578", "Chianciano\ Terme",
"390932", "Ragusa",
"390835", "Matera",
"390564", "Grosseto",
"390765", "Poggio\ Mirteto",
"390124", "Rivarolo\ Canavese",
"390437", "Belluno",
"390377", "Codogno",
"39010", "Genova",
"390525", "Fornovo\ di\ Taro",
"390828", "Battipaglia",
"3906698", "Città\ del\ Vaticano",
"390546", "Faenza",
"390967", "Soverato",
"390384", "Mortara",
"390984", "Cosenza",
"390345", "San\ Pellegrino\ Terme",
"390173", "Alba",
"390142", "Casale\ Monferrato",
"390426", "Adria",
"390941", "Patti",
"390875", "Termoli",
"390972", "Melfi",
"390775", "Frosinone",
"390742", "Foligno",
"390343", "Chiavenna",
"390771", "Formia",
"390871", "Chieti",
"390175", "Saluzzo",
"390873", "Vasto",
"390462", "Cavalese",
"390773", "Latina",
"390982", "Paola",
"390885", "Cerignola",
"390584", "Viareggio",
"390776", "Cassino",
"390785", "Macomer",
"390346", "Clusone",
"390883", "Andria",
"390423", "Montebelluna",
"390781", "Iglesias",
"390421", "San\ Donà\ di\ Piave",
"390185", "Rapallo",
"390374", "Soresina",
"390464", "Rovereto",
"390434", "Pordenone",
"39081", "Napoli",
"390545", "Lugo",
"390744", "Terni",
"39011", "Torino",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390572", "Montecatini\ Terme",
"390974", "Vallo\ della\ Lucania",
"390144", "Acqui\ Terme",
"390968", "Lamezia\ Terme",
"390543", "Forlì",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;