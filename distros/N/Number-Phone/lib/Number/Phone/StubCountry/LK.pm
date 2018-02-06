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
package Number::Phone::StubCountry::LK;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180203200235;

my $formatters = [
                {
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})',
                  'leading_digits' => '[1-689]',
                  'format' => '$1 $2 $3',
                  'national_rule' => '0$1'
                },
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '7',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'voip' => '',
                'pager' => '',
                'fixed_line' => '
          1(?:
            1[2-57]\\d{6}|
            973\\d{5}
          )|
          (?:
            2[13-7]|
            3[1-8]|
            4[157]|
            5[12457]|
            6[35-7]|
            [89]1
          )[2-57]\\d{6}
        ',
                'specialrate' => '',
                'toll_free' => '',
                'geographic' => '
          1(?:
            1[2-57]\\d{6}|
            973\\d{5}
          )|
          (?:
            2[13-7]|
            3[1-8]|
            4[157]|
            5[12457]|
            6[35-7]|
            [89]1
          )[2-57]\\d{6}
        ',
                'mobile' => '7[0125-8]\\d{7}',
                'personal_number' => ''
              };
my %areanames = (
  9411 => "Colombo",
  9421 => "Jaffna",
  9423 => "Mannar",
  9424 => "Vavuniya",
  9425 => "Anuradhapura",
  9426 => "Trincomalee",
  9427 => "Polonnaruwa",
  9431 => "Negombo\,\ Gampaha",
  9432 => "Chilaw\,\ Puttalam",
  9433 => "Gampaha",
  9434 => "Kalutara",
  9435 => "Kegalle",
  9436 => "Avissawella\,\ Colombo",
  9437 => "Kurunegala",
  9438 => "Panadura\,\ Kalutara",
  9441 => "Matara",
  9445 => "Ratnapura",
  9447 => "Hambantota",
  9451 => "Hatton\,\ Nuwara\ Eliya",
  9452 => "Nuwara\ Eliya",
  9454 => "Nawalapitiya\,\ Kandy",
  9455 => "Badulla",
  9457 => "Bandarawela\,\ Badulla",
  9463 => "Ampara",
  9465 => "Batticaloa",
  9466 => "Matale",
  9467 => "Kalmunai\,\ Ampara",
  9481 => "Kandy",
  9491 => "Galle",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+94|\D)//g;
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