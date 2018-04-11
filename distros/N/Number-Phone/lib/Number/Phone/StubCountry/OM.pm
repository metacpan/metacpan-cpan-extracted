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
package Number::Phone::StubCountry::OM;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180410221547;

my $formatters = [
                {
                  'leading_digits' => '2',
                  'format' => '$1 $2',
                  'pattern' => '(2\\d)(\\d{6})'
                },
                {
                  'pattern' => '([79]\\d{3})(\\d{4})',
                  'leading_digits' => '[79]',
                  'format' => '$1 $2'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[58]00',
                  'pattern' => '([58]00)(\\d{4,6})'
                }
              ];

my $validators = {
                'pager' => '',
                'personal_number' => '',
                'geographic' => '2[2-6]\\d{6}',
                'mobile' => '
          7[19]\\d{6}|
          9(?:
            0[1-9]|
            [1-9]\\d
          )\\d{5}
        ',
                'specialrate' => '(900\\d{5})',
                'voip' => '',
                'fixed_line' => '2[2-6]\\d{6}',
                'toll_free' => '
          8007\\d{4,5}|
          500\\d{4}
        '
              };
my %areanames = (
  96823 => "Dhofar\ \&\ Al\ Wusta",
  96824 => "Muscat",
  96825 => "A\’Dakhliyah\,\ Al\ Sharqiya\ \&\ A\’Dhahira",
  96826 => "Al\ Batinah\ \&\ Musandam",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+968|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;