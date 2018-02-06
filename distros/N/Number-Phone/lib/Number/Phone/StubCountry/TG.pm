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
package Number::Phone::StubCountry::TG;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180203200236;

my $formatters = [
                {
                  'leading_digits' => '[279]',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})',
                  'format' => '$1 $2 $3 $4'
                }
              ];

my $validators = {
                'pager' => '',
                'voip' => '',
                'personal_number' => '',
                'mobile' => '
          (?:
            70|
            9[0-36-9]
          )\\d{6}
        ',
                'toll_free' => '',
                'specialrate' => '',
                'fixed_line' => '
          2(?:
            2[2-7]|
            3[23]|
            44|
            55|
            66|
            77
          )\\d{5}
        ',
                'geographic' => '
          2(?:
            2[2-7]|
            3[23]|
            44|
            55|
            66|
            77
          )\\d{5}
        '
              };
my %areanames = (
  22822 => "Lome",
  22823 => "Maritime\ region",
  22824 => "Plateaux\ region",
  22825 => "Central\ region",
  22826 => "Kara\ region",
  22827 => "Savannah\ region",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+228|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  return $self->is_valid() ? $self : undef;
}
1;