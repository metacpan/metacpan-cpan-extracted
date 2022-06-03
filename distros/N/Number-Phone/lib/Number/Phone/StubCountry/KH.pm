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
package Number::Phone::StubCountry::KH;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20220601185319;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[1-9]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '1',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          23(?:
            4(?:
              [2-4]|
              [56]\\d
            )|
            [568]\\d\\d
          )\\d{4}|
          23[236-9]\\d{5}|
          (?:
            2[4-6]|
            3[2-6]|
            4[2-4]|
            [5-7][2-5]
          )(?:
            (?:
              [237-9]|
              4[56]|
              5\\d
            )\\d{5}|
            6\\d{5,6}
          )
        ',
                'geographic' => '
          23(?:
            4(?:
              [2-4]|
              [56]\\d
            )|
            [568]\\d\\d
          )\\d{4}|
          23[236-9]\\d{5}|
          (?:
            2[4-6]|
            3[2-6]|
            4[2-4]|
            [5-7][2-5]
          )(?:
            (?:
              [237-9]|
              4[56]|
              5\\d
            )\\d{5}|
            6\\d{5,6}
          )
        ',
                'mobile' => '
          (?:
            (?:
              1[28]|
              3[18]|
              9[67]
            )\\d|
            6[016-9]|
            7(?:
              [07-9]|
              [16]\\d
            )|
            8(?:
              [013-79]|
              8\\d
            )
          )\\d{6}|
          (?:
            1\\d|
            9[0-57-9]
          )\\d{6}|
          (?:
            2[3-6]|
            3[2-6]|
            4[2-4]|
            [5-7][2-5]
          )48\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(
          1900(?:
            1\\d|
            2[09]
          )\\d{4}
        )',
                'toll_free' => '
          1800(?:
            1\\d|
            2[019]
          )\\d{4}
        ',
                'voip' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+855|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;