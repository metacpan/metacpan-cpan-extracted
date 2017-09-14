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
package Number::Phone::StubCountry::SC;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170908113149;

my $formatters = [
                {
                  'leading_digits' => '[246]',
                  'pattern' => '(\\d)(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'pager' => '',
                'geographic' => '4[2-46]\\d{5}',
                'personal_number' => '',
                'voip' => '
          (?:
            64\\d|
            971
          )\\d{4}
        ',
                'mobile' => '2[5-8]\\d{5}',
                'toll_free' => '8000\\d{3}',
                'specialrate' => '',
                'fixed_line' => '4[2-46]\\d{5}'
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+248|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  return $self->is_valid() ? $self : undef;
}
1;