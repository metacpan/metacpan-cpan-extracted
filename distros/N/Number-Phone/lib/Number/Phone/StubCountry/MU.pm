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
package Number::Phone::StubCountry::MU;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250605193636;

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
                  'leading_digits' => '[57]',
                  'pattern' => '(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '8',
                  'pattern' => '(\\d{5})(\\d{5})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              [0346-8]\\d|
              1[0-8]
            )|
            4(?:
              [013568]\\d|
              2[4-8]|
              71|
              90
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
              1[0-8]
            )|
            4(?:
              [013568]\\d|
              2[4-8]|
              71|
              90
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
          (?:
            5(?:
              2[5-9]|
              4[3-689]|
              [57]\\d|
              8[0-689]|
              9[0-8]
            )|
            7(?:
              0[0-6]|
              3[013]
            )
          )\\d{5}
        ',
                'pager' => '219\\d{4}',
                'personal_number' => '',
                'specialrate' => '(30\\d{5})',
                'toll_free' => '
          802\\d{7}|
          80[0-2]\\d{4}
        ',
                'voip' => '
          3(?:
            20|
            9\\d
          )\\d{4}
        '
              };
my %areanames = ();
$areanames{en} = {"230214", "North\ Region",
"23024", "North\ Region",
"230218", "North\ Region",
"23083", "Rodrigues",
"230217", "North\ Region",
"230210", "North\ Region",
"230211", "North\ Region",
"230215", "North\ Region",
"2306", "South\ Region",
"23020", "North\ Region",
"23028", "North\ Region",
"23026", "North\ Region",
"230216", "North\ Region",
"230213", "North\ Region",
"23081", "Agalega",
"230212", "North\ Region",
"2304", "Central\ Region",
"23023", "North\ Region",
"23027", "North\ Region",};
$areanames{es} = {"230217", "Región\ Norte",
"230218", "Región\ Norte",
"23024", "Región\ Norte",
"230214", "Región\ Norte",
"23028", "Región\ Norte",
"23020", "Región\ Norte",
"2306", "Región\ Sur",
"230215", "Región\ Norte",
"230210", "Región\ Norte",
"230211", "Región\ Norte",
"230216", "Región\ Norte",
"230213", "Región\ Norte",
"23026", "Región\ Norte",
"23027", "Región\ Norte",
"23023", "Región\ Norte",
"2304", "Región\ Central",
"230212", "Región\ Norte",};
$areanames{fr} = {"23023", "Région\ Nord",
"23027", "Région\ Nord",
"230212", "Région\ Nord",
"2304", "Région\ Centrale",
"23026", "Région\ Nord",
"230213", "Région\ Nord",
"230216", "Région\ Nord",
"23020", "Région\ Nord",
"23028", "Région\ Nord",
"230210", "Région\ Nord",
"230211", "Région\ Nord",
"230215", "Région\ Nord",
"2306", "Région\ Sud",
"230218", "Región\ Nord",
"230217", "Région\ Nord",
"230214", "Région\ Nord",
"23024", "Région\ Nord",};
my $timezones = {
               '' => [
                       'Indian/Mauritius'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+230|\D)//g;
      my $self = bless({ country_code => '230', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;