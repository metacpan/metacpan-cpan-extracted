# automatically generated file, don't edit



# Copyright 2024 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::IE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20240910191015;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            2[24-9]|
            47|
            58|
            6[237-9]|
            9[35-9]
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{2})(\\d{5})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[45]0',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{3})(\\d{5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '1',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d)(\\d{3,4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [2569]|
            4[1-69]|
            7[14]
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '70',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '81',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[78]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '1',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '4',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '8',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d)(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            1\\d|
            21
          )\\d{6,7}|
          (?:
            2[24-9]|
            4(?:
              0[24]|
              5\\d|
              7
            )|
            5(?:
              0[45]|
              1\\d|
              8
            )|
            6(?:
              1\\d|
              [237-9]
            )|
            9(?:
              1\\d|
              [35-9]
            )
          )\\d{5}|
          (?:
            23|
            4(?:
              [1-469]|
              8\\d
            )|
            5[23679]|
            6[4-6]|
            7[14]|
            9[04]
          )\\d{7}
        ',
                'geographic' => '
          (?:
            1\\d|
            21
          )\\d{6,7}|
          (?:
            2[24-9]|
            4(?:
              0[24]|
              5\\d|
              7
            )|
            5(?:
              0[45]|
              1\\d|
              8
            )|
            6(?:
              1\\d|
              [237-9]
            )|
            9(?:
              1\\d|
              [35-9]
            )
          )\\d{5}|
          (?:
            23|
            4(?:
              [1-469]|
              8\\d
            )|
            5[23679]|
            6[4-6]|
            7[14]|
            9[04]
          )\\d{7}
        ',
                'mobile' => '
          8(?:
            22|
            [35-9]\\d
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '700\\d{6}',
                'specialrate' => '(18[59]0\\d{6})|(
          15(?:
            1[2-8]|
            [2-8]0|
            9[089]
          )\\d{6}
        )|(818\\d{6})',
                'toll_free' => '1800\\d{6}',
                'voip' => '76\\d{7}'
              };
my %areanames = ();
$areanames{en} = {"35366", "Tralee",
"35395", "Clifden",
"3535261", "Clonmel",
"353719344", "Sligo",
"353498", "Oldcastle",
"3534368", "Granard",
"353658", "Kilrush",
"35351999", "Waterford\/Carrick\-on\-Suir\/New\ Ross\/Kilmacthomas",
"35368", "Listowel",
"3534693", "Kells",
"3534294", "Dundalk",
"353470", "Monaghan\/Clones",
"353476", "Monaghan",
"353420", "Dundalk\/Carrickmacross\/Castleblaney",
"353624", "Tipperary",
"353949288", "Castlebar",
"353629", "Cashel",
"353426", "Dundalk",
"35344", "Mullingar",
"3534510", "Kildare",
"3539495", "Ballinrobe",
"353909902", "Ballinasloe",
"3539096", "Ballinasloe",
"353531202", "Enniscorthy",
"353749888", "Letterkenny",
"353719900", "Sligo",
"3537497", "Donegal",
"3534292", "Dundalk",
"353514", "New\ Ross",
"353461", "Navan",
"353425", "Castleblaney",
"35393", "Tuam",
"353719330", "Sligo",
"353475", "Clones",
"353531203", "Gorey",
"35353", "Wexford\/Enniscorthy\/Ferns\/Gorey",
"353909903", "Ballinasloe",
"353453", "The\ Curragh",
"35329", "Kanturk",
"3537491", "Letterkenny",
"353468", "Navan",
"3534290", "Dundalk",
"3536695", "Cahirciveen",
"35343666", "Granard",
"353539900", "Wexford",
"35369", "Newcastle\ West",
"3532140", "Kinsale",
"353949285", "Castlebar",
"35343667", "Granard",
"353622", "Cashel",
"3534331", "Longford",
"353443", "Mullingar\/Castlepollard\/Tyrrellspass",
"353949289", "Castlebar",
"35343668", "Granard",
"353570", "Portlaoise",
"35371", "Sligo\/Manorhamilton\/Carrick\-on\-Shannon",
"353900", "Athlone",
"3534495", "Castlepollard",
"353949291", "Castlebar",
"353477", "Monaghan",
"353749889", "Letterkenny",
"353512", "Kilmacthomas",
"353217", "Coachford",
"35394", "Castlebar\/Claremorris\/Castlerea\/Ballinrobe",
"3534296", "Carrickmacross",
"353912", "Gort",
"353749212", "Letterkenny",
"353616", "Scariff",
"353427", "Dundalk",
"3534698", "Edenderry",
"35328", "Skibbereen",
"353491", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"3535987", "Athy",
"3534799", "Monaghan\/Clones",
"353561", "Kilkenny",
"353651", "Ennis\/Ennistymon\/Kilrush",
"35326", "Macroom",
"35343", "Longford\/Granard",
"353505", "Roscrea",
"3534299", "Dundalk\/Carrickmacross\/Castleblaney",
"35359", "Carlow\/Muine\ Bheag\/Athy\/Baltinglass",
"35323", "Bandon",
"3535291", "Killenaule",
"353458", "Naas",
"353749214", "Letterkenny",
"3535791", "Birr",
"3534199", "Drogheda\/Ardee",
"3536693", "Dingle",
"353531", "Wexford",
"35399", "Kilronan",
"353646700", "Killarney",
"35357859", "Portlaoise",
"353404", "Wicklow",
"353474", "Clones",
"353479", "Monaghan",
"353620", "Tipperary\/Cashel",
"353424", "Carrickmacross",
"3539498", "Castlerea",
"353740", "Letterkenny",
"353626", "Cashel",
"3535989", "Athy",
"35364", "Killarney\/Rathmore",
"353909897", "Athlone",
"353916", "Gort",
"3537198", "Manorhamilton",
"3532147", "Kinsale",
"35390650", "Athlone",
"3539066", "Roscommon",
"3534297", "Castleblaney",
"353516", "Carrick\-on\-Suir",
"35325", "Fermoy",
"353625", "Tipperary",
"3535393", "Ferns",
"353493", "Belturbet",
"3535986", "Athy",
"353749211", "Letterkenny",
"3535274", "Cahir",
"353438", "Granard",
"3534332", "Longford",
"353569900", "Kilkenny",
"353653", "Ennis",
"35398", "Westport",
"3534695", "Enfield",
"353669100", "Killorglin",
"353668", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353719010", "Sligo",
"35356", "Kilkenny\/Castlecomer\/Freshford",
"3535678", "Kilkenny",
"3534291", "Dundalk",
"353719335", "Sligo",
"35396", "Ballina",
"3532141", "Kinsale",
"35358", "Dungarvan",
"35361999", "Limerick\/Scariff",
"3534791", "Monaghan\/Clones",
"3539064", "Athlone",
"3534330", "Longford",
"353422", "Dundalk",
"3534498", "Castlepollard",
"353504", "Thurles",
"35371959", "Carrick\-on\-Shannon",
"35324", "Youghal",
"353402", "Arklow",
"353472", "Clones",
"353448", "Tyrellspass",
"353711", "Sligo",
"3539493", "Claremorris",
"3539097", "Portumna",
"353627", "Cashel",
"353416", "Ardee",
"353619", "Scariff",
"3536698", "Killorglin",
"353579901", "Portlaoise",
"353463", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"353451", "Naas\/Kildare\/Curragh",
"353469900", "Navan",
"35363", "Rathluirc",
"353909901", "Athlone",
"3534120", "Drogheda\/Ardee",
"3536299", "Tipperary",
"35390", "Athlone\/Ballinasloe\/Portumna\/Roscommon",
"35397", "Belmullet",
"3536690", "Killorglin",
"353539903", "Gorey",
"3534295", "Carrickmacross",
"353628", "Tipperary",
"35352", "Clonmel\/Cahir\/Killenaule",
"3534691", "Navan",
"3535991", "Carlow",
"353646701", "Killarney",
"3536466", "Killarney",
"3534496", "Castlepollard",
"353710", "Sligo",
"35357", "Portlaoise\/Abbeyleix\/Tullamore\/Birr",
"353447", "Castlepollard",
"35343669", "Granard",
"353450", "Naas\/Kildare\/Curragh",
"353654", "Ennis",
"353462", "Kells",
"353949287", "Castlebar",
"3534367", "Granard",
"353539902", "Enniscorthy",
"353456", "Naas",
"353659", "Kilrush",
"353499", "Belturbet",
"3534499", "Mullingar\/Castlepollard\/Tyrrellspass",
"353494", "Cavan",
"3534490", "Tyrellspass",
"3536696", "Cahirciveen",
"3535688", "Freshford",
"35361", "Limerick",
"353423", "Dundalk\/Carrickmacross\/Castleblaney",
"35357850", "Portlaoise",
"353569901", "Kilkenny",
"353918", "Loughrea",
"353455", "Kildare",
"3535786", "Portlaoise",
"3535390", "Wexford",
"353749210", "Letterkenny",
"3536699", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353473", "Monaghan",
"3539496", "Castlerea",
"35321", "Cork",
"353469907", "Edenderry",
"3537493", "Buncrana",
"3536694", "Cahirciveen",
"3534492", "Tyrellspass",
"3535964", "Baltinglass",
"3535392", "Enniscorthy",
"353437", "Granard",
"353492", "Cootehill",
"353652", "Ennis",
"353464", "Trim",
"3534333", "Longford",
"353457", "Naas",
"353530", "Wexford",
"3535997", "Muine\ Bheag",
"3539490", "Castlebar",
"3534697", "Edenderry",
"353719332", "Sligo",
"35371931", "Sligo",
"3536692", "Dingle",
"3535988", "Athy",
"353621", "Tipperary\/Cashel",
"3535394", "Gorey",
"353741", "Letterkenny",
"353579900", "Portlaoise",
"35394925", "Castlebar",
"353909900", "Athlone",
"3537196", "Carrick\-on\-Shannon",
"353469901", "Navan",
"353428", "Dundalk",
"3535793", "Tullamore",
"3534690", "Navan",
"3536691", "Dingle",
"3537495", "Dungloe",
"353218", "Cork\/Kinsale\/Coachford",
"353478", "Monaghan",
"35374960", "Letterkenny",
"353719334", "Sligo",
"3535644", "Castlecomer",
"353650", "Ennis\/Ennistymon\/Kilrush",
"353454", "The\ Curragh",
"353459", "Naas",
"353656", "Ennis",
"353496", "Cavan",
"353490", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"353560", "Kilkenny",
"3534491", "Tyrellspass",
"3534696", "Enfield",
"353467", "Navan",
"35341", "Drogheda",
"3534298", "Castleblaney",
"353901", "Athlone",
"35327", "Bantry",
"353623", "Tipperary",
"353495", "Cootehill",
"3535391", "Wexford",
"3536477", "Rathmore",
"353655", "Ennis",
"35322", "Mallow",
"353749900", "Letterkenny",
"35371930", "Sligo",
"353719331", "Sligo",
"353571", "Portlaoise",
"3534699", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"353539901", "Wexford",
"353578510", "Portlaoise",
"3534369", "Granard",
"35374", "Letterkenny\/Donegal\/Dungloe\/Buncrana",
"3534497", "Castlepollard",
"35367", "Nenagh",
"35374920", "Letterkenny",
"3534694", "Trim",
"3534293", "Dundalk",
"3537191", "Sligo",
"353719401", "Sligo",
"353460", "Navan",
"353452", "Kildare",
"3535677", "Kilkenny",
"353466", "Edenderry",
"353949286", "Castlebar",
"353949290", "Castlebar",
"353657", "Ennistymon",
"353497", "Cavan",
"3536697", "Killorglin",
"353432", "Longford",
"35371932", "Sligo",
"3534692", "Kells",
"3536670", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353421", "Dundalk\/Carrickmacross\/Castleblaney",
"3531", "Dublin",
"353465", "Enfield",
"35374989", "Letterkenny",
"35351", "Waterford",
"3536599", "Ennis\/Ennistymon\/Kilrush",
"35391", "Galway",
"3535787", "Abbeyleix",
"353471", "Monaghan\/Clones",
"3534999", "Cavan\/Cootehill\/Oldcastle\/Belturbet",};
my $timezones = {
               '' => [
                       'Europe/Guernsey',
                       'Europe/Isle_of_Man',
                       'Europe/London'
                     ],
               '539253' => [
                             'Europe/Guernsey',
                             'Europe/Isle_of_Man',
                             'Europe/London'
                           ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+353|\D)//g;
      my $self = bless({ country_code => '353', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '353', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;