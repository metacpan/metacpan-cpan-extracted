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
package Number::Phone::StubCountry::KM;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200427120030;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[3478]',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '7[4-7]\\d{5}',
                'geographic' => '7[4-7]\\d{5}',
                'mobile' => '[34]\\d{6}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(8\\d{6})',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{fr}->{269760} = "Domoni";
$areanames{fr}->{269761} = "Mutsamudu";
$areanames{fr}->{269762} = "Mohéli";
$areanames{fr}->{269763} = "Moroni";
$areanames{fr}->{269767} = "Mbéni";
$areanames{fr}->{269768} = "Mitsamiouli";
$areanames{fr}->{269769} = "Foumbouni";
$areanames{fr}->{269770} = "Domoni";
$areanames{fr}->{269771} = "Mutsamudu";
$areanames{fr}->{269772} = "Mohéli";
$areanames{fr}->{269773} = "Moroni";
$areanames{fr}->{269774} = "Moroni";
$areanames{fr}->{269775} = "Moroni";
$areanames{fr}->{269777} = "Mbéni";
$areanames{fr}->{269778} = "Mitsamiouli";
$areanames{fr}->{269779} = "Foumbouni";
$areanames{en}->{269760} = "Domoni";
$areanames{en}->{269761} = "Mutsamudu";
$areanames{en}->{269762} = "Mohéli";
$areanames{en}->{269763} = "Moroni";
$areanames{en}->{269767} = "Mbéni";
$areanames{en}->{269768} = "Mitsamiouli";
$areanames{en}->{269769} = "Foumbouni";
$areanames{en}->{269770} = "Domoni";
$areanames{en}->{269771} = "Mutsamudu";
$areanames{en}->{269772} = "Mohéli";
$areanames{en}->{269773} = "Moroni";
$areanames{en}->{269774} = "Moroni";
$areanames{en}->{269775} = "Moroni";
$areanames{en}->{269777} = "Mbéni";
$areanames{en}->{269778} = "Mitsamiouli";
$areanames{en}->{269779} = "Foumbouni";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+269|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;