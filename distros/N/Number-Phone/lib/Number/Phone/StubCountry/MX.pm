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
our $VERSION = 1.20220601185319;

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
          6571\\d{6}|
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
              6[1-9]|
              7[12]|
              8[1-8]|
              9\\d
            )
          )\\d{7}
        ',
                'geographic' => '
          6571\\d{6}|
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
              6[1-9]|
              7[12]|
              8[1-8]|
              9\\d
            )
          )\\d{7}
        ',
                'mobile' => '
          6571\\d{6}|
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
$areanames{es} = {"52427", "México\/Quintana\ Roo",
"52477", "León\,\ GTO",
"52966", "Arriaga\/Tonalá\,\ CHIS",
"52422", "Michoacán",
"52594", "Estado\ de\ México",
"52716", "Estado\ de\ México",
"52986", "Yucatán",
"52892", "Nuevo\ León",
"52441", "Querétaro",
"52869", "Cuatro\ Ciénegas\/San\ Buenaventura\,\ COAH",
"52711", "México\/Michoacán",
"52353", "Michoacán",
"52921", "Coatzacoalcos\/Ixhuatlán\ del\ Sureste\,\ VER",
"52232", "La\ Vigueta\/Martínez\ de\ la\ Torre\,\ VER",
"52328", "Michoacán",
"52829", "Nuevo\ León",
"52825", "Nuevo\ León",
"52454", "Michoacán",
"52722", "Estado\ de\ México",
"52423", "Michoacán",
"52469", "Buenavista\ de\ Cortés\/Pénjamo\,\ GTO",
"52938", "Ciudad\ del\ Carmen\,\ CAMP",
"52418", "Dolores\ Hidalgo\/San\ Diego\ de\ la\ Unión\,\ GTO",
"52451", "Michoacán",
"52877", "Ciudad\ Acuña\,\ COAH",
"52729", "Estado\ de\ México",
"52342", "Gómez\ Farías\/Sayula\,\ JAL",
"52653", "Luis\ B\.\ Sánchez\/San\ Luis\ Río\ Colorado\,\ SON",
"52725", "Almoloya\ de\ Juárez\/Santa\ María\ del\ Monte\,\ MEX",
"5258", "Estado\ de\ México",
"52591", "Estado\ de\ México",
"52718", "Estado\ de\ México",
"52448", "Querétaro",
"52317", "Autlán\/El\ Chante\,\ JAL",
"52873", "Nuevo\ León",
"52823", "Nuevo\ León",
"52756", "Chilapa\/Olinalá\,\ GRO",
"52475", "Bajío\ de\ San\ José\/Encarnación\ de\ Diaz\,\ JAL",
"52596", "Estado\ de\ México",
"52425", "Michoacán",
"52988", "Yucatán",
"52991", "Yucatán",
"52765", "Álamo\ Temapache\/Alazán\/Potrero\ del\ Llano\,\ VER",
"52444", "San\ Luis\ Potosí\,\ SLP",
"52355", "Michoacán",
"52714", "Estado\ de\ México",
"52867", "Nuevo\ León\/Tamaulipas",
"52231", "Teteles\/Teziutlán\,\ PUE",
"52632", "Ímuris\/Magdalena\,\ SON",
"52443", "Morelia\/Tarímbaro\,\ MICH",
"52641", "Benjamín\ Hill\/Santa\ Ana\,\ SON",
"52494", "Jerez\ de\ García\ Salinas\,\ ZAC",
"52771", "Pachuca\/Real\ del\ Monte\,\ HGO",
"52937", "Cárdenas\,\ TAB",
"5255", "Ciudad\ de\ México\,\ CDMX",
"52459", "Michoacán",
"52455", "Michoacán",
"52726", "Estado\ de\ México",
"52392", "Jamay\/Ocotlán\,\ JAL",
"52967", "San\ Cristóbal\ de\ las\ Casas\,\ CHIS",
"52599", "Estado\ de\ México",
"52995", "Magdalena\ Tequisistlán\/Santa\ Maria\ Jalapa\ del\ Marqués\,\ OAX",
"52314", "Manzanillo\/Peña\ Colorada\,\ COL",
"52999", "Conkal\/Mérida\,\ YUC",
"52595", "Estado\ de\ México",
"52426", "Michoacán",
"52781", "Coyuca\ de\ Benítez\/San\ Jerónimo\ de\ Juárez\,\ GRO",
"52476", "San\ Francisco\ del\ Rincón\,\ GTO",
"52766", "Gutiérrez\ Zamora\/Tecolutla\,\ VER",
"52442", "Querétaro",
"52356", "Tanhuato\/Yurécuaro\,\ MICH",
"52712", "Estado\ de\ México",
"52447", "Contepec\/Maravatío\,\ MICH",
"52717", "Estado\ de\ México",
"52431", "Jalostotitlán\/Villa\ Obregón\,\ JAL",
"52351", "Ario\ de\ Rayón\/Zamora\,\ MICH",
"52358", "Tamazula\/Zapotiltic\,\ JAL",
"52438", "Michoacán",
"52997", "Yucatán",
"52284", "Ángel\ Rosario\ Cabada\/Lerdo\ de\ Tejada\,\ VER",
"52453", "Apatzingán\,\ MICH",
"52424", "Michoacán",
"52592", "Estado\ de\ México",
"52866", "Castaños\/Monclova\,\ COAH",
"52434", "Michoacán",
"52715", "Michoacán",
"52354", "Michoacán",
"52791", "Ciudad\ Sahagún\,\ HGO",
"5248", "San\ Luis\ Potosí",
"52449", "Aguascalientes\/Jesús\ María\,\ AGS",
"52985", "Yucatán",
"52719", "San\ Francisco\ Xonacatlán\/Temoaya\,\ MEX",
"52728", "Lerma\/Santa\ María\ Atarasquillo\,\ MEX",
"52383", "Michoacán",
"52341", "Ciudad\ Guzmán\,\ JAL",
"52826", "Nuevo\ León",
"52753", "Michoacán",
"52593", "Estado\ de\ México",
"52238", "Santiago\ Miahuatlán\/Tehuacán\,\ PUE",};
$areanames{en} = {"52735", "Cuautla\/Jonacatepec\,\ MOR",
"52465", "Aguascalientes",
"52634", "Sonora",
"5296", "Chiapas",
"52832", "Tamaulipas",
"52924", "Veracruz",
"52326", "Jalisco",
"52846", "Veracruz",
"52744", "Acapulco\/Xaltianguis\,\ GRO",
"52414", "Tequisquiapan\,\ QRO",
"52645", "Cananea\,\ SON",
"52649", "Chihuahua\/Durango",
"52235", "Veracruz",
"52492", "Zacatecas",
"52938", "Ciudad\ Del\ Carmen\,\ CAMP",
"52321", "El\ Grullo\/El\ Limon\,\ JAL",
"52244", "Puebla",
"52469", "Buenavista\ de\ Cortez\/Penjamo\,\ GTO",
"52739", "Huitzilac\/Tepoztlan\,\ MOR",
"52841", "Tamaulipas",
"52628", "Chihuahua",
"52418", "Dolores\ Hidalgo\/San\ Diego\ de\ la\ Union\,\ GTO",
"52275", "Puebla",
"52225", "Tlapacoyan\,\ VER",
"52451", "Michoacan",
"52748", "Hidalgo",
"52347", "Jalisco",
"52638", "Puerto\ Penasco\,\ SON",
"52877", "Ciudad\ Acuna\,\ COAH",
"52729", "Estado\ de\ Mexico",
"52779", "Tizayuca\,\ HGO",
"52775", "Tulancingo\,\ HGO",
"52624", "Baja\ California\ Sur",
"52248", "Puebla",
"52725", "Almoloya\ de\ Juarez\/Santa\ Maria\ Del\ Monte\,\ MEX",
"52674", "Durango",
"52342", "Gomez\ Farias\/Sayula\,\ JAL",
"52934", "Tabasco",
"52872", "Coahuila\/Durango",
"52313", "Colima",
"52653", "Luis\ B\.\ Sanchez\/San\ Luis\ Rio\ Colorado\,\ SON",
"52456", "Valle\ de\ Santiago\,\ GTO",
"5258", "Estado\ de\ Mexico",
"52229", "Veracruz\,\ VER",
"52279", "Veracruz",
"52718", "Estado\ de\ Mexico",
"52394", "Cotija\ de\ la\ Paz\,\ MICH",
"52448", "Queretaro",
"52751", "Morelos",
"52785", "Veracruz",
"52919", "Chiapas",
"52591", "Estado\ de\ Mexico",
"52668", "Sinaloa",
"52429", "Guanajuato",
"52996", "Campeche",
"52657", "Chihuahua",
"52317", "Autlan\/El\ Chante\,\ JAL",
"52475", "Bajio\ de\ San\ Jose\/Encarnacion\ de\ Diaz\,\ JAL",
"52425", "Michoacan",
"5297", "Oaxaca",
"52596", "Estado\ de\ Mexico",
"52285", "Veracruz",
"52343", "Jalisco",
"52873", "Nuevo\ Leon",
"52312", "Colima\/Los\ Tepames\,\ COL",
"52823", "Nuevo\ Leon",
"52652", "Chihuahua",
"52756", "Chilapa\/Olinala\,\ GRO",
"52991", "Yucatan",
"52789", "Veracruz",
"52988", "Yucatan",
"52899", "Tamaulipas",
"52435", "Huetamo\/San\ Lucas\,\ MICH",
"52765", "Alamo\ Temapache\/Alazan\/Potrero\ Del\ Llano\,\ VER",
"52797", "Puebla",
"52833", "Tampico\,\ TAMPS",
"52862", "Coahuila",
"52381", "Cojumatlan\/San\ Jose\ de\ Gracia\,\ MICH",
"52355", "Michoacan",
"52615", "Baja\ California\ Sur",
"52444", "San\ Luis\ Potosi\,\ SLP",
"52714", "Estado\ de\ Mexico",
"52984", "Quintana\ Roo",
"52297", "Alvarado\,\ VER",
"52493", "Fresnillo\,\ ZAC",
"52867", "Nuevo\ Laredo\/Tamaulipas",
"52769", "Morelos",
"52386", "Jalisco",
"52917", "Tabasco",
"52223", "Puebla",
"52273", "Veracruz",
"52686", "Baja\ California",
"52782", "Poza\ Rica\,\ VER",
"52427", "Mexico\/Quintana\ Roo",
"52319", "Nayarit",
"52659", "Chihuahua",
"52477", "Leon\,\ GTO",
"52994", "Oaxaca",
"52287", "Oaxaca",
"52723", "Coatepec\ Harinas\,\ MEX",
"52422", "Michoacan",
"52388", "Jalisco",
"52594", "Estado\ de\ Mexico",
"52773", "Hidalgo",
"52472", "Silao\,\ GTO",
"52966", "Arriaga\/Tonala\,\ CHIS",
"52315", "Jalisco",
"52391", "Jalisco",
"52282", "Puebla\/Veracruz",
"52754", "Guerrero",
"5237", "Jalisco",
"52463", "Jalpa\/Tabasco\,\ ZAC",
"52762", "Taxco\,\ GRO",
"52733", "Iguala\,\ GRO",
"52432", "Ciudad\ Manuel\ Doblado\/Romita\,\ GTO",
"52998", "Quintana\ Roo",
"52897", "Tamaulipas",
"52981", "Campeche\,\ CAMP",
"5233", "Guadalajara\,\ JAL",
"52643", "Sonora",
"52352", "La\ Piedad\,\ MICH",
"52612", "La\ Paz\/Todos\ Santos\,\ BCS",
"52716", "Estado\ de\ Mexico",
"52986", "Yucatan",
"52233", "Puebla",
"52357", "Jalisco",
"52661", "Primo\ Tapia\/Rosarito\,\ BCN",
"52758", "Petatlan\/San\ Jeronimito\,\ GRO",
"52441", "Queretaro",
"52869", "Cuatro\ Cienegas\/San\ Buenaventura\,\ COAH",
"52767", "Guerrero",
"52711", "Mexico\/Michoacan",
"52437", "Jalisco\/Zacatecas",
"52892", "Nuevo\ Leon",
"52384", "Tala\/Teuchitlan\,\ JAL",
"52433", "Zacatecas",
"52763", "Tezontepec\ de\ Aldama\/Tlahuelilpan\,\ HGO",
"52462", "Irapuato\,\ GTO",
"52732", "Guerrero",
"52636", "Chihuahua",
"52835", "Tamaulipas",
"52499", "Jalisco\/Zacatecas",
"52241", "Tlaxcala",
"52324", "Nayarit",
"52237", "Puebla",
"52844", "Saltillo\,\ COAH",
"52642", "Navojoa\/Pueblo\ Mayo\,\ SON",
"52746", "Puebla\/Veracruz",
"52613", "Baja\ California\ Sur",
"52353", "Michoacan",
"52232", "La\ Vigueta\/Martinez\ de\ la\ Torre\,\ VER",
"52921", "Coatzacoalcos\/Ixhuatlan\ Del\ Sureste\,\ VER",
"52647", "Sonora",
"52631", "Nogales\,\ SON",
"52495", "Aguascalientes\/Jalisco",
"52741", "Guerrero",
"52458", "Zacatecas",
"52411", "Guanajuato",
"52467", "Zacatecas",
"52737", "Morelos",
"52246", "Tlaxcala",
"52222", "Puebla",
"52272", "Maltrata\/Orizaba\,\ VER",
"52621", "Chihuahua",
"52783", "Tuxpan\,\ VER",
"52671", "Durango",
"52328", "Michoacan",
"52349", "Jalisco",
"52727", "Guerrero",
"52829", "Nuevo\ Leon",
"52777", "Morelos",
"5269", "Sinaloa",
"52626", "Ojinaga\,\ CHIH",
"52423", "Michoacan",
"52722", "Estado\ de\ Mexico",
"52676", "Durango",
"52473", "Guanajuato\,\ GTO",
"52772", "Actopan\,\ HGO",
"52936", "Tabasco",
"52825", "Nuevo\ Leon",
"52345", "Jalisco",
"52454", "Michoacan",
"52283", "Veracruz",
"52913", "Tabasco",
"52227", "Huejotzingo\/San\ Buenaventura\ Nealtican\,\ PUE",
"5281", "Monterrey\,\ NL",
"52358", "Tamazula\/Zapoltitic\,\ JAL",
"52618", "Colonia\ Hidalgo\/Durango\,\ DGO",
"52395", "Jalisco",
"52311", "Nayarit",
"52651", "Sonoita\,\ SON",
"52784", "Veracruz",
"52969", "Flamboyanes\/Yucalpeten\,\ YUC",
"52438", "Michoacan",
"52768", "Veracruz",
"52992", "Chiapas",
"52757", "Huamuxtitlan\/Tlapa\ de\ Comonfort\,\ GRO",
"52424", "Michoacan",
"52592", "Estado\ de\ Mexico",
"52474", "Lagos\ de\ Moreno\/Paso\ de\ Cuarenta\,\ JAL",
"52997", "Yucatan",
"52316", "Jalisco",
"52656", "Chihuahua",
"52453", "Apatzingan\,\ MICH",
"52284", "Angel\ Rosario\ Cabada\/Lerdo\ de\ Tejada\,\ VER",
"52914", "Tabasco",
"52665", "Tecate\,\ BCN",
"52434", "Michoacan",
"52764", "Puebla",
"52866", "Castanos\/Monclova\,\ COAH",
"52387", "Jalisco",
"52323", "Nayarit",
"52296", "Veracruz",
"52715", "Michoacan",
"52791", "Ciudad\ Sahagun\,\ HGO",
"52614", "Chihuahua",
"52445", "Moroleon\,\ GTO",
"52354", "Michoacan",
"5248", "San\ Luis\ Potosi",
"52861", "Nueva\ Rosita\/Sabinas\,\ COAH",
"52449", "Aguascalientes\/Jesus\ Maria\,\ AGS",
"52985", "Yucatan",
"52719", "San\ Francisco\ Xonacatlan\/Temoaya\,\ MEX",
"52990", "Merida",
"52918", "Chiapas",
"52288", "Veracruz",
"52894", "Santa\ Apolonia\/Valle\ Hermoso\,\ TAMPS",
"52478", "Calera\ Victor\ Rosales\,\ ZAC",
"52428", "Ocampo\/San\ Felipe\,\ GTO",
"52382", "Jalisco",
"52669", "Sinaloa",
"52635", "Chihuahua",
"52249", "Puebla",
"52734", "Morelos",
"52464", "Salamanca\,\ GTO",
"52836", "Tamaulipas",
"52322", "Jalisco",
"52842", "Coahuila",
"52644", "Sonora",
"52278", "Veracruz",
"52415", "San\ Miguel\ Allende\,\ GTO",
"52228", "Jalapa\/Tuzamapan\,\ VER",
"52745", "Guerrero",
"52327", "Nayarit",
"52831", "Ciudad\ Mante\/Los\ Aztecas\,\ TAMPS",
"52749", "Calpulalpan\,\ TLAX",
"52377", "Cocula\/Estipac\,\ JAL",
"52419", "Guanajuato",
"52496", "Zacatecas",
"52778", "Hidalgo",
"52383", "Michoacan",
"52245", "Puebla",
"52728", "Lerma\/Santa\ Maria\ Atarasquillo\,\ MEX",
"52639", "Chihuahua",
"52224", "Puebla",
"52871", "Coahuila",
"52341", "Ciudad\ Guzman\,\ JAL",
"52821", "Hualahuises\/Linares\,\ NL",
"52274", "Oaxaca",
"52648", "Boquilla\/Ciudad\ Camargo\,\ CHIH",
"52629", "Chihuahua",
"52993", "Tabasco",
"52468", "San\ Luis\ de\ la\ Paz\,\ GTO",
"52738", "Mixquiahuala\/Tepatepec\,\ HGO",
"52457", "Jalisco\/Zacatecas",
"52724", "Luvianos\/Tejupilco\ de\ Hidalgo\,\ MEX",
"52675", "Durango",
"52593", "Estado\ de\ Mexico",
"52625", "Chihuahua",
"52774", "Hidalgo",
"52346", "Jalisco\/Zacatecas",
"52826", "Nuevo\ Leon",
"52452", "Nuevo\ San\ Juan\ Parangaricutiro\/Uruapan\,\ MICH",
"52753", "Michoacan",
"52238", "Santiago\ Miahuatlan\/Tehuacan\,\ PUE",
"52736", "Guerrero",
"52466", "Guanajuato",
"52632", "Imuris\/Magdalena\,\ SON",
"52834", "Ciudad\ Victoria\,\ TAMPS",
"52247", "Huamantla\/San\ Cosme\ Xalostoc\,\ TLAX",
"52922", "Veracruz",
"52231", "Teteles\/Teziutlan\,\ PUE",
"52375", "Ameca\,\ JAL",
"52845", "Ebano\/Ponciano\ Arriaga\,\ SLP",
"52325", "Acaponeta\,\ NAY",
"52646", "Baja\ California",
"52443", "Morelia\/Tarimbaro\,\ MICH",
"52742", "Guerrero",
"52713", "Santiago\ Tianguistenco\,\ MEX",
"52412", "Guanajuato",
"52983", "Quintana\ Roo",
"52236", "Oaxaca\/Puebla",
"52329", "Nayarit",
"52747", "Guerrero",
"52461", "Guanajuato",
"52731", "Morelos",
"52417", "Guanajuato",
"52641", "Benjamin\ Hill\/Santa\ Ana\,\ SON",
"52828", "Cadereyta\,\ NL",
"52878", "Piedras\ Negras\,\ COAH",
"52348", "Jalisco",
"52637", "Altar\/Caborca\,\ SON",
"52494", "Jerez\ de\ Garcia\ Salinas\,\ ZAC",
"52226", "Altotonga\/Jalacingo\,\ VER",
"52393", "Jalisco",
"52276", "Puebla",
"52721", "Ixtapan\ de\ la\ Sal\,\ MEX",
"52771", "Pachuca\/Real\ Del\ Monte\,\ HGO",
"52627", "Parral\,\ CHIH",
"5255", "Mexico\ City\,\ FD",
"52677", "Durango",
"52459", "Michoacan",
"52937", "Cardenas\,\ TAB",
"52622", "Guaymas\/San\ Carlos\,\ SON",
"52726", "Estado\ de\ Mexico",
"52672", "Sinaloa",
"52481", "Ciudad\ Valles\,\ SLP",
"52776", "Puebla",
"52498", "Zacatecas",
"52932", "Chiapas\/Tabasco",
"52455", "Michoacan",
"52221", "Puebla",
"52344", "Mexticacan\/Yahualica\,\ JAL",
"52271", "Veracruz",
"52824", "Sabinas\ Hidalgo\,\ NL",
"5295", "Oaxaca",
"52392", "Jamay\/Ocotlan\,\ JAL",
"52281", "Loma\ Bonita\,\ OAX",
"52421", "Guanajuato",
"52471", "Purepero\/Tlazazalca\,\ MICH",
"52786", "Ciudad\ Hidalgo\/Tuxpan\,\ MICH",
"52868", "Tamaulipas",
"52759", "Hidalgo",
"52967", "San\ Cristobal\ de\ las\ Casas\,\ CHIS",
"52599", "Estado\ de\ Mexico",
"52995", "Magdalena\ Tequisistlan\/Santa\ Maria\ Jalapa\ Del\ Marquez\,\ OAX",
"52623", "Sonora",
"52426", "Michoacan",
"52999", "Conkal\/Merida\,\ YUC",
"52595", "Estado\ de\ Mexico",
"52781", "Coyuca\ de\ Benitez\/San\ Jeronimo\ de\ Juarez\,\ GRO",
"52673", "Sinaloa",
"52476", "San\ Francisco\ Del\ Rincon\,\ GTO",
"52933", "Tabasco",
"52755", "Ixtapa\/Zihuatanejo\,\ GRO",
"52314", "Manzanillo\/Pena\ Colorada\,\ COL",
"52916", "Chiapas",
"52687", "Sinaloa",
"52766", "Gutierrez\ Zamora\/Tecolutla\,\ VER",
"52436", "Zacapu\,\ MICH",
"52389", "Nayarit",
"52633", "Sonora",
"52662", "Sonora",
"52864", "Coahuila",
"52923", "Tabasco\/Veracruz",
"52891", "Tamaulipas",
"52987", "Cozumel\,\ QRO",
"52294", "Veracruz",
"52442", "Queretaro",
"52743", "Hidalgo",
"52356", "Tanhuato\/Yurecuaro\,\ MICH",
"52616", "Baja\ California",
"52712", "Estado\ de\ Mexico",
"52413", "Apaseo\ el\ Alto\/Apaseo\ el\ Grande\,\ GTO",
"52982", "Campeche",
"52447", "Contepec\/Maravatio\,\ MICH",
"52431", "Jalostotitlan\/Villa\ Obregon\,\ JAL",
"52761", "Hidalgo",
"52717", "Estado\ de\ Mexico",
"52658", "Baja\ California",
"52667", "Sinaloa",
"52351", "Ario\ de\ Rayon\/Zamora\,\ MICH",
"52243", "Puebla",
"52385", "Jalisco",};

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