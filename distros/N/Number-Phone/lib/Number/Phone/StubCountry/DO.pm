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
package Number::Phone::StubCountry::DO;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200904144531;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'intl_format' => 'NA',
                  'leading_digits' => '[2-9]',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '($1) $2-$3',
                  'intl_format' => '$1-$2-$3',
                  'leading_digits' => '[2-9]',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'geographic' => '(
          8(?:
            [04]9[2-9]\\d\\d|
            29(?:
              2(?:
                [0-59]\\d|
                6[04-9]|
                7[0-27]|
                8[0237-9]
              )|
              3(?:
                [0-35-9]\\d|
                4[7-9]
              )|
              [45]\\d\\d|
              6(?:
                [0-27-9]\\d|
                [3-5][1-9]|
                6[0135-8]
              )|
              7(?:
                0[013-9]|
                [1-37]\\d|
                4[1-35689]|
                5[1-4689]|
                6[1-57-9]|
                8[1-79]|
                9[1-8]
              )|
              8(?:
                0[146-9]|
                1[0-48]|
                [248]\\d|
                3[1-79]|
                5[01589]|
                6[013-68]|
                7[124-8]|
                9[0-8]
              )|
              9(?:
                [0-24]\\d|
                3[02-46-9]|
                5[0-79]|
                60|
                7[0169]|
                8[57-9]|
                9[02-9]
              )
            )
          )\\d{4}
        |8[024]9[2-9]\\d{6})',
                'pager' => '',
                'personal_number' => '
          52(?:
            35(?:
              [02-46-9]\\d|
              1[02-9]|
              5[0-46-9]
            )|
            45(?:
              [034]\\d|
              1[02-9]|
              2[024-9]|
              5[0-46-9]
            )
          )\\d{4}|
          52(?:
            3[2-46-9]|
            4[2-4]
          )(?:
            [02-9]\\d|
            1[02-9]
          )\\d{4}|
          5(?:
            00|
            2[12]|
            33|
            44|
            66|
            77|
            88
          )[2-9]\\d{6}
        ',
                'specialrate' => '(900[2-9]\\d{6})',
                'toll_free' => '
          8(?:
            00|
            33|
            44|
            55|
            66|
            77|
            88
          )[2-9]\\d{6}
        ',
                'voip' => ''
              };
use Number::Phone::NANP::Data;
sub areaname {
# uncoverable subroutine - no data for most NANP countries
                            # uncoverable statement
Number::Phone::NANP::Data::_areaname('1'.shift()->{number}); }

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+1|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;