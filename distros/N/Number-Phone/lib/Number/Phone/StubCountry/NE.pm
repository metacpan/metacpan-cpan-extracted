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
package Number::Phone::StubCountry::NE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20230614174404;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '08',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            [089]|
            2[013]|
            7[04]
          ',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2(?:
            0(?:
              20|
              3[1-8]|
              4[13-5]|
              5[14]|
              6[14578]|
              7[1-578]
            )|
            1(?:
              4[145]|
              5[14]|
              6[14-68]|
              7[169]|
              88
            )
          )\\d{4}
        ',
                'geographic' => '
          2(?:
            0(?:
              20|
              3[1-8]|
              4[13-5]|
              5[14]|
              6[14578]|
              7[1-578]
            )|
            1(?:
              4[145]|
              5[14]|
              6[14-68]|
              7[169]|
              88
            )
          )\\d{4}
        ',
                'mobile' => '
          (?:
            23|
            7[04]|
            [89]\\d
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(09\\d{6})',
                'toll_free' => '08\\d{6}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"2272045", "Arlit",
"2272071", "Tillabéry",
"2272072", "Niamey",
"2272068", "Gaya",
"2272064", "Konni",
"2272075", "Niamey",
"227202", "Niamey",
"2272073", "Niamey",
"2272041", "Maradi",
"2272051", "Zinder",
"227203", "Niamey",
"2272077", "Filingué",
"2272074", "Niamey",
"2272061", "Tahoua",
"2272078", "Say",
"2272065", "Dosso",
"2272044", "Agadez",
"2272054", "Diffa",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+227|\D)//g;
      my $self = bless({ country_code => '227', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;