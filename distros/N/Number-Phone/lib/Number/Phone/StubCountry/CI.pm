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
our $VERSION = 1.20210204173824;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            [03-9]|
            2[0-4]
          ',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '2',
                  'pattern' => '(\\d{2})(\\d{2})(\\d)(\\d{5})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              0[023]|
              12[0-3]8|
              [23][045]|
              4[03-5]|
              5(?:
                2[0-4]|
                3[0-6]
              )0|
              7(?:
                2(?:
                  0[23]|
                  1[2357]|
                  [23][45]|
                  4[3-5]
                )|
                3(?:
                  06|
                  1[69]|
                  [2-6]7
                )
              )
            )|
            3(?:
              0[06]|
              1[069]|
              [2-4][07]|
              5[09]|
              6[08]
            )
          )\\d{5}|
          21[02357]\\d{5}
        ',
                'geographic' => '
          (?:
            2(?:
              0[023]|
              12[0-3]8|
              [23][045]|
              4[03-5]|
              5(?:
                2[0-4]|
                3[0-6]
              )0|
              7(?:
                2(?:
                  0[23]|
                  1[2357]|
                  [23][45]|
                  4[3-5]
                )|
                3(?:
                  06|
                  1[69]|
                  [2-6]7
                )
              )
            )|
            3(?:
              0[06]|
              1[069]|
              [2-4][07]|
              5[09]|
              6[08]
            )
          )\\d{5}|
          21[02357]\\d{5}
        ',
                'mobile' => '
          (?:
            (?:
              0(?:
                1(?:
                  0[1-3]|
                  [457][0-3]
                )|
                5[04-9][4-6]|
                7(?:
                  [04-8][7-9]|
                  9[78]
                )
              )|
              [457]\\d|
              6[014-9]|
              8[4-9]|
              9[4-8]
            )\\d\\d|
            2[0-3]80
          )\\d{4}|
          0[1-9]\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"2252732", "Daloa",
"225213", "Abidjan\ \(southeast\)",
"2252533", "Man",
"2252530", "Yamoussoukro",
"22535", "Abengourou",
"2252731", "Bouaké",
"2252524", "Abobo\,\ Abidjan",
"2252532", "Daloa",
"2252535", "Abengourou",
"2252733", "Man",
"2252730", "Yamoussoukro",
"225203", "Plateau\,\ Abidjan",
"2252531", "Bouaké",
"22536", "Korhogo",
"2252724", "Abobo\,\ Abidjan",
"2252522", "Cocody\,\ Abidjan",
"22531", "Bouaké",
"225225", "Cocody\,\ Abidjan",
"2252720", "Plateau\,\ Abidjan",
"2252723", "Banco\,\ Abidjan",
"225202", "Plateau\,\ Abidjan",
"225200", "Plateau\,\ Abidjan",
"2252521", "Abidjan\ \(southeast\)",
"225224", "Cocody\,\ Abidjan",
"22533", "Man",
"225220", "Cocody\,\ Abidjan",
"2252734", "San\-Pédro",
"22530", "Yamoussoukro",
"22534", "San\-Pédro",
"2252536", "Korhogo",
"225234", "Banco\,\ Abidjan",
"2252722", "Cocody\,\ Abidjan",
"225215", "Abidjan\ \(southeast\)",
"22532", "Daloa",
"225230", "Banco\,\ Abidjan",
"225212", "Abidjan\ \(southeast\)",
"2252520", "Plateau\,\ Abidjan",
"2252523", "Banco\,\ Abidjan",
"225217", "Abidjan\ \(southeast\)",
"225235", "Banco\,\ Abidjan",
"225210", "Abidjan\ \(southeast\)",
"22524", "Abobo\,\ Abidjan",
"2252721", "Abidjan\ \(southeast\)",
"2252534", "San\-Pédro",};
$areanames{fr} = {};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+225|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;