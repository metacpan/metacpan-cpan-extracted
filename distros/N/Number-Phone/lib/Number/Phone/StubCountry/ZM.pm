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
package Number::Phone::StubCountry::ZM;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190912215428;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'intl_format' => 'NA',
                  'leading_digits' => '[1-9]',
                  'pattern' => '(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[28]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[79]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{7})'
                }
              ];

my $validators = {
                'fixed_line' => '21[1-8]\\d{6}',
                'geographic' => '21[1-8]\\d{6}',
                'mobile' => '
          (?:
            76|
            9[5-8]
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '800\\d{6}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{260211} = "Lusaka\ Province";
$areanames{en}->{260212} = "Ndola\/Copperbelt\ and\ Luapula\ Provinces";
$areanames{en}->{260213} = "Livingstone\/Southern\ Province";
$areanames{en}->{260214} = "Kasama\/Northern\ Province";
$areanames{en}->{260215} = "Kabwe\/Central\ Province";
$areanames{en}->{260216} = "Chipata\/Eastern\ Province";
$areanames{en}->{260217} = "Solwezi\/Western\ Province";
$areanames{en}->{260218} = "Mongu\/North\-Western\ Province";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+260|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;