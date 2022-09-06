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
our $VERSION = 1.20220903144944;

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
$areanames{en} = {"26327541", "Mt\.\ Darwin",
"263420089", "Selous",
"26327524", "Mt\.\ Darwin",
"263842835", "Collen\ Bawn",
"263375", "Concession",
"2632582", "Headlands",
"26334", "Jerera",
"263272046", "Chipangayi",
"26335", "Mashava",
"26327203", "Birchenough\ Bridge",
"26366219", "Christon\ Bank\/Concession\/Mazowe",
"263275219", "Mazowe",
"26354212", "Chivhu",
"263242150", "Beatrice",
"26325", "Rusape",
"263842801", "Filabusi",
"263956", "Luveve",
"2634", "Harare",
"263946", "Bellevue",
"26330", "Gutu",
"263206", "Mutare",
"26355", "Kwekwe",
"2638428", "Gwanda",
"263292807", "Kezi",
"263392308", "Chatsworth",
"26354", "Gweru",
"263220201", "Chikanga\/Mutare",
"263672192", "Darwendale",
"263688", "Chakari",
"26350", "Shanagani",
"263220203", "Dangamvura",
"263398", "Lupane",
"263628", "Selous",
"26339235", "Zvishavane",
"263278", "Murewa",
"26325207", "Headlands",
"26363", "Makuti",
"26324213", "Ruwa",
"263512", "Zvishavane",
"263282", "Kezi",
"263273", "Ruwa",
"263229", "Juliasdale",
"263289", "Jotsholo",
"263292802", "Shangani",
"26342010", "Selous",
"26367215", "Murombedzi",
"263272317", "Checheche",
"263329", "Nyanga",
"26320200", "Odzi",
"263929", "Killarney",
"263222", "Wedza",
"263612140", "Chirundu",
"26318", "Dete",
"263687", "Sanyati",
"2639228", "Queensdale",
"263219", "Plumtree",
"263392360", "Mberengwa",
"263251", "Zvishavane",
"26342729", "Marondera",
"263420107", "Norton",
"263842808", "West\ Nicholson",
"263277", "Mvurwi",
"263212", "Murambinda",
"263941", "Mabutewni",
"263262098", "Nyanga",
"263392323", "Nyika",
"26329246", "Bellevue",
"26329", "Bulawayo",
"263558", "Nkayi",
"263205", "Pengalonga",
"263682189", "Chakari",
"26368", "Kadoma",
"263392380", "Nyaningwe",
"26362", "Norton",
"26339", "Masvingo",
"263514", "Zvishavane",
"263284", "Gwanda",
"263261", "Kariba",
"263420087", "Selous",
"263924", "Hillside",
"263376", "Glendale",
"2636521", "Murewa",
"263392366", "Mataga",
"26357", "Centenary",
"263948", "Nkulumane",
"26361", "Kariba",
"263672136", "Trelawney",
"263308", "Chatsworth",
"263292809", "Matopos",
"26367214", "Banket\/Mhangura",
"263920", "Northend",
"26355259", "Gokwe",
"263552557", "Munyati",
"263248", "Birchenough\ Bridge",
"26359", "Gokwe",
"263557", "Munyati",
"263312337", "Rutenga",
"263612141", "Makuti",
"263812856", "Lupane",
"26327529", "Mt\.\ Darwin",
"2635525", "Battle\ Fields\/Kwekwe\/Redcliff",
"263943", "Mabutewni",
"26368216", "Sanyati",
"26313", "Victoria\ Falls",
"26356", "Chivhu",
"26339234", "Jerera",
"263637", "Chirundu",
"263652080", "Macheke",
"26326", "Chimanimani",
"26327525", "Mt\.\ Darwin",
"26326208", "Juliasdale",
"263271", "Bindura",
"26331233", "Triangle",
"263252055", "Nyazura",
"263947", "Bellevue",
"263420109", "Norton",
"26383", "Victoria\ Falls",
"26325206", "Murambinda",
"263420110", "Norton",
"26336", "Ngundu",
"263371", "Shamva",
"263272", "Mutoko",
"263379", "Macheke",
"263513", "Zvishavane",
"263283", "Figtree",
"263420106", "Norton",
"26366218", "Glendale",
"263279", "Marondera",
"263383", "Matopose",
"263292803", "Turkmine",
"263668", "Mutorashanga",
"263317", "Checheche",
"263672198", "Raffingora",
"263542548", "Lalapanzi",
"26368215", "Chegutu",
"263292804", "Figtree",
"26361215", "Karoi",
"263672196", "Mutorashanga",
"263227", "Chipinge",
"26366217", "Guruve",
"26317", "Filabusi",
"26327526", "Mt\.\ Darwin",
"263387", "Nyamandhlovu",
"26327540", "Mt\.\ Darwin",
"263420108", "Norton",
"26354252", "Shurugwi",
"263517", "Mataga",
"263287", "Tsholotsho",
"26319", "Plumtree",
"263213", "Victoria\ Falls",
"263675", "Murombedzi",
"26365208", "Wedza",
"26327522", "Mt\.\ Darwin",
"263204", "Odzi",
"26365", "Beatrice",
"26364", "Karoi",
"26339230", "Gutu",
"263812875", "Jotsholo",
"263225", "Rusape",
"263285", "Turkmine",
"263812847", "Binga",
"26353", "Chegutu",
"26366210", "Bindura\/Centenary",
"26327523", "Mt\.\ Darwin",
"263254", "Gweru",
"263667", "Raffingora",
"26360", "Mhangura",
"2636821", "Kadoma\/Selous",
"26316", "West\ Nicholson",
"26327204", "Chipinge",
"26339245", "Mashava",
"263420085", "Selous",
"263940", "Mabutewni",
"2632753", "Mt\.\ Darwin",
"263228", "Hauna",
"2632020", "Mutare",
"26324214", "Arcturus",
"26365213", "Mutoko",
"26323", "Chiredzi",
"263698", "Trelawney",
"26342728", "Marondera",
"263220202", "Mutare",
"263542532", "Mvuma",
"26333", "Triangle",
"263518", "Mberengwa",
"263288", "Esigodini",
"26366212", "Mount\ Darwin",
"2632024", "Penhalonga",
"263242", "Harare",
"263949", "Nkulumane",
"2639", "Bulawayo",
"26389280", "Plumtree",
"26324215", "Norton",
"26329252", "Luveve",
"263292800", "Esigodini",
"263952", "Luveve",
"263942", "Mabutewni",
"26385", "BeitBridge",
"263337", "Nyaningwe",
"26315", "Binga",
"2636523", "Marondera",
"26314", "Rutenga",
"263921", "Northend",
"263281", "Hwange",
"263264", "Karoi",
"26366", "Banket",
"26342009", "Selous",
"263221", "Murambinda",
"263662137", "Shamva",
"263292861", "Tsholotsho",
"26327205", "Chimanimani",
"263312370", "Ngundu",
"263286", "Beitbridge",
"2632583", "Nyazura",
"26327528", "Mt\.\ Darwin",
"26367", "Chinhoyi",
"2632421", "Chitungwiza",
"263274", "Arcturus",
"263292821", "Nyamandlovu",
"26369", "Darwendale",
"26332", "Mvuma",
"263338", "Nyika",
"2632021", "Dangamvura",
"2638128", "Baobab\/Hwange",
"263420088", "Selous",
"263420086", "Selous",
"26327527", "Mt\.\ Darwin",
"26358", "Guruve",
"26326209", "Hauna",
"26342723", "Chitungwiza",
"26366216", "Mvurwi",
"2639226", "Queensdale",
"2635483", "Lalapanzi",
"26331", "Chiredzi",
"263270", "Chitungwiza",
"263812835", "Dete",
"263552558", "Nkayi",
"26352", "Shurugwi",
"26342722", "Chitungwiza",};

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