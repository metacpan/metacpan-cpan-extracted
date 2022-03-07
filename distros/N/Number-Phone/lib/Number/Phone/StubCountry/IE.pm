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
package Number::Phone::StubCountry::IE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20220305001842;

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
$areanames{en} = {"3534510", "Kildare",
"3535678", "Kilkenny",
"353626", "Cashel",
"35344", "Mullingar",
"353650", "Ennis\/Ennistymon\/Kilrush",
"35390", "Athlone\/Ballinasloe\/Portumna\/Roscommon",
"35398", "Westport",
"353646700", "Killarney",
"35325", "Fermoy",
"35361999", "Limerick\/Scariff",
"353469900", "Navan",
"3534497", "Castlepollard",
"353447", "Castlepollard",
"3534120", "Drogheda\/Ardee",
"3539097", "Portumna",
"353493", "Belturbet",
"3534699", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"35343666", "Granard",
"353471", "Monaghan\/Clones",
"353421", "Dundalk\/Carrickmacross\/Castleblaney",
"353448", "Tyrellspass",
"353479", "Monaghan",
"35343669", "Granard",
"3535987", "Athy",
"35357850", "Portlaoise",
"353474", "Clones",
"353424", "Carrickmacross",
"353461", "Navan",
"35374960", "Letterkenny",
"353514", "New\ Ross",
"3534799", "Monaghan\/Clones",
"3534299", "Dundalk\/Carrickmacross\/Castleblaney",
"35371", "Sligo\/Manorhamilton\/Carrick\-on\-Shannon",
"353464", "Trim",
"3539064", "Athlone",
"3535688", "Freshford",
"3534492", "Tyrellspass",
"353749888", "Letterkenny",
"353741", "Letterkenny",
"3534696", "Enfield",
"353710", "Sligo",
"353463", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"3534999", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"353579900", "Portlaoise",
"353531", "Wexford",
"3534296", "Carrickmacross",
"3535787", "Abbeyleix",
"353494", "Cavan",
"3536670", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353616", "Scariff",
"353499", "Belturbet",
"353539903", "Gorey",
"3537191", "Sligo",
"3535988", "Athy",
"353491", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"353658", "Kilrush",
"3537198", "Manorhamilton",
"353569900", "Kilkenny",
"35371930", "Sligo",
"353473", "Monaghan",
"353423", "Dundalk\/Carrickmacross\/Castleblaney",
"353719401", "Sligo",
"353455", "Kildare",
"353719335", "Sligo",
"3534491", "Tyrellspass",
"3534199", "Drogheda\/Ardee",
"353657", "Ennistymon",
"353749900", "Letterkenny",
"3534498", "Castlepollard",
"353539900", "Wexford",
"353719010", "Sligo",
"353571", "Portlaoise",
"3534495", "Castlepollard",
"353452", "Kildare",
"353912", "Gort",
"353749214", "Letterkenny",
"3535677", "Kilkenny",
"35394925", "Castlebar",
"353561", "Kilkenny",
"353900", "Athlone",
"3534330", "Longford",
"35363", "Rathluirc",
"353628", "Tipperary",
"353719331", "Sligo",
"353217", "Coachford",
"3536477", "Rathmore",
"353453", "The\ Curragh",
"3532147", "Kinsale",
"353949291", "Castlebar",
"3536692", "Dingle",
"35394", "Castlebar\/Claremorris\/Castlerea\/Ballinrobe",
"353432", "Longford",
"353668", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353719332", "Sligo",
"35321", "Cork",
"35367", "Nenagh",
"3535261", "Clonmel",
"3536697", "Killorglin",
"353462", "Kells",
"353531202", "Enniscorthy",
"353512", "Kilmacthomas",
"3534694", "Trim",
"353465", "Enfield",
"35329", "Kanturk",
"353949289", "Castlebar",
"353472", "Clones",
"353422", "Dundalk",
"35366", "Tralee",
"353475", "Clones",
"353425", "Castleblaney",
"3534294", "Dundalk",
"353218", "Cork\/Kinsale\/Coachford",
"3534367", "Granard",
"3535390", "Wexford",
"353627", "Cashel",
"3534368", "Granard",
"3534690", "Navan",
"353909902", "Ballinasloe",
"353495", "Cootehill",
"353909897", "Athlone",
"35322", "Mallow",
"35327", "Bantry",
"353492", "Cootehill",
"35358", "Dungarvan",
"353749210", "Letterkenny",
"3539066", "Roscommon",
"353620", "Tipperary\/Cashel",
"353909901", "Athlone",
"3535394", "Gorey",
"3534290", "Dundalk",
"3536691", "Dingle",
"35374989", "Letterkenny",
"3536698", "Killorglin",
"35369", "Newcastle\ West",
"3536693", "Dingle",
"353656", "Ennis",
"35326", "Macroom",
"3536695", "Cahirciveen",
"3539498", "Castlerea",
"3539493", "Claremorris",
"3539495", "Ballinrobe",
"353669100", "Killorglin",
"3535644", "Castlecomer",
"35323", "Bandon",
"35361", "Limerick",
"353459", "Naas",
"353454", "The\ Curragh",
"3532141", "Kinsale",
"353451", "Naas\/Kildare\/Curragh",
"35396", "Ballina",
"3534369", "Granard",
"353579901", "Portlaoise",
"3536299", "Tipperary",
"353624", "Tipperary",
"35397", "Belmullet",
"35371959", "Carrick\-on\-Shannon",
"353629", "Cashel",
"353949288", "Castlebar",
"353621", "Tipperary\/Cashel",
"3536699", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353569901", "Kilkenny",
"353516", "Carrick\-on\-Suir",
"353719344", "Sligo",
"353539901", "Wexford",
"353466", "Edenderry",
"35393", "Tuam",
"353450", "Naas\/Kildare\/Curragh",
"353404", "Wicklow",
"353539902", "Enniscorthy",
"353578510", "Portlaoise",
"353426", "Dundalk",
"353476", "Monaghan",
"35364", "Killarney\/Rathmore",
"3539496", "Castlerea",
"35391", "Galway",
"353496", "Cavan",
"353619", "Scariff",
"3534490", "Tyrellspass",
"353646701", "Killarney",
"353469901", "Navan",
"353652", "Ennis",
"35324", "Youghal",
"35371932", "Sligo",
"353457", "Naas",
"353655", "Ennis",
"3535274", "Cahir",
"353623", "Tipperary",
"35351999", "Waterford\/Carrick\-on\-Suir\/New\ Ross\/Kilmacthomas",
"353719334", "Sligo",
"353458", "Naas",
"353918", "Loughrea",
"35357859", "Portlaoise",
"35399", "Kilronan",
"353416", "Ardee",
"35390650", "Athlone",
"3536696", "Cahirciveen",
"35371931", "Sligo",
"353504", "Thurles",
"353949286", "Castlebar",
"353749212", "Letterkenny",
"353530", "Wexford",
"35351", "Waterford",
"353427", "Dundalk",
"353477", "Monaghan",
"353625", "Tipperary",
"3534297", "Castleblaney",
"3535786", "Portlaoise",
"353622", "Cashel",
"353740", "Letterkenny",
"353711", "Sligo",
"3535989", "Athy",
"353749211", "Letterkenny",
"353490", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"3536694", "Cahirciveen",
"3535391", "Wexford",
"353749889", "Letterkenny",
"353467", "Navan",
"3537495", "Dungloe",
"3537493", "Buncrana",
"353909900", "Athlone",
"3535393", "Ferns",
"3535964", "Baltinglass",
"3537491", "Letterkenny",
"353438", "Granard",
"3534697", "Edenderry",
"353570", "Portlaoise",
"353437", "Granard",
"3534333", "Longford",
"3534292", "Dundalk",
"353909903", "Ballinasloe",
"3534331", "Longford",
"353468", "Navan",
"353719900", "Sligo",
"353402", "Arklow",
"35359", "Carlow\/Muine\ Bheag\/Athy\/Baltinglass",
"3534499", "Mullingar\/Castlepollard\/Tyrrellspass",
"3534692", "Kells",
"3535291", "Killenaule",
"3535791", "Birr",
"353560", "Kilkenny",
"353901", "Athlone",
"3535793", "Tullamore",
"3535997", "Muine\ Bheag",
"35368", "Listowel",
"353653", "Ennis",
"353949285", "Castlebar",
"35343667", "Granard",
"353478", "Monaghan",
"353428", "Dundalk",
"35343", "Longford\/Granard",
"353469907", "Edenderry",
"353498", "Oldcastle",
"353651", "Ennis\/Ennistymon\/Kilrush",
"3539096", "Ballinasloe",
"35356", "Kilkenny\/Castlecomer\/Freshford",
"353719330", "Sligo",
"353443", "Mullingar\/Castlepollard\/Tyrrellspass",
"3539490", "Castlebar",
"35374920", "Letterkenny",
"353654", "Ennis",
"353531203", "Gorey",
"3535392", "Enniscorthy",
"3534496", "Castlepollard",
"35395", "Clifden",
"353949290", "Castlebar",
"35341", "Drogheda",
"353949287", "Castlebar",
"353659", "Kilrush",
"3535991", "Carlow",
"35328", "Skibbereen",
"35357", "Portlaoise\/Abbeyleix\/Tullamore\/Birr",
"35352", "Clonmel\/Cahir\/Killenaule",
"3536599", "Ennis\/Ennistymon\/Kilrush",
"3532140", "Kinsale",
"3531", "Dublin",
"353916", "Gort",
"3534695", "Enfield",
"3534693", "Kells",
"353456", "Naas",
"3534698", "Edenderry",
"3536466", "Killarney",
"3534691", "Navan",
"3537497", "Donegal",
"353420", "Dundalk\/Carrickmacross\/Castleblaney",
"353470", "Monaghan\/Clones",
"353505", "Roscrea",
"3534332", "Longford",
"35353", "Wexford\/Enniscorthy\/Ferns\/Gorey",
"3534298", "Castleblaney",
"3535986", "Athy",
"3534293", "Dundalk",
"3534295", "Carrickmacross",
"3537196", "Carrick\-on\-Shannon",
"353460", "Navan",
"35343668", "Granard",
"35374", "Letterkenny\/Donegal\/Dungloe\/Buncrana",
"353497", "Cavan",
"3536690", "Killorglin",
"3534791", "Monaghan\/Clones",
"3534291", "Dundalk",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+353|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;