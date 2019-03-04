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
package Number::Phone::StubCountry::GF;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190303205539;

my $formatters = [
                {
                  'leading_digits' => '[56]',
                  'format' => '$1 $2 $3 $4',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})',
                  'national_rule' => '0$1'
                }
              ];

my $validators = {
                'voip' => '',
                'specialrate' => '',
                'mobile' => '
          694(?:
            [0-249]\\d|
            3[0-48]
          )\\d{4}
        ',
                'geographic' => '
          594(?:
            [023]\\d|
            1[01]|
            4[03-9]|
            5[6-9]|
            6[0-3]|
            80|
            9[014]
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'toll_free' => '',
                'fixed_line' => '
          594(?:
            [023]\\d|
            1[01]|
            4[03-9]|
            5[6-9]|
            6[0-3]|
            80|
            9[014]
          )\\d{4}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+594|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;