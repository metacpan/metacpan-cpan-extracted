# automatically generated file, don't edit



# Copyright 2025 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20250913135858;

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
                }
              ];

my $validators = {
                'fixed_line' => '
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
              [267][1-9]|
              3[1-8]|
              [45]\\d|
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
              5[1-36-9]|
              6[0-57-9]|
              7[1-7]|
              8[67]|
              9[4-8]
            )|
            7(?:
              [1346][1-9]|
              [27]\\d|
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
              7[0-378]|
              9[12479]
            )|
            9(?:
              1[346-9]|
              2[1-4]|
              3[2-46-8]|
              5[1348]|
              [69]\\d|
              7[12]|
              8[1-8]
            )
          )\\d{7}
        ',
                'geographic' => '
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
              [267][1-9]|
              3[1-8]|
              [45]\\d|
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
              5[1-36-9]|
              6[0-57-9]|
              7[1-7]|
              8[67]|
              9[4-8]
            )|
            7(?:
              [1346][1-9]|
              [27]\\d|
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
              7[0-378]|
              9[12479]
            )|
            9(?:
              1[346-9]|
              2[1-4]|
              3[2-46-8]|
              5[1348]|
              [69]\\d|
              7[12]|
              8[1-8]
            )
          )\\d{7}
        ',
                'mobile' => '
          (?:
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
              [267][1-9]|
              3[1-8]|
              [45]\\d|
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
              5[1-36-9]|
              6[0-57-9]|
              7[1-7]|
              8[67]|
              9[4-8]
            )|
            7(?:
              [1346][1-9]|
              [27]\\d|
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
              7[0-378]|
              9[12479]
            )|
            9(?:
              1[346-9]|
              2[1-4]|
              3[2-46-8]|
              5[1348]|
              [69]\\d|
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
$areanames{es} = {"52475", "Bajío\ de\ San\ José\/Encarnación\ de\ Diaz\,\ JAL",
"52986", "Yucatán",
"52469", "Buenavista\ de\ Cortés\/Pénjamo\,\ GTO",
"5258", "Estado\ de\ México",
"5248", "San\ Luis\ Potosí",
"52596", "Estado\ de\ México",
"5255", "Ciudad\ de\ México\,\ CDMX",
"52892", "Nuevo\ León",
"52431", "Jalostotitlán\/Villa\ Obregón\,\ JAL",
"52476", "San\ Francisco\ del\ Rincón\,\ GTO",
"52477", "León\,\ GTO",
"52985", "Yucatán",
"52711", "México\/Michoacán",
"52284", "Ángel\ Rosario\ Cabada\/Lerdo\ de\ Tejada\,\ VER",
"52328", "Michoacán",
"52447", "Contepec\/Maravatío\,\ MICH",
"52595", "Estado\ de\ México",
"52632", "Ímuris\/Magdalena\,\ SON",
"52729", "Estado\ de\ México",
"52921", "Coatzacoalcos\/Ixhuatlán\ del\ Sureste\,\ VER",
"52424", "Michoacán",
"52756", "Chilapa\/Olinalá\,\ GRO",
"52423", "Michoacán",
"52341", "Ciudad\ Guzmán\,\ JAL",
"52719", "San\ Francisco\ Xonacatlán\/Temoaya\,\ MEX",
"52829", "Nuevo\ León",
"52383", "Michoacán",
"52354", "Michoacán",
"52353", "Michoacán",
"52232", "La\ Vigueta\/Martínez\ de\ la\ Torre\,\ VER",
"52869", "Cuatro\ Ciénegas\/San\ Buenaventura\,\ COAH",
"52351", "Ario\ de\ Rayón\/Zamora\,\ MICH",
"52592", "Estado\ de\ México",
"52877", "Ciudad\ Acuña\,\ COAH",
"52442", "Querétaro",
"52995", "Magdalena\ Tequisistlán\/Santa\ Maria\ Jalapa\ del\ Marqués\,\ OAX",
"52434", "Michoacán",
"52448", "Querétaro",
"52823", "Nuevo\ León",
"52641", "Benjamín\ Hill\/Santa\ Ana\,\ SON",
"52455", "Michoacán",
"52714", "Estado\ de\ México",
"52997", "Yucatán",
"52238", "Santiago\ Miahuatlán\/Tehuacán\,\ PUE",
"52988", "Yucatán",
"52653", "Luis\ B\.\ Sánchez\/San\ Luis\ Río\ Colorado\,\ SON",
"52317", "Autlán\/El\ Chante\,\ JAL",
"52826", "Nuevo\ León",
"52938", "Ciudad\ del\ Carmen\,\ CAMP",
"52441", "Querétaro",
"52716", "Estado\ de\ México",
"52717", "Estado\ de\ México",
"52725", "Almoloya\ de\ Juárez\/Santa\ María\ del\ Monte\,\ MEX",
"52422", "Michoacán",
"52231", "Teteles\/Teziutlán\,\ PUE",
"52715", "Michoacán",
"52314", "Manzanillo\/Peña\ Colorada\,\ COL",
"52453", "Apatzingán\,\ MICH",
"52825", "Nuevo\ León",
"52454", "Michoacán",
"52726", "Estado\ de\ México",
"52591", "Estado\ de\ México",
"52449", "Aguascalientes\/Jesús\ María\,\ AGS",
"52660", "Culiacán",
"52418", "Dolores\ Hidalgo\/San\ Diego\ de\ la\ Unión\,\ GTO",
"52358", "Tamazula\/Zapotiltic\,\ JAL",
"52599", "Estado\ de\ México",
"52873", "Nuevo\ León",
"52781", "Coyuca\ de\ Benítez\/San\ Jerónimo\ de\ Juárez\,\ GRO",
"52459", "Michoacán",
"52712", "Estado\ de\ México",
"52791", "Ciudad\ Sahagún\,\ HGO",
"52753", "Michoacán",
"52427", "México\/Quintana\ Roo",
"52426", "Michoacán",
"52967", "San\ Cristóbal\ de\ las\ Casas\,\ CHIS",
"52355", "Michoacán",
"52966", "Arriaga\/Tonalá\,\ CHIS",
"52999", "Conkal\/Mérida\,\ YUC",
"52771", "Pachuca\/Real\ del\ Monte\,\ HGO",
"52356", "Tanhuato\/Yurécuaro\,\ MICH",
"52722", "Estado\ de\ México",
"52425", "Michoacán",
"52991", "Yucatán",
"52766", "Gutiérrez\ Zamora\/Tecolutla\,\ VER",
"52594", "Estado\ de\ México",
"52451", "Michoacán",
"52494", "Jerez\ de\ García\ Salinas\,\ ZAC",
"52593", "Estado\ de\ México",
"52728", "Lerma\/Santa\ María\ Atarasquillo\,\ MEX",
"52392", "Jamay\/Ocotlán\,\ JAL",
"52438", "Michoacán",
"52866", "Castaños\/Monclova\,\ COAH",
"52867", "Nuevo\ León\/Tamaulipas",
"52765", "Álamo\ Temapache\/Alazán\/Potrero\ del\ Llano\,\ VER",
"52443", "Morelia\/Tarímbaro\,\ MICH",
"52718", "Estado\ de\ México",
"52937", "Cárdenas\,\ TAB",
"52444", "San\ Luis\ Potosí\,\ SLP",
"52342", "Gómez\ Farías\/Sayula\,\ JAL",};
$areanames{en} = {"52249", "Puebla",
"52659", "Chihuahua",
"52921", "Coatzacoalcos\/Ixhuatlan\ Del\ Sureste\,\ VER",
"52668", "Sinaloa",
"52833", "Tampico\,\ TAMPS",
"52461", "Guanajuato",
"52834", "Ciudad\ Victoria\,\ TAMPS",
"52878", "Piedras\ Negras\,\ COAH",
"52632", "Imuris\/Magdalena\,\ SON",
"52729", "Estado\ de\ Mexico",
"52786", "Ciudad\ Hidalgo\/Tuxpan\,\ MICH",
"52341", "Ciudad\ Guzman\,\ JAL",
"52627", "Parral\,\ CHIH",
"52423", "Michoacan",
"52626", "Ojinaga\,\ CHIH",
"52322", "Jalisco",
"52756", "Chilapa\/Olinala\,\ GRO",
"52757", "Huamuxtitlan\/Tlapa\ de\ Comonfort\,\ GRO",
"52615", "Baja\ California\ Sur",
"52279", "Veracruz",
"52424", "Michoacan",
"52829", "Nuevo\ Leon",
"52778", "Hidalgo",
"52734", "Morelos",
"52719", "San\ Francisco\ Xonacatlan\/Temoaya\,\ MEX",
"52992", "Chiapas",
"52733", "Iguala\,\ GRO",
"52960", "Tuxtla\ Gutierrez",
"52312", "Colima\/Los\ Tepames\,\ COL",
"52625", "Chihuahua",
"52391", "Jalisco",
"52353", "Michoacan",
"52228", "Jalapa\/Tuzamapan\,\ VER",
"52384", "Tala\/Teuchitlan\,\ JAL",
"52785", "Veracruz",
"52414", "Tequisquiapan\,\ QRO",
"52748", "Hidalgo",
"52452", "Nuevo\ San\ Juan\ Parangaricutiro\/Uruapan\,\ MICH",
"52755", "Ixtapa\/Zihuatanejo\,\ GRO",
"52383", "Michoacan",
"52354", "Michoacan",
"52616", "Baja\ California",
"52413", "Apaseo\ el\ Alto\/Apaseo\ el\ Grande\,\ GTO",
"52772", "Actopan\,\ HGO",
"52987", "Cozumel\,\ QRO",
"52763", "Tezontepec\ de\ Aldama\/Tlahuelilpan\,\ HGO",
"52475", "Bajio\ de\ San\ Jose\/Encarnacion\ de\ Diaz\,\ JAL",
"52986", "Yucatan",
"52271", "Veracruz",
"52237", "Puebla",
"52349", "Jalisco",
"52236", "Oaxaca\/Puebla",
"52764", "Puebla",
"52998", "Quintana\ Roo",
"52222", "Puebla",
"52892", "Nuevo\ Leon",
"52721", "Ixtapan\ de\ la\ Sal\,\ MEX",
"5248", "San\ Luis\ Potosi",
"52596", "Estado\ de\ Mexico",
"5255", "Mexico\ City\,\ FD",
"52445", "Moroleon\,\ GTO",
"52651", "Sonoita\,\ SON",
"52241", "Tlaxcala",
"52469", "Buenavista\ de\ Cortez\/Penjamo\,\ GTO",
"52496", "Zacatecas",
"5258", "Estado\ de\ Mexico",
"52742", "Guerrero",
"52458", "Zacatecas",
"52864", "Coahuila",
"52476", "San\ Francisco\ Del\ Rincon\,\ GTO",
"52673", "Sinaloa",
"52477", "Leon\,\ GTO",
"52985", "Yucatan",
"52662", "Sonora",
"52674", "Durango",
"52638", "Puerto\ Penasco\,\ SON",
"52431", "Jalostotitlan\/Villa\ Obregon\,\ JAL",
"52872", "Coahuila\/Durango",
"52235", "Veracruz",
"52934", "Tabasco",
"52919", "Chiapas",
"52842", "Coahuila",
"5297", "Oaxaca",
"52595", "Estado\ de\ Mexico",
"52283", "Veracruz",
"52644", "Sonora",
"52821", "Hualahuises\/Linares\,\ NL",
"52495", "Aguascalientes\/Jalisco",
"52933", "Tabasco",
"52711", "Mexico\/Michoacan",
"52328", "Michoacan",
"52284", "Angel\ Rosario\ Cabada\/Lerdo\ de\ Tejada\,\ VER",
"52643", "Sonora",
"52447", "Contepec\/Maravatio\,\ MICH",
"52478", "Calera\ Victor\ Rosales\,\ ZAC",
"52434", "Michoacan",
"52419", "Guanajuato",
"52389", "Nayarit",
"52671", "Durango",
"52995", "Magdalena\ Tequisistlan\/Santa\ Maria\ Jalapa\ Del\ Marquez\,\ OAX",
"52433", "Zacatecas",
"52636", "Chihuahua",
"52637", "Altar\/Caborca\,\ SON",
"52861", "Nueva\ Rosita\/Sabinas\,\ COAH",
"52720", "Toluca",
"52714", "Estado\ de\ Mexico",
"52739", "Huitzilac\/Tepoztlan\,\ MOR",
"52281", "Loma\ Bonita\,\ OAX",
"52315", "Jalisco",
"52622", "Guaymas\/San\ Carlos\,\ SON",
"52824", "Sabinas\ Hidalgo\,\ NL",
"52782", "Poza\ Rica\,\ VER",
"52294", "Veracruz",
"52641", "Benjamin\ Hill\/Santa\ Ana\,\ SON",
"52713", "Santiago\ Tianguistenco\,\ MEX",
"52455", "Michoacan",
"52448", "Queretaro",
"52326", "Jalisco",
"52823", "Nuevo\ Leon",
"52327", "Nayarit",
"52761", "Hidalgo",
"52273", "Veracruz",
"52988", "Yucatan",
"52429", "Guanajuato",
"52238", "Santiago\ Miahuatlan\/Tehuacan\,\ PUE",
"52274", "Oaxaca",
"5295", "Oaxaca",
"52635", "Chihuahua",
"52969", "Flamboyanes\/Yucalpeten\,\ YUC",
"52996", "Campeche",
"52997", "Yucatan",
"52723", "Coatepec\ Harinas\,\ MEX",
"52316", "Jalisco",
"52317", "Autlan\/El\ Chante\,\ JAL",
"52244", "Puebla",
"52325", "Acaponeta\,\ NAY",
"52724", "Luvianos\/Tejupilco\ de\ Hidalgo\,\ MEX",
"52612", "La\ Paz\/Todos\ Santos\,\ BCS",
"52457", "Jalisco\/Zacatecas",
"52498", "Zacatecas",
"52243", "Puebla",
"52653", "Luis\ B\.\ Sanchez\/San\ Luis\ Rio\ Colorado\,\ SON",
"52456", "Valle\ de\ Santiago\,\ GTO",
"52982", "Campeche",
"52649", "Chihuahua\/Durango",
"52777", "Morelos",
"52914", "Tabasco",
"52665", "Tecate\,\ BCN",
"52776", "Puebla",
"52731", "Morelos",
"52232", "La\ Vigueta\/Martinez\ de\ la\ Torre\,\ VER",
"52913", "Tabasco",
"52351", "Ario\ de\ Rayon\/Zamora\,\ MICH",
"52845", "Ebano\/Ponciano\ Arriaga\,\ SLP",
"52592", "Estado\ de\ Mexico",
"52897", "Tamaulipas",
"52226", "Altotonga\/Jalacingo\,\ VER",
"52227", "Huejotzingo\/San\ Buenaventura\ Nealtican\,\ PUE",
"52393", "Jalisco",
"52869", "Cuatro\ Cienegas\/San\ Buenaventura\,\ COAH",
"52381", "Cojumatlan\/San\ Jose\ de\ Gracia\,\ MICH",
"52492", "Zacatecas",
"52747", "Guerrero",
"52746", "Puebla\/Veracruz",
"52411", "Guanajuato",
"52618", "Colonia\ Hidalgo\/Durango\,\ DGO",
"52394", "Cotija\ de\ la\ Paz\,\ MICH",
"5233", "Guadalajara\,\ JAL",
"52667", "Sinaloa",
"52463", "Jalpa\/Tabasco\,\ ZAC",
"52775", "Tulancingo\,\ HGO",
"52472", "Silao\,\ GTO",
"52923", "Tabasco\/Veracruz",
"52831", "Ciudad\ Mante\/Los\ Aztecas\,\ TAMPS",
"52877", "Ciudad\ Acuna\,\ COAH",
"52464", "Salamanca\,\ GTO",
"52924", "Veracruz",
"52225", "Tlapacoyan\,\ VER",
"52421", "Guanajuato",
"52343", "Jalisco",
"52846", "Veracruz",
"52628", "Chihuahua",
"52442", "Queretaro",
"52797", "Puebla",
"52758", "Petatlan\/San\ Jeronimito\,\ GRO",
"52769", "Morelos",
"52344", "Mexticacan\/Yahualica\,\ JAL",
"52745", "Guerrero",
"52762", "Taxco\,\ GRO",
"52449", "Aguascalientes\/Jesus\ Maria\,\ AGS",
"52773", "Hidalgo",
"52465", "Aguascalientes",
"52917", "Tabasco",
"52738", "Mixquiahuala\/Tepatepec\,\ HGO",
"52375", "Ameca\,\ JAL",
"52916", "Chiapas",
"52774", "Hidalgo",
"52345", "Jalisco",
"52744", "Acapulco\/Xaltianguis\,\ GRO",
"52223", "Puebla",
"52358", "Tamazula\/Zapoltitic\,\ JAL",
"52870", "Coahuila\/Durango",
"52743", "Hidalgo",
"52388", "Jalisco",
"52224", "Puebla",
"52660", "Culiacan",
"52894", "Santa\ Apolonia\/Valle\ Hermoso\,\ TAMPS",
"52418", "Dolores\ Hidalgo\/San\ Diego\ de\ la\ Union\,\ GTO",
"52467", "Zacatecas",
"52466", "Guanajuato",
"52499", "Jalisco\/Zacatecas",
"52672", "Sinaloa",
"52599", "Estado\ de\ Mexico",
"52220", "Puebla",
"52377", "Cocula\/Estipac\,\ JAL",
"52873", "Nuevo\ Leon",
"52862", "Coahuila",
"52282", "Puebla\/Veracruz",
"5296", "Chiapas",
"52621", "Chihuahua",
"52395", "Jalisco",
"52347", "Jalisco",
"52781", "Coyuca\ de\ Benitez\/San\ Jeronimo\ de\ Juarez\,\ GRO",
"52428", "Ocampo\/San\ Felipe\,\ GTO",
"52346", "Jalisco\/Zacatecas",
"52642", "Navojoa\/Pueblo\ Mayo\,\ SON",
"52770", "Cuernavaca\/Emiliano\ Zapata\/Temixco\/Xochitepec\/Jiutepec",
"52751", "Morelos",
"52932", "Chiapas\/Tabasco",
"52844", "Saltillo\,\ COAH",
"52634", "Sonora",
"52450", "Morelia",
"52471", "Purepero\/Tlazazalca\,\ MICH",
"52832", "Tamaulipas",
"52275", "Puebla",
"52436", "Zacapu\,\ MICH",
"52633", "Sonora",
"52868", "Tamaulipas",
"52437", "Jalisco\/Zacatecas",
"52990", "Merida",
"52422", "Michoacan",
"52324", "Nayarit",
"52288", "Veracruz",
"52725", "Almoloya\ de\ Juarez\/Santa\ Maria\ Del\ Monte\,\ MEX",
"52938", "Ciudad\ Del\ Carmen\,\ CAMP",
"52716", "Estado\ de\ Mexico",
"52441", "Queretaro",
"52245", "Puebla",
"52717", "Estado\ de\ Mexico",
"52826", "Nuevo\ Leon",
"52648", "Boquilla\/Ciudad\ Camargo\,\ CHIH",
"52323", "Nayarit",
"52297", "Alvarado\,\ VER",
"52296", "Veracruz",
"52276", "Puebla",
"52981", "Campeche\,\ CAMP",
"52994", "Oaxaca",
"52768", "Veracruz",
"52759", "Hidalgo",
"52629", "Chihuahua",
"52732", "Guerrero",
"52435", "Huetamo\/San\ Lucas\,\ MICH",
"52993", "Tabasco",
"52789", "Veracruz",
"52231", "Teteles\/Teziutlan\,\ PUE",
"52726", "Estado\ de\ Mexico",
"52352", "La\ Piedad\,\ MICH",
"52727", "Guerrero",
"52591", "Estado\ de\ Mexico",
"52313", "Colima",
"52687", "Sinaloa",
"52454", "Michoacan",
"52686", "Baja\ California",
"52825", "Nuevo\ Leon",
"52382", "Jalisco",
"52412", "Guanajuato",
"52715", "Michoacan",
"52657", "Chihuahua",
"52247", "Huamantla\/San\ Cosme\ Xalostoc\,\ TLAX",
"52314", "Manzanillo\/Pena\ Colorada\,\ COL",
"52656", "Chihuahua",
"52246", "Tlaxcala",
"5269", "Sinaloa",
"52453", "Apatzingan\,\ MICH",
"52278", "Veracruz",
"52766", "Gutierrez\ Zamora\/Tecolutla\,\ VER",
"52675", "Durango",
"52983", "Quintana\ Roo",
"52767", "Guerrero",
"52991", "Yucatan",
"52233", "Puebla",
"52984", "Quintana\ Roo",
"52728", "Lerma\/Santa\ Maria\ Atarasquillo\,\ MEX",
"52285", "Veracruz",
"52311", "Nayarit",
"52481", "Ciudad\ Valles\,\ SLP",
"52392", "Jamay\/Ocotlan\,\ JAL",
"52494", "Jerez\ de\ Garcia\ Salinas\,\ ZAC",
"52593", "Estado\ de\ Mexico",
"5281", "Monterrey\,\ NL",
"52645", "Cananea\,\ SON",
"52451", "Michoacan",
"52669", "Sinaloa",
"52493", "Fresnillo\,\ ZAC",
"52658", "Baja\ California",
"52248", "Puebla",
"52594", "Estado\ de\ Mexico",
"52473", "Guanajuato\,\ GTO",
"52676", "Durango",
"52765", "Alamo\ Temapache\/Alazan\/Potrero\ Del\ Llano\,\ VER",
"52677", "Durango",
"52922", "Veracruz",
"52749", "Calpulalpan\,\ TLAX",
"52462", "Irapuato\,\ GTO",
"52438", "Michoacan",
"52899", "Tamaulipas",
"52866", "Castanos\/Monclova\,\ COAH",
"52474", "Lagos\ de\ Moreno\/Paso\ de\ Cuarenta\,\ JAL",
"52229", "Veracruz\,\ VER",
"52867", "Nuevo\ Laredo\/Tamaulipas",
"52631", "Nogales\,\ SON",
"52342", "Gomez\ Farias\/Sayula\,\ JAL",
"52444", "San\ Luis\ Potosi\,\ SLP",
"52287", "Oaxaca",
"52936", "Tabasco",
"52779", "Tizayuca\,\ HGO",
"52321", "El\ Grullo\/El\ Limon\,\ JAL",
"52718", "Estado\ de\ Mexico",
"52937", "Cardenas\,\ TAB",
"52443", "Morelia\/Tarimbaro\,\ MICH",
"52828", "Cadereyta\,\ NL",
"52646", "Baja\ California",
"52647", "Sonora",
"52459", "Michoacan",
"52468", "San\ Luis\ de\ la\ Paz\,\ GTO",
"52836", "Tamaulipas",
"52661", "Primo\ Tapia\/Rosarito\,\ BCN",
"5237", "Jalisco",
"52319", "Nayarit",
"52735", "Cuautla\/Jonacatepec\,\ MOR",
"52432", "Ciudad\ Manuel\ Doblado\/Romita\,\ GTO",
"52871", "Coahuila",
"52967", "San\ Cristobal\ de\ las\ Casas\,\ CHIS",
"52754", "Guerrero",
"52783", "Tuxpan\,\ VER",
"52355", "Michoacan",
"52966", "Arriaga\/Tonala\,\ CHIS",
"52841", "Tamaulipas",
"52999", "Conkal\/Merida\,\ YUC",
"52427", "Mexico\/Quintana\ Roo",
"52426", "Michoacan",
"52623", "Sonora",
"52348", "Jalisco",
"52385", "Jalisco",
"52753", "Michoacan",
"52784", "Veracruz",
"52415", "San\ Miguel\ Allende\,\ GTO",
"52712", "Estado\ de\ Mexico",
"52624", "Baja\ California\ Sur",
"52791", "Ciudad\ Sahagun\,\ HGO",
"52771", "Pachuca\/Real\ Del\ Monte\,\ HGO",
"52329", "Nayarit",
"52835", "Tamaulipas",
"52272", "Maltrata\/Orizaba\,\ VER",
"52737", "Morelos",
"52736", "Guerrero",
"52918", "Chiapas",
"52221", "Puebla",
"52891", "Tamaulipas",
"52425", "Michoacan",
"52356", "Tanhuato\/Yurecuaro\,\ MICH",
"52722", "Estado\ de\ Mexico",
"52357", "Jalisco",
"52639", "Chihuahua",
"52614", "Chihuahua",
"52652", "Chihuahua",
"52417", "Guanajuato",
"52386", "Jalisco",
"52613", "Baja\ California\ Sur",
"52387", "Jalisco",
"52741", "Guerrero",};
my $timezones = {
               '' => [
                       'America/Hermosillo',
                       'America/Mazatlan',
                       'America/Mexico_City',
                       'America/New_York',
                       'America/Tijuana'
                     ],
               '2' => [
                        'America/Mexico_City'
                      ],
               '200' => [
                          'America/Mexico_City',
                          'America/Tijuana'
                        ],
               '201' => [
                          'America/Mexico_City',
                          'America/New_York'
                        ],
               '3' => [
                        'America/Mexico_City'
                      ],
               '311' => [
                          'America/Mazatlan'
                        ],
               '319' => [
                          'America/Mazatlan'
                        ],
               '323' => [
                          'America/Mazatlan'
                        ],
               '324' => [
                          'America/Mazatlan'
                        ],
               '325' => [
                          'America/Mazatlan'
                        ],
               '327' => [
                          'America/Mazatlan'
                        ],
               '389' => [
                          'America/Mazatlan'
                        ],
               '4' => [
                        'America/Mexico_City'
                      ],
               '5' => [
                        'America/Mexico_City'
                      ],
               '612' => [
                          'America/Mazatlan'
                        ],
               '613' => [
                          'America/Mazatlan'
                        ],
               '614' => [
                          'America/Mazatlan'
                        ],
               '615' => [
                          'America/Mazatlan'
                        ],
               '616' => [
                          'America/Tijuana'
                        ],
               '618' => [
                          'America/Mexico_City'
                        ],
               '62' => [
                         'America/Mazatlan'
                       ],
               '626' => [
                          'America/Hermosillo'
                        ],
               '63' => [
                         'America/Mazatlan'
                       ],
               '64' => [
                         'America/Mazatlan'
                       ],
               '646' => [
                          'America/Tijuana'
                        ],
               '649' => [
                          'America/Mazatlan',
                          'America/Mexico_City'
                        ],
               '651' => [
                          'America/Mazatlan'
                        ],
               '652' => [
                          'America/Mazatlan'
                        ],
               '653' => [
                          'America/Mazatlan'
                        ],
               '656' => [
                          'America/Hermosillo'
                        ],
               '657' => [
                          'America/Mazatlan'
                        ],
               '658' => [
                          'America/Tijuana'
                        ],
               '659' => [
                          'America/Mazatlan'
                        ],
               '660' => [
                          'America/Mazatlan'
                        ],
               '661' => [
                          'America/Tijuana'
                        ],
               '662' => [
                          'America/Mazatlan'
                        ],
               '663' => [
                          'America/Mexico_City'
                        ],
               '664' => [
                          'America/Tijuana'
                        ],
               '665' => [
                          'America/Tijuana'
                        ],
               '667' => [
                          'America/Mazatlan'
                        ],
               '668' => [
                          'America/Mazatlan'
                        ],
               '669' => [
                          'America/Mazatlan'
                        ],
               '671' => [
                          'America/Mexico_City'
                        ],
               '672' => [
                          'America/Mazatlan'
                        ],
               '673' => [
                          'America/Mazatlan'
                        ],
               '674' => [
                          'America/Mexico_City'
                        ],
               '675' => [
                          'America/Mexico_City'
                        ],
               '676' => [
                          'America/Mexico_City'
                        ],
               '677' => [
                          'America/Mexico_City'
                        ],
               '686' => [
                          'America/Tijuana'
                        ],
               '687' => [
                          'America/Mazatlan'
                        ],
               '69' => [
                         'America/Mazatlan'
                       ],
               '7' => [
                        'America/Mexico_City'
                      ],
               '8' => [
                        'America/Mexico_City'
                      ],
               '9' => [
                        'America/Mexico_City'
                      ],
               '983' => [
                          'America/New_York'
                        ],
               '984' => [
                          'America/New_York'
                        ],
               '987' => [
                          'America/New_York'
                        ],
               '998' => [
                          'America/New_York'
                        ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+52|\D)//g;
      my $self = bless({ country_code => '52', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;