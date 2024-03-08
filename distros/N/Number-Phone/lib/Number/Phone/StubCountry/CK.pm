# automatically generated file, don't edit



# Copyright 2024 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::CK;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20240308154349;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[2-578]',
                  'pattern' => '(\\d{2})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2\\d|
            3[13-7]|
            4[1-5]
          )\\d{3}
        ',
                'geographic' => '
          (?:
            2\\d|
            3[13-7]|
            4[1-5]
          )\\d{3}
        ',
                'mobile' => '[578]\\d{4}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"68234", "Mangaia",
"68245", "Nassau",
"68243", "Manihiki",
"68231", "Aitutaki",
"68241", "Pukapuka",
"68242", "Penrhyn",
"68236", "Mitiaro",
"68235", "Mauke",
"68233", "Atiu",
"6822", "Rarotonga",
"68237", "Palmerston",
"68244", "Rakahanga",};
my $timezones = {
               '' => [
                       'Pacific/Rarotonga'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+682|\D)//g;
      my $self = bless({ country_code => '682', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;