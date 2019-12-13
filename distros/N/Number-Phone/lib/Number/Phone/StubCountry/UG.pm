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
package Number::Phone::StubCountry::UG;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20191211212303;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '2024',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{4})(\\d{5})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            [27-9]|
            4(?:
              6[45]|
              [7-9]
            )
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{6})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[34]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{7})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            20(?:
              (?:
                (?:
                  [0147]\\d|
                  5[0-4]
                )\\d|
                2(?:
                  40|
                  [5-9]\\d
                )|
                3(?:
                  0[67]|
                  2[0-4]
                )|
                810
              )\\d|
              6(?:
                00[0-2]|
                [15-9]\\d\\d|
                30[0-4]
              )
            )|
            [34]\\d{5}
          )\\d{3}
        ',
                'geographic' => '
          (?:
            20(?:
              (?:
                (?:
                  [0147]\\d|
                  5[0-4]
                )\\d|
                2(?:
                  40|
                  [5-9]\\d
                )|
                3(?:
                  0[67]|
                  2[0-4]
                )|
                810
              )\\d|
              6(?:
                00[0-2]|
                [15-9]\\d\\d|
                30[0-4]
              )
            )|
            [34]\\d{5}
          )\\d{3}
        ',
                'mobile' => '
          7260\\d{5}|
          7(?:
            [0157-9]\\d|
            20|
            4[0-4]
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(90[1-3]\\d{6})',
                'toll_free' => '800[1-3]\\d{5}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{25641} = "Kampala";
$areanames{en}->{25643} = "Jinja";
$areanames{en}->{25645} = "Mbale";
$areanames{en}->{25646} = "Mityana";
$areanames{en}->{256464} = "Mubende";
$areanames{en}->{256465} = "Masindi";
$areanames{en}->{256471} = "Gulu";
$areanames{en}->{256473} = "Lira";
$areanames{en}->{256476} = "Arua";
$areanames{en}->{256481} = "Masaka";
$areanames{en}->{256483} = "Fort\ Portal";
$areanames{en}->{256485} = "Mbarara";
$areanames{en}->{256486} = "Kabale\/Rukungiri\/Kisoro";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+256|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;