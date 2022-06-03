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
package Number::Phone::StubCountry::ES;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20220601185318;

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
$areanames{es} = {"34971", "Baleares",
"34857", "Córdoba",
"34844", "Vizcaya",
"3497396", "Lérida",
"349732", "Lérida",
"34954", "Sevilla",
"34848", "Navarra",
"34850", "Álmería",
"34888", "Orense",
"34845", "Álava",
"34946", "Vizcaya",
"349731", "Lérida",
"3497394", "Lérida",
"3497398", "Lérida",
"3497393", "Lérida",
"34955", "Sevilla",
"3497391", "Lérida",
"34981", "A\ Coruña",
"34854", "Sevilla",
"3497399", "Lérida",
"34873", "Lérida",
"34948", "Navarra",
"349737", "Lérida",
"349738", "Lérida",
"34988", "Orense",
"349730", "Lérida",
"3497395", "Lérida",
"349736", "Lérida",
"34957", "Córdoba",
"34944", "Vizcaya",
"349735", "Lérida",
"34871", "Baleares",
"3497392", "Lérida",
"3497397", "Lérida",
"349733", "Lérida",
"349734", "Lérida",
"34846", "Vizcaya",
"34945", "Álava",};
$areanames{en} = {"3491", "Madrid",
"34842", "Cantabria",
"34975", "Soria",
"34925", "Toledo",
"3497395", "Lleida",
"34882", "Lugo",
"349730", "Lleida",
"34988", "Ourense",
"349738", "Lleida",
"34860", "Valencia",
"349737", "Lleida",
"34887", "León",
"34950", "Almería",
"34979", "Palencia",
"34823", "Salamanca",
"34873", "Lleida",
"34964", "Castellón",
"34948", "Navarre",
"34847", "Burgos",
"3497399", "Lleida",
"34854", "Seville",
"349691", "Cuenca",
"349690617", "Cuenca",
"3497397", "Lleida",
"34862", "Valencia",
"3493", "Barcelona",
"34821", "Segovia",
"34871", "Balearic\ Islands",
"3497392", "Lleida",
"34952", "Málaga",
"349735", "Lleida",
"34858", "Granada",
"34867", "Albacete",
"34944", "Bizkaia",
"34968", "Murcia",
"34880", "Zamora",
"34957", "Cordova",
"34826", "Ciudad\ Real",
"34969067", "Cuenca",
"34876", "Zaragoza",
"349736", "Lleida",
"34969065", "Cuenca",
"34984", "Asturias",
"34820", "Ávila",
"3496901", "Cuenca",
"34859", "Huelva",
"3496903", "Cuenca",
"34846", "Bizkaia",
"3496908", "Cuenca",
"34969069", "Cuenca",
"34924", "Badajoz",
"34974", "Huesca",
"34863", "Valencia",
"349734", "Lleida",
"34886", "Pontevedra",
"34953", "Jaén",
"34841", "La\ Rioja",
"349690600", "Cuenca",
"34969062", "Cuenca",
"34969066", "Cuenca",
"349733", "Lleida",
"349692", "Cuenca",
"34965", "Alicante",
"3496904", "Cuenca",
"34881", "La\ Coruña",
"34855", "Seville",
"349690607", "Cuenca",
"34827", "Cáceres",
"34877", "Tarragona",
"34843", "Guipúzcoa",
"34978", "Teruel",
"34928", "Las\ Palmas",
"34949", "Guadalajara",
"34866", "Alicante",
"3496900", "Cuenca",
"34883", "Valladolid",
"34956", "Cádiz",
"34945", "Araba",
"34822", "Tenerife",
"34951", "Málaga",
"349690619", "Cuenca",
"34872", "Gerona",
"34985", "Asturias",
"34861", "Valencia",
"34958", "Granada",
"3496907", "Cuenca",
"34967", "Albacete",
"3496902", "Cuenca",
"34844", "Bizkaia",
"34868", "Murcia",
"34980", "Zamora",
"34857", "Cordova",
"34926", "Ciudad\ Real",
"34969063", "Cuenca",
"349690604", "Cuenca",
"34976", "Zaragoza",
"34884", "Asturias",
"349690616", "Cuenca",
"34962", "Valencia",
"3483", "Barcelona",
"34921", "Segovia",
"34971", "Balearic\ Islands",
"34852", "Málaga",
"3496905", "Cuenca",
"34888", "Ourense",
"349694", "Cuenca",
"349690605", "Cuenca",
"34960", "Valencia",
"349699", "Cuenca",
"349690618", "Cuenca",
"34879", "Palencia",
"34987", "León",
"34850", "Almería",
"349690603", "Cuenca",
"34923", "Salamanca",
"34864", "Castellón",
"34848", "Navarre",
"34947", "Burgos",
"34954", "Seville",
"3481", "Madrid",
"349690601", "Cuenca",
"349732", "Lleida",
"3497396", "Lleida",
"34942", "Cantabria",
"349693", "Cuenca",
"3496909", "Cuenca",
"349690612", "Cuenca",
"34875", "Soria",
"34825", "Toledo",
"34982", "Lugo",
"34845", "Araba",
"349690611", "Cuenca",
"34922", "Tenerife",
"34851", "Málaga",
"34972", "Gerona",
"349690602", "Cuenca",
"34885", "Asturias",
"34961", "Valencia",
"34969064", "Cuenca",
"34927", "Cáceres",
"349696", "Cuenca",
"34977", "Tarragona",
"349690613", "Cuenca",
"34943", "Guipúzcoa",
"34878", "Teruel",
"34969068", "Cuenca",
"34828", "Las\ Palmas",
"349690615", "Cuenca",
"34849", "Guadalajara",
"34966", "Alicante",
"349695", "Cuenca",
"34856", "Cádiz",
"349690608", "Cuenca",
"34983", "Valladolid",
"34941", "La\ Rioja",
"34865", "Alicante",
"34981", "La\ Coruña",
"3497391", "Lleida",
"349690606", "Cuenca",
"34955", "Seville",
"3497393", "Lleida",
"3497398", "Lleida",
"349690614", "Cuenca",
"34920", "Ávila",
"3497394", "Lleida",
"349731", "Lleida",
"34959", "Huelva",
"34946", "Bizkaia",
"34869", "Cuenca",
"349697", "Cuenca",
"34824", "Badajoz",
"34874", "Huesca",
"34963", "Valencia",
"34853", "Jaén",
"34986", "Pontevedra",
"349698", "Cuenca",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+34|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;