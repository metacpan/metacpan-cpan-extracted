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
package Number::Phone::StubCountry::IE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20230305170052;

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
$areanames{en} = {"3537198", "Manorhamilton",
"353749900", "Letterkenny",
"35323", "Bandon",
"35369", "Newcastle\ West",
"353657", "Ennistymon",
"353912", "Gort",
"35394925", "Castlebar",
"3534498", "Castlepollard",
"3534369", "Granard",
"353464", "Trim",
"353622", "Cashel",
"3534294", "Dundalk",
"35343668", "Granard",
"353949289", "Castlebar",
"35374920", "Letterkenny",
"3539097", "Portumna",
"3537493", "Buncrana",
"35341", "Drogheda",
"3534698", "Edenderry",
"3536670", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353909897", "Athlone",
"35374", "Letterkenny\/Donegal\/Dungloe\/Buncrana",
"353569901", "Kilkenny",
"353497", "Cavan",
"353570", "Portlaoise",
"3537495", "Dungloe",
"3534292", "Dundalk",
"353949286", "Castlebar",
"35328", "Skibbereen",
"353949291", "Castlebar",
"353455", "Kildare",
"353424", "Carrickmacross",
"35371932", "Sligo",
"353475", "Clones",
"353530", "Wexford",
"3536691", "Dingle",
"353658", "Kilrush",
"353621", "Tipperary\/Cashel",
"35371930", "Sligo",
"3534492", "Tyrellspass",
"3534694", "Trim",
"353650", "Ennis\/Ennistymon\/Kilrush",
"35343", "Longford\/Granard",
"3536599", "Ennis\/Ennistymon\/Kilrush",
"353453", "The\ Curragh",
"3539066", "Roscommon",
"3534332", "Longford",
"35357850", "Portlaoise",
"353404", "Wicklow",
"353626", "Cashel",
"3534298", "Castleblaney",
"353900", "Athlone",
"353473", "Monaghan",
"35359", "Carlow\/Muine\ Bheag\/Athy\/Baltinglass",
"353916", "Gort",
"3534692", "Kells",
"35327", "Bantry",
"353498", "Oldcastle",
"35321", "Cork",
"353749888", "Letterkenny",
"3534999", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"35325", "Fermoy",
"3532140", "Kinsale",
"3534367", "Granard",
"3535291", "Killenaule",
"353490", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"353561", "Kilkenny",
"3534497", "Castlepollard",
"353659", "Kilrush",
"35393", "Tuam",
"35352", "Clonmel\/Cahir\/Killenaule",
"35364", "Killarney\/Rathmore",
"3532141", "Kinsale",
"353467", "Navan",
"35351999", "Waterford\/Carrick\-on\-Suir\/New\ Ross\/Kilmacthomas",
"353619", "Scariff",
"353949290", "Castlebar",
"353654", "Ennis",
"353625", "Tipperary",
"353420", "Dundalk\/Carrickmacross\/Castleblaney",
"3535991", "Carlow",
"3535787", "Abbeyleix",
"353471", "Monaghan\/Clones",
"3534299", "Dundalk\/Carrickmacross\/Castleblaney",
"3536693", "Dingle",
"353451", "Naas\/Kildare\/Curragh",
"353428", "Dundalk",
"353741", "Letterkenny",
"353456", "Naas",
"353447", "Castlepollard",
"353499", "Belturbet",
"353494", "Cavan",
"353432", "Longford",
"353623", "Tipperary",
"3534697", "Edenderry",
"353416", "Ardee",
"3536690", "Killorglin",
"35366", "Tralee",
"353476", "Monaghan",
"3536695", "Cahirciveen",
"35398", "Westport",
"3535964", "Baltinglass",
"353427", "Dundalk",
"353505", "Roscrea",
"35356", "Kilkenny\/Castlecomer\/Freshford",
"3535394", "Gorey",
"353468", "Navan",
"353472", "Clones",
"3539498", "Castlerea",
"3537491", "Letterkenny",
"353531203", "Gorey",
"353460", "Navan",
"353452", "Kildare",
"3534791", "Monaghan\/Clones",
"3534699", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"3534297", "Castleblaney",
"35343666", "Granard",
"3535986", "Athy",
"3535392", "Enniscorthy",
"353531202", "Enniscorthy",
"353569900", "Kilkenny",
"353514", "New\ Ross",
"35361999", "Limerick\/Scariff",
"3534368", "Granard",
"35395", "Clifden",
"3534499", "Mullingar\/Castlepollard\/Tyrrellspass",
"3536696", "Cahirciveen",
"353710", "Sligo",
"353448", "Tyrellspass",
"35391", "Galway",
"35397", "Belmullet",
"353496", "Cavan",
"35344", "Mullingar",
"3534490", "Tyrellspass",
"353469900", "Navan",
"353918", "Loughrea",
"353459", "Naas",
"353474", "Clones",
"35371", "Sligo\/Manorhamilton\/Carrick\-on\-Shannon",
"353425", "Castleblaney",
"353531", "Wexford",
"353454", "The\ Curragh",
"353479", "Monaghan",
"3534333", "Longford",
"3535688", "Freshford",
"3536299", "Tipperary",
"353620", "Tipperary\/Cashel",
"35343669", "Granard",
"353719332", "Sligo",
"35374960", "Letterkenny",
"3534495", "Castlepollard",
"3534693", "Kells",
"353651", "Ennis\/Ennistymon\/Kilrush",
"353628", "Tipperary",
"353579901", "Portlaoise",
"353656", "Ennis",
"353719900", "Sligo",
"353616", "Scariff",
"3534690", "Navan",
"353901", "Athlone",
"353719335", "Sligo",
"353749210", "Letterkenny",
"3536697", "Killorglin",
"353423", "Dundalk\/Carrickmacross\/Castleblaney",
"3534695", "Enfield",
"353719334", "Sligo",
"353949287", "Castlebar",
"353512", "Kilmacthomas",
"35322", "Mallow",
"3534296", "Carrickmacross",
"353560", "Kilkenny",
"3534330", "Longford",
"353491", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"3535987", "Athy",
"3535791", "Birr",
"353465", "Enfield",
"353749214", "Letterkenny",
"3535391", "Wexford",
"353627", "Cashel",
"3535678", "Kilkenny",
"3535989", "Athy",
"3539064", "Athlone",
"35390650", "Athlone",
"3535786", "Portlaoise",
"353443", "Mullingar\/Castlepollard\/Tyrrellspass",
"353516", "Carrick\-on\-Suir",
"35399", "Kilronan",
"3537196", "Carrick\-on\-Shannon",
"353668", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353578510", "Portlaoise",
"353719010", "Sligo",
"35324", "Youghal",
"3534293", "Dundalk",
"3534496", "Castlepollard",
"3536699", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353719330", "Sligo",
"353539901", "Wexford",
"353652", "Ennis",
"3534290", "Dundalk",
"353463", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"353749212", "Letterkenny",
"353719401", "Sligo",
"3534696", "Enfield",
"353571", "Portlaoise",
"3536466", "Killarney",
"3535274", "Cahir",
"353719344", "Sligo",
"353492", "Cootehill",
"3534295", "Carrickmacross",
"353646700", "Killarney",
"35326", "Macroom",
"353909901", "Athlone",
"353477", "Monaghan",
"3539496", "Castlerea",
"353504", "Thurles",
"353669100", "Killorglin",
"35358", "Dungarvan",
"3535393", "Ferns",
"353218", "Cork\/Kinsale\/Coachford",
"353457", "Naas",
"3536477", "Rathmore",
"353719331", "Sligo",
"353539900", "Wexford",
"353422", "Dundalk",
"35374989", "Letterkenny",
"353461", "Navan",
"35390", "Athlone\/Ballinasloe\/Portumna\/Roscommon",
"3534291", "Dundalk",
"353438", "Granard",
"3536698", "Killorglin",
"35361", "Limerick",
"353466", "Edenderry",
"35367", "Nenagh",
"35371959", "Carrick\-on\-Shannon",
"3537497", "Donegal",
"3534510", "Kildare",
"35357859", "Portlaoise",
"353909900", "Athlone",
"353402", "Arklow",
"3535644", "Castlecomer",
"353646701", "Killarney",
"3535988", "Athy",
"353749889", "Letterkenny",
"35353", "Wexford\/Enniscorthy\/Ferns\/Gorey",
"353711", "Sligo",
"353469907", "Edenderry",
"3535390", "Wexford",
"353655", "Ennis",
"353624", "Tipperary",
"35357", "Portlaoise\/Abbeyleix\/Tullamore\/Birr",
"353493", "Belturbet",
"3535677", "Kilkenny",
"35351", "Waterford",
"3539096", "Ballinasloe",
"3534331", "Longford",
"3539495", "Ballinrobe",
"353469901", "Navan",
"353909903", "Ballinasloe",
"353629", "Cashel",
"353470", "Monaghan\/Clones",
"35371931", "Sligo",
"353217", "Coachford",
"353458", "Naas",
"3534691", "Navan",
"3534199", "Drogheda\/Ardee",
"353421", "Dundalk\/Carrickmacross\/Castleblaney",
"3534799", "Monaghan\/Clones",
"353539902", "Enniscorthy",
"353740", "Letterkenny",
"3535261", "Clonmel",
"353478", "Monaghan",
"35363", "Rathluirc",
"3531", "Dublin",
"35329", "Kanturk",
"35394", "Castlebar\/Claremorris\/Castlerea\/Ballinrobe",
"3539490", "Castlebar",
"3536694", "Cahirciveen",
"353462", "Kells",
"353949288", "Castlebar",
"353450", "Naas\/Kildare\/Curragh",
"353749211", "Letterkenny",
"35343667", "Granard",
"353653", "Ennis",
"353495", "Cootehill",
"353539903", "Gorey",
"3539493", "Claremorris",
"35368", "Listowel",
"353426", "Dundalk",
"353579900", "Portlaoise",
"3535997", "Muine\ Bheag",
"3535793", "Tullamore",
"353909902", "Ballinasloe",
"35396", "Ballina",
"3536692", "Dingle",
"3537191", "Sligo",
"3532147", "Kinsale",
"353949285", "Castlebar",
"353437", "Granard",
"3534491", "Tyrellspass",
"3534120", "Drogheda\/Ardee",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+353|\D)//g;
      my $self = bless({ country_code => '353', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '353', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;