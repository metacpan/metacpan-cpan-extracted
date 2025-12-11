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
package Number::Phone::StubCountry::ES;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20251210153522;

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
          96906(?:
            09|
            10
          )\\d\\d|
          (?:
            590(?:
              10[0-2]|
              600
            )|
            97390\\d
          )\\d{3}|
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
$areanames{en} = {"34972", "Girona",
"34873", "Lleida",
"34868", "Murcia",
"34876", "Zaragoza",
"34925", "Toledo",
"34888", "Ourense",
"34969063", "Cuenca",
"34922", "Tenerife",
"34950", "Almería",
"349694", "Cuenca",
"34823", "Salamanca",
"3497391", "Lleida",
"34964", "Castellón",
"349736", "Lleida",
"3493", "Barcelona",
"349690617", "Cuenca",
"34975", "Soria",
"34826", "Ciudad\ Real",
"34984", "Asturias",
"34969065", "Cuenca",
"34971", "Balearic\ Islands",
"34969069", "Cuenca",
"34977", "Tarragona",
"34858", "Granada",
"3497394", "Lleida",
"349730", "Lleida",
"34879", "Palencia",
"34944", "Bizkaia",
"349733", "Lleida",
"3497393", "Lleida",
"349737", "Lleida",
"34980", "Zamora",
"34921", "Segovia",
"34954", "Seville",
"349698", "Cuenca",
"34927", "Cáceres",
"349690614", "Cuenca",
"349690615", "Cuenca",
"34848", "Navarre",
"349690613", "Cuenca",
"349690602", "Cuenca",
"34960", "Valencia",
"349690606", "Cuenca",
"34958", "Granada",
"34877", "Tarragona",
"34844", "Bizkaia",
"349690601", "Cuenca",
"34979", "Palencia",
"349691", "Cuenca",
"349690608", "Cuenca",
"349735", "Lleida",
"34969067", "Cuenca",
"34871", "Balearic\ Islands",
"34854", "Seville",
"34827", "Cáceres",
"34860", "Valencia",
"34948", "Navarre",
"3496901", "Cuenca",
"349690600", "Cuenca",
"34821", "Segovia",
"34880", "Zamora",
"3496904", "Cuenca",
"349699", "Cuenca",
"3496903", "Cuenca",
"34988", "Ourense",
"34825", "Toledo",
"34976", "Zaragoza",
"34872", "Girona",
"34969064", "Cuenca",
"34968", "Murcia",
"3496900", "Cuenca",
"349692", "Cuenca",
"34884", "Asturias",
"34926", "Ciudad\ Real",
"34875", "Soria",
"34822", "Tenerife",
"34850", "Almería",
"34864", "Castellón",
"34923", "Salamanca",
"3483", "Barcelona",
"34981", "A\ Coruña",
"34920", "Ávila",
"34952", "Málaga",
"34869", "Cuenca",
"3491", "Madrid",
"349690604", "Cuenca",
"3497398", "Lleida",
"349690605", "Cuenca",
"349690612", "Cuenca",
"34967", "Albacete",
"34853", "Jaén",
"349690603", "Cuenca",
"34961", "Valencia",
"34945", "Araba",
"34987", "León",
"34856", "Cádiz",
"3497392", "Lleida",
"34843", "Guipúzcoa",
"349696", "Cuenca",
"34942", "Cantabria",
"349734", "Lleida",
"349690619", "Cuenca",
"3496909", "Cuenca",
"34846", "Bizkaia",
"34955", "Seville",
"34883", "Valladolid",
"34866", "Alicante",
"34951", "Málaga",
"34982", "Lugo",
"349693", "Cuenca",
"34886", "Pontevedra",
"34878", "Teruel",
"3497395", "Lleida",
"34957", "Cordova",
"34924", "Badajoz",
"34863", "Valencia",
"3497397", "Lleida",
"349690607", "Cuenca",
"34962", "Valencia",
"34859", "Huelva",
"34965", "Alicante",
"34941", "La\ Rioja",
"349697", "Cuenca",
"34985", "Asturias",
"34828", "Las\ Palmas",
"34849", "Guadalajara",
"34974", "Huesca",
"349738", "Lleida",
"34947", "Burgos",
"34978", "Teruel",
"34857", "Cordova",
"34963", "Valencia",
"34824", "Badajoz",
"34986", "Pontevedra",
"34959", "Huelva",
"34862", "Valencia",
"3496908", "Cuenca",
"34966", "Alicante",
"34969066", "Cuenca",
"349695", "Cuenca",
"34983", "Valladolid",
"34851", "Málaga",
"34882", "Lugo",
"349731", "Lleida",
"34928", "Las\ Palmas",
"34874", "Huesca",
"34949", "Guadalajara",
"34885", "Asturias",
"34969068", "Cuenca",
"34847", "Burgos",
"34969062", "Cuenca",
"34865", "Alicante",
"34841", "La\ Rioja",
"3497399", "Lleida",
"3496902", "Cuenca",
"34845", "Araba",
"34861", "Valencia",
"3496907", "Cuenca",
"34956", "Cádiz",
"34887", "León",
"3496905", "Cuenca",
"3481", "Madrid",
"34820", "Ávila",
"34881", "A\ Coruña",
"34852", "Málaga",
"34867", "Albacete",
"34953", "Jaén",
"34946", "Bizkaia",
"349690618", "Cuenca",
"349732", "Lleida",
"3497396", "Lleida",
"34855", "Seville",
"34943", "Guipúzcoa",
"349690616", "Cuenca",
"34842", "Cantabria",
"349690611", "Cuenca",};
$areanames{es} = {"349736", "Lérida",
"3497391", "Lérida",
"34888", "Orense",
"34972", "Gerona",
"34873", "Lérida",
"34954", "Sevilla",
"34848", "Navarra",
"349737", "Lérida",
"34944", "Vizcaya",
"3497394", "Lérida",
"349730", "Lérida",
"3497393", "Lérida",
"349733", "Lérida",
"34971", "Baleares",
"34854", "Sevilla",
"34948", "Navarra",
"349735", "Lérida",
"34871", "Baleares",
"34844", "Vizcaya",
"34850", "Álmería",
"34872", "Gerona",
"34988", "Orense",
"34846", "Vizcaya",
"34955", "Sevilla",
"3497392", "Lérida",
"349734", "Lérida",
"34945", "Álava",
"3497398", "Lérida",
"349738", "Lérida",
"34957", "Córdoba",
"3497395", "Lérida",
"3497397", "Lérida",
"3497399", "Lérida",
"349731", "Lérida",
"34857", "Córdoba",
"34946", "Vizcaya",
"3497396", "Lérida",
"349732", "Lérida",
"34845", "Álava",};
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