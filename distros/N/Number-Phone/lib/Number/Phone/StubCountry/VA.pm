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
our $VERSION = 1.20201204215957;

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
$areanames{en} = {"390541", "Rimini",
"390832", "Lecce",
"390732", "Ancona",
"390373", "Cremona",
"390341", "Lecco",
"390783", "Oristano",
"390125", "Turin",
"390422", "Treviso",
"390933", "Caltanissetta",
"390161", "Vercelli",
"390883", "Andria\ Barletta\ Trani",
"390922", "Agrigento",
"390171", "Cuneo",
"390549", "San\ Marino",
"390823", "Caserta",
"390363", "Bergamo",
"390185", "Genoa",
"3906", "Rome",
"390884", "Foggia",
"39095", "Catania",
"390934", "Caltanissetta\ and\ Enna",
"390575", "Arezzo",
"390574", "Prato",
"390942", "Catania",
"39049", "Padova",
"39099", "Taranto",
"390365", "Brescia",
"390364", "Brescia",
"390183", "Imperia",
"390321", "Novara",
"390825", "Avellino",
"390824", "Benevento",
"39045", "Verona",
"390565", "Livorno",
"390521", "Parma",
"39031", "Como",
"39089", "Salerno",
"390471", "Bolzano\/Bozen",
"39051", "Bologna",
"39079", "Sassari",
"390961", "Catanzaro",
"390925", "Agrigento",
"390924", "Trapani",
"390424", "Vicenza",
"390122", "Turin",
"390425", "Rovigo",
"390461", "Trento",
"390346", "Bergamo",
"390166", "Aosta\ Valley",
"39050", "Pisa",
"39033", "Varese",
"39085", "Pescara",
"390734", "Fermo",
"39030", "Brescia",
"39075", "Perugia",
"390735", "Ascoli\ Piceno",
"3906698", "Vatican\ City",
"39015", "Biella",
"390432", "Udine",
"390362", "Cremona\/Monza",
"390444", "Vicenza",
"390445", "Vicenza",
"390372", "Cremona",
"390733", "Macerata",
"390776", "Frosinone",
"390586", "Livorno",
"390882", "Foggia",
"390423", "Treviso",
"39039", "Monza",
"3902", "Milan",
"390187", "La\ Spezia",
"390965", "Reggio\ Calabria",
"390921", "Palermo",
"39059", "Modena",
"39071", "Ancona",
"39081", "Naples",
"39048", "Gorizia",
"39035", "Bergamo",
"39070", "Cagliari",
"39080", "Bari",
"390731", "Ancona",
"390421", "Venice",
"390342", "Sondrio",
"39055", "Florence",
"390975", "Potenza",
"390974", "Salerno",
"390862", "L\'Aquila",
"390322", "Novara",
"39013", "Alessandria",
"390522", "Reggio\ Emilia",
"39010", "Genoa",
"390963", "Vibo\ Valentia",
"39011", "Turin",
"390382", "Pavia",
"390577", "Siena",
"390376", "Mantua",
"390532", "Ferrara",
"390344", "Como",
"390737", "Macerata",
"390426", "Rovigo",
"390165", "Aosta\ Valley",
"390545", "Ravenna",
"390583", "Lucca",
"390962", "Crotone",
"390523", "Piacenza",
"390543", "Forlì\-Cesena",
"390774", "Rome",
"390585", "Massa\-Carrara",
"390371", "Lodi",
"390874", "Campobasso",
"390343", "Sondrio",
"390881", "Foggia",
"39041", "Venice",
"39090", "Messina",
"39040", "Trieste",
"39091", "Palermo",
"390789", "Sassari",
"390141", "Asti",
"390865", "Isernia",
"390324", "Verbano\-Cusio\-Ossola",};
$areanames{it} = {"390166", "Saint\-Vincent",
"390578", "Chianciano\ Terme",
"390547", "Cesena",
"390424", "Bassano\ del\ Grappa",
"390122", "Susa",
"390924", "Alcamo",
"390925", "Sciacca",
"390438", "Conegliano",
"390983", "Rossano",
"390833", "Gallipoli",
"390587", "Pontedera",
"3906698", "Città\ del\ Vaticano",
"390766", "Civitavecchia",
"390722", "Urbino",
"390362", "Seregno",
"3906", "Roma",
"390185", "Rapallo",
"390184", "Sanremo",
"390363", "Treviglio",
"390549", "Repubblica\ di\ San\ Marino",
"390967", "Soverato",
"390982", "Paola",
"390732", "Fabriano",
"390976", "Muro\ Lucano",
"390536", "Sassuolo",
"390744", "Terni",
"390144", "Acqui\ Terme",
"390442", "Legnago",
"390435", "Pieve\ di\ Cadore",
"390434", "Pordenone",
"390381", "Vigevano",
"390934", "Caltanissetta",
"390885", "Cerignola",
"390884", "Manfredonia",
"390935", "Enna",
"390784", "Nuoro",
"390785", "Macomer",
"390123", "Lanzo\ Torinese",
"390428", "Tarvisio",
"390771", "Formia",
"390942", "Taormina",
"390374", "Soresina",
"390871", "Chieti",
"390375", "Casalmaggiore",
"390121", "Pinerolo",
"390462", "Cavalese",
"390383", "Voghera",
"390165", "Aosta",
"390737", "Camerino",
"390426", "Adria",
"390873", "Vasto",
"390773", "Latina",
"390524", "Fidenza",
"390173", "Alba",
"390525", "Fornovo\ di\ Taro",
"390721", "Pesaro",
"390864", "Sulmona",
"390324", "Domodossola",
"390765", "Poggio\ Mirteto",
"390543", "Forlì",
"39041", "Venezia",
"390343", "Chiavenna",
"390981", "Castrovillari",
"390831", "Brindisi",
"390542", "Imola",
"390731", "Jesi",
"390534", "Porretta\ Terme",
"390535", "Mirandola",
"390974", "Vallo\ della\ Lucania",
"390975", "Sala\ Consilina",
"390746", "Rieti",
"3902", "Milano",
"390172", "Savigliano",
"390474", "Brunico",
"390463", "Cles",
"390376", "Mantova",
"390941", "Patti",
"390872", "Lanciano",
"39010", "Genova",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390436", "Cortina\ d\'Ampezzo",
"390742", "Foligno",
"390971", "Potenza",
"390346", "Clusone",
"390985", "Scalea",
"390331", "Busto\ Arsizio",
"390984", "Cosenza",
"390835", "Matera",
"390735", "San\ Benedetto\ del\ Tronto",
"390546", "Faenza",
"390828", "Battipaglia",
"390182", "Albenga",
"390471", "Bolzano",
"390776", "Cassino",
"39019", "Savona",
"390386", "Ostiglia",
"390882", "San\ Severo",
"390932", "Ragusa",
"390423", "Montebelluna",
"390572", "Montecatini\ Terme",
"390782", "Lanusei",
"390923", "Trapani",
"390445", "Schio",
"390142", "Casale\ Monferrato",
"390966", "Palmi",
"390433", "Tolmezzo",
"390143", "Novi\ Ligure",
"390373", "Crema",
"390124", "Rivarolo\ Canavese",
"390573", "Pistoia",
"390125", "Ivrea",
"390883", "Andria",
"390933", "Caltagirone",
"390364", "Breno",
"390861", "Teramo",
"390365", "Salò",
"390761", "Viterbo",
"390564", "Grosseto",
"390565", "Piombino",
"390743", "Spoleto",
"390763", "Orvieto",
"390323", "Baveno",
"390863", "Avezzano",
"390174", "Mondovì",
"390472", "Bressanone",
"390175", "Saluzzo",
"390344", "Menaggio",
"390345", "San\ Pellegrino\ Terme",
"390972", "Melfi",
"390736", "Ascoli\ Piceno",
"390836", "Maglie",
"390427", "Spilimbergo",
"390544", "Ravenna",
"390332", "Varese",
"390545", "Lugo",
"390789", "Olbia",
"390968", "Lamezia\ Terme",
"390431", "Cervignano\ del\ Friuli",
"390775", "Frosinone",
"390585", "Massa",
"390584", "Viareggio",
"390774", "Tivoli",
"390875", "Termoli",
"390385", "Stradella",
"390384", "Mortara",
"390931", "Siracusa",
"390163", "Borgosesia",
"390781", "Iglesias",
"390571", "Empoli",
"390439", "Feltre",
"390588", "Volterra",
"39055", "Firenze",
"390421", "San\ Donà\ di\ Piave",
"390465", "Tione\ di\ Trento",
"390464", "Rovereto",
"390964", "Locri",
"390965", "Reggio\ di\ Calabria",
"390921", "Cefalù",
"390429", "Este",
"39081", "Napoli",
"390973", "Lagonegro",
"390533", "Comacchio",
"39011", "Torino",
"390377", "Codogno",
"390437", "Belluno",
"390322", "Arona",
"390566", "Follonica",
"390473", "Merano",
"390522", "Reggio\ nell\'Emilia",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;