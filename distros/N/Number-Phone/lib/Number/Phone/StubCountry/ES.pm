# automatically generated file, don't edit



# Copyright 2023 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20230903131447;

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
$areanames{en} = {"34984", "Asturias",
"34958", "Granada",
"34827", "Cáceres",
"34883", "Valladolid",
"34946", "Bizkaia",
"34860", "Valencia",
"349690611", "Cuenca",
"34878", "Teruel",
"34842", "Cantabria",
"34841", "La\ Rioja",
"34825", "Toledo",
"34969063", "Cuenca",
"34964", "Castellón",
"34979", "Palencia",
"34880", "Zamora",
"349690617", "Cuenca",
"34863", "Valencia",
"34859", "Huelva",
"34923", "Salamanca",
"34972", "Girona",
"34971", "Balearic\ Islands",
"34956", "Cádiz",
"34948", "Navarre",
"34824", "Badajoz",
"3497391", "Lleida",
"349695", "Cuenca",
"3496908", "Cuenca",
"34965", "Alicante",
"34987", "León",
"34876", "Zaragoza",
"34851", "Málaga",
"34852", "Málaga",
"349734", "Lleida",
"349698", "Cuenca",
"3496901", "Cuenca",
"349690604", "Cuenca",
"349690603", "Cuenca",
"3497398", "Lleida",
"34920", "Ávila",
"34985", "Asturias",
"34967", "Albacete",
"349732", "Lleida",
"3497396", "Lleida",
"34849", "Guadalajara",
"34888", "Ourense",
"34847", "Burgos",
"3497399", "Lleida",
"34854", "Seville",
"34926", "Ciudad\ Real",
"34969067", "Cuenca",
"34953", "Jaén",
"34974", "Huesca",
"3496909", "Cuenca",
"34873", "Lleida",
"34822", "Tenerife",
"34821", "Segovia",
"34845", "Araba",
"34868", "Murcia",
"34969069", "Cuenca",
"3493", "Barcelona",
"34950", "Almería",
"349690616", "Cuenca",
"349690615", "Cuenca",
"34886", "Pontevedra",
"34943", "Guipúzcoa",
"349733", "Lleida",
"34857", "Cordova",
"34928", "Las\ Palmas",
"34844", "Bizkaia",
"349690619", "Cuenca",
"349731", "Lleida",
"34982", "Lugo",
"34981", "La\ Coruña",
"349696", "Cuenca",
"3491", "Madrid",
"34977", "Tarragona",
"349690602", "Cuenca",
"34866", "Alicante",
"3496904", "Cuenca",
"349737", "Lleida",
"3497393", "Lleida",
"3496905", "Cuenca",
"34855", "Seville",
"34961", "Valencia",
"34962", "Valencia",
"3497394", "Lleida",
"3496903", "Cuenca",
"349690608", "Cuenca",
"34975", "Soria",
"3497395", "Lleida",
"34922", "Tenerife",
"34921", "Segovia",
"349690605", "Cuenca",
"34869", "Cuenca",
"34874", "Huesca",
"349690606", "Cuenca",
"34826", "Ciudad\ Real",
"34853", "Jaén",
"34988", "Ourense",
"34954", "Seville",
"34947", "Burgos",
"34969064", "Cuenca",
"3496907", "Cuenca",
"3483", "Barcelona",
"34850", "Almería",
"3497397", "Lleida",
"34945", "Araba",
"34968", "Murcia",
"3496900", "Cuenca",
"349691", "Cuenca",
"34877", "Tarragona",
"349736", "Lleida",
"3481", "Madrid",
"34882", "Lugo",
"349690618", "Cuenca",
"34881", "La\ Coruña",
"34969065", "Cuenca",
"349690612", "Cuenca",
"34944", "Bizkaia",
"34828", "Las\ Palmas",
"34957", "Cordova",
"349693", "Cuenca",
"34843", "Guipúzcoa",
"34986", "Pontevedra",
"34875", "Soria",
"34861", "Valencia",
"34862", "Valencia",
"349697", "Cuenca",
"34955", "Seville",
"34966", "Alicante",
"3496902", "Cuenca",
"34942", "Cantabria",
"34941", "La\ Rioja",
"34978", "Teruel",
"3497392", "Lleida",
"34846", "Bizkaia",
"34983", "Valladolid",
"34960", "Valencia",
"349690607", "Cuenca",
"34884", "Asturias",
"34927", "Cáceres",
"34858", "Granada",
"349690601", "Cuenca",
"34969068", "Cuenca",
"34959", "Huelva",
"34969066", "Cuenca",
"349690600", "Cuenca",
"34980", "Zamora",
"34963", "Valencia",
"34925", "Toledo",
"34879", "Palencia",
"34864", "Castellón",
"349694", "Cuenca",
"349738", "Lleida",
"34976", "Zaragoza",
"34951", "Málaga",
"349730", "Lleida",
"34952", "Málaga",
"34924", "Badajoz",
"34848", "Navarre",
"34865", "Alicante",
"34887", "León",
"34872", "Girona",
"349735", "Lleida",
"34823", "Salamanca",
"34871", "Balearic\ Islands",
"34856", "Cádiz",
"349699", "Cuenca",
"34949", "Guadalajara",
"349692", "Cuenca",
"349690613", "Cuenca",
"349690614", "Cuenca",
"34885", "Asturias",
"34867", "Albacete",
"34969062", "Cuenca",
"34820", "Ávila",};
$areanames{es} = {"34946", "Vizcaya",
"3497396", "Lérida",
"349732", "Lérida",
"34948", "Navarra",
"3497391", "Lérida",
"34972", "Gerona",
"34971", "Baleares",
"3497398", "Lérida",
"349734", "Lérida",
"34845", "Álava",
"34888", "Orense",
"34854", "Sevilla",
"3497399", "Lérida",
"34873", "Lérida",
"3497393", "Lérida",
"349737", "Lérida",
"3497395", "Lérida",
"3497394", "Lérida",
"34857", "Córdoba",
"34844", "Vizcaya",
"349733", "Lérida",
"349731", "Lérida",
"34981", "A\ Coruña",
"34945", "Álava",
"34850", "Álmería",
"3497397", "Lérida",
"34988", "Orense",
"34954", "Sevilla",
"34955", "Sevilla",
"349736", "Lérida",
"34944", "Vizcaya",
"34957", "Córdoba",
"34846", "Vizcaya",
"3497392", "Lérida",
"349738", "Lérida",
"349730", "Lérida",
"34872", "Gerona",
"349735", "Lérida",
"34871", "Baleares",
"34848", "Navarra",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+34|\D)//g;
      my $self = bless({ country_code => '34', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;