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
package Number::Phone::StubCountry::MW;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170908113148;

my $formatters = [
                {
                  'pattern' => '(\\d)(\\d{3})(\\d{3})',
                  'leading_digits' => '1'
                },
                {
                  'pattern' => '(2\\d{2})(\\d{3})(\\d{3})',
                  'leading_digits' => '2'
                },
                {
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})',
                  'leading_digits' => '[17-9]'
                }
              ];

my $validators = {
                'voip' => '',
                'fixed_line' => '
          (?:
            1[2-9]|
            21\\d{2}
          )\\d{5}
        ',
                'specialrate' => '',
                'mobile' => '
          (?:
            111|
            77\\d|
            88\\d|
            99\\d
          )\\d{6}
        ',
                'toll_free' => '',
                'pager' => '',
                'personal_number' => '',
                'geographic' => '
          (?:
            1[2-9]|
            21\\d{2}
          )\\d{5}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+265|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;