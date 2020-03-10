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
package Number::Phone::StubCountry::GN;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200309202346;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '3',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[67]',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          3(?:
            0(?:
              24|
              3[12]|
              4[1-35-7]|
              5[13]|
              6[189]|
              [78]1|
              9[1478]
            )|
            1\\d\\d
          )\\d{4}
        ',
                'geographic' => '
          3(?:
            0(?:
              24|
              3[12]|
              4[1-35-7]|
              5[13]|
              6[189]|
              [78]1|
              9[1478]
            )|
            1\\d\\d
          )\\d{4}
        ',
                'mobile' => '6[02356]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => '722\\d{6}'
              };
my %areanames = ();
$areanames{en}->{224302} = "Fria";
$areanames{en}->{2243031} = "Boké";
$areanames{en}->{2243032} = "Kamsar";
$areanames{en}->{2243041} = "Conakry";
$areanames{en}->{2243042} = "Sangoya";
$areanames{en}->{2243043} = "Conakry";
$areanames{en}->{2243045} = "Conakry";
$areanames{en}->{2243046} = "Boussoura";
$areanames{en}->{2243047} = "Conakry";
$areanames{en}->{2243051} = "Labé";
$areanames{en}->{2243053} = "Pita";
$areanames{en}->{2243061} = "Kindia";
$areanames{en}->{22430613} = "Télimélé";
$areanames{en}->{2243068} = "Mamou";
$areanames{en}->{2243069} = "Dalaba";
$areanames{en}->{224307} = "Kankan";
$areanames{en}->{224308} = "Faranah";
$areanames{en}->{2243091} = "N\'Zérékoré";
$areanames{en}->{2243094} = "Macenta";
$areanames{en}->{2243097} = "Guéckédou";
$areanames{en}->{2243098} = "Kissidougou";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+224|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;