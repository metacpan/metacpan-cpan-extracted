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
package Number::Phone::StubCountry::EC;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180203200234;

my $formatters = [
                {
                  'format' => '$1 $2-$3',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})',
                  'leading_digits' => '
            [247]|
            [356][2-8]
          ',
                  'national_rule' => '(0$1)',
                  'intl_format' => '$1-$2-$3'
                },
                {
                  'national_rule' => '0$1',
                  'leading_digits' => '9',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})',
                  'format' => '$1 $2 $3'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '1800',
                  'pattern' => '(1800)(\\d{3})(\\d{3,4})',
                  'national_rule' => '$1'
                }
              ];

my $validators = {
                'pager' => '',
                'voip' => '[2-7]890\\d{4}',
                'mobile' => '
          9(?:
            (?:
              39|
              [45][89]|
              7[7-9]|
              [89]\\d
            )\\d{2}|
            6(?:
              [017-9]\\d{2}|
              2(?:
                [0-47-9]\\d|
                5[1-9]|
                60
              )|
              30\\d
            )
          )\\d{4}
        ',
                'personal_number' => '',
                'fixed_line' => '[2-7][2-7]\\d{6}',
                'toll_free' => '1800\\d{6,7}',
                'specialrate' => '',
                'geographic' => '[2-7][2-7]\\d{6}'
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+593|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      {
        no warnings 'uninitialized';
        $number =~ s/^(?:0)//;
      }
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;