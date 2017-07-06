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
our $VERSION = 1.20170702164946;

my $formatters = [
                {
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'personal_number' => '
          5(?:
            00|
            22|
            33|
            44|
            66|
            77|
            88
          )[2-9]\\d{6}
        ',
                'specialrate' => '(900[2-9]\\d{6})',
                'geographic' => '
          242(?:
            3(?:
              02|
              [236][1-9]|
              4[0-24-9]|
              5[0-68]|
              7[3467]|
              8[0-4]|
              9[2-467]
            )|
            461|
            502|
            6(?:
              0[1-3]|
              12|
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
                'pager' => '',
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
                'voip' => '',
                'mobile' => '
          242(?:
            3(?:
              5[79]|
              [79]5
            )|
            4(?:
              [2-4][1-9]|
              5[1-8]|
              6[2-8]|
              7\\d|
              81
            )|
            5(?:
              2[45]|
              3[35]|
              44|
              5[1-9]|
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
              99
            )
          )\\d{4}
        ',
                'fixed_line' => '
          242(?:
            3(?:
              02|
              [236][1-9]|
              4[0-24-9]|
              5[0-68]|
              7[3467]|
              8[0-4]|
              9[2-467]
            )|
            461|
            502|
            6(?:
              0[1-3]|
              12|
              7[67]|
              8[78]|
              9[89]
            )|
            7(?:
              02|
              88
            )
          )\\d{4}
        '
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