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
package Number::Phone::StubCountry::HR;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250605193635;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '6[01]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '8',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2,3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '1',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{4})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            6|
            7[245]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '9',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[2-57]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '8',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          1\\d{7}|
          (?:
            2[0-3]|
            3[1-5]|
            4[02-47-9]|
            5[1-3]
          )\\d{6,7}
        ',
                'geographic' => '
          1\\d{7}|
          (?:
            2[0-3]|
            3[1-5]|
            4[02-47-9]|
            5[1-3]
          )\\d{6,7}
        ',
                'mobile' => '
          9(?:
            (?:
              0[1-9]|
              [12589]\\d
            )\\d\\d|
            7(?:
              [0679]\\d\\d|
              5(?:
                [01]\\d|
                44|
                55|
                77|
                9[5-79]
              )
            )
          )\\d{4}|
          98\\d{6}
        ',
                'pager' => '',
                'personal_number' => '7[45]\\d{6}',
                'specialrate' => '(
          6[01459]\\d{6}|
          6[01]\\d{5}
        )|(
          62\\d{6,7}|
          72\\d{6}
        )',
                'toll_free' => '80\\d{5,7}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"38523", "Zadar",
"38549", "Krapina\-Zagorje",
"38547", "Karlovac",
"38535", "Brod\-Posavina",
"38553", "Lika\-Senj",
"38543", "Bjelovar\-Bilogora",
"3851", "Zagreb",
"38533", "Virovitica\-Podravina",
"38542", "Varaždin",
"38552", "Istra",
"38551", "Primorsko\-goranska",
"38520", "Dubrovnik\-Neretva",
"38534", "Požega\-Slavonia",
"38548", "Koprivnica\-Križevci",
"38540", "Međimurje",
"38521", "Split\-Dalmatia",
"38522", "Šibenik\-Knin",
"38544", "Sisak\-Moslavina",
"38532", "Vukovar\-Srijem",
"38531", "Osijek\-Baranja",};
my $timezones = {
               '' => [
                       'Europe/Zagreb'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+385|\D)//g;
      my $self = bless({ country_code => '385', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '385', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;