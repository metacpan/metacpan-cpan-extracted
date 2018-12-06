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
our $VERSION = 1.20181205223704;

my $formatters = [
                {
                  'pattern' => '(\\d{2})(\\d{7})',
                  'leading_digits' => '[25-79]',
                  'format' => '$1-$2',
                  'national_rule' => '0$1'
                }
              ];

my $validators = {
                'voip' => '',
                'mobile' => '9[1-6]\\d{7}',
                'pager' => '',
                'fixed_line' => '
          (?:
            2[13-5]|
            5[1347]|
            6[1-479]|
            71
          )\\d{7}
        ',
                'specialrate' => '',
                'personal_number' => '',
                'geographic' => '
          (?:
            2[13-5]|
            5[1347]|
            6[1-479]|
            71
          )\\d{7}
        ',
                'toll_free' => ''
              };
my %areanames = (
  21821 => "Tripoli",
  21823 => "Zawia",
  21824 => "Sabratha",
  21825 => "Zuara",
  218252 => "Zahra",
  21851 => "Misratah",
  21854 => "Sirt",
  21857 => "Hun",
  21861 => "Benghazi",
  218623 => "Gmines",
  218624 => "Elkuwaifia",
  218625 => "Deriana",
  218626 => "Kaalifa",
  218627 => "Jerdina",
  218628 => "Seluk",
  218629 => "Elmagrun",
  21863 => "Benina",
  21867 => "Elmareg",
  2187 => "Sebha",
);
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