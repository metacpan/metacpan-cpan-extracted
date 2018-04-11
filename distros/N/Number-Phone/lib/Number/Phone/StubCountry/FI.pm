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
package Number::Phone::StubCountry::FI;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20180410221546;

my $formatters = [
                {
                  'pattern' => '(\\d{3})(\\d{3,7})',
                  'national_rule' => '0$1',
                  'leading_digits' => '
            (?:
              [1-3]0|
              [6-8]
            )0
          ',
                  'format' => '$1 $2'
                },
                {
                  'pattern' => '(75\\d{3})',
                  'leading_digits' => '75[12]',
                  'national_rule' => '0$1',
                  'format' => '$1'
                },
                {
                  'national_rule' => '$1',
                  'leading_digits' => '116',
                  'format' => '$1',
                  'pattern' => '(116\\d{3})'
                },
                {
                  'pattern' => '(\\d{2})(\\d{4,10})',
                  'format' => '$1 $2',
                  'leading_digits' => '
            [14]|
            2[09]|
            50|
            7[135]
          ',
                  'national_rule' => '0$1'
                },
                {
                  'leading_digits' => '
            [25689][1-8]|
            3
          ',
                  'national_rule' => '0$1',
                  'format' => '$1 $2',
                  'pattern' => '(\\d)(\\d{4,11})'
                }
              ];

my $validators = {
                'geographic' => '
          1(?:
            [3569][1-8]\\d{3,9}|
            [47]\\d{5,10}
          )|
          2[1-8]\\d{3,9}|
          3(?:
            [1-8]\\d{3,9}|
            9\\d{4,8}
          )|
          [5689][1-8]\\d{3,9}
        ',
                'mobile' => '
          4(?:
            [0-8]\\d{4,9}|
            9\\d{3,8}
          )|
          50\\d{4,8}
        ',
                'specialrate' => '([67]00\\d{5,6})|(
          [13]0\\d{4,8}|
          2(?:
            0(?:
              [016-8]\\d{3,7}|
              [2-59]\\d{2,7}
            )|
            9\\d{4,8}
          )|
          60(?:
            [12]\\d{5,6}|
            6\\d{7}
          )|
          7(?:
            1\\d{7}|
            3\\d{8}|
            5[03-9]\\d{3,7}
          )
        )',
                'pager' => '',
                'personal_number' => '',
                'fixed_line' => '
          1(?:
            [3569][1-8]\\d{3,9}|
            [47]\\d{5,10}
          )|
          2[1-8]\\d{3,9}|
          3(?:
            [1-8]\\d{3,9}|
            9\\d{4,8}
          )|
          [5689][1-8]\\d{3,9}
        ',
                'toll_free' => '800\\d{4,7}',
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
  35891 => "Helsinki",
  35892 => "Helsinki",
  35893 => "Helsinki",
  35894 => "Helsinki",
  35895 => "Helsinki",
  35896 => "Helsinki",
  35897 => "Helsinki",
  35898 => "Helsinki",
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