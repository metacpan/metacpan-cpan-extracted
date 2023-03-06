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
our $VERSION = 1.20230305170053;

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
$areanames{en} = {"52634", "Sonora",
"52425", "Michoacan",
"52427", "Mexico\/Quintana\ Roo",
"52720", "Toluca",
"52421", "Guanajuato",
"52668", "Sinaloa",
"52789", "Veracruz",
"52346", "Jalisco\/Zacatecas",
"52322", "Jalisco",
"52777", "Morelos",
"52448", "Queretaro",
"52771", "Pachuca\/Real\ Del\ Monte\,\ HGO",
"52719", "San\ Francisco\ Xonacatlan\/Temoaya\,\ MEX",
"52775", "Tulancingo\,\ HGO",
"52899", "Tamaulipas",
"52744", "Acapulco\/Xaltianguis\,\ GRO",
"52443", "Morelia\/Tarimbaro\,\ MICH",
"52319", "Nayarit",
"52375", "Ameca\,\ JAL",
"52651", "Sonoita\,\ SON",
"52344", "Mexticacan\/Yahualica\,\ JAL",
"52722", "Estado\ de\ Mexico",
"52636", "Chihuahua",
"52377", "Cocula\/Estipac\,\ JAL",
"52472", "Silao\,\ GTO",
"52746", "Puebla\/Veracruz",
"52389", "Nayarit",
"52924", "Veracruz",
"52877", "Ciudad\ Acuna\,\ COAH",
"52871", "Coahuila",
"52616", "Baja\ California",
"52248", "Puebla",
"52844", "Saltillo\,\ COAH",
"52686", "Baja\ California",
"52221", "Puebla",
"52227", "Huejotzingo\/San\ Buenaventura\ Nealtican\,\ PUE",
"52225", "Tlapacoyan\,\ VER",
"52846", "Veracruz",
"52272", "Maltrata\/Orizaba\,\ VER",
"52649", "Chihuahua\/Durango",
"5269", "Sinaloa",
"52614", "Chihuahua",
"52469", "Buenavista\ de\ Cortez\/Penjamo\,\ GTO",
"52739", "Huitzilac\/Tepoztlan\,\ MOR",
"52243", "Puebla",
"52784", "Veracruz",
"52316", "Jalisco",
"52836", "Tamaulipas",
"52639", "Chihuahua",
"5233", "Guadalajara\,\ JAL",
"5281", "Monterrey\,\ NL",
"52386", "Jalisco",
"526571", "Chihuahua",
"52749", "Calpulalpan\,\ TLAX",
"52982", "Campeche",
"52714", "Estado\ de\ Mexico",
"52894", "Santa\ Apolonia\/Valle\ Hermoso\,\ TAMPS",
"52233", "Puebla",
"52418", "Dolores\ Hidalgo\/San\ Diego\ de\ la\ Union\,\ GTO",
"52868", "Tamaulipas",
"52349", "Jalisco",
"52413", "Apaseo\ el\ Alto\/Apaseo\ el\ Grande\,\ GTO",
"52786", "Ciudad\ Hidalgo\/Tuxpan\,\ MICH",
"52314", "Manzanillo\/Pena\ Colorada\,\ COL",
"52834", "Ciudad\ Victoria\,\ TAMPS",
"52238", "Santiago\ Miahuatlan\/Tehuacan\,\ PUE",
"52384", "Tala\/Teuchitlan\,\ JAL",
"52716", "Estado\ de\ Mexico",
"52763", "Tezontepec\ de\ Aldama\/Tlahuelilpan\,\ HGO",
"52433", "Zacatecas",
"52498", "Zacatecas",
"52967", "San\ Cristobal\ de\ las\ Casas\,\ CHIS",
"52646", "Baja\ California",
"52622", "Guaymas\/San\ Carlos\,\ SON",
"52736", "Guerrero",
"52466", "Guanajuato",
"526572", "Juarez\/Chihuahua",
"52755", "Ixtapa\/Zihuatanejo\,\ GRO",
"52288", "Veracruz",
"52992", "Chiapas",
"52751", "Morelos",
"52757", "Huamuxtitlan\/Tlapa\ de\ Comonfort\,\ GRO",
"52675", "Durango",
"52283", "Veracruz",
"52357", "Jalisco",
"52351", "Ario\ de\ Rayon\/Zamora\,\ MICH",
"52644", "Sonora",
"52592", "Estado\ de\ Mexico",
"52355", "Michoacan",
"52677", "Durango",
"52671", "Durango",
"52932", "Chiapas\/Tabasco",
"52438", "Michoacan",
"52768", "Veracruz",
"52990", "Merida",
"52464", "Salamanca\,\ GTO",
"52394", "Cotija\ de\ la\ Paz\,\ MICH",
"52734", "Morelos",
"52452", "Nuevo\ San\ Juan\ Parangaricutiro\/Uruapan\,\ MICH",
"52493", "Fresnillo\,\ ZAC",
"52872", "Coahuila\/Durango",
"52618", "Colonia\ Hidalgo\/Durango\,\ DGO",
"52246", "Tlaxcala",
"5297", "Oaxaca",
"52222", "Puebla",
"52769", "Morelos",
"52244", "Puebla",
"52275", "Puebla",
"52271", "Veracruz",
"52499", "Jalisco\/Zacatecas",
"52613", "Baja\ California\ Sur",
"52825", "Nuevo\ Leon",
"52220", "Puebla",
"52821", "Hualahuises\/Linares\,\ NL",
"52743", "Hidalgo",
"52869", "Cuatro\ Cienegas\/San\ Buenaventura\,\ COAH",
"52422", "Michoacan",
"52348", "Jalisco",
"52327", "Nayarit",
"52321", "El\ Grullo\/El\ Limon\,\ JAL",
"52772", "Actopan\,\ HGO",
"52325", "Acaponeta\,\ NAY",
"52633", "Sonora",
"52923", "Tabasco\/Veracruz",
"52652", "Chihuahua",
"52725", "Almoloya\ de\ Juarez\/Santa\ Maria\ Del\ Monte\,\ MEX",
"52721", "Ixtapan\ de\ la\ Sal\,\ MEX",
"52727", "Guerrero",
"52638", "Puerto\ Penasco\,\ SON",
"52471", "Purepero\/Tlazazalca\,\ MICH",
"52748", "Hidalgo",
"52477", "Leon\,\ GTO",
"52475", "Bajio\ de\ San\ Jose\/Encarnacion\ de\ Diaz\,\ JAL",
"52419", "Guanajuato",
"52343", "Jalisco",
"52444", "San\ Luis\ Potosi\,\ SLP",
"52496", "Zacatecas",
"52648", "Boquilla\/Ciudad\ Camargo\,\ CHIH",
"52621", "Chihuahua",
"52468", "San\ Luis\ de\ la\ Paz\,\ GTO",
"52627", "Parral\,\ CHIH",
"52738", "Mixquiahuala\/Tepatepec\,\ HGO",
"52997", "Yucatan",
"52991", "Yucatan",
"52995", "Magdalena\ Tequisistlan\/Santa\ Maria\ Jalapa\ Del\ Marquez\,\ OAX",
"52434", "Michoacan",
"52764", "Puebla",
"52625", "Chihuahua",
"52494", "Jerez\ de\ Garcia\ Salinas\,\ ZAC",
"52733", "Iguala\,\ GRO",
"52352", "La\ Piedad\,\ MICH",
"52393", "Jalisco",
"52463", "Jalpa\/Tabasco\,\ ZAC",
"52595", "Estado\ de\ Mexico",
"52591", "Estado\ de\ Mexico",
"52937", "Cardenas\,\ TAB",
"52672", "Sinaloa",
"52249", "Puebla",
"52455", "Michoacan",
"52766", "Gutierrez\ Zamora\/Tecolutla\,\ VER",
"52436", "Zacapu\,\ MICH",
"5248", "San\ Luis\ Potosi",
"52643", "Sonora",
"52457", "Jalisco\/Zacatecas",
"52284", "Angel\ Rosario\ Cabada\/Lerdo\ de\ Tejada\,\ VER",
"52451", "Michoacan",
"52917", "Tabasco",
"52713", "Santiago\ Tianguistenco\,\ MEX",
"52864", "Coahuila",
"52388", "Jalisco",
"52296", "Veracruz",
"52981", "Campeche\,\ CAMP",
"52987", "Cozumel\,\ QRO",
"5295", "Oaxaca",
"52985", "Yucatan",
"52783", "Tuxpan\,\ VER",
"52383", "Michoacan",
"52866", "Castanos\/Monclova\,\ COAH",
"5255", "Mexico\ City\,\ FD",
"52236", "Oaxaca\/Puebla",
"52669", "Sinaloa",
"52313", "Colima",
"52449", "Aguascalientes\/Jesus\ Maria\,\ AGS",
"52833", "Tampico\,\ TAMPS",
"52414", "Tequisquiapan\,\ QRO",
"52718", "Estado\ de\ Mexico",
"52294", "Veracruz",
"52247", "Huamantla\/San\ Cosme\ Xalostoc\,\ TLAX",
"52241", "Tlaxcala",
"52599", "Estado\ de\ Mexico",
"52878", "Piedras\ Negras\,\ COAH",
"52274", "Oaxaca",
"52245", "Puebla",
"52612", "La\ Paz\/Todos\ Santos\,\ BCS",
"52459", "Michoacan",
"52228", "Jalapa\/Tuzamapan\,\ VER",
"52824", "Sabinas\ Hidalgo\,\ NL",
"52276", "Puebla",
"52842", "Coahuila",
"52223", "Puebla",
"52826", "Nuevo\ Leon",
"52999", "Conkal\/Merida\,\ YUC",
"52629", "Chihuahua",
"52873", "Nuevo\ Leon",
"52667", "Sinaloa",
"52661", "Primo\ Tapia\/Rosarito\,\ BCN",
"52428", "Ocampo\/San\ Felipe\,\ GTO",
"52342", "Gomez\ Farias\/Sayula\,\ JAL",
"52724", "Luvianos\/Tejupilco\ de\ Hidalgo\,\ MEX",
"52665", "Tecate\,\ BCN",
"52445", "Moroleon\,\ GTO",
"52474", "Lagos\ de\ Moreno\/Paso\ de\ Cuarenta\,\ JAL",
"52326", "Jalisco",
"52653", "Luis\ B\.\ Sanchez\/San\ Luis\ Rio\ Colorado\,\ SON",
"52922", "Veracruz",
"52441", "Queretaro",
"52447", "Contepec\/Maravatio\,\ MICH",
"52778", "Hidalgo",
"52632", "Imuris\/Magdalena\,\ SON",
"52726", "Estado\ de\ Mexico",
"52773", "Hidalgo",
"52919", "Chiapas",
"52658", "Baja\ California",
"52324", "Nayarit",
"52423", "Michoacan",
"52476", "San\ Francisco\ Del\ Rincon\,\ GTO",
"52742", "Guerrero",
"52642", "Navojoa\/Pueblo\ Mayo\,\ SON",
"52279", "Veracruz",
"52594", "Estado\ de\ Mexico",
"52934", "Tabasco",
"52495", "Aguascalientes\/Jalisco",
"52829", "Nuevo\ Leon",
"52673", "Sinaloa",
"52285", "Veracruz",
"52758", "Petatlan\/San\ Jeronimito\,\ GRO",
"52392", "Jamay\/Ocotlan\,\ JAL",
"52462", "Irapuato\,\ GTO",
"52353", "Michoacan",
"5258", "Estado\ de\ Mexico",
"52732", "Guerrero",
"52626", "Ojinaga\,\ CHIH",
"52996", "Campeche",
"52281", "Loma\ Bonita\,\ OAX",
"52287", "Oaxaca",
"52454", "Michoacan",
"52596", "Estado\ de\ Mexico",
"52753", "Michoacan",
"52936", "Tabasco",
"52358", "Tamazula\/Zapoltitic\,\ JAL",
"52624", "Baja\ California\ Sur",
"52456", "Valle\ de\ Santiago\,\ GTO",
"52765", "Alamo\ Temapache\/Alazan\/Potrero\ Del\ Llano\,\ VER",
"52994", "Oaxaca",
"52435", "Huetamo\/San\ Lucas\,\ MICH",
"52767", "Guerrero",
"52431", "Jalostotitlan\/Villa\ Obregon\,\ JAL",
"52761", "Hidalgo",
"52437", "Jalisco\/Zacatecas",
"52481", "Ciudad\ Valles\,\ SLP",
"52729", "Estado\ de\ Mexico",
"52916", "Chiapas",
"52832", "Tamaulipas",
"52312", "Colima\/Los\ Tepames\,\ COL",
"52417", "Guanajuato",
"52411", "Guanajuato",
"52415", "San\ Miguel\ Allende\,\ GTO",
"52382", "Jalisco",
"52297", "Alvarado\,\ VER",
"52986", "Yucatan",
"52782", "Poza\ Rica\,\ VER",
"52914", "Tabasco",
"52237", "Puebla",
"52231", "Teteles\/Teziutlan\,\ PUE",
"52235", "Veracruz",
"52867", "Nuevo\ Laredo\/Tamaulipas",
"52861", "Nueva\ Rosita\/Sabinas\,\ COAH",
"52984", "Quintana\ Roo",
"52712", "Estado\ de\ Mexico",
"52892", "Nuevo\ Leon",
"52329", "Nayarit",
"52426", "Michoacan",
"52662", "Sonora",
"52341", "Ciudad\ Guzman\,\ JAL",
"52347", "Jalisco",
"52473", "Guanajuato\,\ GTO",
"52345", "Jalisco",
"52723", "Coatepec\ Harinas\,\ MEX",
"52328", "Michoacan",
"52921", "Coatzacoalcos\/Ixhuatlan\ Del\ Sureste\,\ VER",
"52442", "Queretaro",
"52776", "Puebla",
"52637", "Altar\/Caborca\,\ SON",
"52728", "Lerma\/Santa\ Maria\ Atarasquillo\,\ MEX",
"52631", "Nogales\,\ SON",
"52424", "Michoacan",
"52635", "Chihuahua",
"52323", "Nayarit",
"52656", "Chihuahua",
"52745", "Guerrero",
"52774", "Hidalgo",
"52747", "Guerrero",
"52478", "Calera\ Victor\ Rosales\,\ ZAC",
"52741", "Guerrero",
"52615", "Baja\ California\ Sur",
"52823", "Nuevo\ Leon",
"52273", "Veracruz",
"52687", "Sinaloa",
"5237", "Jalisco",
"52226", "Altotonga\/Jalacingo\,\ VER",
"52278", "Veracruz",
"52969", "Flamboyanes\/Yucalpeten\,\ YUC",
"52845", "Ebano\/Ponciano\ Arriaga\,\ SLP",
"52841", "Tamaulipas",
"52759", "Hidalgo",
"52224", "Puebla",
"52828", "Cadereyta\,\ NL",
"52315", "Jalisco",
"52835", "Tamaulipas",
"52918", "Chiapas",
"52659", "Chihuahua",
"52317", "Autlan\/El\ Chante\,\ JAL",
"52831", "Ciudad\ Mante\/Los\ Aztecas\,\ TAMPS",
"52311", "Nayarit",
"52385", "Jalisco",
"52412", "Guanajuato",
"52387", "Jalisco",
"52381", "Cojumatlan\/San\ Jose\ de\ Gracia\,\ MICH",
"52988", "Yucatan",
"52781", "Coyuca\ de\ Benitez\/San\ Jeronimo\ de\ Juarez\,\ GRO",
"52429", "Guanajuato",
"52232", "La\ Vigueta\/Martinez\ de\ la\ Torre\,\ VER",
"52983", "Quintana\ Roo",
"52862", "Coahuila",
"52785", "Veracruz",
"52711", "Mexico\/Michoacan",
"52897", "Tamaulipas",
"52891", "Tamaulipas",
"52717", "Estado\ de\ Mexico",
"52715", "Michoacan",
"52779", "Tizayuca\,\ HGO",
"52913", "Tabasco",
"5296", "Chiapas",
"52453", "Apatzingan\,\ MICH",
"52492", "Zacatecas",
"52647", "Sonora",
"52966", "Arriaga\/Tonala\,\ CHIS",
"52641", "Benjamin\ Hill\/Santa\ Ana\,\ SON",
"52354", "Michoacan",
"52645", "Cananea\,\ SON",
"52674", "Durango",
"52933", "Tabasco",
"52735", "Cuautla\/Jonacatepec\,\ MOR",
"52593", "Estado\ de\ Mexico",
"52465", "Aguascalientes",
"52395", "Jalisco",
"52756", "Chilapa\/Olinala\,\ GRO",
"52737", "Morelos",
"52461", "Guanajuato",
"52628", "Chihuahua",
"52391", "Jalisco",
"52731", "Morelos",
"52467", "Zacatecas",
"52282", "Puebla\/Veracruz",
"52998", "Quintana\ Roo",
"52797", "Puebla",
"52791", "Ciudad\ Sahagun\,\ HGO",
"52676", "Durango",
"52938", "Ciudad\ Del\ Carmen\,\ CAMP",
"52993", "Tabasco",
"52356", "Tanhuato\/Yurecuaro\,\ MICH",
"52623", "Sonora",
"52458", "Zacatecas",
"52432", "Ciudad\ Manuel\ Doblado\/Romita\,\ GTO",
"52229", "Veracruz\,\ VER",
"52762", "Taxco\,\ GRO",
"52754", "Guerrero",};
$areanames{es} = {"52722", "Estado\ de\ México",
"52443", "Morelia\/Tarímbaro\,\ MICH",
"52427", "México\/Quintana\ Roo",
"52425", "Michoacán",
"52719", "San\ Francisco\ Xonacatlán\/Temoaya\,\ MEX",
"52771", "Pachuca\/Real\ del\ Monte\,\ HGO",
"52448", "Querétaro",
"52469", "Buenavista\ de\ Cortés\/Pénjamo\,\ GTO",
"52877", "Ciudad\ Acuña\,\ COAH",
"52238", "Santiago\ Miahuatlán\/Tehuacán\,\ PUE",
"52314", "Manzanillo\/Peña\ Colorada\,\ COL",
"52716", "Estado\ de\ México",
"52418", "Dolores\ Hidalgo\/San\ Diego\ de\ la\ Unión\,\ GTO",
"52714", "Estado\ de\ México",
"52355", "Michoacán",
"52592", "Estado\ de\ México",
"52351", "Ario\ de\ Rayón\/Zamora\,\ MICH",
"52438", "Michoacán",
"52967", "San\ Cristóbal\ de\ las\ Casas\,\ CHIS",
"52825", "Nuevo\ León",
"52725", "Almoloya\ de\ Juárez\/Santa\ María\ del\ Monte\,\ MEX",
"52444", "San\ Luis\ Potosí\,\ SLP",
"52475", "Bajío\ de\ San\ José\/Encarnación\ de\ Diaz\,\ JAL",
"52477", "León\,\ GTO",
"52422", "Michoacán",
"52869", "Cuatro\ Ciénegas\/San\ Buenaventura\,\ COAH",
"52937", "Cárdenas\,\ TAB",
"52591", "Estado\ de\ México",
"52595", "Estado\ de\ México",
"52494", "Jerez\ de\ García\ Salinas\,\ ZAC",
"52451", "Michoacán",
"52284", "Ángel\ Rosario\ Cabada\/Lerdo\ de\ Tejada\,\ VER",
"5248", "San\ Luis\ Potosí",
"52766", "Gutiérrez\ Zamora\/Tecolutla\,\ VER",
"52455", "Michoacán",
"52995", "Magdalena\ Tequisistlán\/Santa\ Maria\ Jalapa\ del\ Marqués\,\ OAX",
"52434", "Michoacán",
"52991", "Yucatán",
"52997", "Yucatán",
"5255", "Ciudad\ de\ México\,\ CDMX",
"52866", "Castaños\/Monclova\,\ COAH",
"52383", "Michoacán",
"52718", "Estado\ de\ México",
"52449", "Aguascalientes\/Jesús\ María\,\ AGS",
"52985", "Yucatán",
"52873", "Nuevo\ León",
"52999", "Conkal\/Mérida\,\ YUC",
"52826", "Nuevo\ León",
"52599", "Estado\ de\ México",
"52459", "Michoacán",
"52726", "Estado\ de\ México",
"52632", "Ímuris\/Magdalena\,\ SON",
"52476", "San\ Francisco\ del\ Rincón\,\ GTO",
"52423", "Michoacán",
"52342", "Gómez\ Farías\/Sayula\,\ JAL",
"52447", "Contepec\/Maravatío\,\ MICH",
"52441", "Querétaro",
"52653", "Luis\ B\.\ Sánchez\/San\ Luis\ Río\ Colorado\,\ SON",
"52358", "Tamazula\/Zapotiltic\,\ JAL",
"52753", "Michoacán",
"52596", "Estado\ de\ México",
"52431", "Jalostotitlán\/Villa\ Obregón\,\ JAL",
"52765", "Álamo\ Temapache\/Alazán\/Potrero\ del\ Llano\,\ VER",
"52594", "Estado\ de\ México",
"52454", "Michoacán",
"5258", "Estado\ de\ México",
"52353", "Michoacán",
"52392", "Jamay\/Ocotlán\,\ JAL",
"52829", "Nuevo\ León",
"52867", "Nuevo\ León\/Tamaulipas",
"52231", "Teteles\/Teziutlán\,\ PUE",
"52892", "Nuevo\ León",
"52712", "Estado\ de\ México",
"52729", "Estado\ de\ México",
"52986", "Yucatán",
"52424", "Michoacán",
"52728", "Lerma\/Santa\ María\ Atarasquillo\,\ MEX",
"52341", "Ciudad\ Guzmán\,\ JAL",
"52426", "Michoacán",
"52442", "Querétaro",
"52921", "Coatzacoalcos\/Ixhuatlán\ del\ Sureste\,\ VER",
"52328", "Michoacán",
"52823", "Nuevo\ León",
"52232", "La\ Vigueta\/Martínez\ de\ la\ Torre\,\ VER",
"52781", "Coyuca\ de\ Benítez\/San\ Jerónimo\ de\ Juárez\,\ GRO",
"52715", "Michoacán",
"52717", "Estado\ de\ México",
"52711", "México\/Michoacán",
"52317", "Autlán\/El\ Chante\,\ JAL",
"52988", "Yucatán",
"52356", "Tanhuato\/Yurécuaro\,\ MICH",
"52938", "Ciudad\ del\ Carmen\,\ CAMP",
"52791", "Ciudad\ Sahagún\,\ HGO",
"52354", "Michoacán",
"52641", "Benjamín\ Hill\/Santa\ Ana\,\ SON",
"52966", "Arriaga\/Tonalá\,\ CHIS",
"52453", "Apatzingán\,\ MICH",
"52756", "Chilapa\/Olinalá\,\ GRO",
"52593", "Estado\ de\ México",};

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