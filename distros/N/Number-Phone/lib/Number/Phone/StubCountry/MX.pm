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
package Number::Phone::StubCountry::MX;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20230307181421;

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
          657[12]\\d{6}|
          (?:
            2(?:
              0[01]|
              2\\d|
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
              [25-7][1-9]|
              3[1-8]|
              4\\d|
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
              [13467][1-9]|
              2\\d|
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
              6[1-9]|
              7[12]|
              8[1-8]|
              9\\d
            )
          )\\d{7}
        ',
                'geographic' => '
          657[12]\\d{6}|
          (?:
            2(?:
              0[01]|
              2\\d|
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
              [25-7][1-9]|
              3[1-8]|
              4\\d|
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
              [13467][1-9]|
              2\\d|
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
              6[1-9]|
              7[12]|
              8[1-8]|
              9\\d
            )
          )\\d{7}
        ',
                'mobile' => '
          657[12]\\d{6}|
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
              2\\d|
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
              [25-7][1-9]|
              3[1-8]|
              4\\d|
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
              [13467][1-9]|
              2\\d|
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
              6[1-9]|
              7[12]|
              8[1-8]|
              9\\d
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
$areanames{es} = {"52997", "Yucatán",
"52719", "San\ Francisco\ Xonacatlán\/Temoaya\,\ MEX",
"52423", "Michoacán",
"52444", "San\ Luis\ Potosí\,\ SLP",
"52725", "Almoloya\ de\ Juárez\/Santa\ María\ del\ Monte\,\ MEX",
"52825", "Nuevo\ León",
"52232", "La\ Vigueta\/Martínez\ de\ la\ Torre\,\ VER",
"52869", "Cuatro\ Ciénegas\/San\ Buenaventura\,\ COAH",
"52728", "Lerma\/Santa\ María\ Atarasquillo\,\ MEX",
"52442", "Querétaro",
"52653", "Luis\ B\.\ Sánchez\/San\ Luis\ Río\ Colorado\,\ SON",
"52425", "Michoacán",
"52469", "Buenavista\ de\ Cortés\/Pénjamo\,\ GTO",
"52459", "Michoacán",
"52999", "Conkal\/Mérida\,\ YUC",
"52717", "Estado\ de\ México",
"52632", "Ímuris\/Magdalena\,\ SON",
"52383", "Michoacán",
"52314", "Manzanillo\/Peña\ Colorada\,\ COL",
"52594", "Estado\ de\ México",
"52284", "Ángel\ Rosario\ Cabada\/Lerdo\ de\ Tejada\,\ VER",
"52823", "Nuevo\ León",
"52867", "Nuevo\ León\/Tamaulipas",
"52966", "Arriaga\/Tonalá\,\ CHIS",
"52592", "Estado\ de\ México",
"52354", "Michoacán",
"52937", "Cárdenas\,\ TAB",
"52988", "Yucatán",
"52985", "Yucatán",
"52753", "Michoacán",
"52418", "Dolores\ Hidalgo\/San\ Diego\ de\ la\ Unión\,\ GTO",
"52892", "Nuevo\ León",
"52434", "Michoacán",
"52991", "Yucatán",
"52995", "Magdalena\ Tequisistlán\/Santa\ Maria\ Jalapa\ del\ Marqués\,\ OAX",
"5255", "Ciudad\ de\ México\,\ CDMX",
"52455", "Michoacán",
"52451", "Michoacán",
"52938", "Ciudad\ del\ Carmen\,\ CAMP",
"52765", "Álamo\ Temapache\/Alazán\/Potrero\ del\ Llano\,\ VER",
"52829", "Nuevo\ León",
"52729", "Estado\ de\ México",
"52341", "Ciudad\ Guzmán\,\ JAL",
"52453", "Apatzingán\,\ MICH",
"52427", "México\/Quintana\ Roo",
"52494", "Jerez\ de\ García\ Salinas\,\ ZAC",
"52596", "Estado\ de\ México",
"52476", "San\ Francisco\ del\ Rincón\,\ GTO",
"52718", "Estado\ de\ México",
"52356", "Tanhuato\/Yurécuaro\,\ MICH",
"52711", "México\/Michoacán",
"52715", "Michoacán",
"52443", "Morelia\/Tarímbaro\,\ MICH",
"52358", "Tamazula\/Zapotiltic\,\ JAL",
"52355", "Michoacán",
"52351", "Ario\ de\ Rayón\/Zamora\,\ MICH",
"52716", "Estado\ de\ México",
"52475", "Bajío\ de\ San\ José\/Encarnación\ de\ Diaz\,\ JAL",
"52595", "Estado\ de\ México",
"52591", "Estado\ de\ México",
"52422", "Michoacán",
"5248", "San\ Luis\ Potosí",
"52766", "Gutiérrez\ Zamora\/Tecolutla\,\ VER",
"52866", "Castaños\/Monclova\,\ COAH",
"52967", "San\ Cristóbal\ de\ las\ Casas\,\ CHIS",
"52756", "Chilapa\/Olinalá\,\ GRO",
"52424", "Michoacán",
"52873", "Nuevo\ León",
"52392", "Jamay\/Ocotlán\,\ JAL",
"52231", "Teteles\/Teziutlán\,\ PUE",
"52722", "Estado\ de\ México",
"52593", "Estado\ de\ México",
"52238", "Santiago\ Miahuatlán\/Tehuacán\,\ PUE",
"52441", "Querétaro",
"52448", "Querétaro",
"52353", "Michoacán",
"52771", "Pachuca\/Real\ del\ Monte\,\ HGO",
"52986", "Yucatán",
"52921", "Coatzacoalcos\/Ixhuatlán\ del\ Sureste\,\ VER",
"52342", "Gómez\ Farías\/Sayula\,\ JAL",
"52641", "Benjamín\ Hill\/Santa\ Ana\,\ SON",
"52317", "Autlán\/El\ Chante\,\ JAL",
"52714", "Estado\ de\ México",
"52712", "Estado\ de\ México",
"52477", "León\,\ GTO",
"5258", "Estado\ de\ México",
"52449", "Aguascalientes\/Jesús\ María\,\ AGS",
"52426", "Michoacán",
"52454", "Michoacán",
"52877", "Ciudad\ Acuña\,\ COAH",
"52781", "Coyuca\ de\ Benítez\/San\ Jerónimo\ de\ Juárez\,\ GRO",
"52826", "Nuevo\ León",
"52726", "Estado\ de\ México",
"52599", "Estado\ de\ México",
"52431", "Jalostotitlán\/Villa\ Obregón\,\ JAL",
"52438", "Michoacán",
"52447", "Contepec\/Maravatío\,\ MICH",
"52791", "Ciudad\ Sahagún\,\ HGO",
"52328", "Michoacán",};
$areanames{en} = {"52425", "Michoacan",
"52744", "Acapulco\/Xaltianguis\,\ GRO",
"52844", "Saltillo\,\ COAH",
"52421", "Guanajuato",
"52469", "Buenavista\ de\ Cortez\/Penjamo\,\ GTO",
"52428", "Ocampo\/San\ Felipe\,\ GTO",
"52634", "Sonora",
"52615", "Baja\ California\ Sur",
"52347", "Jalisco",
"52227", "Huejotzingo\/San\ Buenaventura\ Nealtican\,\ PUE",
"52312", "Colima\/Los\ Tepames\,\ COL",
"52618", "Colonia\ Hidalgo\/Durango\,\ DGO",
"52459", "Michoacan",
"52294", "Veracruz",
"52916", "Chiapas",
"52999", "Conkal\/Merida\,\ YUC",
"52742", "Guerrero",
"52842", "Coahuila",
"52717", "Estado\ de\ Mexico",
"52632", "Imuris\/Magdalena\,\ SON",
"52276", "Puebla",
"52383", "Michoacan",
"52314", "Manzanillo\/Pena\ Colorada\,\ COL",
"52651", "Sonoita\,\ SON",
"5281", "Monterrey\,\ NL",
"52594", "Estado\ de\ Mexico",
"52352", "La\ Piedad\,\ MICH",
"52658", "Baja\ California",
"52496", "Zacatecas",
"52419", "Guanajuato",
"52668", "Sinaloa",
"52284", "Angel\ Rosario\ Cabada\/Lerdo\ de\ Tejada\,\ VER",
"52665", "Tecate\,\ BCN",
"52661", "Primo\ Tapia\/Rosarito\,\ BCN",
"52472", "Silao\,\ GTO",
"52629", "Chihuahua",
"52723", "Coatepec\ Harinas\,\ MEX",
"52767", "Guerrero",
"52867", "Nuevo\ Laredo\/Tamaulipas",
"52823", "Nuevo\ Leon",
"52592", "Estado\ de\ Mexico",
"52966", "Arriaga\/Tonala\,\ CHIS",
"52354", "Michoacan",
"52736", "Guerrero",
"52836", "Tamaulipas",
"52282", "Puebla\/Veracruz",
"52393", "Jalisco",
"52937", "Cardenas\,\ TAB",
"52646", "Baja\ California",
"52757", "Huamuxtitlan\/Tlapa\ de\ Comonfort\,\ GRO",
"52474", "Lagos\ de\ Moreno\/Paso\ de\ Cuarenta\,\ JAL",
"52385", "Jalisco",
"52246", "Tlaxcala",
"52381", "Cojumatlan\/San\ Jose\ de\ Gracia\,\ MICH",
"52326", "Jalisco",
"52388", "Jalisco",
"52872", "Coahuila\/Durango",
"52772", "Actopan\,\ HGO",
"52997", "Yucatan",
"52719", "San\ Francisco\ Xonacatlan\/Temoaya\,\ MEX",
"52924", "Veracruz",
"52436", "Zacapu\,\ MICH",
"52613", "Baja\ California\ Sur",
"52229", "Veracruz\,\ VER",
"52349", "Jalisco",
"52774", "Hidalgo",
"52457", "Jalisco\/Zacatecas",
"52423", "Michoacan",
"52467", "Zacatecas",
"52922", "Veracruz",
"52377", "Cocula\/Estipac\,\ JAL",
"52391", "Jalisco",
"52759", "Hidalgo",
"52395", "Jalisco",
"52721", "Ixtapan\ de\ la\ Sal\,\ MEX",
"52676", "Durango",
"52232", "La\ Vigueta\/Martinez\ de\ la\ Torre\,\ VER",
"52821", "Hualahuises\/Linares\,\ NL",
"52825", "Nuevo\ Leon",
"52725", "Almoloya\ de\ Juarez\/Santa\ Maria\ Del\ Monte\,\ MEX",
"52444", "San\ Luis\ Potosi\,\ SLP",
"52869", "Cuatro\ Cienegas\/San\ Buenaventura\,\ COAH",
"52769", "Morelos",
"52786", "Ciudad\ Hidalgo\/Tuxpan\,\ MICH",
"52728", "Lerma\/Santa\ Maria\ Atarasquillo\,\ MEX",
"52828", "Cadereyta\,\ NL",
"5237", "Jalisco",
"52987", "Cozumel\,\ QRO",
"52627", "Parral\,\ CHIH",
"52442", "Queretaro",
"52653", "Luis\ B\.\ Sanchez\/San\ Luis\ Rio\ Colorado\,\ SON",
"52417", "Guanajuato",
"52623", "Sonora",
"52667", "Sinaloa",
"52296", "Veracruz",
"52846", "Veracruz",
"52746", "Puebla\/Veracruz",
"5233", "Guadalajara\,\ JAL",
"52413", "Apaseo\ el\ Alto\/Apaseo\ el\ Grande\,\ GTO",
"52636", "Chihuahua",
"52272", "Maltrata\/Orizaba\,\ VER",
"52938", "Ciudad\ Del\ Carmen\,\ CAMP",
"52758", "Petatlan\/San\ Jeronimito\,\ GRO",
"52755", "Ixtapa\/Zihuatanejo\,\ GRO",
"52751", "Morelos",
"52316", "Jalisco",
"52765", "Alamo\ Temapache\/Alazan\/Potrero\ Del\ Llano\,\ VER",
"52861", "Nueva\ Rosita\/Sabinas\,\ COAH",
"52761", "Hidalgo",
"52914", "Tabasco",
"52729", "Estado\ de\ Mexico",
"52829", "Nuevo\ Leon",
"52274", "Oaxaca",
"526572", "Juarez\/Chihuahua",
"52868", "Tamaulipas",
"52768", "Veracruz",
"52983", "Quintana\ Roo",
"52341", "Ciudad\ Guzman\,\ JAL",
"52345", "Jalisco",
"52832", "Tamaulipas",
"52221", "Puebla",
"52732", "Guerrero",
"52225", "Tlapacoyan\,\ VER",
"52348", "Jalisco",
"52642", "Navojoa\/Pueblo\ Mayo\,\ SON",
"52453", "Apatzingan\,\ MICH",
"52228", "Jalapa\/Tuzamapan\,\ VER",
"52427", "Mexico\/Quintana\ Roo",
"52463", "Jalpa\/Tabasco\,\ ZAC",
"52494", "Jerez\ de\ Garcia\ Salinas\,\ ZAC",
"52596", "Estado\ de\ Mexico",
"52389", "Nayarit",
"52834", "Ciudad\ Victoria\,\ TAMPS",
"52734", "Morelos",
"52644", "Sonora",
"52476", "San\ Francisco\ Del\ Rincon\,\ GTO",
"52718", "Estado\ de\ Mexico",
"52993", "Tabasco",
"52715", "Michoacan",
"52492", "Zacatecas",
"52711", "Mexico\/Michoacan",
"52356", "Tanhuato\/Yurecuaro\,\ MICH",
"52763", "Tezontepec\ de\ Aldama\/Tlahuelilpan\,\ HGO",
"52727", "Guerrero",
"52988", "Yucatan",
"52894", "Santa\ Apolonia\/Valle\ Hermoso\,\ TAMPS",
"52981", "Campeche\,\ CAMP",
"52985", "Yucatan",
"52324", "Nayarit",
"52244", "Puebla",
"52432", "Ciudad\ Manuel\ Doblado\/Romita\,\ GTO",
"52933", "Tabasco",
"52753", "Michoacan",
"52659", "Chihuahua",
"52418", "Dolores\ Hidalgo\/San\ Diego\ de\ la\ Union\,\ GTO",
"52411", "Guanajuato",
"52415", "San\ Miguel\ Allende\,\ GTO",
"52892", "Nuevo\ Leon",
"52628", "Chihuahua",
"52322", "Jalisco",
"52434", "Michoacan",
"52776", "Puebla",
"52621", "Chihuahua",
"52625", "Chihuahua",
"52669", "Sinaloa",
"52686", "Baja\ California",
"52784", "Veracruz",
"52995", "Magdalena\ Tequisistlan\/Santa\ Maria\ Jalapa\ Del\ Marquez\,\ OAX",
"52674", "Durango",
"52991", "Yucatan",
"52713", "Santiago\ Tianguistenco\,\ MEX",
"52998", "Quintana\ Roo",
"5297", "Oaxaca",
"52387", "Jalisco",
"5255", "Mexico\ City\,\ FD",
"52461", "Guanajuato",
"52782", "Poza\ Rica\,\ VER",
"526571", "Chihuahua",
"52465", "Aguascalientes",
"52429", "Guanajuato",
"52672", "Sinaloa",
"52236", "Oaxaca\/Puebla",
"52468", "San\ Luis\ de\ la\ Paz\,\ GTO",
"52375", "Ameca\,\ JAL",
"52343", "Jalisco",
"52223", "Puebla",
"52458", "Zacatecas",
"52451", "Michoacan",
"52455", "Michoacan",
"52437", "Jalisco\/Zacatecas",
"52283", "Veracruz",
"52392", "Jamay\/Ocotlan\,\ JAL",
"52456", "Valle\ de\ Santiago\,\ GTO",
"52231", "Teteles\/Teziutlan\,\ PUE",
"52722", "Estado\ de\ Mexico",
"52235", "Veracruz",
"52466", "Guanajuato",
"52593", "Estado\ de\ Mexico",
"52238", "Santiago\ Miahuatlan\/Tehuacan\,\ PUE",
"52327", "Nayarit",
"52247", "Huamantla\/San\ Cosme\ Xalostoc\,\ TLAX",
"52394", "Cotija\ de\ la\ Paz\,\ MICH",
"52473", "Guanajuato\,\ GTO",
"52919", "Chiapas",
"52441", "Queretaro",
"52996", "Campeche",
"52824", "Sabinas\ Hidalgo\,\ NL",
"52445", "Moroleon\,\ GTO",
"52724", "Luvianos\/Tejupilco\ de\ Hidalgo\,\ MEX",
"52797", "Puebla",
"52448", "Queretaro",
"52897", "Tamaulipas",
"52353", "Michoacan",
"52279", "Veracruz",
"52382", "Jalisco",
"52778", "Hidalgo",
"52878", "Piedras\ Negras\,\ COAH",
"52775", "Tulancingo\,\ HGO",
"52626", "Ojinaga\,\ CHIH",
"52771", "Pachuca\/Real\ Del\ Monte\,\ HGO",
"52871", "Coahuila",
"52743", "Hidalgo",
"52990", "Merida",
"52633", "Sonora",
"52499", "Jalisco\/Zacatecas",
"52384", "Tala\/Teuchitlan\,\ JAL",
"52739", "Huitzilac\/Tepoztlan\,\ MOR",
"52313", "Colima",
"52649", "Chihuahua\/Durango",
"52677", "Durango",
"52969", "Flamboyanes\/Yucalpeten\,\ YUC",
"52986", "Yucatan",
"52921", "Coatzacoalcos\/Ixhuatlan\ Del\ Sureste\,\ VER",
"52443", "Morelia\/Tarimbaro\,\ MICH",
"52358", "Tamazula\/Zapoltitic\,\ JAL",
"52917", "Tabasco",
"52652", "Chihuahua",
"52716", "Estado\ de\ Mexico",
"52899", "Tamaulipas",
"52351", "Ario\ de\ Rayon\/Zamora\,\ MICH",
"52355", "Michoacan",
"52249", "Puebla",
"52478", "Calera\ Victor\ Rosales\,\ ZAC",
"52329", "Nayarit",
"52662", "Sonora",
"52471", "Purepero\/Tlazazalca\,\ MICH",
"52475", "Bajio\ de\ San\ Jose\/Encarnacion\ de\ Diaz\,\ JAL",
"52233", "Puebla",
"52591", "Estado\ de\ Mexico",
"52595", "Estado\ de\ Mexico",
"5296", "Chiapas",
"5295", "Oaxaca",
"52226", "Altotonga\/Jalacingo\,\ VER",
"52281", "Loma\ Bonita\,\ OAX",
"52285", "Veracruz",
"52346", "Jalisco\/Zacatecas",
"52288", "Veracruz",
"5248", "San\ Luis\ Potosi",
"52422", "Michoacan",
"52866", "Castanos\/Monclova\,\ COAH",
"52766", "Gutierrez\ Zamora\/Tecolutla\,\ VER",
"52789", "Veracruz",
"52967", "San\ Cristobal\ de\ las\ Casas\,\ CHIS",
"52923", "Tabasco\/Veracruz",
"52612", "La\ Paz\/Todos\ Santos\,\ BCS",
"52737", "Morelos",
"52647", "Sonora",
"52756", "Chilapa\/Olinala\,\ GRO",
"52311", "Nayarit",
"52220", "Puebla",
"52315", "Jalisco",
"52936", "Tabasco",
"52745", "Guerrero",
"52424", "Michoacan",
"52845", "Ebano\/Ponciano\ Arriaga\,\ SLP",
"52841", "Tamaulipas",
"52741", "Guerrero",
"52638", "Puerto\ Penasco\,\ SON",
"52748", "Hidalgo",
"52631", "Nogales\,\ SON",
"52635", "Chihuahua",
"52614", "Chihuahua",
"52773", "Hidalgo",
"52873", "Nuevo\ Leon",
"52464", "Salamanca\,\ GTO",
"52749", "Calpulalpan\,\ TLAX",
"52992", "Chiapas",
"52493", "Fresnillo\,\ ZAC",
"52639", "Chihuahua",
"52687", "Sinaloa",
"52877", "Ciudad\ Acuna\,\ COAH",
"52777", "Morelos",
"52454", "Michoacan",
"52781", "Coyuca\ de\ Benitez\/San\ Jeronimo\ de\ Juarez\,\ GRO",
"52462", "Irapuato\,\ GTO",
"52785", "Veracruz",
"52994", "Oaxaca",
"52675", "Durango",
"52726", "Estado\ de\ Mexico",
"52671", "Durango",
"52826", "Nuevo\ Leon",
"5269", "Sinaloa",
"52733", "Iguala\,\ GRO",
"52833", "Tampico\,\ TAMPS",
"52643", "Sonora",
"52452", "Nuevo\ San\ Juan\ Parangaricutiro\/Uruapan\,\ MICH",
"52319", "Nayarit",
"52237", "Puebla",
"52414", "Tequisquiapan\,\ QRO",
"52982", "Campeche",
"52720", "Toluca",
"52599", "Estado\ de\ Mexico",
"52435", "Huetamo\/San\ Lucas\,\ MICH",
"52431", "Jalostotitlan\/Villa\ Obregon\,\ JAL",
"52624", "Baja\ California\ Sur",
"52438", "Michoacan",
"52447", "Contepec\/Maravatio\,\ MICH",
"52913", "Tabasco",
"52412", "Guanajuato",
"52891", "Tamaulipas",
"52791", "Ciudad\ Sahagun\,\ HGO",
"52273", "Veracruz",
"52984", "Quintana\ Roo",
"52325", "Acaponeta\,\ NAY",
"52321", "El\ Grullo\/El\ Limon\,\ JAL",
"52245", "Puebla",
"52386", "Jalisco",
"52241", "Tlaxcala",
"52622", "Guaymas\/San\ Carlos\,\ SON",
"52328", "Michoacan",
"52248", "Puebla",
"52342", "Gomez\ Farias\/Sayula\,\ JAL",
"52648", "Boquilla\/Ciudad\ Camargo\,\ CHIH",
"52731", "Morelos",
"52222", "Puebla",
"52831", "Ciudad\ Mante\/Los\ Aztecas\,\ TAMPS",
"52835", "Tamaulipas",
"52735", "Cuautla\/Jonacatepec\,\ MOR",
"52645", "Cananea\,\ SON",
"52317", "Autlan\/El\ Chante\,\ JAL",
"52641", "Benjamin\ Hill\/Santa\ Ana\,\ SON",
"52738", "Mixquiahuala\/Tepatepec\,\ HGO",
"52783", "Tuxpan\,\ VER",
"52673", "Sinaloa",
"52714", "Estado\ de\ Mexico",
"52344", "Mexticacan\/Yahualica\,\ JAL",
"52224", "Puebla",
"52779", "Tizayuca\,\ HGO",
"52297", "Alvarado\,\ VER",
"52498", "Zacatecas",
"52747", "Guerrero",
"52656", "Chihuahua",
"52712", "Estado\ de\ Mexico",
"52495", "Aguascalientes\/Jalisco",
"52637", "Altar\/Caborca\,\ SON",
"52323", "Nayarit",
"52243", "Puebla",
"52934", "Tabasco",
"52754", "Guerrero",
"52477", "Leon\,\ GTO",
"5258", "Estado\ de\ Mexico",
"52764", "Puebla",
"52864", "Coahuila",
"52278", "Veracruz",
"52449", "Aguascalientes\/Jesus\ Maria\,\ AGS",
"52275", "Puebla",
"52271", "Veracruz",
"52357", "Jalisco",
"52918", "Chiapas",
"52616", "Baja\ California",
"52287", "Oaxaca",
"52433", "Zacatecas",
"52932", "Chiapas\/Tabasco",
"52762", "Taxco\,\ GRO",
"52481", "Ciudad\ Valles\,\ SLP",
"52862", "Coahuila",
"52426", "Michoacan",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+52|\D)//g;
      my $self = bless({ country_code => '52', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0(?:[12]|4[45])|1)//;
      $self = bless({ country_code => '52', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;