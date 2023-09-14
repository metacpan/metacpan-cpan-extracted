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
package Number::Phone::StubCountry::PS;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20230903131448;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[2489]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '5',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '1',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            22[2-47-9]|
            42[45]|
            82[014-68]|
            92[3569]
          )\\d{5}
        ',
                'geographic' => '
          (?:
            22[2-47-9]|
            42[45]|
            82[014-68]|
            92[3569]
          )\\d{5}
        ',
                'mobile' => '5[69]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(1700\\d{6})',
                'toll_free' => '1800\\d{6}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"970424", "Jenin",
"970826", "Gaza",
"970222", "Jericho\/Hebron",
"970926", "Tulkarm",
"970923", "Nablus",
"970828", "Gaza",
"970929", "Qalqilya\/Salfit",
"970820", "Khan\ Yunis",
"970821", "Rafah",
"970824", "North\ Gaza",
"970227", "Bethlehem",
"970223", "Jerusalem",
"970825", "Deir\ al\-Balah",
"970925", "Tubas",
"970229", "Ramallah\/Al\-Bireh",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+970|\D)//g;
      my $self = bless({ country_code => '970', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '970', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;