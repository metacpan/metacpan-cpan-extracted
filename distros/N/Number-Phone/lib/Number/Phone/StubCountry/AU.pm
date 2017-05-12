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
package Number::Phone::StubCountry::AU;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170314173053;

my $formatters = [
                {
                  'pattern' => '([2378])(\\d{4})(\\d{4})',
                  'leading_digits' => '[2378]'
                },
                {
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})',
                  'leading_digits' => '
            [45]|
            14
          '
                },
                {
                  'pattern' => '(16)(\\d{3,4})',
                  'leading_digits' => '16'
                },
                {
                  'leading_digits' => '16',
                  'pattern' => '(16)(\\d{3})(\\d{2,4})'
                },
                {
                  'leading_digits' => '
            1(?:
              [38]00|
              90
            )
          ',
                  'pattern' => '(1[389]\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'pattern' => '(180)(2\\d{3})',
                  'leading_digits' => '1802'
                },
                {
                  'leading_digits' => '19[13]',
                  'pattern' => '(19\\d)(\\d{3})'
                },
                {
                  'leading_digits' => '19[679]',
                  'pattern' => '(19\\d{2})(\\d{4})'
                },
                {
                  'leading_digits' => '13[1-9]',
                  'pattern' => '(13)(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'mobile' => '
          14(?:
            5\\d|
            71
          )\\d{5}|
          4(?:
            [0-3]\\d|
            4[47-9]|
            5[0-25-9]|
            6[6-9]|
            7[02-9]|
            8[147-9]|
            9[017-9]
          )\\d{6}
        ',
                'specialrate' => '(
          13(?:
            00\\d{3}|
            45[0-4]|
            \\d
          )\\d{3}
        )|(
          19(?:
            0[0126]\\d|
            [679]
          )\\d{5}
        )',
                'toll_free' => '
          180(?:
            0\\d{3}|
            2
          )\\d{3}
        ',
                'geographic' => '
          [237]\\d{8}|
          8(?:
            [6-8]\\d{3}|
            9(?:
              [02-9]\\d{2}|
              1(?:
                [0-57-9]\\d|
                6[0135-9]
              )
            )
          )\\d{4}
        ',
                'personal_number' => '500\\d{6}',
                'pager' => '16\\d{3,7}',
                'voip' => '550\\d{6}',
                'fixed_line' => '
          [237]\\d{8}|
          8(?:
            [6-8]\\d{3}|
            9(?:
              [02-9]\\d{2}|
              1(?:
                [0-57-9]\\d|
                6[0135-9]
              )
            )
          )\\d{4}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+61|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;