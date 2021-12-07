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
package Number::Phone::StubCountry::VU;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20211206222447;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[57-9]',
                  'pattern' => '(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            38[0-8]|
            48[4-9]
          )\\d\\d|
          (?:
            2[02-9]|
            3[4-7]|
            88
          )\\d{3}
        ',
                'geographic' => '
          (?:
            38[0-8]|
            48[4-9]
          )\\d\\d|
          (?:
            2[02-9]|
            3[4-7]|
            88
          )\\d{3}
        ',
                'mobile' => '
          (?:
            [58]\\d|
            7[013-7]
          )\\d{5}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(
          (?:
            3[03]|
            900\\d
          )\\d{3}
        )',
                'toll_free' => '',
                'voip' => '
          9(?:
            0[1-9]|
            1[01]
          )\\d{4}
        '
              };
my %areanames = ();
$areanames{en} = {"67828", "Port\ Vila\,\ Shefa",
"67822", "Port\ Vila\,\ Shefa",
"67836", "Sanma",
"67827", "Port\ Vila\,\ Shefa",
"67888", "Tafea",
"67837", "Luganville",
"67823", "Port\ Vila\,\ Shefa",
"67824", "Port\ Vila\,\ Shefa",
"67829", "Port\ Vila\,\ Shefa",
"6784", "Malampa",
"67838", "Penama\/Torba",
"67825", "Port\ Vila\,\ Shefa",
"67826", "Port\ Vila\,\ Shefa",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+678|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;