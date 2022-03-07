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
package Number::Phone::StubCountry::SY;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20220305001844;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[1-5]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '9',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          21\\d{6,7}|
          (?:
            1(?:
              [14]\\d|
              [2356]
            )|
            2[235]|
            3(?:
              [13]\\d|
              4
            )|
            4[134]|
            5[1-3]
          )\\d{6}
        ',
                'geographic' => '
          21\\d{6,7}|
          (?:
            1(?:
              [14]\\d|
              [2356]
            )|
            2[235]|
            3(?:
              [13]\\d|
              4
            )|
            4[134]|
            5[1-3]
          )\\d{6}
        ',
                'mobile' => '
          9(?:
            22|
            [3-689]\\d
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"96351", "Deir\ Ezzour",
"96316", "Al\-Swedaa",
"96311", "Damascus\ and\ rural\ areas",
"96333", "Hamah",
"96344", "Hamah",
"96323", "Edleb",
"96322", "Al\-Rakkah",
"96315", "Dara",
"96341", "Lattakia",
"96314", "Al\-Quneitra",
"96353", "Al\-Kameshli",
"96352", "Alhasakah",
"96325", "Menbej",
"96313", "Al\-Zabadani",
"96331", "Homs",
"96312", "Al\-Nebek",
"96321", "Aleppo",
"96343", "Tartous",
"96334", "Palmyra",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+963|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;