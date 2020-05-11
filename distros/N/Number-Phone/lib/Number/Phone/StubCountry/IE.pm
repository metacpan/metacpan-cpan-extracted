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
our $VERSION = 1.20200511123714;

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
$areanames{en}->{3531} = "Dublin";
$areanames{en}->{35321} = "Cork";
$areanames{en}->{3532140} = "Kinsale";
$areanames{en}->{3532141} = "Kinsale";
$areanames{en}->{3532147} = "Kinsale";
$areanames{en}->{353217} = "Coachford";
$areanames{en}->{353218} = "Cork\/Kinsale\/Coachford";
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
$areanames{en}->{35341} = "Drogheda";
$areanames{en}->{3534120} = "Drogheda\/Ardee";
$areanames{en}->{353416} = "Ardee";
$areanames{en}->{3534199} = "Drogheda\/Ardee";
$areanames{en}->{353420} = "Dundalk\/Carrickmacross\/Castleblaney";
$areanames{en}->{353421} = "Dundalk\/Carrickmacross\/Castleblaney";
$areanames{en}->{353422} = "Dundalk";
$areanames{en}->{353423} = "Dundalk\/Carrickmacross\/Castleblaney";
$areanames{en}->{353424} = "Carrickmacross";
$areanames{en}->{353425} = "Castleblaney";
$areanames{en}->{353426} = "Dundalk";
$areanames{en}->{353427} = "Dundalk";
$areanames{en}->{353428} = "Dundalk";
$areanames{en}->{3534290} = "Dundalk";
$areanames{en}->{3534291} = "Dundalk";
$areanames{en}->{3534292} = "Dundalk";
$areanames{en}->{3534293} = "Dundalk";
$areanames{en}->{3534294} = "Dundalk";
$areanames{en}->{3534295} = "Carrickmacross";
$areanames{en}->{3534296} = "Carrickmacross";
$areanames{en}->{3534297} = "Castleblaney";
$areanames{en}->{3534298} = "Castleblaney";
$areanames{en}->{3534299} = "Dundalk\/Carrickmacross\/Castleblaney";
$areanames{en}->{35343} = "Longford\/Granard";
$areanames{en}->{353432} = "Longford";
$areanames{en}->{3534330} = "Longford";
$areanames{en}->{3534331} = "Longford";
$areanames{en}->{3534332} = "Longford";
$areanames{en}->{3534333} = "Longford";
$areanames{en}->{35343666} = "Granard";
$areanames{en}->{35343667} = "Granard";
$areanames{en}->{35343668} = "Granard";
$areanames{en}->{35343669} = "Granard";
$areanames{en}->{3534367} = "Granard";
$areanames{en}->{3534368} = "Granard";
$areanames{en}->{3534369} = "Granard";
$areanames{en}->{353437} = "Granard";
$areanames{en}->{353438} = "Granard";
$areanames{en}->{35344} = "Mullingar";
$areanames{en}->{353443} = "Mullingar\/Castlepollard\/Tyrrellspass";
$areanames{en}->{353447} = "Castlepollard";
$areanames{en}->{353448} = "Tyrellspass";
$areanames{en}->{3534490} = "Tyrellspass";
$areanames{en}->{3534491} = "Tyrellspass";
$areanames{en}->{3534492} = "Tyrellspass";
$areanames{en}->{3534495} = "Castlepollard";
$areanames{en}->{3534496} = "Castlepollard";
$areanames{en}->{3534497} = "Castlepollard";
$areanames{en}->{3534498} = "Castlepollard";
$areanames{en}->{3534499} = "Mullingar\/Castlepollard\/Tyrrellspass";
$areanames{en}->{353450} = "Naas\/Kildare\/Curragh";
$areanames{en}->{353451} = "Naas\/Kildare\/Curragh";
$areanames{en}->{3534510} = "Kildare";
$areanames{en}->{353452} = "Kildare";
$areanames{en}->{353453} = "The\ Curragh";
$areanames{en}->{353454} = "The\ Curragh";
$areanames{en}->{353455} = "Kildare";
$areanames{en}->{353456} = "Naas";
$areanames{en}->{353457} = "Naas";
$areanames{en}->{353458} = "Naas";
$areanames{en}->{353459} = "Naas";
$areanames{en}->{353460} = "Navan";
$areanames{en}->{353461} = "Navan";
$areanames{en}->{353462} = "Kells";
$areanames{en}->{353463} = "Navan\/Kells\/Trim\/Edenderry\/Enfield";
$areanames{en}->{353464} = "Trim";
$areanames{en}->{353465} = "Enfield";
$areanames{en}->{353466} = "Edenderry";
$areanames{en}->{353467} = "Navan";
$areanames{en}->{353468} = "Navan";
$areanames{en}->{3534690} = "Navan";
$areanames{en}->{3534691} = "Navan";
$areanames{en}->{3534692} = "Kells";
$areanames{en}->{3534693} = "Kells";
$areanames{en}->{3534694} = "Trim";
$areanames{en}->{3534695} = "Enfield";
$areanames{en}->{3534696} = "Enfield";
$areanames{en}->{3534697} = "Edenderry";
$areanames{en}->{3534698} = "Edenderry";
$areanames{en}->{3534699} = "Navan\/Kells\/Trim\/Edenderry\/Enfield";
$areanames{en}->{353469900} = "Navan";
$areanames{en}->{353469901} = "Navan";
$areanames{en}->{353469907} = "Edenderry";
$areanames{en}->{353470} = "Monaghan\/Clones";
$areanames{en}->{353471} = "Monaghan\/Clones";
$areanames{en}->{353472} = "Clones";
$areanames{en}->{353473} = "Monaghan";
$areanames{en}->{353474} = "Clones";
$areanames{en}->{353475} = "Clones";
$areanames{en}->{353476} = "Monaghan";
$areanames{en}->{353477} = "Monaghan";
$areanames{en}->{353478} = "Monaghan";
$areanames{en}->{353479} = "Monaghan";
$areanames{en}->{3534791} = "Monaghan\/Clones";
$areanames{en}->{3534799} = "Monaghan\/Clones";
$areanames{en}->{353490} = "Cavan\/Cootehill\/Oldcastle\/Belturbet";
$areanames{en}->{353491} = "Cavan\/Cootehill\/Oldcastle\/Belturbet";
$areanames{en}->{353492} = "Cootehill";
$areanames{en}->{353493} = "Belturbet";
$areanames{en}->{353494} = "Cavan";
$areanames{en}->{353495} = "Cootehill";
$areanames{en}->{353496} = "Cavan";
$areanames{en}->{353497} = "Cavan";
$areanames{en}->{353498} = "Oldcastle";
$areanames{en}->{353499} = "Belturbet";
$areanames{en}->{3534999} = "Cavan\/Cootehill\/Oldcastle\/Belturbet";
$areanames{en}->{353504} = "Thurles";
$areanames{en}->{353505} = "Roscrea";
$areanames{en}->{35351} = "Waterford";
$areanames{en}->{353512} = "Kilmacthomas";
$areanames{en}->{353514} = "New\ Ross";
$areanames{en}->{353516} = "Carrick\-on\-Suir";
$areanames{en}->{35351999} = "Waterford\/Carrick\-on\-Suir\/New\ Ross\/Kilmacthomas";
$areanames{en}->{35352} = "Clonmel\/Cahir\/Killenaule";
$areanames{en}->{3535261} = "Clonmel";
$areanames{en}->{3535274} = "Cahir";
$areanames{en}->{3535291} = "Killenaule";
$areanames{en}->{35353} = "Wexford\/Enniscorthy\/Ferns\/Gorey";
$areanames{en}->{353530} = "Wexford";
$areanames{en}->{353531} = "Wexford";
$areanames{en}->{353531202} = "Enniscorthy";
$areanames{en}->{353531203} = "Gorey";
$areanames{en}->{3535390} = "Wexford";
$areanames{en}->{3535391} = "Wexford";
$areanames{en}->{3535392} = "Enniscorthy";
$areanames{en}->{3535393} = "Ferns";
$areanames{en}->{3535394} = "Gorey";
$areanames{en}->{353539900} = "Wexford";
$areanames{en}->{353539901} = "Wexford";
$areanames{en}->{353539902} = "Enniscorthy";
$areanames{en}->{353539903} = "Gorey";
$areanames{en}->{35356} = "Kilkenny\/Castlecomer\/Freshford";
$areanames{en}->{353560} = "Kilkenny";
$areanames{en}->{353561} = "Kilkenny";
$areanames{en}->{3535644} = "Castlecomer";
$areanames{en}->{3535677} = "Kilkenny";
$areanames{en}->{3535678} = "Kilkenny";
$areanames{en}->{3535688} = "Freshford";
$areanames{en}->{353569900} = "Kilkenny";
$areanames{en}->{353569901} = "Kilkenny";
$areanames{en}->{35357} = "Portlaoise\/Abbeyleix\/Tullamore\/Birr";
$areanames{en}->{353570} = "Portlaoise";
$areanames{en}->{353571} = "Portlaoise";
$areanames{en}->{35357850} = "Portlaoise";
$areanames{en}->{353578510} = "Portlaoise";
$areanames{en}->{35357859} = "Portlaoise";
$areanames{en}->{3535786} = "Portlaoise";
$areanames{en}->{3535787} = "Abbeyleix";
$areanames{en}->{3535791} = "Birr";
$areanames{en}->{3535793} = "Tullamore";
$areanames{en}->{353579900} = "Portlaoise";
$areanames{en}->{353579901} = "Portlaoise";
$areanames{en}->{35358} = "Dungarvan";
$areanames{en}->{35359} = "Carlow\/Muine\ Bheag\/Athy\/Baltinglass";
$areanames{en}->{3535964} = "Baltinglass";
$areanames{en}->{3535986} = "Athy";
$areanames{en}->{3535987} = "Athy";
$areanames{en}->{3535988} = "Athy";
$areanames{en}->{3535989} = "Athy";
$areanames{en}->{3535991} = "Carlow";
$areanames{en}->{3535997} = "Muine\ Bheag";
$areanames{en}->{35361} = "Limerick";
$areanames{en}->{353616} = "Scariff";
$areanames{en}->{353619} = "Scariff";
$areanames{en}->{35361999} = "Limerick\/Scariff";
$areanames{en}->{353620} = "Tipperary\/Cashel";
$areanames{en}->{353621} = "Tipperary\/Cashel";
$areanames{en}->{353622} = "Cashel";
$areanames{en}->{353623} = "Tipperary";
$areanames{en}->{353624} = "Tipperary";
$areanames{en}->{353625} = "Tipperary";
$areanames{en}->{353626} = "Cashel";
$areanames{en}->{353627} = "Cashel";
$areanames{en}->{353628} = "Tipperary";
$areanames{en}->{353629} = "Cashel";
$areanames{en}->{3536299} = "Tipperary";
$areanames{en}->{35363} = "Rathluirc";
$areanames{en}->{35364} = "Killarney\/Rathmore";
$areanames{en}->{3536466} = "Killarney";
$areanames{en}->{353646700} = "Killarney";
$areanames{en}->{353646701} = "Killarney";
$areanames{en}->{3536477} = "Rathmore";
$areanames{en}->{353650} = "Ennis\/Ennistymon\/Kilrush";
$areanames{en}->{353651} = "Ennis\/Ennistymon\/Kilrush";
$areanames{en}->{353652} = "Ennis";
$areanames{en}->{353653} = "Ennis";
$areanames{en}->{353654} = "Ennis";
$areanames{en}->{353655} = "Ennis";
$areanames{en}->{353656} = "Ennis";
$areanames{en}->{353657} = "Ennistymon";
$areanames{en}->{353658} = "Kilrush";
$areanames{en}->{353659} = "Kilrush";
$areanames{en}->{3536599} = "Ennis\/Ennistymon\/Kilrush";
$areanames{en}->{35366} = "Tralee";
$areanames{en}->{3536670} = "Tralee\/Dingle\/Killorglin\/Cahersiveen";
$areanames{en}->{353668} = "Tralee\/Dingle\/Killorglin\/Cahersiveen";
$areanames{en}->{3536690} = "Killorglin";
$areanames{en}->{3536691} = "Dingle";
$areanames{en}->{353669100} = "Killorglin";
$areanames{en}->{3536692} = "Dingle";
$areanames{en}->{3536693} = "Dingle";
$areanames{en}->{3536694} = "Cahirciveen";
$areanames{en}->{3536695} = "Cahirciveen";
$areanames{en}->{3536696} = "Cahirciveen";
$areanames{en}->{3536697} = "Killorglin";
$areanames{en}->{3536698} = "Killorglin";
$areanames{en}->{3536699} = "Tralee\/Dingle\/Killorglin\/Cahersiveen";
$areanames{en}->{35367} = "Nenagh";
$areanames{en}->{35368} = "Listowel";
$areanames{en}->{35369} = "Newcastle\ West";
$areanames{en}->{35371} = "Sligo\/Manorhamilton\/Carrick\-on\-Shannon";
$areanames{en}->{353710} = "Sligo";
$areanames{en}->{353711} = "Sligo";
$areanames{en}->{353719010} = "Sligo";
$areanames{en}->{3537191} = "Sligo";
$areanames{en}->{35371930} = "Sligo";
$areanames{en}->{35371931} = "Sligo";
$areanames{en}->{35371932} = "Sligo";
$areanames{en}->{353719330} = "Sligo";
$areanames{en}->{353719331} = "Sligo";
$areanames{en}->{353719332} = "Sligo";
$areanames{en}->{353719334} = "Sligo";
$areanames{en}->{353719335} = "Sligo";
$areanames{en}->{353719344} = "Sligo";
$areanames{en}->{353719401} = "Sligo";
$areanames{en}->{35371959} = "Carrick\-on\-Shannon";
$areanames{en}->{3537196} = "Carrick\-on\-Shannon";
$areanames{en}->{3537198} = "Manorhamilton";
$areanames{en}->{353719900} = "Sligo";
$areanames{en}->{35374} = "Letterkenny\/Donegal\/Dungloe\/Buncrana";
$areanames{en}->{353740} = "Letterkenny";
$areanames{en}->{353741} = "Letterkenny";
$areanames{en}->{3537491} = "Letterkenny";
$areanames{en}->{35374920} = "Letterkenny";
$areanames{en}->{353749210} = "Letterkenny";
$areanames{en}->{353749211} = "Letterkenny";
$areanames{en}->{353749212} = "Letterkenny";
$areanames{en}->{353749214} = "Letterkenny";
$areanames{en}->{3537493} = "Buncrana";
$areanames{en}->{3537495} = "Dungloe";
$areanames{en}->{35374960} = "Letterkenny";
$areanames{en}->{3537497} = "Donegal";
$areanames{en}->{353749888} = "Letterkenny";
$areanames{en}->{353749889} = "Letterkenny";
$areanames{en}->{35374989} = "Letterkenny";
$areanames{en}->{353749900} = "Letterkenny";
$areanames{en}->{35390} = "Athlone\/Ballinasloe\/Portumna\/Roscommon";
$areanames{en}->{353900} = "Athlone";
$areanames{en}->{353901} = "Athlone";
$areanames{en}->{3539064} = "Athlone";
$areanames{en}->{35390650} = "Athlone";
$areanames{en}->{3539066} = "Roscommon";
$areanames{en}->{3539096} = "Ballinasloe";
$areanames{en}->{3539097} = "Portumna";
$areanames{en}->{353909897} = "Athlone";
$areanames{en}->{353909900} = "Athlone";
$areanames{en}->{353909901} = "Athlone";
$areanames{en}->{353909902} = "Ballinasloe";
$areanames{en}->{353909903} = "Ballinasloe";
$areanames{en}->{35391} = "Galway";
$areanames{en}->{353912} = "Gort";
$areanames{en}->{353916} = "Gort";
$areanames{en}->{353918} = "Loughrea";
$areanames{en}->{35393} = "Tuam";
$areanames{en}->{35394} = "Castlebar\/Claremorris\/Castlerea\/Ballinrobe";
$areanames{en}->{3539490} = "Castlebar";
$areanames{en}->{35394925} = "Castlebar";
$areanames{en}->{353949285} = "Castlebar";
$areanames{en}->{353949286} = "Castlebar";
$areanames{en}->{353949287} = "Castlebar";
$areanames{en}->{353949288} = "Castlebar";
$areanames{en}->{353949289} = "Castlebar";
$areanames{en}->{353949290} = "Castlebar";
$areanames{en}->{353949291} = "Castlebar";
$areanames{en}->{3539493} = "Claremorris";
$areanames{en}->{3539495} = "Ballinrobe";
$areanames{en}->{3539496} = "Castlerea";
$areanames{en}->{3539498} = "Castlerea";
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