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
package Number::Phone::StubCountry::LR;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170908113148;

my $formatters = [
                {
                  'pattern' => '(2\\d)(\\d{3})(\\d{3})',
                  'leading_digits' => '2'
                },
                {
                  'pattern' => '([4-5])(\\d{3})(\\d{3})',
                  'leading_digits' => '[45]'
                },
                {
                  'leading_digits' => '[23578]',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'voip' => '',
                'toll_free' => '',
                'mobile' => '
          (?:
            20\\d{2}|
            330\\d|
            4[67]|
            5(?:
              55
            )?\\d|
            77\\d{2}|
            88\\d{2}
          )\\d{5}
        ',
                'specialrate' => '(
          332(?:
            02|
            [2-5]\\d
          )\\d{4}
        )',
                'fixed_line' => '
          (?:
            2\\d{3}|
            33333
          )\\d{4}
        ',
                'pager' => '',
                'geographic' => '
          (?:
            2\\d{3}|
            33333
          )\\d{4}
        ',
                'personal_number' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+231|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;