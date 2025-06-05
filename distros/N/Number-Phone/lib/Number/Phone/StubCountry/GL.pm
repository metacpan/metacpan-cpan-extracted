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
package Number::Phone::StubCountry::GL;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250605193635;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            19|
            [2-9]
          ',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            19|
            3[1-7]|
            [68][1-9]|
            70|
            9\\d
          )\\d{4}
        ',
                'geographic' => '
          (?:
            19|
            3[1-7]|
            [68][1-9]|
            70|
            9\\d
          )\\d{4}
        ',
                'mobile' => '[245]\\d{5}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '80\\d{4}',
                'voip' => '3[89]\\d{4}'
              };
my %areanames = ();
$areanames{en} = {"29999", "Ittoqqortoormiit",
"299691", "Ivittuut",
"29986", "Sisimiut",
"29989", "Aasiaat",
"29966", "Narsaq",
"29996", "Upernavik",
"29961", "Nanortalik",
"29998", "Tasiilaq",
"29935", "Nuuk",
"29984", "Kangerlussuaq",
"29968", "Paamiut",
"29991", "Qasigannguit",
"29992", "Qeqertasuaq",
"29964", "Qaqortoq",
"29981", "Maniitsoq",
"29937", "Nuuk",
"29994", "Ilulissat",
"29933", "Nuuk",
"29985", "Sisimiut",
"29934", "Nuuk",
"29997", "Qaanaaq",
"29987", "Kangaatsiaq",
"29932", "Nuuk",
"29931", "Nuuk",
"29995", "Uummannaq",
"29936", "Nuuk",};
my $timezones = {
               '' => [
                       'America/Godthab',
                       'America/Scoresbysund',
                       'America/Thule'
                     ],
               '1' => [
                        'America/Godthab'
                      ],
               '2' => [
                        'America/Godthab'
                      ],
               '3' => [
                        'America/Godthab'
                      ],
               '4' => [
                        'America/Godthab'
                      ],
               '5' => [
                        'America/Godthab'
                      ],
               '6' => [
                        'America/Godthab'
                      ],
               '8' => [
                        'America/Godthab'
                      ],
               '9' => [
                        'America/Godthab'
                      ],
               '97' => [
                         'America/Thule'
                       ],
               '99' => [
                         'America/Scoresbysund'
                       ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+299|\D)//g;
      my $self = bless({ country_code => '299', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;