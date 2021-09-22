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
our $VERSION = 1.20210921211831;

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
$areanames{en} = {"34969069", "Cuenca",
"34873", "Lleida",
"34921", "Segovia",
"34857", "Cordova",
"34969067", "Cuenca",
"34955", "Seville",
"34881", "La\ Coruña",
"349737", "Lleida",
"349690616", "Cuenca",
"34876", "Zaragoza",
"349690605", "Cuenca",
"34952", "Málaga",
"34954", "Seville",
"34988", "Ourense",
"34850", "Almería",
"34969065", "Cuenca",
"3496907", "Cuenca",
"349731", "Lleida",
"349690603", "Cuenca",
"3497399", "Lleida",
"34828", "Las\ Palmas",
"3496908", "Cuenca",
"34956", "Cádiz",
"34875", "Soria",
"349690614", "Cuenca",
"34941", "La\ Rioja",
"34977", "Tarragona",
"349691", "Cuenca",
"349690601", "Cuenca",
"34961", "Valencia",
"34953", "Jaén",
"349697", "Cuenca",
"3483", "Barcelona",
"34848", "Navarre",
"34868", "Murcia",
"349690608", "Cuenca",
"34849", "Guadalajara",
"349699", "Cuenca",
"34874", "Huesca",
"34872", "Gerona",
"34869", "Cuenca",
"34855", "Seville",
"34981", "La\ Coruña",
"3497394", "Lleida",
"3496902", "Cuenca",
"349690606", "Cuenca",
"34976", "Zaragoza",
"34821", "Segovia",
"34957", "Cordova",
"349693", "Cuenca",
"34928", "Las\ Palmas",
"349690613", "Cuenca",
"34854", "Seville",
"34852", "Málaga",
"34888", "Ourense",
"349690615", "Cuenca",
"34950", "Almería",
"34969062", "Cuenca",
"349690611", "Cuenca",
"34841", "La\ Rioja",
"34877", "Tarragona",
"34861", "Valencia",
"34853", "Jaén",
"3497391", "Lleida",
"34856", "Cádiz",
"34975", "Soria",
"349690604", "Cuenca",
"349733", "Lleida",
"34949", "Guadalajara",
"349690618", "Cuenca",
"3496903", "Cuenca",
"34974", "Huesca",
"34972", "Gerona",
"3493", "Barcelona",
"3497395", "Lleida",
"34948", "Navarre",
"34968", "Murcia",
"34847", "Burgos",
"34871", "Balearic\ Islands",
"34867", "Albacete",
"34923", "Salamanca",
"34886", "Pontevedra",
"349696", "Cuenca",
"3496900", "Cuenca",
"349735", "Lleida",
"34965", "Alicante",
"34883", "Valladolid",
"34926", "Ciudad\ Real",
"3496901", "Cuenca",
"34945", "Araba",
"349734", "Lleida",
"34860", "Valencia",
"34979", "Palencia",
"34964", "Castellón",
"34962", "Valencia",
"349732", "Lleida",
"349690612", "Cuenca",
"3497393", "Lleida",
"34942", "Cantabria",
"34944", "Bizkaia",
"3496905", "Cuenca",
"34978", "Teruel",
"34925", "Toledo",
"3496904", "Cuenca",
"34966", "Alicante",
"34987", "León",
"34946", "Bizkaia",
"3497392", "Lleida",
"34943", "Guipúzcoa",
"34969063", "Cuenca",
"34885", "Asturias",
"34951", "Málaga",
"34963", "Valencia",
"34827", "Cáceres",
"349692", "Cuenca",
"349694", "Cuenca",
"34882", "Lugo",
"34884", "Asturias",
"34858", "Granada",
"349736", "Lleida",
"349690607", "Cuenca",
"3491", "Madrid",
"34980", "Zamora",
"34969068", "Cuenca",
"349695", "Cuenca",
"34924", "Badajoz",
"34922", "Tenerife",
"34820", "Ávila",
"34969064", "Cuenca",
"34859", "Huelva",
"34969066", "Cuenca",
"34865", "Alicante",
"349690600", "Cuenca",
"34983", "Valladolid",
"34826", "Ciudad\ Real",
"34845", "Araba",
"349698", "Cuenca",
"34947", "Burgos",
"34971", "Balearic\ Islands",
"34967", "Albacete",
"34823", "Salamanca",
"34986", "Pontevedra",
"34878", "Teruel",
"34960", "Valencia",
"34879", "Palencia",
"349730", "Lleida",
"34862", "Valencia",
"34864", "Castellón",
"34842", "Cantabria",
"34844", "Bizkaia",
"349690602", "Cuenca",
"34843", "Guipúzcoa",
"34985", "Asturias",
"34851", "Málaga",
"34863", "Valencia",
"34927", "Cáceres",
"34825", "Toledo",
"34866", "Alicante",
"34887", "León",
"34846", "Bizkaia",
"34822", "Tenerife",
"349690619", "Cuenca",
"34824", "Badajoz",
"34920", "Ávila",
"34959", "Huelva",
"3497397", "Lleida",
"3497396", "Lleida",
"349738", "Lleida",
"3497398", "Lleida",
"34982", "Lugo",
"34984", "Asturias",
"34958", "Granada",
"3481", "Madrid",
"34880", "Zamora",
"3496909", "Cuenca",
"349690617", "Cuenca",};
$areanames{es} = {"34955", "Sevilla",
"349737", "Lérida",
"34873", "Lérida",
"34857", "Córdoba",
"3497399", "Lérida",
"34850", "Álmería",
"34988", "Orense",
"34954", "Sevilla",
"349731", "Lérida",
"34848", "Navarra",
"34957", "Córdoba",
"3497394", "Lérida",
"34981", "A\ Coruña",
"34888", "Orense",
"34854", "Sevilla",
"3497391", "Lérida",
"349733", "Lérida",
"34948", "Navarra",
"3497395", "Lérida",
"349735", "Lérida",
"349734", "Lérida",
"34945", "Álava",
"34871", "Baleares",
"349732", "Lérida",
"34944", "Vizcaya",
"3497393", "Lérida",
"3497392", "Lérida",
"34946", "Vizcaya",
"349736", "Lérida",
"34971", "Baleares",
"34845", "Álava",
"349730", "Lérida",
"34844", "Vizcaya",
"34846", "Vizcaya",
"349738", "Lérida",
"3497398", "Lérida",
"3497396", "Lérida",
"3497397", "Lérida",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+34|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;