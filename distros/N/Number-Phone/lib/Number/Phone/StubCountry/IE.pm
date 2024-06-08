# automatically generated file, don't edit



# Copyright 2024 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20240607153920;

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
$areanames{en} = {"353749210", "Letterkenny",
"3535261", "Clonmel",
"3534693", "Kells",
"35364", "Killarney\/Rathmore",
"3534510", "Kildare",
"353949287", "Castlebar",
"3534696", "Enfield",
"353505", "Roscrea",
"353472", "Clones",
"353469900", "Navan",
"353901", "Athlone",
"353719344", "Sligo",
"3534297", "Castleblaney",
"353658", "Kilrush",
"353432", "Longford",
"353531203", "Gorey",
"3535988", "Athy",
"353569901", "Kilkenny",
"353749888", "Letterkenny",
"35361", "Limerick",
"353478", "Monaghan",
"3535786", "Portlaoise",
"3534368", "Granard",
"353652", "Ennis",
"353438", "Granard",
"35367", "Nenagh",
"3534332", "Longford",
"35363", "Rathluirc",
"353465", "Enfield",
"353561", "Kilkenny",
"353918", "Loughrea",
"353749889", "Letterkenny",
"353909901", "Athlone",
"353623", "Tipperary",
"353627", "Cashel",
"3536692", "Dingle",
"353448", "Tyrellspass",
"35395", "Clifden",
"353912", "Gort",
"353531202", "Enniscorthy",
"3536697", "Killorglin",
"3534499", "Mullingar\/Castlepollard\/Tyrrellspass",
"353654", "Ennis",
"3539495", "Ballinrobe",
"353719900", "Sligo",
"3534495", "Castlepollard",
"353656", "Ennis",
"3537196", "Carrick\-on\-Shannon",
"35356", "Kilkenny\/Castlecomer\/Freshford",
"35326", "Macroom",
"3535392", "Enniscorthy",
"353451", "Naas\/Kildare\/Curragh",
"3535644", "Castlecomer",
"353474", "Clones",
"353749900", "Letterkenny",
"35371931", "Sligo",
"353719330", "Sligo",
"3537493", "Buncrana",
"3534199", "Drogheda\/Ardee",
"353949289", "Castlebar",
"353476", "Monaghan",
"353619", "Scariff",
"3534799", "Monaghan\/Clones",
"353470", "Monaghan\/Clones",
"353416", "Ardee",
"3534120", "Drogheda\/Ardee",
"353916", "Gort",
"35343666", "Granard",
"353625", "Tipperary",
"35390", "Athlone\/Ballinasloe\/Portumna\/Roscommon",
"353669100", "Killorglin",
"353459", "Naas",
"353650", "Ennis\/Ennistymon\/Kilrush",
"3536599", "Ennis\/Ennistymon\/Kilrush",
"353467", "Navan",
"3534292", "Dundalk",
"35368", "Listowel",
"353949288", "Castlebar",
"353463", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"3539064", "Athlone",
"353460", "Navan",
"353949285", "Castlebar",
"353909897", "Athlone",
"3534699", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"353657", "Ennistymon",
"3535987", "Athy",
"35324", "Youghal",
"3534298", "Castleblaney",
"353653", "Ennis",
"3534695", "Enfield",
"3535791", "Birr",
"35351", "Waterford",
"353477", "Monaghan",
"35321", "Cork",
"3535391", "Wexford",
"353437", "Granard",
"353719332", "Sligo",
"353504", "Thurles",
"35374920", "Letterkenny",
"353473", "Monaghan",
"3534367", "Granard",
"3534290", "Dundalk",
"3539066", "Roscommon",
"353491", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"353622", "Cashel",
"353646701", "Killarney",
"35357", "Portlaoise\/Abbeyleix\/Tullamore\/Birr",
"35327", "Bantry",
"35353", "Wexford\/Enniscorthy\/Ferns\/Gorey",
"35323", "Bandon",
"3534291", "Dundalk",
"35343668", "Granard",
"353447", "Castlepollard",
"353628", "Tipperary",
"35371959", "Carrick\-on\-Shannon",
"353464", "Trim",
"353466", "Edenderry",
"353443", "Mullingar\/Castlepollard\/Tyrrellspass",
"353499", "Belturbet",
"3535390", "Wexford",
"353749212", "Letterkenny",
"353475", "Clones",
"3539496", "Castlerea",
"353710", "Sligo",
"35366", "Tralee",
"3536698", "Killorglin",
"353531", "Wexford",
"3539493", "Claremorris",
"3536299", "Tipperary",
"3534330", "Longford",
"35343667", "Granard",
"353620", "Tipperary\/Cashel",
"353571", "Portlaoise",
"3534496", "Castlepollard",
"353655", "Ennis",
"3537495", "Dungloe",
"3536690", "Killorglin",
"353740", "Letterkenny",
"3534331", "Longford",
"35357859", "Portlaoise",
"35371932", "Sligo",
"3539097", "Portumna",
"353462", "Kells",
"3534694", "Trim",
"353421", "Dundalk\/Carrickmacross\/Castleblaney",
"35328", "Skibbereen",
"353539901", "Wexford",
"35358", "Dungarvan",
"353626", "Cashel",
"353719010", "Sligo",
"3536466", "Killarney",
"35399", "Kilronan",
"353579901", "Portlaoise",
"353624", "Tipperary",
"3536691", "Dingle",
"353468", "Navan",
"353949290", "Castlebar",
"353512", "Kilmacthomas",
"3534999", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"3535678", "Kilkenny",
"35371930", "Sligo",
"35325", "Fermoy",
"3537191", "Sligo",
"353490", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"353428", "Dundalk",
"353719401", "Sligo",
"3532140", "Kinsale",
"35343669", "Granard",
"353218", "Cork\/Kinsale\/Coachford",
"35374960", "Letterkenny",
"35351999", "Waterford\/Carrick\-on\-Suir\/New\ Ross\/Kilmacthomas",
"353909900", "Athlone",
"3534294", "Dundalk",
"353461", "Navan",
"353422", "Dundalk",
"353539902", "Enniscorthy",
"3539096", "Ballinasloe",
"3537491", "Letterkenny",
"353469901", "Navan",
"3532141", "Kinsale",
"35374", "Letterkenny\/Donegal\/Dungloe\/Buncrana",
"353539903", "Gorey",
"353749211", "Letterkenny",
"353494", "Cavan",
"353453", "The\ Curragh",
"3536695", "Cahirciveen",
"353749214", "Letterkenny",
"353569900", "Kilkenny",
"3537198", "Manorhamilton",
"3535394", "Gorey",
"35371", "Sligo\/Manorhamilton\/Carrick\-on\-Shannon",
"353496", "Cavan",
"3536699", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353457", "Naas",
"3534497", "Castlepollard",
"353741", "Letterkenny",
"35369", "Newcastle\ West",
"353424", "Carrickmacross",
"3534691", "Navan",
"353578510", "Portlaoise",
"3534492", "Tyrellspass",
"353668", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353426", "Dundalk",
"3535997", "Muine\ Bheag",
"353469907", "Edenderry",
"353530", "Wexford",
"353516", "Carrick\-on\-Suir",
"353570", "Portlaoise",
"3536694", "Cahirciveen",
"353621", "Tipperary\/Cashel",
"353514", "New\ Ross",
"353711", "Sligo",
"35390650", "Athlone",
"35374989", "Letterkenny",
"353719334", "Sligo",
"3535274", "Cahir",
"353492", "Cootehill",
"353455", "Kildare",
"3534690", "Navan",
"35396", "Ballina",
"3534299", "Dundalk\/Carrickmacross\/Castleblaney",
"353420", "Dundalk\/Carrickmacross\/Castleblaney",
"353629", "Cashel",
"353498", "Oldcastle",
"3535986", "Athy",
"3534295", "Carrickmacross",
"3534698", "Edenderry",
"353719331", "Sligo",
"3535291", "Killenaule",
"353427", "Dundalk",
"3534692", "Kells",
"3534491", "Tyrellspass",
"3535677", "Kilkenny",
"353423", "Dundalk\/Carrickmacross\/Castleblaney",
"3535688", "Freshford",
"353719335", "Sligo",
"353646700", "Killarney",
"35393", "Tuam",
"353900", "Athlone",
"35397", "Belmullet",
"3532147", "Kinsale",
"35361999", "Limerick\/Scariff",
"3536670", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353217", "Coachford",
"35343", "Longford\/Granard",
"353495", "Cootehill",
"353949286", "Castlebar",
"3537497", "Donegal",
"35341", "Drogheda",
"3534791", "Monaghan\/Clones",
"3534333", "Longford",
"3539490", "Castlebar",
"353452", "Kildare",
"3534490", "Tyrellspass",
"353404", "Wicklow",
"35391", "Galway",
"3531", "Dublin",
"353560", "Kilkenny",
"3536696", "Cahirciveen",
"3539498", "Castlerea",
"353458", "Naas",
"35394", "Castlebar\/Claremorris\/Castlerea\/Ballinrobe",
"3536693", "Dingle",
"3534498", "Castlepollard",
"35352", "Clonmel\/Cahir\/Killenaule",
"35344", "Mullingar",
"35322", "Mallow",
"35394925", "Castlebar",
"35329", "Kanturk",
"353450", "Naas\/Kildare\/Curragh",
"35359", "Carlow\/Muine\ Bheag\/Athy\/Baltinglass",
"353659", "Kilrush",
"3536477", "Rathmore",
"35398", "Westport",
"3535393", "Ferns",
"353425", "Castleblaney",
"3535793", "Tullamore",
"353949291", "Castlebar",
"353909902", "Ballinasloe",
"353539900", "Wexford",
"3535964", "Baltinglass",
"35357850", "Portlaoise",
"353616", "Scariff",
"353479", "Monaghan",
"353579900", "Portlaoise",
"3534369", "Granard",
"353909903", "Ballinasloe",
"3535787", "Abbeyleix",
"353651", "Ennis\/Ennistymon\/Kilrush",
"3535991", "Carlow",
"353456", "Naas",
"353402", "Arklow",
"353497", "Cavan",
"3534293", "Dundalk",
"3535989", "Athy",
"3534697", "Edenderry",
"353493", "Belturbet",
"353471", "Monaghan\/Clones",
"3534296", "Carrickmacross",
"353454", "The\ Curragh",};
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