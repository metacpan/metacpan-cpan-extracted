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
our $VERSION = 1.20180619214156;

my $formatters = [
                {
                  'leading_digits' => '
            1\\d[1-9]|
            [2-9]
          ',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                },
                {
                  'leading_digits' => '1[89]00',
                  'format' => '$1 $2 $3',
                  'pattern' => '(1[89]00)(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'pager' => '',
                'geographic' => '
          (?:
            2[3-6]|
            3[2-6]|
            4[2-4]|
            [5-7][2-5]
          )(?:
            [237-9]|
            4[56]|
            5\\d|
            6\\d?
          )\\d{5}|
          23(?:
            4[234]|
            8\\d{2}
          )\\d{4}
        ',
                'personal_number' => '',
                'voip' => '',
                'fixed_line' => '
          (?:
            2[3-6]|
            3[2-6]|
            4[2-4]|
            [5-7][2-5]
          )(?:
            [237-9]|
            4[56]|
            5\\d|
            6\\d?
          )\\d{5}|
          23(?:
            4[234]|
            8\\d{2}
          )\\d{4}
        ',
                'toll_free' => '
          1800(?:
            1\\d|
            2[019]
          )\\d{4}
        ',
                'mobile' => '
          (?:
            1(?:
              [013-79]\\d|
              [28]\\d{1,2}
            )|
            2[3-6]48|
            3(?:
              [18]\\d{2}|
              [2-6]48
            )|
            4[2-4]48|
            5[2-5]48|
            6(?:
              [016-9]\\d|
              [2-5]48
            )|
            7(?:
              [07-9]\\d|
              [16]\\d{2}|
              [2-5]48
            )|
            8(?:
              [013-79]\\d|
              8\\d{2}
            )|
            9(?:
              6\\d{2}|
              7\\d{1,2}|
              [0-589]\\d
            )
          )\\d{5}
        ',
                'specialrate' => '(
          1900(?:
            1\\d|
            2[09]
          )\\d{4}
        )'
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