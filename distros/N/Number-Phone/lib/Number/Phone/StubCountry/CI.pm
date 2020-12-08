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
our $VERSION = 1.20201204215954;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[02-9]',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
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
                'mobile' => '
          2[0-3]80\\d{4}|
          (?:
            0[1-9]|
            [457]\\d|
            6[014-9]|
            8[4-9]|
            9[4-8]
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{fr} = {};
$areanames{en} = {"225220", "Cocody\,\ Abidjan",
"22535", "Abengourou",
"225235", "Banco\,\ Abidjan",
"22533", "Man",
"225234", "Banco\,\ Abidjan",
"225212", "Abidjan\ \(southeast\)",
"22530", "Yamoussoukro",
"225217", "Abidjan\ \(southeast\)",
"225202", "Plateau\,\ Abidjan",
"22531", "Bouaké",
"225215", "Abidjan\ \(southeast\)",
"22524", "Abobo\,\ Abidjan",
"22534", "San\-Pédro",
"225225", "Cocody\,\ Abidjan",
"22532", "Daloa",
"225224", "Cocody\,\ Abidjan",
"225203", "Plateau\,\ Abidjan",
"22536", "Korhogo",
"225230", "Banco\,\ Abidjan",
"225200", "Plateau\,\ Abidjan",
"225210", "Abidjan\ \(southeast\)",
"225213", "Abidjan\ \(southeast\)",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+225|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;