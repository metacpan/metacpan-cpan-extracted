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
our $VERSION = 1.20230307181420;

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
$areanames{en} = {"353909901", "Athlone",
"353909900", "Athlone",
"353495", "Cootehill",
"353626", "Cashel",
"353474", "Clones",
"353719401", "Sligo",
"353749888", "Letterkenny",
"3534199", "Drogheda\/Ardee",
"3534295", "Carrickmacross",
"353465", "Enfield",
"3532141", "Kinsale",
"353749889", "Letterkenny",
"3539498", "Castlerea",
"3534368", "Granard",
"3534120", "Drogheda\/Ardee",
"35363", "Rathluirc",
"35327", "Bantry",
"3536699", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"3532140", "Kinsale",
"35394", "Castlebar\/Claremorris\/Castlerea\/Ballinrobe",
"353909902", "Ballinasloe",
"353569901", "Kilkenny",
"353569900", "Kilkenny",
"3534495", "Castlepollard",
"353655", "Ennis",
"353472", "Clones",
"3534293", "Dundalk",
"35353", "Wexford\/Enniscorthy\/Ferns\/Gorey",
"35374920", "Letterkenny",
"3534697", "Edenderry",
"353476", "Monaghan",
"353650", "Ennis\/Ennistymon\/Kilrush",
"353461", "Navan",
"353624", "Tipperary",
"353493", "Belturbet",
"3534690", "Navan",
"35343666", "Granard",
"35352", "Clonmel\/Cahir\/Killenaule",
"3534696", "Enfield",
"3539066", "Roscommon",
"353668", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"3534330", "Longford",
"353491", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"353463", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"353217", "Coachford",
"353218", "Cork\/Kinsale\/Coachford",
"353749900", "Letterkenny",
"35374989", "Letterkenny",
"35390650", "Athlone",
"3532147", "Kinsale",
"353460", "Navan",
"3536477", "Rathmore",
"353651", "Ennis\/Ennistymon\/Kilrush",
"3535793", "Tullamore",
"353949290", "Castlebar",
"353949291", "Castlebar",
"353457", "Naas",
"353458", "Naas",
"3534331", "Longford",
"353490", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"3534294", "Dundalk",
"35364", "Killarney\/Rathmore",
"3535392", "Enniscorthy",
"3534691", "Navan",
"353622", "Cashel",
"353653", "Ennis",
"35343667", "Granard",
"35393", "Tuam",
"35326", "Macroom",
"35358", "Dungarvan",
"353654", "Ennis",
"3534698", "Edenderry",
"353620", "Tipperary\/Cashel",
"353447", "Castlepollard",
"353579901", "Portlaoise",
"353579900", "Portlaoise",
"35351", "Waterford",
"353448", "Tyrellspass",
"353749212", "Letterkenny",
"353492", "Cootehill",
"3535291", "Killenaule",
"35374960", "Letterkenny",
"353909903", "Ballinasloe",
"35329", "Kanturk",
"3536694", "Cahirciveen",
"35361", "Limerick",
"353916", "Gort",
"3534367", "Granard",
"353514", "New\ Ross",
"353462", "Kells",
"3537495", "Dungloe",
"35368", "Listowel",
"353464", "Trim",
"353621", "Tipperary\/Cashel",
"353749210", "Letterkenny",
"353749211", "Letterkenny",
"35371932", "Sligo",
"35351999", "Waterford\/Carrick\-on\-Suir\/New\ Ross\/Kilmacthomas",
"353512", "Kilmacthomas",
"353428", "Dundalk",
"35343668", "Granard",
"353427", "Dundalk",
"353494", "Cavan",
"35394925", "Castlebar",
"3537493", "Buncrana",
"353475", "Clones",
"353719900", "Sligo",
"353652", "Ennis",
"35361999", "Limerick\/Scariff",
"3535989", "Athy",
"353623", "Tipperary",
"3535390", "Wexford",
"353656", "Ennis",
"353616", "Scariff",
"353470", "Monaghan\/Clones",
"35398", "Westport",
"353404", "Wicklow",
"35395", "Clifden",
"353749214", "Letterkenny",
"353531", "Wexford",
"3534299", "Dundalk\/Carrickmacross\/Castleblaney",
"35391", "Galway",
"353719344", "Sligo",
"3539496", "Castlerea",
"3534791", "Monaghan\/Clones",
"35371931", "Sligo",
"3539490", "Castlebar",
"353438", "Granard",
"353437", "Granard",
"3536693", "Dingle",
"353516", "Carrick\-on\-Suir",
"353912", "Gort",
"353471", "Monaghan\/Clones",
"353466", "Edenderry",
"3534332", "Longford",
"353530", "Wexford",
"3534499", "Mullingar\/Castlepollard\/Tyrrellspass",
"353459", "Naas",
"353719010", "Sligo",
"353625", "Tipperary",
"353496", "Cavan",
"353402", "Arklow",
"3536695", "Cahirciveen",
"3535391", "Wexford",
"353473", "Monaghan",
"3534510", "Kildare",
"3534692", "Kells",
"3536670", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353531202", "Enniscorthy",
"353646700", "Killarney",
"353646701", "Killarney",
"353504", "Thurles",
"353469907", "Edenderry",
"3534297", "Castleblaney",
"353570", "Portlaoise",
"3535986", "Athy",
"35374", "Letterkenny\/Donegal\/Dungloe\/Buncrana",
"3534693", "Kells",
"353456", "Naas",
"353416", "Ardee",
"3537196", "Carrick\-on\-Shannon",
"3534333", "Longford",
"353499", "Belturbet",
"35371959", "Carrick\-on\-Shannon",
"353711", "Sligo",
"3535791", "Birr",
"3536299", "Tipperary",
"353619", "Scariff",
"353659", "Kilrush",
"353425", "Castleblaney",
"3534695", "Enfield",
"3535274", "Cahir",
"35399", "Kilronan",
"3534497", "Castlepollard",
"3535644", "Castlecomer",
"3537191", "Sligo",
"353571", "Portlaoise",
"3536692", "Dingle",
"35371930", "Sligo",
"353578510", "Portlaoise",
"35396", "Ballina",
"353477", "Monaghan",
"353478", "Monaghan",
"353949285", "Castlebar",
"353710", "Sligo",
"3534291", "Dundalk",
"3539064", "Athlone",
"3534694", "Trim",
"353949289", "Castlebar",
"35341", "Drogheda",
"353539902", "Enniscorthy",
"353443", "Mullingar\/Castlepollard\/Tyrrellspass",
"35390", "Athlone\/Ballinasloe\/Portumna\/Roscommon",
"353949288", "Castlebar",
"353454", "The\ Curragh",
"3536698", "Killorglin",
"353420", "Dundalk\/Carrickmacross\/Castleblaney",
"3534496", "Castlepollard",
"3534369", "Granard",
"3534799", "Monaghan\/Clones",
"3534490", "Tyrellspass",
"35366", "Tralee",
"3534491", "Tyrellspass",
"353539900", "Wexford",
"353539901", "Wexford",
"353452", "Kildare",
"3535677", "Kilkenny",
"3536466", "Killarney",
"35359", "Carlow\/Muine\ Bheag\/Athy\/Baltinglass",
"3535261", "Clonmel",
"353423", "Dundalk\/Carrickmacross\/Castleblaney",
"353421", "Dundalk\/Carrickmacross\/Castleblaney",
"35369", "Newcastle\ West",
"35321", "Cork",
"35325", "Fermoy",
"353628", "Tipperary",
"3535964", "Baltinglass",
"3535987", "Athy",
"3534296", "Carrickmacross",
"353627", "Cashel",
"35328", "Skibbereen",
"35356", "Kilkenny\/Castlecomer\/Freshford",
"3534290", "Dundalk",
"353900", "Athlone",
"3535393", "Ferns",
"353909897", "Athlone",
"3537497", "Donegal",
"353561", "Kilkenny",
"353497", "Cavan",
"353949286", "Castlebar",
"35343669", "Granard",
"353498", "Oldcastle",
"3534498", "Castlepollard",
"3539493", "Claremorris",
"353450", "Naas\/Kildare\/Curragh",
"353424", "Carrickmacross",
"35324", "Youghal",
"3536690", "Killorglin",
"35397", "Belmullet",
"353467", "Navan",
"3536696", "Cahirciveen",
"353468", "Navan",
"353479", "Monaghan",
"35344", "Mullingar",
"3536691", "Dingle",
"353949287", "Castlebar",
"353901", "Athlone",
"353719334", "Sligo",
"3535991", "Carlow",
"353422", "Dundalk",
"3539096", "Ballinasloe",
"353453", "The\ Curragh",
"353560", "Kilkenny",
"35357850", "Portlaoise",
"35357859", "Portlaoise",
"3534298", "Castleblaney",
"353451", "Naas\/Kildare\/Curragh",
"35322", "Mallow",
"353719335", "Sligo",
"353505", "Roscrea",
"3539495", "Ballinrobe",
"353657", "Ennistymon",
"353658", "Kilrush",
"353669100", "Killorglin",
"3535786", "Portlaoise",
"353531203", "Gorey",
"3535988", "Athy",
"35367", "Nenagh",
"35323", "Bandon",
"3534292", "Dundalk",
"3535394", "Gorey",
"3537491", "Letterkenny",
"3535787", "Abbeyleix",
"353719331", "Sligo",
"353719330", "Sligo",
"3535678", "Kilkenny",
"353426", "Dundalk",
"3535688", "Freshford",
"353740", "Letterkenny",
"35357", "Portlaoise\/Abbeyleix\/Tullamore\/Birr",
"353432", "Longford",
"3536599", "Ennis\/Ennistymon\/Kilrush",
"3537198", "Manorhamilton",
"3539097", "Portumna",
"353629", "Cashel",
"353918", "Loughrea",
"353719332", "Sligo",
"353469901", "Navan",
"3535997", "Muine\ Bheag",
"353469900", "Navan",
"353455", "Kildare",
"3534999", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"3534492", "Tyrellspass",
"35371", "Sligo\/Manorhamilton\/Carrick\-on\-Shannon",
"3531", "Dublin",
"3536697", "Killorglin",
"35343", "Longford\/Granard",
"353539903", "Gorey",
"3534699", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"353741", "Letterkenny",};

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