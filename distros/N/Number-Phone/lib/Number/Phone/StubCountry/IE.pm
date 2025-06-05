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
our $VERSION = 1.20250605193635;

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
$areanames{en} = {"353459", "Naas",
"353719401", "Sligo",
"353457", "Naas",
"353909900", "Athlone",
"353460", "Navan",
"35343669", "Granard",
"3535787", "Abbeyleix",
"353453", "The\ Curragh",
"353655", "Ennis",
"353476", "Monaghan",
"3537497", "Donegal",
"353646701", "Killarney",
"353217", "Coachford",
"3535688", "Freshford",
"353949291", "Castlebar",
"35368", "Listowel",
"3534297", "Castleblaney",
"353471", "Monaghan\/Clones",
"35326", "Macroom",
"353749900", "Letterkenny",
"35364", "Killarney\/Rathmore",
"3534496", "Castlepollard",
"3539097", "Portumna",
"35321", "Cork",
"353404", "Wicklow",
"353719334", "Sligo",
"35371932", "Sligo",
"353452", "Kildare",
"35374960", "Letterkenny",
"353514", "New\ Ross",
"3534510", "Kildare",
"35357", "Portlaoise\/Abbeyleix\/Tullamore\/Birr",
"353530", "Wexford",
"353539903", "Gorey",
"3534293", "Dundalk",
"35351999", "Waterford\/Carrick\-on\-Suir\/New\ Ross\/Kilmacthomas",
"353494", "Cavan",
"3534791", "Monaghan\/Clones",
"353465", "Enfield",
"353619", "Scariff",
"353498", "Oldcastle",
"353505", "Roscrea",
"3539496", "Castlerea",
"353428", "Dundalk",
"353650", "Ennis\/Ennistymon\/Kilrush",
"35395", "Clifden",
"353949288", "Castlebar",
"3535677", "Kilkenny",
"353424", "Carrickmacross",
"353626", "Cashel",
"353719900", "Sligo",
"35361", "Limerick",
"3539066", "Roscommon",
"353621", "Tipperary\/Cashel",
"3534333", "Longford",
"35343666", "Granard",
"3532147", "Kinsale",
"353909897", "Athlone",
"3536698", "Killorglin",
"3534299", "Dundalk\/Carrickmacross\/Castleblaney",
"353569900", "Kilkenny",
"353438", "Granard",
"353539902", "Enniscorthy",
"35328", "Skibbereen",
"353749211", "Letterkenny",
"35324", "Youghal",
"3537493", "Buncrana",
"3534696", "Enfield",
"35394925", "Castlebar",
"35366", "Tralee",
"353749888", "Letterkenny",
"3534999", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"353490", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"353900", "Athlone",
"353909903", "Ballinasloe",
"353719331", "Sligo",
"35323", "Bandon",
"3534367", "Granard",
"353479", "Monaghan",
"3536694", "Cahirciveen",
"353469900", "Navan",
"353477", "Monaghan",
"3537196", "Carrick\-on\-Shannon",
"353719335", "Sligo",
"3535988", "Athy",
"3536695", "Cahirciveen",
"353448", "Tyrellspass",
"353456", "Naas",
"353654", "Ennis",
"3536691", "Dingle",
"3535393", "Ferns",
"353420", "Dundalk\/Carrickmacross\/Castleblaney",
"353658", "Kilrush",
"353473", "Monaghan",
"35371931", "Sligo",
"3534499", "Mullingar\/Castlepollard\/Tyrrellspass",
"35329", "Kanturk",
"3536599", "Ennis\/Ennistymon\/Kilrush",
"353740", "Letterkenny",
"353579901", "Portlaoise",
"353451", "Naas\/Kildare\/Curragh",
"3535791", "Birr",
"353918", "Loughrea",
"353909902", "Ballinasloe",
"353472", "Clones",
"35322", "Mallow",
"3536670", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"3534697", "Edenderry",
"3536690", "Killorglin",
"353539900", "Wexford",
"353468", "Navan",
"353495", "Cootehill",
"353571", "Portlaoise",
"353749214", "Letterkenny",
"353464", "Trim",
"3536692", "Dingle",
"353627", "Cashel",
"353629", "Cashel",
"3534369", "Granard",
"35371930", "Sligo",
"35363", "Rathluirc",
"3535786", "Portlaoise",
"35397", "Belmullet",
"3535997", "Muine\ Bheag",
"353425", "Castleblaney",
"3534693", "Kells",
"353504", "Thurles",
"353616", "Scariff",
"353623", "Tipperary",
"353710", "Sligo",
"3534296", "Carrickmacross",
"353669100", "Killorglin",
"3534497", "Castlepollard",
"3534199", "Drogheda\/Ardee",
"353560", "Kilkenny",
"3534699", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"35369", "Newcastle\ West",
"3539096", "Ballinasloe",
"353622", "Cashel",
"3535644", "Castlecomer",
"3539493", "Claremorris",
"3537491", "Letterkenny",
"353570", "Portlaoise",
"35371959", "Carrick\-on\-Shannon",
"35353", "Wexford\/Enniscorthy\/Ferns\/Gorey",
"3537495", "Dungloe",
"353578510", "Portlaoise",
"353949290", "Castlebar",
"3534498", "Castlepollard",
"353652", "Ennis",
"353516", "Carrick\-on\-Suir",
"3534290", "Dundalk",
"353719332", "Sligo",
"3534331", "Longford",
"35344", "Mullingar",
"3534799", "Monaghan\/Clones",
"353711", "Sligo",
"35391", "Galway",
"35359", "Carlow\/Muine\ Bheag\/Athy\/Baltinglass",
"353653", "Ennis",
"3534294", "Dundalk",
"353443", "Mullingar\/Castlepollard\/Tyrrellspass",
"353474", "Clones",
"353455", "Kildare",
"353909901", "Athlone",
"353561", "Kilkenny",
"353478", "Monaghan",
"353659", "Kilrush",
"353447", "Castlepollard",
"3534330", "Longford",
"353912", "Gort",
"353646700", "Killarney",
"353657", "Ennistymon",
"35352", "Clonmel\/Cahir\/Killenaule",
"3535989", "Athy",
"35396", "Ballina",
"3534295", "Carrickmacross",
"3534291", "Dundalk",
"3531", "Dublin",
"353491", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"353901", "Athlone",
"3535964", "Baltinglass",
"353569901", "Kilkenny",
"3534332", "Longford",
"35357859", "Portlaoise",
"3537191", "Sligo",
"3536696", "Cahirciveen",
"3535261", "Clonmel",
"35325", "Fermoy",
"353749210", "Letterkenny",
"3532140", "Kinsale",
"35341", "Drogheda",
"353421", "Dundalk\/Carrickmacross\/Castleblaney",
"3534698", "Edenderry",
"3536299", "Tipperary",
"353462", "Kells",
"35390650", "Athlone",
"353467", "Navan",
"3534292", "Dundalk",
"35398", "Westport",
"3534368", "Granard",
"35394", "Castlebar\/Claremorris\/Castlerea\/Ballinrobe",
"353741", "Letterkenny",
"353628", "Tipperary",
"353450", "Naas\/Kildare\/Curragh",
"353719010", "Sligo",
"353624", "Tipperary",
"353426", "Dundalk",
"3535987", "Athy",
"353463", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"3532141", "Kinsale",
"353496", "Cavan",
"3539498", "Castlerea",
"353531", "Wexford",
"353579900", "Portlaoise",
"3539495", "Ballinrobe",
"3536697", "Killorglin",
"3536466", "Killarney",
"3534690", "Navan",
"35367", "Nenagh",
"35361999", "Limerick\/Scariff",
"35393", "Tuam",
"353916", "Gort",
"353651", "Ennis\/Ennistymon\/Kilrush",
"35343668", "Granard",
"353402", "Arklow",
"3534695", "Enfield",
"353656", "Ennis",
"3539064", "Athlone",
"353949285", "Castlebar",
"35371", "Sligo\/Manorhamilton\/Carrick\-on\-Shannon",
"353475", "Clones",
"353454", "The\ Curragh",
"3534691", "Navan",
"353469901", "Navan",
"353512", "Kilmacthomas",
"353620", "Tipperary\/Cashel",
"353458", "Naas",
"3539490", "Castlebar",
"3534492", "Tyrellspass",
"353719330", "Sligo",
"353949286", "Castlebar",
"3534120", "Drogheda\/Ardee",
"35356", "Kilkenny\/Castlecomer\/Freshford",
"35343667", "Granard",
"35374989", "Letterkenny",
"35399", "Kilronan",
"35351", "Waterford",
"3535986", "Athy",
"3535392", "Enniscorthy",
"3537198", "Manorhamilton",
"35374920", "Letterkenny",
"3534694", "Trim",
"3535678", "Kilkenny",
"353218", "Cork\/Kinsale\/Coachford",
"3536699", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"3535390", "Wexford",
"3534298", "Castleblaney",
"35390", "Athlone\/Ballinasloe\/Portumna\/Roscommon",
"353422", "Dundalk",
"3535274", "Cahir",
"35327", "Bantry",
"3535991", "Carlow",
"353461", "Navan",
"353437", "Granard",
"353492", "Cootehill",
"353531202", "Enniscorthy",
"3535793", "Tullamore",
"353749889", "Letterkenny",
"3534490", "Tyrellspass",
"3536477", "Rathmore",
"3535291", "Killenaule",
"353470", "Monaghan\/Clones",
"353531203", "Gorey",
"353469907", "Edenderry",
"35343", "Longford\/Granard",
"353749212", "Letterkenny",
"353625", "Tipperary",
"3536693", "Dingle",
"353539901", "Wexford",
"3535391", "Wexford",
"353499", "Belturbet",
"35374", "Letterkenny\/Donegal\/Dungloe\/Buncrana",
"35357850", "Portlaoise",
"353497", "Cavan",
"353423", "Dundalk\/Carrickmacross\/Castleblaney",
"353416", "Ardee",
"353432", "Longford",
"353949287", "Castlebar",
"353668", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"35358", "Dungarvan",
"3534495", "Castlepollard",
"3535394", "Gorey",
"353466", "Edenderry",
"3534491", "Tyrellspass",
"3534692", "Kells",
"353719344", "Sligo",
"353949289", "Castlebar",
"353427", "Dundalk",
"353493", "Belturbet",};
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