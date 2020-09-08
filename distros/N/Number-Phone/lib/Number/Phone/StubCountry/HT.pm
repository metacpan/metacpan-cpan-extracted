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
package Number::Phone::StubCountry::HT;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200904144532;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[2-489]',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2(?:
            2\\d|
            5[1-5]|
            81|
            9[149]
          )\\d{5}
        ',
                'geographic' => '
          2(?:
            2\\d|
            5[1-5]|
            81|
            9[149]
          )\\d{5}
        ',
                'mobile' => '[34]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '8\\d{7}',
                'voip' => '
          9(?:
            [67][0-4]|
            8[0-3589]|
            9\\d
          )\\d{5}
        '
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+509|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;