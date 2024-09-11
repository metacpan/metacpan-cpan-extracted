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
package Number::Phone::StubCountry::TG;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20240910191017;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[279]',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2(?:
            2[2-7]|
            3[23]|
            4[45]|
            55|
            6[67]|
            77
          )\\d{5}
        ',
                'geographic' => '
          2(?:
            2[2-7]|
            3[23]|
            4[45]|
            55|
            6[67]|
            77
          )\\d{5}
        ',
                'mobile' => '
          (?:
            7[019]|
            9[0-36-9]
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{es} = {"22825", "Región\ Central",
"22823", "Región\ Marítima",
"22827", "Región\ de\ Savannah",
"22822", "Lomé",
"22826", "Región\ de\ Kara",
"22824", "Región\ Plateaux",};
$areanames{fr} = {"22823", "Région\ Maritime",
"22825", "Région\ Centrale",
"22827", "Région\ des\ Savanes",
"22822", "Lomé",
"22826", "Région\ de\ la\ Kara",
"22824", "Région\ des\ Plateaux",};
$areanames{en} = {"22827", "Savannah\ region",
"22825", "Central\ region",
"22823", "Maritime\ region",
"22822", "Lome",
"22826", "Kara\ region",
"22824", "Plateaux\ region",};
my $timezones = {
               '' => [
                       'Africa/Lome'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+228|\D)//g;
      my $self = bless({ country_code => '228', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;