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
package Number::Phone::StubCountry::ES;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20240308154351;

my $formatters = [
                {
                  'format' => '$1',
                  'intl_format' => 'NA',
                  'leading_digits' => '905',
                  'pattern' => '(\\d{4})'
                },
                {
                  'format' => '$1',
                  'intl_format' => 'NA',
                  'leading_digits' => '[79]9',
                  'pattern' => '(\\d{6})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[89]00',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[5-9]',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          96906(?:
            0[0-8]|
            1[1-9]|
            [2-9]\\d
          )\\d\\d|
          9(?:
            69(?:
              0[0-57-9]|
              [1-9]\\d
            )|
            73(?:
              [0-8]\\d|
              9[1-9]
            )
          )\\d{4}|
          (?:
            8(?:
              [1356]\\d|
              [28][0-8]|
              [47][1-9]
            )|
            9(?:
              [135]\\d|
              [268][0-8]|
              4[1-9]|
              7[124-9]
            )
          )\\d{6}
        ',
                'geographic' => '
          96906(?:
            0[0-8]|
            1[1-9]|
            [2-9]\\d
          )\\d\\d|
          9(?:
            69(?:
              0[0-57-9]|
              [1-9]\\d
            )|
            73(?:
              [0-8]\\d|
              9[1-9]
            )
          )\\d{4}|
          (?:
            8(?:
              [1356]\\d|
              [28][0-8]|
              [47][1-9]
            )|
            9(?:
              [135]\\d|
              [268][0-8]|
              4[1-9]|
              7[124-9]
            )
          )\\d{6}
        ',
                'mobile' => '
          (?:
            590[16]00\\d|
            9(?:
              6906(?:
                09|
                10
              )|
              7390\\d\\d
            )
          )\\d\\d|
          (?:
            6\\d|
            7[1-48]
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '70\\d{7}',
                'specialrate' => '(90[12]\\d{6})|(80[367]\\d{6})|(51\\d{7})',
                'toll_free' => '[89]00\\d{6}',
                'voip' => ''
              };
my %areanames = ();
$areanames{es} = {"34888", "Orense",
"3497396", "Lérida",
"349734", "Lérida",
"34971", "Baleares",
"3497393", "Lérida",
"34854", "Sevilla",
"34945", "Álava",
"349730", "Lérida",
"34857", "Córdoba",
"34848", "Navarra",
"349737", "Lérida",
"349733", "Lérida",
"34946", "Vizcaya",
"34972", "Gerona",
"34844", "Vizcaya",
"3497392", "Lérida",
"349736", "Lérida",
"34981", "A\ Coruña",
"34955", "Sevilla",
"3497394", "Lérida",
"3497399", "Lérida",
"3497391", "Lérida",
"34873", "Lérida",
"349735", "Lérida",
"349738", "Lérida",
"3497398", "Lérida",
"3497397", "Lérida",
"349731", "Lérida",
"34846", "Vizcaya",
"34872", "Gerona",
"34944", "Vizcaya",
"34845", "Álava",
"34957", "Córdoba",
"34948", "Navarra",
"34988", "Orense",
"349732", "Lérida",
"34871", "Baleares",
"3497395", "Lérida",
"34850", "Álmería",
"34954", "Sevilla",};
$areanames{en} = {"349690602", "Cuenca",
"349737", "Lleida",
"349690607", "Cuenca",
"34865", "Alicante",
"349733", "Lleida",
"349690603", "Cuenca",
"349692", "Cuenca",
"34943", "Guipúzcoa",
"34982", "Lugo",
"349690606", "Cuenca",
"34927", "Cáceres",
"34968", "Murcia",
"34863", "Valencia",
"34848", "Navarre",
"349690600", "Cuenca",
"3493", "Barcelona",
"34945", "Araba",
"34877", "Tarragona",
"349730", "Lleida",
"3496903", "Cuenca",
"34857", "Cordova",
"349690601", "Cuenca",
"34942", "Cantabria",
"34983", "Valladolid",
"34821", "Segovia",
"34854", "Seville",
"349690615", "Cuenca",
"34874", "Huesca",
"34950", "Almería",
"34956", "Cádiz",
"34979", "Palencia",
"3497393", "Lleida",
"349699", "Cuenca",
"34959", "Huelva",
"34976", "Zaragoza",
"34985", "Asturias",
"34971", "Balearic\ Islands",
"34924", "Badajoz",
"34951", "Málaga",
"349690619", "Cuenca",
"34862", "Valencia",
"34820", "Ávila",
"3497396", "Lleida",
"349734", "Lleida",
"34826", "Ciudad\ Real",
"34888", "Ourense",
"34967", "Albacete",
"34928", "Las\ Palmas",
"34986", "Pontevedra",
"34980", "Zamora",
"34969069", "Cuenca",
"34825", "Toledo",
"349691", "Cuenca",
"34953", "Jaén",
"349690605", "Cuenca",
"34884", "Asturias",
"34969063", "Cuenca",
"34858", "Granada",
"3496902", "Cuenca",
"34878", "Teruel",
"34969064", "Cuenca",
"34975", "Soria",
"34847", "Burgos",
"3491", "Madrid",
"349736", "Lleida",
"34823", "Salamanca",
"34981", "La\ Coruña",
"34955", "Seville",
"34972", "Girona",
"349690616", "Cuenca",
"34952", "Málaga",
"3497392", "Lleida",
"34844", "Bizkaia",
"34861", "Valencia",
"349690617", "Cuenca",
"34969067", "Cuenca",
"349690612", "Cuenca",
"34949", "Guadalajara",
"349690613", "Cuenca",
"34946", "Bizkaia",
"34887", "León",
"34869", "Cuenca",
"34822", "Tenerife",
"34941", "La\ Rioja",
"34969065", "Cuenca",
"34860", "Valencia",
"34866", "Alicante",
"349690611", "Cuenca",
"34964", "Castellón",
"349695", "Cuenca",
"349698", "Cuenca",
"349696", "Cuenca",
"34872", "Girona",
"3496901", "Cuenca",
"34944", "Bizkaia",
"34852", "Málaga",
"34849", "Guadalajara",
"3496904", "Cuenca",
"34961", "Valencia",
"34846", "Bizkaia",
"3496909", "Cuenca",
"34922", "Tenerife",
"3497397", "Lleida",
"34841", "La\ Rioja",
"34987", "León",
"34966", "Alicante",
"349731", "Lleida",
"34960", "Valencia",
"3496908", "Cuenca",
"349690608", "Cuenca",
"34969066", "Cuenca",
"34864", "Castellón",
"34969062", "Cuenca",
"34867", "Albacete",
"3496907", "Cuenca",
"349690604", "Cuenca",
"349738", "Lleida",
"34880", "Zamora",
"3497398", "Lleida",
"34886", "Pontevedra",
"34828", "Las\ Palmas",
"349735", "Lleida",
"34925", "Toledo",
"3496900", "Cuenca",
"34873", "Lleida",
"34984", "Asturias",
"34853", "Jaén",
"3497391", "Lleida",
"34958", "Granada",
"34978", "Teruel",
"34923", "Salamanca",
"34881", "La\ Coruña",
"3497394", "Lleida",
"34875", "Soria",
"34947", "Burgos",
"3481", "Madrid",
"34855", "Seville",
"3497399", "Lleida",
"34954", "Seville",
"34842", "Cantabria",
"34883", "Valladolid",
"34921", "Segovia",
"34974", "Huesca",
"34879", "Palencia",
"34856", "Cádiz",
"3497395", "Lleida",
"34850", "Almería",
"34876", "Zaragoza",
"34859", "Huelva",
"349690614", "Cuenca",
"34871", "Balearic\ Islands",
"349732", "Lleida",
"34885", "Asturias",
"34851", "Málaga",
"34824", "Badajoz",
"349697", "Cuenca",
"34962", "Valencia",
"34969068", "Cuenca",
"34988", "Ourense",
"34926", "Ciudad\ Real",
"349693", "Cuenca",
"34920", "Ávila",
"34965", "Alicante",
"349694", "Cuenca",
"34827", "Cáceres",
"34843", "Guipúzcoa",
"34882", "Lugo",
"34868", "Murcia",
"34963", "Valencia",
"34948", "Navarre",
"349690618", "Cuenca",
"34845", "Araba",
"34977", "Tarragona",
"3496905", "Cuenca",
"3483", "Barcelona",
"34957", "Cordova",};
my $timezones = {
               '' => [
                       'Atlantic/Canary',
                       'Europe/Madrid'
                     ],
               '5' => [
                        'Europe/Madrid'
                      ],
               '6' => [
                        'Europe/Madrid'
                      ],
               '7' => [
                        'Europe/Madrid'
                      ],
               '8' => [
                        'Europe/Madrid'
                      ],
               '822' => [
                          'Atlantic/Canary'
                        ],
               '827' => [
                          'Atlantic/Canary'
                        ],
               '828' => [
                          'Atlantic/Canary'
                        ],
               '9' => [
                        'Europe/Madrid'
                      ],
               '922' => [
                          'Atlantic/Canary'
                        ],
               '928' => [
                          'Atlantic/Canary'
                        ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+34|\D)//g;
      my $self = bless({ country_code => '34', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;