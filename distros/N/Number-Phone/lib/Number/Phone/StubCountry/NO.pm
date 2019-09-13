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
our $VERSION = 1.20190912215427;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[489]',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[235-7]',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2[1-4]|
            3[1-3578]|
            5[1-35-7]|
            6[1-4679]|
            7[0-8]
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
                'mobile' => '
          (?:
            4[015-8]|
            5[89]|
            9\\d
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '880\\d{5}',
                'specialrate' => '(
          810(?:
            0[0-6]|
            [2-8]\\d
          )\\d{3}
        )|(82[09]\\d{5})|(
          (?:
            0[2-9]|
            81(?:
              0(?:
                0[7-9]|
                1\\d
              )|
              5\\d\\d
            )
          )\\d{3}
        )',
                'toll_free' => '80[01]\\d{5}',
                'voip' => '85[0-5]\\d{5}'
              };
my %areanames = ();
$areanames{en}->{472} = "Oslo";
$areanames{en}->{4731} = "Buskerud";
$areanames{en}->{4732} = "Buskerud";
$areanames{en}->{4733} = "Vestfold";
$areanames{en}->{4735} = "Telemark";
$areanames{en}->{4737} = "Aust\-Agder";
$areanames{en}->{4738} = "Vest\-Agder";
$areanames{en}->{4751} = "Rogaland";
$areanames{en}->{4752} = "Rogaland";
$areanames{en}->{4753} = "Hordaland";
$areanames{en}->{4755} = "Hordaland";
$areanames{en}->{4756} = "Hordaland";
$areanames{en}->{4757} = "Sogn\ og\ Fjordane";
$areanames{en}->{4761} = "Oppland";
$areanames{en}->{4762} = "Hedmark";
$areanames{en}->{4763} = "Akershus";
$areanames{en}->{4764} = "Akershus";
$areanames{en}->{4766} = "Akershus";
$areanames{en}->{4767} = "Akershus";
$areanames{en}->{4769} = "Østfold";
$areanames{en}->{4770} = "Møre\ og\ Romsdal";
$areanames{en}->{4771} = "Møre\ og\ Romsdal";
$areanames{en}->{4772} = "Sør\-Trøndelag";
$areanames{en}->{4773} = "Sør\-Trøndelag";
$areanames{en}->{4774} = "Nord\-Trøndelag";
$areanames{en}->{4775} = "Nordland";
$areanames{en}->{4776} = "Nordland";
$areanames{en}->{4777} = "Troms";
$areanames{en}->{4778} = "Finnmark";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+47|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;