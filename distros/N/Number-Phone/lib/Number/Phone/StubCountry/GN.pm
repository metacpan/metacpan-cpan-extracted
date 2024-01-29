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
package Number::Phone::StubCountry::GN;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20231210185945;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '3',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[67]',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          3(?:
            0(?:
              24|
              3[12]|
              4[1-35-7]|
              5[13]|
              6[189]|
              [78]1|
              9[1478]
            )|
            1\\d\\d
          )\\d{4}
        ',
                'geographic' => '
          3(?:
            0(?:
              24|
              3[12]|
              4[1-35-7]|
              5[13]|
              6[189]|
              [78]1|
              9[1478]
            )|
            1\\d\\d
          )\\d{4}
        ',
                'mobile' => '6[0-356]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => '722\\d{6}'
              };
my %areanames = ();
$areanames{en} = {"2243053", "Pita",
"2243031", "Boké",
"224302", "Fria",
"2243061", "Kindia",
"2243042", "Sangoya",
"2243098", "Kissidougou",
"2243046", "Boussoura",
"2243069", "Dalaba",
"2243094", "Macenta",
"2243051", "Labé",
"224308", "Faranah",
"2243032", "Kamsar",
"2243091", "N\'Zérékoré",
"2243043", "Conakry",
"2243047", "Conakry",
"2243097", "Guéckédou",
"224307", "Kankan",
"2243041", "Conakry",
"2243068", "Mamou",
"22430613", "Télimélé",
"2243045", "Conakry",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+224|\D)//g;
      my $self = bless({ country_code => '224', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;