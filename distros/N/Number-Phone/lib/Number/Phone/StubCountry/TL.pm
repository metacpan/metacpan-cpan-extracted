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
package Number::Phone::StubCountry::TL;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20240607153922;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            [2-489]|
            70
          ',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '7',
                  'pattern' => '(\\d{4})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2[1-5]|
            3[1-9]|
            4[1-4]
          )\\d{5}
        ',
                'geographic' => '
          (?:
            2[1-5]|
            3[1-9]|
            4[1-4]
          )\\d{5}
        ',
                'mobile' => '7[2-8]\\d{6}',
                'pager' => '',
                'personal_number' => '70\\d{5}',
                'specialrate' => '(90\\d{5})',
                'toll_free' => '80\\d{5}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"67037", "Aileu",
"67043", "Viqueque",
"67039", "Oekusi",
"67036", "Liquica",
"67033", "Dili",
"67044", "Lautem",
"67022", "Cova\ Lima",
"67021", "Manufahi",
"67032", "Dili",
"67023", "Bobonaro",
"67024", "Ainaro",
"67042", "Manatuto",
"67025", "Dekuse",
"67031", "Dili",
"67038", "Ermera",
"67041", "Baucau",};
my $timezones = {
               '' => [
                       'Asia/Dili'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+670|\D)//g;
      my $self = bless({ country_code => '670', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;