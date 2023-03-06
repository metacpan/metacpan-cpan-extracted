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
package Number::Phone::StubCountry::ZW;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20230305170054;

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
            [178]\\d|
            3[1-9]
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
$areanames{en} = {"26354212", "Chivhu",
"263292804", "Figtree",
"26333", "Triangle",
"26327523", "Mt\.\ Darwin",
"26385", "BeitBridge",
"26355259", "Gokwe",
"263286", "Beitbridge",
"26317", "Filabusi",
"26327541", "Mt\.\ Darwin",
"263248", "Birchenough\ Bridge",
"263292803", "Turkmine",
"263612140", "Chirundu",
"263375", "Concession",
"263329", "Nyanga",
"26366", "Banket",
"26389280", "Plumtree",
"26350", "Shanagani",
"26315", "Binga",
"26324213", "Ruwa",
"263924", "Hillside",
"2632583", "Nyazura",
"263398", "Lupane",
"263292802", "Shangani",
"263227", "Chipinge",
"263929", "Killarney",
"263281", "Hwange",
"2636521", "Murewa",
"263552557", "Munyati",
"263272", "Mutoko",
"263212", "Murambinda",
"26352", "Shurugwi",
"26364", "Karoi",
"263812847", "Binga",
"263262098", "Nyanga",
"26324215", "Norton",
"26327524", "Mt\.\ Darwin",
"263949", "Nkulumane",
"26366212", "Mount\ Darwin",
"263812875", "Jotsholo",
"26324214", "Arcturus",
"26325206", "Murambinda",
"26327525", "Mt\.\ Darwin",
"263420088", "Selous",
"26354", "Gweru",
"26318", "Dete",
"26362", "Norton",
"263514", "Zvishavane",
"26366210", "Bindura\/Centenary",
"263672198", "Raffingora",
"26327529", "Mt\.\ Darwin",
"26313", "Victoria\ Falls",
"263292800", "Esigodini",
"26356", "Chivhu",
"2632020", "Mutare",
"263672192", "Darwendale",
"26335", "Mashava",
"26366216", "Mvurwi",
"263282", "Kezi",
"263228", "Hauna",
"2636821", "Kadoma\/Selous",
"263420108", "Norton",
"263251", "Zvishavane",
"26383", "Victoria\ Falls",
"263842808", "West\ Nicholson",
"263383", "Matopose",
"263271", "Bindura",
"263420085", "Selous",
"263392366", "Mataga",
"26360", "Mhangura",
"26331", "Chiredzi",
"263213", "Victoria\ Falls",
"2639226", "Queensdale",
"263518", "Mberengwa",
"263273", "Ruwa",
"263272046", "Chipangayi",
"26329246", "Bellevue",
"263204", "Odzi",
"26366218", "Glendale",
"2632021", "Dangamvura",
"263292861", "Tsholotsho",
"263558", "Nkayi",
"263940", "Mabutewni",
"26342010", "Selous",
"26327527", "Mt\.\ Darwin",
"263420107", "Norton",
"263948", "Nkulumane",
"26326209", "Hauna",
"26339234", "Jerera",
"263229", "Juliasdale",
"26367214", "Banket\/Mhangura",
"263688", "Chakari",
"26342729", "Marondera",
"26369", "Darwendale",
"26361215", "Karoi",
"26323", "Chiredzi",
"263420087", "Selous",
"26367215", "Murombedzi",
"263292821", "Nyamandlovu",
"2635525", "Battle\ Fields\/Kwekwe\/Redcliff",
"26339235", "Zvishavane",
"263952", "Luveve",
"2635483", "Lalapanzi",
"26325", "Rusape",
"263637", "Chirundu",
"263812835", "Dete",
"263947", "Bellevue",
"263956", "Luveve",
"263371", "Shamva",
"263283", "Figtree",
"2632421", "Chitungwiza",
"2638128", "Baobab\/Hwange",
"263292807", "Kezi",
"26359", "Gokwe",
"263557", "Munyati",
"263517", "Mataga",
"263612141", "Makuti",
"26342723", "Chitungwiza",
"263552558", "Nkayi",
"263264", "Karoi",
"26365213", "Mutoko",
"26354252", "Shurugwi",
"263842801", "Filabusi",
"263308", "Chatsworth",
"263682189", "Chakari",
"263285", "Turkmine",
"263376", "Glendale",
"263242150", "Beatrice",
"263920", "Northend",
"263687", "Sanyati",
"2636523", "Marondera",
"26368215", "Chegutu",
"2632024", "Penhalonga",
"26353", "Chegutu",
"26365", "Beatrice",
"263220201", "Chikanga\/Mutare",
"26316", "West\ Nicholson",
"26320200", "Odzi",
"263242", "Harare",
"26330", "Gutu",
"26361", "Kariba",
"263275219", "Mazowe",
"26367", "Chinhoyi",
"263206", "Mutare",
"263287", "Tsholotsho",
"263943", "Mabutewni",
"26368216", "Sanyati",
"26358", "Guruve",
"263392380", "Nyaningwe",
"26314", "Rutenga",
"2639", "Bulawayo",
"263513", "Zvishavane",
"263278", "Murewa",
"263221", "Murambinda",
"263270", "Chitungwiza",
"26332", "Mvuma",
"26331233", "Triangle",
"263698", "Trelawney",
"2632582", "Headlands",
"263312337", "Rutenga",
"26339230", "Gutu",
"263252055", "Nyazura",
"26368", "Kadoma",
"263379", "Macheke",
"26334", "Jerera",
"26325207", "Headlands",
"263812856", "Lupane",
"26329", "Bulawayo",
"26363", "Makuti",
"263312370", "Ngundu",
"263277", "Mvurwi",
"26327528", "Mt\.\ Darwin",
"26342722", "Chitungwiza",
"263261", "Kariba",
"26355", "Kwekwe",
"26365208", "Wedza",
"26366217", "Guruve",
"263675", "Murombedzi",
"26336", "Ngundu",
"26357", "Centenary",
"263222", "Wedza",
"263288", "Esigodini",
"263672196", "Mutorashanga",
"26327204", "Chipinge",
"263392323", "Nyika",
"263512", "Zvishavane",
"26366219", "Christon\ Bank\/Concession\/Mazowe",
"263942", "Mabutewni",
"26327526", "Mt\.\ Darwin",
"263220202", "Mutare",
"263420106", "Norton",
"26327540", "Mt\.\ Darwin",
"263387", "Nyamandhlovu",
"263420089", "Selous",
"26327205", "Chimanimani",
"263337", "Nyaningwe",
"263420110", "Norton",
"26326208", "Juliasdale",
"263284", "Gwanda",
"263628", "Selous",
"26327522", "Mt\.\ Darwin",
"263289", "Jotsholo",
"263220203", "Dangamvura",
"263420109", "Norton",
"263921", "Northend",
"26342728", "Marondera",
"263392308", "Chatsworth",
"263667", "Raffingora",
"26342009", "Selous",
"2632753", "Mt\.\ Darwin",
"263542532", "Mvuma",
"263420086", "Selous",
"26319", "Plumtree",
"263272317", "Checheche",
"26327203", "Birchenough\ Bridge",
"263205", "Pengalonga",
"263652080", "Macheke",
"26326", "Chimanimani",
"263392360", "Mberengwa",
"26339", "Masvingo",
"2639228", "Queensdale",
"263941", "Mabutewni",
"263317", "Checheche",
"26329252", "Luveve",
"263842835", "Collen\ Bawn",
"263542548", "Lalapanzi",
"263254", "Gweru",
"263279", "Marondera",
"263225", "Rusape",
"263219", "Plumtree",
"263274", "Arcturus",
"2634", "Harare",
"263946", "Bellevue",
"263668", "Mutorashanga",
"263662137", "Shamva",
"263672136", "Trelawney",
"2638428", "Gwanda",
"26339245", "Mashava",
"263338", "Nyika",
"263292809", "Matopos",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+263|\D)//g;
      my $self = bless({ country_code => '263', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '263', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;