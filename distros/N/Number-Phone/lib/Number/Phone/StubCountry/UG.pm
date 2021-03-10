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
our $VERSION = 1.20210309172133;

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
          20(?:
            (?:
              (?:
                24|
                81
              )0|
              30[67]
            )\\d|
            6(?:
              00[0-2]|
              30[0-4]
            )
          )\\d{3}|
          (?:
            20(?:
              [0147]\\d|
              2[5-9]|
              32|
              5[0-4]|
              6[15-9]
            )|
            [34]\\d{3}
          )\\d{5}
        ',
                'geographic' => '
          20(?:
            (?:
              (?:
                24|
                81
              )0|
              30[67]
            )\\d|
            6(?:
              00[0-2]|
              30[0-4]
            )
          )\\d{3}|
          (?:
            20(?:
              [0147]\\d|
              2[5-9]|
              32|
              5[0-4]|
              6[15-9]
            )|
            [34]\\d{3}
          )\\d{5}
        ',
                'mobile' => '
          7260\\d{5}|
          7(?:
            [0157-9]\\d|
            20|
            36|
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
$areanames{en} = {"25643", "Jinja",
"256486", "Kabale\/Rukungiri\/Kisoro",
"256483", "Fort\ Portal",
"25641", "Kampala",
"256481", "Masaka",
"256471", "Gulu",
"256485", "Mbarara",
"256465", "Masindi",
"256473", "Lira",
"256476", "Arua",
"256464", "Mubende",
"25645", "Mbale",
"25646", "Mityana",};

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