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
package Number::Phone::StubCountry::BZ;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170908113147;

my $formatters = [
                {
                  'leading_digits' => '[2-8]',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '(0)(800)(\\d{4})(\\d{3})',
                  'leading_digits' => '0'
                }
              ];

my $validators = {
                'pager' => '',
                'personal_number' => '',
                'geographic' => '
          (?:
            2(?:
              [02]\\d|
              36
            )|
            [3-58][02]\\d|
            7(?:
              [02]\\d|
              32
            )
          )\\d{4}
        ',
                'voip' => '',
                'fixed_line' => '
          (?:
            2(?:
              [02]\\d|
              36
            )|
            [3-58][02]\\d|
            7(?:
              [02]\\d|
              32
            )
          )\\d{4}
        ',
                'specialrate' => '',
                'mobile' => '6[0-35-7]\\d{5}',
                'toll_free' => '0800\\d{7}'
              };
my %areanames = (
  5012 => "Belize\ District",
  5013 => "Orange\ Walk\ District",
  5014 => "Corozal\ District",
  5015 => "Stann\ Creek\ District",
  5017 => "Toledo\ District",
  5018 => "Cayo\ District",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+501|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  return $self->is_valid() ? $self : undef;
}
1;