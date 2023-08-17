# automatically generated file, don't edit



# Copyright 2023 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::MV;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20230614174404;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'leading_digits' => '[34679]',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[89]',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            3(?:
              0[0-3]|
              3[0-59]
            )|
            6(?:
              [58][024689]|
              6[024-68]|
              7[02468]
            )
          )\\d{4}
        ',
                'geographic' => '
          (?:
            3(?:
              0[0-3]|
              3[0-59]
            )|
            6(?:
              [58][024689]|
              6[024-68]|
              7[02468]
            )
          )\\d{4}
        ',
                'mobile' => '
          (?:
            46[46]|
            [79]\\d\\d
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(900\\d{7})|(
          4(?:
            0[01]|
            50
          )\\d{4}
        )',
                'toll_free' => '800\\d{7}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"960682", "Gaafu\ Alifu",
"960674", "Faafu",
"960680", "Laamu",
"960689", "Addu",
"960302", "Malé\ Region",
"960684", "Gaafu\ Dhaalu",
"960668", "Alifu\ Dhaalu",
"960672", "Meemu",
"960670", "Vaavu",
"960301", "Malé\/Hulhulé\/Aarah",
"960658", "Raa",
"960300", "Malé\/Hulhulé\/Aarah",
"960332", "Malé\/Hulhulé\/Aarah",
"960654", "Shaviyani",
"960659", "Raa",
"960331", "Malé\/Hulhulé\/Aarah",
"960688", "Addu",
"960664", "Kaafu",
"960665", "Kaafu",
"960330", "Malé\/Hulhulé\/Aarah",
"960335", "Hulhumalé",
"960339", "Vilimalé",
"960660", "Baa",
"960334", "Malé\/Hulhulé\/Aarah",
"960652", "Haa\ Dhaalu",
"960650", "Haa\ Alifu",
"960678", "Thaa",
"960662", "Lhaviyani",
"960656", "Noonu",
"960303", "Malé\ Region",
"960666", "Alifu\ Alifu",
"960686", "Gnaviyani",
"960333", "Malé\/Hulhulé\/Aarah",
"960676", "Dhaalu",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+960|\D)//g;
      my $self = bless({ country_code => '960', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;