# automatically generated file, don't edit



# Copyright 2023 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::LK;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20230903131448;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '7',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[1-689]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            12[2-9]|
            602|
            8[12]\\d|
            9(?:
              1\\d|
              22|
              9[245]
            )
          )\\d{6}|
          (?:
            11|
            2[13-7]|
            3[1-8]|
            4[157]|
            5[12457]|
            6[35-7]
          )[2-57]\\d{6}
        ',
                'geographic' => '
          (?:
            12[2-9]|
            602|
            8[12]\\d|
            9(?:
              1\\d|
              22|
              9[245]
            )
          )\\d{6}|
          (?:
            11|
            2[13-7]|
            3[1-8]|
            4[157]|
            5[12457]|
            6[35-7]
          )[2-57]\\d{6}
        ',
                'mobile' => '
          7(?:
            [0-25-8]\\d|
            4[0-4]
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(1973\\d{5})',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"9435", "Kegalle",
"9447", "Hambantota",
"9451", "Hatton\,\ Nuwara\ Eliya",
"9463", "Ampara",
"9445", "Ratnapura",
"9434", "Kalutara",
"9421", "Jaffna",
"9437", "Kurunegala",
"9432", "Chilaw\,\ Puttalam",
"9441", "Matara",
"9455", "Badulla",
"9425", "Anuradhapura",
"9411", "Colombo",
"9427", "Polonnaruwa",
"9431", "Negombo\,\ Gampaha",
"9424", "Vavuniya",
"9452", "Nuwara\ Eliya",
"9438", "Panadura\,\ Kalutara",
"9457", "Bandarawela\,\ Badulla",
"9454", "Nawalapitiya\,\ Kandy",
"9466", "Matale",
"9465", "Batticaloa",
"9467", "Kalmunai\,\ Ampara",
"9426", "Trincomalee",
"9433", "Gampaha",
"9482", "Kandy",
"9423", "Mannar",
"9436", "Avissawella\,\ Colombo",
"9491", "Galle",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+94|\D)//g;
      my $self = bless({ country_code => '94', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '94', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;