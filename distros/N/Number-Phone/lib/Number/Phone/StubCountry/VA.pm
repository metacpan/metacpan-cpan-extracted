# automatically generated file, don't edit



# Copyright 2025 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20250605193637;

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
$areanames{it} = {"390766", "Civitavecchia",
"390732", "Fabriano",
"390365", "Salò",
"390442", "Legnago",
"390125", "Ivrea",
"390967", "Soverato",
"390324", "Domodossola",
"390931", "Siracusa",
"390566", "Follonica",
"390921", "Cefalù",
"390522", "Reggio\ nell\'Emilia",
"390828", "Battipaglia",
"390474", "Brunico",
"390722", "Urbino",
"390761", "Viterbo",
"390533", "Comacchio",
"390737", "Camerino",
"390546", "Faenza",
"390746", "Rieti",
"390376", "Mantova",
"390421", "San\ Donà\ di\ Piave",
"390144", "Acqui\ Terme",
"390775", "Frosinone",
"39041", "Venezia",
"390345", "San\ Pellegrino\ Terme",
"390184", "Sanremo",
"390173", "Alba",
"390436", "Cortina\ d\'Ampezzo",
"390385", "Stradella",
"390983", "Rossano",
"390974", "Vallo\ della\ Lucania",
"390462", "Cavalese",
"390871", "Chieti",
"390431", "Cervignano\ del\ Friuli",
"390781", "Iglesias",
"390426", "Adria",
"390885", "Cerignola",
"390172", "Savigliano",
"390982", "Paola",
"390463", "Cles",
"390942", "Taormina",
"390763", "Orvieto",
"390966", "Palmi",
"390932", "Ragusa",
"390364", "Breno",
"390165", "Aosta",
"390731", "Jesi",
"390923", "Trapani",
"390835", "Matera",
"390124", "Rivarolo\ Canavese",
"390721", "Pesaro",
"390736", "Ascoli\ Piceno",
"390933", "Caltagirone",
"3906", "Roma",
"390864", "Sulmona",
"390536", "Sassuolo",
"390543", "Forlì",
"390377", "Codogno",
"390439", "Feltre",
"390437", "Belluno",
"390578", "Chianciano\ Terme",
"390789", "Olbia",
"390872", "Lanciano",
"390185", "Rapallo",
"390547", "Cesena",
"390373", "Crema",
"390384", "Mortara",
"390743", "Spoleto",
"390975", "Sala\ Consilina",
"390549", "Repubblica\ di\ San\ Marino",
"390433", "Tolmezzo",
"390344", "Menaggio",
"390774", "Tivoli",
"390587", "Pontedera",
"390981", "Castrovillari",
"3902", "Milano",
"390884", "Manfredonia",
"390873", "Vasto",
"390941", "Patti",
"390423", "Montebelluna",
"390542", "Imola",
"390782", "Lanusei",
"390742", "Foligno",
"390427", "Spilimbergo",
"390429", "Este",
"39019", "Savona",
"390535", "Mirandola",
"390122", "Susa",
"390863", "Avezzano",
"390362", "Seregno",
"390735", "San\ Benedetto\ del\ Tronto",
"390445", "Schio",
"390831", "Brindisi",
"390934", "Caltanissetta",
"390471", "Bolzano",
"390836", "Maglie",
"390564", "Grosseto",
"390924", "Alcamo",
"390331", "Busto\ Arsizio",
"39081", "Napoli",
"390123", "Lanzo\ Torinese",
"390525", "Fornovo\ di\ Taro",
"390166", "Saint\-Vincent",
"390965", "Reggio\ di\ Calabria",
"390363", "Treviglio",
"390465", "Tione\ di\ Trento",
"390572", "Montecatini\ Terme",
"390971", "Potenza",
"390883", "Andria",
"390428", "Tarvisio",
"390424", "Bassano\ del\ Grappa",
"390175", "Saluzzo",
"390744", "Terni",
"390383", "Voghera",
"390374", "Soresina",
"390985", "Scalea",
"3906698", "Città\ del\ Vaticano",
"390434", "Pordenone",
"390976", "Muro\ Lucano",
"390784", "Nuoro",
"390438", "Conegliano",
"390773", "Latina",
"390343", "Chiavenna",
"39010", "Genova",
"390544", "Ravenna",
"390584", "Viareggio",
"390573", "Pistoia",
"390588", "Volterra",
"390882", "San\ Severo",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390534", "Porretta\ Terme",
"390322", "Arona",
"390121", "Pinerolo",
"390935", "Enna",
"39011", "Torino",
"390473", "Merano",
"390925", "Sciacca",
"390833", "Gallipoli",
"390323", "Baveno",
"390565", "Piombino",
"390861", "Teramo",
"390472", "Bressanone",
"390964", "Locri",
"390163", "Borgosesia",
"390968", "Lamezia\ Terme",
"390765", "Poggio\ Mirteto",
"390332", "Varese",
"390524", "Fidenza",
"390182", "Albenga",
"390571", "Empoli",
"390972", "Melfi",
"390464", "Rovereto",
"39055", "Firenze",
"390142", "Casale\ Monferrato",
"390771", "Formia",
"390381", "Vigevano",
"390875", "Termoli",
"390435", "Pieve\ di\ Cadore",
"390386", "Ostiglia",
"390143", "Novi\ Ligure",
"390785", "Macomer",
"390174", "Mondovì",
"390375", "Casalmaggiore",
"390984", "Cosenza",
"390973", "Lagonegro",
"390346", "Clusone",
"390776", "Cassino",
"390585", "Massa",
"390545", "Lugo",};
$areanames{en} = {"39070", "Cagliari",
"390342", "Sondrio",
"390575", "Arezzo",
"390382", "Pavia",
"390586", "Livorno",
"390883", "Andria\ Barletta\ Trani",
"39041", "Venice",
"390874", "Campobasso",
"390421", "Venice",
"39085", "Pescara",
"390376", "Mantua",
"39050", "Pisa",
"39095", "Catania",
"390141", "Asti",
"390424", "Vicenza",
"390974", "Salerno",
"39035", "Bergamo",
"390343", "Sondrio",
"390577", "Siena",
"390426", "Rovigo",
"3906698", "Vatican\ City",
"390371", "Lodi",
"39010", "Genoa",
"390882", "Foggia",
"390541", "Rimini",
"390942", "Catania",
"390122", "Turin",
"390365", "Brescia",
"390732", "Ancona",
"390963", "Vibo\ Valentia",
"390161", "Vercelli",
"390523", "Piacenza",
"390324", "Verbano\-Cusio\-Ossola",
"390735", "Ascoli\ Piceno",
"390362", "Cremona\/Monza",
"390125", "Turin",
"390532", "Ferrara",
"39048", "Gorizia",
"390321", "Novara",
"390934", "Caltanissetta\ and\ Enna",
"39031", "Como",
"390445", "Vicenza",
"390522", "Reggio\ Emilia",
"390824", "Benevento",
"39059", "Modena",
"39091", "Palermo",
"390471", "Bolzano\/Bozen",
"39013", "Alessandria",
"390862", "L\'Aquila",
"390921", "Palermo",
"390733", "Macerata",
"390962", "Crotone",
"39045", "Verona",
"39081", "Naples",
"390924", "Trapani",
"390166", "Aosta\ Valley",
"39079", "Sassari",
"390865", "Isernia",
"390363", "Bergamo",
"390737", "Macerata",
"390965", "Reggio\ Calabria",
"390422", "Treviso",
"39090", "Messina",
"390543", "Forlì\-Cesena",
"39049", "Padova",
"390461", "Trento",
"39080", "Bari",
"390789", "Sassari",
"39055", "Florence",
"390574", "Prato",
"390583", "Lucca",
"390549", "San\ Marino",
"390341", "Lecco",
"390975", "Potenza",
"390425", "Rovigo",
"390373", "Cremona",
"390185", "Genoa",
"390774", "Rome",
"390783", "Oristano",
"390344", "Como",
"39075", "Perugia",
"390884", "Foggia",
"3902", "Milan",
"390171", "Cuneo",
"390346", "Bergamo",
"390776", "Frosinone",
"390881", "Foggia",
"390423", "Treviso",
"39015", "Biella",
"390183", "Imperia",
"390432", "Udine",
"390585", "Massa\-Carrara",
"390187", "La\ Spezia",
"390545", "Ravenna",
"39030", "Brescia",
"390372", "Cremona",
"390165", "Aosta\ Valley",
"390322", "Novara",
"390832", "Lecce",
"390364", "Brescia",
"39039", "Monza",
"39011", "Turin",
"390444", "Vicenza",
"390731", "Ancona",
"390823", "Caserta",
"390734", "Fermo",
"390925", "Agrigento",
"39071", "Ancona",
"390565", "Livorno",
"390933", "Caltanissetta",
"39033", "Varese",
"390825", "Avellino",
"39099", "Taranto",
"39051", "Bologna",
"390521", "Parma",
"3906", "Rome",
"39040", "Trieste",
"390922", "Agrigento",
"39089", "Salerno",
"390961", "Catanzaro",};
my $timezones = {
               '' => [
                       'Europe/Rome',
                       'Europe/Vatican'
                     ],
               '0' => [
                        'Europe/Rome'
                      ],
               '06698' => [
                            'Europe/Vatican'
                          ],
               '0878' => [
                           'Europe/Rome',
                           'Europe/Vatican'
                         ],
               '1' => [
                        'Europe/Rome',
                        'Europe/Vatican'
                      ],
               '3' => [
                        'Europe/Rome',
                        'Europe/Vatican'
                      ],
               '4' => [
                        'Europe/Rome'
                      ],
               '5' => [
                        'Europe/Rome',
                        'Europe/Vatican'
                      ],
               '7' => [
                        'Europe/Rome'
                      ],
               '8' => [
                        'Europe/Rome',
                        'Europe/Vatican'
                      ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+39|\D)//g;
      my $self = bless({ country_code => '39', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;