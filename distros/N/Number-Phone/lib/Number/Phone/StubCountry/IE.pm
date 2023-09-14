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
our $VERSION = 1.20230903131447;

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
$areanames{en} = {"3535989", "Athy",
"353657", "Ennistymon",
"3535644", "Castlecomer",
"35359", "Carlow\/Muine\ Bheag\/Athy\/Baltinglass",
"3534290", "Dundalk",
"3535786", "Portlaoise",
"353496", "Cavan",
"353624", "Tipperary",
"3534333", "Longford",
"35325", "Fermoy",
"353629", "Cashel",
"353619", "Scariff",
"353916", "Gort",
"3535678", "Kilkenny",
"35361999", "Limerick\/Scariff",
"353949289", "Castlebar",
"353668", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353404", "Wicklow",
"353719332", "Sligo",
"3534297", "Castleblaney",
"353432", "Longford",
"35363", "Rathluirc",
"353653", "Ennis",
"3534510", "Kildare",
"3534699", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"3535261", "Clonmel",
"353516", "Carrick\-on\-Suir",
"353539902", "Enniscorthy",
"353622", "Cashel",
"353749214", "Letterkenny",
"35341", "Drogheda",
"353448", "Tyrellspass",
"353651", "Ennis\/Ennistymon\/Kilrush",
"353570", "Portlaoise",
"35327", "Bantry",
"353909902", "Ballinasloe",
"3535997", "Muine\ Bheag",
"3534120", "Drogheda\/Ardee",
"353711", "Sligo",
"353561", "Kilkenny",
"35399", "Kilronan",
"353402", "Arklow",
"35357859", "Portlaoise",
"3539096", "Ballinasloe",
"3536692", "Dingle",
"353467", "Navan",
"353455", "Kildare",
"3534693", "Kells",
"3536670", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353504", "Thurles",
"3534694", "Trim",
"3534367", "Granard",
"353669100", "Killorglin",
"353458", "Naas",
"35357850", "Portlaoise",
"35391", "Galway",
"353450", "Naas\/Kildare\/Curragh",
"3534695", "Enfield",
"353749889", "Letterkenny",
"3536599", "Ennis\/Ennistymon\/Kilrush",
"35351", "Waterford",
"353463", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"353218", "Cork\/Kinsale\/Coachford",
"35352", "Clonmel\/Cahir\/Killenaule",
"353949286", "Castlebar",
"3534492", "Tyrellspass",
"353949285", "Castlebar",
"353416", "Ardee",
"353475", "Clones",
"3535391", "Wexford",
"353426", "Dundalk",
"3537491", "Letterkenny",
"353461", "Navan",
"353470", "Monaghan\/Clones",
"35324", "Youghal",
"353478", "Monaghan",
"353490", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"3532147", "Kinsale",
"353498", "Oldcastle",
"353909903", "Ballinasloe",
"35394", "Castlebar\/Claremorris\/Castlerea\/Ballinrobe",
"353621", "Tipperary\/Cashel",
"353437", "Granard",
"353749212", "Letterkenny",
"353652", "Ennis",
"3537196", "Carrick\-on\-Shannon",
"35368", "Listowel",
"353918", "Loughrea",
"353495", "Cootehill",
"353539903", "Gorey",
"353623", "Tipperary",
"3532140", "Kinsale",
"35374960", "Letterkenny",
"353719334", "Sligo",
"3539490", "Castlebar",
"35374989", "Letterkenny",
"3537191", "Sligo",
"35322", "Mallow",
"3534331", "Longford",
"353659", "Kilrush",
"35321", "Cork",
"3537198", "Manorhamilton",
"353654", "Ennis",
"353579901", "Portlaoise",
"353579900", "Portlaoise",
"3534292", "Dundalk",
"353627", "Cashel",
"3537495", "Dungloe",
"35397", "Belmullet",
"3534497", "Castlepollard",
"35329", "Kanturk",
"3535393", "Ferns",
"3537493", "Buncrana",
"35371959", "Carrick\-on\-Shannon",
"35343668", "Granard",
"3535394", "Gorey",
"35366", "Tralee",
"3534490", "Tyrellspass",
"353462", "Kells",
"353456", "Naas",
"3535988", "Athy",
"3534696", "Enfield",
"3536299", "Tipperary",
"35343666", "Granard",
"35371930", "Sligo",
"35395", "Clifden",
"353428", "Dundalk",
"3536697", "Killorglin",
"353420", "Dundalk\/Carrickmacross\/Castleblaney",
"353901", "Athlone",
"353741", "Letterkenny",
"3534691", "Navan",
"353425", "Castleblaney",
"353476", "Monaghan",
"353531", "Wexford",
"353578510", "Portlaoise",
"353464", "Trim",
"3536690", "Killorglin",
"35344", "Mullingar",
"35357", "Portlaoise\/Abbeyleix\/Tullamore\/Birr",
"353949287", "Castlebar",
"3535964", "Baltinglass",
"3535986", "Athy",
"3534698", "Edenderry",
"353499", "Belturbet",
"3534495", "Castlepollard",
"3535390", "Wexford",
"3539097", "Portumna",
"3537497", "Donegal",
"3536477", "Rathmore",
"3535793", "Tullamore",
"35390650", "Athlone",
"353512", "Kilmacthomas",
"35393", "Tuam",
"353626", "Cashel",
"353494", "Cavan",
"353447", "Castlepollard",
"353616", "Scariff",
"353531203", "Gorey",
"35326", "Macroom",
"353710", "Sligo",
"353560", "Kilkenny",
"3536694", "Cahirciveen",
"35351999", "Waterford\/Carrick\-on\-Suir\/New\ Ross\/Kilmacthomas",
"35353", "Wexford\/Enniscorthy\/Ferns\/Gorey",
"353571", "Portlaoise",
"353650", "Ennis\/Ennistymon\/Kilrush",
"353912", "Gort",
"3536695", "Cahirciveen",
"353658", "Kilrush",
"3535291", "Killenaule",
"3534692", "Kells",
"3534799", "Monaghan\/Clones",
"3535688", "Freshford",
"353514", "New\ Ross",
"35390", "Athlone\/Ballinasloe\/Portumna\/Roscommon",
"35374", "Letterkenny\/Donegal\/Dungloe\/Buncrana",
"35369", "Newcastle\ West",
"3535274", "Cahir",
"353492", "Cootehill",
"353443", "Mullingar\/Castlepollard\/Tyrrellspass",
"3536693", "Dingle",
"35394925", "Castlebar",
"353655", "Ennis",
"3534368", "Granard",
"353451", "Naas\/Kildare\/Curragh",
"353217", "Coachford",
"3535787", "Abbeyleix",
"3539066", "Roscommon",
"3535991", "Carlow",
"353719330", "Sligo",
"3534296", "Carrickmacross",
"353477", "Monaghan",
"3536699", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353453", "The\ Curragh",
"35361", "Limerick",
"353719331", "Sligo",
"353422", "Dundalk",
"3539493", "Claremorris",
"3534291", "Dundalk",
"35328", "Skibbereen",
"353539900", "Wexford",
"353471", "Monaghan\/Clones",
"353539901", "Wexford",
"353468", "Navan",
"35343", "Longford\/Granard",
"35371931", "Sligo",
"353460", "Navan",
"3534332", "Longford",
"353473", "Monaghan",
"35374920", "Letterkenny",
"3535677", "Kilkenny",
"3531", "Dublin",
"3539495", "Ballinrobe",
"353909901", "Athlone",
"3534298", "Castleblaney",
"353646700", "Killarney",
"353457", "Naas",
"353909900", "Athlone",
"353749900", "Letterkenny",
"353465", "Enfield",
"353646701", "Killarney",
"3534499", "Mullingar\/Castlepollard\/Tyrrellspass",
"353424", "Carrickmacross",
"3534496", "Castlepollard",
"353625", "Tipperary",
"3536698", "Killorglin",
"353493", "Belturbet",
"3534690", "Navan",
"35364", "Killarney\/Rathmore",
"353909897", "Athlone",
"353620", "Tipperary\/Cashel",
"35398", "Westport",
"353628", "Tipperary",
"3534697", "Edenderry",
"353949288", "Castlebar",
"353491", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"35371932", "Sligo",
"3536691", "Dingle",
"353569901", "Kilkenny",
"353719344", "Sligo",
"353438", "Granard",
"353656", "Ennis",
"353531202", "Enniscorthy",
"3534498", "Castlepollard",
"353497", "Cavan",
"3534199", "Drogheda\/Ardee",
"353719900", "Sligo",
"35358", "Dungarvan",
"3536696", "Cahirciveen",
"353569900", "Kilkenny",
"3534299", "Dundalk\/Carrickmacross\/Castleblaney",
"3534491", "Tyrellspass",
"3535987", "Athy",
"3535791", "Birr",
"3535392", "Enniscorthy",
"353719010", "Sligo",
"3534293", "Dundalk",
"35367", "Nenagh",
"353472", "Clones",
"3539064", "Athlone",
"353949290", "Castlebar",
"353454", "The\ Curragh",
"353949291", "Castlebar",
"3534999", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"3534330", "Longford",
"353427", "Dundalk",
"35396", "Ballina",
"353719401", "Sligo",
"353749211", "Letterkenny",
"353469907", "Edenderry",
"3539498", "Castlerea",
"3534295", "Carrickmacross",
"35343669", "Granard",
"353749210", "Letterkenny",
"353459", "Naas",
"353505", "Roscrea",
"3534294", "Dundalk",
"353469900", "Navan",
"353474", "Clones",
"353749888", "Letterkenny",
"353452", "Kildare",
"3534369", "Granard",
"353466", "Edenderry",
"353530", "Wexford",
"35323", "Bandon",
"353469901", "Navan",
"35371", "Sligo\/Manorhamilton\/Carrick\-on\-Shannon",
"353423", "Dundalk\/Carrickmacross\/Castleblaney",
"35356", "Kilkenny\/Castlecomer\/Freshford",
"3539496", "Castlerea",
"353719335", "Sligo",
"353740", "Letterkenny",
"353900", "Athlone",
"353421", "Dundalk\/Carrickmacross\/Castleblaney",
"353479", "Monaghan",
"3532141", "Kinsale",
"3536466", "Killarney",
"3534791", "Monaghan\/Clones",
"35343667", "Granard",};

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