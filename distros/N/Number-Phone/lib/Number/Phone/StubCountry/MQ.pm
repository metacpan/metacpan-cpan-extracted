# automatically generated file, don't edit



# Copyright 2025 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::MQ;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20251210153524;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            [5-79]|
            8(?:
              0[6-9]|
              [36]
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '8',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            596(?:
              [03-7]\\d|
              1[05]|
              2[7-9]|
              8[0-39]|
              9[04-9]
            )|
            80[6-9]\\d\\d|
            9(?:
              477[6-9]|
              767[4589]
            )
          )\\d{4}
        ',
                'geographic' => '
          (?:
            596(?:
              [03-7]\\d|
              1[05]|
              2[7-9]|
              8[0-39]|
              9[04-9]
            )|
            80[6-9]\\d\\d|
            9(?:
              477[6-9]|
              767[4589]
            )
          )\\d{4}
        ',
                'mobile' => '
          (?:
            69[67]\\d\\d|
            7091[0-3]
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(8[129]\\d{7})',
                'toll_free' => '80[0-5]\\d{6}',
                'voip' => '
          9(?:
            397[0-3]|
            477[0-5]|
            76(?:
              6\\d|
              7[0-367]
            )
          )\\d{4}
        '
              };
my $timezones = {
               '' => [
                       'America/Martinique'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+596|\D)//g;
      my $self = bless({ country_code => '596', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '596', number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;