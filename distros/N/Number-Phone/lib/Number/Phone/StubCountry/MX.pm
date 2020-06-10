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
package Number::Phone::StubCountry::MX;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200606132000;

my $formatters = [
                {
                  'format' => '$1',
                  'intl_format' => 'NA',
                  'leading_digits' => '53',
                  'pattern' => '(\\d{5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            33|
            5[56]|
            81
          ',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[2-9]',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$2 $3 $4',
                  'leading_digits' => '
            1(?:
              33|
              5[56]|
              81
            )
          ',
                  'pattern' => '(\\d)(\\d{2})(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$2 $3 $4',
                  'leading_digits' => '1',
                  'pattern' => '(\\d)(\\d{3})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              0[01]|
              2[1-9]|
              3[1-35-8]|
              4[13-9]|
              7[1-689]|
              8[1-578]|
              9[467]
            )|
            3(?:
              1[1-79]|
              [2458][1-9]|
              3\\d|
              7[1-8]|
              9[1-5]
            )|
            4(?:
              1[1-57-9]|
              [24-7][1-9]|
              3[1-8]|
              8[1-35-9]|
              9[2-689]
            )|
            5(?:
              [56]\\d|
              88|
              9[1-79]
            )|
            6(?:
              1[2-68]|
              [2-4][1-9]|
              5[1-3689]|
              6[1-57-9]|
              7[1-7]|
              8[67]|
              9[4-8]
            )|
            7(?:
              [1-467][1-9]|
              5[13-9]|
              8[1-69]|
              9[17]
            )|
            8(?:
              1\\d|
              2[13-689]|
              3[1-6]|
              4[124-6]|
              6[1246-9]|
              7[1-378]|
              9[12479]
            )|
            9(?:
              1[346-9]|
              2[1-4]|
              3[2-46-8]|
              5[1348]|
              [69][1-9]|
              7[12]|
              8[1-8]
            )
          )\\d{7}
        ',
                'geographic' => '
          (?:
            2(?:
              0[01]|
              2[1-9]|
              3[1-35-8]|
              4[13-9]|
              7[1-689]|
              8[1-578]|
              9[467]
            )|
            3(?:
              1[1-79]|
              [2458][1-9]|
              3\\d|
              7[1-8]|
              9[1-5]
            )|
            4(?:
              1[1-57-9]|
              [24-7][1-9]|
              3[1-8]|
              8[1-35-9]|
              9[2-689]
            )|
            5(?:
              [56]\\d|
              88|
              9[1-79]
            )|
            6(?:
              1[2-68]|
              [2-4][1-9]|
              5[1-3689]|
              6[1-57-9]|
              7[1-7]|
              8[67]|
              9[4-8]
            )|
            7(?:
              [1-467][1-9]|
              5[13-9]|
              8[1-69]|
              9[17]
            )|
            8(?:
              1\\d|
              2[13-689]|
              3[1-6]|
              4[124-6]|
              6[1246-9]|
              7[1-378]|
              9[12479]
            )|
            9(?:
              1[346-9]|
              2[1-4]|
              3[2-46-8]|
              5[1348]|
              [69][1-9]|
              7[12]|
              8[1-8]
            )
          )\\d{7}
        ',
                'mobile' => '
          (?:
            1(?:
              2(?:
                2[1-9]|
                3[1-35-8]|
                4[13-9]|
                7[1-689]|
                8[1-578]|
                9[467]
              )|
              3(?:
                1[1-79]|
                [2458][1-9]|
                3\\d|
                7[1-8]|
                9[1-5]
              )|
              4(?:
                1[1-57-9]|
                [24-7][1-9]|
                3[1-8]|
                8[1-35-9]|
                9[2-689]
              )|
              5(?:
                [56]\\d|
                88|
                9[1-79]
              )|
              6(?:
                1[2-68]|
                [2-4][1-9]|
                5[1-3689]|
                6[1-57-9]|
                7[1-7]|
                8[67]|
                9[4-8]
              )|
              7(?:
                [1-467][1-9]|
                5[13-9]|
                8[1-69]|
                9[17]
              )|
              8(?:
                1\\d|
                2[13-689]|
                3[1-6]|
                4[124-6]|
                6[1246-9]|
                7[1-378]|
                9[12479]
              )|
              9(?:
                1[346-9]|
                2[1-4]|
                3[2-46-8]|
                5[1348]|
                [69][1-9]|
                7[12]|
                8[1-8]
              )
            )|
            2(?:
              2[1-9]|
              3[1-35-8]|
              4[13-9]|
              7[1-689]|
              8[1-578]|
              9[467]
            )|
            3(?:
              1[1-79]|
              [2458][1-9]|
              3\\d|
              7[1-8]|
              9[1-5]
            )|
            4(?:
              1[1-57-9]|
              [24-7][1-9]|
              3[1-8]|
              8[1-35-9]|
              9[2-689]
            )|
            5(?:
              [56]\\d|
              88|
              9[1-79]
            )|
            6(?:
              1[2-68]|
              [2-4][1-9]|
              5[1-3689]|
              6[1-57-9]|
              7[1-7]|
              8[67]|
              9[4-8]
            )|
            7(?:
              [1-467][1-9]|
              5[13-9]|
              8[1-69]|
              9[17]
            )|
            8(?:
              1\\d|
              2[13-689]|
              3[1-6]|
              4[124-6]|
              6[1246-9]|
              7[1-378]|
              9[12479]
            )|
            9(?:
              1[346-9]|
              2[1-4]|
              3[2-46-8]|
              5[1348]|
              [69][1-9]|
              7[12]|
              8[1-8]
            )
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '500\\d{7}',
                'specialrate' => '(300\\d{7})|(900\\d{7})',
                'toll_free' => '
          8(?:
            00|
            88
          )\\d{7}
        ',
                'voip' => ''
              };
my %areanames = ();
$areanames{es}->{52221} = "Puebla";
$areanames{es}->{52222} = "Puebla";
$areanames{es}->{52223} = "Puebla";
$areanames{es}->{52224} = "Puebla";
$areanames{es}->{52225} = "Tlapacoyan\,\ VER";
$areanames{es}->{52226} = "Altotonga\/Jalacingo\,\ VER";
$areanames{es}->{52227} = "Huejotzingo\/San\ Buenaventura\ Nealtican\,\ PUE";
$areanames{es}->{52228} = "Jalapa\/Tuzamapan\,\ VER";
$areanames{es}->{52229} = "Veracruz\,\ VER";
$areanames{es}->{52231} = "Teteles\/Teziutlán\,\ PUE";
$areanames{es}->{52232} = "La\ Vigueta\/Martínez\ de\ la\ Torre\,\ VER";
$areanames{es}->{52233} = "Puebla";
$areanames{es}->{52235} = "Veracruz";
$areanames{es}->{52236} = "Oaxaca\/Puebla";
$areanames{es}->{52237} = "Puebla";
$areanames{es}->{52238} = "Santiago\ Miahuatlán\/Tehuacán\,\ PUE";
$areanames{es}->{52241} = "Tlaxcala";
$areanames{es}->{52243} = "Puebla";
$areanames{es}->{52244} = "Puebla";
$areanames{es}->{52245} = "Puebla";
$areanames{es}->{52246} = "Tlaxcala";
$areanames{es}->{52247} = "Huamantla\/San\ Cosme\ Xalostoc\,\ TLAX";
$areanames{es}->{52248} = "Puebla";
$areanames{es}->{52249} = "Puebla";
$areanames{es}->{52271} = "Veracruz";
$areanames{es}->{52272} = "Maltrata\/Orizaba\,\ VER";
$areanames{es}->{52273} = "Veracruz";
$areanames{es}->{52274} = "Oaxaca";
$areanames{es}->{52275} = "Puebla";
$areanames{es}->{52276} = "Puebla";
$areanames{es}->{52278} = "Veracruz";
$areanames{es}->{52279} = "Veracruz";
$areanames{es}->{52281} = "Loma\ Bonita\,\ OAX";
$areanames{es}->{52282} = "Puebla\/Veracruz";
$areanames{es}->{52283} = "Veracruz";
$areanames{es}->{52284} = "Ángel\ Rosario\ Cabada\/Lerdo\ de\ Tejada\,\ VER";
$areanames{es}->{52285} = "Veracruz";
$areanames{es}->{52287} = "Oaxaca";
$areanames{es}->{52288} = "Veracruz";
$areanames{es}->{52294} = "Veracruz";
$areanames{es}->{52296} = "Veracruz";
$areanames{es}->{52297} = "Alvarado\,\ VER";
$areanames{es}->{52311} = "Nayarit";
$areanames{es}->{52312} = "Colima\/Los\ Tepames\,\ COL";
$areanames{es}->{52313} = "Colima";
$areanames{es}->{52314} = "Manzanillo\/Peña\ Colorada\,\ COL";
$areanames{es}->{52315} = "Jalisco";
$areanames{es}->{52316} = "Jalisco";
$areanames{es}->{52317} = "Autlán\/El\ Chante\,\ JAL";
$areanames{es}->{52319} = "Nayarit";
$areanames{es}->{52321} = "El\ Grullo\/El\ Limon\,\ JAL";
$areanames{es}->{52322} = "Jalisco";
$areanames{es}->{52323} = "Nayarit";
$areanames{es}->{52324} = "Nayarit";
$areanames{es}->{52325} = "Acaponeta\,\ NAY";
$areanames{es}->{52326} = "Jalisco";
$areanames{es}->{52327} = "Nayarit";
$areanames{es}->{52328} = "Michoacán";
$areanames{es}->{52329} = "Nayarit";
$areanames{es}->{5233} = "Guadalajara\,\ JAL";
$areanames{es}->{52341} = "Ciudad\ Guzmán\,\ JAL";
$areanames{es}->{52342} = "Gómez\ Farías\/Sayula\,\ JAL";
$areanames{es}->{52343} = "Jalisco";
$areanames{es}->{52344} = "Mexticacan\/Yahualica\,\ JAL";
$areanames{es}->{52345} = "Jalisco";
$areanames{es}->{52346} = "Jalisco\/Zacatecas";
$areanames{es}->{52347} = "Jalisco";
$areanames{es}->{52348} = "Jalisco";
$areanames{es}->{52349} = "Jalisco";
$areanames{es}->{52351} = "Ario\ de\ Rayón\/Zamora\,\ MICH";
$areanames{es}->{52352} = "La\ Piedad\,\ MICH";
$areanames{es}->{52353} = "Michoacán";
$areanames{es}->{52354} = "Michoacán";
$areanames{es}->{52355} = "Michoacán";
$areanames{es}->{52356} = "Tanhuato\/Yurécuaro\,\ MICH";
$areanames{es}->{52357} = "Jalisco";
$areanames{es}->{52358} = "Tamazula\/Zapotiltic\,\ JAL";
$areanames{es}->{5237} = "Jalisco";
$areanames{es}->{52375} = "Ameca\,\ JAL";
$areanames{es}->{52377} = "Cocula\/Estipac\,\ JAL";
$areanames{es}->{52381} = "Cojumatlan\/San\ Jose\ de\ Gracia\,\ MICH";
$areanames{es}->{52382} = "Jalisco";
$areanames{es}->{52383} = "Michoacán";
$areanames{es}->{52384} = "Tala\/Teuchitlan\,\ JAL";
$areanames{es}->{52385} = "Jalisco";
$areanames{es}->{52386} = "Jalisco";
$areanames{es}->{52387} = "Jalisco";
$areanames{es}->{52388} = "Jalisco";
$areanames{es}->{52389} = "Nayarit";
$areanames{es}->{52391} = "Jalisco";
$areanames{es}->{52392} = "Jamay\/Ocotlán\,\ JAL";
$areanames{es}->{52393} = "Jalisco";
$areanames{es}->{52394} = "Cotija\ de\ la\ Paz\,\ MICH";
$areanames{es}->{52395} = "Jalisco";
$areanames{es}->{52411} = "Guanajuato";
$areanames{es}->{52412} = "Guanajuato";
$areanames{es}->{52413} = "Apaseo\ el\ Alto\/Apaseo\ el\ Grande\,\ GTO";
$areanames{es}->{52414} = "Tequisquiapan\,\ QRO";
$areanames{es}->{52415} = "San\ Miguel\ Allende\,\ GTO";
$areanames{es}->{52417} = "Guanajuato";
$areanames{es}->{52418} = "Dolores\ Hidalgo\/San\ Diego\ de\ la\ Unión\,\ GTO";
$areanames{es}->{52419} = "Guanajuato";
$areanames{es}->{52421} = "Guanajuato";
$areanames{es}->{52422} = "Michoacán";
$areanames{es}->{52423} = "Michoacán";
$areanames{es}->{52424} = "Michoacán";
$areanames{es}->{52425} = "Michoacán";
$areanames{es}->{52426} = "Michoacán";
$areanames{es}->{52427} = "México\/Quintana\ Roo";
$areanames{es}->{52428} = "Ocampo\/San\ Felipe\,\ GTO";
$areanames{es}->{52429} = "Guanajuato";
$areanames{es}->{52431} = "Jalostotitlán\/Villa\ Obregón\,\ JAL";
$areanames{es}->{52432} = "Ciudad\ Manuel\ Doblado\/Romita\,\ GTO";
$areanames{es}->{52433} = "Zacatecas";
$areanames{es}->{52434} = "Michoacán";
$areanames{es}->{52435} = "Huetamo\/San\ Lucas\,\ MICH";
$areanames{es}->{52436} = "Zacapu\,\ MICH";
$areanames{es}->{52437} = "Jalisco\/Zacatecas";
$areanames{es}->{52438} = "Michoacán";
$areanames{es}->{52441} = "Querétaro";
$areanames{es}->{52442} = "Querétaro";
$areanames{es}->{52443} = "Morelia\/Tarímbaro\,\ MICH";
$areanames{es}->{52444} = "San\ Luis\ Potosí\,\ SLP";
$areanames{es}->{52445} = "Moroleon\,\ GTO";
$areanames{es}->{52447} = "Contepec\/Maravatío\,\ MICH";
$areanames{es}->{52448} = "Querétaro";
$areanames{es}->{52449} = "Aguascalientes\/Jesús\ María\,\ AGS";
$areanames{es}->{52451} = "Michoacán";
$areanames{es}->{52452} = "Nuevo\ San\ Juan\ Parangaricutiro\/Uruapan\,\ MICH";
$areanames{es}->{52453} = "Apatzingán\,\ MICH";
$areanames{es}->{52454} = "Michoacán";
$areanames{es}->{52455} = "Michoacán";
$areanames{es}->{52456} = "Valle\ de\ Santiago\,\ GTO";
$areanames{es}->{52457} = "Jalisco\/Zacatecas";
$areanames{es}->{52458} = "Zacatecas";
$areanames{es}->{52459} = "Michoacán";
$areanames{es}->{52461} = "Guanajuato";
$areanames{es}->{52462} = "Irapuato\,\ GTO";
$areanames{es}->{52463} = "Jalpa\/Tabasco\,\ ZAC";
$areanames{es}->{52464} = "Salamanca\,\ GTO";
$areanames{es}->{52465} = "Aguascalientes";
$areanames{es}->{52466} = "Guanajuato";
$areanames{es}->{52467} = "Zacatecas";
$areanames{es}->{52468} = "San\ Luis\ de\ la\ Paz\,\ GTO";
$areanames{es}->{52469} = "Buenavista\ de\ Cortés\/Pénjamo\,\ GTO";
$areanames{es}->{52471} = "Purepero\/Tlazazalca\,\ MICH";
$areanames{es}->{52472} = "Silao\,\ GTO";
$areanames{es}->{52473} = "Guanajuato\,\ GTO";
$areanames{es}->{52474} = "Lagos\ de\ Moreno\/Paso\ de\ Cuarenta\,\ JAL";
$areanames{es}->{52475} = "Bajío\ de\ San\ José\/Encarnación\ de\ Diaz\,\ JAL";
$areanames{es}->{52476} = "San\ Francisco\ del\ Rincón\,\ GTO";
$areanames{es}->{52477} = "León\,\ GTO";
$areanames{es}->{52478} = "Calera\ Victor\ Rosales\,\ ZAC";
$areanames{es}->{5248} = "San\ Luis\ Potosí";
$areanames{es}->{52481} = "Ciudad\ Valles\,\ SLP";
$areanames{es}->{52492} = "Zacatecas";
$areanames{es}->{52493} = "Fresnillo\,\ ZAC";
$areanames{es}->{52494} = "Jerez\ de\ García\ Salinas\,\ ZAC";
$areanames{es}->{52495} = "Aguascalientes\/Jalisco";
$areanames{es}->{52496} = "Zacatecas";
$areanames{es}->{52498} = "Zacatecas";
$areanames{es}->{52499} = "Jalisco\/Zacatecas";
$areanames{es}->{5255} = "Ciudad\ de\ México\,\ CDMX";
$areanames{es}->{5258} = "Estado\ de\ Mexico";
$areanames{es}->{52591} = "Estado\ de\ Mexico";
$areanames{es}->{52592} = "Estado\ de\ Mexico";
$areanames{es}->{52593} = "Estado\ de\ Mexico";
$areanames{es}->{52594} = "Estado\ de\ Mexico";
$areanames{es}->{52595} = "Estado\ de\ Mexico";
$areanames{es}->{52596} = "Estado\ de\ Mexico";
$areanames{es}->{52599} = "Estado\ de\ Mexico";
$areanames{es}->{52612} = "La\ Paz\/Todos\ Santos\,\ BCS";
$areanames{es}->{52613} = "Baja\ California\ Sur";
$areanames{es}->{52614} = "Chihuahua";
$areanames{es}->{52615} = "Baja\ California\ Sur";
$areanames{es}->{52616} = "Baja\ California";
$areanames{es}->{52618} = "Colonia\ Hidalgo\/Durango\,\ DGO";
$areanames{es}->{52621} = "Chihuahua";
$areanames{es}->{52622} = "Guaymas\/San\ Carlos\,\ SON";
$areanames{es}->{52623} = "Sonora";
$areanames{es}->{52624} = "Baja\ California\ Sur";
$areanames{es}->{52625} = "Chihuahua";
$areanames{es}->{52626} = "Ojinaga\,\ CHIH";
$areanames{es}->{52627} = "Parral\,\ CHIH";
$areanames{es}->{52628} = "Chihuahua";
$areanames{es}->{52629} = "Chihuahua";
$areanames{es}->{52631} = "Nogales\,\ SON";
$areanames{es}->{52632} = "Ímuris\/Magdalena\,\ SON";
$areanames{es}->{52633} = "Sonora";
$areanames{es}->{52634} = "Sonora";
$areanames{es}->{52635} = "Chihuahua";
$areanames{es}->{52636} = "Chihuahua";
$areanames{es}->{52637} = "Altar\/Caborca\,\ SON";
$areanames{es}->{52638} = "Puerto\ Penasco\,\ SON";
$areanames{es}->{52639} = "Chihuahua";
$areanames{es}->{52641} = "Benjamín\ Hill\/Santa\ Ana\,\ SON";
$areanames{es}->{52642} = "Navojoa\/Pueblo\ Mayo\,\ SON";
$areanames{es}->{52643} = "Sonora";
$areanames{es}->{52644} = "Sonora";
$areanames{es}->{52645} = "Cananea\,\ SON";
$areanames{es}->{52646} = "Baja\ California";
$areanames{es}->{52647} = "Sonora";
$areanames{es}->{52648} = "Boquilla\/Ciudad\ Camargo\,\ CHIH";
$areanames{es}->{52649} = "Chihuahua\/Durango";
$areanames{es}->{52651} = "Sonoita\,\ SON";
$areanames{es}->{52652} = "Chihuahua";
$areanames{es}->{52653} = "Luis\ B\.\ Sánchez\/San\ Luis\ Río\ Colorado\,\ SON";
$areanames{es}->{52656} = "Chihuahua";
$areanames{es}->{52658} = "Baja\ California";
$areanames{es}->{52659} = "Chihuahua";
$areanames{es}->{52661} = "Primo\ Tapia\/Rosarito\,\ BCN";
$areanames{es}->{52662} = "Sonora";
$areanames{es}->{52665} = "Tecate\,\ BCN";
$areanames{es}->{52667} = "Sinaloa";
$areanames{es}->{52668} = "Sinaloa";
$areanames{es}->{52669} = "Sinaloa";
$areanames{es}->{52671} = "Durango";
$areanames{es}->{52672} = "Sinaloa";
$areanames{es}->{52673} = "Sinaloa";
$areanames{es}->{52674} = "Durango";
$areanames{es}->{52675} = "Durango";
$areanames{es}->{52676} = "Durango";
$areanames{es}->{52677} = "Durango";
$areanames{es}->{52686} = "Baja\ California";
$areanames{es}->{52687} = "Sinaloa";
$areanames{es}->{5269} = "Sinaloa";
$areanames{es}->{52711} = "México\/Michoacán";
$areanames{es}->{52712} = "Estado\ de\ Mexico";
$areanames{es}->{52713} = "Santiago\ Tianguistenco\,\ MEX";
$areanames{es}->{52714} = "Estado\ de\ Mexico";
$areanames{es}->{52715} = "Michoacán";
$areanames{es}->{52716} = "Estado\ de\ Mexico";
$areanames{es}->{52717} = "Estado\ de\ Mexico";
$areanames{es}->{52718} = "Estado\ de\ Mexico";
$areanames{es}->{52719} = "San\ Francisco\ Xonacatlán\/Temoaya\,\ MEX";
$areanames{es}->{52721} = "Ixtapan\ de\ la\ Sal\,\ MEX";
$areanames{es}->{52722} = "Estado\ de\ Mexico";
$areanames{es}->{52723} = "Coatepec\ Harinas\,\ MEX";
$areanames{es}->{52724} = "Luvianos\/Tejupilco\ de\ Hidalgo\,\ MEX";
$areanames{es}->{52725} = "Almoloya\ de\ Juárez\/Santa\ María\ del\ Monte\,\ MEX";
$areanames{es}->{52726} = "Estado\ de\ Mexico";
$areanames{es}->{52727} = "Guerrero";
$areanames{es}->{52728} = "Lerma\/Santa\ María\ Atarasquillo\,\ MEX";
$areanames{es}->{52729} = "Estado\ de\ Mexico";
$areanames{es}->{52731} = "Morelos";
$areanames{es}->{52732} = "Guerrero";
$areanames{es}->{52733} = "Iguala\,\ GRO";
$areanames{es}->{52734} = "Morelos";
$areanames{es}->{52735} = "Cuautla\/Jonacatepec\,\ MOR";
$areanames{es}->{52736} = "Guerrero";
$areanames{es}->{52737} = "Morelos";
$areanames{es}->{52738} = "Mixquiahuala\/Tepatepec\,\ HGO";
$areanames{es}->{52739} = "Huitzilac\/Tepoztlan\,\ MOR";
$areanames{es}->{52741} = "Guerrero";
$areanames{es}->{52742} = "Guerrero";
$areanames{es}->{52743} = "Hidalgo";
$areanames{es}->{52744} = "Acapulco\/Xaltianguis\,\ GRO";
$areanames{es}->{52745} = "Guerrero";
$areanames{es}->{52746} = "Puebla\/Veracruz";
$areanames{es}->{52747} = "Guerrero";
$areanames{es}->{52748} = "Hidalgo";
$areanames{es}->{52749} = "Calpulalpan\,\ TLAX";
$areanames{es}->{52751} = "Morelos";
$areanames{es}->{52753} = "Michoacán";
$areanames{es}->{52754} = "Guerrero";
$areanames{es}->{52755} = "Ixtapa\/Zihuatanejo\,\ GRO";
$areanames{es}->{52756} = "Chilapa\/Olinalá\,\ GRO";
$areanames{es}->{52757} = "Huamuxtitlan\/Tlapa\ de\ Comonfort\,\ GRO";
$areanames{es}->{52758} = "Petatlan\/San\ Jeronimito\,\ GRO";
$areanames{es}->{52759} = "Hidalgo";
$areanames{es}->{52761} = "Hidalgo";
$areanames{es}->{52762} = "Taxco\,\ GRO";
$areanames{es}->{52763} = "Tezontepec\ de\ Aldama\/Tlahuelilpan\,\ HGO";
$areanames{es}->{52764} = "Puebla";
$areanames{es}->{52765} = "Álamo\ Temapache\/Alazán\/Potrero\ del\ Llano\,\ VER";
$areanames{es}->{52766} = "Gutiérrez\ Zamora\/Tecolutla\,\ VER";
$areanames{es}->{52767} = "Guerrero";
$areanames{es}->{52768} = "Veracruz";
$areanames{es}->{52769} = "Morelos";
$areanames{es}->{52771} = "Pachuca\/Real\ del\ Monte\,\ HGO";
$areanames{es}->{52772} = "Actopan\,\ HGO";
$areanames{es}->{52773} = "Hidalgo";
$areanames{es}->{52774} = "Hidalgo";
$areanames{es}->{52775} = "Tulancingo\,\ HGO";
$areanames{es}->{52776} = "Puebla";
$areanames{es}->{52777} = "Morelos";
$areanames{es}->{52778} = "Hidalgo";
$areanames{es}->{52779} = "Tizayuca\,\ HGO";
$areanames{es}->{52781} = "Coyuca\ de\ Benítez\/San\ Jerónimo\ de\ Juárez\,\ GRO";
$areanames{es}->{52782} = "Poza\ Rica\,\ VER";
$areanames{es}->{52783} = "Tuxpan\,\ VER";
$areanames{es}->{52784} = "Veracruz";
$areanames{es}->{52785} = "Veracruz";
$areanames{es}->{52786} = "Ciudad\ Hidalgo\/Tuxpan\,\ MICH";
$areanames{es}->{52789} = "Veracruz";
$areanames{es}->{52791} = "Ciudad\ Sahagún\,\ HGO";
$areanames{es}->{52797} = "Puebla";
$areanames{es}->{5281} = "Monterrey\,\ NL";
$areanames{es}->{52821} = "Hualahuises\/Linares\,\ NL";
$areanames{es}->{52823} = "Nuevo\ León";
$areanames{es}->{52824} = "Sabinas\ Hidalgo\,\ NL";
$areanames{es}->{52825} = "Nuevo\ León";
$areanames{es}->{52826} = "Nuevo\ León";
$areanames{es}->{52828} = "Cadereyta\,\ NL";
$areanames{es}->{52829} = "Nuevo\ León";
$areanames{es}->{52831} = "Ciudad\ Mante\/Los\ Aztecas\,\ TAMPS";
$areanames{es}->{52832} = "Tamaulipas";
$areanames{es}->{52833} = "Tampico\,\ TAMPS";
$areanames{es}->{52834} = "Ciudad\ Victoria\,\ TAMPS";
$areanames{es}->{52835} = "Tamaulipas";
$areanames{es}->{52836} = "Tamaulipas";
$areanames{es}->{52841} = "Tamaulipas";
$areanames{es}->{52842} = "Coahuila";
$areanames{es}->{52844} = "Saltillo\,\ COAH";
$areanames{es}->{52845} = "Ebano\/Ponciano\ Arriaga\,\ SLP";
$areanames{es}->{52846} = "Veracruz";
$areanames{es}->{52861} = "Nueva\ Rosita\/Sabinas\,\ COAH";
$areanames{es}->{52862} = "Coahuila";
$areanames{es}->{52864} = "Coahuila";
$areanames{es}->{52866} = "Castaños\/Monclova\,\ COAH";
$areanames{es}->{52867} = "Nuevo\ León\/Tamaulipas";
$areanames{es}->{52868} = "Tamaulipas";
$areanames{es}->{52869} = "Cuatro\ Ciénegas\/San\ Buenaventura\,\ COAH";
$areanames{es}->{52871} = "Coahuila";
$areanames{es}->{52872} = "Coahuila\/Durango";
$areanames{es}->{52873} = "Nuevo\ León";
$areanames{es}->{52877} = "Ciudad\ Acuña\,\ COAH";
$areanames{es}->{52878} = "Piedras\ Negras\,\ COAH";
$areanames{es}->{52891} = "Tamaulipas";
$areanames{es}->{52892} = "Nuevo\ León";
$areanames{es}->{52894} = "Santa\ Apolonia\/Valle\ Hermoso\,\ TAMPS";
$areanames{es}->{52897} = "Tamaulipas";
$areanames{es}->{52899} = "Tamaulipas";
$areanames{es}->{52913} = "Tabasco";
$areanames{es}->{52914} = "Tabasco";
$areanames{es}->{52916} = "Chiapas";
$areanames{es}->{52917} = "Tabasco";
$areanames{es}->{52918} = "Chiapas";
$areanames{es}->{52919} = "Chiapas";
$areanames{es}->{52921} = "Coatzacoalcos\/Ixhuatlán\ del\ Sureste\,\ VER";
$areanames{es}->{52922} = "Veracruz";
$areanames{es}->{52923} = "Tabasco\/Veracruz";
$areanames{es}->{52924} = "Veracruz";
$areanames{es}->{52932} = "Chiapas\/Tabasco";
$areanames{es}->{52933} = "Tabasco";
$areanames{es}->{52934} = "Tabasco";
$areanames{es}->{52936} = "Tabasco";
$areanames{es}->{52937} = "Cárdenas\,\ TAB";
$areanames{es}->{52938} = "Ciudad\ del\ Carmen\,\ CAMP";
$areanames{es}->{5295} = "Oaxaca";
$areanames{es}->{5296} = "Chiapas";
$areanames{es}->{52966} = "Arriaga\/Tonalá\,\ CHIS";
$areanames{es}->{52967} = "San\ Cristóbal\ de\ las\ Casas\,\ CHIS";
$areanames{es}->{52969} = "Flamboyanes\/Yucalpeten\,\ YUC";
$areanames{es}->{5297} = "Oaxaca";
$areanames{es}->{52981} = "Campeche\,\ CAMP";
$areanames{es}->{52982} = "Campeche";
$areanames{es}->{52983} = "Quintana\ Roo";
$areanames{es}->{52984} = "Quintana\ Roo";
$areanames{es}->{52985} = "Yucatán";
$areanames{es}->{52986} = "Yucatán";
$areanames{es}->{52987} = "Cozumel\,\ QRO";
$areanames{es}->{52988} = "Yucatán";
$areanames{es}->{52991} = "Yucatán";
$areanames{es}->{52992} = "Chiapas";
$areanames{es}->{52993} = "Tabasco";
$areanames{es}->{52994} = "Oaxaca";
$areanames{es}->{52995} = "Magdalena\ Tequisistlán\/Santa\ Maria\ Jalapa\ del\ Marqués\,\ OAX";
$areanames{es}->{52996} = "Campeche";
$areanames{es}->{52997} = "Yucatán";
$areanames{es}->{52998} = "Quintana\ Roo";
$areanames{es}->{52999} = "Conkal\/Mérida\,\ YUC";
$areanames{en}->{52221} = "Puebla";
$areanames{en}->{52222} = "Puebla";
$areanames{en}->{52223} = "Puebla";
$areanames{en}->{52224} = "Puebla";
$areanames{en}->{52225} = "Tlapacoyan\,\ VER";
$areanames{en}->{52226} = "Altotonga\/Jalacingo\,\ VER";
$areanames{en}->{52227} = "Huejotzingo\/San\ Buenaventura\ Nealtican\,\ PUE";
$areanames{en}->{52228} = "Jalapa\/Tuzamapan\,\ VER";
$areanames{en}->{52229} = "Veracruz\,\ VER";
$areanames{en}->{52231} = "Teteles\/Teziutlan\,\ PUE";
$areanames{en}->{52232} = "La\ Vigueta\/Martinez\ de\ la\ Torre\,\ VER";
$areanames{en}->{52233} = "Puebla";
$areanames{en}->{52235} = "Veracruz";
$areanames{en}->{52236} = "Oaxaca\/Puebla";
$areanames{en}->{52237} = "Puebla";
$areanames{en}->{52238} = "Santiago\ Miahuatlan\/Tehuacan\,\ PUE";
$areanames{en}->{52241} = "Tlaxcala";
$areanames{en}->{52243} = "Puebla";
$areanames{en}->{52244} = "Puebla";
$areanames{en}->{52245} = "Puebla";
$areanames{en}->{52246} = "Tlaxcala";
$areanames{en}->{52247} = "Huamantla\/San\ Cosme\ Xalostoc\,\ TLAX";
$areanames{en}->{52248} = "Puebla";
$areanames{en}->{52249} = "Puebla";
$areanames{en}->{52271} = "Veracruz";
$areanames{en}->{52272} = "Maltrata\/Orizaba\,\ VER";
$areanames{en}->{52273} = "Veracruz";
$areanames{en}->{52274} = "Oaxaca";
$areanames{en}->{52275} = "Puebla";
$areanames{en}->{52276} = "Puebla";
$areanames{en}->{52278} = "Veracruz";
$areanames{en}->{52279} = "Veracruz";
$areanames{en}->{52281} = "Loma\ Bonita\,\ OAX";
$areanames{en}->{52282} = "Puebla\/Veracruz";
$areanames{en}->{52283} = "Veracruz";
$areanames{en}->{52284} = "Angel\ Rosario\ Cabada\/Lerdo\ de\ Tejada\,\ VER";
$areanames{en}->{52285} = "Veracruz";
$areanames{en}->{52287} = "Oaxaca";
$areanames{en}->{52288} = "Veracruz";
$areanames{en}->{52294} = "Veracruz";
$areanames{en}->{52296} = "Veracruz";
$areanames{en}->{52297} = "Alvarado\,\ VER";
$areanames{en}->{52311} = "Nayarit";
$areanames{en}->{52312} = "Colima\/Los\ Tepames\,\ COL";
$areanames{en}->{52313} = "Colima";
$areanames{en}->{52314} = "Manzanillo\/Pena\ Colorada\,\ COL";
$areanames{en}->{52315} = "Jalisco";
$areanames{en}->{52316} = "Jalisco";
$areanames{en}->{52317} = "Autlan\/El\ Chante\,\ JAL";
$areanames{en}->{52319} = "Nayarit";
$areanames{en}->{52321} = "El\ Grullo\/El\ Limon\,\ JAL";
$areanames{en}->{52322} = "Jalisco";
$areanames{en}->{52323} = "Nayarit";
$areanames{en}->{52324} = "Nayarit";
$areanames{en}->{52325} = "Acaponeta\,\ NAY";
$areanames{en}->{52326} = "Jalisco";
$areanames{en}->{52327} = "Nayarit";
$areanames{en}->{52328} = "Michoacan";
$areanames{en}->{52329} = "Nayarit";
$areanames{en}->{5233} = "Guadalajara\,\ JAL";
$areanames{en}->{52341} = "Ciudad\ Guzman\,\ JAL";
$areanames{en}->{52342} = "Gomez\ Farias\/Sayula\,\ JAL";
$areanames{en}->{52343} = "Jalisco";
$areanames{en}->{52344} = "Mexticacan\/Yahualica\,\ JAL";
$areanames{en}->{52345} = "Jalisco";
$areanames{en}->{52346} = "Jalisco\/Zacatecas";
$areanames{en}->{52347} = "Jalisco";
$areanames{en}->{52348} = "Jalisco";
$areanames{en}->{52349} = "Jalisco";
$areanames{en}->{52351} = "Ario\ de\ Rayon\/Zamora\,\ MICH";
$areanames{en}->{52352} = "La\ Piedad\,\ MICH";
$areanames{en}->{52353} = "Michoacan";
$areanames{en}->{52354} = "Michoacan";
$areanames{en}->{52355} = "Michoacan";
$areanames{en}->{52356} = "Tanhuato\/Yurecuaro\,\ MICH";
$areanames{en}->{52357} = "Jalisco";
$areanames{en}->{52358} = "Tamazula\/Zapoltitic\,\ JAL";
$areanames{en}->{5237} = "Jalisco";
$areanames{en}->{52375} = "Ameca\,\ JAL";
$areanames{en}->{52377} = "Cocula\/Estipac\,\ JAL";
$areanames{en}->{52381} = "Cojumatlan\/San\ Jose\ de\ Gracia\,\ MICH";
$areanames{en}->{52382} = "Jalisco";
$areanames{en}->{52383} = "Michoacan";
$areanames{en}->{52384} = "Tala\/Teuchitlan\,\ JAL";
$areanames{en}->{52385} = "Jalisco";
$areanames{en}->{52386} = "Jalisco";
$areanames{en}->{52387} = "Jalisco";
$areanames{en}->{52388} = "Jalisco";
$areanames{en}->{52389} = "Nayarit";
$areanames{en}->{52391} = "Jalisco";
$areanames{en}->{52392} = "Jamay\/Ocotlan\,\ JAL";
$areanames{en}->{52393} = "Jalisco";
$areanames{en}->{52394} = "Cotija\ de\ la\ Paz\,\ MICH";
$areanames{en}->{52395} = "Jalisco";
$areanames{en}->{52411} = "Guanajuato";
$areanames{en}->{52412} = "Guanajuato";
$areanames{en}->{52413} = "Apaseo\ el\ Alto\/Apaseo\ el\ Grande\,\ GTO";
$areanames{en}->{52414} = "Tequisquiapan\,\ QRO";
$areanames{en}->{52415} = "San\ Miguel\ Allende\,\ GTO";
$areanames{en}->{52417} = "Guanajuato";
$areanames{en}->{52418} = "Dolores\ Hidalgo\/San\ Diego\ de\ la\ Union\,\ GTO";
$areanames{en}->{52419} = "Guanajuato";
$areanames{en}->{52421} = "Guanajuato";
$areanames{en}->{52422} = "Michoacan";
$areanames{en}->{52423} = "Michoacan";
$areanames{en}->{52424} = "Michoacan";
$areanames{en}->{52425} = "Michoacan";
$areanames{en}->{52426} = "Michoacan";
$areanames{en}->{52427} = "Mexico\/Quintana\ Roo";
$areanames{en}->{52428} = "Ocampo\/San\ Felipe\,\ GTO";
$areanames{en}->{52429} = "Guanajuato";
$areanames{en}->{52431} = "Jalostotitlan\/Villa\ Obregon\,\ JAL";
$areanames{en}->{52432} = "Ciudad\ Manuel\ Doblado\/Romita\,\ GTO";
$areanames{en}->{52433} = "Zacatecas";
$areanames{en}->{52434} = "Michoacan";
$areanames{en}->{52435} = "Huetamo\/San\ Lucas\,\ MICH";
$areanames{en}->{52436} = "Zacapu\,\ MICH";
$areanames{en}->{52437} = "Jalisco\/Zacatecas";
$areanames{en}->{52438} = "Michoacan";
$areanames{en}->{52441} = "Queretaro";
$areanames{en}->{52442} = "Queretaro";
$areanames{en}->{52443} = "Morelia\/Tarimbaro\,\ MICH";
$areanames{en}->{52444} = "San\ Luis\ Potosi\,\ SLP";
$areanames{en}->{52445} = "Moroleon\,\ GTO";
$areanames{en}->{52447} = "Contepec\/Maravatio\,\ MICH";
$areanames{en}->{52448} = "Queretaro";
$areanames{en}->{52449} = "Aguascalientes\/Jesus\ Maria\,\ AGS";
$areanames{en}->{52451} = "Michoacan";
$areanames{en}->{52452} = "Nuevo\ San\ Juan\ Parangaricutiro\/Uruapan\,\ MICH";
$areanames{en}->{52453} = "Apatzingan\,\ MICH";
$areanames{en}->{52454} = "Michoacan";
$areanames{en}->{52455} = "Michoacan";
$areanames{en}->{52456} = "Valle\ de\ Santiago\,\ GTO";
$areanames{en}->{52457} = "Jalisco\/Zacatecas";
$areanames{en}->{52458} = "Zacatecas";
$areanames{en}->{52459} = "Michoacan";
$areanames{en}->{52461} = "Guanajuato";
$areanames{en}->{52462} = "Irapuato\,\ GTO";
$areanames{en}->{52463} = "Jalpa\/Tabasco\,\ ZAC";
$areanames{en}->{52464} = "Salamanca\,\ GTO";
$areanames{en}->{52465} = "Aguascalientes";
$areanames{en}->{52466} = "Guanajuato";
$areanames{en}->{52467} = "Zacatecas";
$areanames{en}->{52468} = "San\ Luis\ de\ la\ Paz\,\ GTO";
$areanames{en}->{52469} = "Buenavista\ de\ Cortez\/Penjamo\,\ GTO";
$areanames{en}->{52471} = "Purepero\/Tlazazalca\,\ MICH";
$areanames{en}->{52472} = "Silao\,\ GTO";
$areanames{en}->{52473} = "Guanajuato\,\ GTO";
$areanames{en}->{52474} = "Lagos\ de\ Moreno\/Paso\ de\ Cuarenta\,\ JAL";
$areanames{en}->{52475} = "Bajio\ de\ San\ Jose\/Encarnacion\ de\ Diaz\,\ JAL";
$areanames{en}->{52476} = "San\ Francisco\ Del\ Rincon\,\ GTO";
$areanames{en}->{52477} = "Leon\,\ GTO";
$areanames{en}->{52478} = "Calera\ Victor\ Rosales\,\ ZAC";
$areanames{en}->{5248} = "San\ Luis\ Potosi";
$areanames{en}->{52481} = "Ciudad\ Valles\,\ SLP";
$areanames{en}->{52492} = "Zacatecas";
$areanames{en}->{52493} = "Fresnillo\,\ ZAC";
$areanames{en}->{52494} = "Jerez\ de\ Garcia\ Salinas\,\ ZAC";
$areanames{en}->{52495} = "Aguascalientes\/Jalisco";
$areanames{en}->{52496} = "Zacatecas";
$areanames{en}->{52498} = "Zacatecas";
$areanames{en}->{52499} = "Jalisco\/Zacatecas";
$areanames{en}->{5255} = "Mexico\ City\,\ FD";
$areanames{en}->{5258} = "Estado\ de\ Mexico";
$areanames{en}->{52591} = "Estado\ de\ Mexico";
$areanames{en}->{52592} = "Estado\ de\ Mexico";
$areanames{en}->{52593} = "Estado\ de\ Mexico";
$areanames{en}->{52594} = "Estado\ de\ Mexico";
$areanames{en}->{52595} = "Estado\ de\ Mexico";
$areanames{en}->{52596} = "Estado\ de\ Mexico";
$areanames{en}->{52599} = "Estado\ de\ Mexico";
$areanames{en}->{52612} = "La\ Paz\/Todos\ Santos\,\ BCS";
$areanames{en}->{52613} = "Baja\ California\ Sur";
$areanames{en}->{52614} = "Chihuahua";
$areanames{en}->{52615} = "Baja\ California\ Sur";
$areanames{en}->{52616} = "Baja\ California";
$areanames{en}->{52618} = "Colonia\ Hidalgo\/Durango\,\ DGO";
$areanames{en}->{52621} = "Chihuahua";
$areanames{en}->{52622} = "Guaymas\/San\ Carlos\,\ SON";
$areanames{en}->{52623} = "Sonora";
$areanames{en}->{52624} = "Baja\ California\ Sur";
$areanames{en}->{52625} = "Chihuahua";
$areanames{en}->{52626} = "Ojinaga\,\ CHIH";
$areanames{en}->{52627} = "Parral\,\ CHIH";
$areanames{en}->{52628} = "Chihuahua";
$areanames{en}->{52629} = "Chihuahua";
$areanames{en}->{52631} = "Nogales\,\ SON";
$areanames{en}->{52632} = "Imuris\/Magdalena\,\ SON";
$areanames{en}->{52633} = "Sonora";
$areanames{en}->{52634} = "Sonora";
$areanames{en}->{52635} = "Chihuahua";
$areanames{en}->{52636} = "Chihuahua";
$areanames{en}->{52637} = "Altar\/Caborca\,\ SON";
$areanames{en}->{52638} = "Puerto\ Penasco\,\ SON";
$areanames{en}->{52639} = "Chihuahua";
$areanames{en}->{52641} = "Benjamin\ Hill\/Santa\ Ana\,\ SON";
$areanames{en}->{52642} = "Navojoa\/Pueblo\ Mayo\,\ SON";
$areanames{en}->{52643} = "Sonora";
$areanames{en}->{52644} = "Sonora";
$areanames{en}->{52645} = "Cananea\,\ SON";
$areanames{en}->{52646} = "Baja\ California";
$areanames{en}->{52647} = "Sonora";
$areanames{en}->{52648} = "Boquilla\/Ciudad\ Camargo\,\ CHIH";
$areanames{en}->{52649} = "Chihuahua\/Durango";
$areanames{en}->{52651} = "Sonoita\,\ SON";
$areanames{en}->{52652} = "Chihuahua";
$areanames{en}->{52653} = "Luis\ B\.\ Sanchez\/San\ Luis\ Rio\ Colorado\,\ SON";
$areanames{en}->{52656} = "Chihuahua";
$areanames{en}->{52658} = "Baja\ California";
$areanames{en}->{52659} = "Chihuahua";
$areanames{en}->{52661} = "Primo\ Tapia\/Rosarito\,\ BCN";
$areanames{en}->{52662} = "Sonora";
$areanames{en}->{52665} = "Tecate\,\ BCN";
$areanames{en}->{52667} = "Sinaloa";
$areanames{en}->{52668} = "Sinaloa";
$areanames{en}->{52669} = "Sinaloa";
$areanames{en}->{52671} = "Durango";
$areanames{en}->{52672} = "Sinaloa";
$areanames{en}->{52673} = "Sinaloa";
$areanames{en}->{52674} = "Durango";
$areanames{en}->{52675} = "Durango";
$areanames{en}->{52676} = "Durango";
$areanames{en}->{52677} = "Durango";
$areanames{en}->{52686} = "Baja\ California";
$areanames{en}->{52687} = "Sinaloa";
$areanames{en}->{5269} = "Sinaloa";
$areanames{en}->{52711} = "Mexico\/Michoacan";
$areanames{en}->{52712} = "Estado\ de\ Mexico";
$areanames{en}->{52713} = "Santiago\ Tianguistenco\,\ MEX";
$areanames{en}->{52714} = "Estado\ de\ Mexico";
$areanames{en}->{52715} = "Michoacan";
$areanames{en}->{52716} = "Estado\ de\ Mexico";
$areanames{en}->{52717} = "Estado\ de\ Mexico";
$areanames{en}->{52718} = "Estado\ de\ Mexico";
$areanames{en}->{52719} = "San\ Francisco\ Xonacatlan\/Temoaya\,\ MEX";
$areanames{en}->{52721} = "Ixtapan\ de\ la\ Sal\,\ MEX";
$areanames{en}->{52722} = "Estado\ de\ Mexico";
$areanames{en}->{52723} = "Coatepec\ Harinas\,\ MEX";
$areanames{en}->{52724} = "Luvianos\/Tejupilco\ de\ Hidalgo\,\ MEX";
$areanames{en}->{52725} = "Almoloya\ de\ Juarez\/Santa\ Maria\ Del\ Monte\,\ MEX";
$areanames{en}->{52726} = "Estado\ de\ Mexico";
$areanames{en}->{52727} = "Guerrero";
$areanames{en}->{52728} = "Lerma\/Santa\ Maria\ Atarasquillo\,\ MEX";
$areanames{en}->{52729} = "Estado\ de\ Mexico";
$areanames{en}->{52731} = "Morelos";
$areanames{en}->{52732} = "Guerrero";
$areanames{en}->{52733} = "Iguala\,\ GRO";
$areanames{en}->{52734} = "Morelos";
$areanames{en}->{52735} = "Cuautla\/Jonacatepec\,\ MOR";
$areanames{en}->{52736} = "Guerrero";
$areanames{en}->{52737} = "Morelos";
$areanames{en}->{52738} = "Mixquiahuala\/Tepatepec\,\ HGO";
$areanames{en}->{52739} = "Huitzilac\/Tepoztlan\,\ MOR";
$areanames{en}->{52741} = "Guerrero";
$areanames{en}->{52742} = "Guerrero";
$areanames{en}->{52743} = "Hidalgo";
$areanames{en}->{52744} = "Acapulco\/Xaltianguis\,\ GRO";
$areanames{en}->{52745} = "Guerrero";
$areanames{en}->{52746} = "Puebla\/Veracruz";
$areanames{en}->{52747} = "Guerrero";
$areanames{en}->{52748} = "Hidalgo";
$areanames{en}->{52749} = "Calpulalpan\,\ TLAX";
$areanames{en}->{52751} = "Morelos";
$areanames{en}->{52753} = "Michoacan";
$areanames{en}->{52754} = "Guerrero";
$areanames{en}->{52755} = "Ixtapa\/Zihuatanejo\,\ GRO";
$areanames{en}->{52756} = "Chilapa\/Olinala\,\ GRO";
$areanames{en}->{52757} = "Huamuxtitlan\/Tlapa\ de\ Comonfort\,\ GRO";
$areanames{en}->{52758} = "Petatlan\/San\ Jeronimito\,\ GRO";
$areanames{en}->{52759} = "Hidalgo";
$areanames{en}->{52761} = "Hidalgo";
$areanames{en}->{52762} = "Taxco\,\ GRO";
$areanames{en}->{52763} = "Tezontepec\ de\ Aldama\/Tlahuelilpan\,\ HGO";
$areanames{en}->{52764} = "Puebla";
$areanames{en}->{52765} = "Alamo\ Temapache\/Alazan\/Potrero\ Del\ Llano\,\ VER";
$areanames{en}->{52766} = "Gutierrez\ Zamora\/Tecolutla\,\ VER";
$areanames{en}->{52767} = "Guerrero";
$areanames{en}->{52768} = "Veracruz";
$areanames{en}->{52769} = "Morelos";
$areanames{en}->{52771} = "Pachuca\/Real\ Del\ Monte\,\ HGO";
$areanames{en}->{52772} = "Actopan\,\ HGO";
$areanames{en}->{52773} = "Hidalgo";
$areanames{en}->{52774} = "Hidalgo";
$areanames{en}->{52775} = "Tulancingo\,\ HGO";
$areanames{en}->{52776} = "Puebla";
$areanames{en}->{52777} = "Morelos";
$areanames{en}->{52778} = "Hidalgo";
$areanames{en}->{52779} = "Tizayuca\,\ HGO";
$areanames{en}->{52781} = "Coyuca\ de\ Benitez\/San\ Jeronimo\ de\ Juarez\,\ GRO";
$areanames{en}->{52782} = "Poza\ Rica\,\ VER";
$areanames{en}->{52783} = "Tuxpan\,\ VER";
$areanames{en}->{52784} = "Veracruz";
$areanames{en}->{52785} = "Veracruz";
$areanames{en}->{52786} = "Ciudad\ Hidalgo\/Tuxpan\,\ MICH";
$areanames{en}->{52789} = "Veracruz";
$areanames{en}->{52791} = "Ciudad\ Sahagun\,\ HGO";
$areanames{en}->{52797} = "Puebla";
$areanames{en}->{5281} = "Monterrey\,\ NL";
$areanames{en}->{52821} = "Hualahuises\/Linares\,\ NL";
$areanames{en}->{52823} = "Nuevo\ Leon";
$areanames{en}->{52824} = "Sabinas\ Hidalgo\,\ NL";
$areanames{en}->{52825} = "Nuevo\ Leon";
$areanames{en}->{52826} = "Nuevo\ Leon";
$areanames{en}->{52828} = "Cadereyta\,\ NL";
$areanames{en}->{52829} = "Nuevo\ Leon";
$areanames{en}->{52831} = "Ciudad\ Mante\/Los\ Aztecas\,\ TAMPS";
$areanames{en}->{52832} = "Tamaulipas";
$areanames{en}->{52833} = "Tampico\,\ TAMPS";
$areanames{en}->{52834} = "Ciudad\ Victoria\,\ TAMPS";
$areanames{en}->{52835} = "Tamaulipas";
$areanames{en}->{52836} = "Tamaulipas";
$areanames{en}->{52841} = "Tamaulipas";
$areanames{en}->{52842} = "Coahuila";
$areanames{en}->{52844} = "Saltillo\,\ COAH";
$areanames{en}->{52845} = "Ebano\/Ponciano\ Arriaga\,\ SLP";
$areanames{en}->{52846} = "Veracruz";
$areanames{en}->{52861} = "Nueva\ Rosita\/Sabinas\,\ COAH";
$areanames{en}->{52862} = "Coahuila";
$areanames{en}->{52864} = "Coahuila";
$areanames{en}->{52866} = "Castanos\/Monclova\,\ COAH";
$areanames{en}->{52867} = "Nuevo\ Laredo\/Tamaulipas";
$areanames{en}->{52868} = "Tamaulipas";
$areanames{en}->{52869} = "Cuatro\ Cienegas\/San\ Buenaventura\,\ COAH";
$areanames{en}->{52871} = "Coahuila";
$areanames{en}->{52872} = "Coahuila\/Durango";
$areanames{en}->{52873} = "Nuevo\ Leon";
$areanames{en}->{52877} = "Ciudad\ Acuna\,\ COAH";
$areanames{en}->{52878} = "Piedras\ Negras\,\ COAH";
$areanames{en}->{52891} = "Tamaulipas";
$areanames{en}->{52892} = "Nuevo\ Leon";
$areanames{en}->{52894} = "Santa\ Apolonia\/Valle\ Hermoso\,\ TAMPS";
$areanames{en}->{52897} = "Tamaulipas";
$areanames{en}->{52899} = "Tamaulipas";
$areanames{en}->{52913} = "Tabasco";
$areanames{en}->{52914} = "Tabasco";
$areanames{en}->{52916} = "Chiapas";
$areanames{en}->{52917} = "Tabasco";
$areanames{en}->{52918} = "Chiapas";
$areanames{en}->{52919} = "Chiapas";
$areanames{en}->{52921} = "Coatzacoalcos\/Ixhuatlan\ Del\ Sureste\,\ VER";
$areanames{en}->{52922} = "Veracruz";
$areanames{en}->{52923} = "Tabasco\/Veracruz";
$areanames{en}->{52924} = "Veracruz";
$areanames{en}->{52932} = "Chiapas\/Tabasco";
$areanames{en}->{52933} = "Tabasco";
$areanames{en}->{52934} = "Tabasco";
$areanames{en}->{52936} = "Tabasco";
$areanames{en}->{52937} = "Cardenas\,\ TAB";
$areanames{en}->{52938} = "Ciudad\ Del\ Carmen\,\ CAMP";
$areanames{en}->{5295} = "Oaxaca";
$areanames{en}->{5296} = "Chiapas";
$areanames{en}->{52966} = "Arriaga\/Tonala\,\ CHIS";
$areanames{en}->{52967} = "San\ Cristobal\ de\ las\ Casas\,\ CHIS";
$areanames{en}->{52969} = "Flamboyanes\/Yucalpeten\,\ YUC";
$areanames{en}->{5297} = "Oaxaca";
$areanames{en}->{52981} = "Campeche\,\ CAMP";
$areanames{en}->{52982} = "Campeche";
$areanames{en}->{52983} = "Quintana\ Roo";
$areanames{en}->{52984} = "Quintana\ Roo";
$areanames{en}->{52985} = "Yucatan";
$areanames{en}->{52986} = "Yucatan";
$areanames{en}->{52987} = "Cozumel\,\ QRO";
$areanames{en}->{52988} = "Yucatan";
$areanames{en}->{52991} = "Yucatan";
$areanames{en}->{52992} = "Chiapas";
$areanames{en}->{52993} = "Tabasco";
$areanames{en}->{52994} = "Oaxaca";
$areanames{en}->{52995} = "Magdalena\ Tequisistlan\/Santa\ Maria\ Jalapa\ Del\ Marquez\,\ OAX";
$areanames{en}->{52996} = "Campeche";
$areanames{en}->{52997} = "Yucatan";
$areanames{en}->{52998} = "Quintana\ Roo";
$areanames{en}->{52999} = "Conkal\/Merida\,\ YUC";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+52|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0(?:[12]|4[45])|1)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;