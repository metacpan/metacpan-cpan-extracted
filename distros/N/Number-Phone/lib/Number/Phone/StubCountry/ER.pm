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
package Number::Phone::StubCountry::ER;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20170314173054;

my $formatters = [
                {
                  'pattern' => '(\\d)(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'toll_free' => '',
                'geographic' => '
          1(?:
            1[12568]|
            20|
            40|
            55|
            6[146]
          )\\d{4}|
          8\\d{6}
        ',
                'personal_number' => '',
                'specialrate' => '',
                'mobile' => '
          17[1-3]\\d{4}|
          7\\d{6}
        ',
                'fixed_line' => '
          1(?:
            1[12568]|
            20|
            40|
            55|
            6[146]
          )\\d{4}|
          8\\d{6}
        ',
                'pager' => '',
                'voip' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+291|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
    return $self->is_valid() ? $self : undef;
}
1;