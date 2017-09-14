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
package Number::Phone::StubCountry::NG;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170908113148;

my $formatters = [
                {
                  'leading_digits' => '
            [12]|
            9(?:
              0[3-9]|
              [1-9]
            )
          ',
                  'pattern' => '(\\d)(\\d{3})(\\d{3,4})'
                },
                {
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2,3})',
                  'leading_digits' => '
            [3-6]|
            7(?:
              0[1-9]|
              [1-79]
            )|
            8[2-9]
          '
                },
                {
                  'leading_digits' => '
            70|
            8[01]|
            90[235-9]
          ',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})'
                },
                {
                  'leading_digits' => '[78]00',
                  'pattern' => '([78]00)(\\d{4})(\\d{4,5})'
                },
                {
                  'pattern' => '([78]00)(\\d{5})(\\d{5,6})',
                  'leading_digits' => '[78]00'
                },
                {
                  'pattern' => '(78)(\\d{2})(\\d{3})',
                  'leading_digits' => '78'
                }
              ];

my $validators = {
                'geographic' => '
          [12]\\d{6,7}|
          9(?:
            0[3-9]|
            [1-9]\\d
          )\\d{5}|
          (?:
            3\\d|
            4[023568]|
            5[02368]|
            6[02-469]|
            7[4-69]|
            8[2-9]
          )\\d{6}|
          (?:
            4[47]|
            5[14579]|
            6[1578]|
            7[0-357]
          )\\d{5,6}|
          (?:
            78|
            41
          )\\d{5}
        ',
                'personal_number' => '',
                'pager' => '',
                'toll_free' => '800\\d{7,11}',
                'mobile' => '
          (?:
            1(?:
              7[34]\\d|
              8(?:
                04|
                [124579]\\d|
                8[0-3]
              )|
              95\\d
            )|
            287[0-7]|
            3(?:
              18[1-8]|
              88[0-7]|
              9(?:
                8[5-9]|
                6[1-5]
              )
            )|
            4(?:
              28[0-2]|
              6(?:
                7[1-9]|
                8[02-47]
              )|
              88[0-2]
            )|
            5(?:
              2(?:
                7[7-9]|
                8\\d
              )|
              38[1-79]|
              48[0-7]|
              68[4-7]
            )|
            6(?:
              2(?:
                7[7-9]|
                8\\d
              )|
              4(?:
                3[7-9]|
                [68][129]|
                7[04-69]|
                9[1-8]
              )|
              58[0-2]|
              98[7-9]
            )|
            7(?:
              38[0-7]|
              69[1-8]|
              78[2-4]
            )|
            8(?:
              28[3-9]|
              38[0-2]|
              4(?:
                2[12]|
                3[147-9]|
                5[346]|
                7[4-9]|
                8[014-689]|
                90
              )|
              58[1-8]|
              78[2-9]|
              88[5-7]
            )|
            98[07]\\d
          )\\d{4}|
          (?:
            70(?:
              [1-689]\\d|
              7[0-3]
            )|
            8(?:
              0(?:
                1[01]|
                [2-9]\\d
              )|
              1(?:
                [0-8]\\d|
                9[01]
              )
            )|
            90[235-9]\\d
          )\\d{6}
        ',
                'specialrate' => '(700\\d{7,11})',
                'fixed_line' => '
          [12]\\d{6,7}|
          9(?:
            0[3-9]|
            [1-9]\\d
          )\\d{5}|
          (?:
            3\\d|
            4[023568]|
            5[02368]|
            6[02-469]|
            7[4-69]|
            8[2-9]
          )\\d{6}|
          (?:
            4[47]|
            5[14579]|
            6[1578]|
            7[0-357]
          )\\d{5,6}|
          (?:
            78|
            41
          )\\d{5}
        ',
                'voip' => ''
              };
my %areanames = (
  2341 => "Lagos",
  2342 => "Ibadan",
  23430 => "Ado\ Ekiti",
  23431 => "Ilorin",
  23433 => "New\ Bussa",
  23434 => "Akura",
  23435 => "Oshogbo",
  23436 => "Ile\ Ife",
  23437 => "Ijebu\ Ode",
  23438 => "Oyo",
  23439 => "Abeokuta",
  23441 => "Wukari",
  23442 => "Enugu",
  23443 => "Abakaliki",
  23444 => "Makurdi",
  23445 => "Ogoja",
  23446 => "Onitsha",
  23447 => "Lafia",
  23448 => "Awka",
  23450 => "Ikare",
  23451 => "Owo",
  23452 => "Benin",
  23453 => "Warri",
  23454 => "Sapele",
  23455 => "Agbor",
  23456 => "Asaba",
  23457 => "Auchi",
  23458 => "Lokoja",
  23459 => "Okitipupa",
  23460 => "Sokobo",
  23461 => "Kafanchau",
  23462 => "Kaduna",
  23463 => "Gusau",
  23464 => "Kano",
  23465 => "Katsina",
  23466 => "Minna",
  23467 => "Kontagora",
  23468 => "Birnin\-Kebbi",
  23469 => "Zaria",
  2347020 => "Pank\ Shin",
  23471 => "Azare",
  23472 => "Gombe",
  23473 => "Jos",
  23474 => "Damaturu",
  23475 => "Yola",
  23476 => "Maiduguri",
  23477 => "Bauchi",
  23478 => "Hadejia",
  23479 => "Jalingo",
  23482 => "Aba",
  23483 => "Owerri",
  23484 => "Port\ Harcourt",
  23485 => "Uyo",
  23486 => "Ahoada",
  23487 => "Calabar",
  23488 => "Umuahia",
  23489 => "Yenegoa",
  2349 => "Abuja",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+234|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
    return $self->is_valid() ? $self : undef;
}
1;