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
package Number::Phone::StubCountry::SG;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200904144535;

my $formatters = [
                {
                  'format' => '$1',
                  'intl_format' => 'NA',
                  'leading_digits' => '
            1(?:
              [013-8]|
              9(?:
                0[1-9]|
                [1-9]
              )
            )|
            77
          ',
                  'pattern' => '(\\d{4,5})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            [369]|
            8(?:
              0[1-3]|
              [1-9]
            )
          ',
                  'pattern' => '(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '8',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '7',
                  'pattern' => '(\\d{4})(\\d{4})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '1',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          662[0-24-9]\\d{4}|
          6(?:
            [1-578]\\d|
            6[013-57-9]|
            9[0-35-9]
          )\\d{5}
        ',
                'geographic' => '
          662[0-24-9]\\d{4}|
          6(?:
            [1-578]\\d|
            6[013-57-9]|
            9[0-35-9]
          )\\d{5}
        ',
                'mobile' => '
          (?:
            8(?:
              0(?:
                1[0-8]|
                2[7-9]|
                3[01]
              )|
              [1-8]\\d\\d|
              9(?:
                [0-24]\\d|
                3[0-489]|
                5[0-2]
              )
            )|
            9[0-8]\\d\\d
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(1900\\d{7})|(7000\\d{7})',
                'toll_free' => '
          (?:
            18|
            8
          )00\\d{7}
        ',
                'voip' => '
          (?:
            3[12]\\d|
            666
          )\\d{5}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+65|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;