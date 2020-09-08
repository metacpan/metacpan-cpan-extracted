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
package Number::Phone::StubCountry::IS;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200904144533;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[4-9]',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '3',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            4(?:
              1[0-24-69]|
              2[0-7]|
              [37][0-8]|
              4[0-245]|
              5[0-68]|
              6\\d|
              8[0-36-8]
            )|
            5(?:
              05|
              [156]\\d|
              2[02578]|
              3[0-579]|
              4[03-7]|
              7[0-2578]|
              8[0-35-9]|
              9[013-689]
            )|
            872
          )\\d{4}
        ',
                'geographic' => '
          (?:
            4(?:
              1[0-24-69]|
              2[0-7]|
              [37][0-8]|
              4[0-245]|
              5[0-68]|
              6\\d|
              8[0-36-8]
            )|
            5(?:
              05|
              [156]\\d|
              2[02578]|
              3[0-579]|
              4[03-7]|
              7[0-2578]|
              8[0-35-9]|
              9[013-689]
            )|
            872
          )\\d{4}
        ',
                'mobile' => '
          (?:
            38[589]\\d\\d|
            6(?:
              1[1-8]|
              2[0-6]|
              3[027-9]|
              4[014679]|
              5[0159]|
              6[0-69]|
              70|
              8[06-8]|
              9\\d
            )|
            7(?:
              5[057]|
              [6-9]\\d
            )|
            8(?:
              2[0-59]|
              [3-69]\\d|
              8[28]
            )
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(
          90(?:
            0\\d|
            1[5-79]|
            2[015-79]|
            3[135-79]|
            4[125-7]|
            5[25-79]|
            7[1-37]|
            8[0-35-7]
          )\\d{3}
        )|(809\\d{4})',
                'toll_free' => '80[08]\\d{4}',
                'voip' => '49[0-24-79]\\d{4}'
              };
my %areanames = ();
$areanames{en}->{35442} = "Keflavík";
$areanames{en}->{35446} = "Akureyri";
$areanames{en}->{3545} = "Reykjavík";
$areanames{en}->{35455} = "Reykjavík\/Vesturbær\/Miðbærinn";
$areanames{en}->{35456} = "Reykjavík\/Vesturbær\/Miðbærinn";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+354|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;