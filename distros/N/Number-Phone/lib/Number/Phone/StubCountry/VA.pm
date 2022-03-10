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
our $VERSION = 1.20220307120124;

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
$areanames{it} = {"390973", "Lagonegro",
"390163", "Borgosesia",
"390363", "Treviglio",
"390883", "Andria",
"390933", "Caltagirone",
"390383", "Voghera",
"3902", "Milano",
"390463", "Cles",
"390578", "Chianciano\ Terme",
"390863", "Avezzano",
"390861", "Teramo",
"390975", "Sala\ Consilina",
"390165", "Aosta",
"390736", "Ascoli\ Piceno",
"390365", "Salò",
"390744", "Terni",
"390885", "Cerignola",
"390426", "Adria",
"390776", "Cassino",
"390935", "Enna",
"390381", "Vigevano",
"390931", "Siracusa",
"390385", "Stradella",
"390546", "Faenza",
"390185", "Rapallo",
"390465", "Tione\ di\ Trento",
"390971", "Potenza",
"390534", "Porretta\ Terme",
"390542", "Imola",
"390345", "San\ Pellegrino\ Terme",
"390122", "Susa",
"390525", "Fornovo\ di\ Taro",
"390322", "Arona",
"390732", "Fabriano",
"390445", "Schio",
"390566", "Follonica",
"390924", "Alcamo",
"390784", "Nuoro",
"390143", "Novi\ Ligure",
"390343", "Chiavenna",
"390774", "Tivoli",
"390424", "Bassano\ del\ Grappa",
"390782", "Lanusei",
"390746", "Rieti",
"39055", "Firenze",
"390124", "Rivarolo\ Canavese",
"390536", "Sassuolo",
"390941", "Patti",
"390324", "Domodossola",
"390544", "Ravenna",
"390828", "Battipaglia",
"390427", "Spilimbergo",
"390428", "Tarvisio",
"390737", "Camerino",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"3906698", "Città\ del\ Vaticano",
"390547", "Cesena",
"390588", "Volterra",
"390173", "Alba",
"390373", "Crema",
"390587", "Pontedera",
"390433", "Tolmezzo",
"390873", "Vasto",
"390833", "Gallipoli",
"390983", "Rossano",
"3906", "Roma",
"390473", "Merano",
"390471", "Bolzano",
"390981", "Castrovillari",
"390766", "Civitavecchia",
"390439", "Feltre",
"390831", "Brindisi",
"390721", "Pesaro",
"39041", "Venezia",
"390965", "Reggio\ di\ Calabria",
"390871", "Chieti",
"390572", "Montecatini\ Terme",
"390175", "Saluzzo",
"390584", "Viareggio",
"390375", "Casalmaggiore",
"390431", "Cervignano\ del\ Friuli",
"39081", "Napoli",
"390435", "Pieve\ di\ Cadore",
"390742", "Foligno",
"39011", "Torino",
"390875", "Termoli",
"390835", "Matera",
"390564", "Grosseto",
"390985", "Scalea",
"390331", "Busto\ Arsizio",
"390533", "Comacchio",
"390573", "Pistoia",
"390743", "Spoleto",
"390864", "Sulmona",
"390535", "Mirandola",
"390332", "Varese",
"390464", "Rovereto",
"390184", "Sanremo",
"390172", "Savigliano",
"390384", "Mortara",
"390872", "Lanciano",
"390934", "Caltanissetta",
"390571", "Empoli",
"390884", "Manfredonia",
"39010", "Genova",
"390472", "Bressanone",
"390982", "Paola",
"390364", "Breno",
"390974", "Vallo\ della\ Lucania",
"390722", "Urbino",
"390785", "Macomer",
"390436", "Cortina\ d\'Ampezzo",
"390925", "Sciacca",
"390836", "Maglie",
"390761", "Viterbo",
"390942", "Taormina",
"390765", "Poggio\ Mirteto",
"390789", "Olbia",
"390524", "Fidenza",
"390966", "Palmi",
"390344", "Menaggio",
"390921", "Cefalù",
"390376", "Mantova",
"390144", "Acqui\ Terme",
"390781", "Iglesias",
"390923", "Trapani",
"390763", "Orvieto",
"390386", "Ostiglia",
"390771", "Formia",
"390545", "Lugo",
"390421", "San\ Donà\ di\ Piave",
"390142", "Casale\ Monferrato",
"390731", "Jesi",
"390522", "Reggio\ nell\'Emilia",
"390429", "Este",
"390125", "Ivrea",
"390976", "Muro\ Lucano",
"390549", "Repubblica\ di\ San\ Marino",
"390121", "Pinerolo",
"390735", "San\ Benedetto\ del\ Tronto",
"390166", "Saint\-Vincent",
"390442", "Legnago",
"390775", "Frosinone",
"390543", "Forlì",
"390323", "Baveno",
"390123", "Lanzo\ Torinese",
"390423", "Montebelluna",
"39019", "Savona",
"390773", "Latina",
"390438", "Conegliano",
"390437", "Belluno",
"390377", "Codogno",
"390967", "Soverato",
"390968", "Lamezia\ Terme",
"390474", "Brunico",
"390984", "Cosenza",
"390362", "Seregno",
"390972", "Melfi",
"390565", "Piombino",
"390932", "Ragusa",
"390882", "San\ Severo",
"390434", "Pordenone",
"390462", "Cavalese",
"390182", "Albenga",
"390374", "Soresina",
"390585", "Massa",
"390174", "Mondovì",
"390346", "Clusone",
"390964", "Locri",};
$areanames{en} = {"390425", "Rovigo",
"390541", "Rimini",
"390549", "San\ Marino",
"390825", "Avellino",
"390166", "Aosta\ Valley",
"390735", "Ascoli\ Piceno",
"390324", "Verbano\-Cusio\-Ossola",
"390321", "Novara",
"390734", "Fermo",
"390731", "Ancona",
"390824", "Benevento",
"39055", "Florence",
"390522", "Reggio\ Emilia",
"390125", "Turin",
"390342", "Sondrio",
"390922", "Agrigento",
"39095", "Catania",
"390774", "Rome",
"390421", "Venice",
"39071", "Ancona",
"390424", "Vicenza",
"390545", "Ravenna",
"390423", "Treviso",
"39039", "Monza",
"3906698", "Vatican\ City",
"390733", "Macerata",
"390823", "Caserta",
"39049", "Padova",
"390737", "Macerata",
"390543", "Forlì\-Cesena",
"39089", "Salerno",
"3906", "Rome",
"390583", "Lucca",
"390963", "Vibo\ Valentia",
"39079", "Sassari",
"390373", "Cremona",
"390862", "L\'Aquila",
"39050", "Pisa",
"39011", "Turin",
"390585", "Massa\-Carrara",
"390371", "Lodi",
"39013", "Alessandria",
"39090", "Messina",
"39033", "Varese",
"390171", "Cuneo",
"39031", "Como",
"390382", "Pavia",
"390961", "Catanzaro",
"390346", "Bergamo",
"390874", "Campobasso",
"390965", "Reggio\ Calabria",
"390882", "Foggia",
"39081", "Naples",
"390471", "Bolzano\/Bozen",
"390362", "Cremona\/Monza",
"39041", "Venice",
"390532", "Ferrara",
"390565", "Livorno",
"390577", "Siena",
"3902", "Milan",
"390183", "Imperia",
"390883", "Andria\ Barletta\ Trani",
"390187", "La\ Spezia",
"390933", "Caltanissetta",
"390363", "Bergamo",
"39091", "Palermo",
"39010", "Genoa",
"390364", "Brescia",
"390161", "Vercelli",
"390974", "Salerno",
"39030", "Brescia",
"39075", "Perugia",
"390832", "Lecce",
"390865", "Isernia",
"390934", "Caltanissetta\ and\ Enna",
"390574", "Prato",
"390884", "Foggia",
"390881", "Foggia",
"39048", "Gorizia",
"390185", "Genoa",
"39051", "Bologna",
"390432", "Udine",
"390461", "Trento",
"390372", "Cremona",
"390426", "Rovigo",
"390776", "Frosinone",
"39040", "Trieste",
"390575", "Arezzo",
"390962", "Crotone",
"390975", "Potenza",
"390165", "Aosta\ Valley",
"390365", "Brescia",
"39080", "Bari",
"390344", "Como",
"390341", "Lecco",
"390921", "Palermo",
"390924", "Trapani",
"390376", "Mantua",
"39045", "Verona",
"390422", "Treviso",
"390141", "Asti",
"390789", "Sassari",
"39085", "Pescara",
"390445", "Vicenza",
"390732", "Ancona",
"390521", "Parma",
"39015", "Biella",
"390122", "Turin",
"390444", "Vicenza",
"390942", "Catania",
"39070", "Cagliari",
"39035", "Bergamo",
"390322", "Novara",
"390586", "Livorno",
"390925", "Agrigento",
"39059", "Modena",
"39099", "Taranto",
"390523", "Piacenza",
"390783", "Oristano",
"390343", "Sondrio",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;