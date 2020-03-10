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
package Number::Phone::StubCountry::SK;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200309202348;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '21',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{2})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[3-5][1-8]1[67]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2,3})'
                },
                {
                  'format' => '$1 $2',
                  'intl_format' => 'NA',
                  'leading_digits' => '9090',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{4})(\\d{3})'
                },
                {
                  'format' => '$1/$2 $3 $4',
                  'leading_digits' => '2',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{3})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[689]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1/$2 $3 $4',
                  'leading_digits' => '[3-5]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              16|
              [2-9]\\d{3}
            )|
            (?:
              (?:
                [3-5][1-8]\\d|
                819
              )\\d|
              601[1-5]
            )\\d
          )\\d{4}|
          (?:
            2|
            [3-5][1-8]
          )1[67]\\d{3}|
          [3-5][1-8]16\\d\\d
        ',
                'geographic' => '
          (?:
            2(?:
              16|
              [2-9]\\d{3}
            )|
            (?:
              (?:
                [3-5][1-8]\\d|
                819
              )\\d|
              601[1-5]
            )\\d
          )\\d{4}|
          (?:
            2|
            [3-5][1-8]
          )1[67]\\d{3}|
          [3-5][1-8]16\\d\\d
        ',
                'mobile' => '
          909[1-9]\\d{5}|
          9(?:
            0[1-8]|
            1[0-24-9]|
            4[03-57-9]|
            5\\d
          )\\d{6}
        ',
                'pager' => '9090\\d{3}',
                'personal_number' => '',
                'specialrate' => '(8[5-9]\\d{7})|(
          9(?:
            00|
            [78]\\d
          )\\d{6}
        )|(96\\d{7})',
                'toll_free' => '800\\d{6}',
                'voip' => '
          6(?:
            02|
            5[0-4]|
            9[0-6]
          )\\d{6}
        '
              };
my %areanames = ();
$areanames{en}->{4212} = "Bratislava";
$areanames{en}->{42131} = "Dunajska\ Streda";
$areanames{en}->{42132} = "Trencin";
$areanames{en}->{42133} = "Trnava";
$areanames{en}->{42134} = "Senica";
$areanames{en}->{42135} = "Nove\ Zamky";
$areanames{en}->{42136} = "Levice";
$areanames{en}->{42137} = "Nitra";
$areanames{en}->{42138} = "Topolcany";
$areanames{en}->{42141} = "Zilina";
$areanames{en}->{42142} = "Povazska\ Bystrica";
$areanames{en}->{42143} = "Martin";
$areanames{en}->{42144} = "Liptovsky\ Mikulas";
$areanames{en}->{42145} = "Zvolen";
$areanames{en}->{42146} = "Prievidza";
$areanames{en}->{42147} = "Lucenec";
$areanames{en}->{42148} = "Banska\ Bystrica";
$areanames{en}->{42151} = "Presov";
$areanames{en}->{42152} = "Poprad";
$areanames{en}->{42153} = "Spisska\ Nova\ Ves";
$areanames{en}->{42154} = "Bardejov";
$areanames{en}->{42155} = "Kosice";
$areanames{en}->{42156} = "Michalovce";
$areanames{en}->{42157} = "Humenne";
$areanames{en}->{42158} = "Roznava";
$areanames{en}->{421601} = "Roznava";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+421|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;