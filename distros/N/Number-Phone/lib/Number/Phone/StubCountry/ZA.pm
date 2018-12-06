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
package Number::Phone::StubCountry::ZA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20181205223705;

my $formatters = [
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2',
                  'leading_digits' => '8[1-4]',
                  'pattern' => '(\\d{2})(\\d{3,4})'
                },
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '8[1-4]',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2,3})'
                },
                {
                  'leading_digits' => '860',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'leading_digits' => '[1-9]',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'voip' => '87\\d{7}',
                'pager' => '',
                'mobile' => '
          (?:
            6\\d|
            7[0-46-9]|
            8[1-5]
          )\\d{7}|
          8[1-4]\\d{3,6}
        ',
                'fixed_line' => '
          (?:
            1[0-8]|
            2[1-378]|
            3[1-69]|
            4\\d|
            5[1346-8]
          )\\d{7}
        ',
                'specialrate' => '(860\\d{6})|(
          (?:
            86[2-9]|
            9[0-2]\\d
          )\\d{6}
        )|(861\\d{6})',
                'personal_number' => '',
                'toll_free' => '80\\d{7}',
                'geographic' => '
          (?:
            1[0-8]|
            2[1-378]|
            3[1-69]|
            4\\d|
            5[1346-8]
          )\\d{7}
        '
              };
my %areanames = (
  2710 => "Johannesburg",
  2711 => "Johannesburg",
  2712 => "Brits\/Tshwane",
  2713 => "Bronkhorstspruit\/Eastern\ Gauteng\/Middelburg\/Nelspruit\/Northern\ and\ Western\ Mpumalanga\/Witbank",
  2714 => "Modimolle\/Northern\ North\ West\ and\ Southwestern\ Limpopo\/Rustenburg",
  2715 => "Northern\ and\ Eastern\ Limpopo\/Polokwane",
  2716 => "Vaal\ Triangle",
  2717 => "Ermelo\/Secunda\/Southern\ Mpumalanga",
  2718 => "Klerksdorp\/Lichtenburg\/Potchefstroom",
  2721 => "Cape\ Town\/Gordons\ Bay\/Somerset\ West\/Stellenbosch",
  2722 => "Boland\/Malmesbury\/Vredenburg\/Western\ coast\ of\ Western\ Cape",
  2723 => "Beaufort\ West\/Karoo\/Robertson\/Worcester",
  2727 => "Alexander\ Bay\/Calvinia\/Clanwilliam\/Namaqualand\/Port\ Nolloth\/Springbok\/Vredendal",
  2728 => "Caledon\/Hermanus\/Southern\ coast\ of\ Western\ Cape\/Swellendam",
  2731 => "Durban",
  2732 => "Ballito\/KwaZulu\ Natal\ coast\/Stanger\/Tongaat\/Verulam",
  2733 => "KwaZulu\ Natal\ Midlands\/Pietermaritzburg",
  2734 => "Newcastle\/Northern\ KwaZulu\ Natal\/Vryheid",
  2735 => "Richards\ Bay\/St\.\ Lucia\/Ulundi\/Zululand",
  2736 => "Drakensberg\/Ladysmith",
  2739 => "Eastern\ Pondoland\/Port\ Shepstone\/Southern\ coast\ of\ KwaZulu\ Natal",
  2740 => "Alice\/Bhisho",
  2741 => "Port\ Elizabeth\/Uitenhage",
  2742 => "Jeffreys\ Bay\/Humansdorp\/Southern\ and\ central\ Eastern\ Cape",
  2743 => "East\ London",
  2744 => "Garden\ Route\/George\/Knysna\/Mossel\ Bay\/Oudtshoorn\/Plettenberg\ Bay",
  2745 => "Northern\ and\ eastern\ parts\ of\ Eastern\ Cape\/Queenstown",
  2746 => "Bathurst\/Southern\ and\ eastern\ parts\ of\ Eastern\ Cape\/Grahamstown\/Kenton\-on\-Sea\/Port\ Alfred",
  2747 => "Butterworth\/Eastern\ part\ of\ Eastern\ Cape\/Mthatha",
  2748 => "Cradock\/Northern\ part\ of\ Eastern\ Cape\/Steynsburg",
  2749 => "Graaff\-Reinet\/Western\ part\ of\ Eastern\ Cape",
  2751 => "Aliwal\ North\/Bloemfontein\/Far\ eastern\ part\ of\ Eastern\ Cape\/Southern\ and\ Central\ Free\ State",
  2753 => "Eastern\ part\ of\ Northern\ Cape\/Far\ western\ part\ of\ North\ West\/Kimberley\/Kuruman",
  2754 => "Upington\/Gordonia",
  2756 => "Kroonstad\/Parys\/Northern\ Free\ State",
  2757 => "Northern\ Free\ State\ Goldfields\/Welkom",
  2758 => "Bethlehem\/Eastern\ Free\ State",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+27|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;