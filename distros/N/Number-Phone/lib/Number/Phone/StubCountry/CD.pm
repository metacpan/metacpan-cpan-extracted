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
package Number::Phone::StubCountry::CD;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180203200233;

my $formatters = [
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '12',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'pattern' => '([89]\\d{2})(\\d{3})(\\d{3})',
                  'leading_digits' => '
            8[0-2459]|
            9
          ',
                  'national_rule' => '0$1'
                },
                {
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{3})',
                  'leading_digits' => '88',
                  'national_rule' => '0$1'
                },
                {
                  'national_rule' => '0$1',
                  'format' => '$1 $2',
                  'leading_digits' => '[1-6]',
                  'pattern' => '(\\d{2})(\\d{5})'
                }
              ];

my $validators = {
                'pager' => '',
                'voip' => '',
                'mobile' => '
          8(?:
            [0-2459]\\d{2}|
            8
          )\\d{5}|
          9[017-9]\\d{7}
        ',
                'personal_number' => '',
                'geographic' => '
          1(?:
            2\\d{7}|
            \\d{6}
          )|
          [2-6]\\d{6}
        ',
                'specialrate' => '',
                'fixed_line' => '
          1(?:
            2\\d{7}|
            \\d{6}
          )|
          [2-6]\\d{6}
        ',
                'toll_free' => ''
              };
my %areanames = (
  2431 => "Kinshasa",
  2432 => "Katanga",
  2433 => "Bas\-Congo\/Bandundu",
  2434 => "Kasai\-Oriental\/Kasai\-Occidental",
  2435 => "Oriental\ Province\ \(Kisanga\/Mbandaka\)",
  2436 => "North\ Kivu\/South\ Kivu\/Maniema",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+243|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  
      return $self if ($self->is_valid());
      {
        no warnings 'uninitialized';
        $number =~ s/^(?:0)//;
      }
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
    return $self->is_valid() ? $self : undef;
}
1;