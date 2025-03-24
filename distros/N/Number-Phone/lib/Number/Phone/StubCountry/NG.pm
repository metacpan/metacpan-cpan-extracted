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
our $VERSION = 1.20250323211833;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '3',
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
          (?:
            20(?:
              [1259]\\d|
              3[013-9]|
              4[1-8]|
              6[024-689]|
              7[1-79]|
              8[2-9]
            )|
            38
          )\\d{6}
        ',
                'geographic' => '
          (?:
            20(?:
              [1259]\\d|
              3[013-9]|
              4[1-8]|
              6[024-689]|
              7[1-79]|
              8[2-9]
            )|
            38
          )\\d{6}
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
$areanames{en} = {"2342074", "Damaturu",
"2342059", "Okitipupa",
"2342065", "Katsina",
"2342085", "Uyo",
"2342050", "Ikare",
"2342052", "Benin",
"2342041", "Wukari",
"2342077", "Bauchi",
"234202", "Ibadan",
"2342045", "Ogoja",
"2342036", "Ile\ Ife",
"2342053", "Warri",
"2342068", "Birin\ Kebbi",
"2342064", "Kano",
"2342030", "Ado\ Ekiti",
"2342047", "Lafia\/Keffi",
"2342071", "Azare",
"2342075", "Yola",
"2342033", "New\ Bussa",
"2342087", "Calabar",
"2342056", "Asaba",
"2342084", "Port\ Harcourt",
"2343", "Oyo",
"2342048", "Awka",
"2342088", "Umuahia",
"2342039", "Abeokuta",
"2342044", "Makurdi",
"2342072", "Gombe",
"2342057", "Auchi",
"2342086", "Ahoada",
"2342046", "Onitsha",
"2342035", "Osogbo",
"2342073", "Jos",
"2342031", "Ilorin",
"2342058", "Lokoja",
"2342054", "Sapele",
"2342079", "Jalingo",
"2342066", "Minna",
"2342060", "Sokoto",
"2342062", "Kaduna",
"2342034", "Akure",
"2342089", "Yenagoa",
"2342038", "Oyo",
"234201", "Lagos",
"2342043", "Abakaliki",
"2342037", "Ijebu\ Ode",
"2342083", "Owerri",
"2342069", "Zaria",
"2342042", "Nsukka\ Enugu",
"2342051", "Owoh",
"2342055", "Agbor",
"234209", "Abuja",
"2342082", "Aba",
"2342076", "Maiduguri",};
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