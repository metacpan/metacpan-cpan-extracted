# automatically generated file, don't edit



# Copyright 2024 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::DK;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20240910191015;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[2-9]',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            (?:
              2\\d|
              9[1-46-9]
            )\\d|
            3(?:
              [0-37]\\d|
              4[013]|
              5[0-58]|
              6[01347-9]|
              8[0-8]|
              9[0-79]
            )|
            4(?:
              [0-25]\\d|
              [34][02-9]|
              6[013-579]|
              7[013579]|
              8[0-47]|
              9[0-27]
            )|
            5(?:
              [0-36]\\d|
              4[0146-9]|
              5[03-57-9]|
              7[0568]|
              8[0-358]|
              9[0-69]
            )|
            6(?:
              [013578]\\d|
              2[0-68]|
              4[02-8]|
              6[01689]|
              9[015689]
            )|
            7(?:
              [0-69]\\d|
              7[03-9]|
              8[0147]
            )|
            8(?:
              [16-9]\\d|
              2[0-58]
            )
          )\\d{5}
        ',
                'geographic' => '
          (?:
            (?:
              2\\d|
              9[1-46-9]
            )\\d|
            3(?:
              [0-37]\\d|
              4[013]|
              5[0-58]|
              6[01347-9]|
              8[0-8]|
              9[0-79]
            )|
            4(?:
              [0-25]\\d|
              [34][02-9]|
              6[013-579]|
              7[013579]|
              8[0-47]|
              9[0-27]
            )|
            5(?:
              [0-36]\\d|
              4[0146-9]|
              5[03-57-9]|
              7[0568]|
              8[0-358]|
              9[0-69]
            )|
            6(?:
              [013578]\\d|
              2[0-68]|
              4[02-8]|
              6[01689]|
              9[015689]
            )|
            7(?:
              [0-69]\\d|
              7[03-9]|
              8[0147]
            )|
            8(?:
              [16-9]\\d|
              2[0-58]
            )
          )\\d{5}
        ',
                'mobile' => '
          (?:
            [2-7]\\d|
            8[126-9]|
            9[1-46-9]
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(90\\d{6})',
                'toll_free' => '80\\d{6}',
                'voip' => ''
              };
my $timezones = {
               '' => [
                       'Europe/Copenhagen'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+45|\D)//g;
      my $self = bless({ country_code => '45', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;