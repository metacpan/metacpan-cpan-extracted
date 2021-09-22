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
our $VERSION = 1.20210921211833;

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
$areanames{en} = {"39010", "Genoa",
"390577", "Siena",
"39055", "Florence",
"390183", "Imperia",
"390372", "Cremona",
"390735", "Ascoli\ Piceno",
"390574", "Prato",
"390942", "Catania",
"390922", "Agrigento",
"390737", "Macerata",
"390734", "Fermo",
"390575", "Arezzo",
"390921", "Palermo",
"390166", "Aosta\ Valley",
"39045", "Verona",
"390371", "Lodi",
"390865", "Isernia",
"390586", "Livorno",
"390125", "Turin",
"390363", "Bergamo",
"39090", "Messina",
"39089", "Salerno",
"390832", "Lecce",
"390122", "Turin",
"390141", "Asti",
"39079", "Sassari",
"390732", "Ancona",
"390925", "Agrigento",
"390471", "Bolzano\/Bozen",
"39035", "Bergamo",
"390731", "Ancona",
"390924", "Trapani",
"3906698", "Vatican\ City",
"390862", "L\'Aquila",
"390934", "Caltanissetta\ and\ Enna",
"39041", "Venice",
"390343", "Sondrio",
"390161", "Vercelli",
"39051", "Bologna",
"390376", "Mantua",
"390965", "Reggio\ Calabria",
"390962", "Crotone",
"390382", "Pavia",
"390824", "Benevento",
"390825", "Avellino",
"390585", "Massa\-Carrara",
"390961", "Catanzaro",
"390783", "Oristano",
"39070", "Cagliari",
"390165", "Aosta\ Valley",
"39031", "Como",
"390423", "Treviso",
"39033", "Varese",
"39099", "Taranto",
"390883", "Andria\ Barletta\ Trani",
"390523", "Piacenza",
"390543", "Forlì\-Cesena",
"39080", "Bari",
"390522", "Reggio\ Emilia",
"390974", "Salerno",
"39071", "Ancona",
"390882", "Foggia",
"390344", "Como",
"390324", "Verbano\-Cusio\-Ossola",
"39095", "Catania",
"390933", "Caltanissetta",
"390421", "Venice",
"390881", "Foggia",
"390521", "Parma",
"390541", "Rimini",
"390975", "Potenza",
"390422", "Treviso",
"3902", "Milan",
"390171", "Cuneo",
"39081", "Naples",
"390963", "Vibo\ Valentia",
"39030", "Brescia",
"390583", "Lucca",
"39015", "Biella",
"39050", "Pisa",
"390823", "Caserta",
"390549", "San\ Marino",
"39040", "Trieste",
"390545", "Ravenna",
"390321", "Novara",
"390341", "Lecco",
"390444", "Vicenza",
"390424", "Vicenza",
"390884", "Foggia",
"390322", "Novara",
"390342", "Sondrio",
"390789", "Sassari",
"390776", "Frosinone",
"390425", "Rovigo",
"390445", "Vicenza",
"390187", "La\ Spezia",
"39039", "Monza",
"390426", "Rovigo",
"390733", "Macerata",
"39075", "Perugia",
"390185", "Genoa",
"39091", "Palermo",
"390774", "Rome",
"390565", "Livorno",
"3906", "Rome",
"39085", "Pescara",
"390874", "Campobasso",
"390362", "Cremona\/Monza",
"390461", "Trento",
"39048", "Gorizia",
"390364", "Brescia",
"39013", "Alessandria",
"39011", "Turin",
"390365", "Brescia",
"390432", "Udine",
"390346", "Bergamo",
"39049", "Padova",
"39059", "Modena",
"390373", "Cremona",
"390532", "Ferrara",};
$areanames{it} = {"390933", "Caltagirone",
"390588", "Volterra",
"390828", "Battipaglia",
"390442", "Legnago",
"390782", "Lanusei",
"39081", "Napoli",
"390172", "Savigliano",
"390785", "Macomer",
"390174", "Mondovì",
"390175", "Saluzzo",
"390784", "Nuoro",
"390549", "Repubblica\ di\ San\ Marino",
"390971", "Potenza",
"390743", "Spoleto",
"390424", "Bassano\ del\ Grappa",
"390436", "Cortina\ d\'Ampezzo",
"390547", "Cesena",
"390445", "Schio",
"390435", "Pieve\ di\ Cadore",
"390573", "Pistoia",
"390426", "Adria",
"390434", "Pordenone",
"390331", "Busto\ Arsizio",
"390763", "Orvieto",
"390464", "Rovereto",
"390875", "Termoli",
"390465", "Tione\ di\ Trento",
"390982", "Paola",
"390984", "Cosenza",
"390872", "Lanciano",
"390462", "Cavalese",
"390985", "Scalea",
"39011", "Torino",
"390373", "Crema",
"390923", "Trapani",
"390771", "Formia",
"39055", "Firenze",
"390533", "Comacchio",
"390864", "Sulmona",
"390773", "Latina",
"390737", "Camerino",
"390474", "Brunico",
"390166", "Saint\-Vincent",
"390941", "Patti",
"390921", "Cefalù",
"390125", "Ivrea",
"390835", "Matera",
"390144", "Acqui\ Terme",
"390124", "Rivarolo\ Canavese",
"390438", "Conegliano",
"390363", "Treviglio",
"390122", "Susa",
"390142", "Casale\ Monferrato",
"390761", "Viterbo",
"390386", "Ostiglia",
"390472", "Bressanone",
"390571", "Empoli",
"390377", "Codogno",
"3906698", "Città\ del\ Vaticano",
"390731", "Jesi",
"390721", "Pesaro",
"39041", "Venezia",
"390323", "Baveno",
"390343", "Chiavenna",
"390973", "Lagonegro",
"390385", "Stradella",
"390384", "Mortara",
"390428", "Tarvisio",
"39019", "Savona",
"390967", "Soverato",
"390584", "Viareggio",
"390585", "Massa",
"390836", "Maglie",
"390931", "Siracusa",
"390165", "Aosta",
"390543", "Forlì",
"390883", "Andria",
"390882", "San\ Severo",
"390324", "Domodossola",
"390344", "Menaggio",
"390974", "Vallo\ della\ Lucania",
"390542", "Imola",
"390522", "Reggio\ nell\'Emilia",
"390421", "San\ Donà\ di\ Piave",
"390975", "Sala\ Consilina",
"390345", "San\ Pellegrino\ Terme",
"3902", "Milano",
"390781", "Iglesias",
"390383", "Voghera",
"390429", "Este",
"390566", "Follonica",
"390885", "Cerignola",
"390427", "Spilimbergo",
"390536", "Sassuolo",
"390968", "Lamezia\ Terme",
"390545", "Lugo",
"390525", "Fornovo\ di\ Taro",
"390789", "Olbia",
"390972", "Melfi",
"390776", "Cassino",
"390524", "Fidenza",
"390544", "Ravenna",
"390322", "Arona",
"390884", "Manfredonia",
"390163", "Borgosesia",
"390863", "Avezzano",
"390184", "Sanremo",
"390332", "Varese",
"390534", "Porretta\ Terme",
"390775", "Frosinone",
"390774", "Tivoli",
"390535", "Mirandola",
"390546", "Faenza",
"390473", "Merano",
"390437", "Belluno",
"390185", "Rapallo",
"390981", "Castrovillari",
"390565", "Piombino",
"390439", "Feltre",
"3906", "Roma",
"390833", "Gallipoli",
"390123", "Lanzo\ Torinese",
"390143", "Novi\ Ligure",
"390362", "Seregno",
"390564", "Grosseto",
"390364", "Breno",
"390365", "Salò",
"390871", "Chieti",
"390578", "Chianciano\ Terme",
"390346", "Clusone",
"390976", "Muro\ Lucano",
"390431", "Cervignano\ del\ Friuli",
"390182", "Albenga",
"39010", "Genova",
"390942", "Taormina",
"390746", "Rieti",
"390735", "San\ Benedetto\ del\ Tronto",
"390433", "Tolmezzo",
"390463", "Cles",
"390873", "Vasto",
"390765", "Poggio\ Mirteto",
"390983", "Rossano",
"390966", "Palmi",
"390831", "Brindisi",
"390121", "Pinerolo",
"390925", "Sciacca",
"390732", "Fabriano",
"390375", "Casalmaggiore",
"390861", "Teramo",
"390471", "Bolzano",
"390374", "Soresina",
"390924", "Alcamo",
"390572", "Montecatini\ Terme",
"390934", "Caltanissetta",
"390376", "Mantova",
"390742", "Foligno",
"390722", "Urbino",
"390935", "Enna",
"390965", "Reggio\ di\ Calabria",
"390964", "Locri",
"390766", "Civitavecchia",
"390587", "Pontedera",
"390173", "Alba",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390381", "Vigevano",
"390744", "Terni",
"390423", "Montebelluna",
"390932", "Ragusa",
"390736", "Ascoli\ Piceno",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;