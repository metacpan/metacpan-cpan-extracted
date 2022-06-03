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
package Number::Phone::StubCountry::YE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20220601185320;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [1-6]|
            7[24-68]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '7',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          78[0-7]\\d{4}|
          17\\d{6}|
          (?:
            [12][2-68]|
            3[2358]|
            4[2-58]|
            5[2-6]|
            6[3-58]|
            7[24-6]
          )\\d{5}
        ',
                'geographic' => '
          78[0-7]\\d{4}|
          17\\d{6}|
          (?:
            [12][2-68]|
            3[2358]|
            4[2-58]|
            5[2-6]|
            6[3-58]|
            7[24-6]
          )\\d{5}
        ',
                'mobile' => '7[0137]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"9676863", "Maareb",
"9676868", "Al\ Baidha",
"9676862", "Al\ Baidha",
"967683", "Maareb",
"967652", "Al\ Baidha",
"9677845", "Al\ Mahweet",
"9676867", "Dhamar",
"967284", "Dhalea",
"9676861", "Dhamar",
"967485", "Ibb",
"967651", "Dhamar",
"9671", "Sanaa",
"967655", "Al\ Baidha",
"967638", "Maareb",
"967280", "Aden",
"96753", "Hadhrmout",
"9677879", "Al\ Mahweet",
"967656", "Al\ Baidha",
"9672840", "Aden",
"96724", "Dhalea",
"9676853", "Al\ Baidha",
"96722", "Aden",
"967633", "Maareb",
"96726", "Abyan",
"96775", "Saadah",
"96776", "Amran",
"96772", "Hajjah",
"96774", "Al\ Mahweet",
"96725", "Lahj",
"9677870", "Hajjah",
"96743", "Taiz",
"967283", "Aden",
"967684", "Dhamar",
"967634", "Aljawf",
"9676866", "Dhamar",
"967630", "Maareb",
"9674841", "Taiz",
"9677875", "Saadah",
"967639", "Dhamar",
"9674843", "Taiz",
"9674842", "Taiz",
"9676864", "Dhamar",
"96764", "Dhamar",
"9677876", "Amran",
"967657", "Al\ Baidha",
"967433", "Ibb",
"9676865", "Dhamar",
"9676850", "Al\ Baidha",
"9677874", "Al\ Mahweet",
"9673", "Hodaidah",
"9676860", "Al\ Baidha",
"967636", "Maareb",
"96755", "Hadhrmout",
"96752", "Shabwah",
"96754", "Hadhrmout",
"96723", "Aden",
"967483", "Taiz",
"967653", "Al\ Baidha",
"967682", "Dhamar",
"96742", "Taiz",
"96744", "Ibb",
"96745", "Ibb",
"9676869", "Al\ Baidha",
"967286", "Abyan",
"967786", "Amran",
"9674840", "Taiz",
"967650", "Dhamar",
"967484", "Ibb",
"9677872", "Hajjah",
"9677873", "Hajjah",
"9677878", "Saadah",
"967285", "Lahj",
"967281", "Aden",
"967654", "Al\ Baidha",
"967785", "Saadah",
"9677871", "Hajjah",
"9677877", "Amran",
"967282", "Aden",
"967566", "Soqatrah",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+967|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;