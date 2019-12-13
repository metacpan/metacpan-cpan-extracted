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
package Number::Phone::StubCountry::BN;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20191211212259;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[2-578]',
                  'pattern' => '(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          22[0-7]\\d{4}|
          (?:
            2[013-9]|
            [34]\\d|
            5[0-25-9]
          )\\d{5}
        ',
                'geographic' => '
          22[0-7]\\d{4}|
          (?:
            2[013-9]|
            [34]\\d|
            5[0-25-9]
          )\\d{5}
        ',
                'mobile' => '
          (?:
            22[89]|
            [78]\\d\\d
          )\\d{4}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => '5[34]\\d{5}'
              };
my %areanames = ();
$areanames{en}->{67320} = "Brunei\ Muara";
$areanames{en}->{67321} = "Brunei\ Muara";
$areanames{en}->{673220} = "Brunei\ Muara";
$areanames{en}->{673221} = "Brunei\ Muara";
$areanames{en}->{673222} = "Brunei\ Muara";
$areanames{en}->{673223} = "Brunei\ Muara";
$areanames{en}->{673224} = "Brunei\ Muara";
$areanames{en}->{673225} = "Brunei\ Muara";
$areanames{en}->{673226} = "Brunei\ Muara";
$areanames{en}->{673227} = "Brunei\ Muara";
$areanames{en}->{67323} = "Brunei\ Muara";
$areanames{en}->{67324} = "Brunei\ Muara";
$areanames{en}->{67325} = "Brunei\ Muara";
$areanames{en}->{67326} = "Brunei\ Muara";
$areanames{en}->{67327} = "Brunei\ Muara";
$areanames{en}->{67328} = "Brunei\ Muara";
$areanames{en}->{67329} = "Brunei\ Muara";
$areanames{en}->{6733} = "Beliat";
$areanames{en}->{6734} = "Tutong";
$areanames{en}->{67350} = "Temburong";
$areanames{en}->{67351} = "Temburong";
$areanames{en}->{67352} = "Temburong";
$areanames{en}->{67355} = "Temburong";
$areanames{en}->{67356} = "Temburong";
$areanames{en}->{67357} = "Temburong";
$areanames{en}->{67358} = "Temburong";
$areanames{en}->{67359} = "Temburong";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+673|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;