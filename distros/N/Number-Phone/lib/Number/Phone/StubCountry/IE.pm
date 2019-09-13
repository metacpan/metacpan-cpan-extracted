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
our $VERSION = 1.20190912215426;

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
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '8',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d)(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '4',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4})'
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
              8[0-46-9]
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
              8[0-46-9]
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
$areanames{en}->{3531} = "Dublin";
$areanames{en}->{35321} = "Cork\/Kinsale\/Coachford";
$areanames{en}->{35322} = "Mallow";
$areanames{en}->{35323} = "Bandon";
$areanames{en}->{35324} = "Youghal";
$areanames{en}->{35325} = "Fermoy";
$areanames{en}->{35326} = "Macroom";
$areanames{en}->{35327} = "Bantry";
$areanames{en}->{35328} = "Skibbereen";
$areanames{en}->{35329} = "Kanturk";
$areanames{en}->{353402} = "Arklow";
$areanames{en}->{353404} = "Wicklow";
$areanames{en}->{35341} = "Drogheda\/Ardee";
$areanames{en}->{35342} = "Dundalk\/Carrickmacross\/Castleblaney";
$areanames{en}->{35343} = "Longford\/Granard";
$areanames{en}->{35344} = "Mullingar\/Castlepollard\/Tyrrellspass";
$areanames{en}->{35345} = "Naas\/Kildare\/Curragh";
$areanames{en}->{35346} = "Navan\/Kells\/Trim\/Edenderry\/Enfield";
$areanames{en}->{35347} = "Monaghan\/Clones";
$areanames{en}->{35349} = "Cavan\/Cootehill\/Oldcastle\/Belturbet";
$areanames{en}->{353504} = "Thurles";
$areanames{en}->{353505} = "Roscrea";
$areanames{en}->{35351} = "Waterford\/Carrick\-on\-Suir\/New\ Ross\/Kilmacthomas";
$areanames{en}->{35352} = "Clonmel\/Cahir\/Killenaule";
$areanames{en}->{35353} = "Wexford\/Enniscorthy\/Ferns\/Gorey";
$areanames{en}->{35356} = "Kilkenny\/Castlecomer\/Freshford";
$areanames{en}->{35357} = "Portlaoise\/Abbeyleix\/Tullamore\/Birr";
$areanames{en}->{35358} = "Dungarvan";
$areanames{en}->{35359} = "Carlow\/Muine\ Bheag\/Athy\/Baltinglass";
$areanames{en}->{35361} = "Limerick\/Scariff";
$areanames{en}->{35362} = "Tipperary\/Cashel";
$areanames{en}->{35363} = "Charleville";
$areanames{en}->{35364} = "Killarney\/Rathmore";
$areanames{en}->{35365} = "Ennis\/Ennistymon\/Kilrush";
$areanames{en}->{35366} = "Tralee\/Dingle\/Killorglin\/Cahersiveen";
$areanames{en}->{35367} = "Nenagh";
$areanames{en}->{35368} = "Listowel";
$areanames{en}->{35369} = "Newcastle\ West";
$areanames{en}->{35371} = "Sligo\/Manorhamilton\/Carrick\-on\-Shannon";
$areanames{en}->{35374} = "Letterkenny\/Donegal\/Dungloe\/Buncrana";
$areanames{en}->{35390} = "Athlone\/Ballinasloe\/Portumna\/Roscommon";
$areanames{en}->{35391} = "Galway\/Gort\/Loughrea";
$areanames{en}->{35393} = "Tuam";
$areanames{en}->{35394} = "Castlebar\/Claremorris\/Castlerea\/Ballinrobe";
$areanames{en}->{35395} = "Clifden";
$areanames{en}->{35396} = "Ballina";
$areanames{en}->{35397} = "Belmullet";
$areanames{en}->{35398} = "Westport";
$areanames{en}->{35399} = "Kilronan";

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