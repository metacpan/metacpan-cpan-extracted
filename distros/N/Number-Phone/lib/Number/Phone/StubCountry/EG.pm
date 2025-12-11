# automatically generated file, don't edit



# Copyright 2025 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::EG;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20251210153522;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[23]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{7,8})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            1[35]|
            [4-6]|
            8[2468]|
            9[235-7]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{6,7})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[89]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '1',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{8})'
                }
              ];

my $validators = {
                'fixed_line' => '
          13[23]\\d{6}|
          (?:
            15|
            57
          )\\d{6,7}|
          (?:
            2\\d|
            3|
            4[05-8]|
            5[05]|
            6[24-689]|
            8[2468]|
            9[235-7]
          )\\d{7}
        ',
                'geographic' => '
          13[23]\\d{6}|
          (?:
            15|
            57
          )\\d{6,7}|
          (?:
            2\\d|
            3|
            4[05-8]|
            5[05]|
            6[24-689]|
            8[2468]|
            9[235-7]
          )\\d{7}
        ',
                'mobile' => '1[0-25]\\d{8}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(900\\d{7})',
                'toll_free' => '800\\d{7}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"2015", "10th\ of\ Ramadan",
"2045", "Damanhur",
"2082", "Beni\ Suef",
"2047", "Kafr\ El\-Sheikh",
"203", "Alexandria",
"2048", "Monufia",
"2084", "Fayoum",
"2066", "Port\ Said",
"2040", "Tanta",
"202", "Cairo\/Giza\/Qalyubia",
"2092", "Wadi\ El\-Gedid",
"2065", "Red\ Sea",
"2093", "Sohag",
"2046", "Marsa\ Matruh",
"2068", "El\-Arish",
"20554", "10th\ of\ Ramadan",
"2069", "El\-Tor",
"2088", "Assiout",
"2096", "Qena",
"2013", "Banha",
"2057", "Damietta",
"2055", "Zagazig",
"2095", "Luxor",
"2062", "Suez",
"2097", "Aswan",
"2086", "Minia",
"2064", "Ismailia",
"2050", "Mansoura",};
my $timezones = {
               '' => [
                       'Africa/Cairo'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+20|\D)//g;
      my $self = bless({ country_code => '20', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '20', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;