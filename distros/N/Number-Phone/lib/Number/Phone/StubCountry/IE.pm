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
package Number::Phone::StubCountry::IE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250913135857;

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
$areanames{en} = {"353949289", "Castlebar",
"35361", "Limerick",
"353512", "Kilmacthomas",
"353420", "Dundalk\/Carrickmacross\/Castleblaney",
"353949285", "Castlebar",
"3534791", "Monaghan\/Clones",
"353455", "Kildare",
"3535391", "Wexford",
"3534367", "Granard",
"3534691", "Navan",
"3535678", "Kilkenny",
"3534332", "Longford",
"3535786", "Portlaoise",
"3536693", "Dingle",
"3535390", "Wexford",
"353461", "Navan",
"353531", "Wexford",
"3534690", "Navan",
"353471", "Monaghan\/Clones",
"3534697", "Edenderry",
"35323", "Bandon",
"353505", "Roscrea",
"353453", "The\ Curragh",
"353909903", "Ballinasloe",
"353719334", "Sligo",
"353657", "Ennistymon",
"353402", "Arklow",
"35324", "Youghal",
"3531", "Dublin",
"3534695", "Enfield",
"3537198", "Manorhamilton",
"353497", "Cavan",
"3536699", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"3535677", "Kilkenny",
"3534368", "Granard",
"3534698", "Edenderry",
"35366", "Tralee",
"353432", "Longford",
"35399", "Kilronan",
"353749214", "Letterkenny",
"35367", "Nenagh",
"353451", "Naas\/Kildare\/Curragh",
"353531202", "Enniscorthy",
"353628", "Tipperary",
"353494", "Cavan",
"3536692", "Dingle",
"353949287", "Castlebar",
"353465", "Enfield",
"3534333", "Longford",
"353654", "Ennis",
"353475", "Clones",
"35328", "Skibbereen",
"353438", "Granard",
"353463", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"353656", "Ennis",
"353616", "Scariff",
"353473", "Monaghan",
"3537191", "Sligo",
"35357850", "Portlaoise",
"353711", "Sligo",
"3534296", "Carrickmacross",
"353496", "Cavan",
"35374920", "Letterkenny",
"353749888", "Letterkenny",
"353448", "Tyrellspass",
"3536599", "Ennis\/Ennistymon\/Kilrush",
"353719401", "Sligo",
"35352", "Clonmel\/Cahir\/Killenaule",
"3534999", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"353622", "Cashel",
"35361999", "Limerick\/Scariff",
"353569900", "Kilkenny",
"353570", "Portlaoise",
"3534120", "Drogheda\/Ardee",
"3534699", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"353719335", "Sligo",
"3534799", "Monaghan\/Clones",
"353579900", "Portlaoise",
"353560", "Kilkenny",
"35371", "Sligo\/Manorhamilton\/Carrick\-on\-Shannon",
"353579901", "Portlaoise",
"353909902", "Ballinasloe",
"3534294", "Dundalk",
"3536695", "Cahirciveen",
"353457", "Naas",
"353569901", "Kilkenny",
"3534369", "Granard",
"353466", "Edenderry",
"353653", "Ennis",
"353476", "Monaghan",
"3535291", "Killenaule",
"353916", "Gort",
"353719332", "Sligo",
"353493", "Belturbet",
"3535393", "Ferns",
"3536690", "Killorglin",
"3536697", "Killorglin",
"353719331", "Sligo",
"353495", "Cootehill",
"353949288", "Castlebar",
"3534693", "Kells",
"353629", "Cashel",
"3536691", "Dingle",
"353740", "Letterkenny",
"353464", "Trim",
"35322", "Mallow",
"353749900", "Letterkenny",
"353655", "Ennis",
"353474", "Clones",
"353719330", "Sligo",
"35371959", "Carrick\-on\-Shannon",
"353909901", "Athlone",
"35358", "Dungarvan",
"35397", "Belmullet",
"353620", "Tipperary\/Cashel",
"35369", "Newcastle\ West",
"3532147", "Kinsale",
"3532140", "Kinsale",
"35396", "Ballina",
"3539496", "Castlerea",
"35394925", "Castlebar",
"353900", "Athlone",
"3532141", "Kinsale",
"35341", "Drogheda",
"353909900", "Athlone",
"353749211", "Letterkenny",
"353422", "Dundalk",
"35343668", "Granard",
"353477", "Monaghan",
"353467", "Navan",
"353578510", "Portlaoise",
"3534199", "Drogheda\/Ardee",
"353749210", "Letterkenny",
"3535274", "Cahir",
"353749889", "Letterkenny",
"353504", "Thurles",
"35371932", "Sligo",
"353456", "Naas",
"353416", "Ardee",
"3539096", "Ballinasloe",
"353454", "The\ Curragh",
"3535986", "Athy",
"3534330", "Longford",
"3535392", "Enniscorthy",
"3534692", "Kells",
"353491", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"3536477", "Rathmore",
"3534331", "Longford",
"353428", "Dundalk",
"353651", "Ennis\/Ennistymon\/Kilrush",
"35353", "Wexford\/Enniscorthy\/Ferns\/Gorey",
"3536698", "Killorglin",
"3534496", "Castlepollard",
"353531203", "Gorey",
"353749212", "Letterkenny",
"35395", "Clifden",
"35391", "Galway",
"353218", "Cork\/Kinsale\/Coachford",
"353539900", "Wexford",
"353460", "Navan",
"353530", "Wexford",
"353469900", "Navan",
"3535989", "Athy",
"353470", "Monaghan\/Clones",
"353949286", "Castlebar",
"353469901", "Navan",
"353539901", "Wexford",
"3537493", "Buncrana",
"353421", "Dundalk\/Carrickmacross\/Castleblaney",
"3534499", "Mullingar\/Castlepollard\/Tyrrellspass",
"35343667", "Granard",
"35374989", "Letterkenny",
"3537196", "Carrick\-on\-Shannon",
"3534297", "Castleblaney",
"3535261", "Clonmel",
"353658", "Kilrush",
"3534290", "Dundalk",
"353479", "Monaghan",
"353624", "Tipperary",
"353498", "Oldcastle",
"3534291", "Dundalk",
"35390650", "Athlone",
"35394", "Castlebar\/Claremorris\/Castlerea\/Ballinrobe",
"353626", "Cashel",
"3535793", "Tullamore",
"353669100", "Killorglin",
"3535688", "Freshford",
"353539902", "Enniscorthy",
"353492", "Cootehill",
"353646701", "Killarney",
"3536299", "Tipperary",
"35393", "Tuam",
"35351", "Waterford",
"353646700", "Killarney",
"3534295", "Carrickmacross",
"3536694", "Cahirciveen",
"353652", "Ennis",
"3534298", "Castleblaney",
"353437", "Granard",
"353450", "Naas\/Kildare\/Curragh",
"35390", "Athlone\/Ballinasloe\/Portumna\/Roscommon",
"35343666", "Granard",
"353425", "Castleblaney",
"353404", "Wicklow",
"3534510", "Kildare",
"3539066", "Roscommon",
"353459", "Naas",
"353447", "Castlepollard",
"35329", "Kanturk",
"353516", "Carrick\-on\-Suir",
"353668", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"35374", "Letterkenny\/Donegal\/Dungloe\/Buncrana",
"3535787", "Abbeyleix",
"353949290", "Castlebar",
"3535997", "Muine\ Bheag",
"3534696", "Enfield",
"35344", "Mullingar",
"353514", "New\ Ross",
"353469907", "Edenderry",
"353423", "Dundalk\/Carrickmacross\/Castleblaney",
"353949291", "Castlebar",
"3535991", "Carlow",
"353627", "Cashel",
"353710", "Sligo",
"35356", "Kilkenny\/Castlecomer\/Freshford",
"353719900", "Sligo",
"35343", "Longford\/Granard",
"35398", "Westport",
"3534492", "Tyrellspass",
"35357", "Portlaoise\/Abbeyleix\/Tullamore\/Birr",
"3539493", "Claremorris",
"3535964", "Baltinglass",
"3536670", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353719344", "Sligo",
"3534694", "Trim",
"353452", "Kildare",
"3535394", "Gorey",
"3534491", "Tyrellspass",
"35368", "Listowel",
"3534299", "Dundalk\/Carrickmacross\/Castleblaney",
"3534497", "Castlepollard",
"35359", "Carlow\/Muine\ Bheag\/Athy\/Baltinglass",
"3534490", "Tyrellspass",
"353539903", "Gorey",
"3535791", "Birr",
"3539498", "Castlerea",
"353426", "Dundalk",
"353571", "Portlaoise",
"3535987", "Athy",
"353561", "Kilkenny",
"3537495", "Dungloe",
"35343669", "Granard",
"35326", "Macroom",
"353424", "Carrickmacross",
"353901", "Athlone",
"35327", "Bantry",
"3534495", "Castlepollard",
"3539097", "Portumna",
"353458", "Naas",
"3534293", "Dundalk",
"353621", "Tipperary\/Cashel",
"353741", "Letterkenny",
"3535644", "Castlecomer",
"3537497", "Donegal",
"3539064", "Athlone",
"35351999", "Waterford\/Carrick\-on\-Suir\/New\ Ross\/Kilmacthomas",
"3537491", "Letterkenny",
"35357859", "Portlaoise",
"353909897", "Athlone",
"353912", "Gort",
"3536466", "Killarney",
"353462", "Kells",
"35363", "Rathluirc",
"353427", "Dundalk",
"353472", "Clones",
"3539490", "Castlebar",
"3535988", "Athy",
"353623", "Tipperary",
"353217", "Coachford",
"3536696", "Cahirciveen",
"35364", "Killarney\/Rathmore",
"3534498", "Castlepollard",
"353468", "Navan",
"353499", "Belturbet",
"353478", "Monaghan",
"3539495", "Ballinrobe",
"353659", "Kilrush",
"353619", "Scariff",
"353918", "Loughrea",
"35321", "Cork",
"35325", "Fermoy",
"353625", "Tipperary",
"35374960", "Letterkenny",
"3534292", "Dundalk",
"353719010", "Sligo",
"353443", "Mullingar\/Castlepollard\/Tyrrellspass",
"35371931", "Sligo",
"353650", "Ennis\/Ennistymon\/Kilrush",
"35371930", "Sligo",
"353490", "Cavan\/Cootehill\/Oldcastle\/Belturbet",};
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