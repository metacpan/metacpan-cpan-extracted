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
package Number::Phone::StubCountry::NG;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20240607153921;

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
            [3-6]|
            7(?:
              0[0-689]|
              [1-79]
            )|
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
                  'leading_digits' => '20[129]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '2',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{4})(\\d{2})(\\d{4})'
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
          20(?:
            [1259]\\d|
            3[013-9]|
            4[1-8]|
            6[024-689]|
            7[1-79]|
            8[2-9]
          )\\d{6}|
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
          20(?:
            [1259]\\d|
            3[013-9]|
            4[1-8]|
            6[024-689]|
            7[1-79]|
            8[2-9]
          )\\d{6}|
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
            7(?:
              0[13-9]|
              [12]\\d
            )|
            8(?:
              0[1-9]|
              1[0-8]
            )|
            9(?:
              0[1-9]|
              1[1-6]
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
$areanames{en} = {"2342068", "Birin\ Kebbi",
"23435", "Oshogbo",
"23484", "Port\ Harcourt",
"23460", "Sokobo",
"2342054", "Sapele",
"2342048", "Awka",
"23448", "Awka",
"2342060", "Sokoto",
"23466", "Minna",
"2342057", "Auchi",
"23459", "Okitipupa",
"23498", "Abuja",
"23483", "Owerri",
"23458", "Lokoja",
"23499", "Abuja",
"23487", "Calabar",
"2342086", "Ahoada",
"23476", "Maiduguri",
"2342072", "Gombe",
"2342035", "Osogbo",
"23482", "Aba",
"2342041", "Wukari",
"2342079", "Jalingo",
"2342083", "Owerri",
"2342039", "Abeokuta",
"2342075", "Yola",
"234908", "Abuja",
"2342037", "Ijebu\ Ode",
"23493", "Abuja",
"23451", "Owo",
"23489", "Yenegoa",
"23497", "Abuja",
"2342088", "Umuahia",
"23436", "Ile\ Ife",
"2342077", "Bauchi",
"23447", "Lafia",
"23443", "Abakaliki",
"23430", "Ado\ Ekiti",
"23492", "Abuja",
"2342034", "Akure",
"23454", "Sapele",
"23442", "Enugu",
"23465", "Katsina",
"2342074", "Damaturu",
"2342052", "Benin",
"23494", "Abuja",
"2342059", "Okitipupa",
"23444", "Makurdi",
"23452", "Benin",
"2342055", "Agbor",
"2342043", "Abakaliki",
"23441", "Wukari",
"2342066", "Minna",
"234904", "Abuja",
"234906", "Abuja",
"2342046", "Onitsha",
"23457", "Auchi",
"23475", "Yola",
"23491", "Abuja",
"23453", "Warri",
"2341", "Lagos",
"23488", "Umuahia",
"23450", "Ikare",
"2342047", "Lafia\/Keffi",
"23485", "Uyo",
"23434", "Akura",
"2342050", "Ikare",
"23478", "Hadejia",
"23469", "Zaria",
"2342064", "Kano",
"23431", "Ilorin",
"2342044", "Makurdi",
"2342058", "Lokoja",
"23456", "Asaba",
"23496", "Abuja",
"2342051", "Owoh",
"23468", "Birnin\-Kebbi",
"23433", "New\ Bussa",
"23446", "Onitsha",
"23437", "Ijebu\ Ode",
"2342036", "Ile\ Ife",
"2342073", "Jos",
"234907", "Abuja",
"23479", "Jalingo",
"2342085", "Uyo",
"2342082", "Aba",
"2342076", "Maiduguri",
"2342033", "New\ Bussa",
"234903", "Abuja",
"2342089", "Yenagoa",
"23486", "Ahoada",
"2342087", "Calabar",
"23472", "Gombe",
"2342038", "Oyo",
"234209", "Abuja",
"23461", "Kafanchau",
"23439", "Abeokuta",
"23473", "Jos",
"23464", "Kano",
"23477", "Bauchi",
"23455", "Agbor",
"2342030", "Ado\ Ekiti",
"2342084", "Port\ Harcourt",
"2342053", "Warri",
"23462", "Kaduna",
"2342", "Ibadan",
"23445", "Ogoja",
"234201", "Lagos",
"234905", "Abuja",
"2347020", "Pank\ Shin",
"23495", "Abuja",
"2342056", "Asaba",
"23471", "Azare",
"2342065", "Katsina",
"2342042", "Nsukka\ Enugu",
"23467", "Kontagora",
"23438", "Oyo",
"23463", "Gusau",
"2342071", "Azare",
"23474", "Damaturu",
"2342069", "Zaria",
"234909", "Abuja",
"2342062", "Kaduna",
"2342031", "Ilorin",
"2342045", "Ogoja",};
my $timezones = {
               '' => [
                       'Africa/Lagos'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+234|\D)//g;
      my $self = bless({ country_code => '234', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '234', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;