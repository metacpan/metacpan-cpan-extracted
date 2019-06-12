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
package Number::Phone::StubCountry::SB;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190611222641;

my $formatters = [
                {
                  'pattern' => '(\\d{2})(\\d{5})',
                  'format' => '$1 $2',
                  'leading_digits' => '
            7|
            8[4-9]|
            9(?:
              [1-8]|
              9[0-8]
            )
          '
                }
              ];

my $validators = {
                'toll_free' => '1[38]\\d{3}',
                'mobile' => '
          48\\d{3}|
          (?:
            (?:
              7[1-9]|
              8[4-9]
            )\\d|
            9(?:
              1[2-9]|
              2[013-9]|
              3[0-2]|
              [46]\\d|
              5[0-46-9]|
              7[0-689]|
              8[0-79]|
              9[0-8]
            )
          )\\d{4}
        ',
                'personal_number' => '',
                'pager' => '',
                'fixed_line' => '
          (?:
            1[4-79]|
            [23]\\d|
            4[0-2]|
            5[03]|
            6[0-37]
          )\\d{3}
        ',
                'voip' => '5[12]\\d{3}',
                'specialrate' => '',
                'geographic' => '
          (?:
            1[4-79]|
            [23]\\d|
            4[0-2]|
            5[03]|
            6[0-37]
          )\\d{3}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+677|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;