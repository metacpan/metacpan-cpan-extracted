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
package Number::Phone::StubCountry::PW;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20210204173827;

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
            2(?:
              55|
              77
            )|
            345|
            488|
            5(?:
              35|
              44|
              87
            )|
            6(?:
              22|
              54|
              79
            )|
            7(?:
              33|
              47
            )|
            8(?:
              24|
              55|
              76
            )|
            900
          )\\d{4}
        ',
                'geographic' => '
          (?:
            2(?:
              55|
              77
            )|
            345|
            488|
            5(?:
              35|
              44|
              87
            )|
            6(?:
              22|
              54|
              79
            )|
            7(?:
              33|
              47
            )|
            8(?:
              24|
              55|
              76
            )|
            900
          )\\d{4}
        ',
                'mobile' => '
          (?:
            46[0-5]|
            6[2-4689]0
          )\\d{4}|
          (?:
            45|
            77|
            88
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"68053", "Ngatpang\ State",
"68058", "Airai\ State",
"68073", "Ngaremlengui\ State",
"68027", "Angaur\ State",
"6803", "Peleliu\ State",
"68025", "Sonsorol\ State\ and\ Hatohobei\ State",
"68082", "Ngaraard\ State",
"68074", "Ngardmau\ State",
"68087", "Kayangel\ State",
"68067", "Ngiwal\ State",
"68085", "Ngarchelong\ State",
"680622", "Ngchesar\ State",
"68048", "Koror\ State",
"68065", "Melekeok\ State",
"68054", "Aimeliik\ State",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+680|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;