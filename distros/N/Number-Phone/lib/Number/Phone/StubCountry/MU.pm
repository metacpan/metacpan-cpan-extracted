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
package Number::Phone::StubCountry::MU;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20210204173826;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            [2-46]|
            8[013]
          ',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '5',
                  'pattern' => '(\\d{4})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              [0346-8]\\d|
              1[0-7]
            )|
            4(?:
              [013568]\\d|
              2[4-7]
            )|
            54(?:
              [3-5]\\d|
              71
            )|
            6\\d\\d|
            8(?:
              14|
              3[129]
            )
          )\\d{4}
        ',
                'geographic' => '
          (?:
            2(?:
              [0346-8]\\d|
              1[0-7]
            )|
            4(?:
              [013568]\\d|
              2[4-7]
            )|
            54(?:
              [3-5]\\d|
              71
            )|
            6\\d\\d|
            8(?:
              14|
              3[129]
            )
          )\\d{4}
        ',
                'mobile' => '
          5(?:
            4(?:
              2[1-389]|
              7[1-9]
            )|
            87[15-8]
          )\\d{4}|
          5(?:
            2[5-9]|
            4[3-589]|
            5[1-9]|
            7\\d|
            8[0-689]|
            9[0-8]
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(30\\d{5})',
                'toll_free' => '80[0-2]\\d{4}',
                'voip' => '
          3(?:
            20|
            9\\d
          )\\d{4}
        '
              };
my %areanames = ();
$areanames{en} = {"23083", "Rodrigues",
"2304", "Central\ Region",
"2302", "North\ Region",
"2306", "South\ Region",
"23081", "Agalega",};
$areanames{es} = {"2306", "Región\ Sur",
"2304", "Región\ Central",
"2302", "Región\ Norte",};
$areanames{fr} = {"2304", "Région\ Centrale",
"2302", "Région\ Nord",
"2306", "Région\ Sud",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+230|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;