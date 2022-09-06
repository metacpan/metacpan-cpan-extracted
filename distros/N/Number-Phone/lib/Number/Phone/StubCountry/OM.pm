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
our $VERSION = 1.20220903144942;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[58]',
                  'pattern' => '(\\d{3})(\\d{4,6})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '2',
                  'pattern' => '(\\d{2})(\\d{6})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[179]',
                  'pattern' => '(\\d{4})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '2[2-6]\\d{6}',
                'geographic' => '2[2-6]\\d{6}',
                'mobile' => '
          1505\\d{4}|
          (?:
            7(?:
              [1289]\\d|
              7[0-4]
            )|
            9(?:
              0[1-9]|
              [1-9]\\d
            )
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(900\\d{5})',
                'toll_free' => '
          8007\\d{4,5}|
          (?:
            500|
            800[05]
          )\\d{4}
        ',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"96823", "Dhofar\ \&\ Al\ Wusta",
"96826", "Al\ Batinah\ \&\ Musandam",
"96824", "Muscat",
"96825", "A\’Dakhliyah\,\ Al\ Sharqiya\ \&\ A\’Dhahira",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+968|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;