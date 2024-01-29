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
package Number::Phone::StubCountry::MT;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20231210185945;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[2357-9]',
                  'pattern' => '(\\d{4})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          20(?:
            3[1-4]|
            6[059]
          )\\d{4}|
          2(?:
            0[19]|
            [1-357]\\d|
            60
          )\\d{5}
        ',
                'geographic' => '
          20(?:
            3[1-4]|
            6[059]
          )\\d{4}|
          2(?:
            0[19]|
            [1-357]\\d|
            60
          )\\d{5}
        ',
                'mobile' => '
          (?:
            7(?:
              210|
              [79]\\d\\d
            )|
            9(?:
              [29]\\d\\d|
              69[67]|
              8(?:
                1[1-3]|
                89|
                97
              )
            )
          )\\d{4}
        ',
                'pager' => '7117\\d{4}',
                'personal_number' => '',
                'specialrate' => '(
          5(?:
            0(?:
              0(?:
                37|
                43
              )|
              (?:
                6\\d|
                70|
                9[0168]
              )\\d
            )|
            [12]\\d0[1-5]
          )\\d{3}
        )|(501\\d{5})',
                'toll_free' => '
          800(?:
            02|
            [3467]\\d
          )\\d{3}
        ',
                'voip' => '3550\\d{4}'
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+356|\D)//g;
      my $self = bless({ country_code => '356', number => $number, formatters => $formatters, validators => $validators, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;