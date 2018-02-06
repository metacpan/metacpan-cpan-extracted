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
package Number::Phone::StubCountry::AF;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180203200232;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'pattern' => '([2-7]\\d)(\\d{3})(\\d{4})',
                  'leading_digits' => '[2-7]',
                  'national_rule' => '0$1'
                }
              ];

my $validators = {
                'toll_free' => '',
                'fixed_line' => '
          (?:
            [25][0-8]|
            [34][0-4]|
            6[0-5]
          )[2-9]\\d{6}
        ',
                'specialrate' => '',
                'geographic' => '
          (?:
            [25][0-8]|
            [34][0-4]|
            6[0-5]
          )[2-9]\\d{6}
        ',
                'personal_number' => '',
                'mobile' => '
          7(?:
            [014-9]\\d|
            2[89]|
            30
          )\\d{6}
        ',
                'voip' => '',
                'pager' => ''
              };
my %areanames = (
  9320 => "Kabul",
  9321 => "Parwan",
  9322 => "Kapisa",
  9323 => "Bamian",
  9324 => "Wardak",
  9325 => "Logar",
  9326 => "Dorkondi",
  9327 => "Khost",
  9328 => "Panjshar",
  9330 => "Kandahar",
  9331 => "Ghazni",
  9332 => "Uruzgan",
  9333 => "Zabol",
  9334 => "Helmand",
  9340 => "Heart",
  9341 => "Badghis",
  9342 => "Ghowr",
  9343 => "Farah",
  9344 => "Nimruz",
  9350 => "Balkh",
  9351 => "Kunduz",
  9352 => "Badkhshan",
  9353 => "Takhar",
  9354 => "Jowzjan",
  9355 => "Samangan",
  9356 => "Sar\-E\ Pol",
  9357 => "Faryab",
  9358 => "Baghlan",
  9360 => "Nangarhar",
  9361 => "Nurestan",
  9362 => "Kunarha",
  9363 => "Laghman",
  9364 => "Paktia",
  9365 => "Paktika",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+93|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  
      return $self if ($self->is_valid());
      {
        no warnings 'uninitialized';
        $number =~ s/^(?:0)//;
      }
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
    return $self->is_valid() ? $self : undef;
}
1;