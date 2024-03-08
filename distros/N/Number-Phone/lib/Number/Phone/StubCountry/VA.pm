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
our $VERSION = 1.20240308154353;

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
$areanames{en} = {"39089", "Salerno",
"39090", "Messina",
"390341", "Lecco",
"390185", "Genoa",
"390823", "Caserta",
"390565", "Livorno",
"39015", "Biella",
"390882", "Foggia",
"39080", "Bari",
"39099", "Taranto",
"390324", "Verbano\-Cusio\-Ossola",
"390425", "Rovigo",
"390934", "Caltanissetta\ and\ Enna",
"390732", "Ancona",
"390921", "Palermo",
"390424", "Vicenza",
"39013", "Alessandria",
"390532", "Ferrara",
"390343", "Sondrio",
"390962", "Crotone",
"39075", "Perugia",
"39081", "Naples",
"390862", "L\'Aquila",
"39055", "Florence",
"390585", "Massa\-Carrara",
"390165", "Aosta\ Valley",
"39091", "Palermo",
"390187", "La\ Spezia",
"390321", "Novara",
"390925", "Agrigento",
"390974", "Salerno",
"390122", "Turin",
"390471", "Bolzano\/Bozen",
"390183", "Imperia",
"390825", "Avellino",
"390874", "Campobasso",
"390373", "Cremona",
"390933", "Caltanissetta",
"390776", "Frosinone",
"390362", "Cremona\/Monza",
"390445", "Vicenza",
"39049", "Padova",
"390423", "Treviso",
"39031", "Como",
"39040", "Trieste",
"390344", "Como",
"390161", "Vercelli",
"39030", "Brescia",
"390382", "Pavia",
"390444", "Vicenza",
"39041", "Venice",
"39048", "Gorizia",
"39039", "Monza",
"390975", "Potenza",
"390924", "Trapani",
"390783", "Oristano",
"3906698", "Vatican\ City",
"390371", "Lodi",
"390583", "Lucca",
"390549", "San\ Marino",
"390824", "Benevento",
"3906", "Rome",
"390421", "Venice",
"390522", "Reggio\ Emilia",
"390342", "Sondrio",
"390737", "Macerata",
"390881", "Foggia",
"390364", "Brescia",
"390733", "Macerata",
"390141", "Asti",
"39035", "Bergamo",
"390346", "Bergamo",
"390789", "Sassari",
"390574", "Prato",
"390543", "Forlì\-Cesena",
"390774", "Rome",
"390963", "Vibo\ Valentia",
"390575", "Arezzo",
"390883", "Andria\ Barletta\ Trani",
"390125", "Turin",
"390432", "Udine",
"390731", "Ancona",
"39033", "Varese",
"390922", "Agrigento",
"39045", "Verona",
"390961", "Catanzaro",
"390541", "Rimini",
"390365", "Brescia",
"390586", "Livorno",
"390166", "Aosta\ Valley",
"390322", "Novara",
"390735", "Ascoli\ Piceno",
"390523", "Piacenza",
"390865", "Isernia",
"390884", "Foggia",
"39050", "Pisa",
"39079", "Sassari",
"390965", "Reggio\ Calabria",
"39011", "Turin",
"39070", "Cagliari",
"39059", "Modena",
"390545", "Ravenna",
"39085", "Pescara",
"390461", "Trento",
"39010", "Genoa",
"390942", "Catania",
"39071", "Ancona",
"390426", "Rovigo",
"39095", "Catania",
"390577", "Siena",
"39051", "Bologna",
"390376", "Mantua",
"3902", "Milan",
"390171", "Cuneo",
"390521", "Parma",
"390422", "Treviso",
"390832", "Lecce",
"390734", "Fermo",
"390363", "Bergamo",
"390372", "Cremona",};
$areanames{it} = {"390941", "Patti",
"39041", "Venezia",
"3906", "Roma",
"390549", "Repubblica\ di\ San\ Marino",
"390875", "Termoli",
"390434", "Pordenone",
"3906698", "Città\ del\ Vaticano",
"390924", "Alcamo",
"390975", "Sala\ Consilina",
"390386", "Ostiglia",
"390122", "Susa",
"390471", "Bolzano",
"390572", "Montecatini\ Terme",
"390763", "Orvieto",
"390377", "Codogno",
"390344", "Menaggio",
"390423", "Montebelluna",
"390833", "Gallipoli",
"390362", "Seregno",
"390781", "Iglesias",
"390445", "Schio",
"390427", "Spilimbergo",
"390373", "Crema",
"390933", "Caltagirone",
"390343", "Chiavenna",
"390424", "Bassano\ del\ Grappa",
"390966", "Palmi",
"390374", "Soresina",
"390934", "Caltanissetta",
"390165", "Aosta",
"390742", "Foligno",
"390536", "Sassuolo",
"390585", "Massa",
"390184", "Sanremo",
"390564", "Grosseto",
"390588", "Volterra",
"39055", "Firenze",
"390736", "Ascoli\ Piceno",
"390785", "Macomer",
"390542", "Imola",
"39081", "Napoli",
"390882", "San\ Severo",
"390433", "Tolmezzo",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390437", "Belluno",
"390982", "Paola",
"390923", "Trapani",
"390871", "Chieti",
"390331", "Busto\ Arsizio",
"390971", "Potenza",
"390985", "Scalea",
"3902", "Milano",
"390964", "Locri",
"390376", "Mantova",
"390942", "Taormina",
"390864", "Sulmona",
"390426", "Adria",
"390836", "Maglie",
"390885", "Cerignola",
"390766", "Civitavecchia",
"390566", "Follonica",
"390534", "Porretta\ Terme",
"390383", "Voghera",
"390322", "Arona",
"390771", "Formia",
"390463", "Cles",
"390121", "Pinerolo",
"390472", "Bressanone",
"390571", "Empoli",
"390144", "Acqui\ Terme",
"390545", "Lugo",
"390782", "Lanusei",
"390173", "Alba",
"390143", "Novi\ Ligure",
"390775", "Frosinone",
"390578", "Chianciano\ Terme",
"390524", "Fidenza",
"390174", "Mondovì",
"390125", "Ivrea",
"390442", "Legnago",
"390384", "Mortara",
"390365", "Salò",
"390436", "Cortina\ d\'Ampezzo",
"390464", "Rovereto",
"390981", "Castrovillari",
"390737", "Camerino",
"390533", "Comacchio",
"390332", "Varese",
"390972", "Melfi",
"390863", "Avezzano",
"390872", "Lanciano",
"390346", "Clusone",
"390967", "Soverato",
"390789", "Olbia",
"390473", "Merano",
"390462", "Cavalese",
"390345", "San\ Pellegrino\ Terme",
"390323", "Baveno",
"390761", "Viterbo",
"390172", "Savigliano",
"390522", "Reggio\ nell\'Emilia",
"390421", "San\ Donà\ di\ Piave",
"390831", "Brindisi",
"390163", "Borgosesia",
"390931", "Siracusa",
"390587", "Pontedera",
"390722", "Urbino",
"390435", "Pieve\ di\ Cadore",
"390438", "Conegliano",
"390828", "Battipaglia",
"390974", "Vallo\ della\ Lucania",
"390925", "Sciacca",
"390776", "Cassino",
"390431", "Cervignano\ del\ Friuli",
"390746", "Rieti",
"390546", "Faenza",
"390732", "Fabriano",
"390921", "Cefalù",
"390873", "Vasto",
"390973", "Lagonegro",
"390584", "Viareggio",
"390565", "Piombino",
"390185", "Rapallo",
"390784", "Nuoro",
"390765", "Poggio\ Mirteto",
"390142", "Casale\ Monferrato",
"390835", "Matera",
"390474", "Brunico",
"390428", "Tarvisio",
"390324", "Domodossola",
"390375", "Casalmaggiore",
"390935", "Enna",
"390773", "Latina",
"39019", "Savona",
"390439", "Feltre",
"390381", "Vigevano",
"390544", "Ravenna",
"390573", "Pistoia",
"390123", "Lanzo\ Torinese",
"390182", "Albenga",
"390744", "Terni",
"39010", "Genova",
"390932", "Ragusa",
"390721", "Pesaro",
"390363", "Treviglio",
"390735", "San\ Benedetto\ del\ Tronto",
"390166", "Saint\-Vincent",
"390535", "Mirandola",
"390968", "Lamezia\ Terme",
"390984", "Cosenza",
"390965", "Reggio\ di\ Calabria",
"39011", "Torino",
"390884", "Manfredonia",
"390731", "Jesi",
"390983", "Rossano",
"390883", "Andria",
"390429", "Este",
"390861", "Teramo",
"390385", "Stradella",
"390364", "Breno",
"390976", "Muro\ Lucano",
"390465", "Tione\ di\ Trento",
"390774", "Tivoli",
"390543", "Forlì",
"390525", "Fornovo\ di\ Taro",
"390547", "Cesena",
"390124", "Rivarolo\ Canavese",
"390175", "Saluzzo",
"390743", "Spoleto",};
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