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
package Number::Phone::StubCountry::VI;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180410221547;

my $formatters = [
                {
                  'intl_format' => 'NA',
                  'format' => '$1-$2',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})',
                  'format' => '($1) $2-$3',
                  'intl_format' => '$1-$2-$3'
                }
              ];

my $validators = {
                'specialrate' => '(900[2-9]\\d{6})',
                'geographic' => '(
          340(?:
            2(?:
              01|
              2[0678]|
              44|
              77
            )|
            3(?:
              32|
              44
            )|
            4(?:
              22|
              7[34]
            )|
            5(?:
              1[34]|
              55
            )|
            6(?:
              26|
              4[23]|
              77|
              9[023]
            )|
            7(?:
              1[2-589]|
              27|
              7\\d
            )|
            884|
            998
          )\\d{4}
        |
          340(?:
            2(?:
              01|
              2[0678]|
              44|
              77
            )|
            3(?:
              32|
              44
            )|
            4(?:
              22|
              7[34]
            )|
            5(?:
              1[34]|
              55
            )|
            6(?:
              26|
              4[23]|
              77|
              9[023]
            )|
            7(?:
              1[2-589]|
              27|
              7\\d
            )|
            884|
            998
          )\\d{4}
        )',
                'personal_number' => '
          5(?:
            (?:
              00|
              22|
              33|
              44|
              66|
              77|
              88
            )[2-9]|
            21[23]
          )\\d{6}
        ',
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