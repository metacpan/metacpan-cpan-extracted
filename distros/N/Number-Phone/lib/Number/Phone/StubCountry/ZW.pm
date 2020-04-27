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
package Number::Phone::StubCountry::ZW;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200427120032;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            2(?:
              0[45]|
              2[278]|
              [49]8
            )|
            3(?:
              [09]8|
              17
            )|
            6(?:
              [29]8|
              37|
              75
            )|
            [23][78]|
            (?:
              33|
              5[15]|
              6[68]
            )[78]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3,5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[49]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{2,4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '80',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            2(?:
              02[014]|
              4|
              [56]20|
              [79]2
            )|
            392|
            5(?:
              42|
              525
            )|
            6(?:
              [16-8]21|
              52[013]
            )|
            8[13-59]
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{2})(\\d{7})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '7',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            2(?:
              1[39]|
              2[0157]|
              [378]|
              [56][14]
            )|
            3(?:
              123|
              29
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '8',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{4})(\\d{6})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            1|
            2(?:
              0[0-36-9]|
              12|
              29|
              [56]
            )|
            3(?:
              1[0-689]|
              [24-6]
            )|
            5(?:
              [0236-9]|
              1[2-4]
            )|
            6(?:
              [013-59]|
              7[0-46-9]
            )|
            (?:
              33|
              55|
              6[68]
            )[0-69]|
            (?:
              29|
              3[09]|
              62
            )[0-79]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3,5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            29[013-9]|
            39|
            54
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            258|
            5483
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{4})(\\d{3,5})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            1(?:
              (?:
                3\\d|
                9
              )\\d|
              [4-8]
            )|
            2(?:
              (?:
                (?:
                  0(?:
                    2[014]|
                    5
                  )|
                  (?:
                    2[0157]|
                    31|
                    84|
                    9
                  )\\d\\d|
                  [56](?:
                    [14]\\d\\d|
                    20
                  )|
                  7(?:
                    [089]|
                    2[03]|
                    [35]\\d\\d
                  )
                )\\d|
                4(?:
                  2\\d\\d|
                  8
                )
              )\\d|
              1(?:
                2|
                [39]\\d{4}
              )
            )|
            3(?:
              (?:
                123|
                (?:
                  29\\d|
                  92
                )\\d
              )\\d\\d|
              7(?:
                [19]|
                [56]\\d
              )
            )|
            5(?:
              0|
              1[2-478]|
              26|
              [37]2|
              4(?:
                2\\d{3}|
                83
              )|
              5(?:
                25\\d\\d|
                [78]
              )|
              [689]\\d
            )|
            6(?:
              (?:
                [16-8]21|
                28|
                52[013]
              )\\d\\d|
              [39]
            )|
            8(?:
              [1349]28|
              523
            )\\d\\d
          )\\d{3}|
          (?:
            4\\d\\d|
            9[2-9]
          )\\d{4,5}|
          (?:
            (?:
              2(?:
                (?:
                  (?:
                    0|
                    8[146]
                  )\\d|
                  7[1-7]
                )\\d|
                2(?:
                  [278]\\d|
                  92
                )|
                58(?:
                  2\\d|
                  3
                )
              )|
              3(?:
                [26]|
                9\\d{3}
              )|
              5(?:
                4\\d|
                5
              )\\d\\d
            )\\d|
            6(?:
              (?:
                (?:
                  [0-246]|
                  [78]\\d
                )\\d|
                37
              )\\d|
              5[2-8]
            )
          )\\d\\d|
          (?:
            2(?:
              [569]\\d|
              8[2-57-9]
            )|
            3(?:
              [013-59]\\d|
              8[37]
            )|
            6[89]8
          )\\d{3}
        ',
                'geographic' => '
          (?:
            1(?:
              (?:
                3\\d|
                9
              )\\d|
              [4-8]
            )|
            2(?:
              (?:
                (?:
                  0(?:
                    2[014]|
                    5
                  )|
                  (?:
                    2[0157]|
                    31|
                    84|
                    9
                  )\\d\\d|
                  [56](?:
                    [14]\\d\\d|
                    20
                  )|
                  7(?:
                    [089]|
                    2[03]|
                    [35]\\d\\d
                  )
                )\\d|
                4(?:
                  2\\d\\d|
                  8
                )
              )\\d|
              1(?:
                2|
                [39]\\d{4}
              )
            )|
            3(?:
              (?:
                123|
                (?:
                  29\\d|
                  92
                )\\d
              )\\d\\d|
              7(?:
                [19]|
                [56]\\d
              )
            )|
            5(?:
              0|
              1[2-478]|
              26|
              [37]2|
              4(?:
                2\\d{3}|
                83
              )|
              5(?:
                25\\d\\d|
                [78]
              )|
              [689]\\d
            )|
            6(?:
              (?:
                [16-8]21|
                28|
                52[013]
              )\\d\\d|
              [39]
            )|
            8(?:
              [1349]28|
              523
            )\\d\\d
          )\\d{3}|
          (?:
            4\\d\\d|
            9[2-9]
          )\\d{4,5}|
          (?:
            (?:
              2(?:
                (?:
                  (?:
                    0|
                    8[146]
                  )\\d|
                  7[1-7]
                )\\d|
                2(?:
                  [278]\\d|
                  92
                )|
                58(?:
                  2\\d|
                  3
                )
              )|
              3(?:
                [26]|
                9\\d{3}
              )|
              5(?:
                4\\d|
                5
              )\\d\\d
            )\\d|
            6(?:
              (?:
                (?:
                  [0-246]|
                  [78]\\d
                )\\d|
                37
              )\\d|
              5[2-8]
            )
          )\\d\\d|
          (?:
            2(?:
              [569]\\d|
              8[2-57-9]
            )|
            3(?:
              [013-59]\\d|
              8[37]
            )|
            6[89]8
          )\\d{3}
        ',
                'mobile' => '
          7(?:
            [17]\\d|
            [38][1-9]
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '
          80(?:
            [01]\\d|
            20|
            8[0-8]
          )\\d{3}
        ',
                'voip' => '
          86(?:
            1[12]|
            22|
            30|
            44|
            55|
            77|
            8[368]
          )\\d{6}
        '
              };
my %areanames = ();
$areanames{en}->{26313} = "Victoria\ Falls";
$areanames{en}->{26314} = "Rutenga";
$areanames{en}->{26315} = "Binga";
$areanames{en}->{26316} = "West\ Nicholson";
$areanames{en}->{26317} = "Filabusi";
$areanames{en}->{26318} = "Dete";
$areanames{en}->{26319} = "Plumtree";
$areanames{en}->{2632020} = "Mutare";
$areanames{en}->{26320200} = "Odzi";
$areanames{en}->{2632021} = "Dangamvura";
$areanames{en}->{2632024} = "Penhalonga";
$areanames{en}->{263204} = "Odzi";
$areanames{en}->{263205} = "Pengalonga";
$areanames{en}->{263206} = "Mutare";
$areanames{en}->{263212} = "Murambinda";
$areanames{en}->{263213} = "Victoria\ Falls";
$areanames{en}->{263219} = "Plumtree";
$areanames{en}->{263220201} = "Chikanga\/Mutare";
$areanames{en}->{263220202} = "Mutare";
$areanames{en}->{263220203} = "Dangamvura";
$areanames{en}->{263221} = "Murambinda";
$areanames{en}->{263222} = "Wedza";
$areanames{en}->{263225} = "Rusape";
$areanames{en}->{263227} = "Chipinge";
$areanames{en}->{263228} = "Hauna";
$areanames{en}->{263229} = "Juliasdale";
$areanames{en}->{26323} = "Chiredzi";
$areanames{en}->{263242} = "Harare";
$areanames{en}->{2632421} = "Chitungwiza";
$areanames{en}->{26324213} = "Ruwa";
$areanames{en}->{26324214} = "Arcturus";
$areanames{en}->{26324215} = "Norton";
$areanames{en}->{263242150} = "Beatrice";
$areanames{en}->{263248} = "Birchenough\ Bridge";
$areanames{en}->{26325} = "Rusape";
$areanames{en}->{263251} = "Zvishavane";
$areanames{en}->{263252055} = "Nyazura";
$areanames{en}->{26325206} = "Murambinda";
$areanames{en}->{26325207} = "Headlands";
$areanames{en}->{263254} = "Gweru";
$areanames{en}->{2632582} = "Headlands";
$areanames{en}->{2632583} = "Nyazura";
$areanames{en}->{26326} = "Chimanimani";
$areanames{en}->{263261} = "Kariba";
$areanames{en}->{26326208} = "Juliasdale";
$areanames{en}->{26326209} = "Hauna";
$areanames{en}->{263262098} = "Nyanga";
$areanames{en}->{263264} = "Karoi";
$areanames{en}->{263270} = "Chitungwiza";
$areanames{en}->{263271} = "Bindura";
$areanames{en}->{263272} = "Mutoko";
$areanames{en}->{26327203} = "Birchenough\ Bridge";
$areanames{en}->{26327204} = "Chipinge";
$areanames{en}->{263272046} = "Chipangayi";
$areanames{en}->{26327205} = "Chimanimani";
$areanames{en}->{263272317} = "Checheche";
$areanames{en}->{263273} = "Ruwa";
$areanames{en}->{263274} = "Arcturus";
$areanames{en}->{263275219} = "Mazowe";
$areanames{en}->{26327522} = "Mt\.\ Darwin";
$areanames{en}->{26327523} = "Mt\.\ Darwin";
$areanames{en}->{26327524} = "Mt\.\ Darwin";
$areanames{en}->{26327525} = "Mt\.\ Darwin";
$areanames{en}->{26327526} = "Mt\.\ Darwin";
$areanames{en}->{26327527} = "Mt\.\ Darwin";
$areanames{en}->{26327528} = "Mt\.\ Darwin";
$areanames{en}->{26327529} = "Mt\.\ Darwin";
$areanames{en}->{2632753} = "Mt\.\ Darwin";
$areanames{en}->{26327540} = "Mt\.\ Darwin";
$areanames{en}->{26327541} = "Mt\.\ Darwin";
$areanames{en}->{263277} = "Mvurwi";
$areanames{en}->{263278} = "Murewa";
$areanames{en}->{263279} = "Marondera";
$areanames{en}->{263281} = "Hwange";
$areanames{en}->{263282} = "Kezi";
$areanames{en}->{263283} = "Figtree";
$areanames{en}->{263284} = "Gwanda";
$areanames{en}->{263285} = "Turkmine";
$areanames{en}->{263286} = "Beitbridge";
$areanames{en}->{263287} = "Tsholotsho";
$areanames{en}->{263288} = "Esigodini";
$areanames{en}->{263289} = "Jotsholo";
$areanames{en}->{26329} = "Bulawayo";
$areanames{en}->{26329246} = "Bellevue";
$areanames{en}->{26329252} = "Luveve";
$areanames{en}->{263292800} = "Esigodini";
$areanames{en}->{263292802} = "Shangani";
$areanames{en}->{263292803} = "Turkmine";
$areanames{en}->{263292804} = "Figtree";
$areanames{en}->{263292807} = "Kezi";
$areanames{en}->{263292809} = "Matopos";
$areanames{en}->{263292821} = "Nyamandlovu";
$areanames{en}->{263292861} = "Tsholotsho";
$areanames{en}->{26330} = "Gutu";
$areanames{en}->{263308} = "Chatsworth";
$areanames{en}->{26331} = "Chiredzi";
$areanames{en}->{26331233} = "Triangle";
$areanames{en}->{263312337} = "Rutenga";
$areanames{en}->{263312370} = "Ngundu";
$areanames{en}->{263317} = "Checheche";
$areanames{en}->{26332} = "Mvuma";
$areanames{en}->{263329} = "Nyanga";
$areanames{en}->{26333} = "Triangle";
$areanames{en}->{263337} = "Nyaningwe";
$areanames{en}->{263338} = "Nyika";
$areanames{en}->{26334} = "Jerera";
$areanames{en}->{26335} = "Mashava";
$areanames{en}->{26336} = "Ngundu";
$areanames{en}->{263371} = "Shamva";
$areanames{en}->{263375} = "Concession";
$areanames{en}->{263376} = "Glendale";
$areanames{en}->{263379} = "Macheke";
$areanames{en}->{263383} = "Matopose";
$areanames{en}->{263387} = "Nyamandhlovu";
$areanames{en}->{26339} = "Masvingo";
$areanames{en}->{26339230} = "Gutu";
$areanames{en}->{263392308} = "Chatsworth";
$areanames{en}->{263392323} = "Nyika";
$areanames{en}->{26339234} = "Jerera";
$areanames{en}->{26339235} = "Zvishavane";
$areanames{en}->{263392360} = "Mberengwa";
$areanames{en}->{263392366} = "Mataga";
$areanames{en}->{263392380} = "Nyaningwe";
$areanames{en}->{26339245} = "Mashava";
$areanames{en}->{263398} = "Lupane";
$areanames{en}->{2634} = "Harare";
$areanames{en}->{263420085} = "Selous";
$areanames{en}->{263420086} = "Selous";
$areanames{en}->{263420087} = "Selous";
$areanames{en}->{263420088} = "Selous";
$areanames{en}->{263420089} = "Selous";
$areanames{en}->{26342009} = "Selous";
$areanames{en}->{26342010} = "Selous";
$areanames{en}->{263420106} = "Norton";
$areanames{en}->{263420107} = "Norton";
$areanames{en}->{263420108} = "Norton";
$areanames{en}->{263420109} = "Norton";
$areanames{en}->{263420110} = "Norton";
$areanames{en}->{26342722} = "Chitungwiza";
$areanames{en}->{26342723} = "Chitungwiza";
$areanames{en}->{26342728} = "Marondera";
$areanames{en}->{26342729} = "Marondera";
$areanames{en}->{26350} = "Shanagani";
$areanames{en}->{263512} = "Zvishavane";
$areanames{en}->{263513} = "Zvishavane";
$areanames{en}->{263514} = "Zvishavane";
$areanames{en}->{263517} = "Mataga";
$areanames{en}->{263518} = "Mberengwa";
$areanames{en}->{26352} = "Shurugwi";
$areanames{en}->{26353} = "Chegutu";
$areanames{en}->{26354} = "Gweru";
$areanames{en}->{26354212} = "Chivhu";
$areanames{en}->{26354252} = "Shurugwi";
$areanames{en}->{263542532} = "Mvuma";
$areanames{en}->{263542548} = "Lalapanzi";
$areanames{en}->{2635483} = "Lalapanzi";
$areanames{en}->{26355} = "Kwekwe";
$areanames{en}->{2635525} = "Battle\ Fields\/Kwekwe\/Redcliff";
$areanames{en}->{263552557} = "Munyati";
$areanames{en}->{263552558} = "Nkayi";
$areanames{en}->{26355259} = "Gokwe";
$areanames{en}->{263557} = "Munyati";
$areanames{en}->{263558} = "Nkayi";
$areanames{en}->{26356} = "Chivhu";
$areanames{en}->{26357} = "Centenary";
$areanames{en}->{26358} = "Guruve";
$areanames{en}->{26359} = "Gokwe";
$areanames{en}->{26360} = "Mhangura";
$areanames{en}->{26361} = "Kariba";
$areanames{en}->{263612140} = "Chirundu";
$areanames{en}->{263612141} = "Makuti";
$areanames{en}->{26361215} = "Karoi";
$areanames{en}->{26362} = "Norton";
$areanames{en}->{263628} = "Selous";
$areanames{en}->{26363} = "Makuti";
$areanames{en}->{263637} = "Chirundu";
$areanames{en}->{26364} = "Karoi";
$areanames{en}->{26365} = "Beatrice";
$areanames{en}->{26365208} = "Wedza";
$areanames{en}->{263652080} = "Macheke";
$areanames{en}->{2636521} = "Murewa";
$areanames{en}->{26365213} = "Mutoko";
$areanames{en}->{2636523} = "Marondera";
$areanames{en}->{26366} = "Banket";
$areanames{en}->{26366210} = "Bindura\/Centenary";
$areanames{en}->{26366212} = "Mount\ Darwin";
$areanames{en}->{263662137} = "Shamva";
$areanames{en}->{26366216} = "Mvurwi";
$areanames{en}->{26366217} = "Guruve";
$areanames{en}->{26366218} = "Glendale";
$areanames{en}->{26366219} = "Christon\ Bank\/Concession\/Mazowe";
$areanames{en}->{263667} = "Raffingora";
$areanames{en}->{263668} = "Mutorashanga";
$areanames{en}->{26367} = "Chinhoyi";
$areanames{en}->{263672136} = "Trelawney";
$areanames{en}->{26367214} = "Banket\/Mhangura";
$areanames{en}->{26367215} = "Murombedzi";
$areanames{en}->{263672192} = "Darwendale";
$areanames{en}->{263672196} = "Mutorashanga";
$areanames{en}->{263672198} = "Raffingora";
$areanames{en}->{263675} = "Murombedzi";
$areanames{en}->{26368} = "Kadoma";
$areanames{en}->{2636821} = "Kadoma\/Selous";
$areanames{en}->{26368215} = "Chegutu";
$areanames{en}->{26368216} = "Sanyati";
$areanames{en}->{263682189} = "Chakari";
$areanames{en}->{263687} = "Sanyati";
$areanames{en}->{263688} = "Chakari";
$areanames{en}->{26369} = "Darwendale";
$areanames{en}->{263698} = "Trelawney";
$areanames{en}->{2638128} = "Baobab\/Hwange";
$areanames{en}->{263812835} = "Dete";
$areanames{en}->{263812847} = "Binga";
$areanames{en}->{263812856} = "Lupane";
$areanames{en}->{263812875} = "Jotsholo";
$areanames{en}->{26383} = "Victoria\ Falls";
$areanames{en}->{2638428} = "Gwanda";
$areanames{en}->{263842801} = "Filabusi";
$areanames{en}->{263842808} = "West\ Nicholson";
$areanames{en}->{263842835} = "Collen\ Bawn";
$areanames{en}->{26385} = "BeitBridge";
$areanames{en}->{26389280} = "Plumtree";
$areanames{en}->{2639} = "Bulawayo";
$areanames{en}->{263920} = "Northend";
$areanames{en}->{263921} = "Northend";
$areanames{en}->{2639226} = "Queensdale";
$areanames{en}->{2639228} = "Queensdale";
$areanames{en}->{263924} = "Hillside";
$areanames{en}->{263929} = "Killarney";
$areanames{en}->{263940} = "Mabutewni";
$areanames{en}->{263941} = "Mabutewni";
$areanames{en}->{263942} = "Mabutewni";
$areanames{en}->{263943} = "Mabutewni";
$areanames{en}->{263946} = "Bellevue";
$areanames{en}->{263947} = "Bellevue";
$areanames{en}->{263948} = "Nkulumane";
$areanames{en}->{263949} = "Nkulumane";
$areanames{en}->{263952} = "Luveve";
$areanames{en}->{263956} = "Luveve";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+263|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;