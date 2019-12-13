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
our $VERSION = 1.20191211212302;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '7',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[1-689]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            [189]1|
            2[13-7]|
            3[1-8]|
            4[157]|
            5[12457]|
            6[35-7]
          )[2-57]\\d{6}
        ',
                'geographic' => '
          (?:
            [189]1|
            2[13-7]|
            3[1-8]|
            4[157]|
            5[12457]|
            6[35-7]
          )[2-57]\\d{6}
        ',
                'mobile' => '7[0-25-8]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(1973\\d{5})',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{9411} = "Colombo";
$areanames{en}->{9421} = "Jaffna";
$areanames{en}->{9423} = "Mannar";
$areanames{en}->{9424} = "Vavuniya";
$areanames{en}->{9425} = "Anuradhapura";
$areanames{en}->{9426} = "Trincomalee";
$areanames{en}->{9427} = "Polonnaruwa";
$areanames{en}->{9431} = "Negombo\,\ Gampaha";
$areanames{en}->{9432} = "Chilaw\,\ Puttalam";
$areanames{en}->{9433} = "Gampaha";
$areanames{en}->{9434} = "Kalutara";
$areanames{en}->{9435} = "Kegalle";
$areanames{en}->{9436} = "Avissawella\,\ Colombo";
$areanames{en}->{9437} = "Kurunegala";
$areanames{en}->{9438} = "Panadura\,\ Kalutara";
$areanames{en}->{9441} = "Matara";
$areanames{en}->{9445} = "Ratnapura";
$areanames{en}->{9447} = "Hambantota";
$areanames{en}->{9451} = "Hatton\,\ Nuwara\ Eliya";
$areanames{en}->{9452} = "Nuwara\ Eliya";
$areanames{en}->{9454} = "Nawalapitiya\,\ Kandy";
$areanames{en}->{9455} = "Badulla";
$areanames{en}->{9457} = "Bandarawela\,\ Badulla";
$areanames{en}->{9463} = "Ampara";
$areanames{en}->{9465} = "Batticaloa";
$areanames{en}->{9466} = "Matale";
$areanames{en}->{9467} = "Kalmunai\,\ Ampara";
$areanames{en}->{948} = "Kandy";
$areanames{en}->{949} = "Galle";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+94|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;