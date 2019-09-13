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
our $VERSION = 1.20190912215427;

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
            6[2-4689]0|
            77\\d|
            88[0-4]
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{68025} = "Sonsorol\ State\ and\ Hatohobei\ State";
$areanames{en}->{68027} = "Angaur\ State";
$areanames{en}->{6803} = "Peleliu\ State";
$areanames{en}->{6804} = "Koror\ State";
$areanames{en}->{68053} = "Ngatpang\ State";
$areanames{en}->{68054} = "Aimeliik\ State";
$areanames{en}->{68058} = "Airai\ State";
$areanames{en}->{680622} = "Ngchesar\ State";
$areanames{en}->{68065} = "Melekeok\ State";
$areanames{en}->{68067} = "Ngiwal\ State";
$areanames{en}->{68073} = "Ngaremlengui\ State";
$areanames{en}->{68074} = "Ngardmau\ State";
$areanames{en}->{68082} = "Ngaraard\ State";
$areanames{en}->{68085} = "Ngarchelong\ State";
$areanames{en}->{68087} = "Kayangel\ State";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+680|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;