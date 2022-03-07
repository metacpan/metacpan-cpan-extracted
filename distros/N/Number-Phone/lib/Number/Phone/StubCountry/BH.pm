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
package Number::Phone::StubCountry::BH;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20220305001838;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            [13679]|
            8[047]
          ',
                  'pattern' => '(\\d{4})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            1(?:
              3[1356]|
              6[0156]|
              7\\d
            )\\d|
            6(?:
              1[16]\\d|
              500|
              6(?:
                0\\d|
                3[12]|
                44|
                7[7-9]|
                88
              )|
              9[69][69]
            )|
            7(?:
              1(?:
                11|
                78
              )|
              7\\d\\d
            )
          )\\d{4}
        ',
                'geographic' => '
          (?:
            1(?:
              3[1356]|
              6[0156]|
              7\\d
            )\\d|
            6(?:
              1[16]\\d|
              500|
              6(?:
                0\\d|
                3[12]|
                44|
                7[7-9]|
                88
              )|
              9[69][69]
            )|
            7(?:
              1(?:
                11|
                78
              )|
              7\\d\\d
            )
          )\\d{4}
        ',
                'mobile' => '
          (?:
            3(?:
              [1-79]\\d|
              8[0-47-9]
            )\\d|
            6(?:
              3(?:
                00|
                33|
                6[16]
              )|
              6(?:
                3[03-9]|
                [69]\\d|
                7[0-6]
              )
            )
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(84\\d{6})|(
          (?:
            87|
            9[014578]
          )\\d{6}
        )',
                'toll_free' => '80\\d{6}',
                'voip' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+973|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;