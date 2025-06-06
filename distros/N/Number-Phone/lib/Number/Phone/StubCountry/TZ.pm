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
package Number::Phone::StubCountry::TZ;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250605193637;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[89]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[24]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '5',
                  'pattern' => '(\\d{2})(\\d{7})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[67]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '2[2-8]\\d{7}',
                'geographic' => '2[2-8]\\d{7}',
                'mobile' => '
          (?:
            6[125-9]|
            7[13-9]
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(
          8(?:
            40|
            6[01]
          )\\d{6}
        )|(90\\d{7})',
                'toll_free' => '80[08]\\d{6}',
                'voip' => '41\\d{7}'
              };
my %areanames = ();
$areanames{en} = {"25523", "Coast\/Morogoro\/Lindi\/Mtwara",
"25528", "Mwanza\/Shinyanga\/Mara\/Geita\/Simiyu\/Kagera\/Kigoma",
"25527", "Arusha\/Manyara\/Kilimanjaro\/Tanga",
"25522", "Dar\-Es\-Salaam",
"25525", "Mbeya\/Songwe\/Ruvuma\/Katavi\/Rukwa",
"25526", "Dodoma\/Iringa\/Njombe\/Singida\/Tabora",
"25524", "Zanzibar",};
my $timezones = {
               '' => [
                       'Africa/Dar_es_Salaam'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+255|\D)//g;
      my $self = bless({ country_code => '255', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '255', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;