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
package Number::Phone::StubCountry::BO;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20210602223257;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            [23]|
            4[46]
          ',
                  'pattern' => '(\\d)(\\d{7})'
                },
                {
                  'format' => '$1',
                  'leading_digits' => '[67]',
                  'pattern' => '(\\d{8})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '8',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              2\\d\\d|
              5(?:
                11|
                [258]\\d|
                9[67]
              )|
              6(?:
                12|
                2\\d|
                9[34]
              )|
              8(?:
                2[34]|
                39|
                62
              )
            )|
            3(?:
              3\\d\\d|
              4(?:
                6\\d|
                8[24]
              )|
              8(?:
                25|
                42|
                5[257]|
                86|
                9[25]
              )|
              9(?:
                [27]\\d|
                3[2-4]|
                4[248]|
                5[24]|
                6[2-6]
              )
            )|
            4(?:
              4\\d\\d|
              6(?:
                11|
                [24689]\\d|
                72
              )
            )
          )\\d{4}
        ',
                'geographic' => '
          (?:
            2(?:
              2\\d\\d|
              5(?:
                11|
                [258]\\d|
                9[67]
              )|
              6(?:
                12|
                2\\d|
                9[34]
              )|
              8(?:
                2[34]|
                39|
                62
              )
            )|
            3(?:
              3\\d\\d|
              4(?:
                6\\d|
                8[24]
              )|
              8(?:
                25|
                42|
                5[257]|
                86|
                9[25]
              )|
              9(?:
                [27]\\d|
                3[2-4]|
                4[248]|
                5[24]|
                6[2-6]
              )
            )|
            4(?:
              4\\d\\d|
              6(?:
                11|
                [24689]\\d|
                72
              )
            )
          )\\d{4}
        ',
                'mobile' => '[67]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '8001[07]\\d{4}',
                'voip' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+591|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0(1\d)?)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;