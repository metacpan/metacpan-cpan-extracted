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
package Number::Phone::StubCountry::BW;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20211206222442;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '90',
                  'pattern' => '(\\d{2})(\\d{5})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            [24-6]|
            3[15-79]
          ',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[37]',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '8',
                  'pattern' => '(\\d{3})(\\d{4})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              4[0-48]|
              6[0-24]|
              9[0578]
            )|
            3(?:
              1[0-35-9]|
              55|
              [69]\\d|
              7[013]
            )|
            4(?:
              6[03]|
              7[1267]|
              9[0-5]
            )|
            5(?:
              3[03489]|
              4[0489]|
              7[1-47]|
              88|
              9[0-49]
            )|
            6(?:
              2[1-35]|
              5[149]|
              8[067]
            )
          )\\d{4}
        ',
                'geographic' => '
          (?:
            2(?:
              4[0-48]|
              6[0-24]|
              9[0578]
            )|
            3(?:
              1[0-35-9]|
              55|
              [69]\\d|
              7[013]
            )|
            4(?:
              6[03]|
              7[1267]|
              9[0-5]
            )|
            5(?:
              3[03489]|
              4[0489]|
              7[1-47]|
              88|
              9[0-49]
            )|
            6(?:
              2[1-35]|
              5[149]|
              8[067]
            )
          )\\d{4}
        ',
                'mobile' => '
          (?:
            321|
            7(?:
              [1-7]\\d|
              8[01]
            )
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(90\\d{5})',
                'toll_free' => '
          (?:
            0800|
            800\\d
          )\\d{6}
        ',
                'voip' => '
          79(?:
            1(?:
              [01]\\d|
              20
            )|
            2[0-25-7]\\d
          )\\d{3}
        '
              };
my %areanames = ();
$areanames{en} = {"267318", "Gaborone",
"267533", "Lobatse",
"267397", "Gaborone",
"26746", "Serowe",
"267315", "Gaborone",
"267659", "Gantsi",
"267390", "Gaborone",
"26729", "Letlhakane\/Orapa",
"267394", "Gaborone",
"26757", "Mochudi",
"267392", "Gaborone",
"267313", "Gaborone",
"267538", "Ramotswa",
"267370", "Gaborone",
"26762", "Kasane",
"26768", "Maun",
"267654", "Kgalagadi",
"26759", "Molepolole",
"267393", "Gaborone",
"26749", "Palapye",
"26724", "Francistown",
"267312", "Gaborone",
"26758", "Jwaneng",
"267530", "Lobatse",
"267319", "Gaborone",
"267316", "Gaborone",
"267391", "Gaborone",
"267534", "Lobatse",
"26726", "Selebi\-Phikwe",
"267317", "Gaborone",
"26754", "Barolong\/Ngwaketse",
"26747", "Mahalapye",
"267395", "Gaborone",
"26736", "Gaborone",
"26735", "Gaborone",
"267539", "Ramotswa",
"267651", "Kgalagadi",
"267310", "Gaborone\ \(outer\)",
"267371", "Gaborone",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+267|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;