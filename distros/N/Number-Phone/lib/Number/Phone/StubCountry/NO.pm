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
package Number::Phone::StubCountry::NO;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190303205540;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[489]',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{3})'
                },
                {
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})',
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[235-7]'
                }
              ];

my $validators = {
                'mobile' => '
          (?:
            4[015-8]|
            5[89]|
            9\\d
          )\\d{6}
        ',
                'geographic' => '
          (?:
            2[1-4]|
            3[1-3578]|
            5[1-35-7]|
            6[1-4679]|
            7[0-8]
          )\\d{6}
        ',
                'pager' => '',
                'voip' => '85[0-5]\\d{5}',
                'specialrate' => '(
          810(?:
            0[0-6]|
            [2-8]\\d
          )\\d{3}
        )|(82[09]\\d{5})|(
          8100[7-9]\\d{3}|
          (?:
            0|
            81(?:
              01|
              5\\d
            )
          )\\d{4}
        )',
                'fixed_line' => '
          (?:
            2[1-4]|
            3[1-3578]|
            5[1-35-7]|
            6[1-4679]|
            7[0-8]
          )\\d{6}
        ',
                'personal_number' => '880\\d{5}',
                'toll_free' => '80[01]\\d{5}'
              };
my %areanames = (
  472 => "Oslo",
  4731 => "Buskerud",
  4732 => "Buskerud",
  4733 => "Vestfold",
  4735 => "Telemark",
  4737 => "Aust\-Agder",
  4738 => "Vest\-Agder",
  4751 => "Rogaland",
  4752 => "Rogaland",
  4753 => "Hordaland",
  4755 => "Hordaland",
  4756 => "Hordaland",
  4757 => "Sogn\ og\ Fjordane",
  4761 => "Oppland",
  4762 => "Hedmark",
  4763 => "Akershus",
  4764 => "Akershus",
  4766 => "Akershus",
  4767 => "Akershus",
  4769 => "Østfold",
  4770 => "Møre\ og\ Romsdal",
  4771 => "Møre\ og\ Romsdal",
  4772 => "Sør\-Trøndelag",
  4773 => "Sør\-Trøndelag",
  4774 => "Nord\-Trøndelag",
  4775 => "Nordland",
  4776 => "Nordland",
  4777 => "Troms",
  4778 => "Finnmark",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+47|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;