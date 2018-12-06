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
package Number::Phone::StubCountry::AX;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20181205223702;

my $formatters = [];

my $validators = {
                'geographic' => '18[1-8]\\d{3,6}',
                'toll_free' => '800\\d{4,6}',
                'personal_number' => '',
                'specialrate' => '([67]00\\d{5,6})|(
          (?:
            10|
            [23][09]
          )\\d{4,8}|
          60(?:
            [12]\\d{5,6}|
            6\\d{7}
          )|
          7(?:
            (?:
              1|
              3\\d
            )\\d{7}|
            5[03-9]\\d{3,7}
          )|
          20[2-59]\\d\\d
        )',
                'fixed_line' => '18[1-8]\\d{3,6}',
                'mobile' => '
          (?:
            4[0-8]|
            50
          )\\d{4,8}
        ',
                'pager' => '',
                'voip' => ''
              };
my %areanames = (
  35813 => "North\ Karelia",
  35814 => "Central\ Finland",
  35815 => "Mikkeli",
  35816 => "Lapland",
  35817 => "Kuopio",
  35819 => "Uusimaa",
  35821 => "Turku\/Pori",
  35822 => "Turku\/Pori",
  35823 => "Turku\/Pori",
  35824 => "Turku\/Pori",
  35825 => "Turku\/Pori",
  35826 => "Turku\/Pori",
  35827 => "Turku\/Pori",
  35828 => "Turku\/Pori",
  35831 => "Häme",
  35832 => "Häme",
  35833 => "Häme",
  35834 => "Häme",
  35835 => "Häme",
  35836 => "Häme",
  35837 => "Häme",
  35838 => "Häme",
  35851 => "Kymi",
  35852 => "Kymi",
  35853 => "Kymi",
  35854 => "Kymi",
  35855 => "Kymi",
  35856 => "Kymi",
  35857 => "Kymi",
  35858 => "Kymi",
  35861 => "Vaasa",
  35862 => "Vaasa",
  35863 => "Vaasa",
  35864 => "Vaasa",
  35865 => "Vaasa",
  35866 => "Vaasa",
  35867 => "Vaasa",
  35868 => "Vaasa",
  35881 => "Oulu",
  35882 => "Oulu",
  35883 => "Oulu",
  35884 => "Oulu",
  35885 => "Oulu",
  35886 => "Oulu",
  35887 => "Oulu",
  35888 => "Oulu",
  3589 => "Helsinki",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+358|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;