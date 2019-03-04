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
package Number::Phone::StubCountry::AE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190303205537;

my $formatters = [
                {
                  'leading_digits' => '
            60|
            8
          ',
                  'format' => '$1 $2',
                  'pattern' => '(\\d{3})(\\d{2,9})'
                },
                {
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [236]|
            [479][2-8]
          '
                },
                {
                  'pattern' => '(\\d{3})(\\d)(\\d{5})',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[479]'
                },
                {
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})',
                  'leading_digits' => '5',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1'
                }
              ];

my $validators = {
                'voip' => '',
                'specialrate' => '(700[05]\\d{5})|(900[02]\\d{5})|(600[25]\\d{5})',
                'mobile' => '5[024-68]\\d{7}',
                'geographic' => '[2-4679][2-8]\\d{6}',
                'pager' => '',
                'personal_number' => '',
                'toll_free' => '
          400\\d{6}|
          800\\d{2,9}
        ',
                'fixed_line' => '[2-4679][2-8]\\d{6}'
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+971|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;