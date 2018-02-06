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
our $VERSION = 1.20180203200235;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'pattern' => '(1)(\\d{7})',
                  'leading_digits' => '1[2-6]',
                  'national_rule' => '0$1'
                },
                {
                  'pattern' => '(\\d{2})(\\d{6})',
                  'leading_digits' => '
            1[01]|
            [2-8]|
            9(?:
              [1-69]|
              7[15-9]
            )
          ',
                  'format' => '$1-$2',
                  'national_rule' => '0$1'
                },
                {
                  'national_rule' => '$1',
                  'pattern' => '(9\\d{2})(\\d{7})',
                  'leading_digits' => '
            9(?:
              6[013]|
              7[245]|
              8
            )
          ',
                  'format' => '$1-$2'
                }
              ];

my $validators = {
                'voip' => '',
                'pager' => '',
                'toll_free' => '',
                'fixed_line' => '
          (?:
            1[0-6]\\d|
            2[13-79][2-6]|
            3[135-8][2-6]|
            4[146-9][2-6]|
            5[135-7][2-6]|
            6[13-9][2-6]|
            7[15-9][2-6]|
            8[1-46-9][2-6]|
            9[1-79][2-6]
          )\\d{5}
        ',
                'specialrate' => '',
                'geographic' => '
          (?:
            1[0-6]\\d|
            2[13-79][2-6]|
            3[135-8][2-6]|
            4[146-9][2-6]|
            5[135-7][2-6]|
            6[13-9][2-6]|
            7[15-9][2-6]|
            8[1-46-9][2-6]|
            9[1-79][2-6]
          )\\d{5}
        ',
                'personal_number' => '',
                'mobile' => '
          9(?:
            6[0-3]|
            7[245]|
            8[0-24-68]
          )\\d{7}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+977|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      {
        no warnings 'uninitialized';
        $number =~ s/^(?:0)//;
      }
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;