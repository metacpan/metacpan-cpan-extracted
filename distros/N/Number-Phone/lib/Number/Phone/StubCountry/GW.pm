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
package Number::Phone::StubCountry::GW;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190912215426;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '40',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[49]',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '443\\d{6}',
                'geographic' => '443\\d{6}',
                'mobile' => '
          9(?:
            5\\d|
            6[569]|
            77
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => '40\\d{5}'
              };
my %areanames = ();
$areanames{pt}->{245320} = "Bissau";
$areanames{pt}->{245321} = "Bissau";
$areanames{pt}->{245322} = "Sta\.\ Luzia";
$areanames{pt}->{245325} = "Brá";
$areanames{pt}->{245331} = "Mansôa";
$areanames{pt}->{245332} = "Bigene\/Bissorã";
$areanames{pt}->{245334} = "Mansaba";
$areanames{pt}->{245335} = "Farim";
$areanames{pt}->{245341} = "Bafatá";
$areanames{pt}->{245342} = "Bambadinca";
$areanames{pt}->{245351} = "Gabú";
$areanames{pt}->{245352} = "Sonaco";
$areanames{pt}->{245353} = "Pirada";
$areanames{pt}->{245354} = "Pitche";
$areanames{pt}->{245370} = "Buba";
$areanames{pt}->{245391} = "Canchungo";
$areanames{pt}->{245392} = "Cacheu";
$areanames{pt}->{245393} = "S\.\ Domingos";
$areanames{pt}->{245394} = "Bula";
$areanames{pt}->{245396} = "Ingoré";
$areanames{en}->{24544320} = "Bissau";
$areanames{en}->{24544321} = "Bissau";
$areanames{en}->{24544322} = "St\.\ Luzia";
$areanames{en}->{24544325} = "Brá";
$areanames{en}->{24544331} = "Mansôa";
$areanames{en}->{24544332} = "Bissora";
$areanames{en}->{24544334} = "Mansaba";
$areanames{en}->{24544335} = "Farim";
$areanames{en}->{24544341} = "Bafatá";
$areanames{en}->{24544342} = "Bambadinca";
$areanames{en}->{24544351} = "Gabu";
$areanames{en}->{24544352} = "Sonaco";
$areanames{en}->{24544353} = "Pirada";
$areanames{en}->{24544354} = "Pitche";
$areanames{en}->{24544370} = "Buba";
$areanames{en}->{24544391} = "Canchungo";
$areanames{en}->{24544392} = "Cacheu";
$areanames{en}->{24544393} = "S\.\ Domingos";
$areanames{en}->{24544394} = "Bula";
$areanames{en}->{24544396} = "Ingoré";
$areanames{en}->{24544397} = "Bigene";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+245|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;