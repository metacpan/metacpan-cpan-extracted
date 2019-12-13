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
our $VERSION = 1.20191211212302;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '2',
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
            2(?:
              [23]\\d|
              5[0-24578]|
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
            2(?:
              [23]\\d|
              5[0-24578]|
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
            (?:
              [0-25-8]\\d|
              3[2-4]|
              9[23]
            )\\d|
            4(?:
              21|
              60
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
        )|(5[02-9]\\d{6})',
                'toll_free' => '800\\d{5}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{3892} = "Skopje";
$areanames{en}->{38931} = "Kumanovo\/Kriva\ Palanka\/Kratovo";
$areanames{en}->{38932} = "Stip\/Probistip\/Sveti\ Nikole\/Radovis";
$areanames{en}->{38933} = "Kocani\/Berovo\/Delcevo\/Vinica";
$areanames{en}->{38934} = "Gevgelija\/Valandovo\/Strumica\/Dojran";
$areanames{en}->{38942} = "Gostivar";
$areanames{en}->{38943} = "Veles\/Kavadarci\/Negotino";
$areanames{en}->{38944} = "Tetovo";
$areanames{en}->{38945} = "Kicevo\/Makedonski\ Brod";
$areanames{en}->{38946} = "Ohrid\/Struga\/Debar";
$areanames{en}->{38947} = "Bitola\/Demir\ Hisar\/Resen";
$areanames{en}->{38948} = "Prilep\/Krusevo";

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