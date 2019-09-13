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
package Number::Phone::StubCountry::LY;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20190912215427;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'leading_digits' => '[25-79]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{7})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2[13-5]|
            5[1347]|
            6[1-479]|
            71
          )\\d{7}
        ',
                'geographic' => '
          (?:
            2[13-5]|
            5[1347]|
            6[1-479]|
            71
          )\\d{7}
        ',
                'mobile' => '9[1-6]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{21821} = "Tripoli";
$areanames{en}->{21823} = "Zawia";
$areanames{en}->{21824} = "Sabratha";
$areanames{en}->{21825} = "Zuara";
$areanames{en}->{218252} = "Zahra";
$areanames{en}->{21851} = "Misratah";
$areanames{en}->{21854} = "Sirt";
$areanames{en}->{21857} = "Hun";
$areanames{en}->{21861} = "Benghazi";
$areanames{en}->{218623} = "Gmines";
$areanames{en}->{218624} = "Elkuwaifia";
$areanames{en}->{218625} = "Deriana";
$areanames{en}->{218626} = "Kaalifa";
$areanames{en}->{218627} = "Jerdina";
$areanames{en}->{218628} = "Seluk";
$areanames{en}->{218629} = "Elmagrun";
$areanames{en}->{21863} = "Benina";
$areanames{en}->{21867} = "Elmareg";
$areanames{en}->{2187} = "Sebha";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+218|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;