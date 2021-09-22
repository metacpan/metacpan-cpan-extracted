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
package Number::Phone::StubCountry::KY;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20210921211832;

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
                'fixed_line' => '
          345(?:
            2(?:
              22|
              3[23]|
              44|
              66
            )|
            333|
            444|
            6(?:
              23|
              38|
              40
            )|
            7(?:
              30|
              4[35-79]|
              6[6-9]|
              77
            )|
            8(?:
              00|
              1[45]|
              25|
              [48]8
            )|
            9(?:
              14|
              4[035-9]
            )
          )\\d{4}
        ',
                'geographic' => '
          345(?:
            2(?:
              22|
              3[23]|
              44|
              66
            )|
            333|
            444|
            6(?:
              23|
              38|
              40
            )|
            7(?:
              30|
              4[35-79]|
              6[6-9]|
              77
            )|
            8(?:
              00|
              1[45]|
              25|
              [48]8
            )|
            9(?:
              14|
              4[035-9]
            )
          )\\d{4}
        ',
                'mobile' => '
          345(?:
            32[1-9]|
            42[0-4]|
            5(?:
              1[67]|
              2[5-79]|
              4[6-9]|
              50|
              76
            )|
            649|
            9(?:
              1[679]|
              2[2-9]|
              3[06-9]|
              90
            )
          )\\d{4}
        ',
                'pager' => '345849\\d{4}',
                'personal_number' => '
          52(?:
            3(?:
              [2-46-9][02-9]\\d|
              5(?:
                [02-46-9]\\d|
                5[0-46-9]
              )
            )|
            4(?:
              [2-478][02-9]\\d|
              5(?:
                [034]\\d|
                2[024-9]|
                5[0-46-9]
              )|
              6(?:
                0[1-9]|
                [2-9]\\d
              )|
              9(?:
                [05-9]\\d|
                2[0-5]|
                49
              )
            )
          )\\d{4}|
          52[34][2-9]1[02-9]\\d{4}|
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
                'specialrate' => '(
          (?:
            345976|
            900[2-9]\\d\\d
          )\\d{4}
        )',
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