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
package Number::Phone::StubCountry::UA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170702164949;

my $formatters = [
                {
                  'leading_digits' => '
            [38]9|
            4(?:
              [45][0-5]|
              87
            )|
            5(?:
              0|
              6(?:
                3[14-7]|
                7
              )|
              7[37]
            )|
            6[36-8]|
            7|
            9[1-9]
          ',
                  'pattern' => '([3-9]\\d)(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '([3-689]\\d{2})(\\d{3})(\\d{3})',
                  'leading_digits' => '
            3(?:
              [1-46-8]2[013-9]|
              52
            )|
            4(?:
              [1378]2|
              62[013-9]
            )|
            5(?:
              [12457]2|
              6[24]
            )|
            6(?:
              [49]2|
              [12][29]|
              5[24]
            )|
            8[0-8]|
            90
          '
                },
                {
                  'pattern' => '([3-6]\\d{3})(\\d{5})',
                  'leading_digits' => '
            3(?:
              5[013-9]|
              [1-46-8](?:
                22|
                [013-9]
              )
            )|
            4(?:
              [137][013-9]|
              6(?:
                [013-9]|
                22
              )|
              [45][6-9]|
              8[4-6]
            )|
            5(?:
              [1245][013-9]|
              6(?:
                3[02389]|
                [015689]
              )|
              3|
              7[4-6]
            )|
            6(?:
              [49][013-9]|
              5[0135-9]|
              [12][13-8]
            )
          '
                }
              ];

my $validators = {
                'specialrate' => '(900[2-49]\\d{5})',
                'geographic' => '
          (?:
            3[1-8]|
            4[13-8]|
            5[1-7]|
            6[12459]
          )\\d{7}
        ',
                'personal_number' => '',
                'voip' => '89\\d{7}',
                'pager' => '',
                'toll_free' => '800\\d{6}',
                'mobile' => '
          (?:
            39|
            50|
            6[36-8]|
            7[13]|
            9[1-9]
          )\\d{7}
        ',
                'fixed_line' => '
          (?:
            3[1-8]|
            4[13-8]|
            5[1-7]|
            6[12459]
          )\\d{7}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+380|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;