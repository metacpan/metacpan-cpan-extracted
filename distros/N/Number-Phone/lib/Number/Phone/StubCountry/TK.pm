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
package Number::Phone::StubCountry::TK;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250605193636;

my $formatters = [];

my $validators = {
                'fixed_line' => '
          (?:
            2[2-4]|
            [34]\\d
          )\\d{2,5}
        ',
                'geographic' => '
          (?:
            2[2-4]|
            [34]\\d
          )\\d{2,5}
        ',
                'mobile' => '7[2-4]\\d{2,5}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"6902", "Atafu\ Atoll",
"6903", "Fakaofo\ Atoll",
"6904", "Nakunonu\ Atoll",};
my $timezones = {
               '' => [
                       'Pacific/Fakaofo'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+690|\D)//g;
      my $self = bless({ country_code => '690', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;