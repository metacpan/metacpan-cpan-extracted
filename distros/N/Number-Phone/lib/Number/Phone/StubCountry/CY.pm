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
package Number::Phone::StubCountry::CY;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170314173054;

my $formatters = [
                {
                  'pattern' => '(\\d{2})(\\d{6})'
                }
              ];

my $validators = {
                'pager' => '',
                'voip' => '',
                'fixed_line' => '2[2-6]\\d{6}',
                'mobile' => '9[4-79]\\d{6}',
                'specialrate' => '(80[1-9]\\d{5})|(90[09]\\d{5})|(
          (?:
            50|
            77
          )\\d{6}
        )',
                'geographic' => '2[2-6]\\d{6}',
                'personal_number' => '700\\d{5}',
                'toll_free' => '800\\d{5}'
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+357|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  return $self->is_valid() ? $self : undef;
}
1;