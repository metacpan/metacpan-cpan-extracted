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
package Number::Phone::StubCountry::MC;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20181205223704;

my $formatters = [
                {
                  'leading_digits' => '8',
                  'format' => '$1 $2 $3',
                  'intl_format' => 'NA',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{2})'
                },
                {
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})',
                  'leading_digits' => '[39]',
                  'format' => '$1 $2 $3 $4'
                },
                {
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '4',
                  'national_rule' => '0$1'
                },
                {
                  'pattern' => '(\\d)(\\d{2})(\\d{2})(\\d{2})(\\d{2})',
                  'national_rule' => '0$1',
                  'leading_digits' => '6',
                  'format' => '$1 $2 $3 $4 $5'
                }
              ];

my $validators = {
                'geographic' => '
          (?:
            870|
            9[2-47-9]\\d
          )\\d{5}
        ',
                'toll_free' => '90\\d{6}',
                'fixed_line' => '
          (?:
            870|
            9[2-47-9]\\d
          )\\d{5}
        ',
                'personal_number' => '',
                'specialrate' => '',
                'mobile' => '
          (?:
            (?:
              3|
              6\\d
            )\\d\\d|
            4(?:
              4\\d|
              5[1-9]
            )
          )\\d{5}
        ',
                'pager' => '',
                'voip' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+377|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;