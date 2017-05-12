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
package Number::Phone::StubCountry::PW;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170314173054;

my $formatters = [
                {
                  'pattern' => '(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2552255|
          (?:
            277|
            345|
            488|
            5(?:
              35|
              44|
              87
            )|
            6(?:
              22|
              54|
              79
            )|
            7(?:
              33|
              47
            )|
            8(?:
              24|
              55|
              76
            )
          )\\d{4}
        ',
                'pager' => '',
                'voip' => '',
                'geographic' => '
          2552255|
          (?:
            277|
            345|
            488|
            5(?:
              35|
              44|
              87
            )|
            6(?:
              22|
              54|
              79
            )|
            7(?:
              33|
              47
            )|
            8(?:
              24|
              55|
              76
            )
          )\\d{4}
        ',
                'personal_number' => '',
                'toll_free' => '',
                'specialrate' => '',
                'mobile' => '
          (?:
            6[234689]0|
            77[45789]
          )\\d{4}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+680|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  return $self->is_valid() ? $self : undef;
}
1;