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
our $VERSION = 1.20200904144531;

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
$areanames{en}->{3481} = "Madrid";
$areanames{en}->{34820} = "Ávila";
$areanames{en}->{34821} = "Segovia";
$areanames{en}->{34822} = "Tenerife";
$areanames{en}->{34823} = "Salamanca";
$areanames{en}->{34824} = "Badajoz";
$areanames{en}->{34825} = "Toledo";
$areanames{en}->{34826} = "Ciudad\ Real";
$areanames{en}->{34827} = "Cáceres";
$areanames{en}->{34828} = "Las\ Palmas";
$areanames{en}->{3483} = "Barcelona";
$areanames{en}->{34841} = "La\ Rioja";
$areanames{en}->{34842} = "Cantabria";
$areanames{en}->{34843} = "Guipúzcoa";
$areanames{en}->{34844} = "Bizkaia";
$areanames{en}->{34845} = "Araba";
$areanames{en}->{34846} = "Bizkaia";
$areanames{en}->{34847} = "Burgos";
$areanames{en}->{34848} = "Navarre";
$areanames{en}->{34849} = "Guadalajara";
$areanames{en}->{34850} = "Almería";
$areanames{en}->{34851} = "Málaga";
$areanames{en}->{34852} = "Málaga";
$areanames{en}->{34853} = "Jaén";
$areanames{en}->{34854} = "Seville";
$areanames{en}->{34855} = "Seville";
$areanames{en}->{34856} = "Cádiz";
$areanames{en}->{34857} = "Cordova";
$areanames{en}->{34858} = "Granada";
$areanames{en}->{34859} = "Huelva";
$areanames{en}->{34860} = "Valencia";
$areanames{en}->{34861} = "Valencia";
$areanames{en}->{34862} = "Valencia";
$areanames{en}->{34863} = "Valencia";
$areanames{en}->{34864} = "Castellón";
$areanames{en}->{34865} = "Alicante";
$areanames{en}->{34866} = "Alicante";
$areanames{en}->{34867} = "Albacete";
$areanames{en}->{34868} = "Murcia";
$areanames{en}->{34869} = "Cuenca";
$areanames{en}->{34871} = "Balearic\ Islands";
$areanames{en}->{34872} = "Gerona";
$areanames{en}->{34873} = "Lleida";
$areanames{en}->{34874} = "Huesca";
$areanames{en}->{34875} = "Soria";
$areanames{en}->{34876} = "Zaragoza";
$areanames{en}->{34877} = "Tarragona";
$areanames{en}->{34878} = "Teruel";
$areanames{en}->{34879} = "Palencia";
$areanames{en}->{34880} = "Zamora";
$areanames{en}->{34881} = "La\ Coruña";
$areanames{en}->{34882} = "Lugo";
$areanames{en}->{34883} = "Valladolid";
$areanames{en}->{34884} = "Asturias";
$areanames{en}->{34885} = "Asturias";
$areanames{en}->{34886} = "Pontevedra";
$areanames{en}->{34887} = "León";
$areanames{en}->{34888} = "Ourense";
$areanames{en}->{3491} = "Madrid";
$areanames{en}->{34920} = "Ávila";
$areanames{en}->{34921} = "Segovia";
$areanames{en}->{34922} = "Tenerife";
$areanames{en}->{34923} = "Salamanca";
$areanames{en}->{34924} = "Badajoz";
$areanames{en}->{34925} = "Toledo";
$areanames{en}->{34926} = "Ciudad\ Real";
$areanames{en}->{34927} = "Cáceres";
$areanames{en}->{34928} = "Las\ Palmas";
$areanames{en}->{3493} = "Barcelona";
$areanames{en}->{34941} = "La\ Rioja";
$areanames{en}->{34942} = "Cantabria";
$areanames{en}->{34943} = "Guipúzcoa";
$areanames{en}->{34944} = "Bizkaia";
$areanames{en}->{34945} = "Araba";
$areanames{en}->{34946} = "Bizkaia";
$areanames{en}->{34947} = "Burgos";
$areanames{en}->{34948} = "Navarre";
$areanames{en}->{34949} = "Guadalajara";
$areanames{en}->{34950} = "Almería";
$areanames{en}->{34951} = "Málaga";
$areanames{en}->{34952} = "Málaga";
$areanames{en}->{34953} = "Jaén";
$areanames{en}->{34954} = "Seville";
$areanames{en}->{34955} = "Seville";
$areanames{en}->{34956} = "Cádiz";
$areanames{en}->{34957} = "Cordova";
$areanames{en}->{34958} = "Granada";
$areanames{en}->{34959} = "Huelva";
$areanames{en}->{34960} = "Valencia";
$areanames{en}->{34961} = "Valencia";
$areanames{en}->{34962} = "Valencia";
$areanames{en}->{34963} = "Valencia";
$areanames{en}->{34964} = "Castellón";
$areanames{en}->{34965} = "Alicante";
$areanames{en}->{34966} = "Alicante";
$areanames{en}->{34967} = "Albacete";
$areanames{en}->{34968} = "Murcia";
$areanames{en}->{3496900} = "Cuenca";
$areanames{en}->{3496901} = "Cuenca";
$areanames{en}->{3496902} = "Cuenca";
$areanames{en}->{3496903} = "Cuenca";
$areanames{en}->{3496904} = "Cuenca";
$areanames{en}->{3496905} = "Cuenca";
$areanames{en}->{349690600} = "Cuenca";
$areanames{en}->{349690601} = "Cuenca";
$areanames{en}->{349690602} = "Cuenca";
$areanames{en}->{349690603} = "Cuenca";
$areanames{en}->{349690604} = "Cuenca";
$areanames{en}->{349690605} = "Cuenca";
$areanames{en}->{349690606} = "Cuenca";
$areanames{en}->{349690607} = "Cuenca";
$areanames{en}->{349690608} = "Cuenca";
$areanames{en}->{349690611} = "Cuenca";
$areanames{en}->{349690612} = "Cuenca";
$areanames{en}->{349690613} = "Cuenca";
$areanames{en}->{349690614} = "Cuenca";
$areanames{en}->{349690615} = "Cuenca";
$areanames{en}->{349690616} = "Cuenca";
$areanames{en}->{349690617} = "Cuenca";
$areanames{en}->{349690618} = "Cuenca";
$areanames{en}->{349690619} = "Cuenca";
$areanames{en}->{34969062} = "Cuenca";
$areanames{en}->{34969063} = "Cuenca";
$areanames{en}->{34969064} = "Cuenca";
$areanames{en}->{34969065} = "Cuenca";
$areanames{en}->{34969066} = "Cuenca";
$areanames{en}->{34969067} = "Cuenca";
$areanames{en}->{34969068} = "Cuenca";
$areanames{en}->{34969069} = "Cuenca";
$areanames{en}->{3496907} = "Cuenca";
$areanames{en}->{3496908} = "Cuenca";
$areanames{en}->{3496909} = "Cuenca";
$areanames{en}->{349691} = "Cuenca";
$areanames{en}->{349692} = "Cuenca";
$areanames{en}->{349693} = "Cuenca";
$areanames{en}->{349694} = "Cuenca";
$areanames{en}->{349695} = "Cuenca";
$areanames{en}->{349696} = "Cuenca";
$areanames{en}->{349697} = "Cuenca";
$areanames{en}->{349698} = "Cuenca";
$areanames{en}->{349699} = "Cuenca";
$areanames{en}->{34971} = "Balearic\ Islands";
$areanames{en}->{34972} = "Gerona";
$areanames{en}->{349730} = "Lleida";
$areanames{en}->{349731} = "Lleida";
$areanames{en}->{349732} = "Lleida";
$areanames{en}->{349733} = "Lleida";
$areanames{en}->{349734} = "Lleida";
$areanames{en}->{349735} = "Lleida";
$areanames{en}->{349736} = "Lleida";
$areanames{en}->{349737} = "Lleida";
$areanames{en}->{349738} = "Lleida";
$areanames{en}->{3497391} = "Lleida";
$areanames{en}->{3497392} = "Lleida";
$areanames{en}->{3497393} = "Lleida";
$areanames{en}->{3497394} = "Lleida";
$areanames{en}->{3497395} = "Lleida";
$areanames{en}->{3497396} = "Lleida";
$areanames{en}->{3497397} = "Lleida";
$areanames{en}->{3497398} = "Lleida";
$areanames{en}->{3497399} = "Lleida";
$areanames{en}->{34974} = "Huesca";
$areanames{en}->{34975} = "Soria";
$areanames{en}->{34976} = "Zaragoza";
$areanames{en}->{34977} = "Tarragona";
$areanames{en}->{34978} = "Teruel";
$areanames{en}->{34979} = "Palencia";
$areanames{en}->{34980} = "Zamora";
$areanames{en}->{34981} = "La\ Coruña";
$areanames{en}->{34982} = "Lugo";
$areanames{en}->{34983} = "Valladolid";
$areanames{en}->{34984} = "Asturias";
$areanames{en}->{34985} = "Asturias";
$areanames{en}->{34986} = "Pontevedra";
$areanames{en}->{34987} = "León";
$areanames{en}->{34988} = "Ourense";
$areanames{es}->{3481} = "Madrid";
$areanames{es}->{34820} = "Ávila";
$areanames{es}->{34821} = "Segovia";
$areanames{es}->{34822} = "Tenerife";
$areanames{es}->{34823} = "Salamanca";
$areanames{es}->{34824} = "Badajoz";
$areanames{es}->{34825} = "Toledo";
$areanames{es}->{34826} = "Ciudad\ Real";
$areanames{es}->{34827} = "Cáceres";
$areanames{es}->{34828} = "Las\ Palmas";
$areanames{es}->{3483} = "Barcelona";
$areanames{es}->{34841} = "La\ Rioja";
$areanames{es}->{34842} = "Cantabria";
$areanames{es}->{34843} = "Guipúzcoa";
$areanames{es}->{34844} = "Vizcaya";
$areanames{es}->{34845} = "Álava";
$areanames{es}->{34846} = "Vizcaya";
$areanames{es}->{34847} = "Burgos";
$areanames{es}->{34848} = "Navarra";
$areanames{es}->{34849} = "Guadalajara";
$areanames{es}->{34850} = "Álmería";
$areanames{es}->{34851} = "Málaga";
$areanames{es}->{34852} = "Málaga";
$areanames{es}->{34853} = "Jaén";
$areanames{es}->{34854} = "Sevilla";
$areanames{es}->{34855} = "Seville";
$areanames{es}->{34856} = "Cádiz";
$areanames{es}->{34857} = "Córdoba";
$areanames{es}->{34858} = "Granada";
$areanames{es}->{34859} = "Huelva";
$areanames{es}->{34860} = "Valencia";
$areanames{es}->{34861} = "Valencia";
$areanames{es}->{34862} = "Valencia";
$areanames{es}->{34863} = "Valencia";
$areanames{es}->{34864} = "Castellón";
$areanames{es}->{34865} = "Alicante";
$areanames{es}->{34866} = "Alicante";
$areanames{es}->{34867} = "Albacete";
$areanames{es}->{34868} = "Murcia";
$areanames{es}->{34869} = "Cuenca";
$areanames{es}->{34871} = "Baleares";
$areanames{es}->{34872} = "Gerona";
$areanames{es}->{34873} = "Lérida";
$areanames{es}->{34874} = "Huesca";
$areanames{es}->{34875} = "Soria";
$areanames{es}->{34876} = "Zaragoza";
$areanames{es}->{34877} = "Tarragona";
$areanames{es}->{34878} = "Teruel";
$areanames{es}->{34879} = "Palencia";
$areanames{es}->{34880} = "Zamora";
$areanames{es}->{34881} = "La\ Coruña";
$areanames{es}->{34882} = "Lugo";
$areanames{es}->{34883} = "Valladolid";
$areanames{es}->{34884} = "Asturias";
$areanames{es}->{34885} = "Asturias";
$areanames{es}->{34886} = "Pontevedra";
$areanames{es}->{34887} = "León";
$areanames{es}->{34888} = "Orense";
$areanames{es}->{3491} = "Madrid";
$areanames{es}->{34920} = "Ávila";
$areanames{es}->{34921} = "Segovia";
$areanames{es}->{34922} = "Tenerife";
$areanames{es}->{34923} = "Salamanca";
$areanames{es}->{34924} = "Badajoz";
$areanames{es}->{34925} = "Toledo";
$areanames{es}->{34926} = "Ciudad\ Real";
$areanames{es}->{34927} = "Cáceres";
$areanames{es}->{34928} = "Las\ Palmas";
$areanames{es}->{3493} = "Barcelona";
$areanames{es}->{34941} = "La\ Rioja";
$areanames{es}->{34942} = "Cantabria";
$areanames{es}->{34943} = "Guipúzcoa";
$areanames{es}->{34944} = "Vizcaya";
$areanames{es}->{34945} = "Álava";
$areanames{es}->{34946} = "Vizcaya";
$areanames{es}->{34947} = "Burgos";
$areanames{es}->{34948} = "Navarra";
$areanames{es}->{34949} = "Guadalajara";
$areanames{es}->{34950} = "Almería";
$areanames{es}->{34951} = "Málaga";
$areanames{es}->{34952} = "Málaga";
$areanames{es}->{34953} = "Jaén";
$areanames{es}->{34954} = "Sevilla";
$areanames{es}->{34955} = "Sevilla";
$areanames{es}->{34956} = "Cádiz";
$areanames{es}->{34957} = "Córdoba";
$areanames{es}->{34958} = "Granada";
$areanames{es}->{34959} = "Huelva";
$areanames{es}->{34960} = "Valencia";
$areanames{es}->{34961} = "Valencia";
$areanames{es}->{34962} = "Valencia";
$areanames{es}->{34963} = "Valencia";
$areanames{es}->{34964} = "Castellón";
$areanames{es}->{34965} = "Alicante";
$areanames{es}->{34966} = "Alicante";
$areanames{es}->{34967} = "Albacete";
$areanames{es}->{34968} = "Murcia";
$areanames{es}->{3496900} = "Cuenca";
$areanames{es}->{3496901} = "Cuenca";
$areanames{es}->{3496902} = "Cuenca";
$areanames{es}->{3496903} = "Cuenca";
$areanames{es}->{3496904} = "Cuenca";
$areanames{es}->{3496905} = "Cuenca";
$areanames{es}->{349690600} = "Cuenca";
$areanames{es}->{349690601} = "Cuenca";
$areanames{es}->{349690602} = "Cuenca";
$areanames{es}->{349690603} = "Cuenca";
$areanames{es}->{349690604} = "Cuenca";
$areanames{es}->{349690605} = "Cuenca";
$areanames{es}->{349690606} = "Cuenca";
$areanames{es}->{349690607} = "Cuenca";
$areanames{es}->{349690608} = "Cuenca";
$areanames{es}->{349690611} = "Cuenca";
$areanames{es}->{349690612} = "Cuenca";
$areanames{es}->{349690613} = "Cuenca";
$areanames{es}->{349690614} = "Cuenca";
$areanames{es}->{349690615} = "Cuenca";
$areanames{es}->{349690616} = "Cuenca";
$areanames{es}->{349690617} = "Cuenca";
$areanames{es}->{349690618} = "Cuenca";
$areanames{es}->{349690619} = "Cuenca";
$areanames{es}->{34969062} = "Cuenca";
$areanames{es}->{34969063} = "Cuenca";
$areanames{es}->{34969064} = "Cuenca";
$areanames{es}->{34969065} = "Cuenca";
$areanames{es}->{34969066} = "Cuenca";
$areanames{es}->{34969067} = "Cuenca";
$areanames{es}->{34969068} = "Cuenca";
$areanames{es}->{34969069} = "Cuenca";
$areanames{es}->{3496907} = "Cuenca";
$areanames{es}->{3496908} = "Cuenca";
$areanames{es}->{3496909} = "Cuenca";
$areanames{es}->{349691} = "Cuenca";
$areanames{es}->{349692} = "Cuenca";
$areanames{es}->{349693} = "Cuenca";
$areanames{es}->{349694} = "Cuenca";
$areanames{es}->{349695} = "Cuenca";
$areanames{es}->{349696} = "Cuenca";
$areanames{es}->{349697} = "Cuenca";
$areanames{es}->{349698} = "Cuenca";
$areanames{es}->{349699} = "Cuenca";
$areanames{es}->{34971} = "Baleares";
$areanames{es}->{34972} = "Gerona";
$areanames{es}->{349730} = "Lérida";
$areanames{es}->{349731} = "Lérida";
$areanames{es}->{349732} = "Lérida";
$areanames{es}->{349733} = "Lérida";
$areanames{es}->{349734} = "Lérida";
$areanames{es}->{349735} = "Lérida";
$areanames{es}->{349736} = "Lérida";
$areanames{es}->{349737} = "Lérida";
$areanames{es}->{349738} = "Lérida";
$areanames{es}->{3497391} = "Lérida";
$areanames{es}->{3497392} = "Lérida";
$areanames{es}->{3497393} = "Lérida";
$areanames{es}->{3497394} = "Lérida";
$areanames{es}->{3497395} = "Lérida";
$areanames{es}->{3497396} = "Lérida";
$areanames{es}->{3497397} = "Lérida";
$areanames{es}->{3497398} = "Lérida";
$areanames{es}->{3497399} = "Lérida";
$areanames{es}->{34974} = "Huesca";
$areanames{es}->{34975} = "Soria";
$areanames{es}->{34976} = "Zaragoza";
$areanames{es}->{34977} = "Tarragona";
$areanames{es}->{34978} = "Teruel";
$areanames{es}->{34979} = "Palencia";
$areanames{es}->{34980} = "Zamora";
$areanames{es}->{34981} = "A\ Coruña";
$areanames{es}->{34982} = "Lugo";
$areanames{es}->{34983} = "Valladolid";
$areanames{es}->{34984} = "Asturias";
$areanames{es}->{34985} = "Asturias";
$areanames{es}->{34986} = "Pontevedra";
$areanames{es}->{34987} = "León";
$areanames{es}->{34988} = "Orense";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+34|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;