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
package Number::Phone::StubCountry::US;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200511123716;

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
              0[1-35-9]|
              1[02-9]|
              2[03-589]|
              3[149]|
              4[08]|
              5[1-46]|
              6[0279]|
              7[0269]|
              8[13]
            )|
            3(?:
              0[1-57-9]|
              1[02-9]|
              2[0135]|
              3[0-24679]|
              4[167]|
              5[12]|
              6[014]|
              8[056]
            )|
            4(?:
              0[124-9]|
              1[02-579]|
              2[3-5]|
              3[0245]|
              4[0235]|
              58|
              6[39]|
              7[0589]|
              8[04]
            )|
            5(?:
              0[1-57-9]|
              1[0235-8]|
              20|
              3[0149]|
              4[01]|
              5[19]|
              6[1-47]|
              7[013-5]|
              8[056]
            )|
            6(?:
              0[1-35-9]|
              1[024-9]|
              2[03689]|
              [34][016]|
              5[0179]|
              6[0-279]|
              78|
              8[0-29]
            )|
            7(?:
              0[1-46-8]|
              1[2-9]|
              2[04-7]|
              3[1247]|
              4[037]|
              5[47]|
              6[02359]|
              7[02-59]|
              8[156]
            )|
            8(?:
              0[1-68]|
              1[02-8]|
              2[08]|
              3[0-28]|
              4[3578]|
              5[046-9]|
              6[02-5]|
              7[028]
            )|
            9(?:
              0[1346-9]|
              1[02-9]|
              2[0589]|
              3[0146-8]|
              4[0179]|
              5[12469]|
              7[0-389]|
              8[04-69]
            )
          )[2-9]\\d{6}
        |
          (?:
            2(?:
              0[1-35-9]|
              1[02-9]|
              2[03-589]|
              3[149]|
              4[08]|
              5[1-46]|
              6[0279]|
              7[0269]|
              8[13]
            )|
            3(?:
              0[1-57-9]|
              1[02-9]|
              2[0135]|
              3[0-24679]|
              4[167]|
              5[12]|
              6[014]|
              8[056]
            )|
            4(?:
              0[124-9]|
              1[02-579]|
              2[3-5]|
              3[0245]|
              4[0235]|
              58|
              6[39]|
              7[0589]|
              8[04]
            )|
            5(?:
              0[1-57-9]|
              1[0235-8]|
              20|
              3[0149]|
              4[01]|
              5[19]|
              6[1-47]|
              7[013-5]|
              8[056]
            )|
            6(?:
              0[1-35-9]|
              1[024-9]|
              2[03689]|
              [34][016]|
              5[0179]|
              6[0-279]|
              78|
              8[0-29]
            )|
            7(?:
              0[1-46-8]|
              1[2-9]|
              2[04-7]|
              3[1247]|
              4[037]|
              5[47]|
              6[02359]|
              7[02-59]|
              8[156]
            )|
            8(?:
              0[1-68]|
              1[02-8]|
              2[08]|
              3[0-28]|
              4[3578]|
              5[046-9]|
              6[02-5]|
              7[028]
            )|
            9(?:
              0[1346-9]|
              1[02-9]|
              2[0589]|
              3[0146-8]|
              4[0179]|
              5[12469]|
              7[0-389]|
              8[04-69]
            )
          )[2-9]\\d{6}
        )',
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
Number::Phone::NANP::Data::_areaname('1'.shift()->{number}); }

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+1|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;