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
package Number::Phone::StubCountry::NF;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190303205540;

my $formatters = [
                {
                  'pattern' => '(\\d{2})(\\d{4})',
                  'format' => '$1 $2',
                  'leading_digits' => '1'
                },
                {
                  'pattern' => '(\\d)(\\d{5})',
                  'format' => '$1 $2',
                  'leading_digits' => '3'
                }
              ];

my $validators = {
                'toll_free' => '',
                'personal_number' => '',
                'fixed_line' => '
          (?:
            1(?:
              06|
              17|
              28|
              39
            )|
            3[0-2]\\d
          )\\d{3}
        ',
                'specialrate' => '',
                'voip' => '',
                'geographic' => '
          (?:
            1(?:
              06|
              17|
              28|
              39
            )|
            3[0-2]\\d
          )\\d{3}
        ',
                'pager' => '',
                'mobile' => '3[58]\\d{4}'
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+672|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self if ($self->is_valid());
      my $prefix = qr/^(?:([0-258]\d{4})$)/;
      my @matches = $number =~ /$prefix/;
      if (defined $matches[-1]) {
        no warnings 'uninitialized';
        $number =~ s/$prefix/3$1/;
      }
      else {
        $number =~ s/$prefix//;
      }
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
      return $self->is_valid() ? $self : undef;
    }
1;