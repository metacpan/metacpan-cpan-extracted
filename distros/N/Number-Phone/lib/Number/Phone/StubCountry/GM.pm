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
package Number::Phone::StubCountry::GM;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170908113148;

my $formatters = [
                {
                  'pattern' => '(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'mobile' => '[23679]\\d{6}',
                'toll_free' => '',
                'specialrate' => '',
                'fixed_line' => '
          (?:
            4(?:
              [23]\\d{2}|
              4(?:
                1[024679]|
                [6-9]\\d
              )
            )|
            5(?:
              54[0-7]|
              6(?:
                [67]\\d
              )|
              7(?:
                1[04]|
                2[035]|
                3[58]|
                48
              )
            )|
            8\\d{3}
          )\\d{3}
        ',
                'voip' => '',
                'geographic' => '
          (?:
            4(?:
              [23]\\d{2}|
              4(?:
                1[024679]|
                [6-9]\\d
              )
            )|
            5(?:
              54[0-7]|
              6(?:
                [67]\\d
              )|
              7(?:
                1[04]|
                2[035]|
                3[58]|
                48
              )
            )|
            8\\d{3}
          )\\d{3}
        ',
                'personal_number' => '',
                'pager' => ''
              };
my %areanames = (
  22042 => "Banjul",
  22043 => "Bundung\/Serekunda",
  220441 => "Sanyang",
  2204410 => "Brufut",
  2204412 => "Tanji",
  2204416 => "Tujereng",
  2204417 => "Sanyang",
  2204419 => "Kartong",
  22044195 => "Berending",
  220446 => "Kotu\/Senegambia",
  220447 => "Yundum",
  220448 => "Brikama\/Kanilia",
  2204480 => "Bondali",
  2204485 => "Kafuta",
  2204486 => "Gunjur",
  2204487 => "Faraba",
  2204488 => "Sibanor",
  2204489 => "Bwiam",
  220449 => "Bakau",
  2205540 => "Kaiaf",
  2205541 => "Kwenella",
  2205542 => "Nyorojattaba",
  2205543 => "Japeneh\/Soma",
  2205544 => "Bureng",
  2205545 => "Pakaliba",
  2205546 => "Kudang",
  2205547 => "Jareng",
  220566 => "Baja\ Kunda\/Basse\/Fatoto\/Gambisara\/Garawol\/Misera\/Sambakunda\/Sudowol",
  2205665 => "Kuntaur",
  2205666 => "Numeyel",
  220567 => "Sotuma",
  2205674 => "Bansang",
  2205676 => "Georgetown",
  2205678 => "Brikama\-Ba",
  2205710 => "Barra",
  2205714 => "Ndugukebbe",
  2205720 => "Kerewan",
  2205723 => "Njabakunda",
  2205725 => "Iliasa",
  2205735 => "Farafenni",
  2205738 => "Ngensanjal",
  2205748 => "Kaur",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+220|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  return $self->is_valid() ? $self : undef;
}
1;