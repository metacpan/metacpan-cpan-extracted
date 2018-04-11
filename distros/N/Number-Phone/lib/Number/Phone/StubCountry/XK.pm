# automatically generated file, don't edit



# Copyright 2011 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::XK;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180410221548;

my $formatters = [
                {
                  'national_rule' => '0$1',
                  'leading_digits' => '
            [23][89]|
            4[3-79]
          ',
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'pattern' => '(\\d{3})(\\d{5})',
                  'national_rule' => '0$1',
                  'leading_digits' => '[89]00',
                  'format' => '$1 $2'
                },
                {
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3'
                }
              ];

my $validators = {
                'pager' => '',
                'personal_number' => '',
                'geographic' => '
          (?:
            2[89]0?|
            3(?:
              8|
              90?
            )
          )\\d{6}
        ',
                'mobile' => '4[3-79]\\d{6}',
                'specialrate' => '(900\\d{5})',
                'voip' => '',
                'fixed_line' => '
          (?:
            2[89]0?|
            3(?:
              8|
              90?
            )
          )\\d{6}
        ',
                'toll_free' => '800\\d{5}'
              };
my %areanames = (
  38328 => "Mitrovica",
  383280 => "Gjilan",
  38329 => "Prizren",
  383290 => "Ferizaj",
  38338 => "Prishtina",
  38339 => "Peja",
  383390 => "Gjakova",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+383|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;