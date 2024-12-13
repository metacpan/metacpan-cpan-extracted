# automatically generated file, don't edit



# Copyright 2024 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20241212130807;

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
$areanames{it} = {"390932", "Ragusa",
"390972", "Melfi",
"390774", "Tivoli",
"390323", "Baveno",
"390941", "Patti",
"390588", "Volterra",
"390981", "Castrovillari",
"390722", "Urbino",
"390462", "Cavalese",
"390924", "Alcamo",
"3902", "Milano",
"390835", "Matera",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390875", "Termoli",
"390525", "Fornovo\ di\ Taro",
"390584", "Viareggio",
"390763", "Orvieto",
"390423", "Montebelluna",
"390985", "Scalea",
"390123", "Lanzo\ Torinese",
"390544", "Ravenna",
"390831", "Brindisi",
"390871", "Chieti",
"390566", "Follonica",
"390362", "Seregno",
"390882", "San\ Severo",
"390143", "Novi\ Ligure",
"390925", "Sciacca",
"390524", "Fidenza",
"390775", "Frosinone",
"390735", "San\ Benedetto\ del\ Tronto",
"390572", "Montecatini\ Terme",
"390376", "Mantova",
"390343", "Chiavenna",
"390921", "Cefalù",
"390966", "Palmi",
"390383", "Voghera",
"390863", "Avezzano",
"390585", "Massa",
"390789", "Olbia",
"390782", "Lanusei",
"390984", "Cosenza",
"390742", "Foligno",
"390545", "Lugo",
"390771", "Formia",
"390436", "Cortina\ d\'Ampezzo",
"390731", "Jesi",
"390533", "Comacchio",
"390573", "Pistoia",
"390776", "Cassino",
"390431", "Cervignano\ del\ Friuli",
"390471", "Bolzano",
"390736", "Ascoli\ Piceno",
"390182", "Albenga",
"390442", "Legnago",
"390142", "Casale\ Monferrato",
"390375", "Casalmaggiore",
"390564", "Grosseto",
"390965", "Reggio\ di\ Calabria",
"3906", "Roma",
"390743", "Spoleto",
"390175", "Saluzzo",
"390331", "Busto\ Arsizio",
"390546", "Faenza",
"390435", "Pieve\ di\ Cadore",
"390427", "Spilimbergo",
"390163", "Borgosesia",
"390463", "Cles",
"390438", "Conegliano",
"390374", "Soresina",
"390933", "Caltagirone",
"390973", "Lagonegro",
"390968", "Lamezia\ Terme",
"390322", "Arona",
"390836", "Maglie",
"390174", "Mondovì",
"390363", "Treviglio",
"390883", "Andria",
"390474", "Brunico",
"390434", "Pordenone",
"390565", "Piombino",
"390429", "Este",
"390964", "Locri",
"390122", "Susa",
"390983", "Rossano",
"390765", "Poggio\ Mirteto",
"390437", "Belluno",
"390125", "Ivrea",
"390344", "Menaggio",
"390864", "Sulmona",
"390384", "Mortara",
"390967", "Soverato",
"39081", "Napoli",
"390166", "Saint\-Vincent",
"390121", "Pinerolo",
"390377", "Codogno",
"390421", "San\ Donà\ di\ Piave",
"390761", "Viterbo",
"390976", "Muro\ Lucano",
"390184", "Sanremo",
"390144", "Acqui\ Terme",
"390873", "Vasto",
"390833", "Gallipoli",
"390172", "Savigliano",
"390345", "San\ Pellegrino\ Terme",
"390746", "Rieti",
"390385", "Stradella",
"390439", "Feltre",
"390472", "Bressanone",
"390424", "Bassano\ del\ Grappa",
"390124", "Rivarolo\ Canavese",
"390543", "Forlì",
"390445", "Schio",
"390185", "Rapallo",
"390861", "Teramo",
"390381", "Vigevano",
"390536", "Sassuolo",
"390923", "Trapani",
"390332", "Varese",
"390773", "Latina",
"390428", "Tarvisio",
"390324", "Domodossola",
"39019", "Savona",
"39041", "Venezia",
"39010", "Genova",
"390346", "Clusone",
"390785", "Macomer",
"390549", "Repubblica\ di\ San\ Marino",
"390571", "Empoli",
"390386", "Ostiglia",
"39011", "Torino",
"390542", "Imola",
"390173", "Alba",
"390884", "Manfredonia",
"390364", "Breno",
"390473", "Merano",
"390433", "Tolmezzo",
"390732", "Fabriano",
"390934", "Caltanissetta",
"390974", "Vallo\ della\ Lucania",
"390535", "Mirandola",
"390781", "Iglesias",
"390464", "Rovereto",
"390373", "Crema",
"390547", "Cesena",
"390426", "Adria",
"390766", "Civitavecchia",
"390721", "Pesaro",
"3906698", "Città\ del\ Vaticano",
"390885", "Cerignola",
"390587", "Pontedera",
"390365", "Salò",
"390828", "Battipaglia",
"390578", "Chianciano\ Terme",
"390982", "Paola",
"390784", "Nuoro",
"390744", "Terni",
"390942", "Taormina",
"390971", "Potenza",
"390931", "Siracusa",
"39055", "Firenze",
"390165", "Aosta",
"390737", "Camerino",
"390465", "Tione\ di\ Trento",
"390872", "Lanciano",
"390522", "Reggio\ nell\'Emilia",
"390975", "Sala\ Consilina",
"390935", "Enna",
"390534", "Porretta\ Terme",};
$areanames{en} = {"390774", "Rome",
"390734", "Fermo",
"390425", "Rovigo",
"390321", "Novara",
"390125", "Turin",
"39048", "Gorizia",
"39075", "Perugia",
"390344", "Como",
"390924", "Trapani",
"390577", "Siena",
"3902", "Milan",
"39081", "Naples",
"390423", "Treviso",
"390166", "Aosta\ Valley",
"390421", "Venice",
"39080", "Bari",
"390521", "Parma",
"390444", "Vicenza",
"390362", "Cremona\/Monza",
"390882", "Foggia",
"39099", "Taranto",
"390523", "Piacenza",
"390183", "Imperia",
"390141", "Asti",
"390925", "Agrigento",
"390865", "Isernia",
"390874", "Campobasso",
"390432", "Udine",
"390735", "Ascoli\ Piceno",
"39039", "Monza",
"390541", "Rimini",
"390583", "Lucca",
"390424", "Vicenza",
"390532", "Ferrara",
"390962", "Crotone",
"39085", "Pescara",
"390543", "Forlì\-Cesena",
"390376", "Mantua",
"39070", "Cagliari",
"390921", "Palermo",
"390343", "Sondrio",
"390185", "Genoa",
"390445", "Vicenza",
"39059", "Modena",
"390341", "Lecco",
"390372", "Cremona",
"39071", "Ancona",
"390789", "Sassari",
"39049", "Padova",
"390585", "Massa\-Carrara",
"390733", "Macerata",
"390324", "Verbano\-Cusio\-Ossola",
"390731", "Ancona",
"390545", "Ravenna",
"39010", "Genoa",
"39041", "Venice",
"390346", "Bergamo",
"390823", "Caserta",
"390963", "Vibo\ Valentia",
"390961", "Catanzaro",
"390549", "San\ Marino",
"39011", "Turin",
"39040", "Trieste",
"390471", "Bolzano\/Bozen",
"390776", "Frosinone",
"39050", "Pisa",
"390884", "Foggia",
"390364", "Brescia",
"39051", "Bologna",
"39079", "Sassari",
"390171", "Cuneo",
"390974", "Salerno",
"390934", "Caltanissetta\ and\ Enna",
"39031", "Como",
"390732", "Ancona",
"390965", "Reggio\ Calabria",
"390575", "Arezzo",
"390825", "Avellino",
"390783", "Oristano",
"3906", "Rome",
"39030", "Brescia",
"390371", "Lodi",
"390586", "Livorno",
"39095", "Catania",
"390342", "Sondrio",
"390862", "L\'Aquila",
"390382", "Pavia",
"390922", "Agrigento",
"390373", "Cremona",
"39090", "Messina",
"390461", "Trento",
"390426", "Rovigo",
"390365", "Brescia",
"390161", "Vercelli",
"3906698", "Vatican\ City",
"39091", "Palermo",
"39013", "Alessandria",
"39089", "Salerno",
"390933", "Caltanissetta",
"390322", "Novara",
"39035", "Bergamo",
"390942", "Catania",
"390187", "La\ Spezia",
"39055", "Florence",
"39033", "Varese",
"390881", "Foggia",
"390165", "Aosta\ Valley",
"390737", "Macerata",
"390883", "Andria\ Barletta\ Trani",
"390363", "Bergamo",
"390832", "Lecce",
"390522", "Reggio\ Emilia",
"390565", "Livorno",
"390975", "Potenza",
"390574", "Prato",
"390824", "Benevento",
"390422", "Treviso",
"39015", "Biella",
"390122", "Turin",
"39045", "Verona",};
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