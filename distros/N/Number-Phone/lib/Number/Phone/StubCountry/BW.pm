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
our $VERSION = 1.20170314173053;

my $formatters = [
                {
                  'pattern' => '(\\d{3})(\\d{4})',
                  'leading_digits' => '[2-6]'
                },
                {
                  'leading_digits' => '7',
                  'pattern' => '(7\\d)(\\d{3})(\\d{3})'
                },
                {
                  'leading_digits' => '9',
                  'pattern' => '(90)(\\d{5})'
                }
              ];

my $validators = {
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
              7[01]
            )|
            4(?:
              6[03]|
              7[1267]|
              9[0-5]
            )|
            5(?:
              3[0389]|
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
                'personal_number' => '',
                'toll_free' => '',
                'mobile' => '
          7(?:
            [1-6]\\d|
            7[014-8]
          )\\d{5}
        ',
                'specialrate' => '(90\\d{5})',
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
              7[01]
            )|
            4(?:
              6[03]|
              7[1267]|
              9[0-5]
            )|
            5(?:
              3[0389]|
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
                'pager' => '',
                'voip' => '79[12][01]\\d{4}'
              };
my %areanames = (
  26724 => "Francistown",
  26726 => "Selebi\-Phikwe",
  26729 => "Letlhakane\/Orapa",
  26731 => "Gaborone\ \(outer\)",
  26739 => "Gaborone",
  267463 => "Serowe",
  26747 => "Mahalapye",
  26749 => "Palapye",
  26753 => "Lobatse",
  267539 => "Ramotswa",
  26754 => "Barolong\/Ngwaketse",
  26757 => "Mochudi",
  267588 => "Jwaneng",
  26759 => "Molepolole\/Kweneng",
  267625 => "Kasane",
  26765 => "Kgalagadi",
  267659 => "Gantsi",
  26768 => "Maun",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+267|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  return $self->is_valid() ? $self : undef;
}
1;