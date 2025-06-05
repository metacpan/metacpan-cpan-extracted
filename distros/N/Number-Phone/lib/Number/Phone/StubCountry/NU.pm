# automatically generated file, don't edit



# Copyright 2025 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::NU;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250605193636;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '8',
                  'pattern' => '(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '[47]\\d{3}',
                'geographic' => '[47]\\d{3}',
                'mobile' => '
          (?:
            [56]|
            888[1-9]
          )\\d{3}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my $timezones = {
               '' => [
                       'Pacific/Niue'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+683|\D)//g;
      my $self = bless({ country_code => '683', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;