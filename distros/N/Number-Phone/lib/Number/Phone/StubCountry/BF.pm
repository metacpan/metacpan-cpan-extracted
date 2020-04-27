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
package Number::Phone::StubCountry::BF;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200427120027;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[025-7]',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2(?:
            0(?:
              49|
              5[23]|
              6[56]|
              9[016-9]
            )|
            4(?:
              4[569]|
              5[4-6]|
              6[56]|
              7[0179]
            )|
            5(?:
              [34]\\d|
              50|
              6[5-7]
            )
          )\\d{4}
        ',
                'geographic' => '
          2(?:
            0(?:
              49|
              5[23]|
              6[56]|
              9[016-9]
            )|
            4(?:
              4[569]|
              5[4-6]|
              6[56]|
              7[0179]
            )|
            5(?:
              [34]\\d|
              50|
              6[5-7]
            )
          )\\d{4}
        ',
                'mobile' => '
          (?:
            0[127]|
            5[1-8]|
            [67]\\d
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{226204} = "Kaya";
$areanames{en}->{2262052} = "Dédougou";
$areanames{en}->{2262053} = "Boromo\/Djibasso\/Nouna";
$areanames{en}->{2262090} = "Gaoua";
$areanames{en}->{2262091} = "Banfora";
$areanames{en}->{2262096} = "Orodara";
$areanames{en}->{2262097} = "Bobo\-Dioulasso";
$areanames{en}->{2262098} = "Bobo\-Dioulasso";
$areanames{en}->{2262099} = "Béréba\/Fo\/Houndé";
$areanames{en}->{2262445} = "Kaya";
$areanames{en}->{2262446} = "Falagountou\/Dori";
$areanames{en}->{2262449} = "Falagountou\/Dori";
$areanames{en}->{2262454} = "Yako";
$areanames{en}->{2262455} = "Ouahigouya";
$areanames{en}->{2262456} = "Djibo";
$areanames{en}->{2262470} = "Pouytenga\/Koupéla";
$areanames{en}->{2262471} = "Tenkodogo";
$areanames{en}->{2262477} = "Fada\/Diabo";
$areanames{en}->{2262479} = "Kantchari";
$areanames{en}->{226253} = "Ouagadougou";
$areanames{en}->{226254} = "Ouagadougou";
$areanames{en}->{2262540} = "Pô\/Kombissiri\/Koubri";
$areanames{en}->{2262541} = "Léo\/Sapouy";
$areanames{en}->{2262544} = "Koudougou";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+226|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;