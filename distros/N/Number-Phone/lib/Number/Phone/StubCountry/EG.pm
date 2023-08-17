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
package Number::Phone::StubCountry::EG;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20230614174403;

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
                  'leading_digits' => '[189]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
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
            2[2-4]|
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
            2[2-4]|
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
$areanames{en} = {"2048", "Monufia",
"203", "Alexandria",
"2055", "Zagazig",
"2050", "Mansoura",
"2097", "Aswan",
"2046", "Marsa\ Matruh",
"2065", "Red\ Sea",
"2069", "El\-Tor",
"2095", "Luxor",
"2057", "Damietta",
"20554", "10th\ of\ Ramadan",
"2013", "Banha",
"2068", "El\-Arish",
"2084", "Fayoum",
"2040", "Tanta",
"2092", "Wadi\ El\-Gedid",
"2045", "Damanhur",
"2082", "Beni\ Suef",
"2066", "Port\ Said",
"202", "Cairo\/Giza\/Qalyubia",
"2062", "Suez",
"2086", "Minia",
"2015", "10th\ of\ Ramadan",
"2096", "Qena",
"2047", "Kafr\ El\-Sheikh",
"2088", "Assiout",
"2064", "Ismailia",
"2093", "Sohag",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+20|\D)//g;
      my $self = bless({ country_code => '20', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '20', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;