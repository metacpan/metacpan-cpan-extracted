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
our $VERSION = 1.20220601185318;

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
$areanames{en} = {"35344", "Mullingar",
"35368", "Listowel",
"3534297", "Castleblaney",
"353475", "Clones",
"35357", "Portlaoise\/Abbeyleix\/Tullamore\/Birr",
"353561", "Kilkenny",
"3534292", "Dundalk",
"3535644", "Castlecomer",
"353491", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"353620", "Tipperary\/Cashel",
"353719335", "Sligo",
"353476", "Monaghan",
"353710", "Sligo",
"353218", "Cork\/Kinsale\/Coachford",
"353627", "Cashel",
"3534367", "Granard",
"353749214", "Letterkenny",
"353901", "Athlone",
"35393", "Tuam",
"353628", "Tipperary",
"353217", "Coachford",
"3535390", "Wexford",
"353426", "Dundalk",
"353619", "Scariff",
"3536299", "Tipperary",
"353579901", "Portlaoise",
"35361999", "Limerick\/Scariff",
"35352", "Clonmel\/Cahir\/Killenaule",
"353451", "Naas\/Kildare\/Curragh",
"353425", "Castleblaney",
"3535274", "Cahir",
"353719331", "Sligo",
"3535987", "Athy",
"353539902", "Enniscorthy",
"3534496", "Castlepollard",
"3535394", "Gorey",
"35329", "Kanturk",
"3534295", "Carrickmacross",
"353478", "Monaghan",
"353531", "Wexford",
"3534369", "Granard",
"35391", "Galway",
"353420", "Dundalk\/Carrickmacross\/Castleblaney",
"353719334", "Sligo",
"3539066", "Roscommon",
"353477", "Monaghan",
"353741", "Letterkenny",
"353464", "Trim",
"353749889", "Letterkenny",
"35371930", "Sligo",
"353909902", "Ballinasloe",
"3535989", "Athy",
"353749211", "Letterkenny",
"3532147", "Kinsale",
"3535261", "Clonmel",
"3534799", "Monaghan\/Clones",
"35364", "Killarney\/Rathmore",
"353949287", "Castlebar",
"35357850", "Portlaoise",
"35374920", "Letterkenny",
"353463", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"3531", "Dublin",
"353651", "Ennis\/Ennistymon\/Kilrush",
"353625", "Tipperary",
"35396", "Ballina",
"3534299", "Dundalk\/Carrickmacross\/Castleblaney",
"353469907", "Edenderry",
"353626", "Cashel",
"353428", "Dundalk",
"3537493", "Buncrana",
"3535391", "Wexford",
"353469900", "Navan",
"353470", "Monaghan\/Clones",
"353912", "Gort",
"3535393", "Ferns",
"353427", "Dundalk",
"35325", "Fermoy",
"3537491", "Letterkenny",
"35343668", "Granard",
"353949291", "Castlebar",
"353569901", "Kilkenny",
"3534697", "Edenderry",
"3534491", "Tyrellspass",
"3535678", "Kilkenny",
"353416", "Ardee",
"3535791", "Birr",
"353492", "Cootehill",
"3534498", "Castlepollard",
"3534692", "Kells",
"3534120", "Drogheda\/Ardee",
"3536466", "Killarney",
"3535688", "Freshford",
"3535786", "Portlaoise",
"3535793", "Tullamore",
"3535997", "Muine\ Bheag",
"353624", "Tipperary",
"353629", "Cashel",
"35390", "Athlone\/Ballinasloe\/Portumna\/Roscommon",
"35351", "Waterford",
"353909903", "Ballinasloe",
"3536695", "Cahirciveen",
"353719900", "Sligo",
"3539096", "Ballinasloe",
"353512", "Kilmacthomas",
"35394925", "Castlebar",
"35390650", "Athlone",
"35328", "Skibbereen",
"353749212", "Letterkenny",
"353909901", "Athlone",
"3539495", "Ballinrobe",
"353668", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353466", "Edenderry",
"353438", "Granard",
"3536699", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"35356", "Kilkenny\/Castlecomer\/Freshford",
"353465", "Enfield",
"3535291", "Killenaule",
"353571", "Portlaoise",
"353719401", "Sligo",
"353452", "Kildare",
"353623", "Tipperary",
"35371931", "Sligo",
"35371959", "Carrick\-on\-Shannon",
"353437", "Granard",
"353404", "Wicklow",
"3539064", "Athlone",
"3534695", "Enfield",
"353539901", "Wexford",
"353719332", "Sligo",
"353719344", "Sligo",
"3534199", "Drogheda\/Ardee",
"353460", "Navan",
"353424", "Carrickmacross",
"353473", "Monaghan",
"3536692", "Dingle",
"35374989", "Letterkenny",
"353616", "Scariff",
"3534490", "Tyrellspass",
"3536697", "Killorglin",
"35397", "Belmullet",
"353949289", "Castlebar",
"35369", "Newcastle\ West",
"353652", "Ennis",
"353423", "Dundalk\/Carrickmacross\/Castleblaney",
"3534332", "Longford",
"353646701", "Killarney",
"3534699", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"353468", "Navan",
"353479", "Monaghan",
"35353", "Wexford\/Enniscorthy\/Ferns\/Gorey",
"353539903", "Gorey",
"35324", "Youghal",
"353467", "Navan",
"35374", "Letterkenny\/Donegal\/Dungloe\/Buncrana",
"353474", "Clones",
"353539900", "Wexford",
"3534691", "Navan",
"3534497", "Castlepollard",
"3535986", "Athy",
"3536690", "Killorglin",
"353949286", "Castlebar",
"3534492", "Tyrellspass",
"3534698", "Edenderry",
"3534693", "Kells",
"353749900", "Letterkenny",
"3535991", "Carlow",
"3535677", "Kilkenny",
"353472", "Clones",
"353654", "Ennis",
"353659", "Kilrush",
"3534510", "Kildare",
"353531202", "Enniscorthy",
"353646700", "Killarney",
"353461", "Navan",
"3534694", "Trim",
"353918", "Loughrea",
"3539490", "Castlebar",
"3534330", "Longford",
"35323", "Bandon",
"3534296", "Carrickmacross",
"353653", "Ennis",
"353422", "Dundalk",
"3534495", "Castlepollard",
"353569900", "Kilkenny",
"353949290", "Castlebar",
"353459", "Naas",
"35371932", "Sligo",
"353454", "The\ Curragh",
"353570", "Portlaoise",
"353402", "Arklow",
"353514", "New\ Ross",
"35374960", "Letterkenny",
"35321", "Cork",
"35399", "Kilronan",
"35371", "Sligo\/Manorhamilton\/Carrick\-on\-Shannon",
"3536693", "Dingle",
"3536698", "Killorglin",
"35343667", "Granard",
"3534690", "Navan",
"3536691", "Dingle",
"35351999", "Waterford\/Carrick\-on\-Suir\/New\ Ross\/Kilmacthomas",
"35357859", "Portlaoise",
"353493", "Belturbet",
"353949288", "Castlebar",
"3534331", "Longford",
"353622", "Cashel",
"353453", "The\ Curragh",
"3539498", "Castlerea",
"3539493", "Claremorris",
"3537196", "Carrick\-on\-Shannon",
"353909900", "Athlone",
"353916", "Gort",
"35395", "Clifden",
"3534333", "Longford",
"3536694", "Cahirciveen",
"35358", "Dungarvan",
"3534499", "Mullingar\/Castlepollard\/Tyrrellspass",
"35367", "Nenagh",
"353448", "Tyrellspass",
"353505", "Roscrea",
"353494", "Cavan",
"35326", "Macroom",
"353499", "Belturbet",
"353447", "Castlepollard",
"353471", "Monaghan\/Clones",
"3534291", "Dundalk",
"3532140", "Kinsale",
"35343666", "Granard",
"3534293", "Dundalk",
"353504", "Thurles",
"3534298", "Castleblaney",
"35359", "Carlow\/Muine\ Bheag\/Athy\/Baltinglass",
"353495", "Cootehill",
"353650", "Ennis\/Ennistymon\/Kilrush",
"353496", "Cavan",
"353949285", "Castlebar",
"353749210", "Letterkenny",
"3539097", "Portumna",
"353578510", "Portlaoise",
"35363", "Rathluirc",
"3534368", "Granard",
"353657", "Ennistymon",
"353456", "Naas",
"35341", "Drogheda",
"353658", "Kilrush",
"353909897", "Athlone",
"353516", "Carrick\-on\-Suir",
"3535787", "Abbeyleix",
"35398", "Westport",
"3535988", "Athy",
"353421", "Dundalk\/Carrickmacross\/Castleblaney",
"3534791", "Monaghan\/Clones",
"353455", "Kildare",
"353740", "Letterkenny",
"3536599", "Ennis\/Ennistymon\/Kilrush",
"3534294", "Dundalk",
"353469901", "Navan",
"35343669", "Granard",
"353530", "Wexford",
"3537495", "Dungloe",
"3536670", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353462", "Kells",
"3534696", "Enfield",
"35343", "Longford\/Granard",
"353497", "Cavan",
"353669100", "Killorglin",
"35327", "Bantry",
"353498", "Oldcastle",
"353450", "Naas\/Kildare\/Curragh",
"3535964", "Baltinglass",
"3539496", "Castlerea",
"3534999", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"3537191", "Sligo",
"353900", "Athlone",
"3532141", "Kinsale",
"3534290", "Dundalk",
"3537198", "Manorhamilton",
"35366", "Tralee",
"3536696", "Cahirciveen",
"353719010", "Sligo",
"353711", "Sligo",
"3536477", "Rathmore",
"353443", "Mullingar\/Castlepollard\/Tyrrellspass",
"353531203", "Gorey",
"35394", "Castlebar\/Claremorris\/Castlerea\/Ballinrobe",
"353621", "Tipperary\/Cashel",
"353655", "Ennis",
"353749888", "Letterkenny",
"353490", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"353579900", "Portlaoise",
"35361", "Limerick",
"353458", "Naas",
"353656", "Ennis",
"35322", "Mallow",
"353719330", "Sligo",
"353457", "Naas",
"3535392", "Enniscorthy",
"353560", "Kilkenny",
"353432", "Longford",
"3537497", "Donegal",};

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