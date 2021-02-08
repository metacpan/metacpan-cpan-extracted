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
our $VERSION = 1.20210204173827;

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
$areanames{it} = {"390942", "Taormina",
"390571", "Empoli",
"390464", "Rovereto",
"390123", "Lanzo\ Torinese",
"390744", "Terni",
"390985", "Scalea",
"390143", "Novi\ Ligure",
"390883", "Andria",
"3906", "Roma",
"39055", "Firenze",
"390871", "Chieti",
"390735", "San\ Benedetto\ del\ Tronto",
"390565", "Piombino",
"390736", "Ascoli\ Piceno",
"390721", "Pesaro",
"390566", "Follonica",
"390882", "San\ Severo",
"390427", "Spilimbergo",
"390163", "Borgosesia",
"390534", "Porretta\ Terme",
"390424", "Bassano\ del\ Grappa",
"390776", "Cassino",
"390384", "Mortara",
"390831", "Brindisi",
"390775", "Frosinone",
"390761", "Viterbo",
"39011", "Torino",
"390373", "Crema",
"390185", "Rapallo",
"390421", "San\ Donà\ di\ Piave",
"390436", "Cortina\ d\'Ampezzo",
"390545", "Lugo",
"390923", "Trapani",
"390332", "Varese",
"390525", "Fornovo\ di\ Taro",
"390546", "Faenza",
"390435", "Pieve\ di\ Cadore",
"390381", "Vigevano",
"390122", "Susa",
"390142", "Casale\ Monferrato",
"390784", "Nuoro",
"390931", "Siracusa",
"390472", "Bressanone",
"390375", "Casalmaggiore",
"390543", "Forlì",
"390925", "Sciacca",
"390376", "Mantova",
"390433", "Tolmezzo",
"390364", "Breno",
"390982", "Paola",
"390166", "Saint\-Vincent",
"390934", "Caltanissetta",
"390781", "Iglesias",
"390165", "Aosta",
"390732", "Fabriano",
"390428", "Tarvisio",
"390174", "Mondovì",
"390773", "Latina",
"39081", "Napoli",
"390439", "Feltre",
"390344", "Menaggio",
"390974", "Vallo\ della\ Lucania",
"390885", "Cerignola",
"390324", "Domodossola",
"390549", "Repubblica\ di\ San\ Marino",
"390965", "Reggio\ di\ Calabria",
"3906698", "Città\ del\ Vaticano",
"390966", "Palmi",
"390578", "Chianciano\ Terme",
"390473", "Merano",
"390542", "Imola",
"390182", "Albenga",
"390971", "Potenza",
"390522", "Reggio\ nell\'Emilia",
"390863", "Avezzano",
"390125", "Ivrea",
"390983", "Rossano",
"390585", "Massa",
"390365", "Salò",
"390722", "Urbino",
"390462", "Cavalese",
"390833", "Gallipoli",
"390438", "Conegliano",
"390872", "Lanciano",
"390742", "Foligno",
"390785", "Macomer",
"390374", "Soresina",
"390924", "Alcamo",
"390377", "Codogno",
"390383", "Voghera",
"390175", "Saluzzo",
"390572", "Montecatini\ Terme",
"390921", "Cefalù",
"39019", "Savona",
"390941", "Patti",
"390935", "Enna",
"390763", "Orvieto",
"3902", "Milano",
"390423", "Montebelluna",
"390828", "Battipaglia",
"390533", "Comacchio",
"390964", "Locri",
"39010", "Genova",
"39041", "Venezia",
"390967", "Soverato",
"390121", "Pinerolo",
"390345", "San\ Pellegrino\ Terme",
"390331", "Busto\ Arsizio",
"390573", "Pistoia",
"390884", "Manfredonia",
"390442", "Legnago",
"390975", "Sala\ Consilina",
"390346", "Clusone",
"390976", "Muro\ Lucano",
"390587", "Pontedera",
"390124", "Rivarolo\ Canavese",
"390463", "Cles",
"390743", "Spoleto",
"390873", "Vasto",
"390584", "Viareggio",
"390144", "Acqui\ Terme",
"390429", "Este",
"390362", "Seregno",
"390746", "Rieti",
"390465", "Tione\ di\ Trento",
"390984", "Cosenza",
"390731", "Jesi",
"390875", "Termoli",
"390474", "Brunico",
"390782", "Lanusei",
"390588", "Volterra",
"390864", "Sulmona",
"390981", "Castrovillari",
"390564", "Grosseto",
"390737", "Camerino",
"390172", "Savigliano",
"390343", "Chiavenna",
"390861", "Teramo",
"390973", "Lagonegro",
"390932", "Ragusa",
"390471", "Bolzano",
"390323", "Baveno",
"390968", "Lamezia\ Terme",
"390789", "Olbia",
"390386", "Ostiglia",
"390173", "Alba",
"390385", "Stradella",
"390774", "Tivoli",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390766", "Civitavecchia",
"390431", "Cervignano\ del\ Friuli",
"390972", "Melfi",
"390426", "Adria",
"390536", "Sassuolo",
"390445", "Schio",
"390322", "Arona",
"390765", "Poggio\ Mirteto",
"390933", "Caltagirone",
"390535", "Mirandola",
"390363", "Treviglio",
"390771", "Formia",
"390835", "Matera",
"390836", "Maglie",
"390544", "Ravenna",
"390437", "Belluno",
"390184", "Sanremo",
"390547", "Cesena",
"390434", "Pordenone",
"390524", "Fidenza",};
$areanames{en} = {"390471", "Bolzano\/Bozen",
"390789", "Sassari",
"390732", "Ancona",
"390343", "Sondrio",
"390575", "Arezzo",
"390823", "Caserta",
"39015", "Biella",
"39059", "Modena",
"390737", "Macerata",
"390934", "Caltanissetta\ and\ Enna",
"390165", "Aosta\ Valley",
"390734", "Fermo",
"390166", "Aosta\ Valley",
"39045", "Verona",
"39039", "Monza",
"39089", "Salerno",
"390364", "Brescia",
"390171", "Cuneo",
"390925", "Agrigento",
"390731", "Ancona",
"390862", "L\'Aquila",
"390376", "Mantua",
"390523", "Piacenza",
"390362", "Cremona\/Monza",
"390183", "Imperia",
"390543", "Forlì\-Cesena",
"39051", "Bologna",
"390585", "Massa\-Carrara",
"390187", "La\ Spezia",
"39013", "Alessandria",
"390783", "Oristano",
"39048", "Gorizia",
"390125", "Turin",
"390586", "Livorno",
"39030", "Brescia",
"390341", "Lecco",
"390432", "Udine",
"390522", "Reggio\ Emilia",
"390363", "Bergamo",
"390321", "Novara",
"39080", "Bari",
"390322", "Novara",
"390933", "Caltanissetta",
"390425", "Rovigo",
"39050", "Pisa",
"390541", "Rimini",
"390342", "Sondrio",
"390965", "Reggio\ Calabria",
"390733", "Macerata",
"390426", "Rovigo",
"390445", "Vicenza",
"3906698", "Vatican\ City",
"390521", "Parma",
"390324", "Verbano\-Cusio\-Ossola",
"390549", "San\ Marino",
"39095", "Catania",
"390774", "Rome",
"39031", "Como",
"39075", "Perugia",
"39081", "Naples",
"390344", "Como",
"390974", "Salerno",
"390824", "Benevento",
"39090", "Messina",
"390461", "Trento",
"390423", "Treviso",
"3902", "Milan",
"390371", "Lodi",
"39070", "Cagliari",
"390735", "Ascoli\ Piceno",
"390921", "Palermo",
"390963", "Vibo\ Valentia",
"390565", "Livorno",
"390577", "Siena",
"39055", "Florence",
"390574", "Prato",
"3906", "Rome",
"390883", "Andria\ Barletta\ Trani",
"39049", "Padova",
"390874", "Campobasso",
"39035", "Bergamo",
"390924", "Trapani",
"39091", "Palermo",
"390583", "Lucca",
"39085", "Pescara",
"39071", "Ancona",
"390161", "Vercelli",
"390922", "Agrigento",
"390865", "Isernia",
"390942", "Catania",
"390365", "Brescia",
"390372", "Cremona",
"390881", "Foggia",
"390122", "Turin",
"390961", "Catanzaro",
"39040", "Trieste",
"39011", "Turin",
"390185", "Genoa",
"390832", "Lecce",
"390373", "Cremona",
"390545", "Ravenna",
"390421", "Venice",
"390346", "Bergamo",
"390532", "Ferrara",
"390422", "Treviso",
"390962", "Crotone",
"39033", "Varese",
"390884", "Foggia",
"390825", "Avellino",
"390975", "Potenza",
"390776", "Frosinone",
"39041", "Venice",
"390382", "Pavia",
"39099", "Taranto",
"390424", "Vicenza",
"39079", "Sassari",
"390882", "Foggia",
"390444", "Vicenza",
"390141", "Asti",
"39010", "Genoa",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;