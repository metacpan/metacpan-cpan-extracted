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
package Number::Phone::StubCountry::RU;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190912215427;

my $formatters = [
                {
                  'format' => '$1-$2-$3',
                  'intl_format' => 'NA',
                  'leading_digits' => '[0-79]',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            7(?:
              1(?:
                [0-6]2|
                7|
                8[27]
              )|
              2(?:
                13[03-69]|
                62[013-9]
              )
            )|
            72[1-57-9]2
          ',
                  'national_rule' => '8 ($1)',
                  'pattern' => '(\\d{4})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            7(?:
              1(?:
                0(?:
                  [356]|
                  4[023]
                )|
                [18]|
                2(?:
                  3[013-9]|
                  5
                )|
                3[45]|
                43[013-79]|
                5(?:
                  3[1-8]|
                  4[1-7]|
                  5
                )|
                6(?:
                  3[0-35-9]|
                  [4-6]
                )
              )|
              2(?:
                1(?:
                  3[178]|
                  [45]
                )|
                [24-689]|
                3[35]|
                7[457]
              )
            )|
            7(?:
              14|
              23
            )4[0-8]|
            71(?:
              33|
              45
            )[1-79]
          ',
                  'national_rule' => '8 ($1)',
                  'pattern' => '(\\d{5})(\\d)(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '7',
                  'national_rule' => '8 ($1)',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2-$3-$4',
                  'leading_digits' => '[3489]',
                  'national_rule' => '8 ($1)',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            3(?:
              0[12]|
              4[1-35-79]|
              5[1-3]|
              65|
              8[1-58]|
              9[0145]
            )|
            4(?:
              01|
              1[1356]|
              2[13467]|
              7[1-5]|
              8[1-7]|
              9[1-689]
            )|
            8(?:
              1[1-8]|
              2[01]|
              3[13-6]|
              4[0-8]|
              5[15]|
              6[1-35-79]|
              7[1-37-9]
            )
          )\\d{7}
        ',
                'geographic' => '
          (?:
            3(?:
              0[12]|
              4[1-35-79]|
              5[1-3]|
              65|
              8[1-58]|
              9[0145]
            )|
            4(?:
              01|
              1[1356]|
              2[13467]|
              7[1-5]|
              8[1-7]|
              9[1-689]
            )|
            8(?:
              1[1-8]|
              2[01]|
              3[13-6]|
              4[0-8]|
              5[15]|
              6[1-35-79]|
              7[1-37-9]
            )
          )\\d{7}
        ',
                'mobile' => '9\\d{9}',
                'pager' => '',
                'personal_number' => '808\\d{7}',
                'specialrate' => '(80[39]\\d{7})',
                'toll_free' => '80[04]\\d{7}',
                'voip' => ''
              };
my %areanames = ();
$areanames{ru}->{733} = "Байконыр";
$areanames{ru}->{77102} = "Жезказган";
$areanames{ru}->{771030} = "Жана\-Аркинский\ р\-н";
$areanames{ru}->{771031} = "Шетский\ р\-н";
$areanames{ru}->{771032} = "Каражал";
$areanames{ru}->{771033} = "Шетский\ р\-н";
$areanames{ru}->{771034} = "Улытауский\ р\-н";
$areanames{ru}->{771035} = "Улытауский\ р\-н";
$areanames{ru}->{771036} = "Балхаш";
$areanames{ru}->{771037} = "Актогайский\ р\-н";
$areanames{ru}->{771038} = "Сыры\-Шаган";
$areanames{ru}->{771039} = "Приозерск";
$areanames{ru}->{7710403} = "Жайрем\ \(ГОК\)";
$areanames{ru}->{771041} = "Актау\,\ Жезказган";
$areanames{ru}->{771042} = "Акой";
$areanames{ru}->{771043} = "Жайрем\ \(поселок\)";
$areanames{ru}->{77106} = "Сатпаев";
$areanames{ru}->{77112} = "Уральск";
$areanames{ru}->{771130} = "Зеленовский\ р\-н";
$areanames{ru}->{771131} = "Зеленовский\ р\-н";
$areanames{ru}->{771132} = "Теректинский\ р\-н";
$areanames{ru}->{771133} = "Бурлинский\ р\-н";
$areanames{ru}->{771134} = "Сырымский\ р\-н";
$areanames{ru}->{771135} = "Жанибекский\ р\-н";
$areanames{ru}->{771136} = "Акжаикский\ р\-н";
$areanames{ru}->{771137} = "Чингирлауский\ р\-н";
$areanames{ru}->{771138} = "Казталовский\ р\-н";
$areanames{ru}->{771139} = "Таскалинский\ р\-н";
$areanames{ru}->{771140} = "Бокейординский\ р\-н";
$areanames{ru}->{771141} = "Жангалинский\ р\-н";
$areanames{ru}->{771142} = "Акжаикский\ р\-н";
$areanames{ru}->{771143} = "Теректинский\ р\-н";
$areanames{ru}->{771144} = "Казталовский\ р\-н";
$areanames{ru}->{771145} = "Каратобинский\ р\-н";
$areanames{ru}->{771146} = "Акжаикский\ р\-н";
$areanames{ru}->{771147} = "Акжаикский\ р\-н";
$areanames{ru}->{771149} = "Акжаикский\ р\-н";
$areanames{ru}->{77122} = "Атырау";
$areanames{ru}->{771230} = "Атырауская\ область";
$areanames{ru}->{7712302} = "Тенгизшевройл";
$areanames{ru}->{7712303} = "Тензиз";
$areanames{ru}->{771231} = "Исатайский\ р\-н";
$areanames{ru}->{771232} = "Атырауская\ область";
$areanames{ru}->{771233} = "Курмангазинский\ р\-н";
$areanames{ru}->{771234} = "Индерский\ р\-н";
$areanames{ru}->{771235} = "Макатский\ р\-н";
$areanames{ru}->{771236} = "Махамбетский\ р\-н";
$areanames{ru}->{771237} = "Жылыойский\ р\-н";
$areanames{ru}->{771238} = "Кзылкогинский\ р\-н";
$areanames{ru}->{771239} = "Макатский\ р\-н";
$areanames{ru}->{77125} = "Атырауская\ область";
$areanames{ru}->{77132} = "Актобе\/Актюбинск";
$areanames{ru}->{771330} = "Хромтауский\ р\-н";
$areanames{ru}->{771331} = "Мартукский\ р\-н";
$areanames{ru}->{771332} = "Уилский\ р\-н";
$areanames{ru}->{771333} = "Мугалжарский\ р\-н";
$areanames{ru}->{771334} = "Мугалжарский\ р\-н";
$areanames{ru}->{771335} = "Шалкарский\ р\-н";
$areanames{ru}->{771336} = "Хромтауский\ р\-н";
$areanames{ru}->{771337} = "Алгинский\ р\-н";
$areanames{ru}->{771339} = "Айтекебийский\ р\-н";
$areanames{ru}->{771340} = "Хобдинский\ р\-н";
$areanames{ru}->{771341} = "Хобдинский\ р\-н";
$areanames{ru}->{771342} = "Каргалинский\ р\-н";
$areanames{ru}->{771343} = "Иргизский\ р\-н";
$areanames{ru}->{771345} = "Байганинский\ р\-н";
$areanames{ru}->{771346} = "Темирский\ р\-н";
$areanames{ru}->{771347} = "Айтекебийский\ р\-н";
$areanames{ru}->{771348} = "Шалкарский\ р\-н";
$areanames{ru}->{771349} = "Шалкарский\ р\-н";
$areanames{ru}->{77135} = "Актюбинская\ область";
$areanames{ru}->{77142} = "Костанай";
$areanames{ru}->{771430} = "Аркалык";
$areanames{ru}->{771431} = "Рудный";
$areanames{ru}->{771433} = "Лисаковск";
$areanames{ru}->{771434} = "Денисовский\ р\-н";
$areanames{ru}->{771435} = "Житикаринский\ р\-н";
$areanames{ru}->{771436} = "Тарановский\ р\-н";
$areanames{ru}->{771437} = "Камыстинский\ р\-н";
$areanames{ru}->{771438} = "Амангельдинский\ р\-н";
$areanames{ru}->{771439} = "Джангильдинский\ р\-н";
$areanames{ru}->{771440} = "Амангельдинский\ р\-н";
$areanames{ru}->{771441} = "Карабалыкский\ р\-н";
$areanames{ru}->{771442} = "Федоровский\ р\-н";
$areanames{ru}->{771443} = "Мендыкаринский\ р\-н";
$areanames{ru}->{771444} = "Узункольский\ р\-н";
$areanames{ru}->{771445} = "Алтынсаринский\ р\-н";
$areanames{ru}->{771446} = "Узункольский\ р\-н";
$areanames{ru}->{771447} = "Карабалыкский\ р\-н";
$areanames{ru}->{771448} = "Карасуский\ р\-н";
$areanames{ru}->{771449} = "Тарановский\ р\-н";
$areanames{ru}->{771451} = "Сарыкольский\ р\-н";
$areanames{ru}->{771452} = "Карасуский\ р\-н";
$areanames{ru}->{771453} = "Аулиекольский\ р\-н";
$areanames{ru}->{771454} = "Наурзумский\ р\-н";
$areanames{ru}->{771455} = "Костанайский\ р\-н";
$areanames{ru}->{771456} = "Качар";
$areanames{ru}->{771457} = "Джангильдинский\ р\-н";
$areanames{ru}->{771458} = "Костанайская\ область";
$areanames{ru}->{77145834} = "Красногорск";
$areanames{ru}->{771459} = "Костанайская\ область";
$areanames{ru}->{77152} = "Петропавловск";
$areanames{ru}->{771531} = "Магжана\ Жумабаева\ р\-н";
$areanames{ru}->{771532} = "Аккайынский\ р\-н";
$areanames{ru}->{771533} = "Айыртауский\ р\-н";
$areanames{ru}->{771534} = "Шал\ Акына\ р\-н";
$areanames{ru}->{771535} = "Габита\ Мусрепова\ р\-н";
$areanames{ru}->{771536} = "Тайыншинский\ р\-н";
$areanames{ru}->{771537} = "Тимирязевский\ р\-н";
$areanames{ru}->{771538} = "Кызылжарский\ р\-н";
$areanames{ru}->{771539} = "Кызылжарский\ р\-н";
$areanames{ru}->{771540} = "Уалихановский\ р\-н";
$areanames{ru}->{771541} = "Мамлютский\ р\-н";
$areanames{ru}->{771542} = "Уалихановский\ р\-н";
$areanames{ru}->{771543} = "Есильский\ р\-н";
$areanames{ru}->{771544} = "Жамбылский\ р\-н";
$areanames{ru}->{771545} = "Жамбылский\ р\-н";
$areanames{ru}->{771546} = "Акжарский\ р\-н";
$areanames{ru}->{771547} = "Жамбылский\ р\-н";
$areanames{ru}->{77162} = "Кокшетау";
$areanames{ru}->{771630} = "Боровое";
$areanames{ru}->{771631} = "Шортандинский\ р\-н";
$areanames{ru}->{771632} = "Зерендинский\ р\-н";
$areanames{ru}->{771633} = "Ерейментауский\ р\-н";
$areanames{ru}->{771635} = "Жаксынский\ р\-н";
$areanames{ru}->{771636} = "Щучинский\ р\-н";
$areanames{ru}->{771637} = "Коргалжынский\ р\-н";
$areanames{ru}->{771638} = "Аккольский\ р\-н";
$areanames{ru}->{771639} = "Енбекшилдерский\ р\-н";
$areanames{ru}->{771640} = "Сандыктауский\ р\-н";
$areanames{ru}->{771641} = "Астраханский\ р\-н";
$areanames{ru}->{771642} = "Егиндыкольский\ р\-н";
$areanames{ru}->{771643} = "Атбасарский\ р\-н";
$areanames{ru}->{771644} = "Аршалынский\ р\-н";
$areanames{ru}->{771645} = "Степногорск";
$areanames{ru}->{771646} = "Буландинский\ р\-н";
$areanames{ru}->{771647} = "Есильский\ р\-н";
$areanames{ru}->{771648} = "Жаркаинский\ р\-н";
$areanames{ru}->{771649} = "Жаксынский\ р\-н";
$areanames{ru}->{771651} = "Целиноградский\ р\-н";
$areanames{ru}->{7717} = "Астана";
$areanames{ru}->{77182} = "Павлодар";
$areanames{ru}->{771831} = "Железинский\ р\-н";
$areanames{ru}->{771832} = "Иртышский\ р\-н";
$areanames{ru}->{771833} = "Качирский\ р\-н";
$areanames{ru}->{771834} = "Успенский\ р\-н";
$areanames{ru}->{771836} = "Щербактинский\ р\-н";
$areanames{ru}->{771837} = "Аксуский\ р\-н";
$areanames{ru}->{771838} = "Майский\ р\-он";
$areanames{ru}->{771839} = "Лебяжинский\ р\-н";
$areanames{ru}->{771840} = "Баянаульский\ р\-н";
$areanames{ru}->{771841} = "Актогайский\ р\-н";
$areanames{ru}->{771842} = "Актогайский\ р\-н";
$areanames{ru}->{771843} = "Майский\ р\-н";
$areanames{ru}->{771844} = "Иртышский\ р\-н";
$areanames{ru}->{771845} = "Павлодар";
$areanames{ru}->{77187} = "Экибастуз";
$areanames{ru}->{77212} = "Караганда";
$areanames{ru}->{77213} = "Темиртау";
$areanames{ru}->{772131} = "Абайский\ р\-н";
$areanames{ru}->{772132} = "Нуринский\ р\-н";
$areanames{ru}->{772137} = "Сарань";
$areanames{ru}->{772138} = "Бухар\-Жырауский\ р\-н";
$areanames{ru}->{772144} = "Нуринский\ р\-н";
$areanames{ru}->{772146} = "Каркаралинск";
$areanames{ru}->{772147} = "Каркаралинский\ р\-н";
$areanames{ru}->{772148} = "Осакаровский\ р\-н";
$areanames{ru}->{772149} = "Осакаровский\ р\-н";
$areanames{ru}->{772153} = "Абайский\ р\-н";
$areanames{ru}->{772154} = "Бухар\-Жырауский\ р\-н";
$areanames{ru}->{772156} = "Шахтинск";
$areanames{ru}->{772159} = "Карагандинская\ область";
$areanames{ru}->{77222} = "Семипалатинск";
$areanames{ru}->{772230} = "Урджарский\ р\-н";
$areanames{ru}->{772236} = "Бескарагайский\ р\-н";
$areanames{ru}->{772237} = "Аязог";
$areanames{ru}->{772239} = "Урджарский\ р\-н";
$areanames{ru}->{77224} = "Эмельтау";
$areanames{ru}->{772251} = "Курчатов";
$areanames{ru}->{772252} = "Абайский\ р\-н";
$areanames{ru}->{772256} = "Алгабас";
$areanames{ru}->{772257} = "Шульбинск";
$areanames{ru}->{77232} = "Усть\-Каменогорск";
$areanames{ru}->{772330} = "Зыряновский\ р\-н";
$areanames{ru}->{772331} = "Глубоковский\ р\-н";
$areanames{ru}->{772332} = "Шемонаихинский\ р\-н";
$areanames{ru}->{772333} = "Кокпектинский\ р\-н";
$areanames{ru}->{772334} = "Уланский\ р\-н";
$areanames{ru}->{772335} = "Зыряновск";
$areanames{ru}->{772336} = "Риддер";
$areanames{ru}->{772337} = "Серебрянск";
$areanames{ru}->{772338} = "Уланский\ р\-н";
$areanames{ru}->{772339} = "Курчумский\ р\-н";
$areanames{ru}->{772340} = "Зайсанский\ р\-н";
$areanames{ru}->{772341} = "Катон\-Карагайский\ р\-н";
$areanames{ru}->{772342} = "Катон\-Карагайский\ р\-н";
$areanames{ru}->{772343} = "Курчумский\ р\-н";
$areanames{ru}->{772344} = "Тарбагатайский\ р\-н";
$areanames{ru}->{772345} = "Жарминский\ р\-н";
$areanames{ru}->{772346} = "Тарбагатайский\ р\-н";
$areanames{ru}->{772347} = "Жарминский\ р\-н";
$areanames{ru}->{772348} = "Кокпектинский\ р\-н";
$areanames{ru}->{772351} = "Бородулихинский\ р\-н";
$areanames{ru}->{772353} = "Бородулихинский\ р\-н";
$areanames{ru}->{77242} = "Кызылорда";
$areanames{ru}->{772431} = "Жалагашский\ р\-н";
$areanames{ru}->{772432} = "Шиелийский\ р\-н";
$areanames{ru}->{772433} = "Аральский\ р\-н";
$areanames{ru}->{772435} = "Жанакорганский\ р\-н";
$areanames{ru}->{772436} = "Сырдарьинский\ р\-н";
$areanames{ru}->{772437} = "Кармакшинский\ р\-н";
$areanames{ru}->{772438} = "Казалинский\ р\-н";
$areanames{ru}->{772439} = "Аральский\ р\-н";
$areanames{ru}->{77245} = "Кызылординская\ область";
$areanames{ru}->{77252} = "Шымкент";
$areanames{ru}->{772530} = "Темирлановка";
$areanames{ru}->{772531} = "Аксукент";
$areanames{ru}->{772532} = "Абая";
$areanames{ru}->{772533} = "Туркестан";
$areanames{ru}->{772534} = "Жетысай";
$areanames{ru}->{772535} = "Шардара";
$areanames{ru}->{772536} = "Кентау";
$areanames{ru}->{772537} = "Сарыагаш";
$areanames{ru}->{772538} = "имени\ Турара\ Рыскулова";
$areanames{ru}->{772539} = "Казыгурт";
$areanames{ru}->{772540} = "Арыс";
$areanames{ru}->{772541} = "Мырзакент";
$areanames{ru}->{772542} = "Асыката";
$areanames{ru}->{772544} = "Шаульдер";
$areanames{ru}->{772546} = "Шолаккорган";
$areanames{ru}->{772547} = "Ленгер";
$areanames{ru}->{772548} = "Шаян";
$areanames{ru}->{77262} = "Тараз";
$areanames{ru}->{772631} = "Турара\ Рыскулова\ р\-н";
$areanames{ru}->{772632} = "Меркенский\ р\-н";
$areanames{ru}->{772633} = "Жамбылский\ р\-н";
$areanames{ru}->{772634} = "Жанатас";
$areanames{ru}->{772635} = "Жуалынский\ р\-н";
$areanames{ru}->{772636} = "Кордай";
$areanames{ru}->{772637} = "Байзакский\ р\-н";
$areanames{ru}->{772638} = "Шуский\ р\-н";
$areanames{ru}->{772639} = "Сарысуский\ р\-н";
$areanames{ru}->{772640} = "Мойынкумский\ р\-н";
$areanames{ru}->{772641} = "Таласский\ р\-н";
$areanames{ru}->{772642} = "Мойынкумский\ р\-н";
$areanames{ru}->{772643} = "Шуский\ р\-н";
$areanames{ru}->{772644} = "Таласский\ р\-н";
$areanames{ru}->{77272} = "Алма\-Ата";
$areanames{ru}->{772725} = "Отеген\-Батыр";
$areanames{ru}->{77272956} = "Талгар";
$areanames{ru}->{77272983} = "Каскелен";
$areanames{ru}->{77273} = "Алма\-Ата";
$areanames{ru}->{77274} = "Карасайский\ р\-н";
$areanames{ru}->{772752} = "Илийский\ р\-н";
$areanames{ru}->{772757} = "Акший";
$areanames{ru}->{772759} = "Алматинская\ область";
$areanames{ru}->{772770} = "Жамбылский\ р\-н";
$areanames{ru}->{772771} = "Карасайский\ р\-н";
$areanames{ru}->{772772} = "Капчагай";
$areanames{ru}->{772773} = "Балхашский\ р\-н";
$areanames{ru}->{772774} = "Талгарский\ р\-н";
$areanames{ru}->{772775} = "Енбекшиказахский\ р\-н";
$areanames{ru}->{772776} = "Енбекшиказахский\ р\-н";
$areanames{ru}->{772777} = "Райымбекский\ р\-н";
$areanames{ru}->{772778} = "Уйгурский\ р\-н";
$areanames{ru}->{772779} = "Райымбекский\ р\-н";
$areanames{ru}->{77279} = "Алматы";
$areanames{ru}->{77282} = "Талдыкорган";
$areanames{ru}->{772830} = "Алакольский\ р\-н";
$areanames{ru}->{772831} = "Панфиловский\ р\-н";
$areanames{ru}->{772832} = "Аксуский\ р\-н";
$areanames{ru}->{772833} = "Алакольский\ р\-н";
$areanames{ru}->{772834} = "Каратальский\ р\-н";
$areanames{ru}->{772835} = "Текели";
$areanames{ru}->{772836} = "Ескельдинский\ р\-н";
$areanames{ru}->{772837} = "Алакольский\ р\-н";
$areanames{ru}->{772838} = "Коксуский\ р\-н";
$areanames{ru}->{772839} = "Саркандский\ р\-н";
$areanames{ru}->{772840} = "Кербулакский\ р\-н";
$areanames{ru}->{772841} = "Аксуский\ р\-н";
$areanames{ru}->{772842} = "Кербулакский\ р\-н";
$areanames{ru}->{772843} = "Лепсы";
$areanames{ru}->{77292} = "Актау";
$areanames{ru}->{772931} = "Мангистауский\ р\-н";
$areanames{ru}->{772932} = "Бейнеуский\ р\-н";
$areanames{ru}->{772934} = "Жанаозен";
$areanames{ru}->{772935} = "Каракиянский\ р\-н";
$areanames{ru}->{772937} = "Каракиянский\ р\-н";
$areanames{ru}->{772938} = "Тупкараганский\ р\-н";
$areanames{en}->{7301} = "Republic\ of\ Buryatia";
$areanames{en}->{7302} = "Chita";
$areanames{en}->{733} = "Baikonur";
$areanames{en}->{7341} = "Udmurtian\ Republic";
$areanames{en}->{7342} = "Perm";
$areanames{en}->{7343} = "Ekaterinburg";
$areanames{en}->{7345} = "Tyumen";
$areanames{en}->{7346} = "Surgut";
$areanames{en}->{7347} = "Republic\ of\ Bashkortostan";
$areanames{en}->{7349} = "Yamalo\-Nenets\ Autonomous\ District";
$areanames{en}->{7351} = "Chelyabinsk";
$areanames{en}->{7352} = "Kurgan";
$areanames{en}->{7353} = "Orenburg";
$areanames{en}->{7381} = "Omsk";
$areanames{en}->{7382} = "Tomsk";
$areanames{en}->{7383} = "Novosibirsk";
$areanames{en}->{7384} = "Kemerovo";
$areanames{en}->{7385} = "Altai\ Territory";
$areanames{en}->{7388} = "Republic\ of\ Altai";
$areanames{en}->{7390} = "Republic\ of\ Khakassia";
$areanames{en}->{7391} = "Krasnoyarsk\ Territory";
$areanames{en}->{7394} = "Republic\ of\ Tuva";
$areanames{en}->{740} = "Kaliningrad";
$areanames{en}->{7411} = "Republic\ of\ Sakha";
$areanames{en}->{7413} = "Magadan";
$areanames{en}->{7415} = "Kamchatka\ Region";
$areanames{en}->{7416} = "Amur\ Region";
$areanames{en}->{7421} = "Khabarovsk\ Territory";
$areanames{en}->{7423} = "Primorie\ territory";
$areanames{en}->{7424} = "Sakhalin\ Region";
$areanames{en}->{7426} = "Jewish\ Autonomous\ Region";
$areanames{en}->{7427} = "Chukotka\ Autonomous\ District";
$areanames{en}->{7471} = "Kursk";
$areanames{en}->{7472} = "Belgorod";
$areanames{en}->{7473} = "Voronezh";
$areanames{en}->{7474} = "Lipetsk";
$areanames{en}->{7475} = "Tambov";
$areanames{en}->{7481} = "Smolensk";
$areanames{en}->{7482} = "Tver";
$areanames{en}->{7483} = "Bryansk";
$areanames{en}->{7484} = "Kaluga";
$areanames{en}->{7485} = "Yaroslavl";
$areanames{en}->{7486} = "Orel";
$areanames{en}->{7487} = "Tula";
$areanames{en}->{7491} = "Ryazan";
$areanames{en}->{7492} = "Vladimir";
$areanames{en}->{7494} = "Kostroma";
$areanames{en}->{7495} = "Moscow";
$areanames{en}->{7496} = "Moscow";
$areanames{en}->{7498} = "Moscow";
$areanames{en}->{7499} = "Moscow";
$areanames{en}->{77102} = "Zhezkazgan";
$areanames{en}->{771030} = "Atasu";
$areanames{en}->{771031} = "Aksu\-Ayuly";
$areanames{en}->{771032} = "Karazhal";
$areanames{en}->{771033} = "Agadyr";
$areanames{en}->{771034} = "Zhezdy";
$areanames{en}->{771035} = "Ulytau";
$areanames{en}->{771036} = "Balkhash";
$areanames{en}->{771037} = "Aktogai";
$areanames{en}->{771038} = "Shashubai";
$areanames{en}->{771039} = "Priozersk";
$areanames{en}->{771040} = "Zhairem\ \(GOK\)";
$areanames{en}->{771041} = "Aktau\,\ Zhezkazgan";
$areanames{en}->{771042} = "Zharyk";
$areanames{en}->{771043} = "Zhairem";
$areanames{en}->{77106} = "Satpaev";
$areanames{en}->{77112} = "Uralsk";
$areanames{en}->{771130} = "Peremetnoye";
$areanames{en}->{771131} = "Darinskoye";
$areanames{en}->{771132} = "Fyodorovka";
$areanames{en}->{771133} = "Aksai";
$areanames{en}->{771134} = "Zhympity";
$areanames{en}->{771135} = "Zhanibek";
$areanames{en}->{771136} = "Chapayev";
$areanames{en}->{771137} = "Chingirlau";
$areanames{en}->{771138} = "Zhalpaktal";
$areanames{en}->{771139} = "Taskala";
$areanames{en}->{771140} = "Saikhin";
$areanames{en}->{771141} = "Zhangala";
$areanames{en}->{771142} = "Taipak";
$areanames{en}->{771143} = "Akzhaik";
$areanames{en}->{771144} = "Kaztalovka";
$areanames{en}->{771145} = "Karatobe\ District";
$areanames{en}->{771146} = "Akzhaiksky\ District";
$areanames{en}->{771147} = "Akzhaiksky\ District";
$areanames{en}->{771149} = "Zelenovsky\ District";
$areanames{en}->{77122} = "Atyrau";
$areanames{en}->{771230} = "Atyrau\ Region";
$areanames{en}->{7712302} = "Tengizshevroil";
$areanames{en}->{7712303} = "Tengizs";
$areanames{en}->{771231} = "Akkystau";
$areanames{en}->{771232} = "Atyrau\ Region";
$areanames{en}->{771233} = "Ganyushkino";
$areanames{en}->{771234} = "Indernborski";
$areanames{en}->{771235} = "Dossor";
$areanames{en}->{771236} = "Makhambet";
$areanames{en}->{771237} = "Kulsary";
$areanames{en}->{771238} = "Miyaly";
$areanames{en}->{771239} = "Makat";
$areanames{en}->{77125} = "Atyrau\ Region";
$areanames{en}->{77132} = "Aktobe\/Kargalinskoye";
$areanames{en}->{771330} = "Khromtau\ District";
$areanames{en}->{771331} = "Martuk";
$areanames{en}->{771332} = "Uil";
$areanames{en}->{771333} = "Kandyagash";
$areanames{en}->{771334} = "Emba";
$areanames{en}->{771335} = "Shalkar";
$areanames{en}->{771336} = "Khromtau";
$areanames{en}->{771337} = "Alga";
$areanames{en}->{771339} = "Komsomolskoye";
$areanames{en}->{771340} = "Khobdinsky\ District";
$areanames{en}->{771341} = "Khobda";
$areanames{en}->{771342} = "Badamsha";
$areanames{en}->{771343} = "Irgiz";
$areanames{en}->{771345} = "Karauylkeldy";
$areanames{en}->{771346} = "Shubarkuduk";
$areanames{en}->{771347} = "Aitekebisky\ District";
$areanames{en}->{771348} = "Shalkarsky\ District";
$areanames{en}->{771349} = "Shalkarsky\ District";
$areanames{en}->{77135} = "Aktobe\ Region";
$areanames{en}->{77142} = "Kostanai";
$areanames{en}->{771430} = "Arkalyk";
$areanames{en}->{771431} = "Rudny";
$areanames{en}->{771433} = "Lisakovsk";
$areanames{en}->{771434} = "Denisovka";
$areanames{en}->{771435} = "Zhitikara";
$areanames{en}->{771436} = "Taranovskoye";
$areanames{en}->{771437} = "Kamysty";
$areanames{en}->{771438} = "Amangeldy";
$areanames{en}->{771439} = "Torgai";
$areanames{en}->{771440} = "Amangeldy";
$areanames{en}->{771441} = "Karabalyk";
$areanames{en}->{771442} = "Fyodorovka";
$areanames{en}->{771443} = "Borovskoi";
$areanames{en}->{771444} = "Uzunkol";
$areanames{en}->{771445} = "Ubaganskoye";
$areanames{en}->{771446} = "Uzunkolsky\ District";
$areanames{en}->{771447} = "Karabalyksky\ District";
$areanames{en}->{771448} = "Oktyabrskoye";
$areanames{en}->{771449} = "Taranovskoye";
$areanames{en}->{771451} = "Sarykol";
$areanames{en}->{771452} = "Karasu";
$areanames{en}->{771453} = "Auliekol";
$areanames{en}->{771454} = "Karamendy";
$areanames{en}->{771455} = "Zatobolsk";
$areanames{en}->{771456} = "Kachar";
$areanames{en}->{771457} = "Dzhangildinsky\ District";
$areanames{en}->{771458} = "Kostanai\ Region";
$areanames{en}->{77145834} = "Krasnogorsk";
$areanames{en}->{771459} = "Kostanai\ Region";
$areanames{en}->{77152} = "Petropavlovsk";
$areanames{en}->{771531} = "Bulayevo";
$areanames{en}->{771532} = "Smirnovo";
$areanames{en}->{771533} = "Saumalkol";
$areanames{en}->{771534} = "Sergeyevka";
$areanames{en}->{771535} = "Novoishimski";
$areanames{en}->{771536} = "Taiynsha";
$areanames{en}->{771537} = "Timiryazevo";
$areanames{en}->{771538} = "Beskol";
$areanames{en}->{771539} = "Beskol";
$areanames{en}->{771540} = "Kishkenekol";
$areanames{en}->{771541} = "Mamlutka";
$areanames{en}->{771542} = "Kishkenekol";
$areanames{en}->{771543} = "Yavlenka";
$areanames{en}->{771544} = "Presnovka";
$areanames{en}->{771545} = "Zhambylsky\ District";
$areanames{en}->{771546} = "Talshik";
$areanames{en}->{771547} = "Zhambylsky\ District";
$areanames{en}->{77162} = "Kokshetau\/Krasni\ Yar";
$areanames{en}->{771630} = "Burabay";
$areanames{en}->{771631} = "Shortandy";
$areanames{en}->{771632} = "Zerenda";
$areanames{en}->{771633} = "Ereimentau";
$areanames{en}->{771635} = "Zhaksy";
$areanames{en}->{771636} = "Shuchinsk";
$areanames{en}->{771637} = "Korgalzhyn";
$areanames{en}->{771638} = "Akkol";
$areanames{en}->{771639} = "Stepnyak";
$areanames{en}->{771640} = "Balkashino";
$areanames{en}->{771641} = "Astrakhanka";
$areanames{en}->{771642} = "Egendykol";
$areanames{en}->{771643} = "Atbasar";
$areanames{en}->{771644} = "Arshaly";
$areanames{en}->{771645} = "Stepnogorsk";
$areanames{en}->{771646} = "Makinsk";
$areanames{en}->{771647} = "Esil";
$areanames{en}->{771648} = "Derzhavinsk";
$areanames{en}->{771649} = "Zhaksynsky\ District";
$areanames{en}->{771651} = "Kabanbai\ Batyr";
$areanames{en}->{7717} = "Astana";
$areanames{en}->{77182} = "Pavlodar";
$areanames{en}->{771831} = "Zhelezinka";
$areanames{en}->{771832} = "Irtyshsk";
$areanames{en}->{771833} = "Terenkol";
$areanames{en}->{771834} = "Uspenka";
$areanames{en}->{771836} = "Sharbakty";
$areanames{en}->{771837} = "Aksu";
$areanames{en}->{771838} = "Koktobe";
$areanames{en}->{771839} = "Akku";
$areanames{en}->{771840} = "Bayanaul";
$areanames{en}->{771841} = "Aktogai";
$areanames{en}->{771842} = "Aktogaisky\ District";
$areanames{en}->{771843} = "Maisky\ District";
$areanames{en}->{771844} = "Irtyshsky\ District";
$areanames{en}->{771845} = "Pavlodar\ Area";
$areanames{en}->{77187} = "Ekibastuz";
$areanames{en}->{77212} = "Karaganda";
$areanames{en}->{77213} = "Aktau\/Temirtau";
$areanames{en}->{772131} = "Abai";
$areanames{en}->{772132} = "Nurinsky\ District";
$areanames{en}->{772137} = "Saran";
$areanames{en}->{772138} = "Gabidena\ Mustafina";
$areanames{en}->{772144} = "Kiyevka";
$areanames{en}->{772146} = "Karkaralinsk";
$areanames{en}->{772147} = "Egindybulak";
$areanames{en}->{772148} = "Molodezhnoye";
$areanames{en}->{772149} = "Osakarovka";
$areanames{en}->{772153} = "Topar";
$areanames{en}->{772154} = "Botakara";
$areanames{en}->{772156} = "Shakhtinsk";
$areanames{en}->{772159} = "Karaganda\ Region";
$areanames{en}->{77222} = "Semey";
$areanames{en}->{772230} = "Urdzhar";
$areanames{en}->{772236} = "Beskaragai";
$areanames{en}->{772237} = "Ayagoz";
$areanames{en}->{772239} = "Makanchi";
$areanames{en}->{77224} = "Barshatas";
$areanames{en}->{772251} = "Kurchatov";
$areanames{en}->{772252} = "Karaul";
$areanames{en}->{772256} = "Kainar";
$areanames{en}->{772257} = "Shulbinsk";
$areanames{en}->{77232} = "Ust\-Kamenogorsk";
$areanames{en}->{772330} = "Zyryanovsky\ District";
$areanames{en}->{772331} = "Glubokoye";
$areanames{en}->{772332} = "Shemonaikha";
$areanames{en}->{772333} = "Samarskoye";
$areanames{en}->{772334} = "Tavricheskoye";
$areanames{en}->{772335} = "Zyryanovsk";
$areanames{en}->{772336} = "Ridder";
$areanames{en}->{772337} = "Serebryansk";
$areanames{en}->{772338} = "Bozanbai\/Molodezhnyi";
$areanames{en}->{772339} = "Kurchum";
$areanames{en}->{772340} = "Zaisan";
$areanames{en}->{772341} = "Ulken\ Naryn";
$areanames{en}->{772342} = "Katon\-Karagai";
$areanames{en}->{772343} = "Terekty";
$areanames{en}->{772344} = "Akzhar";
$areanames{en}->{772345} = "Shar";
$areanames{en}->{772346} = "Aksuat";
$areanames{en}->{772347} = "Kalbatau";
$areanames{en}->{772348} = "Kokpekty";
$areanames{en}->{772351} = "Borodulikha";
$areanames{en}->{772353} = "Novaya\ Shulba";
$areanames{en}->{77242} = "Kyzylorda";
$areanames{en}->{772431} = "Zhalagash";
$areanames{en}->{772432} = "Shiyeli";
$areanames{en}->{772433} = "Aralsk";
$areanames{en}->{772435} = "Zhanakorgan";
$areanames{en}->{772436} = "Terenozek";
$areanames{en}->{772437} = "Zhosaly";
$areanames{en}->{772438} = "Aiteke\ bi";
$areanames{en}->{772439} = "Aralsky\ District";
$areanames{en}->{77245} = "Kyzylorda\ Region";
$areanames{en}->{77252} = "Shymkent";
$areanames{en}->{772530} = "Temirlanovka";
$areanames{en}->{772531} = "Aksukent";
$areanames{en}->{772532} = "Abai";
$areanames{en}->{772533} = "Turkestan";
$areanames{en}->{772534} = "Zhetysai";
$areanames{en}->{772535} = "Shardara";
$areanames{en}->{772536} = "Kentau";
$areanames{en}->{772537} = "Saryagash";
$areanames{en}->{772538} = "Turara\ Ryskulova";
$areanames{en}->{772539} = "Kazygurt";
$areanames{en}->{772540} = "Arys";
$areanames{en}->{772541} = "Myrzakent";
$areanames{en}->{772542} = "Asykata";
$areanames{en}->{772544} = "Shaulder";
$areanames{en}->{772546} = "Sholakkorgan";
$areanames{en}->{772547} = "Lenger";
$areanames{en}->{772548} = "Shayan";
$areanames{en}->{77262} = "Taraz";
$areanames{en}->{772631} = "Kulan";
$areanames{en}->{772632} = "Merke";
$areanames{en}->{772633} = "Asa";
$areanames{en}->{772634} = "Zhanatas";
$areanames{en}->{772635} = "Bauyrzhan\ Mamyshuly";
$areanames{en}->{772636} = "Kordai";
$areanames{en}->{772637} = "Sarykemer";
$areanames{en}->{772638} = "Tole\ bi";
$areanames{en}->{772639} = "Saudakent";
$areanames{en}->{772640} = "Moiynkumsky\ District";
$areanames{en}->{772641} = "Akkol";
$areanames{en}->{772642} = "Moiynkum";
$areanames{en}->{772643} = "Shu";
$areanames{en}->{772644} = "Karatau";
$areanames{en}->{77272} = "Almaty";
$areanames{en}->{772725} = "Otegen\ Batyra";
$areanames{en}->{77272956} = "Talgar";
$areanames{en}->{77272983} = "Kaskelen";
$areanames{en}->{77273} = "Almaty";
$areanames{en}->{77274} = "Karassaisky\ District";
$areanames{en}->{772752} = "Otegen\ Batyra";
$areanames{en}->{772757} = "Akshi";
$areanames{en}->{772759} = "Almaty\ Region";
$areanames{en}->{772770} = "Uzynagash";
$areanames{en}->{772771} = "Kaskelen";
$areanames{en}->{772772} = "Kapchagai";
$areanames{en}->{772773} = "Bakanas";
$areanames{en}->{772774} = "Talgar";
$areanames{en}->{772775} = "Esik";
$areanames{en}->{772776} = "Shelek";
$areanames{en}->{772777} = "Kegen";
$areanames{en}->{772778} = "Chundzha";
$areanames{en}->{772779} = "Narynkol";
$areanames{en}->{77279} = "Almaty";
$areanames{en}->{77282} = "Taldykorgan";
$areanames{en}->{772830} = "Alakolsky\ District";
$areanames{en}->{772831} = "Zharkent";
$areanames{en}->{772832} = "Zhansugurov";
$areanames{en}->{772833} = "Usharal";
$areanames{en}->{772834} = "Ushtobe";
$areanames{en}->{772835} = "Tekeli";
$areanames{en}->{772836} = "Karabulak";
$areanames{en}->{772837} = "Kabanbai";
$areanames{en}->{772838} = "Balpyk\ bi";
$areanames{en}->{772839} = "Sarkand";
$areanames{en}->{772840} = "Saryozek";
$areanames{en}->{772841} = "Kapal";
$areanames{en}->{772842} = "Kogaly";
$areanames{en}->{772843} = "Lepsy";
$areanames{en}->{77292} = "Aktau";
$areanames{en}->{772931} = "Shetpe";
$areanames{en}->{772932} = "Beineu";
$areanames{en}->{772934} = "Zhanaozen";
$areanames{en}->{772935} = "Zhetybai";
$areanames{en}->{772937} = "Kuryk";
$areanames{en}->{772938} = "Fort\ Shevchenko";
$areanames{en}->{7811} = "Pskov";
$areanames{en}->{7812} = "St\ Petersburg";
$areanames{en}->{7813} = "Leningrad\ region";
$areanames{en}->{7814} = "Republic\ of\ Karelia";
$areanames{en}->{7815} = "Murmansk";
$areanames{en}->{7816} = "Veliky\ Novgorod";
$areanames{en}->{7817} = "Vologda";
$areanames{en}->{7818} = "Arkhangelsk";
$areanames{en}->{7820} = "Cherepovets";
$areanames{en}->{7821} = "Komi\ Republic";
$areanames{en}->{7831} = "Nizhni\ Novgorod";
$areanames{en}->{7833} = "Kirov";
$areanames{en}->{7834} = "Republic\ of\ Mordovia";
$areanames{en}->{7835} = "Chuvashi\ Republic";
$areanames{en}->{7836} = "Republic\ of\ Marij\ El";
$areanames{en}->{7841} = "Penza";
$areanames{en}->{7842} = "Ulyanovsk";
$areanames{en}->{7843} = "Republic\ of\ Tatarstan";
$areanames{en}->{7844} = "Volgograd";
$areanames{en}->{7845} = "Saratov";
$areanames{en}->{7846} = "Samara";
$areanames{en}->{7847} = "Republic\ of\ Kalmykia";
$areanames{en}->{7848} = "Tolyatti";
$areanames{en}->{7851} = "Astrakhan";
$areanames{en}->{7855} = "Naberezhnye\ Chelny";
$areanames{en}->{7861} = "Krasnodar\ Territory";
$areanames{en}->{7862} = "Sochi";
$areanames{en}->{7863} = "Rostov";
$areanames{en}->{7865} = "Stavropol\ territory";
$areanames{en}->{7866} = "Kabardino\-Balkarian\ Republic";
$areanames{en}->{7867} = "Republic\ of\ North\ Ossetia";
$areanames{en}->{7871} = "Chechen\ Republic";
$areanames{en}->{7872} = "Republic\ of\ Daghestan";
$areanames{en}->{7873} = "Ingushi\ Republic";
$areanames{en}->{7877} = "Republic\ of\ Adygeya";
$areanames{en}->{7878} = "Karachayevo\-Cherkessian\ Republic";
$areanames{en}->{7879} = "Mineranye\ Vody";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+7|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:8)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;