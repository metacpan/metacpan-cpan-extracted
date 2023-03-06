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
our $VERSION = 1.20230305170054;

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
$areanames{it} = {"390743", "Spoleto",
"390784", "Nuoro",
"390789", "Olbia",
"390765", "Poggio\ Mirteto",
"390546", "Faenza",
"390473", "Merano",
"390976", "Muro\ Lucano",
"390588", "Volterra",
"390932", "Ragusa",
"390522", "Reggio\ nell\'Emilia",
"390831", "Brindisi",
"390982", "Paola",
"390566", "Follonica",
"390424", "Bassano\ del\ Grappa",
"390376", "Mantova",
"390872", "Lanciano",
"390971", "Potenza",
"390429", "Este",
"390332", "Varese",
"390836", "Maglie",
"390763", "Orvieto",
"390967", "Soverato",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390172", "Savigliano",
"39041", "Venezia",
"390587", "Pontedera",
"390774", "Tivoli",
"390931", "Siracusa",
"390435", "Pieve\ di\ Cadore",
"390578", "Chianciano\ Terme",
"390381", "Vigevano",
"390981", "Castrovillari",
"390882", "San\ Severo",
"390386", "Ostiglia",
"390828", "Battipaglia",
"390871", "Chieti",
"390972", "Melfi",
"390464", "Rovereto",
"390968", "Lamezia\ Terme",
"390331", "Busto\ Arsizio",
"390433", "Tolmezzo",
"390182", "Albenga",
"390542", "Imola",
"390385", "Stradella",
"390173", "Alba",
"390364", "Breno",
"390935", "Enna",
"390525", "Fornovo\ di\ Taro",
"390431", "Cervignano\ del\ Friuli",
"390873", "Vasto",
"390983", "Rossano",
"390721", "Pesaro",
"390383", "Voghera",
"390175", "Saluzzo",
"390427", "Spilimbergo",
"390344", "Menaggio",
"390124", "Rivarolo\ Canavese",
"390933", "Caltagirone",
"390964", "Locri",
"390436", "Cortina\ d\'Ampezzo",
"390472", "Bressanone",
"390875", "Termoli",
"3906", "Roma",
"390737", "Camerino",
"390985", "Scalea",
"390742", "Foligno",
"390565", "Piombino",
"390324", "Domodossola",
"390746", "Rieti",
"39011", "Torino",
"390835", "Matera",
"390144", "Acqui\ Terme",
"390584", "Viareggio",
"390543", "Forlì",
"390375", "Casalmaggiore",
"390973", "Lagonegro",
"390761", "Viterbo",
"390883", "Andria",
"39081", "Napoli",
"390722", "Urbino",
"390545", "Lugo",
"390185", "Rapallo",
"390373", "Crema",
"390766", "Civitavecchia",
"390833", "Gallipoli",
"390864", "Sulmona",
"390975", "Sala\ Consilina",
"390471", "Bolzano",
"390428", "Tarvisio",
"390534", "Porretta\ Terme",
"390924", "Alcamo",
"390885", "Cerignola",
"390775", "Frosinone",
"390377", "Codogno",
"390463", "Cles",
"390445", "Schio",
"390941", "Patti",
"390346", "Clusone",
"390322", "Arona",
"390571", "Empoli",
"390439", "Feltre",
"390434", "Pordenone",
"390966", "Palmi",
"390142", "Casale\ Monferrato",
"390465", "Tione\ di\ Trento",
"390547", "Cesena",
"390773", "Latina",
"390121", "Pinerolo",
"390785", "Macomer",
"390942", "Taormina",
"390423", "Montebelluna",
"390166", "Saint\-Vincent",
"390536", "Sassuolo",
"390572", "Montecatini\ Terme",
"390362", "Seregno",
"390861", "Teramo",
"390474", "Brunico",
"39019", "Savona",
"3902", "Milano",
"390921", "Cefalù",
"390744", "Terni",
"390122", "Susa",
"390735", "San\ Benedetto\ del\ Tronto",
"390374", "Soresina",
"390585", "Massa",
"390163", "Borgosesia",
"390564", "Grosseto",
"390426", "Adria",
"390923", "Trapani",
"390533", "Comacchio",
"390781", "Iglesias",
"390442", "Legnago",
"390736", "Ascoli\ Piceno",
"390863", "Avezzano",
"390437", "Belluno",
"390731", "Jesi",
"390184", "Sanremo",
"390544", "Ravenna",
"390143", "Novi\ Ligure",
"390549", "Repubblica\ di\ San\ Marino",
"390323", "Baveno",
"39010", "Genova",
"390165", "Aosta",
"39055", "Firenze",
"390884", "Manfredonia",
"390535", "Mirandola",
"390925", "Sciacca",
"390421", "San\ Donà\ di\ Piave",
"390974", "Vallo\ della\ Lucania",
"390462", "Cavalese",
"390934", "Caltanissetta",
"390524", "Fidenza",
"390438", "Conegliano",
"390365", "Salò",
"390123", "Lanzo\ Torinese",
"3906698", "Città\ del\ Vaticano",
"390343", "Chiavenna",
"390384", "Mortara",
"390782", "Lanusei",
"390771", "Formia",
"390732", "Fabriano",
"390363", "Treviglio",
"390125", "Ivrea",
"390776", "Cassino",
"390345", "San\ Pellegrino\ Terme",
"390573", "Pistoia",
"390174", "Mondovì",
"390984", "Cosenza",
"390965", "Reggio\ di\ Calabria",};
$areanames{en} = {"39091", "Palermo",
"39095", "Catania",
"390364", "Brescia",
"390426", "Rovigo",
"390585", "Massa\-Carrara",
"390574", "Prato",
"390974", "Salerno",
"390824", "Benevento",
"39080", "Bari",
"390865", "Isernia",
"390884", "Foggia",
"39013", "Alessandria",
"3906", "Rome",
"390737", "Macerata",
"390421", "Venice",
"390925", "Agrigento",
"39010", "Genoa",
"390165", "Aosta\ Valley",
"390549", "San\ Marino",
"39035", "Bergamo",
"390523", "Piacenza",
"390933", "Caltanissetta",
"39055", "Florence",
"390731", "Ancona",
"390344", "Como",
"39051", "Bologna",
"39031", "Como",
"390583", "Lucca",
"390963", "Vibo\ Valentia",
"390883", "Andria\ Barletta\ Trani",
"39033", "Varese",
"39081", "Naples",
"390823", "Caserta",
"39085", "Pescara",
"390432", "Udine",
"390575", "Arezzo",
"390343", "Sondrio",
"39011", "Turin",
"390183", "Imperia",
"390543", "Forlì\-Cesena",
"390324", "Verbano\-Cusio\-Ossola",
"390565", "Livorno",
"39050", "Pisa",
"3906698", "Vatican\ City",
"39015", "Biella",
"39030", "Brescia",
"39079", "Sassari",
"390365", "Brescia",
"390934", "Caltanissetta\ and\ Enna",
"390924", "Trapani",
"390874", "Campobasso",
"390461", "Trento",
"390965", "Reggio\ Calabria",
"39090", "Messina",
"390825", "Avellino",
"390975", "Potenza",
"390422", "Treviso",
"390471", "Bolzano\/Bozen",
"390185", "Genoa",
"390373", "Cremona",
"390545", "Ravenna",
"39049", "Padova",
"390125", "Turin",
"390363", "Bergamo",
"390732", "Ancona",
"390776", "Frosinone",
"390382", "Pavia",
"390371", "Lodi",
"390322", "Novara",
"390522", "Reggio\ Emilia",
"390789", "Sassari",
"39048", "Gorizia",
"39070", "Cagliari",
"39039", "Monza",
"390346", "Bergamo",
"390445", "Vicenza",
"39059", "Modena",
"390577", "Siena",
"39099", "Taranto",
"390341", "Lecco",
"390734", "Fermo",
"390541", "Rimini",
"390532", "Ferrara",
"390922", "Agrigento",
"390376", "Mantua",
"390881", "Foggia",
"390862", "L\'Aquila",
"39040", "Trieste",
"390961", "Catanzaro",
"390187", "La\ Spezia",
"390424", "Vicenza",
"390733", "Macerata",
"390362", "Cremona\/Monza",
"390141", "Asti",
"390321", "Novara",
"390372", "Cremona",
"390832", "Lecce",
"390521", "Parma",
"390942", "Catania",
"390166", "Aosta\ Valley",
"390423", "Treviso",
"39045", "Verona",
"390774", "Rome",
"39041", "Venice",
"390444", "Vicenza",
"390735", "Ascoli\ Piceno",
"390171", "Cuneo",
"390122", "Turin",
"390342", "Sondrio",
"39089", "Salerno",
"390161", "Vercelli",
"39071", "Ancona",
"390425", "Rovigo",
"390921", "Palermo",
"390783", "Oristano",
"390882", "Foggia",
"390962", "Crotone",
"3902", "Milan",
"390586", "Livorno",
"39075", "Perugia",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ country_code => '39', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;