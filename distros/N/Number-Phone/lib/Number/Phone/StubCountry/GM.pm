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
our $VERSION = 1.20210309172131;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[2-9]',
                  'pattern' => '(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            4(?:
              [23]\\d\\d|
              4(?:
                1[024679]|
                [6-9]\\d
              )
            )|
            5(?:
              5(?:
                3\\d|
                4[0-7]
              )|
              6[67]\\d|
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
                'geographic' => '
          (?:
            4(?:
              [23]\\d\\d|
              4(?:
                1[024679]|
                [6-9]\\d
              )
            )|
            5(?:
              5(?:
                3\\d|
                4[0-7]
              )|
              6[67]\\d|
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
                'mobile' => '
          (?:
            [23679]\\d|
            5[0-389]
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"2204481", "Brikama\/Kanilia",
"2205710", "Barra",
"2204487", "Faraba",
"2205735", "Farafenni",
"2205543", "Japeneh\/Soma",
"220447", "Yundum",
"2204480", "Bondali",
"2205546", "Kudang",
"2204412", "Tanji",
"2205676", "Georgetown",
"2204484", "Brikama\/Kanilia",
"2205723", "Njabakunda",
"22042", "Banjul",
"2204419", "Kartong",
"2205714", "Ndugukebbe",
"220553", "Soma",
"2204414", "Sanyang",
"2204489", "Bwiam",
"2204488", "Sibanor",
"2205545", "Pakaliba",
"220574", "Kaur",
"2205725", "Iliasa",
"2204417", "Sanyang",
"22043", "Bundung\/Serekunda",
"220566", "Baja\ Kunda\/Basse\/Fatoto\/Gambisara\/Garawol\/Misera\/Sambakunda\/Sudowol",
"2204410", "Brufut",
"2204482", "Brikama\/Kanilia",
"2205666", "Numeyel",
"220446", "Kotu\/Senegambia",
"2205678", "Brikama\-Ba",
"2204485", "Kafuta",
"2204416", "Tujereng",
"2205542", "Nyorojattaba",
"2205665", "Kuntaur",
"2205541", "Kwenella",
"2205547", "Jareng",
"2205738", "Ngensanjal",
"2205540", "Kaiaf",
"220449", "Bakau",
"2204483", "Brikama\/Kanilia",
"2204486", "Gunjur",
"22044195", "Berending",
"2205674", "Bansang",
"2205544", "Bureng",
"2205720", "Kerewan",
"220567", "Sotuma",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+220|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;