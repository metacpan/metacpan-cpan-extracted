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
package Number::Phone::StubCountry::FJ;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250605193635;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            [235-9]|
            45
          ',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          603\\d{4}|
          (?:
            3[0-5]|
            6[25-7]|
            8[58]
          )\\d{5}
        ',
                'geographic' => '
          603\\d{4}|
          (?:
            3[0-5]|
            6[25-7]|
            8[58]
          )\\d{5}
        ',
                'mobile' => '
          (?:
            [279]\\d|
            45|
            5[01568]|
            8[034679]
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '0800\\d{7}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"67966", "Lautoka\/Ba\/Vatukoula\/Tavua\/Rakiraki",
"67988", "Vanua\ Levu",
"67965", "Coral\ Coast\/Sigatoka",
"6793", "Suva\ City\/Nausori\/Korovou",
"67985", "Vanua\ Levu",
"67967", "Nadi",};
my $timezones = {
               '' => [
                       'Pacific/Fiji'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+679|\D)//g;
      my $self = bless({ country_code => '679', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;