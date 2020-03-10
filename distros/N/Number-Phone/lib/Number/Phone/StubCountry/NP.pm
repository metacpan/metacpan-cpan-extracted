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
package Number::Phone::StubCountry::NP;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200309202348;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'leading_digits' => '1[2-6]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{7})'
                },
                {
                  'format' => '$1-$2',
                  'leading_digits' => '
            [1-8]|
            9(?:
              [1-579]|
              6[2-6]
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{6})'
                },
                {
                  'format' => '$1-$2',
                  'leading_digits' => '9',
                  'pattern' => '(\\d{3})(\\d{7})'
                }
              ];

my $validators = {
                'fixed_line' => '
          1[0-6]\\d{6}|
          (?:
            2[13-79]|
            3[135-8]|
            4[146-9]|
            5[135-7]|
            6[13-9]|
            7[15-9]|
            8[1-46-9]|
            9[1-79]
          )[2-6]\\d{5}
        ',
                'geographic' => '
          1[0-6]\\d{6}|
          (?:
            2[13-79]|
            3[135-8]|
            4[146-9]|
            5[135-7]|
            6[13-9]|
            7[15-9]|
            8[1-46-9]|
            9[1-79]
          )[2-6]\\d{5}
        ',
                'mobile' => '
          9(?:
            6[0-3]|
            7[245]|
            8[0-24-68]
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+977|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;