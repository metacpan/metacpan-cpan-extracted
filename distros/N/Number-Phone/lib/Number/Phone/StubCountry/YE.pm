# automatically generated file, don't edit



# Copyright 2025 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20250913135859;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [1-6]|
            7(?:
              [24-6]|
              8[0-7]
            )
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
                'mobile' => '7[01378]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"9674843", "Taiz",
"9676863", "Maareb",
"967684", "Dhamar",
"9673", "Hodaidah",
"96764", "Dhamar",
"967282", "Aden",
"967654", "Al\ Baidha",
"96774", "Al\ Mahweet",
"967638", "Maareb",
"967633", "Maareb",
"9677872", "Hajjah",
"9676865", "Dhamar",
"9677876", "Amran",
"96772", "Hajjah",
"96776", "Amran",
"967285", "Lahj",
"9676864", "Dhamar",
"9676869", "Al\ Baidha",
"96753", "Hadhrmout",
"96743", "Taiz",
"967650", "Dhamar",
"967283", "Aden",
"96752", "Shabwah",
"9677845", "Al\ Mahweet",
"96742", "Taiz",
"96754", "Hadhrmout",
"9674841", "Taiz",
"967433", "Ibb",
"9676861", "Dhamar",
"967656", "Al\ Baidha",
"96744", "Ibb",
"9677878", "Saadah",
"9674840", "Taiz",
"967484", "Ibb",
"967786", "Amran",
"96725", "Lahj",
"967651", "Dhamar",
"9676860", "Al\ Baidha",
"9676867", "Dhamar",
"9674842", "Taiz",
"967566", "Soqatrah",
"967653", "Al\ Baidha",
"9676862", "Al\ Baidha",
"967280", "Aden",
"967634", "Aljawf",
"9677875", "Saadah",
"9676866", "Dhamar",
"967485", "Ibb",
"967683", "Maareb",
"9676853", "Al\ Baidha",
"96775", "Saadah",
"967286", "Abyan",
"9677873", "Hajjah",
"967281", "Aden",
"967657", "Al\ Baidha",
"96724", "Dhalea",
"9671", "Sanaa",
"9677871", "Hajjah",
"967682", "Dhamar",
"96755", "Hadhrmout",
"9676868", "Al\ Baidha",
"9672840", "Aden",
"9677870", "Hajjah",
"967630", "Maareb",
"9677877", "Amran",
"967284", "Dhalea",
"967652", "Al\ Baidha",
"96745", "Ibb",
"96726", "Abyan",
"9677879", "Al\ Mahweet",
"96723", "Aden",
"9677874", "Al\ Mahweet",
"967639", "Dhamar",
"967483", "Taiz",
"967785", "Saadah",
"9676850", "Al\ Baidha",
"96722", "Aden",
"967655", "Al\ Baidha",
"967636", "Maareb",};
my $timezones = {
               '' => [
                       'Asia/Aden'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+967|\D)//g;
      my $self = bless({ country_code => '967', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '967', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;