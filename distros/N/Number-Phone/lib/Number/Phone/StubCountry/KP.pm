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
package Number::Phone::StubCountry::KP;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180619214156;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1',
                  'leading_digits' => '1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '(\\d)(\\d{3})(\\d{4})',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '2'
                },
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '8',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2\\d{7}|
          85\\d{6}
        ',
                'toll_free' => '',
                'personal_number' => '',
                'voip' => '',
                'pager' => '',
                'geographic' => '
          2\\d{7}|
          85\\d{6}
        ',
                'specialrate' => '',
                'mobile' => '19[123]\\d{7}'
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+850|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;