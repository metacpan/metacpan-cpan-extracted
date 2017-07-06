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
package Number::Phone::StubCountry::JM;
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
                'geographic' => '(
          876(?:
            5(?:
              0[12]|
              1[0-468]|
              2[35]|
              63
            )|
            6(?:
              0[1-3579]|
              1[027-9]|
              [23]\\d|
              40|
              5[06]|
              6[2-589]|
              7[05]|
              8[04]|
              9[4-9]
            )|
            7(?:
              0[2-689]|
              [1-6]\\d|
              8[056]|
              9[45]
            )|
            9(?:
              0[1-8]|
              1[02378]|
              [2-8]\\d|
              9[2-468]
            )
          )\\d{4}
        |
          876(?:
            2[14-9]\\d|
            [348]\\d{2}|
            5(?:
              0[3-9]|
              [2-57-9]\\d|
              6[0-24-9]
            )|
            7(?:
              0[07]|
              7\\d|
              8[1-47-9]|
              9[0-36-9]
            )|
            9(?:
              [01]9|
              9[0579]
            )
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
                'pager' => '',
                'voip' => ''
              };
use Number::Phone::NANP::Data;
sub areaname {
Number::Phone::NANP::Data::_areaname('1'.shift()->{number}); }

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+1|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  return $self->is_valid() ? $self : undef;
}
1;