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
package Number::Phone::StubCountry::CU;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180619214155;

my $formatters = [
                {
                  'pattern' => '(\\d)(\\d{6,7})',
                  'national_rule' => '(0$1)',
                  'format' => '$1 $2',
                  'leading_digits' => '7'
                },
                {
                  'pattern' => '(\\d{2})(\\d{4,6})',
                  'format' => '$1 $2',
                  'national_rule' => '(0$1)',
                  'leading_digits' => '[2-4]'
                },
                {
                  'pattern' => '(\\d)(\\d{7})',
                  'format' => '$1 $2',
                  'national_rule' => '0$1',
                  'leading_digits' => '5'
                }
              ];

my $validators = {
                'mobile' => '5\\d{7}',
                'specialrate' => '',
                'pager' => '',
                'geographic' => '
          2[1-4]\\d{5,6}|
          3(?:
            1\\d{6}|
            [23]\\d{4,6}
          )|
          4(?:
            [125]\\d{5,6}|
            [36]\\d{6}|
            [78]\\d{4,6}
          )|
          7\\d{6,7}
        ',
                'personal_number' => '',
                'voip' => '',
                'fixed_line' => '
          2[1-4]\\d{5,6}|
          3(?:
            1\\d{6}|
            [23]\\d{4,6}
          )|
          4(?:
            [125]\\d{5,6}|
            [36]\\d{6}|
            [78]\\d{4,6}
          )|
          7\\d{6,7}
        ',
                'toll_free' => ''
              };
my %areanames = (
  5321 => "Guantánamo\ Province",
  5322 => "Santiago\ de\ Cuba\ Province",
  5323 => "Granma\ Province",
  5324 => "Holguín\ Province",
  5331 => "Las\ Tunas\ Province",
  5332 => "Camagüey\ Province",
  5333 => "Ciego\ de\ Ávila\ Province",
  5341 => "Sancti\ Spíritus\ Province",
  5342 => "Villa\ Clara\ Province",
  5343 => "Cienfuegos\ Province",
  5345 => "Matanzas\ Province",
  5346 => "Isle\ of\ Youth",
  5347 => "Havana\ Province",
  5348 => "Pinar\ del\ Río\ Province",
  537 => "Havana\ City",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+53|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;