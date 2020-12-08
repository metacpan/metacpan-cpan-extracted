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
our $VERSION = 1.20201204215957;

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
$areanames{en} = {"52599", "Estado\ de\ Mexico",
"52913", "Tabasco",
"52349", "Jalisco",
"52441", "Queretaro",
"52327", "Nayarit",
"52377", "Cocula\/Estipac\,\ JAL",
"52746", "Puebla\/Veracruz",
"52892", "Nuevo\ Leon",
"52422", "Michoacan",
"52472", "Silao\,\ GTO",
"52785", "Veracruz",
"52354", "Michoacan",
"52762", "Taxco\,\ GRO",
"52412", "Guanajuato",
"52233", "Puebla",
"52317", "Autlan\/El\ Chante\,\ JAL",
"52923", "Tabasco\/Veracruz",
"52247", "Huamantla\/San\ Cosme\ Xalostoc\,\ TLAX",
"52229", "Veracruz\,\ VER",
"52998", "Quintana\ Roo",
"52279", "Veracruz",
"52226", "Altotonga\/Jalacingo\,\ VER",
"52754", "Guerrero",
"52276", "Puebla",
"52734", "Morelos",
"52717", "Estado\ de\ Mexico",
"52467", "Zacatecas",
"52982", "Campeche",
"52936", "Tabasco",
"52824", "Sabinas\ Hidalgo\,\ NL",
"52494", "Jerez\ de\ Garcia\ Salinas\,\ ZAC",
"52991", "Yucatan",
"52645", "Cananea\,\ SON",
"52652", "Chihuahua",
"52777", "Morelos",
"52448", "Queretaro",
"52686", "Baja\ California",
"52749", "Calpulalpan\,\ TLAX",
"52727", "Guerrero",
"52632", "Imuris\/Magdalena\,\ SON",
"52346", "Jalisco\/Zacatecas",
"52596", "Estado\ de\ Mexico",
"52385", "Jalisco",
"52243", "Puebla",
"52415", "San\ Miguel\ Allende\,\ GTO",
"52765", "Alamo\ Temapache\/Alazan\/Potrero\ Del\ Llano\,\ VER",
"52344", "Mexticacan\/Yahualica\,\ JAL",
"52861", "Nueva\ Rosita\/Sabinas\,\ COAH",
"52313", "Colima",
"52669", "Sinaloa",
"52594", "Estado\ de\ Mexico",
"52618", "Colonia\ Hidalgo\/Durango\,\ DGO",
"52237", "Puebla",
"52288", "Veracruz",
"52934", "Tabasco",
"52431", "Jalostotitlan\/Villa\ Obregon\,\ JAL",
"52826", "Nuevo\ Leon",
"52451", "Michoacan",
"52496", "Zacatecas",
"52274", "Oaxaca",
"52756", "Chilapa\/Olinala\,\ GRO",
"52791", "Ciudad\ Sahagun\,\ HGO",
"52628", "Chihuahua",
"5296", "Chiapas",
"52323", "Nayarit",
"52224", "Puebla",
"52736", "Guerrero",
"52782", "Poza\ Rica\,\ VER",
"52475", "Bajio\ de\ San\ Jose\/Encarnacion\ de\ Diaz\,\ JAL",
"52917", "Tabasco",
"52425", "Michoacan",
"52642", "Navojoa\/Pueblo\ Mayo\,\ SON",
"52739", "Huitzilac\/Tepoztlan\,\ MOR",
"52833", "Tampico\,\ TAMPS",
"52438", "Michoacan",
"52635", "Chihuahua",
"52759", "Hidalgo",
"52458", "Zacatecas",
"52621", "Chihuahua",
"52773", "Hidalgo",
"52499", "Jalisco\/Zacatecas",
"52356", "Tanhuato\/Yurecuaro\,\ MICH",
"52391", "Jalisco",
"52671", "Durango",
"52829", "Nuevo\ Leon",
"52723", "Coatepec\ Harinas\,\ MEX",
"52382", "Jalisco",
"52744", "Acapulco\/Xaltianguis\,\ GRO",
"52713", "Santiago\ Tianguistenco\,\ MEX",
"52868", "Tamaulipas",
"52463", "Jalpa\/Tabasco\,\ ZAC",
"52985", "Yucatan",
"52281", "Loma\ Bonita\,\ OAX",
"52437", "Jalisco\/Zacatecas",
"52966", "Arriaga\/Tonala\,\ CHIS",
"52789", "Veracruz",
"52646", "Baja\ California",
"52457", "Jalisco\/Zacatecas",
"52443", "Morelia\/Tarimbaro\,\ MICH",
"52797", "Puebla",
"52386", "Jalisco",
"52595", "Estado\ de\ Mexico",
"52414", "Tequisquiapan\,\ QRO",
"52345", "Jalisco",
"52764", "Puebla",
"52352", "La\ Piedad\,\ MICH",
"52474", "Lagos\ de\ Moreno\/Paso\ de\ Cuarenta\,\ JAL",
"52921", "Coatzacoalcos\/Ixhuatlan\ Del\ Sureste\,\ VER",
"5281", "Monterrey\,\ NL",
"52424", "Michoacan",
"52894", "Santa\ Apolonia\/Valle\ Hermoso\,\ TAMPS",
"52867", "Nuevo\ Laredo\/Tamaulipas",
"52275", "Puebla",
"52225", "Tlapacoyan\,\ VER",
"52231", "Teteles\/Teziutlan\,\ PUE",
"52296", "Veracruz",
"52662", "Sonora",
"52993", "Tabasco",
"52634", "Sonora",
"52238", "Santiago\ Miahuatlan\/Tehuacan\,\ PUE",
"52287", "Oaxaca",
"52872", "Coahuila\/Durango",
"52492", "Zacatecas",
"5233", "Guadalajara\,\ JAL",
"52984", "Quintana\ Roo",
"52481", "Ciudad\ Valles\,\ SLP",
"52389", "Nayarit",
"52649", "Chihuahua\/Durango",
"52786", "Ciudad\ Hidalgo\/Tuxpan\,\ MICH",
"52627", "Parral\,\ CHIH",
"52732", "Guerrero",
"52677", "Durango",
"52841", "Tamaulipas",
"52745", "Guerrero",
"52918", "Chiapas",
"52969", "Flamboyanes\/Yucalpeten\,\ YUC",
"52784", "Veracruz",
"52222", "Puebla",
"52272", "Maltrata\/Orizaba\,\ VER",
"52769", "Morelos",
"52718", "Estado\ de\ Mexico",
"52419", "Guanajuato",
"52468", "San\ Luis\ de\ la\ Paz\,\ GTO",
"52311", "Nayarit",
"52241", "Tlaxcala",
"52665", "Tecate\,\ BCN",
"52932", "Chiapas\/Tabasco",
"52986", "Yucatan",
"52636", "Chihuahua",
"52899", "Tamaulipas",
"52778", "Hidalgo",
"52321", "El\ Grullo\/El\ Limon\,\ JAL",
"52447", "Contepec\/Maravatio\,\ MICH",
"52429", "Guanajuato",
"52656", "Chihuahua",
"52728", "Lerma\/Santa\ Maria\ Atarasquillo\,\ MEX",
"52592", "Estado\ de\ Mexico",
"52453", "Apatzingan\,\ MICH",
"52342", "Gomez\ Farias\/Sayula\,\ JAL",
"52355", "Michoacan",
"52433", "Zacatecas",
"52495", "Aguascalientes\/Jalisco",
"52825", "Nuevo\ Leon",
"52328", "Michoacan",
"52771", "Pachuca\/Real\ Del\ Monte\,\ HGO",
"52623", "Sonora",
"52294", "Veracruz",
"52393", "Jalisco",
"52721", "Ixtapan\ de\ la\ Sal\,\ MEX",
"52673", "Sinaloa",
"52426", "Michoacan",
"52476", "San\ Francisco\ Del\ Rincon\,\ GTO",
"52735", "Cuautla\/Jonacatepec\,\ MOR",
"52659", "Chihuahua",
"52831", "Ciudad\ Mante\/Los\ Aztecas\,\ TAMPS",
"52742", "Guerrero",
"52755", "Ixtapa\/Zihuatanejo\,\ GRO",
"52639", "Chihuahua",
"52384", "Tala\/Teuchitlan\,\ JAL",
"52283", "Veracruz",
"52766", "Gutierrez\ Zamora\/Tecolutla\,\ VER",
"5295", "Oaxaca",
"52711", "Mexico\/Michoacan",
"52613", "Baja\ California\ Sur",
"52461", "Guanajuato",
"52248", "Puebla",
"52997", "Yucatan",
"52644", "Sonora",
"52731", "Morelos",
"52633", "Sonora",
"52842", "Coahuila",
"52751", "Morelos",
"52835", "Tamaulipas",
"52653", "Luis\ B\.\ Sanchez\/San\ Luis\ Rio\ Colorado\,\ SON",
"52358", "Tamazula\/Zapoltitic\,\ JAL",
"52387", "Jalisco",
"52629", "Chihuahua",
"52647", "Sonora",
"52871", "Coahuila",
"52994", "Oaxaca",
"52821", "Hualahuises\/Linares\,\ NL",
"52456", "Valle\ de\ Santiago\,\ GTO",
"52725", "Almoloya\ de\ Juarez\/Santa\ Maria\ Del\ Monte\,\ MEX",
"52967", "San\ Cristobal\ de\ las\ Casas\,\ CHIS",
"52775", "Tulancingo\,\ HGO",
"52436", "Zacapu\,\ MICH",
"52465", "Aguascalientes",
"52715", "Michoacan",
"52297", "Alvarado\,\ VER",
"5297", "Oaxaca",
"52668", "Sinaloa",
"52866", "Castanos\/Monclova\,\ COAH",
"52983", "Quintana\ Roo",
"52315", "Jalisco",
"52444", "San\ Luis\ Potosi\,\ SLP",
"52232", "La\ Vigueta\/Martinez\ de\ la\ Torre\,\ VER",
"52869", "Cuatro\ Cienegas\/San\ Buenaventura\,\ COAH",
"52763", "Tezontepec\ de\ Aldama\/Tlahuelilpan\,\ HGO",
"52661", "Primo\ Tapia\/Rosarito\,\ BCN",
"52413", "Apaseo\ el\ Alto\/Apaseo\ el\ Grande\,\ GTO",
"52245", "Puebla",
"52922", "Veracruz",
"52616", "Baja\ California",
"52738", "Mixquiahuala\/Tepatepec\,\ HGO",
"5248", "San\ Luis\ Potosi",
"52758", "Petatlan\/San\ Jeronimito\,\ GRO",
"52626", "Ojinaga\,\ CHIH",
"52459", "Michoacan",
"52351", "Ario\ de\ Rayon\/Zamora\,\ MICH",
"52676", "Durango",
"52423", "Michoacan",
"52878", "Piedras\ Negras\,\ COAH",
"52473", "Guanajuato\,\ GTO",
"52828", "Cadereyta\,\ NL",
"52498", "Zacatecas",
"52375", "Ameca\,\ JAL",
"52325", "Acaponeta\,\ NAY",
"52712", "Estado\ de\ Mexico",
"52462", "Irapuato\,\ GTO",
"52987", "Cozumel\,\ QRO",
"52938", "Ciudad\ Del\ Carmen\,\ CAMP",
"52394", "Cotija\ de\ la\ Paz\,\ MICH",
"52228", "Jalapa\/Tuzamapan\,\ VER",
"52674", "Durango",
"52999", "Conkal\/Merida\,\ YUC",
"52278", "Veracruz",
"52624", "Baja\ California\ Sur",
"5269", "Sinaloa",
"5237", "Jalisco",
"52614", "Chihuahua",
"52845", "Ebano\/Ponciano\ Arriaga\,\ SLP",
"52832", "Tamaulipas",
"52348", "Jalisco",
"52643", "Sonora",
"52741", "Guerrero",
"52284", "Angel\ Rosario\ Cabada\/Lerdo\ de\ Tejada\,\ VER",
"52383", "Michoacan",
"5258", "Estado\ de\ Mexico",
"52772", "Actopan\,\ HGO",
"52722", "Estado\ de\ Mexico",
"52637", "Altar\/Caborca\,\ SON",
"52591", "Estado\ de\ Mexico",
"52864", "Coahuila",
"52897", "Tamaulipas",
"52427", "Mexico\/Quintana\ Roo",
"52341", "Ciudad\ Guzman\,\ JAL",
"52449", "Aguascalientes\/Jesus\ Maria\,\ AGS",
"52748", "Hidalgo",
"52477", "Leon\,\ GTO",
"52783", "Tuxpan\,\ VER",
"52322", "Jalisco",
"52235", "Veracruz",
"52454", "Michoacan",
"52312", "Colima\/Los\ Tepames\,\ COL",
"52996", "Campeche",
"52434", "Michoacan",
"52767", "Guerrero",
"52417", "Guanajuato",
"52221", "Puebla",
"52271", "Veracruz",
"52675", "Durango",
"52395", "Jalisco",
"52625", "Chihuahua",
"52779", "Tizayuca\,\ HGO",
"52873", "Nuevo\ Leon",
"52428", "Ocampo\/San\ Felipe\,\ GTO",
"52823", "Nuevo\ Leon",
"52729", "Estado\ de\ Mexico",
"52747", "Guerrero",
"52478", "Calera\ Victor\ Rosales\,\ ZAC",
"52493", "Fresnillo\,\ ZAC",
"52753", "Michoacan",
"52326", "Jalisco",
"52651", "Sonoita\,\ SON",
"52733", "Iguala\,\ GRO",
"52631", "Nogales\,\ SON",
"52246", "Tlaxcala",
"52981", "Campeche\,\ CAMP",
"52285", "Veracruz",
"52992", "Chiapas",
"52316", "Jalisco",
"52768", "Veracruz",
"52719", "San\ Francisco\ Xonacatlan\/Temoaya\,\ MEX",
"52418", "Dolores\ Hidalgo\/San\ Diego\ de\ la\ Union\,\ GTO",
"52469", "Buenavista\ de\ Cortez\/Penjamo\,\ GTO",
"52844", "Saltillo\,\ COAH",
"52615", "Baja\ California\ Sur",
"52988", "Yucatan",
"52716", "Estado\ de\ Mexico",
"52937", "Cardenas\,\ TAB",
"52466", "Guanajuato",
"52761", "Hidalgo",
"52914", "Tabasco",
"52411", "Guanajuato",
"52319", "Nayarit",
"52227", "Huejotzingo\/San\ Buenaventura\ Nealtican\,\ PUE",
"52249", "Puebla",
"52836", "Tamaulipas",
"52329", "Nayarit",
"52347", "Jalisco",
"52421", "Guanajuato",
"52891", "Tamaulipas",
"52924", "Veracruz",
"52471", "Purepero\/Tlazazalca\,\ MICH",
"52435", "Huetamo\/San\ Lucas\,\ MICH",
"52776", "Puebla",
"52353", "Michoacan",
"52658", "Baja\ California",
"52687", "Sinaloa",
"5255", "Mexico\ City\,\ FD",
"52726", "Estado\ de\ Mexico",
"52455", "Michoacan",
"52442", "Queretaro",
"52638", "Puerto\ Penasco\,\ SON",
"52724", "Luvianos\/Tejupilco\ de\ Hidalgo\,\ MEX",
"52774", "Hidalgo",
"52995", "Magdalena\ Tequisistlan\/Santa\ Maria\ Jalapa\ Del\ Marquez\,\ OAX",
"52282", "Puebla\/Veracruz",
"52236", "Oaxaca\/Puebla",
"52834", "Ciudad\ Victoria\,\ TAMPS",
"52612", "La\ Paz\/Todos\ Santos\,\ BCS",
"52622", "Guaymas\/San\ Carlos\,\ SON",
"52737", "Morelos",
"52916", "Chiapas",
"52672", "Sinaloa",
"52392", "Jamay\/Ocotlan\,\ JAL",
"52757", "Huamuxtitlan\/Tlapa\ de\ Comonfort\,\ GRO",
"52381", "Cojumatlan\/San\ Jose\ de\ Gracia\,\ MICH",
"52877", "Ciudad\ Acuna\,\ COAH",
"52641", "Benjamin\ Hill\/Santa\ Ana\,\ SON",
"52743", "Hidalgo",
"52464", "Salamanca\,\ GTO",
"52714", "Estado\ de\ Mexico",
"52781", "Coyuca\ de\ Benitez\/San\ Jeronimo\ de\ Juarez\,\ GRO",
"52846", "Veracruz",
"52388", "Jalisco",
"52357", "Jalisco",
"52648", "Boquilla\/Ciudad\ Camargo\,\ CHIH",
"52343", "Jalisco",
"52244", "Puebla",
"52432", "Ciudad\ Manuel\ Doblado\/Romita\,\ GTO",
"52314", "Manzanillo\/Pena\ Colorada\,\ COL",
"52593", "Estado\ de\ Mexico",
"52452", "Nuevo\ San\ Juan\ Parangaricutiro\/Uruapan\,\ MICH",
"52919", "Chiapas",
"52445", "Moroleon\,\ GTO",
"52223", "Puebla",
"52273", "Veracruz",
"52324", "Nayarit",
"52667", "Sinaloa",
"52933", "Tabasco",
"52862", "Coahuila",};
$areanames{es} = {"52454", "Michoacán",
"52434", "Michoacán",
"52427", "México\/Quintana\ Roo",
"52341", "Ciudad\ Guzmán\,\ JAL",
"52449", "Aguascalientes\/Jesús\ María\,\ AGS",
"52477", "León\,\ GTO",
"52284", "Ángel\ Rosario\ Cabada\/Lerdo\ de\ Tejada\,\ VER",
"52383", "Michoacán",
"52938", "Ciudad\ del\ Carmen\,\ CAMP",
"52999", "Conkal\/Mérida\,\ YUC",
"5248", "San\ Luis\ Potosí",
"52459", "Michoacán",
"52351", "Ario\ de\ Rayón\/Zamora\,\ MICH",
"52423", "Michoacán",
"52444", "San\ Luis\ Potosí\,\ SLP",
"52232", "La\ Vigueta\/Martínez\ de\ la\ Torre\,\ VER",
"52869", "Cuatro\ Ciénegas\/San\ Buenaventura\,\ COAH",
"52715", "Michoacán",
"52866", "Castaños\/Monclova\,\ COAH",
"52653", "Luis\ B\.\ Sánchez\/San\ Luis\ Río\ Colorado\,\ SON",
"52358", "Tamazula\/Zapotiltic\,\ JAL",
"52725", "Almoloya\ de\ Juárez\/Santa\ María\ del\ Monte\,\ MEX",
"52967", "San\ Cristóbal\ de\ las\ Casas\,\ CHIS",
"52781", "Coyuca\ de\ Benítez\/San\ Jerónimo\ de\ Juárez\,\ GRO",
"52314", "Manzanillo\/Peña\ Colorada\,\ COL",
"52392", "Jamay\/Ocotlán\,\ JAL",
"52641", "Benjamín\ Hill\/Santa\ Ana\,\ SON",
"52877", "Ciudad\ Acuña\,\ COAH",
"52995", "Magdalena\ Tequisistlán\/Santa\ Maria\ Jalapa\ del\ Marqués\,\ OAX",
"52353", "Michoacán",
"5255", "Ciudad\ de\ México\,\ CDMX",
"52455", "Michoacán",
"52442", "Querétaro",
"52988", "Yucatán",
"52937", "Cárdenas\,\ TAB",
"52719", "San\ Francisco\ Xonacatlán\/Temoaya\,\ MEX",
"52418", "Dolores\ Hidalgo\/San\ Diego\ de\ la\ Unión\,\ GTO",
"52469", "Buenavista\ de\ Cortés\/Pénjamo\,\ GTO",
"52873", "Nuevo\ León",
"52823", "Nuevo\ León",
"52753", "Michoacán",
"52985", "Yucatán",
"52438", "Michoacán",
"52356", "Tanhuato\/Yurécuaro\,\ MICH",
"52829", "Nuevo\ León",
"52431", "Jalostotitlán\/Villa\ Obregón\,\ JAL",
"52826", "Nuevo\ León",
"52451", "Michoacán",
"52756", "Chilapa\/Olinalá\,\ GRO",
"52791", "Ciudad\ Sahagún\,\ HGO",
"52475", "Bajío\ de\ San\ José\/Encarnación\ de\ Diaz\,\ JAL",
"52425", "Michoacán",
"52765", "Álamo\ Temapache\/Alazán\/Potrero\ del\ Llano\,\ VER",
"52448", "Querétaro",
"52632", "Ímuris\/Magdalena\,\ SON",
"52494", "Jerez\ de\ García\ Salinas\,\ ZAC",
"52991", "Yucatán",
"52354", "Michoacán",
"52317", "Autlán\/El\ Chante\,\ JAL",
"52441", "Querétaro",
"52892", "Nuevo\ León",
"52422", "Michoacán",
"52766", "Gutiérrez\ Zamora\/Tecolutla\,\ VER",
"52711", "México\/Michoacán",
"52997", "Yucatán",
"52825", "Nuevo\ León",
"52328", "Michoacán",
"52771", "Pachuca\/Real\ del\ Monte\,\ HGO",
"52426", "Michoacán",
"52476", "San\ Francisco\ del\ Rincón\,\ GTO",
"52447", "Contepec\/Maravatío\,\ MICH",
"52728", "Lerma\/Santa\ María\ Atarasquillo\,\ MEX",
"52453", "Apatzingán\,\ MICH",
"52342", "Gómez\ Farías\/Sayula\,\ JAL",
"52355", "Michoacán",
"52986", "Yucatán",
"52238", "Santiago\ Miahuatlán\/Tehuacán\,\ PUE",
"52921", "Coatzacoalcos\/Ixhuatlán\ del\ Sureste\,\ VER",
"52424", "Michoacán",
"52867", "Nuevo\ León\/Tamaulipas",
"52231", "Teteles\/Teziutlán\,\ PUE",
"52966", "Arriaga\/Tonalá\,\ CHIS",
"52443", "Morelia\/Tarímbaro\,\ MICH",};

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