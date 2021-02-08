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
package Number::Phone::StubCountry::TV;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20210204173827;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '2',
                  'pattern' => '(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '90',
                  'pattern' => '(\\d{2})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '7',
                  'pattern' => '(\\d{2})(\\d{5})'
                }
              ];

my $validators = {
                'fixed_line' => '2[02-9]\\d{3}',
                'geographic' => '2[02-9]\\d{3}',
                'mobile' => '
          (?:
            7[01]\\d|
            90
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"68820", "Funafuti",
"68826", "Nanumea",
"68824", "Nukufetau",
"68825", "Nukulaelae",
"68827", "Nanumaga",
"68829", "Vaitupu",
"68828", "Niutao",
"68823", "Nui",
"68822", "Niulakita",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+688|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;