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
package Number::Phone::StubCountry::YE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20230614174405;

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
$areanames{en} = {"9677870", "Hajjah",
"9676860", "Al\ Baidha",
"967785", "Saadah",
"9677845", "Al\ Mahweet",
"96774", "Al\ Mahweet",
"9674842", "Taiz",
"96742", "Taiz",
"967483", "Taiz",
"967286", "Abyan",
"967636", "Maareb",
"967656", "Al\ Baidha",
"967683", "Maareb",
"96754", "Hadhrmout",
"9676861", "Dhamar",
"967650", "Dhamar",
"9673", "Hodaidah",
"967282", "Aden",
"967630", "Maareb",
"9677871", "Hajjah",
"967651", "Dhamar",
"967484", "Ibb",
"967657", "Al\ Baidha",
"967485", "Ibb",
"9672840", "Aden",
"967280", "Aden",
"967652", "Al\ Baidha",
"967281", "Aden",
"9674843", "Taiz",
"96772", "Hajjah",
"96744", "Ibb",
"96726", "Abyan",
"96725", "Lahj",
"967639", "Dhamar",
"96723", "Aden",
"967566", "Soqatrah",
"9677874", "Al\ Mahweet",
"967638", "Maareb",
"9676864", "Dhamar",
"967684", "Dhamar",
"9676853", "Al\ Baidha",
"96764", "Dhamar",
"96752", "Shabwah",
"967653", "Al\ Baidha",
"967633", "Maareb",
"96775", "Saadah",
"967283", "Aden",
"96722", "Aden",
"96776", "Amran",
"9674841", "Taiz",
"9677873", "Hajjah",
"9677875", "Saadah",
"9676863", "Maareb",
"9676865", "Dhamar",
"96755", "Hadhrmout",
"9671", "Sanaa",
"967433", "Ibb",
"96753", "Hadhrmout",
"9676867", "Dhamar",
"9677877", "Amran",
"9676866", "Dhamar",
"9677876", "Amran",
"96743", "Taiz",
"9676862", "Al\ Baidha",
"96745", "Ibb",
"9677872", "Hajjah",
"96724", "Dhalea",
"967285", "Lahj",
"9674840", "Taiz",
"967284", "Dhalea",
"967634", "Aljawf",
"967655", "Al\ Baidha",
"967654", "Al\ Baidha",
"9677878", "Saadah",
"9676869", "Al\ Baidha",
"9676868", "Al\ Baidha",
"9677879", "Al\ Mahweet",
"9676850", "Al\ Baidha",
"967786", "Amran",
"967682", "Dhamar",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+967|\D)//g;
      my $self = bless({ country_code => '967', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '967', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;