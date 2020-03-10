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
package Number::Phone::StubCountry::MZ;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200309202347;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            2|
            8[2-7]
          ',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '8',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2(?:
            [1346]\\d|
            5[0-2]|
            [78][12]|
            93
          )\\d{5}
        ',
                'geographic' => '
          2(?:
            [1346]\\d|
            5[0-2]|
            [78][12]|
            93
          )\\d{5}
        ',
                'mobile' => '8[2-7]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '800\\d{6}',
                'voip' => ''
              };
my %areanames = ();
$areanames{pt}->{25821} = "Maputo";
$areanames{pt}->{25823} = "Beira";
$areanames{pt}->{25824} = "Quelimane";
$areanames{pt}->{258251} = "Manica";
$areanames{pt}->{258252} = "Tete";
$areanames{pt}->{25826} = "Nampula";
$areanames{pt}->{258271} = "Lichinga";
$areanames{pt}->{258272} = "Pemba";
$areanames{pt}->{258281} = "Chokwé";
$areanames{pt}->{258282} = "Xai\-Xai";
$areanames{pt}->{25829} = "Inhambane";
$areanames{en}->{25821} = "Maputo";
$areanames{en}->{25823} = "Beira";
$areanames{en}->{25824} = "Quelimane";
$areanames{en}->{258251} = "Manica";
$areanames{en}->{258252} = "Tete";
$areanames{en}->{25826} = "Nampula";
$areanames{en}->{258271} = "Lichinga";
$areanames{en}->{258272} = "Pemba";
$areanames{en}->{258281} = "Chokwe";
$areanames{en}->{258282} = "Xai\-Xai";
$areanames{en}->{25829} = "Inhambane";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+258|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;