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
our $VERSION = 1.20211206222446;

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
$areanames{en} = {"353416", "Ardee",
"353460", "Navan",
"353450", "Naas\/Kildare\/Curragh",
"353646701", "Killarney",
"3532141", "Kinsale",
"35341", "Drogheda",
"353949286", "Castlebar",
"353740", "Letterkenny",
"353629", "Cashel",
"353531", "Wexford",
"353427", "Dundalk",
"3539066", "Roscommon",
"35364", "Killarney\/Rathmore",
"3534694", "Trim",
"353901", "Athlone",
"353498", "Oldcastle",
"353561", "Kilkenny",
"3537491", "Letterkenny",
"35374960", "Letterkenny",
"3536299", "Tipperary",
"353476", "Monaghan",
"3534696", "Enfield",
"3539064", "Athlone",
"3534691", "Navan",
"35343666", "Granard",
"3535393", "Ferns",
"3534368", "Granard",
"353539902", "Enniscorthy",
"35393", "Tuam",
"353909902", "Ballinasloe",
"353658", "Kilrush",
"3534510", "Kildare",
"353579901", "Portlaoise",
"353668", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"35396", "Ballina",
"35395", "Clifden",
"3534330", "Longford",
"3534697", "Edenderry",
"353570", "Portlaoise",
"353949288", "Castlebar",
"353657", "Ennistymon",
"3537497", "Donegal",
"353578510", "Portlaoise",
"353475", "Clones",
"353459", "Naas",
"353505", "Roscrea",
"353471", "Monaghan\/Clones",
"3535988", "Athy",
"3534695", "Enfield",
"35374989", "Letterkenny",
"353473", "Monaghan",
"353620", "Tipperary\/Cashel",
"3537495", "Dungloe",
"35343669", "Granard",
"353469907", "Edenderry",
"3535791", "Birr",
"35356", "Kilkenny\/Castlecomer\/Freshford",
"353428", "Dundalk",
"353497", "Cavan",
"3534333", "Longford",
"353949291", "Castlebar",
"35390", "Athlone\/Ballinasloe\/Portumna\/Roscommon",
"3536466", "Killarney",
"35353", "Wexford\/Enniscorthy\/Ferns\/Gorey",
"3532147", "Kinsale",
"35390650", "Athlone",
"35343667", "Granard",
"353469901", "Navan",
"35324", "Youghal",
"3534699", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"3535390", "Wexford",
"353749888", "Letterkenny",
"3534492", "Tyrellspass",
"35343668", "Granard",
"353218", "Cork\/Kinsale\/Coachford",
"353447", "Castlepollard",
"353749210", "Letterkenny",
"3534799", "Monaghan\/Clones",
"353626", "Cashel",
"3535989", "Athy",
"35357", "Portlaoise\/Abbeyleix\/Tullamore\/Birr",
"3537493", "Buncrana",
"35329", "Kanturk",
"3539096", "Ballinasloe",
"3534693", "Kells",
"353652", "Ennis",
"353424", "Carrickmacross",
"3535391", "Wexford",
"35398", "Westport",
"3535394", "Gorey",
"353949287", "Castlebar",
"353451", "Naas\/Kildare\/Curragh",
"353479", "Monaghan",
"353461", "Navan",
"3534698", "Edenderry",
"353463", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"353453", "The\ Curragh",
"3534199", "Drogheda\/Ardee",
"353741", "Letterkenny",
"353669100", "Killorglin",
"3536692", "Dingle",
"353909903", "Ballinasloe",
"353900", "Athlone",
"353530", "Wexford",
"3535987", "Athy",
"35351", "Waterford",
"353539903", "Gorey",
"353465", "Enfield",
"353455", "Kildare",
"353560", "Kilkenny",
"353516", "Carrick\-on\-Suir",
"353492", "Cootehill",
"353909901", "Athlone",
"353719344", "Sligo",
"353654", "Ennis",
"353422", "Dundalk",
"353539901", "Wexford",
"35397", "Belmullet",
"3534367", "Granard",
"3534690", "Navan",
"353569901", "Kilkenny",
"353456", "Naas",
"35343", "Longford\/Granard",
"3535793", "Tullamore",
"353466", "Edenderry",
"35374", "Letterkenny\/Donegal\/Dungloe\/Buncrana",
"3535986", "Athy",
"3536670", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353749889", "Letterkenny",
"3534331", "Longford",
"353949285", "Castlebar",
"3534791", "Monaghan\/Clones",
"353719330", "Sligo",
"353494", "Cavan",
"353949289", "Castlebar",
"3532140", "Kinsale",
"353719010", "Sligo",
"353916", "Gort",
"353625", "Tipperary",
"35351999", "Waterford\/Carrick\-on\-Suir\/New\ Ross\/Kilmacthomas",
"35322", "Mallow",
"3535274", "Cahir",
"35391", "Galway",
"353571", "Portlaoise",
"3534292", "Dundalk",
"3539097", "Portumna",
"3534369", "Granard",
"353470", "Monaghan\/Clones",
"353217", "Coachford",
"353909897", "Athlone",
"353719900", "Sligo",
"353448", "Tyrellspass",
"353623", "Tipperary",
"35358", "Dungarvan",
"35369", "Newcastle\ West",
"353621", "Tipperary\/Cashel",
"35359", "Carlow\/Muine\ Bheag\/Athy\/Baltinglass",
"35368", "Listowel",
"35327", "Bantry",
"353437", "Granard",
"3536697", "Killorglin",
"3534332", "Longford",
"353719331", "Sligo",
"353457", "Naas",
"3534294", "Dundalk",
"353467", "Navan",
"3535261", "Clonmel",
"353719334", "Sligo",
"353539900", "Wexford",
"3536695", "Cahirciveen",
"353909900", "Athlone",
"353659", "Kilrush",
"353420", "Dundalk\/Carrickmacross\/Castleblaney",
"353569900", "Kilkenny",
"35361999", "Limerick\/Scariff",
"3534999", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"35321", "Cork",
"353628", "Tipperary",
"353443", "Mullingar\/Castlepollard\/Tyrrellspass",
"3535787", "Abbeyleix",
"3534498", "Castlepollard",
"353472", "Clones",
"3534291", "Dundalk",
"353499", "Belturbet",
"3535688", "Freshford",
"35357850", "Portlaoise",
"3539495", "Ballinrobe",
"3536699", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"3536599", "Ennis\/Ennistymon\/Kilrush",
"3534296", "Carrickmacross",
"3535786", "Portlaoise",
"3535392", "Enniscorthy",
"3534490", "Tyrellspass",
"353616", "Scariff",
"3535678", "Kilkenny",
"353650", "Ennis\/Ennistymon\/Kilrush",
"353918", "Loughrea",
"353749214", "Letterkenny",
"3539496", "Castlerea",
"353531202", "Enniscorthy",
"3535964", "Baltinglass",
"353719401", "Sligo",
"3534295", "Carrickmacross",
"35361", "Limerick",
"353710", "Sligo",
"3536694", "Cahirciveen",
"353749211", "Letterkenny",
"353627", "Cashel",
"35344", "Mullingar",
"3534297", "Castleblaney",
"35399", "Kilronan",
"3536696", "Cahirciveen",
"3534299", "Dundalk\/Carrickmacross\/Castleblaney",
"353719335", "Sligo",
"353490", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"35371931", "Sligo",
"35371932", "Sligo",
"35367", "Nenagh",
"35328", "Skibbereen",
"3536691", "Dingle",
"353504", "Thurles",
"353474", "Clones",
"353438", "Granard",
"3537196", "Carrick\-on\-Shannon",
"3537191", "Sligo",
"3535644", "Castlecomer",
"353458", "Naas",
"35352", "Clonmel\/Cahir\/Killenaule",
"353468", "Navan",
"3534293", "Dundalk",
"353464", "Trim",
"353622", "Cashel",
"353454", "The\ Curragh",
"35371", "Sligo\/Manorhamilton\/Carrick\-on\-Shannon",
"353478", "Monaghan",
"3536690", "Killorglin",
"353402", "Arklow",
"3535291", "Killenaule",
"3534120", "Drogheda\/Ardee",
"353656", "Ennis",
"35363", "Rathluirc",
"3535997", "Muine\ Bheag",
"35366", "Tralee",
"3539490", "Castlebar",
"3534491", "Tyrellspass",
"3535677", "Kilkenny",
"353425", "Castleblaney",
"353469900", "Navan",
"353749212", "Letterkenny",
"353749900", "Letterkenny",
"3534496", "Castlepollard",
"353423", "Dundalk\/Carrickmacross\/Castleblaney",
"353496", "Cavan",
"353512", "Kilmacthomas",
"35394", "Castlebar\/Claremorris\/Castlerea\/Ballinrobe",
"353421", "Dundalk\/Carrickmacross\/Castleblaney",
"353949290", "Castlebar",
"3534298", "Castleblaney",
"353491", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"35357859", "Portlaoise",
"35371930", "Sligo",
"353619", "Scariff",
"3539498", "Castlerea",
"353426", "Dundalk",
"3534497", "Castlepollard",
"353493", "Belturbet",
"353531203", "Gorey",
"3536477", "Rathmore",
"353646700", "Killarney",
"353404", "Wicklow",
"353432", "Longford",
"3534290", "Dundalk",
"35394925", "Castlebar",
"353452", "Kildare",
"353624", "Tipperary",
"353462", "Kells",
"3534495", "Castlepollard",
"353495", "Cootehill",
"3536693", "Dingle",
"3536698", "Killorglin",
"353651", "Ennis\/Ennistymon\/Kilrush",
"353514", "New\ Ross",
"3531", "Dublin",
"353912", "Gort",
"353579900", "Portlaoise",
"353653", "Ennis",
"35325", "Fermoy",
"3534499", "Mullingar\/Castlepollard\/Tyrrellspass",
"35326", "Macroom",
"3535991", "Carlow",
"35374920", "Letterkenny",
"353711", "Sligo",
"35371959", "Carrick\-on\-Shannon",
"3539493", "Claremorris",
"3537198", "Manorhamilton",
"3534692", "Kells",
"35323", "Bandon",
"353477", "Monaghan",
"353655", "Ennis",
"353719332", "Sligo",};

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