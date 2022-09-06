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
package Number::Phone::StubCountry::CH;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20220903144936;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            8[047]|
            90
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            [2-79]|
            81
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4 $5',
                  'leading_digits' => '8',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{3})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2[12467]|
            3[1-4]|
            4[134]|
            5[256]|
            6[12]|
            [7-9]1
          )\\d{7}
        ',
                'geographic' => '
          (?:
            2[12467]|
            3[1-4]|
            4[134]|
            5[256]|
            6[12]|
            [7-9]1
          )\\d{7}
        ',
                'mobile' => '7[35-9]\\d{7}',
                'pager' => '74[0248]\\d{6}',
                'personal_number' => '878\\d{6}',
                'specialrate' => '(84[0248]\\d{6})|(90[016]\\d{6})|(5[18]\\d{7})',
                'toll_free' => '800\\d{6}',
                'voip' => ''
              };
my %areanames = ();
$areanames{it} = {"4161", "Basilea",
"4121", "Losanna",
"4131", "Berna",
"4126", "Friburgo",
"4144", "Zurigo",
"4181", "Coira",
"4171", "San\ Gallo",
"4143", "Zurigo",
"4122", "Ginevra",
"4132", "Bienne\/Neuchâtel\/Soletta\/Giura",
"4141", "Lucerna",};
$areanames{de} = {"4141", "Luzern",
"4132", "Biel\/Neuenburg\/Solothurn\/Jura",
"4122", "Genf",
"4143", "Zürich",
"4127", "Sitten",
"4144", "Zürich",
"4126", "Freiburg",
"4131", "Bern",};
$areanames{fr} = {"4122", "Genève",
"4171", "St\.\ Gall",
"4181", "Coire",
"4133", "Thoune",
"4152", "Winterthour",
"4161", "Bâle",};
$areanames{en} = {"4143", "Zurich",
"4171", "St\.\ Gallen",
"4124", "Yverdon\/Aigle",
"4191", "Bellinzona",
"4134", "Burgdorf\/Langnau\ i\.E\.",
"4156", "Baden",
"4122", "Geneva",
"4162", "Olten",
"4141", "Lucerne",
"4155", "Rapperswil",
"4132", "Bienne\/Neuchâtel\/Soleure\/Jura",
"4161", "Basel",
"4121", "Lausanne",
"4152", "Winterthur",
"4131", "Berne",
"4126", "Fribourg",
"4133", "Thun",
"4127", "Sion",
"4144", "Zurich",
"4181", "Chur",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+41|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;