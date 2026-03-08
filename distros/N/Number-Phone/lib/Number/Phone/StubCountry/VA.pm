# automatically generated file, don't edit



# Copyright 2026 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20260306161714;

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
$areanames{it} = {"390784", "Nuoro",
"390572", "Montecatini\ Terme",
"390775", "Frosinone",
"390983", "Rossano",
"390971", "Potenza",
"390781", "Iglesias",
"390974", "Vallo\ della\ Lucania",
"390985", "Scalea",
"390773", "Latina",
"390331", "Busto\ Arsizio",
"390535", "Mirandola",
"390732", "Fabriano",
"390864", "Sulmona",
"390123", "Lanzo\ Torinese",
"390125", "Ivrea",
"390861", "Teramo",
"390533", "Comacchio",
"390376", "Mantova",
"39019", "Savona",
"390424", "Bassano\ del\ Grappa",
"390782", "Lanusei",
"390585", "Massa",
"390332", "Varese",
"39010", "Genova",
"390421", "San\ Donà\ di\ Piave",
"390427", "Spilimbergo",
"390571", "Empoli",
"390549", "Repubblica\ di\ San\ Marino",
"390776", "Cassino",
"390143", "Novi\ Ligure",
"390972", "Melfi",
"390463", "Cles",
"390933", "Caltagirone",
"390384", "Mortara",
"390375", "Casalmaggiore",
"390536", "Sassuolo",
"390737", "Camerino",
"390442", "Legnago",
"390968", "Lamezia\ Terme",
"390438", "Conegliano",
"390373", "Crema",
"390731", "Jesi",
"390935", "Enna",
"390465", "Tione\ di\ Trento",
"390381", "Vigevano",
"390175", "Saluzzo",
"390544", "Ravenna",
"390184", "Sanremo",
"390433", "Tolmezzo",
"390746", "Rieti",
"390547", "Cesena",
"390435", "Pieve\ di\ Cadore",
"390965", "Reggio\ di\ Calabria",
"390429", "Este",
"390761", "Viterbo",
"390942", "Taormina",
"390566", "Follonica",
"390173", "Alba",
"390362", "Seregno",
"390588", "Volterra",
"390924", "Alcamo",
"390345", "San\ Pellegrino\ Terme",
"390884", "Manfredonia",
"390875", "Termoli",
"390522", "Reggio\ nell\'Emilia",
"390873", "Vasto",
"390343", "Chiavenna",
"390472", "Bressanone",
"390921", "Cefalù",
"390323", "Baveno",
"390542", "Imola",
"390182", "Albenga",
"390436", "Cortina\ d\'Ampezzo",
"390966", "Palmi",
"390941", "Patti",
"390565", "Piombino",
"390789", "Olbia",
"390743", "Spoleto",
"39081", "Napoli",
"390471", "Bolzano",
"390364", "Breno",
"390882", "San\ Severo",
"390474", "Brunico",
"39011", "Torino",
"390524", "Fidenza",
"390346", "Clusone",
"390828", "Battipaglia",
"390587", "Pontedera",
"390982", "Paola",
"390423", "Montebelluna",
"390166", "Saint\-Vincent",
"390573", "Pistoia",
"390584", "Viareggio",
"390439", "Feltre",
"390144", "Acqui\ Terme",
"390976", "Muro\ Lucano",
"390122", "Susa",
"390383", "Voghera",
"390377", "Codogno",
"390464", "Rovereto",
"390934", "Caltanissetta",
"390735", "San\ Benedetto\ del\ Tronto",
"390385", "Stradella",
"390374", "Soresina",
"390931", "Siracusa",
"390426", "Adria",
"390163", "Borgosesia",
"390771", "Formia",
"390975", "Sala\ Consilina",
"390984", "Cosenza",
"390973", "Lagonegro",
"39055", "Firenze",
"390785", "Macomer",
"390774", "Tivoli",
"390142", "Casale\ Monferrato",
"3906", "Roma",
"390827", "Sant\'Angelo\ dei\ Lombardi",
"390165", "Aosta",
"390981", "Castrovillari",
"390445", "Schio",
"390736", "Ascoli\ Piceno",
"390124", "Rivarolo\ Canavese",
"390462", "Cavalese",
"390932", "Ragusa",
"390386", "Ostiglia",
"390863", "Avezzano",
"390534", "Porretta\ Terme",
"390121", "Pinerolo",
"3902", "Milano",
"390546", "Faenza",
"390833", "Gallipoli",
"390766", "Civitavecchia",
"390324", "Domodossola",
"390172", "Savigliano",
"390744", "Terni",
"3906698", "Città\ del\ Vaticano",
"390564", "Grosseto",
"390835", "Matera",
"390722", "Urbino",
"390525", "Fornovo\ di\ Taro",
"390363", "Treviglio",
"390365", "Salò",
"390473", "Merano",
"390872", "Lanciano",
"390763", "Orvieto",
"390434", "Pordenone",
"390964", "Locri",
"390543", "Forlì",
"390836", "Maglie",
"390322", "Arona",
"39041", "Venezia",
"390437", "Belluno",
"390967", "Soverato",
"390545", "Lugo",
"390742", "Foligno",
"390174", "Mondovì",
"390431", "Cervignano\ del\ Friuli",
"390185", "Rapallo",
"390765", "Poggio\ Mirteto",
"390923", "Trapani",
"390883", "Andria",
"390871", "Chieti",
"390578", "Chianciano\ Terme",
"390721", "Pesaro",
"390428", "Tarvisio",
"390885", "Cerignola",
"390344", "Menaggio",
"390925", "Sciacca",};
$areanames{en} = {"39011", "Turin",
"390344", "Como",
"390925", "Agrigento",
"390346", "Bergamo",
"390874", "Campobasso",
"390364", "Brescia",
"39045", "Verona",
"390521", "Parma",
"390883", "Andria\ Barletta\ Trani",
"390471", "Bolzano\/Bozen",
"39048", "Gorizia",
"39085", "Pescara",
"390341", "Lecco",
"390922", "Agrigento",
"390882", "Foggia",
"390185", "Genoa",
"390961", "Catanzaro",
"390545", "Ravenna",
"390789", "Sassari",
"39041", "Venice",
"39059", "Modena",
"390831", "Brindisi",
"39081", "Naples",
"39050", "Pisa",
"390171", "Cuneo",
"39079", "Sassari",
"39015", "Biella",
"390322", "Novara",
"390565", "Livorno",
"390183", "Imperia",
"390543", "Forlì\-Cesena",
"39070", "Cagliari",
"390343", "Sondrio",
"390365", "Brescia",
"390522", "Reggio\ Emilia",
"390523", "Piacenza",
"390881", "Foggia",
"390921", "Palermo",
"390342", "Sondrio",
"39013", "Alessandria",
"39030", "Brescia",
"390362", "Cremona\/Monza",
"39039", "Monza",
"390884", "Foggia",
"390363", "Bergamo",
"390924", "Trapani",
"3906698", "Vatican\ City",
"390541", "Rimini",
"390965", "Reggio\ Calabria",
"390187", "La\ Spezia",
"390942", "Catania",
"390321", "Novara",
"39090", "Messina",
"390962", "Crotone",
"390432", "Udine",
"390963", "Vibo\ Valentia",
"39099", "Taranto",
"390324", "Verbano\-Cusio\-Ossola",
"390832", "Lecce",
"390373", "Cremona",
"390731", "Ancona",
"390865", "Isernia",
"390737", "Macerata",
"39071", "Ancona",
"390372", "Cremona",
"3902", "Milan",
"39049", "Padova",
"39080", "Bari",
"390933", "Caltanissetta",
"390862", "L\'Aquila",
"39051", "Bologna",
"390734", "Fermo",
"390445", "Vicenza",
"39089", "Salerno",
"39040", "Trieste",
"390776", "Frosinone",
"3906", "Rome",
"390577", "Siena",
"390774", "Rome",
"390549", "San\ Marino",
"390421", "Venice",
"39055", "Florence",
"390165", "Aosta\ Valley",
"390583", "Lucca",
"390574", "Prato",
"390585", "Massa\-Carrara",
"390424", "Vicenza",
"39075", "Perugia",
"390426", "Rovigo",
"390975", "Potenza",
"390824", "Benevento",
"39010", "Genoa",
"390783", "Oristano",
"39033", "Varese",
"390735", "Ascoli\ Piceno",
"390532", "Ferrara",
"390444", "Vicenza",
"390125", "Turin",
"39091", "Palermo",
"390461", "Trento",
"390376", "Mantua",
"390732", "Ancona",
"390122", "Turin",
"390934", "Caltanissetta\ and\ Enna",
"39035", "Bergamo",
"390371", "Lodi",
"390733", "Macerata",
"390382", "Pavia",
"390425", "Rovigo",
"390586", "Livorno",
"390575", "Arezzo",
"390825", "Avellino",
"39031", "Como",
"390161", "Vercelli",
"390974", "Salerno",
"390422", "Treviso",
"390141", "Asti",
"390823", "Caserta",
"39095", "Catania",
"390166", "Aosta\ Valley",
"390423", "Treviso",};
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