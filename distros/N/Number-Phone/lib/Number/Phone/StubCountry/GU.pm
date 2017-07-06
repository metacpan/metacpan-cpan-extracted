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
package Number::Phone::StubCountry::GU;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170702164948;

my $formatters = [
                {
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'geographic' => '(
          671(?:
            3(?:
              00|
              3[39]|
              4[349]|
              55|
              6[26]
            )|
            4(?:
              56|
              7[1-9]|
              8[0236-9]
            )|
            5(?:
              55|
              6[2-5]|
              88
            )|
            6(?:
              3[2-578]|
              4[24-9]|
              5[34]|
              78|
              8[5-9]
            )|
            7(?:
              [079]7|
              2[0167]|
              3[45]|
              47|
              8[789]
            )|
            8(?:
              [2-5789]8|
              6[48]
            )|
            9(?:
              2[29]|
              6[79]|
              7[179]|
              8[789]|
              9[78]
            )
          )\\d{4}
        |
          671(?:
            3(?:
              00|
              3[39]|
              4[349]|
              55|
              6[26]
            )|
            4(?:
              56|
              7[1-9]|
              8[0236-9]
            )|
            5(?:
              55|
              6[2-5]|
              88
            )|
            6(?:
              3[2-578]|
              4[24-9]|
              5[34]|
              78|
              8[5-9]
            )|
            7(?:
              [079]7|
              2[0167]|
              3[45]|
              47|
              8[789]
            )|
            8(?:
              [2-5789]8|
              6[48]
            )|
            9(?:
              2[29]|
              6[79]|
              7[179]|
              8[789]|
              9[78]
            )
          )\\d{4}
        )',
                'specialrate' => '(900[2-9]\\d{6})',
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
                'voip' => '',
                'pager' => '',
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