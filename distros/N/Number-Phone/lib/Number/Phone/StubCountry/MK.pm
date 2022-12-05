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
package Number::Phone::StubCountry::MK;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20221202211027;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            2|
            34[47]|
            4(?:
              [37]7|
              5[47]|
              64
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[347]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[58]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d)(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            (?:
              2(?:
                62|
                77
              )0|
              3444
            )\\d|
            4[56]440
          )\\d{3}|
          (?:
            34|
            4[357]
          )700\\d{3}|
          (?:
            2(?:
              [0-3]\\d|
              5[0-578]|
              6[01]|
              82
            )|
            3(?:
              1[3-68]|
              [23][2-68]|
              4[23568]
            )|
            4(?:
              [23][2-68]|
              4[3-68]|
              5[2568]|
              6[25-8]|
              7[24-68]|
              8[4-68]
            )
          )\\d{5}
        ',
                'geographic' => '
          (?:
            (?:
              2(?:
                62|
                77
              )0|
              3444
            )\\d|
            4[56]440
          )\\d{3}|
          (?:
            34|
            4[357]
          )700\\d{3}|
          (?:
            2(?:
              [0-3]\\d|
              5[0-578]|
              6[01]|
              82
            )|
            3(?:
              1[3-68]|
              [23][2-68]|
              4[23568]
            )|
            4(?:
              [23][2-68]|
              4[3-68]|
              5[2568]|
              6[25-8]|
              7[24-68]|
              8[4-68]
            )
          )\\d{5}
        ',
                'mobile' => '
          7(?:
            3555|
            4747|
            9(?:
              [019]77|
              42[0-4]
            )
          )\\d{3}|
          7(?:
            [0-25-8]\\d\\d|
            3(?:
              [1-48]\\d|
              7[01578]
            )|
            4(?:
              2\\d|
              60|
              7[01578]
            )|
            9(?:
              [23]\\d|
              4[01]|
              7[015]
            )
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(
          8(?:
            0[1-9]|
            [1-9]\\d
          )\\d{5}
        )|(5\\d{7})',
                'toll_free' => '800\\d{5}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"3894865", "Prilep\/Krusevo",
"38946", "Ohrid\/Struga\/Debar",
"3894762", "Bitola\/Demir\ Hisar\/Resen",
"38933", "Kocani\/Berovo\/Delcevo\/Vinica",
"3894769", "Bitola\/Demir\ Hisar\/Resen",
"3894867", "Prilep\/Krusevo",
"38932", "Stip\/Probistip\/Sveti\ Nikole\/Radovis",
"3894763", "Bitola\/Demir\ Hisar\/Resen",
"3894868", "Prilep\/Krusevo",
"3894864", "Prilep\/Krusevo",
"38947609", "Bitola\/Demir\ Hisar\/Resen",
"3892", "Skopje",
"3894862", "Prilep\/Krusevo",
"3894765", "Bitola\/Demir\ Hisar\/Resen",
"38944", "Tetovo",
"3894768", "Bitola\/Demir\ Hisar\/Resen",
"3894764", "Bitola\/Demir\ Hisar\/Resen",
"3894863", "Prilep\/Krusevo",
"389472", "Bitola\/Demir\ Hisar\/Resen",
"3894767", "Bitola\/Demir\ Hisar\/Resen",
"3894869", "Prilep\/Krusevo",
"38942", "Gostivar",
"3894861", "Prilep\/Krusevo",
"389484", "Prilep\/Krusevo",
"38943", "Veles\/Kavadarci\/Negotino",
"389478", "Bitola\/Demir\ Hisar\/Resen",
"3894866", "Prilep\/Krusevo",
"389485", "Prilep\/Krusevo",
"38947600", "Bitola\/Demir\ Hisar\/Resen",
"38931", "Kumanovo\/Kriva\ Palanka\/Kratovo",
"389474", "Bitola\/Demir\ Hisar\/Resen",
"3894761", "Bitola\/Demir\ Hisar\/Resen",
"38945", "Kicevo\/Makedonski\ Brod",
"389477", "Bitola\/Demir\ Hisar\/Resen",
"38947608", "Bitola\/Demir\ Hisar\/Resen",
"38934", "Gevgelija\/Valandovo\/Strumica\/Dojran",
"389475", "Bitola\/Demir\ Hisar\/Resen",
"3894766", "Bitola\/Demir\ Hisar\/Resen",
"389488", "Prilep\/Krusevo",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+389|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;