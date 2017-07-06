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
our $VERSION = 1.20170702164947;

my $formatters = [
                {
                  'leading_digits' => '
            (?:
              [16-8]0|
              300
            )
          ',
                  'pattern' => '(\\d{3})(\\d{3,7})'
                },
                {
                  'pattern' => '(116\\d{3})',
                  'leading_digits' => '116'
                },
                {
                  'leading_digits' => '
            1[3-9]|
            2[09]|
            4|
            50|
            7(?:
              [13]|
              5[03-9]
            )
          ',
                  'pattern' => '(\\d{2})(\\d{3,9})'
                },
                {
                  'leading_digits' => '75[12]',
                  'pattern' => '(75\\d{3})'
                },
                {
                  'pattern' => '(\\d)(\\d{5,9})',
                  'leading_digits' => '
            [25689][1-8]|
            3(?:
              0[1-9]|
              [1-8]
            )
          '
                },
                {
                  'leading_digits' => '39',
                  'pattern' => '(39\\d)(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          1[3-79][1-8]\\d{4,6}|
          [235689][1-8]\\d{5,7}
        ',
                'mobile' => '
          4(?:
            [0-8]\\d{6,8}|
            9\\d{9}
          )|
          50\\d{4,8}
        ',
                'toll_free' => '800\\d{5,6}',
                'pager' => '',
                'voip' => '',
                'personal_number' => '',
                'specialrate' => '([67]00\\d{5,6})|(
          10(?:
            0\\d{4,6}|
            [1-9]\\d{5,7}
          )|
          2(?:
            0(?:
              0\\d{4,6}|
              [13-8]\\d{5,7}|
              2(?:
                [023]\\d{4,5}|
                [14-9]\\d{4,6}
              )|
              9(?:
                [0-7]\\d{4,6}|
                [89]\\d{1,6}
              )
            )|
            9\\d{6,8}
          )|
          3(?:
            0(?:
              0\\d{3,7}|
              [1-57-9]\\d{5,7}|
              6(?:
                \\d{3}|
                \\d{5,7}
              )
            )|
            93\\d{5,7}
          )|
          60(?:
            [12]\\d{5,6}|
            6\\d{7}
          )|
          7(?:
            1\\d{7}|
            3\\d{8}|
            5[03-9]\\d{5,6}
          )
        )',
                'geographic' => '
          1[3-79][1-8]\\d{4,6}|
          [235689][1-8]\\d{5,7}
        '
              };
my %areanames = (
  35813 => "North\ Karelia",
  35814 => "Central\ Finland",
  35815 => "Mikkeli",
  35816 => "Lapland",
  35817 => "Kuopio",
  35818 => "Åland\ Islands",
  35819 => "Nylandia",
  35821 => "Turku\/Pori",
  35822 => "Turku\/Pori",
  35823 => "Turku\/Pori",
  35824 => "Turku\/Pori",
  35825 => "Turku\/Pori",
  35826 => "Turku\/Pori",
  35827 => "Turku\/Pori",
  35828 => "Turku\/Pori",
  35831 => "Tavastia",
  35832 => "Tavastia",
  35833 => "Tavastia",
  35834 => "Tavastia",
  35835 => "Tavastia",
  35836 => "Tavastia",
  35837 => "Tavastia",
  35838 => "Tavastia",
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
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
    return $self->is_valid() ? $self : undef;
}
1;