# automatically generated file, don't edit



# Copyright 2024 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::KP;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20240910191016;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '8',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[2-7]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '1',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            (?:
              195|
              2
            )\\d|
            3[19]|
            4[159]|
            5[37]|
            6[17]|
            7[39]|
            85
          )\\d{6}
        ',
                'geographic' => '
          (?:
            (?:
              195|
              2
            )\\d|
            3[19]|
            4[159]|
            5[37]|
            6[17]|
            7[39]|
            85
          )\\d{6}
        ',
                'mobile' => '19[1-3]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"85073", "Chongjin",
"85053", "Hamhung",
"850195", "Pyongyang",
"8502381", "Pyongyang",
"85031", "Pyongyang",
"85028", "Pyongyang",
"85027", "Pyongyang",
"85061", "Sinuiju",
"85041", "Sariwon",
"8508", "Rason",
"85057", "Wonsan",
"85067", "Kanggye",
"85045", "Haeju",
"85021", "Pyongyang",
"85049", "Kaesong",
"85039", "Nampo",
"85079", "Hyesan",};
my $timezones = {
               '' => [
                       'Asia/Seoul'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+850|\D)//g;
      my $self = bless({ country_code => '850', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '850', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;