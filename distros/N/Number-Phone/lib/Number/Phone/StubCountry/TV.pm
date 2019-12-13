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
our $VERSION = 1.20191211212303;

my $formatters = [];

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
$areanames{en}->{68820} = "Funafuti";
$areanames{en}->{68822} = "Niulakita";
$areanames{en}->{68823} = "Nui";
$areanames{en}->{68824} = "Nukufetau";
$areanames{en}->{68825} = "Nukulaelae";
$areanames{en}->{68826} = "Nanumea";
$areanames{en}->{68827} = "Nanumaga";
$areanames{en}->{68828} = "Niutao";
$areanames{en}->{68829} = "Vaitupu";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+688|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;