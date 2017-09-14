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
package Number::Phone::StubCountry::RW;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170908113149;

my $formatters = [
                {
                  'leading_digits' => '2',
                  'pattern' => '(2\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'pattern' => '([7-9]\\d{2})(\\d{3})(\\d{3})',
                  'leading_digits' => '[7-9]'
                },
                {
                  'leading_digits' => '0',
                  'pattern' => '(0\\d)(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'personal_number' => '',
                'geographic' => '
          2[258]\\d{7}|
          06\\d{6}
        ',
                'pager' => '',
                'mobile' => '7[238]\\d{7}',
                'toll_free' => '800\\d{6}',
                'specialrate' => '(900\\d{6})',
                'fixed_line' => '
          2[258]\\d{7}|
          06\\d{6}
        ',
                'voip' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+250|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;