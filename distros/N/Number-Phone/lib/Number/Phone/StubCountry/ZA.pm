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
package Number::Phone::StubCountry::ZA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20240607153922;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '8[1-4]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '8[1-4]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2,3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '860',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[1-9]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '8',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              0330|
              4302
            )|
            52087
          )0\\d{3}|
          (?:
            1[0-8]|
            2[1-378]|
            3[1-69]|
            4\\d|
            5[1346-8]
          )\\d{7}
        ',
                'geographic' => '
          (?:
            2(?:
              0330|
              4302
            )|
            52087
          )0\\d{3}|
          (?:
            1[0-8]|
            2[1-378]|
            3[1-69]|
            4\\d|
            5[1346-8]
          )\\d{7}
        ',
                'mobile' => '
          (?:
            1(?:
              3492[0-25]|
              4495[0235]|
              549(?:
                20|
                5[01]
              )
            )|
            4[34]492[01]
          )\\d{3}|
          8[1-4]\\d{3,7}|
          (?:
            2[27]|
            47|
            54
          )4950\\d{3}|
          (?:
            1(?:
              049[2-4]|
              9[12]\\d\\d
            )|
            (?:
              6\\d|
              7[0-46-9]
            )\\d{3}|
            8(?:
              5\\d{3}|
              7(?:
                08[67]|
                158|
                28[5-9]|
                310
              )
            )
          )\\d{4}|
          (?:
            1[6-8]|
            28|
            3[2-69]|
            4[025689]|
            5[36-8]
          )4920\\d{3}|
          (?:
            12|
            [2-5]1
          )492\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(860\\d{6})|(
          (?:
            86[2-9]|
            9[0-2]\\d
          )\\d{6}
        )|(861\\d{6,7})',
                'toll_free' => '80\\d{7}',
                'voip' => '
          87(?:
            08[0-589]|
            15[0-79]|
            28[0-4]|
            31[1-9]
          )\\d{4}|
          87(?:
            [02][0-79]|
            1[0-46-9]|
            3[02-9]|
            [4-9]\\d
          )\\d{5}
        '
              };
my %areanames = ();
$areanames{en} = {"2736", "Drakensberg\/Ladysmith",
"2751", "Aliwal\ North\/Bloemfontein\/Far\ eastern\ part\ of\ Eastern\ Cape\/Southern\ and\ Central\ Free\ State",
"2758", "Bethlehem\/Eastern\ Free\ State",
"2716", "Vaal\ Triangle",
"2721", "Cape\ Town\/Gordons\ Bay\/Somerset\ West\/Stellenbosch",
"2728", "Caledon\/Hermanus\/Southern\ coast\ of\ Western\ Cape\/Swellendam",
"2743", "East\ London",
"2753", "Eastern\ part\ of\ Northern\ Cape\/Far\ western\ part\ of\ North\ West\/Kimberley\/Kuruman",
"2735", "Richards\ Bay\/St\.\ Lucia\/Ulundi\/Zululand",
"2732", "Ballito\/KwaZulu\ Natal\ coast\/Stanger\/Tongaat\/Verulam",
"2715", "Northern\ and\ Eastern\ Limpopo\/Polokwane",
"2741", "Port\ Elizabeth\/Uitenhage",
"2748", "Cradock\/Northern\ part\ of\ Eastern\ Cape\/Steynsburg",
"2723", "Beaufort\ West\/Karoo\/Robertson\/Worcester",
"2712", "Brits\/Tshwane",
"2742", "Jeffreys\ Bay\/Humansdorp\/Southern\ and\ central\ Eastern\ Cape",
"2718", "Klerksdorp\/Lichtenburg\/Potchefstroom",
"2711", "Johannesburg",
"2745", "Northern\ and\ eastern\ parts\ of\ Eastern\ Cape\/Queenstown",
"2756", "Kroonstad\/Parys\/Northern\ Free\ State",
"2731", "Durban",
"2722", "Boland\/Malmesbury\/Vredenburg\/Western\ coast\ of\ Western\ Cape",
"2713", "Bronkhorstspruit\/Eastern\ Gauteng\/Middelburg\/Nelspruit\/Northern\ and\ Western\ Mpumalanga\/Witbank",
"2746", "Bathurst\/Southern\ and\ eastern\ parts\ of\ Eastern\ Cape\/Grahamstown\/Kenton\-on\-Sea\/Port\ Alfred",
"2733", "KwaZulu\ Natal\ Midlands\/Pietermaritzburg",
"2744", "Garden\ Route\/George\/Knysna\/Mossel\ Bay\/Oudtshoorn\/Plettenberg\ Bay",
"2740", "Alice\/Bhisho",
"2717", "Ermelo\/Secunda\/Southern\ Mpumalanga",
"2754", "Upington\/Gordonia",
"2749", "Graaff\-Reinet\/Western\ part\ of\ Eastern\ Cape",
"2757", "Northern\ Free\ State\ Goldfields\/Welkom",
"2739", "Eastern\ Pondoland\/Port\ Shepstone\/Southern\ coast\ of\ KwaZulu\ Natal",
"2727", "Alexander\ Bay\/Calvinia\/Clanwilliam\/Namaqualand\/Port\ Nolloth\/Springbok\/Vredendal",
"2734", "Newcastle\/Northern\ KwaZulu\ Natal\/Vryheid",
"2714", "Modimolle\/Northern\ North\ West\ and\ Southwestern\ Limpopo\/Rustenburg",
"2747", "Butterworth\/Eastern\ part\ of\ Eastern\ Cape\/Mthatha",
"2710", "Johannesburg",};
my $timezones = {
               '' => [
                       'Africa/Johannesburg'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+27|\D)//g;
      my $self = bless({ country_code => '27', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '27', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;