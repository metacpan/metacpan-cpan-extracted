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
our $VERSION = 1.20190912215426;

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
              54[0-7]|
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
              54[0-7]|
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
            5[01]
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{22042} = "Banjul";
$areanames{en}->{22043} = "Bundung\/Serekunda";
$areanames{en}->{2204410} = "Brufut";
$areanames{en}->{2204412} = "Tanji";
$areanames{en}->{2204414} = "Sanyang";
$areanames{en}->{2204416} = "Tujereng";
$areanames{en}->{2204417} = "Sanyang";
$areanames{en}->{2204419} = "Kartong";
$areanames{en}->{22044195} = "Berending";
$areanames{en}->{220446} = "Kotu\/Senegambia";
$areanames{en}->{220447} = "Yundum";
$areanames{en}->{2204480} = "Bondali";
$areanames{en}->{2204481} = "Brikama\/Kanilia";
$areanames{en}->{2204482} = "Brikama\/Kanilia";
$areanames{en}->{2204483} = "Brikama\/Kanilia";
$areanames{en}->{2204484} = "Brikama\/Kanilia";
$areanames{en}->{2204485} = "Kafuta";
$areanames{en}->{2204486} = "Gunjur";
$areanames{en}->{2204487} = "Faraba";
$areanames{en}->{2204488} = "Sibanor";
$areanames{en}->{2204489} = "Bwiam";
$areanames{en}->{220449} = "Bakau";
$areanames{en}->{2205540} = "Kaiaf";
$areanames{en}->{2205541} = "Kwenella";
$areanames{en}->{2205542} = "Nyorojattaba";
$areanames{en}->{2205543} = "Japeneh\/Soma";
$areanames{en}->{2205544} = "Bureng";
$areanames{en}->{2205545} = "Pakaliba";
$areanames{en}->{2205546} = "Kudang";
$areanames{en}->{2205547} = "Jareng";
$areanames{en}->{220566} = "Baja\ Kunda\/Basse\/Fatoto\/Gambisara\/Garawol\/Misera\/Sambakunda\/Sudowol";
$areanames{en}->{2205665} = "Kuntaur";
$areanames{en}->{2205666} = "Numeyel";
$areanames{en}->{220567} = "Sotuma";
$areanames{en}->{2205674} = "Bansang";
$areanames{en}->{2205676} = "Georgetown";
$areanames{en}->{2205678} = "Brikama\-Ba";
$areanames{en}->{2205710} = "Barra";
$areanames{en}->{2205714} = "Ndugukebbe";
$areanames{en}->{2205720} = "Kerewan";
$areanames{en}->{2205723} = "Njabakunda";
$areanames{en}->{2205725} = "Iliasa";
$areanames{en}->{2205735} = "Farafenni";
$areanames{en}->{2205738} = "Ngensanjal";
$areanames{en}->{220574} = "Kaur";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+220|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;