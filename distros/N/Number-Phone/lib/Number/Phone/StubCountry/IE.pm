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
our $VERSION = 1.20241212130805;

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
$areanames{en} = {"353719344", "Sligo",
"3536670", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353464", "Trim",
"353627", "Cashel",
"3535291", "Killenaule",
"35395", "Clifden",
"3535991", "Carlow",
"353719330", "Sligo",
"3534296", "Carrickmacross",
"353651", "Ennis\/Ennistymon\/Kilrush",
"3536697", "Killorglin",
"353453", "The\ Curragh",
"353741", "Letterkenny",
"3537196", "Carrick\-on\-Shannon",
"353450", "Naas\/Kildare\/Curragh",
"3531", "Dublin",
"353578510", "Portlaoise",
"353404", "Wicklow",
"3535964", "Baltinglass",
"353473", "Monaghan",
"353900", "Athlone",
"353470", "Monaghan\/Clones",
"353468", "Navan",
"3535678", "Kilkenny",
"35343666", "Granard",
"35393", "Tuam",
"35397", "Belmullet",
"353531", "Wexford",
"353571", "Portlaoise",
"3534294", "Dundalk",
"353949289", "Castlebar",
"35341", "Drogheda",
"353655", "Ennis",
"3539097", "Portumna",
"3535677", "Kilkenny",
"353949288", "Castlebar",
"35374", "Letterkenny\/Donegal\/Dungloe\/Buncrana",
"353749212", "Letterkenny",
"3536690", "Killorglin",
"353629", "Cashel",
"353658", "Kilrush",
"353217", "Coachford",
"353622", "Cashel",
"3534332", "Longford",
"353465", "Enfield",
"3536466", "Killarney",
"353949287", "Castlebar",
"3536299", "Tipperary",
"35353", "Wexford\/Enniscorthy\/Ferns\/Gorey",
"35357", "Portlaoise\/Abbeyleix\/Tullamore\/Birr",
"3535644", "Castlecomer",
"3534293", "Dundalk",
"353560", "Kilkenny",
"3534496", "Castlepollard",
"353654", "Ennis",
"3534331", "Longford",
"35371959", "Carrick\-on\-Shannon",
"35390650", "Athlone",
"353496", "Cavan",
"3536698", "Killorglin",
"353749211", "Letterkenny",
"3536695", "Cahirciveen",
"35367", "Nenagh",
"353461", "Navan",
"35363", "Rathluirc",
"353426", "Dundalk",
"353711", "Sligo",
"353416", "Ardee",
"3534693", "Kells",
"353457", "Naas",
"3539066", "Roscommon",
"353469901", "Navan",
"3539490", "Castlebar",
"3536699", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353669100", "Killorglin",
"353719335", "Sligo",
"353466", "Edenderry",
"353421", "Dundalk\/Carrickmacross\/Castleblaney",
"3535394", "Gorey",
"353620", "Tipperary\/Cashel",
"353623", "Tipperary",
"3535986", "Athy",
"353491", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"35344", "Mullingar",
"35343667", "Granard",
"3534791", "Monaghan\/Clones",
"353512", "Kilmacthomas",
"353448", "Tyrellspass",
"353646701", "Killarney",
"353619", "Scariff",
"3539495", "Ballinrobe",
"3539498", "Castlerea",
"353495", "Cootehill",
"3539064", "Athlone",
"353719334", "Sligo",
"353437", "Granard",
"353425", "Castleblaney",
"353477", "Monaghan",
"353909900", "Athlone",
"353539901", "Wexford",
"353579901", "Portlaoise",
"353498", "Oldcastle",
"353452", "Kildare",
"3535393", "Ferns",
"35323", "Bandon",
"3534330", "Longford",
"35327", "Bantry",
"3535793", "Tullamore",
"353428", "Dundalk",
"353459", "Naas",
"35371", "Sligo\/Manorhamilton\/Carrick\-on\-Shannon",
"3536692", "Dingle",
"3536477", "Rathmore",
"35374920", "Letterkenny",
"3534694", "Trim",
"3534799", "Monaghan\/Clones",
"3535787", "Abbeyleix",
"3537493", "Buncrana",
"353494", "Cavan",
"3534696", "Enfield",
"353949285", "Castlebar",
"35374989", "Letterkenny",
"353424", "Carrickmacross",
"3535997", "Muine\ Bheag",
"353949290", "Castlebar",
"353569900", "Kilkenny",
"353432", "Longford",
"353472", "Clones",
"35325", "Fermoy",
"3536691", "Dingle",
"353479", "Monaghan",
"353539902", "Enniscorthy",
"353539903", "Gorey",
"353912", "Gort",
"353656", "Ennis",
"353909897", "Athlone",
"353427", "Dundalk",
"353475", "Clones",
"3535390", "Wexford",
"3534333", "Longford",
"3534499", "Mullingar\/Castlepollard\/Tyrrellspass",
"353504", "Thurles",
"3537191", "Sligo",
"353514", "New\ Ross",
"353497", "Cavan",
"3535988", "Athy",
"3532147", "Kinsale",
"3534368", "Granard",
"3534697", "Edenderry",
"3537495", "Dungloe",
"353719900", "Sligo",
"353719010", "Sligo",
"353749210", "Letterkenny",
"35324", "Youghal",
"353451", "Naas\/Kildare\/Curragh",
"353740", "Letterkenny",
"353949286", "Castlebar",
"35328", "Skibbereen",
"35371930", "Sligo",
"353650", "Ennis\/Ennistymon\/Kilrush",
"353653", "Ennis",
"35371932", "Sligo",
"3534291", "Dundalk",
"3539496", "Castlerea",
"35351", "Waterford",
"353668", "Tralee\/Dingle\/Killorglin\/Cahersiveen",
"353719401", "Sligo",
"353901", "Athlone",
"353471", "Monaghan\/Clones",
"3535786", "Portlaoise",
"35366", "Tralee",
"3535261", "Clonmel",
"35356", "Kilkenny\/Castlecomer\/Freshford",
"353749889", "Letterkenny",
"353570", "Portlaoise",
"3534292", "Dundalk",
"35361", "Limerick",
"353530", "Wexford",
"353455", "Kildare",
"353492", "Cootehill",
"3539493", "Claremorris",
"353749888", "Letterkenny",
"35357859", "Portlaoise",
"353499", "Belturbet",
"353422", "Dundalk",
"353458", "Naas",
"3534690", "Navan",
"3532140", "Kinsale",
"353474", "Clones",
"353719332", "Sligo",
"353505", "Roscrea",
"3534492", "Tyrellspass",
"3534120", "Drogheda\/Ardee",
"353447", "Castlepollard",
"353561", "Kilkenny",
"35361999", "Limerick\/Scariff",
"3534299", "Dundalk\/Carrickmacross\/Castleblaney",
"35396", "Ballina",
"353454", "The\ Curragh",
"3535987", "Athy",
"3534999", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"3535274", "Cahir",
"353719331", "Sligo",
"3534367", "Granard",
"35391", "Galway",
"3534698", "Edenderry",
"3537497", "Donegal",
"3534695", "Enfield",
"353463", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"35322", "Mallow",
"353460", "Navan",
"353438", "Granard",
"353478", "Monaghan",
"353918", "Loughrea",
"35343669", "Granard",
"3534491", "Tyrellspass",
"35329", "Kanturk",
"353531202", "Enniscorthy",
"35390", "Athlone\/Ballinasloe\/Portumna\/Roscommon",
"35351999", "Waterford\/Carrick\-on\-Suir\/New\ Ross\/Kilmacthomas",
"353531203", "Gorey",
"35343", "Longford\/Granard",
"353626", "Cashel",
"35399", "Kilronan",
"353616", "Scariff",
"3536693", "Dingle",
"353657", "Ennistymon",
"353218", "Cork\/Kinsale\/Coachford",
"3534699", "Navan\/Kells\/Trim\/Edenderry\/Enfield",
"3537198", "Manorhamilton",
"353749900", "Letterkenny",
"35321", "Cork",
"353949291", "Castlebar",
"353710", "Sligo",
"353493", "Belturbet",
"353490", "Cavan\/Cootehill\/Oldcastle\/Belturbet",
"353569901", "Kilkenny",
"3537491", "Letterkenny",
"353621", "Tipperary\/Cashel",
"35394925", "Castlebar",
"353423", "Dundalk\/Carrickmacross\/Castleblaney",
"35326", "Macroom",
"353420", "Dundalk\/Carrickmacross\/Castleblaney",
"353516", "Carrick\-on\-Suir",
"3535392", "Enniscorthy",
"3534298", "Castleblaney",
"3534295", "Carrickmacross",
"3534497", "Castlepollard",
"3534199", "Drogheda\/Ardee",
"35364", "Killarney\/Rathmore",
"3534290", "Dundalk",
"353749214", "Letterkenny",
"353539900", "Wexford",
"353462", "Kells",
"353579900", "Portlaoise",
"35368", "Listowel",
"35358", "Dungarvan",
"3539096", "Ballinasloe",
"353402", "Arklow",
"3535791", "Birr",
"3535391", "Wexford",
"353625", "Tipperary",
"3534490", "Tyrellspass",
"353476", "Monaghan",
"353628", "Tipperary",
"353659", "Kilrush",
"35369", "Newcastle\ West",
"353469907", "Edenderry",
"353916", "Gort",
"353652", "Ennis",
"353646700", "Killarney",
"3536694", "Cahirciveen",
"3534692", "Kells",
"35359", "Carlow\/Muine\ Bheag\/Athy\/Baltinglass",
"35371931", "Sligo",
"353909901", "Athlone",
"35352", "Clonmel\/Cahir\/Killenaule",
"35357850", "Portlaoise",
"353909902", "Ballinasloe",
"35374960", "Letterkenny",
"3536599", "Ennis\/Ennistymon\/Kilrush",
"353909903", "Ballinasloe",
"35398", "Westport",
"3536696", "Cahirciveen",
"3534369", "Granard",
"35394", "Castlebar\/Claremorris\/Castlerea\/Ballinrobe",
"3535688", "Freshford",
"353469900", "Navan",
"35343668", "Granard",
"353467", "Navan",
"353624", "Tipperary",
"3534691", "Navan",
"3532141", "Kinsale",
"3535989", "Athy",
"353443", "Mullingar\/Castlepollard\/Tyrrellspass",
"353456", "Naas",
"3534510", "Kildare",
"3534495", "Castlepollard",
"3534297", "Castleblaney",
"3534498", "Castlepollard",};
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