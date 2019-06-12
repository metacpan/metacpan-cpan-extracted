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
our $VERSION = 1.20190611222641;

my $formatters = [
                {
                  'leading_digits' => '78',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{3,4})',
                  'leading_digits' => '
            [12]|
            9(?:
              0[3-9]|
              [1-9]
            )
          '
                },
                {
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2,3})',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [3-7]|
            8[2-9]
          '
                },
                {
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1',
                  'leading_digits' => '[7-9]'
                },
                {
                  'pattern' => '(\\d{3})(\\d{4})(\\d{4,5})',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[78]'
                },
                {
                  'leading_digits' => '[78]',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{5})(\\d{5,6})'
                }
              ];

my $validators = {
                'pager' => '',
                'toll_free' => '800\\d{7,11}',
                'mobile' => '
          (?:
            707[0-3]|
            8(?:
              01|
              19
            )[01]
          )\\d{6}|
          (?:
            70[1-689]|
            8(?:
              0[2-9]|
              1[0-8]
            )|
            90[1-35-9]
          )\\d{7}
        ',
                'personal_number' => '',
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
                'specialrate' => '(700\\d{7,11})',
                'voip' => '',
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
        '
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