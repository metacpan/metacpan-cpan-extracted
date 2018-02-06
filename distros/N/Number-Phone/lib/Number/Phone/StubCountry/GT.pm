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
package Number::Phone::StubCountry::GT;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180203200234;

my $formatters = [
                {
                  'pattern' => '(\\d{4})(\\d{4})',
                  'leading_digits' => '[2-7]',
                  'format' => '$1 $2'
                },
                {
                  'leading_digits' => '1',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{4})',
                  'format' => '$1 $2 $3'
                }
              ];

my $validators = {
                'personal_number' => '',
                'mobile' => '[345]\\d{7}',
                'geographic' => '[267][2-9]\\d{6}',
                'specialrate' => '(19\\d{9})',
                'fixed_line' => '[267][2-9]\\d{6}',
                'toll_free' => '18[01]\\d{8}',
                'pager' => '',
                'voip' => ''
              };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+502|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, }, $class);
  return $self->is_valid() ? $self : undef;
}
1;