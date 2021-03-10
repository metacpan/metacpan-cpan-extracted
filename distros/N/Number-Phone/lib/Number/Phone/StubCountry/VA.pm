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
our $VERSION = 1.20210309172133;

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
            0878\\d\\d|
            89(?:
              2|
              4[5-9]\\d
            )
          )\\d{3}|
          89[45][0-4]\\d\\d|
          (?:
            1(?:
              44|
              6[346]
            )|
            89(?:
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
$areanames{it} = {"390374", "Soresina",
"390185", "Rapallo",
"390966", "Palmi",
"390789", "Olbia",
"390934", "Caltanissetta",
"390578", "Chianciano\ Terme",
"390429", "Este",
"390549", "Repubblica\ di\ San\ Marino",
"390722", "Urbino",
"390942", "Taormina",
"390965", "Reggio\ di\ Calabria",
"390971", "Potenza",
"390182", "Albenga",
"390331", "Busto\ Arsizio",
"390967", "Soverato",
"390438", "Conegliano",
"390774", "Tivoli",
"390983", "Rossano",
"390166", "Saint\-Vincent",
"390985", "Scalea",
"390525", "Fornovo\ di\ Taro",
"390434", "Pordenone",
"390462", "Cavalese",
"390445", "Schio",
"390143", "Novi\ Ligure",
"390323", "Baveno",
"390522", "Reggio\ nell\'Emilia",
"390831", "Brindisi",
"390465", "Tione\ di\ Trento",
"390142", "Casale\ Monferrato",
"390471", "Bolzano",
"390442", "Legnago",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390322", "Arona",
"390165", "Aosta",
"390463", "Cles",
"390163", "Borgosesia",
"390731", "Jesi",
"390982", "Paola",
"390732", "Fabriano",
"390836", "Maglie",
"390981", "Castrovillari",
"390736", "Ascoli\ Piceno",
"390172", "Savigliano",
"390864", "Sulmona",
"390472", "Bressanone",
"390835", "Matera",
"390384", "Mortara",
"390833", "Gallipoli",
"390173", "Alba",
"390473", "Merano",
"390584", "Viareggio",
"390175", "Saluzzo",
"3902", "Milano",
"390924", "Alcamo",
"390588", "Volterra",
"390735", "San\ Benedetto\ del\ Tronto",
"390439", "Feltre",
"39019", "Savona",
"390744", "Terni",
"390364", "Breno",
"390332", "Varese",
"390976", "Muro\ Lucano",
"390564", "Grosseto",
"39011", "Torino",
"39041", "Venezia",
"390721", "Pesaro",
"390536", "Sassuolo",
"390972", "Melfi",
"390737", "Camerino",
"390941", "Patti",
"390428", "Tarvisio",
"390975", "Sala\ Consilina",
"390973", "Lagonegro",
"390784", "Nuoro",
"390535", "Mirandola",
"390124", "Rivarolo\ Canavese",
"390344", "Menaggio",
"390424", "Bassano\ del\ Grappa",
"390533", "Comacchio",
"390884", "Manfredonia",
"390544", "Ravenna",
"390464", "Rovereto",
"390377", "Codogno",
"390872", "Lanciano",
"390776", "Cassino",
"390381", "Vigevano",
"39055", "Firenze",
"390436", "Cortina\ d\'Ampezzo",
"390921", "Cefalù",
"390761", "Viterbo",
"390775", "Frosinone",
"390773", "Latina",
"390984", "Cosenza",
"390144", "Acqui\ Terme",
"390875", "Termoli",
"390861", "Teramo",
"390324", "Domodossola",
"390873", "Vasto",
"390524", "Fidenza",
"390433", "Tolmezzo",
"390435", "Pieve\ di\ Cadore",
"390781", "Iglesias",
"390964", "Locri",
"390932", "Ragusa",
"390376", "Mantova",
"39081", "Napoli",
"390572", "Montecatini\ Terme",
"390437", "Belluno",
"390421", "San\ Donà\ di\ Piave",
"390968", "Lamezia\ Terme",
"390121", "Pinerolo",
"390184", "Sanremo",
"390573", "Pistoia",
"390375", "Casalmaggiore",
"390373", "Crema",
"390828", "Battipaglia",
"390935", "Enna",
"390933", "Caltagirone",
"390974", "Vallo\ della\ Lucania",
"390566", "Follonica",
"390785", "Macomer",
"390883", "Andria",
"39010", "Genova",
"390543", "Forlì",
"390885", "Cerignola",
"390545", "Lugo",
"390123", "Lanzo\ Torinese",
"390423", "Montebelluna",
"390343", "Chiavenna",
"390534", "Porretta\ Terme",
"390125", "Ivrea",
"390362", "Seregno",
"390345", "San\ Pellegrino\ Terme",
"390565", "Piombino",
"390882", "San\ Severo",
"390571", "Empoli",
"390542", "Imola",
"390363", "Treviglio",
"390587", "Pontedera",
"390122", "Susa",
"390365", "Salò",
"390546", "Faenza",
"390782", "Lanusei",
"390426", "Adria",
"390346", "Clusone",
"390931", "Siracusa",
"390766", "Civitavecchia",
"3906", "Roma",
"390174", "Mondovì",
"3906698", "Città\ del\ Vaticano",
"390585", "Massa",
"390474", "Brunico",
"390383", "Voghera",
"390385", "Stradella",
"390743", "Spoleto",
"390925", "Sciacca",
"390923", "Trapani",
"390763", "Orvieto",
"390771", "Formia",
"390765", "Poggio\ Mirteto",
"390742", "Foligno",
"390386", "Ostiglia",
"390863", "Avezzano",
"390746", "Rieti",
"390871", "Chieti",
"390427", "Spilimbergo",
"390431", "Cervignano\ del\ Friuli",
"390547", "Cesena",};
$areanames{en} = {"390125", "Turin",
"390362", "Cremona\/Monza",
"390321", "Novara",
"390141", "Asti",
"39095", "Catania",
"390425", "Rovigo",
"390343", "Sondrio",
"390423", "Treviso",
"390521", "Parma",
"390545", "Ravenna",
"390883", "Andria\ Barletta\ Trani",
"39010", "Genoa",
"390832", "Lecce",
"390543", "Forlì\-Cesena",
"39040", "Trieste",
"39013", "Alessandria",
"39091", "Palermo",
"390783", "Oristano",
"390974", "Salerno",
"390732", "Ancona",
"390346", "Bergamo",
"390426", "Rovigo",
"39048", "Gorizia",
"39049", "Padova",
"390733", "Macerata",
"390924", "Trapani",
"390735", "Ascoli\ Piceno",
"390161", "Vercelli",
"390371", "Lodi",
"390122", "Turin",
"390365", "Brescia",
"3902", "Milan",
"390342", "Sondrio",
"390422", "Treviso",
"390461", "Trento",
"390363", "Bergamo",
"390565", "Livorno",
"390882", "Foggia",
"39045", "Verona",
"390925", "Agrigento",
"390734", "Fermo",
"39015", "Biella",
"390737", "Macerata",
"39090", "Messina",
"39011", "Turin",
"39041", "Venice",
"390364", "Brescia",
"390862", "L\'Aquila",
"3906698", "Vatican\ City",
"390585", "Massa\-Carrara",
"390583", "Lucca",
"390532", "Ferrara",
"3906", "Rome",
"390382", "Pavia",
"390884", "Foggia",
"390865", "Isernia",
"390344", "Como",
"390424", "Vicenza",
"39099", "Taranto",
"390975", "Potenza",
"390922", "Agrigento",
"390961", "Catanzaro",
"390586", "Livorno",
"39035", "Bergamo",
"390549", "San\ Marino",
"39070", "Cagliari",
"390962", "Crotone",
"390921", "Palermo",
"39055", "Florence",
"390934", "Caltanissetta\ and\ Enna",
"390432", "Udine",
"390789", "Sassari",
"39080", "Bari",
"390183", "Imperia",
"390185", "Genoa",
"390577", "Siena",
"39031", "Como",
"390574", "Prato",
"390823", "Caserta",
"390776", "Frosinone",
"39051", "Bologna",
"390825", "Avellino",
"39079", "Sassari",
"390324", "Verbano\-Cusio\-Ossola",
"390444", "Vicenza",
"390942", "Catania",
"390965", "Reggio\ Calabria",
"39089", "Salerno",
"390963", "Vibo\ Valentia",
"39050", "Pisa",
"390421", "Venice",
"390341", "Lecco",
"390445", "Vicenza",
"390874", "Campobasso",
"390372", "Cremona",
"39075", "Perugia",
"39030", "Brescia",
"390523", "Piacenza",
"390541", "Rimini",
"390881", "Foggia",
"39081", "Naples",
"390376", "Mantua",
"390166", "Aosta\ Valley",
"39033", "Varese",
"390774", "Rome",
"39085", "Pescara",
"39071", "Ancona",
"390933", "Caltanissetta",
"39059", "Modena",
"390731", "Ancona",
"39039", "Monza",
"390373", "Cremona",
"390471", "Bolzano\/Bozen",
"390322", "Novara",
"390824", "Benevento",
"390171", "Cuneo",
"390165", "Aosta\ Valley",
"390575", "Arezzo",
"390187", "La\ Spezia",
"390522", "Reggio\ Emilia",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;