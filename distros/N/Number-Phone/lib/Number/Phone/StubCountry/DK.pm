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
package Number::Phone::StubCountry::DK;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170908113148;

my $formatters = [
                {
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'specialrate' => '(90\\d{6})',
                'fixed_line' => '
          (?:
            [2-7]\\d|
            8[126-9]|
            9[1-36-9]
          )\\d{6}
        ',
                'toll_free' => '80\\d{6}',
                'mobile' => '
          (?:
            [2-7]\\d|
            8[126-9]|
            9[1-36-9]
          )\\d{6}
        ',
                'voip' => '',
                'geographic' => '
          (?:
            [2-7]\\d|
            8[126-9]|
            9[1-36-9]
          )\\d{6}
        ',
                'personal_number' => '',
                'pager' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+45|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  return $self->is_valid() ? $self : undef;
}
1;