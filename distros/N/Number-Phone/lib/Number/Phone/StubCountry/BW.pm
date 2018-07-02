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
our $VERSION = 1.20180619214154;

my $formatters = [
                {
                  'pattern' => '(\\d{3})(\\d{4})',
                  'leading_digits' => '[2-6]',
                  'format' => '$1 $2'
                },
                {
                  'pattern' => '(7\\d)(\\d{3})(\\d{3})',
                  'leading_digits' => '7',
                  'format' => '$1 $2 $3'
                },
                {
                  'pattern' => '(90)(\\d{5})',
                  'leading_digits' => '90',
                  'format' => '$1 $2'
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
                'pager' => '',
                'toll_free' => '',
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
                'voip' => '79[12][01]\\d{4}',
                'personal_number' => '',
                'mobile' => '
          7(?:
            [1-6]\\d|
            7[014-8]
          )\\d{5}
        ',
                'specialrate' => '(90\\d{5})'
              };
my %areanames = (
  267240 => "Francistown",
  267241 => "Francistown",
  267242 => "Francistown",
  267243 => "Francistown",
  267244 => "Francistown",
  267248 => "Francistown",
  267260 => "Selebi\-Phikwe",
  267261 => "Selebi\-Phikwe",
  267262 => "Selebi\-Phikwe",
  267264 => "Selebi\-Phikwe",
  267290 => "Letlhakane\/Orapa",
  267295 => "Letlhakane\/Orapa",
  267297 => "Letlhakane\/Orapa",
  267298 => "Letlhakane\/Orapa",
  267310 => "Gaborone\ \(outer\)",
  267312 => "Gaborone",
  267313 => "Gaborone",
  267315 => "Gaborone",
  267316 => "Gaborone",
  267317 => "Gaborone",
  267318 => "Gaborone",
  267319 => "Gaborone",
  267355 => "Gaborone",
  26736 => "Gaborone",
  267370 => "Gaborone",
  267371 => "Gaborone",
  267390 => "Gaborone",
  267391 => "Gaborone",
  267392 => "Gaborone",
  267393 => "Gaborone",
  267394 => "Gaborone",
  267395 => "Gaborone",
  267397 => "Gaborone",
  267460 => "Serowe",
  267463 => "Serowe",
  267471 => "Mahalapye",
  267472 => "Mahalapye",
  267476 => "Mahalapye",
  267477 => "Mahalapye",
  267490 => "Palapye",
  267491 => "Palapye",
  267492 => "Palapye",
  267493 => "Palapye",
  267494 => "Palapye",
  267495 => "Palapye",
  267530 => "Lobatse",
  267533 => "Lobatse",
  267538 => "Ramotswa",
  267539 => "Ramotswa",
  267540 => "Barolong\/Ngwaketse",
  267544 => "Barolong\/Ngwaketse",
  267548 => "Barolong\/Ngwaketse",
  267549 => "Barolong\/Ngwaketse",
  267571 => "Mochudi",
  267572 => "Mochudi",
  267573 => "Mochudi",
  267574 => "Mochudi",
  267577 => "Mochudi",
  267588 => "Jwaneng",
  267590 => "Molepolole",
  267591 => "Molepolole",
  267592 => "Molepolole",
  267593 => "Molepolole",
  267594 => "Molepolole",
  267599 => "Molepolole",
  267621 => "Kasane",
  267622 => "Kasane",
  267623 => "Kasane",
  267625 => "Kasane",
  267651 => "Kgalagadi",
  267654 => "Kgalagadi",
  267659 => "Gantsi",
  267680 => "Maun",
  267686 => "Maun",
  267687 => "Maun",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+267|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;