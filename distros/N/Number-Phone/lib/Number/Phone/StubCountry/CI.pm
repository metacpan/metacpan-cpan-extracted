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
package Number::Phone::StubCountry::CI;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190611222639;

my $formatters = [
                {
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})',
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[02-8]'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              0[023]|
              1[02357]|
              [23][045]|
              4[03-5]
            )|
            3(?:
              0[06]|
              1[069]|
              [2-4][07]|
              5[09]|
              6[08]
            )
          )\\d{5}
        ',
                'voip' => '',
                'specialrate' => '',
                'geographic' => '
          (?:
            2(?:
              0[023]|
              1[02357]|
              [23][045]|
              4[03-5]
            )|
            3(?:
              0[06]|
              1[069]|
              [2-4][07]|
              5[09]|
              6[08]
            )
          )\\d{5}
        ',
                'personal_number' => '',
                'mobile' => '
          (?:
            0[1-9]|
            [457]\\d|
            6[014-9]|
            8[4-9]
          )\\d{6}
        ',
                'toll_free' => '',
                'pager' => ''
              };
my %areanames = (
  22520 => "Plateau\,\ Abidjan",
  22521 => "Abidjan\ \(southeast\)",
  22522 => "Cocody\,\ Abidjan",
  22523 => "Banco\,\ Abidjan",
  22524 => "Abobo\,\ Abidjan",
  22530 => "Yamoussoukro",
  22531 => "Bouaké",
  22532 => "Daloa",
  22533 => "Man",
  22534 => "San\-Pédro",
  22535 => "Abengourou",
  22536 => "Korhogo",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+225|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;