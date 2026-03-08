# automatically generated file, don't edit



# Copyright 2026 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20260306161713;

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
$areanames{en} = {"3534367", "Granard",
"3534510", "Kildare",
"3537198", "Manorhamilton",
"3536690", "Killorglin",
"353909901", "Athlone",
"353460", "Navan",
"3534698", "Edenderry",
"353901", "Athlone",
"353616", "Scariff",
"353710", "Sligo",
"35374", "Letterkenny\/Donegal\/Dungloe\/Buncrana",
"353719335", "Sligo",
"35327", "Bantry",
"35343669", "Granard",
"353539903", "Gorey",
"35356", "Kilkenny\/Castlecomer\/Freshford",
"3534290", "Dundalk",
"353471", "Monaghan\/Clones",
"353477", "Monaghan",
"353452", "Kildare",
"3534497", "Castlepollard",
"3534496", "Castlepollard",
"353656", "Ennis",
"35371932", "Sligo",
"353620", "Tipperary\/Cashel",
"3534492", "Tyrellspass",
"353474", "Clones",
"35367", "Nenagh",
"353469907", "Edenderry",
"353499", "Belturbet",
"3537495", "Dungloe",
"3534491", "Tyrellspass",
"3534330", "Longford",
"353719344", "Sligo",
"35371931", "Sligo",
"35343", "Longford\/Granard",
"35396", "Ballina",
"3534292", "Dundalk",
"3535791", "Birr",
"3536599", "Ennis\/Ennistymon\/Kilrush",
"35325", "Fermoy",
"353909897", "Athlone",
"353949290", "Castlebar",
"3534291", "Dundalk",
"353539902", "Enniscorthy",
"3534297", "Castleblaney",
"35361", "Limerick",
"3534296", "Carrickmacross",
"353530", "Wexford",
"3534490", "Tyrellspass",
"3534331", "Longford",
"3535989", "Athy",
"353468", "Navan",
"353504", "Thurles",
"3534332", "Longford",
"3535678", "Kilkenny",
"353454", "The\ Curragh",
"353719330", "Sligo",
"3534120", "Drogheda\/Ardee",
"35361999", "Limerick\/Scariff",
"3536691", "Dingle",
"353653", "Ennis",
"3536692", "Dingle",
"353949287", "Castlebar",
"353457", "Naas",
"353655", "Ennis",
"353451", "Naas\/Kildare\/Curragh",
"353628", "Tipperary",
"353472", "Clones",
"3537493", "Buncrana",
"35321", "Cork",
"3536697", "Killorglin",
"3536696", "Cahirciveen",
"353579900", "Portlaoise",
"35371959", "Carrick\-on\-Shannon",
"353424", "Carrickmacross",
"3534699", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"3535274", "Cahir",
"3534695", "Enfield",
"3535997", "Muine\ Bheag",
"35374920", "Letterkenny",
"353579901", "Portlaoise",
"353218", "Cork\/Kinsale\/Coachford",
"353623", "Tipperary",
"353427", "Dundalk",
"35357859", "Portlaoise",
"353658", "Kilrush",
"353625", "Tipperary",
"353421", "Dundalk\/Carrickmacross\/Castleblaney",
"353719331", "Sligo",
"35358", "Dungarvan",
"353571", "Portlaoise",
"3535393", "Ferns",
"3535991", "Carlow",
"35374960", "Letterkenny",
"353512", "Kilmacthomas",
"353492", "Cootehill",
"353463", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"353719334", "Sligo",
"35393", "Tuam",
"3536299", "Tipperary",
"35322", "Mallow",
"353949286", "Castlebar",
"353402", "Arklow",
"35374989", "Letterkenny",
"353438", "Granard",
"353740", "Letterkenny",
"35371", "Sligo\/Manorhamilton\/Carrick\-on\-Shannon",
"3536466", "Killarney",
"353459", "Naas",
"353560", "Kilkenny",
"353949291", "Castlebar",
"353465", "Enfield",
"3539490", "Castlebar",
"353422", "Dundalk",
"3534693", "Kells",
"353650", "Ennis\/Ennistymon\/Kilrush",
"353626", "Cashel",
"35398", "Westport",
"35329", "Kanturk",
"3535988", "Athy",
"3536670", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"3539496", "Castlerea",
"3539097", "Portumna",
"3539096", "Ballinasloe",
"3536694", "Cahirciveen",
"35324", "Youghal",
"353749212", "Letterkenny",
"353494", "Cavan",
"353578510", "Portlaoise",
"35369", "Newcastle\ West",
"353447", "Castlepollard",
"353514", "New\ Ross",
"353719401", "Sligo",
"353479", "Monaghan",
"353404", "Wicklow",
"353466", "Edenderry",
"353497", "Cavan",
"3534294", "Dundalk",
"353491", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"35364", "Killarney\/Rathmore",
"35353", "Wexford\/Enniscorthy\/Ferns\/Gorey",
"353909900", "Athlone",
"3535291", "Killenaule",
"353912", "Gort",
"3534791", "Monaghan\/Clones",
"353490", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"3539066", "Roscommon",
"35363", "Rathluirc",
"353505", "Roscrea",
"3534498", "Castlepollard",
"353749211", "Letterkenny",
"353719900", "Sligo",
"353918", "Loughrea",
"3535390", "Wexford",
"353629", "Cashel",
"35359", "Carlow\/Muine\ Bheag\/Athy\/Baltinglass",
"353469900", "Navan",
"353437", "Granard",
"35341", "Drogheda",
"35343668", "Granard",
"353668", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"3534691", "Navan",
"353646700", "Killarney",
"353654", "Ennis",
"3537196", "Carrick\-on\-Shannon",
"3532141", "Kinsale",
"3534692", "Kells",
"353453", "The\ Curragh",
"353217", "Coachford",
"3535261", "Clonmel",
"35323", "Bandon",
"3534368", "Granard",
"353476", "Monaghan",
"3535786", "Portlaoise",
"353657", "Ennistymon",
"353428", "Dundalk",
"3539493", "Claremorris",
"3535787", "Abbeyleix",
"353455", "Kildare",
"353651", "Ennis\/Ennistymon\/Kilrush",
"353949285", "Castlebar",
"353719010", "Sligo",
"3532147", "Kinsale",
"3537191", "Sligo",
"3534697", "Edenderry",
"353531202", "Enniscorthy",
"353749214", "Letterkenny",
"3534696", "Enfield",
"3534199", "Drogheda\/Ardee",
"353741", "Letterkenny",
"353448", "Tyrellspass",
"353432", "Longford",
"35390", "Athlone\/Ballinasloe\/Portumna\/Roscommon",
"353539900", "Wexford",
"3532140", "Kinsale",
"353561", "Kilkenny",
"3534690", "Navan",
"35399", "Kilronan",
"35328", "Skibbereen",
"3535677", "Kilkenny",
"353416", "Ardee",
"353569901", "Kilkenny",
"353498", "Oldcastle",
"3536698", "Killorglin",
"35394", "Castlebar\/Claremorris\/Castlerea\/Ballinrobe",
"3534799", "Monaghan\/Clones",
"353652", "Ennis",
"353420", "Dundalk\/Carrickmacross\/Castleblaney",
"353456", "Naas",
"353475", "Clones",
"35368", "Listowel",
"353570", "Portlaoise",
"353531203", "Gorey",
"35352", "Clonmel\/Cahir\/Killenaule",
"35343667", "Granard",
"3535392", "Enniscorthy",
"3539495", "Ballinrobe",
"353473", "Monaghan",
"353719332", "Sligo",
"3535391", "Wexford",
"3534298", "Castleblaney",
"3537497", "Donegal",
"3536693", "Dingle",
"353622", "Cashel",
"353426", "Dundalk",
"353450", "Naas\/Kildare\/Curragh",
"353478", "Monaghan",
"353949289", "Castlebar",
"3534999", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"35357850", "Portlaoise",
"35351999", "Waterford\/Carrick\-on\-Suir\/New\ Ross\/Kilmacthomas",
"3534499", "Mullingar\/Castlepollard\/Tyrrellspass",
"3534495", "Castlepollard",
"35397", "Belmullet",
"3537491", "Letterkenny",
"3534694", "Trim",
"35390650", "Athlone",
"35351", "Waterford",
"353531", "Wexford",
"353569900", "Kilkenny",
"3539064", "Athlone",
"3536477", "Rathmore",
"353749888", "Letterkenny",
"3534293", "Dundalk",
"35394925", "Castlebar",
"353749900", "Letterkenny",
"353462", "Kells",
"353493", "Belturbet",
"3535793", "Tullamore",
"353909903", "Ballinasloe",
"3534333", "Longford",
"35344", "Mullingar",
"353495", "Cootehill",
"35343666", "Granard",
"353916", "Gort",
"353539901", "Wexford",
"3534369", "Granard",
"353443", "Mullingar\/Castlepollard\/Tyrrellspass",
"35357", "Portlaoise\/Abbeyleix\/Tullamore\/Birr",
"3536695", "Cahirciveen",
"35371930", "Sligo",
"353619", "Scariff",
"3535394", "Gorey",
"353624", "Tipperary",
"3536699", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"3535688", "Freshford",
"35326", "Macroom",
"353423", "Dundalk\/Carrickmacross\/Castleblaney",
"35395", "Clifden",
"353949288", "Castlebar",
"353470", "Monaghan\/Clones",
"353627", "Cashel",
"353646701", "Killarney",
"353621", "Tipperary\/Cashel",
"353425", "Castleblaney",
"353458", "Naas",
"353469901", "Navan",
"3539498", "Castlerea",
"353909902", "Ballinasloe",
"353496", "Cavan",
"353900", "Athlone",
"353711", "Sligo",
"3535987", "Athy",
"353516", "Carrick\-on\-Suir",
"3535986", "Athy",
"3534295", "Carrickmacross",
"353464", "Trim",
"3534299", "Dundalk\/Carrickmacross\/Castleblaney",
"35366", "Tralee",
"353669100", "Killorglin",
"353659", "Kilrush",
"3535964", "Baltinglass",
"3531", "Dublin",
"353749210", "Letterkenny",
"3535644", "Castlecomer",
"35391", "Galway",
"353467", "Navan",
"353461", "Navan",
"353749889", "Letterkenny",};
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