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
our $VERSION = 1.20181205223704;

my $formatters = [
                {
                  'national_rule' => '0$1',
                  'leading_digits' => '78',
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{3})'
                },
                {
                  'pattern' => '(\\d)(\\d{3})(\\d{3,4})',
                  'leading_digits' => '
            [12]|
            9(?:
              0[3-9]|
              [1-9]
            )
          ',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1'
                },
                {
                  'national_rule' => '0$1',
                  'leading_digits' => '
            [3-7]|
            8[2-9]
          ',
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2,3})'
                },
                {
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})',
                  'national_rule' => '0$1',
                  'leading_digits' => '[7-9]',
                  'format' => '$1 $2 $3'
                },
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[78]',
                  'pattern' => '(\\d{3})(\\d{4})(\\d{4,5})'
                },
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[78]',
                  'pattern' => '(\\d{3})(\\d{5})(\\d{5,6})'
                }
              ];

my $validators = {
                'toll_free' => '800\\d{7,11}',
                'geographic' => '
          (?:
            (?:
              [1-356]\\d|
              4[02-8]|
              7[0-79]|
              8[2-9]
            )\\d|
            9(?:
              0[3-9]|
              [1-9]\\d
            )
          )\\d{5}|
          (?:
            [12]\\d|
            4[147]|
            5[14579]|
            6[1578]|
            7[0-3578]
          )\\d{5}
        ',
                'fixed_line' => '
          (?:
            (?:
              [1-356]\\d|
              4[02-8]|
              7[0-79]|
              8[2-9]
            )\\d|
            9(?:
              0[3-9]|
              [1-9]\\d
            )
          )\\d{5}|
          (?:
            [12]\\d|
            4[147]|
            5[14579]|
            6[1578]|
            7[0-3578]
          )\\d{5}
        ',
                'specialrate' => '(700\\d{7,11})',
                'personal_number' => '',
                'pager' => '',
                'mobile' => '
          (?:
            1(?:
              (?:
                7[34]|
                95
              )\\d|
              8(?:
                04|
                [124579]\\d|
                8[0-3]
              )
            )|
            287[0-7]|
            3(?:
              18[1-8]|
              88[0-7]|
              9(?:
                6[1-5]|
                8[5-9]
              )
            )|
            4(?:
              [28]8[0-2]|
              6(?:
                7[1-9]|
                8[02-47]
              )
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
              0(?:
                [1-689]\\d|
                7[0-3]
              )\\d\\d|
              38[0-7]|
              69[1-8]|
              78[2-4]
            )|
            8(?:
              (?:
                0(?:
                  1[01]|
                  [2-9]\\d
                )|
                1(?:
                  [0-8]\\d|
                  9[01]
                )
              )\\d\\d|
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
            9(?:
              0[235-9]\\d\\d|
              8[07]
            )\\d
          )\\d{4}
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
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;