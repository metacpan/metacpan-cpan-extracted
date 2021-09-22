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
our $VERSION = 1.20210921211832;

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
$areanames{en} = {"353496", "Cavan",
"3539493", "Claremorris",
"353749889", "Letterkenny",
"353477", "Monaghan",
"35374960", "Letterkenny",
"3536670", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"35326", "Macroom",
"353900", "Athlone",
"353909902", "Ballinasloe",
"353479", "Monaghan",
"3534690", "Navan",
"35323", "Bandon",
"3534691", "Navan",
"3535261", "Clonmel",
"3536690", "Killorglin",
"353719344", "Sligo",
"353463", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"3536691", "Dingle",
"3534120", "Drogheda\/Ardee",
"3536466", "Killarney",
"3535678", "Kilkenny",
"3534799", "Monaghan\/Clones",
"3534294", "Dundalk",
"353504", "Thurles",
"353909900", "Athlone",
"353505", "Roscrea",
"35357859", "Portlaoise",
"3534695", "Enfield",
"353471", "Monaghan\/Clones",
"353711", "Sligo",
"35344", "Mullingar",
"3535677", "Kilkenny",
"3536695", "Cahirciveen",
"35364", "Killarney\/Rathmore",
"3535793", "Tullamore",
"353719334", "Sligo",
"353653", "Ennis",
"35351", "Waterford",
"35363", "Rathluirc",
"3534694", "Trim",
"3534368", "Granard",
"3532140", "Kinsale",
"3532141", "Kinsale",
"353539900", "Wexford",
"353453", "The\ Curragh",
"35343", "Longford\/Granard",
"3537493", "Buncrana",
"3536694", "Cahirciveen",
"353749214", "Letterkenny",
"353492", "Cootehill",
"3534367", "Granard",
"3539096", "Ballinasloe",
"3539097", "Portumna",
"3534495", "Castlepollard",
"3534295", "Carrickmacross",
"35325", "Fermoy",
"35366", "Tralee",
"353646701", "Killarney",
"3535644", "Castlecomer",
"3539064", "Athlone",
"353569900", "Kilkenny",
"3534510", "Kildare",
"353530", "Wexford",
"35398", "Westport",
"35394925", "Castlebar",
"3535988", "Athy",
"35322", "Mallow",
"35324", "Youghal",
"353623", "Tipperary",
"3534291", "Dundalk",
"3535986", "Athy",
"3534491", "Tyrellspass",
"35343667", "Granard",
"3534290", "Dundalk",
"353218", "Cork\/Kinsale\/Coachford",
"3531", "Dublin",
"3534490", "Tyrellspass",
"353494", "Cavan",
"3535987", "Athy",
"35399", "Kilronan",
"353423", "Dundalk\/Carrickmacross\/Castleblaney",
"353443", "Mullingar\/Castlepollard\/Tyrrellspass",
"35343669", "Granard",
"353560", "Kilkenny",
"353539902", "Enniscorthy",
"353495", "Cootehill",
"35367", "Nenagh",
"353657", "Ennistymon",
"353469901", "Navan",
"353579900", "Portlaoise",
"353621", "Tipperary\/Cashel",
"35371", "Sligo\/Manorhamilton\/Carrick\-on\-Shannon",
"353457", "Naas",
"353421", "Dundalk\/Carrickmacross\/Castleblaney",
"3537497", "Donegal",
"3536299", "Tipperary",
"353659", "Kilrush",
"3534299", "Dundalk\/Carrickmacross\/Castleblaney",
"3534499", "Mullingar\/Castlepollard\/Tyrrellspass",
"3535392", "Enniscorthy",
"35357850", "Portlaoise",
"353459", "Naas",
"353498", "Oldcastle",
"353570", "Portlaoise",
"3536599", "Ennis\/Ennistymon\/Kilrush",
"353629", "Cashel",
"35374920", "Letterkenny",
"353531203", "Gorey",
"35390650", "Athlone",
"353719331", "Sligo",
"353416", "Ardee",
"35374989", "Letterkenny",
"353627", "Cashel",
"353651", "Ennis\/Ennistymon\/Kilrush",
"3535991", "Carlow",
"353949291", "Castlebar",
"353616", "Scariff",
"353427", "Dundalk",
"353447", "Castlepollard",
"353451", "Naas\/Kildare\/Curragh",
"353749211", "Letterkenny",
"35351999", "Waterford\/Carrick\-on\-Suir\/New\ Ross\/Kilmacthomas",
"35371959", "Carrick\-on\-Shannon",
"353437", "Granard",
"353473", "Monaghan",
"35391", "Galway",
"3539496", "Castlerea",
"353719335", "Sligo",
"3537191", "Sligo",
"3534791", "Monaghan\/Clones",
"3539498", "Castlerea",
"35327", "Bantry",
"353740", "Letterkenny",
"3534331", "Longford",
"353490", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"3534330", "Longford",
"353467", "Navan",
"353949287", "Castlebar",
"35358", "Dungarvan",
"353719401", "Sligo",
"353461", "Navan",
"35359", "Carlow\/Muine\ Bheag\/Athy\/Baltinglass",
"353749900", "Letterkenny",
"3536699", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"3535393", "Ferns",
"3534699", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"353949289", "Castlebar",
"353474", "Clones",
"353749888", "Letterkenny",
"3535787", "Abbeyleix",
"3535390", "Wexford",
"35397", "Belmullet",
"3535391", "Wexford",
"353949286", "Castlebar",
"3535786", "Portlaoise",
"35343666", "Granard",
"353475", "Clones",
"35321", "Cork",
"35343668", "Granard",
"353420", "Dundalk\/Carrickmacross\/Castleblaney",
"353749210", "Letterkenny",
"353402", "Arklow",
"353620", "Tipperary\/Cashel",
"353450", "Naas\/Kildare\/Curragh",
"3536696", "Cahirciveen",
"35371931", "Sligo",
"3536697", "Killorglin",
"353578510", "Portlaoise",
"3534333", "Longford",
"353749212", "Letterkenny",
"353650", "Ennis\/Ennistymon\/Kilrush",
"353438", "Granard",
"353531202", "Enniscorthy",
"353404", "Wicklow",
"3534696", "Enfield",
"35390", "Athlone\/Ballinasloe\/Portumna\/Roscommon",
"3534697", "Edenderry",
"353468", "Navan",
"3539066", "Roscommon",
"3536698", "Killorglin",
"35352", "Clonmel\/Cahir\/Killenaule",
"353668", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353472", "Clones",
"353916", "Gort",
"353571", "Portlaoise",
"3535274", "Cahir",
"3534698", "Edenderry",
"353491", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"35361", "Limerick",
"35353", "Wexford\/Enniscorthy\/Ferns\/Gorey",
"3534332", "Longford",
"3534497", "Castlepollard",
"3534297", "Castleblaney",
"353741", "Letterkenny",
"3534296", "Carrickmacross",
"3534496", "Castlepollard",
"35341", "Drogheda",
"3534999", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"353469900", "Navan",
"3536477", "Rathmore",
"353579901", "Portlaoise",
"353428", "Dundalk",
"3535394", "Gorey",
"353448", "Tyrellspass",
"353719332", "Sligo",
"3534298", "Castleblaney",
"3534498", "Castlepollard",
"353628", "Tipperary",
"35356", "Kilkenny\/Castlecomer\/Freshford",
"353719330", "Sligo",
"353458", "Naas",
"353499", "Belturbet",
"353949290", "Castlebar",
"353658", "Kilrush",
"353497", "Cavan",
"353476", "Monaghan",
"353912", "Gort",
"353460", "Navan",
"3535291", "Killenaule",
"3532147", "Kinsale",
"3536692", "Dingle",
"3534369", "Granard",
"35357", "Portlaoise\/Abbeyleix\/Tullamore\/Birr",
"353654", "Ennis",
"353422", "Dundalk",
"3535964", "Baltinglass",
"353455", "Kildare",
"3534692", "Kells",
"353719900", "Sligo",
"353646700", "Killarney",
"3535997", "Muine\ Bheag",
"353454", "The\ Curragh",
"353622", "Cashel",
"353569901", "Kilkenny",
"35395", "Clifden",
"353655", "Ennis",
"3534293", "Dundalk",
"353901", "Athlone",
"3537495", "Dungloe",
"353909903", "Ballinasloe",
"353539901", "Wexford",
"353217", "Coachford",
"35329", "Kanturk",
"35371932", "Sligo",
"353918", "Loughrea",
"3535989", "Athy",
"353949285", "Castlebar",
"353909897", "Athlone",
"353710", "Sligo",
"353470", "Monaghan\/Clones",
"353466", "Edenderry",
"353493", "Belturbet",
"35328", "Skibbereen",
"353669100", "Killorglin",
"35371930", "Sligo",
"3537491", "Letterkenny",
"353624", "Tipperary",
"353425", "Castleblaney",
"353452", "Kildare",
"353424", "Carrickmacross",
"353516", "Carrick\-on\-Suir",
"35394", "Castlebar\/Claremorris\/Castlerea\/Ballinrobe",
"353625", "Tipperary",
"353469907", "Edenderry",
"353652", "Ennis",
"353626", "Cashel",
"3535791", "Birr",
"35393", "Tuam",
"35361999", "Limerick\/Scariff",
"3535688", "Freshford",
"353514", "New\ Ross",
"353426", "Dundalk",
"353465", "Enfield",
"35396", "Ballina",
"353464", "Trim",
"3539495", "Ballinrobe",
"353619", "Scariff",
"3534199", "Drogheda\/Ardee",
"353462", "Kells",
"3536693", "Dingle",
"3537198", "Manorhamilton",
"353561", "Kilkenny",
"35368", "Listowel",
"3534693", "Kells",
"353478", "Monaghan",
"3534492", "Tyrellspass",
"3534292", "Dundalk",
"35374", "Letterkenny\/Donegal\/Dungloe\/Buncrana",
"3537196", "Carrick\-on\-Shannon",
"353656", "Ennis",
"353512", "Kilmacthomas",
"35369", "Newcastle\ West",
"353719010", "Sligo",
"3539490", "Castlebar",
"353432", "Longford",
"353456", "Naas",
"353949288", "Castlebar",
"353909901", "Athlone",
"353539903", "Gorey",
"353531", "Wexford",};

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