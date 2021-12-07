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
package Number::Phone::StubCountry::WS;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20211206222447;

my $formatters = [
                {
                  'format' => '$1',
                  'leading_digits' => '
            [2-5]|
            6[1-9]
          ',
                  'pattern' => '(\\d{5})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[68]',
                  'pattern' => '(\\d{3})(\\d{3,7})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '7',
                  'pattern' => '(\\d{2})(\\d{5})'
                }
              ];

my $validators = {
                'fixed_line' => '
          6[1-9]\\d{3}|
          (?:
            [2-5]|
            60
          )\\d{4}
        ',
                'geographic' => '
          6[1-9]\\d{3}|
          (?:
            [2-5]|
            60
          )\\d{4}
        ',
                'mobile' => '
          (?:
            7[1-35-7]|
            8(?:
              [3-7]|
              9\\d{3}
            )
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '800\\d{3}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"68564", "Apia",
"6854", "Upolu\ Rural",
"6853", "Apia",
"68563", "Apia",
"68562", "Apia",
"68568", "Apia",
"6852", "Apia",
"68561", "Apia",
"68565", "Apia",
"68566", "Apia",
"6855", "Savaii",
"68569", "Apia",
"68567", "Apia",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+685|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;