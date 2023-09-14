# automatically generated file, don't edit



# Copyright 2023 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20230903131448;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '78',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [12]|
            9(?:
              0[3-9]|
              [1-9]
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [3-7]|
            8[2-9]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2,3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[7-9]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[78]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{4})(\\d{4,5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[78]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{5})(\\d{5,6})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            (?:
              [1-356]\\d|
              4[02-8]|
              8[2-9]
            )\\d|
            9(?:
              0[3-9]|
              [1-9]\\d
            )
          )\\d{5}|
          7(?:
            0(?:
              [013-689]\\d|
              2[0-24-9]
            )\\d{3,4}|
            [1-79]\\d{6}
          )|
          (?:
            [12]\\d|
            4[147]|
            5[14579]|
            6[1578]|
            7[1-3578]
          )\\d{5}
        ',
                'geographic' => '
          (?:
            (?:
              [1-356]\\d|
              4[02-8]|
              8[2-9]
            )\\d|
            9(?:
              0[3-9]|
              [1-9]\\d
            )
          )\\d{5}|
          7(?:
            0(?:
              [013-689]\\d|
              2[0-24-9]
            )\\d{3,4}|
            [1-79]\\d{6}
          )|
          (?:
            [12]\\d|
            4[147]|
            5[14579]|
            6[1578]|
            7[1-3578]
          )\\d{5}
        ',
                'mobile' => '
          (?:
            702[0-24-9]|
            819[01]
          )\\d{6}|
          (?:
            70[13-689]|
            8(?:
              0[1-9]|
              1[0-8]
            )|
            9(?:
              0[1-9]|
              1[1-356]
            )
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(700\\d{7,11})',
                'toll_free' => '800\\d{7,11}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"23445", "Ogoja",
"23498", "Abuja",
"23468", "Birnin\-Kebbi",
"23434", "Akura",
"23493", "Abuja",
"23489", "Yenegoa",
"23463", "Gusau",
"2347020", "Pank\ Shin",
"23459", "Okitipupa",
"23438", "Oyo",
"23450", "Ikare",
"23494", "Abuja",
"23433", "New\ Bussa",
"23479", "Jalingo",
"23464", "Kano",
"23488", "Umuahia",
"23447", "Lafia",
"23454", "Sapele",
"23483", "Owerri",
"23469", "Zaria",
"23474", "Damaturu",
"23460", "Sokobo",
"23499", "Abuja",
"23446", "Onitsha",
"23478", "Hadejia",
"23453", "Warri",
"23442", "Enugu",
"23473", "Jos",
"23430", "Ado\ Ekiti",
"23484", "Port\ Harcourt",
"23441", "Wukari",
"23458", "Lokoja",
"23439", "Abeokuta",
"23475", "Yola",
"23496", "Abuja",
"23466", "Minna",
"23437", "Ijebu\ Ode",
"23461", "Kafanchau",
"23492", "Abuja",
"23462", "Kaduna",
"23455", "Agbor",
"234907", "Abuja",
"23491", "Abuja",
"23485", "Uyo",
"23467", "Kontagora",
"23436", "Ile\ Ife",
"23497", "Abuja",
"23431", "Ilorin",
"23486", "Ahoada",
"234908", "Abuja",
"23435", "Oshogbo",
"23477", "Bauchi",
"234909", "Abuja",
"2341", "Lagos",
"23482", "Aba",
"23457", "Auchi",
"23444", "Makurdi",
"234906", "Abuja",
"234903", "Abuja",
"23476", "Maiduguri",
"23451", "Owo",
"23495", "Abuja",
"23448", "Awka",
"2342", "Ibadan",
"234905", "Abuja",
"23465", "Katsina",
"23487", "Calabar",
"23452", "Benin",
"23443", "Abakaliki",
"23472", "Gombe",
"23471", "Azare",
"23456", "Asaba",
"234904", "Abuja",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+234|\D)//g;
      my $self = bless({ country_code => '234', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '234', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;