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
package Number::Phone::StubCountry::GD;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170908113148;

my $formatters = [
                {
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'pager' => '',
                'geographic' => '
          473(?:
            2(?:
              3[0-2]|
              69
            )|
            3(?:
              2[89]|
              86
            )|
            4(?:
              [06]8|
              3[5-9]|
              4[0-49]|
              5[5-79]|
              68|
              73|
              90
            )|
            63[68]|
            7(?:
              58|
              84
            )|
            800|
            938
          )\\d{4}
        ',
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
                'mobile' => '
          473(?:
            4(?:
              0[2-79]|
              1[04-9]|
              2[0-5]|
              58
            )|
            5(?:
              2[01]|
              3[3-8]
            )|
            901
          )\\d{4}
        ',
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
                'specialrate' => '(900[2-9]\\d{6})',
                'fixed_line' => '
          473(?:
            2(?:
              3[0-2]|
              69
            )|
            3(?:
              2[89]|
              86
            )|
            4(?:
              [06]8|
              3[5-9]|
              4[0-49]|
              5[5-79]|
              68|
              73|
              90
            )|
            63[68]|
            7(?:
              58|
              84
            )|
            800|
            938
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