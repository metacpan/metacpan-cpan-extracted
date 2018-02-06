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
package Number::Phone::StubCountry::SD;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180203200236;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})',
                  'national_rule' => '0$1'
                }
              ];

my $validators = {
                'mobile' => '9[0-3569]\\d{7}',
                'personal_number' => '',
                'fixed_line' => '
          1(?:
            [125]\\d|
            8[3567]
          )\\d{6}
        ',
                'specialrate' => '',
                'toll_free' => '',
                'geographic' => '
          1(?:
            [125]\\d|
            8[3567]
          )\\d{6}
        ',
                'pager' => '',
                'voip' => ''
              };
my %areanames = (
  24911 => "Omdurman",
  24921 => "Atbara",
  249183 => "Khartoum",
  24931 => "Port\ Sudan",
  24941 => "Kassala",
  249441 => "Jedaraf",
  24951 => "Wadmedai",
  24961 => "Sennar",
  249616 => "Shetnzi",
  24971 => "Kosti",
  24981 => "Al\-Ubayyid",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+249|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  
      return $self if ($self->is_valid());
      {
        no warnings 'uninitialized';
        $number =~ s/^(?:0)//;
      }
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
    return $self->is_valid() ? $self : undef;
}
1;