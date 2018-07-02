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
package Number::Phone::StubCountry::TN;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180619214157;

my $formatters = [
                {
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})',
                  'format' => '$1 $2 $3'
                }
              ];

my $validators = {
                'mobile' => '
          (?:
            [259]\\d{3}|
            3(?:
              001|
              1(?:
                [1-35]\\d|
                40
              )|
              240|
              6[0-4]\\d|
              91\\d
            )|
            4[0-6]\\d{2}
          )\\d{4}
        ',
                'specialrate' => '(8[12]10\\d{4})|(88\\d{6})',
                'pager' => '',
                'geographic' => '
          (?:
            3[0-2]\\d{3}|
            7\\d{4}|
            81200
          )\\d{3}
        ',
                'personal_number' => '',
                'voip' => '',
                'fixed_line' => '
          (?:
            3[0-2]\\d{3}|
            7\\d{4}|
            81200
          )\\d{3}
        ',
                'toll_free' => '8010\\d{4}'
              };
my %areanames = (
  21670 => "Ben\ Arous",
  21671 => "Ariana\/Ben\ Arous\/Carthage\/Tunis",
  21672 => "Bizerte\/Nabeul\/Zaghouan",
  21673 => "Chebba\/Hamman\-Sousse\/Khenis\/Mahdia\/Monastir\/Sousse",
  21674 => "Agareb\/Sfax",
  21675 => "Gabes\/Kebili\/Medenine\/Tataouine",
  21676 => "Gafsa\/Sidi\ Bouzid\/Tozeur",
  21677 => "Haffouz\/Kairouan\/Kasserine",
  21678 => "Beja\/Jendouba\/Kef\/La\ Kef\/Siliana\/Tabarka",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+216|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;