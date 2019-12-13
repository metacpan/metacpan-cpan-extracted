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
package Number::Phone::StubCountry::MR;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20191211212302;

my $formatters = [
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[2-48]',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            25[08]|
            35\\d|
            45[1-7]
          )\\d{5}
        ',
                'geographic' => '
          (?:
            25[08]|
            35\\d|
            45[1-7]
          )\\d{5}
        ',
                'mobile' => '[2-4][0-46-9]\\d{6}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '800\\d{5}',
                'voip' => ''
              };
my %areanames = ();
$areanames{fr}->{22245} = "Nouakchott";
$areanames{fr}->{2224513} = "Néma";
$areanames{fr}->{2224515} = "Aîoun";
$areanames{fr}->{2224533} = "Kaédi";
$areanames{fr}->{2224534} = "Sélibaby";
$areanames{fr}->{2224537} = "Aleg";
$areanames{fr}->{2224544} = "Zouérat";
$areanames{fr}->{2224546} = "Atar";
$areanames{fr}->{2224550} = "Boghé";
$areanames{fr}->{2224563} = "Kiffa";
$areanames{fr}->{2224569} = "Rosso\/Tidjikja";
$areanames{fr}->{2224574} = "Nouadhibou";
$areanames{en}->{22245} = "Nouakchott";
$areanames{en}->{2224513} = "Néma";
$areanames{en}->{2224515} = "Aioun";
$areanames{en}->{2224533} = "Kaédi";
$areanames{en}->{2224534} = "Sélibaby";
$areanames{en}->{2224537} = "Aleg";
$areanames{en}->{2224544} = "Zouérat";
$areanames{en}->{2224546} = "Atar";
$areanames{en}->{2224550} = "Boghé";
$areanames{en}->{2224563} = "Kiffa";
$areanames{en}->{2224569} = "Rosso\/Tidjikja";
$areanames{en}->{2224574} = "Nouadhibou";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+222|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;