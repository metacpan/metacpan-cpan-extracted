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
our $VERSION = 1.20241212130805;

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
$areanames{en} = {"3496902", "Cuenca",
"34826", "Ciudad\ Real",
"349690603", "Cuenca",
"349690602", "Cuenca",
"34873", "Lleida",
"34877", "Tarragona",
"34821", "Segovia",
"34925", "Toledo",
"34820", "Ávila",
"34854", "Seville",
"34942", "Cantabria",
"34976", "Zaragoza",
"3496901", "Cuenca",
"3497395", "Lleida",
"3497398", "Lleida",
"34949", "Guadalajara",
"34927", "Cáceres",
"349733", "Lleida",
"349730", "Lleida",
"34858", "Granada",
"34923", "Salamanca",
"349690606", "Cuenca",
"34868", "Murcia",
"34971", "Balearic\ Islands",
"34875", "Soria",
"349690601", "Cuenca",
"34864", "Castellón",
"34852", "Málaga",
"34969063", "Cuenca",
"34887", "León",
"34883", "Valladolid",
"34944", "Bizkaia",
"34948", "Navarre",
"34859", "Huelva",
"3497397", "Lleida",
"34969062", "Cuenca",
"34869", "Cuenca",
"3496909", "Cuenca",
"34969068", "Cuenca",
"34862", "Valencia",
"34986", "Pontevedra",
"34980", "Zamora",
"349693", "Cuenca",
"34885", "Asturias",
"34981", "La\ Coruña",
"34957", "Cordova",
"34982", "Lugo",
"34828", "Las\ Palmas",
"34953", "Jaén",
"34824", "Badajoz",
"3497392", "Lleida",
"34963", "Valencia",
"34967", "Albacete",
"3496900", "Cuenca",
"34965", "Alicante",
"349699", "Cuenca",
"34978", "Teruel",
"3496908", "Cuenca",
"34861", "Valencia",
"3496905", "Cuenca",
"349692", "Cuenca",
"3497391", "Lleida",
"34860", "Valencia",
"34974", "Huesca",
"34856", "Cádiz",
"34866", "Alicante",
"349737", "Lleida",
"34969065", "Cuenca",
"34850", "Almería",
"34851", "Málaga",
"34955", "Seville",
"34979", "Palencia",
"3496907", "Cuenca",
"34946", "Bizkaia",
"349690613", "Cuenca",
"34972", "Girona",
"349690612", "Cuenca",
"34969069", "Cuenca",
"3493", "Barcelona",
"3497399", "Lleida",
"34845", "Araba",
"34941", "La\ Rioja",
"34847", "Burgos",
"34843", "Guipúzcoa",
"34984", "Asturias",
"34822", "Tenerife",
"34988", "Ourense",
"349697", "Cuenca",
"349690616", "Cuenca",
"349690611", "Cuenca",
"34969064", "Cuenca",
"349732", "Lleida",
"3491", "Madrid",
"34881", "La\ Coruña",
"3496904", "Cuenca",
"34985", "Asturias",
"349694", "Cuenca",
"349735", "Lleida",
"349690615", "Cuenca",
"34880", "Zamora",
"34969067", "Cuenca",
"34886", "Pontevedra",
"34962", "Valencia",
"349698", "Cuenca",
"349731", "Lleida",
"349690614", "Cuenca",
"34959", "Huelva",
"34848", "Navarre",
"34844", "Bizkaia",
"34983", "Valladolid",
"34952", "Málaga",
"34987", "León",
"34964", "Castellón",
"34975", "Soria",
"34871", "Balearic\ Islands",
"34968", "Murcia",
"34823", "Salamanca",
"34958", "Granada",
"34827", "Cáceres",
"34849", "Guadalajara",
"349695", "Cuenca",
"3496903", "Cuenca",
"349690600", "Cuenca",
"34876", "Zaragoza",
"34842", "Cantabria",
"349734", "Lleida",
"34954", "Seville",
"34920", "Ávila",
"34825", "Toledo",
"34921", "Segovia",
"349690608", "Cuenca",
"34977", "Tarragona",
"349690607", "Cuenca",
"349738", "Lleida",
"349691", "Cuenca",
"34926", "Ciudad\ Real",
"3481", "Madrid",
"3497394", "Lleida",
"34969066", "Cuenca",
"349696", "Cuenca",
"34888", "Ourense",
"34922", "Tenerife",
"34884", "Asturias",
"34943", "Guipúzcoa",
"34947", "Burgos",
"34841", "La\ Rioja",
"34945", "Araba",
"349690618", "Cuenca",
"3483", "Barcelona",
"349690617", "Cuenca",
"34872", "Girona",
"34846", "Bizkaia",
"3497396", "Lleida",
"34879", "Palencia",
"34855", "Seville",
"34951", "Málaga",
"34950", "Almería",
"34966", "Alicante",
"349736", "Lleida",
"349690605", "Cuenca",
"34956", "Cádiz",
"34874", "Huesca",
"34960", "Valencia",
"349690619", "Cuenca",
"34961", "Valencia",
"3497393", "Lleida",
"34878", "Teruel",
"34865", "Alicante",
"349690604", "Cuenca",
"34867", "Albacete",
"34863", "Valencia",
"34924", "Badajoz",
"34928", "Las\ Palmas",
"34853", "Jaén",
"34882", "Lugo",
"34857", "Cordova",};
$areanames{es} = {"34944", "Vizcaya",
"34948", "Navarra",
"3497397", "Lérida",
"34981", "A\ Coruña",
"34873", "Lérida",
"34854", "Sevilla",
"3497395", "Lérida",
"3497398", "Lérida",
"349730", "Lérida",
"349733", "Lérida",
"34971", "Baleares",
"34946", "Vizcaya",
"34972", "Gerona",
"3497399", "Lérida",
"34845", "Álava",
"34988", "Orense",
"349732", "Lérida",
"34957", "Córdoba",
"3497392", "Lérida",
"3497391", "Lérida",
"349737", "Lérida",
"34850", "Álmería",
"34955", "Sevilla",
"34871", "Baleares",
"349734", "Lérida",
"34954", "Sevilla",
"349738", "Lérida",
"349735", "Lérida",
"349731", "Lérida",
"34848", "Navarra",
"34844", "Vizcaya",
"349736", "Lérida",
"3497393", "Lérida",
"34857", "Córdoba",
"3497394", "Lérida",
"34888", "Orense",
"34945", "Álava",
"34872", "Gerona",
"34846", "Vizcaya",
"3497396", "Lérida",};
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