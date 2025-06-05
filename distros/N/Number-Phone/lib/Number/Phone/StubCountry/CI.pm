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
package Number::Phone::StubCountry::CI;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250605193633;

my $formatters = [
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
          2(?:
            [15]\\d{3}|
            7(?:
              2(?:
                0[23]|
                1[2357]|
                2[245]|
                3[45]|
                4[3-5]
              )|
              3(?:
                06|
                1[69]|
                [2-6]7
              )
            )
          )\\d{5}
        ',
                'geographic' => '
          2(?:
            [15]\\d{3}|
            7(?:
              2(?:
                0[23]|
                1[2357]|
                2[245]|
                3[45]|
                4[3-5]
              )|
              3(?:
                06|
                1[69]|
                [2-6]7
              )
            )
          )\\d{5}
        ',
                'mobile' => '0[157]\\d{8}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"2252536", "Korhogo",
"2252723", "Banco\,\ Abidjan",
"2252532", "Daloa",
"2252534", "San\-Pédro",
"22527225", "Cocody\,\ Abidjan",
"2252736", "Korhogo",
"2252121", "Abidjan\-sud",
"2252734", "San\-Pédro",
"2252523", "Banco\,\ Abidjan",
"2252732", "Daloa",
"2252130", "Yamoussoukro",
"2252720", "Plateau\,\ Abidjan",
"2252122", "Cocody\,\ Abidjan",
"2252124", "Abobo\,\ Abidjan",
"2252731", "Bouaké",
"2252735", "Abengourou",
"2252531", "Bouaké",
"2252133", "Man",
"2252520", "Plateau\,\ Abidjan",
"2252535", "Abengourou",
"2252135", "Abengourou",
"2252533", "Man",
"22527224", "Cocody\,\ Abidjan",
"2252120", "Plateau\,\ Abidjan",
"2252131", "Bouaké",
"2252724", "Abobo\,\ Abidjan",
"22527222", "Abidjan\-sud",
"2252524", "Abobo\,\ Abidjan",
"2252733", "Man",
"2252522", "Cocody\,\ Abidjan",
"2252530", "Yamoussoukro",
"2252123", "Banco\,\ Abidjan",
"2252521", "Abidjan\-sud",
"2252721", "Abidjan\-sud",
"2252134", "San\-Pédro",
"2252132", "Daloa",
"2252730", "Yamoussoukro",
"2252136", "Korhogo",};
$areanames{fr} = {};
my $timezones = {
               '' => [
                       'Africa/Abidjan'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+225|\D)//g;
      my $self = bless({ country_code => '225', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;