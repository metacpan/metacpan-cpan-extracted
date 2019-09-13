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
package Number::Phone::StubCountry::SO;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190912215428;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '8[125]',
                  'pattern' => '(\\d{2})(\\d{4})'
                },
                {
                  'format' => '$1',
                  'leading_digits' => '[134]',
                  'pattern' => '(\\d{6})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            1|
            2[0-79]|
            3[0-46-8]|
            4[0-7]|
            59
          ',
                  'pattern' => '(\\d)(\\d{6})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            24|
            [67]
          ',
                  'pattern' => '(\\d)(\\d{7})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [348]|
            64|
            79[0-8]|
            90
          ',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            1|
            28|
            6[1-35-9]|
            799|
            9[2-9]
          ',
                  'pattern' => '(\\d{2})(\\d{5,7})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            1\\d|
            2[0-79]|
            3[0-46-8]|
            4[0-7]|
            59
          )\\d{5}|
          (?:
            [134]\\d|
            8[125]
          )\\d{4}
        ',
                'geographic' => '
          (?:
            1\\d|
            2[0-79]|
            3[0-46-8]|
            4[0-7]|
            59
          )\\d{5}|
          (?:
            [134]\\d|
            8[125]
          )\\d{4}
        ',
                'mobile' => '
          28\\d{5}|
          (?:
            6[1-9]|
            79
          )\\d{6,7}|
          (?:
            15|
            24|
            (?:
              3[59]|
              4[89]|
              8[08]
            )\\d|
            60|
            7[1-8]|
            9(?:
              0[67]|
              [2-9]
            )
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{2521} = "Mogadishu";
$areanames{en}->{2523} = "Hargeisa";
$areanames{en}->{2524} = "Garowe";
$areanames{en}->{25261} = "Mogadishu";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+252|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;