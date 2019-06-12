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
package Number::Phone::StubCountry::EG;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190611222640;

my $formatters = [
                {
                  'leading_digits' => '[23]',
                  'format' => '$1 $2',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{7,8})'
                },
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2',
                  'pattern' => '(\\d{2})(\\d{6,7})',
                  'leading_digits' => '
            1[35]|
            [4-6]|
            8[2468]|
            9[235-7]
          '
                },
                {
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[189]'
                }
              ];

my $validators = {
                'geographic' => '
          (?:
            15\\d|
            57[23]
          )\\d{5,6}|
          (?:
            13[23]|
            (?:
              2[2-4]|
              3
            )\\d|
            4(?:
              0[2-5]|
              [578][23]|
              64
            )|
            5(?:
              0[2-7]|
              5\\d
            )|
            6[24-689]3|
            8(?:
              2[2-57]|
              4[26]|
              6[237]|
              8[2-4]
            )|
            9(?:
              2[27]|
              3[24]|
              52|
              6[2356]|
              7[2-4]
            )
          )\\d{6}
        ',
                'specialrate' => '(900\\d{7})',
                'fixed_line' => '
          (?:
            15\\d|
            57[23]
          )\\d{5,6}|
          (?:
            13[23]|
            (?:
              2[2-4]|
              3
            )\\d|
            4(?:
              0[2-5]|
              [578][23]|
              64
            )|
            5(?:
              0[2-7]|
              5\\d
            )|
            6[24-689]3|
            8(?:
              2[2-57]|
              4[26]|
              6[237]|
              8[2-4]
            )|
            9(?:
              2[27]|
              3[24]|
              52|
              6[2356]|
              7[2-4]
            )
          )\\d{6}
        ',
                'voip' => '',
                'pager' => '',
                'personal_number' => '',
                'toll_free' => '800\\d{7}',
                'mobile' => '1[0-25]\\d{8}'
              };
my %areanames = (
  2013 => "Banha",
  2015 => "10th\ of\ Ramadan",
  202 => "Cairo\/Giza\/Qalyubia",
  203 => "Alexandria",
  2040 => "Tanta",
  2045 => "Damanhur",
  2046 => "Marsa\ Matruh",
  2047 => "Kafr\ El\-Sheikh",
  2048 => "Monufia",
  2050 => "Mansoura",
  2055 => "Zagazig",
  20554 => "10th\ of\ Ramadan",
  2057 => "Damietta",
  2062 => "Suez",
  2064 => "Ismailia",
  2065 => "Red\ Sea",
  2066 => "Port\ Said",
  2068 => "El\-Arish",
  2069 => "El\-Tor",
  2082 => "Beni\ Suef",
  2084 => "Fayoum",
  2086 => "Minia",
  2088 => "Assiout",
  2092 => "Wadi\ El\-Gedid",
  2093 => "Sohag",
  2095 => "Luxor",
  2096 => "Qena",
  2097 => "Aswan",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+20|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;