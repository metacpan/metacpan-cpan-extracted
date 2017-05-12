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
our $VERSION = 1.20170314173054;

my $formatters = [
                {
                  'leading_digits' => '2',
                  'pattern' => '(2\\d)(\\d{3})(\\d{3})'
                },
                {
                  'leading_digits' => '[45]',
                  'pattern' => '([4-5])(\\d{3})(\\d{3})'
                },
                {
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})',
                  'leading_digits' => '[23578]'
                }
              ];

my $validators = {
                'fixed_line' => '2\\d{7}',
                'pager' => '',
                'voip' => '
          332(?:
            02|
            [25]\\d
          )\\d{4}
        ',
                'toll_free' => '',
                'geographic' => '2\\d{7}',
                'personal_number' => '',
                'specialrate' => '',
                'mobile' => '
          (?:
            20\\d{3}|
            330\\d{2}|
            4[67]\\d|
            5(?:55)?\\d{2}|
            77\\d{3}|
            88\\d{3}
          )\\d{4}
        '
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