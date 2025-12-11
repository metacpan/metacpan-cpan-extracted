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
our $VERSION = 1.20251210153523;

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
$areanames{en} = {"353653", "Ennis",
"3535677", "Kilkenny",
"353495", "Cootehill",
"353650", "Ennis\/Ennistymon\/Kilrush",
"353627", "Cashel",
"353456", "Naas",
"353616", "Scariff",
"353473", "Monaghan",
"353470", "Monaghan\/Clones",
"353404", "Wicklow",
"353579900", "Portlaoise",
"35371930", "Sligo",
"353949287", "Castlebar",
"35343668", "Granard",
"353448", "Tyrellspass",
"3535291", "Killenaule",
"353949290", "Castlebar",
"3537493", "Buncrana",
"353740", "Letterkenny",
"353909902", "Ballinasloe",
"35343", "Longford\/Granard",
"353949291", "Castlebar",
"353912", "Gort",
"35356", "Kilkenny\/Castlecomer\/Freshford",
"353218", "Cork\/Kinsale\/Coachford",
"353477", "Monaghan",
"353579901", "Portlaoise",
"35394", "Castlebar\/Claremorris\/Castlerea\/Ballinrobe",
"35343666", "Granard",
"3534368", "Granard",
"353426", "Dundalk",
"353657", "Ennistymon",
"3534510", "Kildare",
"3534497", "Castlepollard",
"353620", "Tipperary\/Cashel",
"3534291", "Dundalk",
"353623", "Tipperary",
"35353", "Wexford\/Enniscorthy\/Ferns\/Gorey",
"353749900", "Letterkenny",
"3534120", "Drogheda\/Ardee",
"3535793", "Tullamore",
"3534495", "Castlepollard",
"35369", "Newcastle\ West",
"353570", "Portlaoise",
"353504", "Thurles",
"353457", "Naas",
"353626", "Cashel",
"3534294", "Dundalk",
"353420", "Dundalk\/Carrickmacross\/Castleblaney",
"3534293", "Dundalk",
"353949285", "Castlebar",
"3535644", "Castlecomer",
"353423", "Dundalk\/Carrickmacross\/Castleblaney",
"353719332", "Sligo",
"353465", "Enfield",
"3534492", "Tyrellspass",
"35328", "Skibbereen",
"3535791", "Birr",
"35374920", "Letterkenny",
"353539902", "Enniscorthy",
"353516", "Carrick\-on\-Suir",
"3535678", "Kilkenny",
"353646701", "Killarney",
"3534290", "Dundalk",
"3534498", "Castlepollard",
"353646700", "Killarney",
"3534791", "Monaghan\/Clones",
"353749214", "Letterkenny",
"353476", "Monaghan",
"35359", "Carlow\/Muine\ Bheag\/Athy\/Baltinglass",
"3537491", "Letterkenny",
"35363", "Rathluirc",
"3537198", "Manorhamilton",
"35374989", "Letterkenny",
"3534332", "Longford",
"35390", "Athlone\/Ballinasloe\/Portumna\/Roscommon",
"353453", "The\ Curragh",
"35366", "Tralee",
"353450", "Naas\/Kildare\/Curragh",
"3534367", "Granard",
"353656", "Ennis",
"353427", "Dundalk",
"353416", "Ardee",
"3534496", "Castlepollard",
"353719330", "Sligo",
"353425", "Castleblaney",
"35341", "Drogheda",
"3536691", "Dingle",
"3534694", "Trim",
"353569900", "Kilkenny",
"353460", "Navan",
"3534693", "Kells",
"353463", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"3534369", "Granard",
"3537196", "Carrick\-on\-Shannon",
"3535991", "Carlow",
"353531202", "Enniscorthy",
"3534690", "Navan",
"353469901", "Navan",
"35374", "Letterkenny\/Donegal\/Dungloe\/Buncrana",
"353539900", "Wexford",
"35374960", "Letterkenny",
"353469900", "Navan",
"353560", "Kilkenny",
"35351", "Waterford",
"353539901", "Wexford",
"353437", "Granard",
"35361999", "Limerick\/Scariff",
"3539066", "Roscommon",
"3535390", "Wexford",
"3539493", "Claremorris",
"3535394", "Gorey",
"353530", "Wexford",
"35357850", "Portlaoise",
"353918", "Loughrea",
"353569901", "Kilkenny",
"3539490", "Castlebar",
"3535393", "Ferns",
"353467", "Navan",
"353719331", "Sligo",
"35324", "Youghal",
"353496", "Cavan",
"35357", "Portlaoise\/Abbeyleix\/Tullamore\/Birr",
"35357859", "Portlaoise",
"353455", "Kildare",
"3535391", "Wexford",
"353490", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"353493", "Belturbet",
"353655", "Ennis",
"353909900", "Athlone",
"353402", "Arklow",
"353475", "Clones",
"35398", "Westport",
"353719401", "Sligo",
"3534499", "Mullingar\/Castlepollard\/Tyrrellspass",
"35367", "Nenagh",
"3532147", "Kinsale",
"35394925", "Castlebar",
"353711", "Sligo",
"3536690", "Killorglin",
"3531", "Dublin",
"353909901", "Athlone",
"35352", "Clonmel\/Cahir\/Killenaule",
"35351999", "Waterford\/Carrick\-on\-Suir\/New\ Ross\/Kilmacthomas",
"353625", "Tipperary",
"353497", "Cavan",
"353466", "Edenderry",
"3536694", "Cahirciveen",
"3534691", "Navan",
"35361", "Limerick",
"3536693", "Dingle",
"353900", "Athlone",
"35326", "Macroom",
"3535988", "Athy",
"3535964", "Baltinglass",
"35397", "Belmullet",
"353719900", "Sligo",
"353491", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"353454", "The\ Curragh",
"353447", "Castlepollard",
"3534333", "Longford",
"35391", "Galway",
"3537495", "Dungloe",
"35323", "Bandon",
"3534298", "Castleblaney",
"35371959", "Carrick\-on\-Shannon",
"3534330", "Longford",
"353949289", "Castlebar",
"353628", "Tipperary",
"3536466", "Killarney",
"3536699", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"3539496", "Castlerea",
"3539064", "Athlone",
"3537497", "Donegal",
"353749212", "Letterkenny",
"353710", "Sligo",
"35343667", "Granard",
"353539903", "Gorey",
"35390650", "Athlone",
"3534999", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"353658", "Kilrush",
"353432", "Longford",
"3534490", "Tyrellspass",
"353424", "Carrickmacross",
"35368", "Listowel",
"353719334", "Sligo",
"353478", "Monaghan",
"353578510", "Portlaoise",
"353443", "Mullingar\/Castlepollard\/Tyrrellspass",
"353901", "Athlone",
"3534696", "Enfield",
"353462", "Kells",
"353217", "Coachford",
"353719335", "Sligo",
"3535786", "Portlaoise",
"3534292", "Dundalk",
"353749888", "Letterkenny",
"35329", "Kanturk",
"3535688", "Freshford",
"3534491", "Tyrellspass",
"3534297", "Castleblaney",
"353624", "Tipperary",
"3536696", "Cahirciveen",
"353669100", "Killorglin",
"3539096", "Ballinasloe",
"353469907", "Edenderry",
"3536670", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353461", "Navan",
"3534295", "Carrickmacross",
"3537191", "Sligo",
"3535987", "Athy",
"353514", "New\ Ross",
"353458", "Naas",
"353499", "Belturbet",
"35395", "Clifden",
"353428", "Dundalk",
"35371931", "Sligo",
"3534699", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"353561", "Kilkenny",
"353474", "Clones",
"35358", "Dungarvan",
"353909903", "Ballinasloe",
"353531", "Wexford",
"3534331", "Longford",
"353492", "Cootehill",
"353654", "Ennis",
"353622", "Cashel",
"353479", "Monaghan",
"35321", "Cork",
"3536692", "Dingle",
"353421", "Dundalk\/Carrickmacross\/Castleblaney",
"3534695", "Enfield",
"35393", "Tuam",
"3534697", "Edenderry",
"353719010", "Sligo",
"353909897", "Athlone",
"3535787", "Abbeyleix",
"353505", "Roscrea",
"353749889", "Letterkenny",
"3532141", "Kinsale",
"35396", "Ballina",
"353512", "Kilmacthomas",
"353659", "Kilrush",
"35327", "Bantry",
"3539495", "Ballinrobe",
"353472", "Clones",
"35371", "Sligo\/Manorhamilton\/Carrick\-on\-Shannon",
"353629", "Cashel",
"3536698", "Killorglin",
"353468", "Navan",
"3534299", "Dundalk\/Carrickmacross\/Castleblaney",
"35344", "Mullingar",
"353494", "Cavan",
"353451", "Naas\/Kildare\/Curragh",
"3535989", "Athy",
"353438", "Granard",
"353652", "Ennis",
"3535274", "Cahir",
"35364", "Killarney\/Rathmore",
"353651", "Ennis\/Ennistymon\/Kilrush",
"35322", "Mallow",
"353719344", "Sligo",
"3535392", "Enniscorthy",
"353452", "Kildare",
"353949286", "Castlebar",
"353471", "Monaghan\/Clones",
"35399", "Kilronan",
"353749210", "Letterkenny",
"353741", "Letterkenny",
"353949288", "Castlebar",
"3534698", "Edenderry",
"353668", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"3536299", "Tipperary",
"3536599", "Ennis\/Ennistymon\/Kilrush",
"3534199", "Drogheda\/Ardee",
"353531203", "Gorey",
"3535997", "Muine\ Bheag",
"3535986", "Athy",
"35371932", "Sligo",
"353916", "Gort",
"3536477", "Rathmore",
"353459", "Naas",
"353619", "Scariff",
"353749211", "Letterkenny",
"353498", "Oldcastle",
"353422", "Dundalk",
"3534296", "Carrickmacross",
"353621", "Tipperary\/Cashel",
"3536695", "Cahirciveen",
"35325", "Fermoy",
"35343669", "Granard",
"3534692", "Kells",
"3539498", "Castlerea",
"353464", "Trim",
"3536697", "Killorglin",
"3532140", "Kinsale",
"3534799", "Monaghan\/Clones",
"353571", "Portlaoise",
"3535261", "Clonmel",
"3539097", "Portumna",};
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