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
package Number::Phone::StubCountry::CA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20191211212259;

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
          (?:
            2(?:
              04|
              [23]6|
              [48]9|
              50
            )|
            3(?:
              06|
              43|
              65
            )|
            4(?:
              03|
              1[68]|
              3[178]|
              50
            )|
            5(?:
              06|
              1[49]|
              48|
              79|
              8[17]
            )|
            6(?:
              04|
              13|
              39|
              47
            )|
            7(?:
              0[59]|
              78|
              8[02]
            )|
            8(?:
              [06]7|
              19|
              25|
              73
            )|
            90[25]
          )[2-9]\\d{6}
        |
          (?:
            2(?:
              04|
              [23]6|
              [48]9|
              50
            )|
            3(?:
              06|
              43|
              65
            )|
            4(?:
              03|
              1[68]|
              3[178]|
              50
            )|
            5(?:
              06|
              1[49]|
              48|
              79|
              8[17]
            )|
            6(?:
              04|
              13|
              39|
              47
            )|
            7(?:
              0[59]|
              78|
              8[02]
            )|
            8(?:
              [06]7|
              19|
              25|
              73
            )|
            90[25]
          )[2-9]\\d{6}
        )',
                'pager' => '',
                'personal_number' => '
          (?:
            5(?:
              00|
              2[12]|
              33|
              44|
              66|
              77|
              88
            )|
            622
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
                'voip' => '600[2-9]\\d{6}'
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