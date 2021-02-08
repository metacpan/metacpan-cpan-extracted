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
package Number::Phone::StubCountry::BS;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20210204173824;

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
          242(?:
            3(?:
              02|
              [236][1-9]|
              4[0-24-9]|
              5[0-68]|
              7[347]|
              8[0-4]|
              9[2-467]
            )|
            461|
            502|
            6(?:
              0[1-4]|
              12|
              2[013]|
              [45]0|
              7[67]|
              8[78]|
              9[89]
            )|
            7(?:
              02|
              88
            )
          )\\d{4}
        ',
                'geographic' => '
          242(?:
            3(?:
              02|
              [236][1-9]|
              4[0-24-9]|
              5[0-68]|
              7[347]|
              8[0-4]|
              9[2-467]
            )|
            461|
            502|
            6(?:
              0[1-4]|
              12|
              2[013]|
              [45]0|
              7[67]|
              8[78]|
              9[89]
            )|
            7(?:
              02|
              88
            )
          )\\d{4}
        ',
                'mobile' => '
          242(?:
            3(?:
              5[79]|
              7[56]|
              95
            )|
            4(?:
              [23][1-9]|
              4[1-35-9]|
              5[1-8]|
              6[2-8]|
              7\\d|
              81
            )|
            5(?:
              2[45]|
              3[35]|
              44|
              5[1-46-9]|
              65|
              77
            )|
            6[34]6|
            7(?:
              27|
              38
            )|
            8(?:
              0[1-9]|
              1[02-9]|
              2\\d|
              [89]9
            )
          )\\d{4}
        ',
                'pager' => '',
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
                'specialrate' => '(900[2-9]\\d{6})|(242225\\d{4})',
                'toll_free' => '
          242300\\d{4}|
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