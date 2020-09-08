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
package Number::Phone::StubCountry::BB;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200904144527;

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
          246(?:
            2(?:
              2[78]|
              7[0-4]
            )|
            4(?:
              1[024-6]|
              2\\d|
              3[2-9]
            )|
            5(?:
              20|
              [34]\\d|
              54|
              7[1-3]
            )|
            6(?:
              2\\d|
              38
            )|
            7[35]7|
            9(?:
              1[89]|
              63
            )
          )\\d{4}
        ',
                'geographic' => '
          246(?:
            2(?:
              2[78]|
              7[0-4]
            )|
            4(?:
              1[024-6]|
              2\\d|
              3[2-9]
            )|
            5(?:
              20|
              [34]\\d|
              54|
              7[1-3]
            )|
            6(?:
              2\\d|
              38
            )|
            7[35]7|
            9(?:
              1[89]|
              63
            )
          )\\d{4}
        ',
                'mobile' => '
          246(?:
            2(?:
              [3568]\\d|
              4[0-57-9]
            )|
            45\\d|
            69[5-7]|
            8(?:
              [2-5]\\d|
              83
            )
          )\\d{4}
        ',
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
                'specialrate' => '(
          (?:
            246976|
            900[2-9]\\d\\d
          )\\d{4}
        )|(
          246(?:
            292|
            367|
            4(?:
              1[7-9]|
              3[01]|
              44|
              67
            )|
            7(?:
              36|
              53
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
                'voip' => '24631\\d{5}'
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