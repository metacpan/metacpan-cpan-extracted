# automatically generated file, don't edit



# Copyright 2023 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20230614174401;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'leading_digits' => '310',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1-$2',
                  'intl_format' => 'NA',
                  'leading_digits' => '
            [24-9]|
            3(?:
              [02-9]|
              1[1-9]
            )
          ',
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
              50|
              63
            )|
            3(?:
              06|
              43|
              54|
              6[578]|
              82
            )|
            4(?:
              03|
              1[68]|
              [26]8|
              3[178]|
              50|
              74
            )|
            5(?:
              06|
              1[49]|
              48|
              79|
              8[147]
            )|
            6(?:
              04|
              [18]3|
              39|
              47|
              72
            )|
            7(?:
              0[59]|
              42|
              53|
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
              50|
              63
            )|
            3(?:
              06|
              43|
              54|
              6[578]|
              82
            )|
            4(?:
              03|
              1[68]|
              [26]8|
              3[178]|
              50|
              74
            )|
            5(?:
              06|
              1[49]|
              48|
              79|
              8[147]
            )|
            6(?:
              04|
              [18]3|
              39|
              47|
              72
            )|
            7(?:
              0[59]|
              42|
              53|
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
          (?:
            5(?:
              00|
              2[125-9]|
              33|
              44|
              66|
              77|
              88
            )|
            622
          )[2-9]\\d{6}
        ',
                'specialrate' => '(900[2-9]\\d{6})|(310\\d{4})',
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
      my $self = bless({ country_code => '1', number => $number, formatters => $formatters, validators => $validators, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;