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
package Number::Phone::StubCountry::IO;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180410221546;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'pattern' => '(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'voip' => '',
                'toll_free' => '',
                'fixed_line' => '37\\d{5}',
                'personal_number' => '',
                'pager' => '',
                'specialrate' => '',
                'mobile' => '38\\d{5}',
                'geographic' => '37\\d{5}'
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+246|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;