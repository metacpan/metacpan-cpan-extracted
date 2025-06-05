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
package Number::Phone::StubCountry::TN;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20250605193637;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[2-57-9]',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          81200\\d{3}|
          (?:
            3[0-2]|
            7\\d
          )\\d{6}
        ',
                'geographic' => '
          81200\\d{3}|
          (?:
            3[0-2]|
            7\\d
          )\\d{6}
        ',
                'mobile' => '
          3(?:
            001|
            [12]40
          )\\d{4}|
          (?:
            (?:
              [259]\\d|
              4[0-8]
            )\\d|
            3(?:
              1[1-35]|
              6[0-4]|
              91
            )
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(8[12]10\\d{4})|(88\\d{6})',
                'toll_free' => '8010\\d{4}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"21675", "Gabes\/Kebili\/Medenine\/Tataouine",
"21676", "Gafsa\/Sidi\ Bouzid\/Tozeur",
"21674", "Agareb\/Sfax",
"21670", "Ben\ Arous",
"21673", "Chebba\/Hamman\-Sousse\/Khenis\/Mahdia\/Monastir\/Sousse",
"21678", "Beja\/Jendouba\/Kef\/La\ Kef\/Siliana\/Tabarka",
"21679", "Ariana\/Ben\ Arous\/Manouba\/Tunis",
"21677", "Haffouz\/Kairouan\/Kasserine",
"21671", "Ariana\/Ben\ Arous\/Carthage\/Tunis",
"21672", "Bizerte\/Nabeul\/Zaghouan",};
my $timezones = {
               '' => [
                       'Africa/Tunis'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+216|\D)//g;
      my $self = bless({ country_code => '216', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;