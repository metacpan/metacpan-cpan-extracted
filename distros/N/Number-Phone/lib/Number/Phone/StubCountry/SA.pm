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
package Number::Phone::StubCountry::SA;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180203200236;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'pattern' => '(1\\d)(\\d{3})(\\d{4})',
                  'leading_digits' => '1[1-467]',
                  'national_rule' => '0$1'
                },
                {
                  'format' => '$1 $2 $3',
                  'pattern' => '(5\\d)(\\d{3})(\\d{4})',
                  'leading_digits' => '5',
                  'national_rule' => '0$1'
                },
                {
                  'leading_digits' => '92',
                  'pattern' => '(92\\d{2})(\\d{5})',
                  'format' => '$1 $2',
                  'national_rule' => '$1'
                },
                {
                  'national_rule' => '$1',
                  'pattern' => '(800)(\\d{3})(\\d{4})',
                  'leading_digits' => '800',
                  'format' => '$1 $2 $3'
                },
                {
                  'national_rule' => '0$1',
                  'pattern' => '(811)(\\d{3})(\\d{3,4})',
                  'leading_digits' => '811',
                  'format' => '$1 $2 $3'
                }
              ];

my $validators = {
                'fixed_line' => '
          1(?:
            1\\d|
            2[24-8]|
            3[35-8]|
            4[3-68]|
            6[2-5]|
            7[235-7]
          )\\d{6}
        ',
                'specialrate' => '(92[05]\\d{6})',
                'toll_free' => '800\\d{7}',
                'geographic' => '
          1(?:
            1\\d|
            2[24-8]|
            3[35-8]|
            4[3-68]|
            6[2-5]|
            7[235-7]
          )\\d{6}
        ',
                'mobile' => '
          (?:
            5(?:
              [013-689]\\d|
              7[0-36-8]
            )|
            811\\d
          )\\d{6}
        ',
                'personal_number' => '',
                'voip' => '',
                'pager' => ''
              };
my %areanames = (
  96611 => "Riyadh\/Kharj",
  96612 => "Makkah\/Jeddah",
  96613 => "Dammam\/Khobar\/Dahran",
  96614 => "Madenah\/Arar\/Tabuk\/Yanbu",
  96616 => "Hail\/Qasim",
  96617 => "Abha\/Najran\/Jezan",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+966|\D)//g;
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