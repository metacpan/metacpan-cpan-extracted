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
our $VERSION = 1.20210602223301;

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
$areanames{en} = {"39013", "Alessandria",
"390183", "Imperia",
"390372", "Cremona",
"390823", "Caserta",
"390471", "Bolzano\/Bozen",
"390382", "Pavia",
"39081", "Naples",
"390586", "Livorno",
"390574", "Prato",
"390549", "San\ Marino",
"390825", "Avellino",
"39085", "Pescara",
"390187", "La\ Spezia",
"390974", "Salerno",
"390776", "Frosinone",
"390185", "Genoa",
"390774", "Rome",
"390373", "Cremona",
"39033", "Varese",
"39089", "Salerno",
"390862", "L\'Aquila",
"390585", "Massa\-Carrara",
"39080", "Bari",
"390575", "Arezzo",
"390865", "Isernia",
"390577", "Siena",
"390832", "Lecce",
"390783", "Oristano",
"390171", "Cuneo",
"390376", "Mantua",
"390371", "Lodi",
"390583", "Lucca",
"390824", "Benevento",
"390975", "Potenza",
"390965", "Reggio\ Calabria",
"390342", "Sondrio",
"39070", "Cagliari",
"39011", "Turin",
"390432", "Udine",
"3906", "Rome",
"39035", "Bergamo",
"390735", "Ascoli\ Piceno",
"390883", "Andria\ Barletta\ Trani",
"390421", "Venice",
"390732", "Ancona",
"390322", "Novara",
"390921", "Palermo",
"390737", "Macerata",
"3902", "Milan",
"390166", "Aosta\ Valley",
"390962", "Crotone",
"390789", "Sassari",
"39040", "Trieste",
"39039", "Monza",
"39090", "Messina",
"390521", "Parma",
"390161", "Vercelli",
"390364", "Brescia",
"39048", "Gorizia",
"390343", "Sondrio",
"390933", "Caltanissetta",
"390122", "Turin",
"390924", "Trapani",
"390424", "Vicenza",
"390426", "Rovigo",
"39050", "Pisa",
"390882", "Foggia",
"390733", "Macerata",
"390565", "Livorno",
"3906698", "Vatican\ City",
"390541", "Rimini",
"39015", "Biella",
"390125", "Turin",
"390532", "Ferrara",
"390444", "Vicenza",
"39031", "Como",
"390963", "Vibo\ Valentia",
"390934", "Caltanissetta\ and\ Enna",
"390423", "Treviso",
"390881", "Foggia",
"39091", "Palermo",
"390141", "Asti",
"39055", "Florence",
"39041", "Venice",
"390363", "Bergamo",
"390344", "Como",
"390165", "Aosta\ Valley",
"390346", "Bergamo",
"39010", "Genoa",
"39071", "Ancona",
"390522", "Reggio\ Emilia",
"39059", "Modena",
"390324", "Verbano\-Cusio\-Ossola",
"390734", "Fermo",
"390545", "Ravenna",
"39075", "Perugia",
"390543", "Forlì\-Cesena",
"390731", "Ancona",
"390422", "Treviso",
"390321", "Novara",
"390922", "Agrigento",
"39049", "Padova",
"390961", "Catanzaro",
"390362", "Cremona\/Monza",
"39030", "Brescia",
"39099", "Taranto",
"390461", "Trento",
"390445", "Vicenza",
"39079", "Sassari",
"390942", "Catania",
"390341", "Lecco",
"390523", "Piacenza",
"390365", "Brescia",
"390925", "Agrigento",
"39045", "Verona",
"39051", "Bologna",
"390425", "Rovigo",
"39095", "Catania",
"390884", "Foggia",
"390874", "Campobasso",};
$areanames{it} = {"390322", "Arona",
"390732", "Fabriano",
"390421", "San\ Donà\ di\ Piave",
"390935", "Enna",
"390166", "Saint\-Vincent",
"390345", "San\ Pellegrino\ Terme",
"390462", "Cavalese",
"390967", "Soverato",
"390789", "Olbia",
"390465", "Tione\ di\ Trento",
"39011", "Torino",
"390932", "Ragusa",
"390437", "Belluno",
"390735", "San\ Benedetto\ del\ Tronto",
"390882", "San\ Severo",
"390588", "Volterra",
"390872", "Lanciano",
"390578", "Chianciano\ Terme",
"390125", "Ivrea",
"3906698", "Città\ del\ Vaticano",
"390142", "Casale\ Monferrato",
"390364", "Breno",
"390763", "Orvieto",
"390535", "Mirandola",
"39019", "Savona",
"390433", "Tolmezzo",
"390424", "Bassano\ del\ Grappa",
"390122", "Susa",
"390875", "Termoli",
"390426", "Adria",
"390885", "Cerignola",
"390964", "Locri",
"39010", "Genova",
"390522", "Reggio\ nell\'Emilia",
"390828", "Battipaglia",
"390966", "Palmi",
"390545", "Lugo",
"390436", "Cortina\ d\'Ampezzo",
"390542", "Imola",
"390434", "Pordenone",
"390423", "Montebelluna",
"390363", "Treviglio",
"390525", "Fornovo\ di\ Taro",
"390766", "Civitavecchia",
"390761", "Viterbo",
"390942", "Taormina",
"390163", "Borgosesia",
"390925", "Sciacca",
"390332", "Varese",
"390431", "Cervignano\ del\ Friuli",
"390722", "Urbino",
"390564", "Grosseto",
"390427", "Spilimbergo",
"390566", "Follonica",
"390742", "Foligno",
"390836", "Maglie",
"390981", "Castrovillari",
"390377", "Codogno",
"390971", "Potenza",
"390584", "Viareggio",
"390429", "Este",
"390428", "Tarvisio",
"390771", "Formia",
"390173", "Alba",
"390781", "Iglesias",
"390776", "Cassino",
"390373", "Crema",
"390784", "Nuoro",
"390383", "Voghera",
"390774", "Tivoli",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390571", "Empoli",
"390976", "Muro\ Lucano",
"390831", "Brindisi",
"390974", "Vallo\ della\ Lucania",
"390984", "Cosenza",
"390587", "Pontedera",
"390374", "Soresina",
"390384", "Mortara",
"390773", "Latina",
"390386", "Ostiglia",
"390376", "Mantova",
"390973", "Lagonegro",
"390983", "Rossano",
"390573", "Pistoia",
"390833", "Gallipoli",
"390968", "Lamezia\ Terme",
"390184", "Sanremo",
"390472", "Bressanone",
"390381", "Vigevano",
"390174", "Mondovì",
"390438", "Conegliano",
"390439", "Feltre",
"390921", "Cefalù",
"390873", "Vasto",
"390737", "Camerino",
"390883", "Andria",
"390435", "Pieve\ di\ Cadore",
"390524", "Fidenza",
"3902", "Milano",
"390765", "Poggio\ Mirteto",
"390533", "Comacchio",
"390143", "Novi\ Ligure",
"390965", "Reggio\ di\ Calabria",
"390941", "Patti",
"390331", "Busto\ Arsizio",
"390123", "Lanzo\ Torinese",
"3906", "Roma",
"390721", "Pesaro",
"390546", "Faenza",
"390544", "Ravenna",
"390565", "Piombino",
"390323", "Baveno",
"390463", "Cles",
"390746", "Rieti",
"390343", "Chiavenna",
"390744", "Terni",
"390933", "Caltagirone",
"390924", "Alcamo",
"390464", "Rovereto",
"390736", "Ascoli\ Piceno",
"390324", "Domodossola",
"390121", "Pinerolo",
"390547", "Cesena",
"390934", "Caltanissetta",
"390871", "Chieti",
"390923", "Trapani",
"39055", "Firenze",
"39041", "Venezia",
"390344", "Menaggio",
"390743", "Spoleto",
"390165", "Aosta",
"390346", "Clusone",
"390442", "Legnago",
"390536", "Sassuolo",
"390144", "Acqui\ Terme",
"390365", "Salò",
"390534", "Porretta\ Terme",
"390931", "Siracusa",
"390884", "Manfredonia",
"390543", "Forlì",
"390124", "Rivarolo\ Canavese",
"390731", "Jesi",
"390362", "Seregno",
"390445", "Schio",
"390471", "Bolzano",
"39081", "Napoli",
"390864", "Sulmona",
"390375", "Casalmaggiore",
"390385", "Stradella",
"390185", "Rapallo",
"390175", "Saluzzo",
"390861", "Teramo",
"390549", "Repubblica\ di\ San\ Marino",
"390172", "Savigliano",
"390182", "Albenga",
"390474", "Brunico",
"390572", "Montecatini\ Terme",
"390473", "Merano",
"390835", "Matera",
"390585", "Massa",
"390782", "Lanusei",
"390975", "Sala\ Consilina",
"390985", "Scalea",
"390982", "Paola",
"390972", "Melfi",
"390785", "Macomer",
"390775", "Frosinone",
"390863", "Avezzano",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;