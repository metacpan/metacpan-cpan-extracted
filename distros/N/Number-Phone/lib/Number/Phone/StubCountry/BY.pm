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
package Number::Phone::StubCountry::BY;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190912215423;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '800',
                  'national_rule' => '8 $1',
                  'pattern' => '(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '800',
                  'national_rule' => '8 $1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2,4})'
                },
                {
                  'format' => '$1 $2-$3',
                  'leading_digits' => '
            1(?:
              5[169]|
              6(?:
                3[1-3]|
                4|
                5[125]
              )|
              7(?:
                1[3-9]|
                7[0-24-6]|
                9[2-7]
              )
            )|
            2(?:
              1[35]|
              2[34]|
              3[3-5]
            )
          ',
                  'national_rule' => '8 0$1',
                  'pattern' => '(\\d{4})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2-$3-$4',
                  'leading_digits' => '
            1(?:
              [56]|
              7[467]
            )|
            2[1-3]
          ',
                  'national_rule' => '8 0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2-$3-$4',
                  'leading_digits' => '[1-4]',
                  'national_rule' => '8 0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[89]',
                  'national_rule' => '8 $1',
                  'pattern' => '(\\d{3})(\\d{3,4})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            1(?:
              5(?:
                1[1-5]|
                [24]\\d|
                6[2-4]|
                9[1-7]
              )|
              6(?:
                [235]\\d|
                4[1-7]
              )|
              7\\d\\d
            )|
            2(?:
              1(?:
                [246]\\d|
                3[0-35-9]|
                5[1-9]
              )|
              2(?:
                [235]\\d|
                4[0-8]
              )|
              3(?:
                [26]\\d|
                3[02-79]|
                4[024-7]|
                5[03-7]
              )
            )
          )\\d{5}
        ',
                'geographic' => '
          (?:
            1(?:
              5(?:
                1[1-5]|
                [24]\\d|
                6[2-4]|
                9[1-7]
              )|
              6(?:
                [235]\\d|
                4[1-7]
              )|
              7\\d\\d
            )|
            2(?:
              1(?:
                [246]\\d|
                3[0-35-9]|
                5[1-9]
              )|
              2(?:
                [235]\\d|
                4[0-8]
              )|
              3(?:
                [26]\\d|
                3[02-79]|
                4[024-7]|
                5[03-7]
              )
            )
          )\\d{5}
        ',
                'mobile' => '
          (?:
            2(?:
              5[5-79]|
              9[1-9]
            )|
            (?:
              33|
              44
            )\\d
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(
          (?:
            810|
            902
          )\\d{7}
        )',
                'toll_free' => '
          800\\d{3,7}|
          8(?:
            0[13]|
            20\\d
          )\\d{7}
        ',
                'voip' => '249\\d{6}'
              };
my %areanames = ();
$areanames{be}->{3751511} = "Вялікая\ Бераставіца\,\ Гродзенская\ вобласць";
$areanames{be}->{3751512} = "Ваўкавыск";
$areanames{be}->{3751513} = "Свіслач\,\ Гродзенская\ вобласць";
$areanames{be}->{3751514} = "Шчучын\,\ Гродзенская\ вобласць";
$areanames{be}->{3751515} = "Масты\,\ Гродзенская\ вобласць";
$areanames{be}->{375152} = "Гродна";
$areanames{be}->{375154} = "Ліда";
$areanames{be}->{3751562} = "Слонім";
$areanames{be}->{3751563} = "Дзятлава\,\ Гродзенская\ вобласць";
$areanames{be}->{3751564} = "Зэльва\,\ Гродзенская\ вобласць";
$areanames{be}->{3751591} = "Астравец\,\ Гродзенская\ вобласць";
$areanames{be}->{3751592} = "Смаргонь";
$areanames{be}->{3751593} = "Ашмяны";
$areanames{be}->{3751594} = "Воранава\,\ Гродзенская\ вобласць";
$areanames{be}->{3751595} = "Іўе\,\ Гродзенская\ вобласць";
$areanames{be}->{3751596} = "Карэлічы\,\ Гродзенская\ вобласць";
$areanames{be}->{3751597} = "Навагрудак";
$areanames{be}->{375162} = "Брэст";
$areanames{be}->{375163} = "Баранавічы";
$areanames{be}->{3751631} = "Камянец\,\ Брэсцкая\ вобласць";
$areanames{be}->{3751632} = "Пружаны\,\ Брэсцкая\ вобласць";
$areanames{be}->{3751633} = "Ляхавічы\,\ Брэсцкая\ вобласць";
$areanames{be}->{3751641} = "Жабінка\,\ Брэсцкая\ вобласць";
$areanames{be}->{3751642} = "Кобрын";
$areanames{be}->{3751643} = "Бяроза\,\ Брэсцкая\ вобласць";
$areanames{be}->{3751644} = "Драгічын\,\ Брэсцкая\ вобласць";
$areanames{be}->{3751645} = "Івацэвічы\,\ Брэсцкая\ вобласць";
$areanames{be}->{3751646} = "Ганцавічы\,\ Брэсцкая\ вобласць";
$areanames{be}->{3751647} = "Лунінец\,\ Брэсцкая\ вобласць";
$areanames{be}->{375165} = "Пінск";
$areanames{be}->{3751651} = "Маларыта\,\ Брэсцкая\ вобласць";
$areanames{be}->{3751652} = "Іванава\,\ Брэсцкая\ вобласць";
$areanames{be}->{3751655} = "Столін\,\ Брэсцкая\ вобласць";
$areanames{be}->{37517} = "Мінск";
$areanames{be}->{3751713} = "Мар\’іна\ Горка\,\ Мінская\ вобласць";
$areanames{be}->{3751714} = "Чэрвень";
$areanames{be}->{3751715} = "Беразіно\,\ Мінская\ вобласць";
$areanames{be}->{3751716} = "Дзяржынск";
$areanames{be}->{3751717} = "Стаўбцы";
$areanames{be}->{3751718} = "Узда\,\ Мінская\ вобласць";
$areanames{be}->{3751719} = "Капыль\,\ Мінская\ вобласць";
$areanames{be}->{375174} = "Салігорск";
$areanames{be}->{375176} = "Маладзечна";
$areanames{be}->{375177} = "Барысаў";
$areanames{be}->{3751770} = "Нясвіж";
$areanames{be}->{3751771} = "Вілейка";
$areanames{be}->{3751772} = "Валожын";
$areanames{be}->{3751774} = "Лагойск";
$areanames{be}->{3751775} = "Жодзіна";
$areanames{be}->{3751776} = "Смалявічы";
$areanames{be}->{3751792} = "Старыя\ Дарогі\,\ Мінская\ вобласць";
$areanames{be}->{3751793} = "Клецк\,\ Мінская\ вобласць";
$areanames{be}->{3751794} = "Любань\,\ Мінская\ вобласць";
$areanames{be}->{3751795} = "Слуцк";
$areanames{be}->{3751796} = "Крупкі\,\ Мінская\ вобласць";
$areanames{be}->{3751797} = "Мядзел";
$areanames{be}->{375212} = "Віцебск";
$areanames{be}->{3752130} = "Шуміліна\,\ Віцебская\ вобласць";
$areanames{be}->{3752131} = "Бешанковічы\,\ Віцебская\ вобласць";
$areanames{be}->{3752132} = "Лепель";
$areanames{be}->{3752133} = "Чашнікі\,\ Віцебская\ вобласць";
$areanames{be}->{3752135} = "Сянно\,\ Віцебская\ вобласць";
$areanames{be}->{3752136} = "Талачын";
$areanames{be}->{3752137} = "Дуброўна\,\ Віцебская\ вобласць";
$areanames{be}->{3752138} = "Лёзна\,\ Віцебская\ вобласць";
$areanames{be}->{3752139} = "Гарадок\,\ Віцебская\ вобласць";
$areanames{be}->{375214} = "Полацк\/Наваполацк";
$areanames{be}->{3752151} = "Верхнядзвінск\,\ Віцебская\ вобласць";
$areanames{be}->{3752152} = "Міёры\,\ Віцебская\ вобласць";
$areanames{be}->{3752153} = "Браслаў";
$areanames{be}->{3752154} = "Шаркоўшчына\,\ Віцебская\ вобласць";
$areanames{be}->{3752155} = "Паставы";
$areanames{be}->{3752156} = "Глыбокае";
$areanames{be}->{3752157} = "Докшыцы\,\ Віцебская\ вобласць";
$areanames{be}->{3752158} = "Ушачы\,\ Віцебская\ вобласць";
$areanames{be}->{3752159} = "Расоны\,\ Віцебская\ вобласць";
$areanames{be}->{375216} = "Орша";
$areanames{be}->{375222} = "Магілёў";
$areanames{be}->{3752230} = "Глуск\,\ Магілёўская\ вобласць";
$areanames{be}->{3752231} = "Быхаў\,\ Магілёўская\ вобласць";
$areanames{be}->{3752232} = "Бялынічы\,\ Магілёўская\ вобласць";
$areanames{be}->{3752233} = "Горкі\,\ Магілёўская\ вобласць";
$areanames{be}->{3752234} = "Круглае\,\ Магілёўская\ вобласць";
$areanames{be}->{3752235} = "Асіповічы";
$areanames{be}->{3752236} = "Клічаў\,\ Магілёўская\ вобласць";
$areanames{be}->{3752237} = "Кіраўск\,\ Магілёўская\ вобласць";
$areanames{be}->{3752238} = "Краснаполле\,\ Магілёўская\ вобласць";
$areanames{be}->{3752239} = "Шклоў";
$areanames{be}->{3752240} = "Мсціслаў";
$areanames{be}->{3752241} = "Крычаў\,\ Магілёўская\ вобласць";
$areanames{be}->{3752242} = "Чавусы\,\ Магілёўская\ вобласць";
$areanames{be}->{3752243} = "Чэрыкаў\,\ Магілёўская\ вобласць";
$areanames{be}->{3752244} = "Клімавічы\,\ Магілёўская\ вобласць";
$areanames{be}->{3752245} = "Касцюковічы\,\ Магілёўская\ вобласць";
$areanames{be}->{3752246} = "Слаўгарад\,\ Магілёўская\ вобласць";
$areanames{be}->{3752247} = "Хоцімск\,\ Магілёўская\ вобласць";
$areanames{be}->{3752248} = "Дрыбін\,\ Магілёўская\ вобласць";
$areanames{be}->{375225} = "Бабруйск";
$areanames{be}->{375232} = "Гомель";
$areanames{be}->{3752330} = "Ветка\,\ Гомельская\ вобласць";
$areanames{be}->{3752332} = "Чачэрск\,\ Гомельская\ вобласць";
$areanames{be}->{3752333} = "Добруш\,\ Гомельская\ вобласць";
$areanames{be}->{3752334} = "Жлобін";
$areanames{be}->{3752336} = "Буда\-Кашалёва\,\ Гомельская\ вобласць";
$areanames{be}->{3752337} = "Карма\,\ Гомельская\ вобласць";
$areanames{be}->{3752339} = "Рагачоў";
$areanames{be}->{3752340} = "Рэчыца";
$areanames{be}->{3752342} = "Светлагорск";
$areanames{be}->{3752344} = "Брагін\,\ Гомельская\ вобласць";
$areanames{be}->{3752345} = "Калінкавічы";
$areanames{be}->{3752346} = "Хойнікі\,\ Гомельская\ вобласць";
$areanames{be}->{3752347} = "Лоеў\,\ Гомельская\ вобласць";
$areanames{be}->{3752350} = "Петрыкаў\,\ Гомельская\ вобласць";
$areanames{be}->{3752353} = "Жыткавічы\,\ Гомельская\ вобласць";
$areanames{be}->{3752354} = "Ельск\,\ Гомельская\ вобласць";
$areanames{be}->{3752355} = "Нароўля\,\ Гомельская\ вобласць";
$areanames{be}->{3752356} = "Лельчыцы\,\ Гомельская\ вобласць";
$areanames{be}->{3752357} = "Акцябрскі\,\ Гомельская\ вобласць";
$areanames{be}->{375236} = "Мазыр";
$areanames{ru}->{3751511} = "Берестовица\,\ Гродненская\ область";
$areanames{ru}->{3751512} = "Волковыск";
$areanames{ru}->{3751513} = "Свислочь\,\ Гродненская\ область";
$areanames{ru}->{3751514} = "Щучин\,\ Гродненская\ область";
$areanames{ru}->{3751515} = "Мосты\,\ Гродненская\ область";
$areanames{ru}->{375152} = "Гродно";
$areanames{ru}->{375154} = "Лида";
$areanames{ru}->{3751562} = "Слоним";
$areanames{ru}->{3751563} = "Дятлово\,\ Гродненская\ область";
$areanames{ru}->{3751564} = "Зельва\,\ Гродненская\ область";
$areanames{ru}->{3751591} = "Островец\,\ Гродненская\ область";
$areanames{ru}->{3751592} = "Сморгонь";
$areanames{ru}->{3751593} = "Ошмяны";
$areanames{ru}->{3751594} = "Вороново\,\ Гродненская\ область";
$areanames{ru}->{3751595} = "Ивье\,\ Гродненская\ область";
$areanames{ru}->{3751596} = "Кореличи\,\ Гродненская\ область";
$areanames{ru}->{3751597} = "Новогрудок";
$areanames{ru}->{375162} = "Брест";
$areanames{ru}->{375163} = "Барановичи";
$areanames{ru}->{3751631} = "Каменец\,\ Брестская\ область";
$areanames{ru}->{3751632} = "Пружаны\,\ Брестская\ область";
$areanames{ru}->{3751633} = "Ляховичи\,\ Брестская\ область";
$areanames{ru}->{3751641} = "Жабинка\,\ Брестская\ область";
$areanames{ru}->{3751642} = "Кобрин";
$areanames{ru}->{3751643} = "Береза\,\ Брестская\ область";
$areanames{ru}->{3751644} = "Дрогичин\,\ Брестская\ область";
$areanames{ru}->{3751645} = "Ивацевичи\,\ Брестская\ область";
$areanames{ru}->{3751646} = "Ганцевичи\,\ Брестская\ область";
$areanames{ru}->{3751647} = "Лунинец\,\ Брестская\ область";
$areanames{ru}->{375165} = "Пинск";
$areanames{ru}->{3751651} = "Малорита\,\ Брестская\ область";
$areanames{ru}->{3751652} = "Иваново\,\ Брестская\ область";
$areanames{ru}->{3751655} = "Столин\,\ Брестская\ область";
$areanames{ru}->{37517} = "Минск";
$areanames{ru}->{3751713} = "Марьина\ Горка\,\ Минская\ область";
$areanames{ru}->{3751714} = "Червень";
$areanames{ru}->{3751715} = "Березино\,\ Минская\ область";
$areanames{ru}->{3751716} = "Дзержинск";
$areanames{ru}->{3751717} = "Столбцы";
$areanames{ru}->{3751718} = "Узда\,\ Минская\ область";
$areanames{ru}->{3751719} = "Копыль\,\ Минская\ область";
$areanames{ru}->{375174} = "Солигорск";
$areanames{ru}->{375176} = "Молодечно";
$areanames{ru}->{375177} = "Борисов";
$areanames{ru}->{3751770} = "Несвиж";
$areanames{ru}->{3751771} = "Вилейка";
$areanames{ru}->{3751772} = "Воложин";
$areanames{ru}->{3751774} = "Логойск";
$areanames{ru}->{3751775} = "Жодино";
$areanames{ru}->{3751776} = "Смолевичи";
$areanames{ru}->{3751792} = "Старые\ Дороги\,\ Минская\ область";
$areanames{ru}->{3751793} = "Клецк\,\ Минская\ область";
$areanames{ru}->{3751794} = "Любань\,\ Минская\ область";
$areanames{ru}->{3751795} = "Слуцк";
$areanames{ru}->{3751796} = "Крупки\,\ Минская\ область";
$areanames{ru}->{3751797} = "Мядель";
$areanames{ru}->{375212} = "Витебск";
$areanames{ru}->{3752130} = "Шумилино\,\ Витебская\ область";
$areanames{ru}->{3752131} = "Бешенковичи\,\ Витебская\ область";
$areanames{ru}->{3752132} = "Лепель";
$areanames{ru}->{3752133} = "Чашники\,\ Витебская\ область";
$areanames{ru}->{3752135} = "Сенно\,\ Витебская\ область";
$areanames{ru}->{3752136} = "Толочин";
$areanames{ru}->{3752137} = "Дубровно\,\ Витебская\ область";
$areanames{ru}->{3752138} = "Лиозно\,\ Витебская\ область";
$areanames{ru}->{3752139} = "Городок\,\ Витебская\ область";
$areanames{ru}->{375214} = "Полоцк\/Новополоцк";
$areanames{ru}->{3752151} = "Верхнедвинск\,\ Витебская\ область";
$areanames{ru}->{3752152} = "Миоры\,\ Витебская\ область";
$areanames{ru}->{3752153} = "Браслав";
$areanames{ru}->{3752154} = "Шарковщина\,\ Витебская\ область";
$areanames{ru}->{3752155} = "Поставы";
$areanames{ru}->{3752156} = "Глубокое";
$areanames{ru}->{3752157} = "Докшицы\,\ Витебская\ область";
$areanames{ru}->{3752158} = "Ушачи\,\ Витебская\ область";
$areanames{ru}->{3752159} = "Россоны\,\ Витебская\ область";
$areanames{ru}->{375216} = "Орша";
$areanames{ru}->{375222} = "Могилев";
$areanames{ru}->{3752230} = "Глуск\,\ Могилевская\ область";
$areanames{ru}->{3752231} = "Быхов\,\ Могилевская\ область";
$areanames{ru}->{3752232} = "Белыничи\,\ Могилевская\ область";
$areanames{ru}->{3752233} = "Горки\,\ Могилевская\ область";
$areanames{ru}->{3752234} = "Круглое\,\ Могилевская\ область";
$areanames{ru}->{3752235} = "Осиповичи";
$areanames{ru}->{3752236} = "Кличев\,\ Могилевская\ область";
$areanames{ru}->{3752237} = "Кировск\,\ Могилевская\ область";
$areanames{ru}->{3752238} = "Краснополье\,\ Могилевская\ область";
$areanames{ru}->{3752239} = "Шклов";
$areanames{ru}->{3752240} = "Мстиславль";
$areanames{ru}->{3752241} = "Кричев\,\ Могилевская\ область";
$areanames{ru}->{3752242} = "Чаусы\,\ Могилевская\ область";
$areanames{ru}->{3752243} = "Чериков\,\ Могилевская\ область";
$areanames{ru}->{3752244} = "Климовичи\,\ Могилевская\ область";
$areanames{ru}->{3752245} = "Костюковичи\,\ Могилевская\ область";
$areanames{ru}->{3752246} = "Славгород\,\ Могилевская\ область";
$areanames{ru}->{3752247} = "Хотимск\,\ Могилевская\ область";
$areanames{ru}->{3752248} = "Дрибин\,\ Могилевская\ область";
$areanames{ru}->{375225} = "Бобруйск";
$areanames{ru}->{375232} = "Гомель";
$areanames{ru}->{3752330} = "Ветка\,\ Гомельская\ область";
$areanames{ru}->{3752332} = "Чечерск\,\ Гомельская\ область";
$areanames{ru}->{3752333} = "Добруш\,\ Гомельская\ область";
$areanames{ru}->{3752334} = "Жлобин";
$areanames{ru}->{3752336} = "Буда\-Кошелево\,\ Гомельская\ область";
$areanames{ru}->{3752337} = "Корма\,\ Гомельская\ область";
$areanames{ru}->{3752339} = "Рогачев";
$areanames{ru}->{3752340} = "Речица";
$areanames{ru}->{3752342} = "Светлогорск";
$areanames{ru}->{3752344} = "Брагин\,\ Гомельская\ область";
$areanames{ru}->{3752345} = "Калинковичи";
$areanames{ru}->{3752346} = "Хойники\,\ Гомельская\ область";
$areanames{ru}->{3752347} = "Лоев\,\ Гомельская\ область";
$areanames{ru}->{3752350} = "Петриков\,\ Гомельская\ область";
$areanames{ru}->{3752353} = "Житковичи\,\ Гомельская\ область";
$areanames{ru}->{3752354} = "Ельск\,\ Гомельская\ область";
$areanames{ru}->{3752355} = "Наровля\,\ Гомельская\ область";
$areanames{ru}->{3752356} = "Лельчицы\,\ Гомельская\ область";
$areanames{ru}->{3752357} = "Октябрьский\,\ Гомельская\ область";
$areanames{ru}->{375236} = "Мозырь";
$areanames{en}->{3751511} = "Vyalikaya\ Byerastavitsa\,\ Grodno\ Region";
$areanames{en}->{3751512} = "Volkovysk";
$areanames{en}->{3751513} = "Svisloch\,\ Grodno\ Region";
$areanames{en}->{3751514} = "Shchuchin\,\ Grodno\ Region";
$areanames{en}->{3751515} = "Mosty\,\ Grodno\ Region";
$areanames{en}->{375152} = "Grodno";
$areanames{en}->{375154} = "Lida";
$areanames{en}->{3751562} = "Slonim";
$areanames{en}->{3751563} = "Dyatlovo\,\ Grodno\ Region";
$areanames{en}->{3751564} = "Zelva\,\ Grodno\ Region";
$areanames{en}->{3751591} = "Ostrovets\,\ Grodno\ Region";
$areanames{en}->{3751592} = "Smorgon";
$areanames{en}->{3751593} = "Oshmyany";
$areanames{en}->{3751594} = "Voronovo\,\ Grodno\ Region";
$areanames{en}->{3751595} = "Ivye\,\ Grodno\ Region";
$areanames{en}->{3751596} = "Korelichi\,\ Grodno\ Region";
$areanames{en}->{3751597} = "Novogrudok";
$areanames{en}->{375162} = "Brest";
$areanames{en}->{375163} = "Baranovichi";
$areanames{en}->{3751631} = "Kamenets\,\ Brest\ Region";
$areanames{en}->{3751632} = "Pruzhany\,\ Brest\ Region";
$areanames{en}->{3751633} = "Lyakhovichi\,\ Brest\ Region";
$areanames{en}->{3751641} = "Zhabinka\,\ Brest\ Region";
$areanames{en}->{3751642} = "Kobryn";
$areanames{en}->{3751643} = "Bereza\,\ Brest\ Region";
$areanames{en}->{3751644} = "Drogichin\,\ Brest\ Region";
$areanames{en}->{3751645} = "Ivatsevichi\,\ Brest\ Region";
$areanames{en}->{3751646} = "Gantsevichi\,\ Brest\ Region";
$areanames{en}->{3751647} = "Luninets\,\ Brest\ Region";
$areanames{en}->{375165} = "Pinsk";
$areanames{en}->{3751651} = "Malorita\,\ Brest\ Region";
$areanames{en}->{3751652} = "Ivanovo\,\ Brest\ Region";
$areanames{en}->{3751655} = "Stolin\,\ Brest\ Region";
$areanames{en}->{37517} = "Minsk";
$areanames{en}->{3751713} = "Maryina\ Gorka\,\ Minsk\ Region";
$areanames{en}->{3751714} = "Cherven";
$areanames{en}->{3751715} = "Berezino\,\ Minsk\ Region";
$areanames{en}->{3751716} = "Dzerzhinsk";
$areanames{en}->{3751717} = "Stolbtsy";
$areanames{en}->{3751718} = "Uzda\,\ Minsk\ Region";
$areanames{en}->{3751719} = "Kopyl\,\ Minsk\ Region";
$areanames{en}->{375174} = "Soligorsk";
$areanames{en}->{375176} = "Molodechno";
$areanames{en}->{375177} = "Borisov";
$areanames{en}->{3751770} = "Nesvizh";
$areanames{en}->{3751771} = "Vileyka";
$areanames{en}->{3751772} = "Volozhin";
$areanames{en}->{3751774} = "Lahoysk";
$areanames{en}->{3751775} = "Zhodino";
$areanames{en}->{3751776} = "Smalyavichy";
$areanames{en}->{3751792} = "Starye\ Dorogi\,\ Minsk\ Region";
$areanames{en}->{3751793} = "Kletsk\,\ Minsk\ Region";
$areanames{en}->{3751794} = "Lyuban\,\ Minsk\ Region";
$areanames{en}->{3751795} = "Slutsk";
$areanames{en}->{3751796} = "Krupki\,\ Minsk\ Region";
$areanames{en}->{3751797} = "Myadel";
$areanames{en}->{375212} = "Vitebsk";
$areanames{en}->{3752130} = "Shumilino\,\ Vitebsk\ Region";
$areanames{en}->{3752131} = "Beshenkovichi\,\ Vitebsk\ Region";
$areanames{en}->{3752132} = "Lepel";
$areanames{en}->{3752133} = "Chashniki\,\ Vitebsk\ Region";
$areanames{en}->{3752135} = "Senno\,\ Vitebsk\ Region";
$areanames{en}->{3752136} = "Tolochin";
$areanames{en}->{3752137} = "Dubrovno\,\ Vitebsk\ Region";
$areanames{en}->{3752138} = "Liozno\,\ Vitebsk\ Region";
$areanames{en}->{3752139} = "Gorodok\,\ Vitebsk\ Region";
$areanames{en}->{375214} = "Polotsk\/Navapolatsk";
$areanames{en}->{3752151} = "Verhnedvinsk\,\ Vitebsk\ Region";
$areanames{en}->{3752152} = "Miory\,\ Vitebsk\ Region";
$areanames{en}->{3752153} = "Braslav";
$areanames{en}->{3752154} = "Sharkovshchina\,\ Vitebsk\ Region";
$areanames{en}->{3752155} = "Postavy";
$areanames{en}->{3752156} = "Glubokoye";
$areanames{en}->{3752157} = "Dokshitsy\,\ Vitebsk\ Region";
$areanames{en}->{3752158} = "Ushachi\,\ Vitebsk\ Region";
$areanames{en}->{3752159} = "Rossony\,\ Vitebsk\ Region";
$areanames{en}->{375216} = "Orsha";
$areanames{en}->{375222} = "Mogilev";
$areanames{en}->{3752230} = "Glusk\,\ Mogilev\ Region";
$areanames{en}->{3752231} = "Byhov\,\ Mogilev\ Region";
$areanames{en}->{3752232} = "Belynichi\,\ Mogilev\ Region";
$areanames{en}->{3752233} = "Gorki\,\ Mogilev\ Region";
$areanames{en}->{3752234} = "Krugloye\,\ Mogilev\ Region";
$areanames{en}->{3752235} = "Osipovichi";
$areanames{en}->{3752236} = "Klichev\,\ Mogilev\ Region";
$areanames{en}->{3752237} = "Kirovsk\,\ Mogilev\ Region";
$areanames{en}->{3752238} = "Krasnopolye\,\ Mogilev\ Region";
$areanames{en}->{3752239} = "Shklov";
$areanames{en}->{3752240} = "Mstislavl";
$areanames{en}->{3752241} = "Krichev\,\ Mogilev\ Region";
$areanames{en}->{3752242} = "Chausy\,\ Mogilev\ Region";
$areanames{en}->{3752243} = "Cherikov\,\ Mogilev\ Region";
$areanames{en}->{3752244} = "Klimovichi\,\ Mogilev\ Region";
$areanames{en}->{3752245} = "Kostyukovichi\,\ Mogilev\ Region";
$areanames{en}->{3752246} = "Slavgorod\,\ Mogilev\ Region";
$areanames{en}->{3752247} = "Khotimsk\,\ Mogilev\ Region";
$areanames{en}->{3752248} = "Dribin\,\ Mogilev\ Region";
$areanames{en}->{375225} = "Babruysk";
$areanames{en}->{375232} = "Gomel";
$areanames{en}->{3752330} = "Vetka\,\ Gomel\ Region";
$areanames{en}->{3752332} = "Chechersk\,\ Gomel\ Region";
$areanames{en}->{3752333} = "Dobrush\,\ Gomel\ Region";
$areanames{en}->{3752334} = "Zhlobin";
$areanames{en}->{3752336} = "Budo\-Koshelevo\,\ Gomel\ Region";
$areanames{en}->{3752337} = "Korma\,\ Gomel\ Region";
$areanames{en}->{3752339} = "Rogachev";
$areanames{en}->{3752340} = "Rechitsa";
$areanames{en}->{3752342} = "Svetlogorsk";
$areanames{en}->{3752344} = "Bragin\,\ Gomel\ Region";
$areanames{en}->{3752345} = "Kalinkovichi";
$areanames{en}->{3752346} = "Khoiniki\,\ Gomel\ Region";
$areanames{en}->{3752347} = "Loyev\,\ Gomel\ Region";
$areanames{en}->{3752350} = "Petrikov\,\ Gomel\ Region";
$areanames{en}->{3752353} = "Zhitkovichi\,\ Gomel\ Region";
$areanames{en}->{3752354} = "Yelsk\,\ Gomel\ Region";
$areanames{en}->{3752355} = "Narovlya\,\ Gomel\ Region";
$areanames{en}->{3752356} = "Lelchitsy\,\ Gomel\ Region";
$areanames{en}->{3752357} = "Oktyabrskiy\,\ Gomel\ Region";
$areanames{en}->{375236} = "Mozyr";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+375|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0|80?)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;