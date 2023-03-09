# automatically generated file, don't edit



# Copyright 2023 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::PF;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20230307181421;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '44',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            4|
            8[7-9]
          ',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '8',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          4(?:
            0[4-689]|
            9[4-68]
          )\\d{5}
        ',
                'geographic' => '
          4(?:
            0[4-689]|
            9[4-68]
          )\\d{5}
        ',
                'mobile' => '8[7-9]\\d{6}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(44\\d{4})',
                'toll_free' => '80[0-5]\\d{6}',
                'voip' => '499\\d{5}'
              };
my %areanames = ();
$areanames{en} = {"689406", "Îles\ Sous\-le\-vent\(ISLV\)",
"689498", "Polynesia",
"689409", "Remote\ Archipelago",
"689404", "Îles\ du\ Vent\(IDV\)",
"689405", "Îles\ du\ Vent\(IDV\)",
"689496", "Polynesia",
"6894088", "Polynesia",
"689408", "Îles\ du\ Vent\(IDV\)",
"689494", "Polynesia",
"689495", "Polynesia",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+689|\D)//g;
      my $self = bless({ country_code => '689', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;