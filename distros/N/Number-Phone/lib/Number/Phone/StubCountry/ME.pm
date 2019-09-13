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
package Number::Phone::StubCountry::ME;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190912215427;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[2-9]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            20[2-8]|
            3(?:
              [0-2][2-7]|
              3[24-7]
            )|
            4(?:
              0[2-467]|
              1[2467]
            )|
            5(?:
              [01][2467]|
              2[2-467]
            )
          )\\d{5}
        ',
                'geographic' => '
          (?:
            20[2-8]|
            3(?:
              [0-2][2-7]|
              3[24-7]
            )|
            4(?:
              0[2-467]|
              1[2467]
            )|
            5(?:
              [01][2467]|
              2[2-467]
            )
          )\\d{5}
        ',
                'mobile' => '
          6(?:
            00|
            3[024]|
            6[0-25]|
            [7-9]\\d
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(
          9(?:
            4[1568]|
            5[178]
          )\\d{5}
        )|(77[1-9]\\d{5})',
                'toll_free' => '
          80(?:
            [0-2578]|
            9\\d
          )\\d{5}
        ',
                'voip' => '78[1-49]\\d{5}'
              };
my %areanames = ();
$areanames{en}->{3822} = "Danilovgad\/Kolasin\/Podgorica";
$areanames{en}->{38230} = "Bar\/Ulcinj";
$areanames{en}->{38231} = "Herceg\ Novi";
$areanames{en}->{38232} = "Kotor\/Tivat";
$areanames{en}->{38233} = "Budva";
$areanames{en}->{38240} = "Niksic\/Pluzine\/Savnik";
$areanames{en}->{38241} = "Cetinje";
$areanames{en}->{38250} = "Bijelo\ Polje\/Mojkovac";
$areanames{en}->{38251} = "Andrijevica\/Berane\/Blue\/Gusinje\/Petnitsa\/Rožaje";
$areanames{en}->{38252} = "Pljevlja\/Zabljak";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+382|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;