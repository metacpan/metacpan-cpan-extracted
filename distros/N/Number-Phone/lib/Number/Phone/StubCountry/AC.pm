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
package Number::Phone::StubCountry::AC;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20220307120107;

my $formatters = [];

my $validators = {
                'fixed_line' => '6[2-467]\\d{3}',
                'geographic' => '6[2-467]\\d{3}',
                'mobile' => '4\\d{4}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(
          (?:
            0[1-9]|
            [1589]\\d
          )\\d{4}
        )',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"24762", "US\ Base",
"24763", "Travellers\ Hill\ \&\ Airhead",
"24767", "Georgetown",
"24766", "Georgetown",
"24764", "Two\ Boats",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+247|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;