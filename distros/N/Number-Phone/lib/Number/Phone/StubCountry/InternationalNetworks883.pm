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
package Number::Phone::StubCountry::InternationalNetworks883;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20231210185947;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [14]|
            2[24-689]|
            3[02-689]|
            51[24-9]
          ',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{2,8})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '510',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '21',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '51[13]',
                  'pattern' => '(\\d{4})(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[235]',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '',
                'geographic' => '',
                'mobile' => '',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => '
          (?:
            2(?:
              00\\d\\d|
              10
            )|
            (?:
              370[1-9]|
              51\\d0
            )\\d
          )\\d{7}|
          51(?:
            00\\d{5}|
            [24-9]0\\d{4,7}
          )|
          (?:
            1[0-79]|
            2[24-689]|
            3[02-689]|
            4[0-4]
          )0\\d{5,9}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+883|\D)//g;
      my $self = bless({ country_code => '883', number => $number, formatters => $formatters, validators => $validators, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;