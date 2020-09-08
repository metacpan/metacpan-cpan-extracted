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
package Number::Phone::StubCountry::ML;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200904144534;

my $formatters = [
                {
                  'format' => '$1',
                  'intl_format' => 'NA',
                  'leading_digits' => '
            67(?:
              0[09]|
              [59]9|
              77|
              8[89]
            )|
            74(?:
              0[02]|
              44|
              55
            )
          ',
                  'pattern' => '(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[24-9]',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2(?:
            07[0-8]|
            12[67]
          )\\d{4}|
          (?:
            2(?:
              02|
              1[4-689]
            )|
            4(?:
              0[0-4]|
              4[1-39]
            )
          )\\d{5}
        ',
                'geographic' => '
          2(?:
            07[0-8]|
            12[67]
          )\\d{4}|
          (?:
            2(?:
              02|
              1[4-689]
            )|
            4(?:
              0[0-4]|
              4[1-39]
            )
          )\\d{5}
        ',
                'mobile' => '
          2(?:
            0(?:
              01|
              79
            )|
            17\\d
          )\\d{4}|
          (?:
            5[01]|
            [679]\\d|
            8[239]
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '80\\d{6}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{223202} = "Bamako";
$areanames{en}->{2232070} = "Bamako";
$areanames{en}->{2232071} = "Bamako";
$areanames{en}->{2232072} = "Bamako";
$areanames{en}->{2232073} = "Bamako";
$areanames{en}->{2232074} = "Bamako";
$areanames{en}->{2232075} = "Bamako";
$areanames{en}->{2232076} = "Bamako";
$areanames{en}->{2232077} = "Bamako";
$areanames{en}->{2232078} = "Bamako";
$areanames{en}->{223212} = "Koulikoro";
$areanames{en}->{223214} = "Mopti";
$areanames{en}->{223215} = "Kayes";
$areanames{en}->{223216} = "Sikasso";
$areanames{en}->{223218} = "Gao\/Kidal";
$areanames{en}->{223219} = "Tombouctou";
$areanames{en}->{223442} = "Bamako";
$areanames{en}->{223443} = "Bamako";
$areanames{en}->{223449} = "Bamako";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+223|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;