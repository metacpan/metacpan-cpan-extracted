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
package Number::Phone::StubCountry::CZ;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20210309172131;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [2-8]|
            9[015-7]
          ',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '9',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '9',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2\\d|
            3[1257-9]|
            4[16-9]|
            5[13-9]
          )\\d{7}
        ',
                'geographic' => '
          (?:
            2\\d|
            3[1257-9]|
            4[16-9]|
            5[13-9]
          )\\d{7}
        ',
                'mobile' => '
          (?:
            60[1-8]|
            7(?:
              0[2-5]|
              [2379]\\d
            )
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '70[01]\\d{6}',
                'specialrate' => '(8[134]\\d{7})|(
          9(?:
            0[05689]|
            76
          )\\d{6}
        )|(
          9(?:
            5\\d|
            7[2-4]
          )\\d{6}
        )',
                'toll_free' => '800\\d{6}',
                'voip' => '9[17]0\\d{6}'
              };
my %areanames = ();
$areanames{en} = {"42051", "South\ Moravian\ Region",
"42053", "South\ Moravian\ Region",
"42054", "South\ Moravian\ Region",
"42031", "Central\ Bohemian\ Region",
"42032", "Central\ Bohemian\ Region",
"42041", "Ústí\ nad\ Labem\ Region",
"4202", "Prague",
"42057", "Zlín\ Region",
"42039", "South\ Bohemian\ Region",
"42056", "Vysočina\ Region",
"42058", "Olomouc\ Region",
"42055", "Moravian\-Silesian\ Region",
"42049", "Hradec\ Králové\ Region",
"42046", "Pardubice\ Region",
"42048", "Liberec\ Region",
"42059", "Moravian\-Silesian\ Region",
"42037", "Plzeň\ Region",
"42038", "South\ Bohemian\ Region",
"42047", "Ústí\ nad\ Labem\ Region",
"42035", "Karlovy\ Vary\ Region",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+420|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;