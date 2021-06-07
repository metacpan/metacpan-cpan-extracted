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
our $VERSION = 1.20210602223257;

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
                [23][45]|
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
                [23][45]|
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
                'mobile' => '
          0(?:
            [15]\\d\\d|
            7(?:
              [04-8][7-9]|
              9[78]
            )
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"22525310", "Bouaké",
"2252721", "Abidjan\ \(southeast\)",
"22525200", "Plateau\,\ Abidjan",
"22525330", "Man",
"2252730", "Yamoussoukro",
"2252723", "Banco\,\ Abidjan",
"2252734", "San\-Pédro",
"2252732", "Daloa",
"22525220", "Cocody\,\ Abidjan",
"22525240", "Abobo\,\ Abidjan",
"22525360", "Korhogo",
"2252731", "Bouaké",
"22525210", "Abidjan\ \(southeast\)",
"2252733", "Man",
"2252720", "Plateau\,\ Abidjan",
"22525230", "Banco\,\ Abidjan",
"22525300", "Yamoussoukro",
"22525340", "San\-Pédro",
"22525320", "Daloa",
"2252724", "Abobo\,\ Abidjan",
"2252722", "Cocody\,\ Abidjan",
"22525350", "Abengourou",};
$areanames{fr} = {};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+225|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;