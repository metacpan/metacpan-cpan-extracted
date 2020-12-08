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
our $VERSION = 1.20201204215956;

my $formatters = [
                {
                  'format' => '$1',
                  'intl_format' => 'NA',
                  'leading_digits' => '75[12]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{5})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            [2568][1-8]|
            3(?:
              0[1-9]|
              [1-9]
            )|
            9
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{4,9})'
                },
                {
                  'format' => '$1',
                  'intl_format' => 'NA',
                  'leading_digits' => '11',
                  'pattern' => '(\\d{6})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            [12]00|
            [368]|
            70[07-9]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3,7})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            [1245]|
            7[135]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{4,8})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '7',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{6,10})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            1[3-79][1-8]|
            [235689][1-8]\\d
          )\\d{2,6}
        ',
                'geographic' => '
          (?:
            1[3-79][1-8]|
            [235689][1-8]\\d
          )\\d{2,6}
        ',
                'mobile' => '
          (?:
            4[0-8]|
            50
          )\\d{4,8}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '([67]00\\d{5,6})|(
          20\\d{4,8}|
          60[12]\\d{5,6}|
          7(?:
            099\\d{4,5}|
            5[03-9]\\d{3,7}
          )|
          20[2-59]\\d\\d|
          (?:
            606|
            7(?:
              0[78]|
              1|
              3\\d
            )
          )\\d{7}|
          (?:
            10|
            29|
            3[09]|
            70[1-5]\\d
          )\\d{4,8}
        )',
                'toll_free' => '800\\d{4,6}',
                'voip' => ''
              };
my %areanames = ();
$areanames{sv} = {"35832", "Tavastland",
"35867", "Vasa",
"35886", "Uleåborg",
"35826", "Åbo\/Björneborg",
"35852", "Kymmene",
"35838", "Tavastland",
"35887", "Uleåborg",
"35813", "Norra\ Karelen",
"35866", "Vasa",
"35858", "Kymmene",
"35827", "Åbo\/Björneborg",
"35883", "Uleåborg",
"35861", "Vasa",
"35835", "Tavastland",
"35823", "Åbo\/Björneborg",
"35855", "Kymmene",
"35854", "Kymmene",
"35816", "Lappland",
"35881", "Uleåborg",
"35863", "Vasa",
"35821", "Åbo\/Björneborg",
"35834", "Tavastland",
"35868", "Vasa",
"35856", "Kymmene",
"35819", "Nyland",
"35882", "Uleåborg",
"35836", "Tavastland",
"35814", "Mellersta\ Finland",
"3589", "Helsingfors",
"35822", "Åbo\/Björneborg",
"35837", "Tavastland",
"35862", "Vasa",
"35815", "St\ Michel",
"35857", "Kymmene",
"35888", "Uleåborg",
"35828", "Åbo\/Björneborg",
"35853", "Kymmene",
"35833", "Tavastland",
"35825", "Åbo\/Björneborg",
"35885", "Uleåborg",
"35864", "Vasa",
"35824", "Åbo\/Björneborg",
"35831", "Tavastland",
"35865", "Vasa",
"35884", "Uleåborg",
"35851", "Kymmene",};
$areanames{fi} = {"35813", "Pohjois\-Karjala",
"35816", "Lappi",
"35814", "Keski\-Suomi",};
$areanames{en} = {"35885", "Oulu",
"35864", "Vaasa",
"35825", "Turku\/Pori",
"35833", "Häme",
"35853", "Kymi",
"35851", "Kymi",
"35865", "Vaasa",
"35884", "Oulu",
"35824", "Turku\/Pori",
"35831", "Häme",
"35814", "Central\ Finland",
"35822", "Turku\/Pori",
"3589", "Helsinki",
"35882", "Oulu",
"35836", "Häme",
"35868", "Vaasa",
"35856", "Kymi",
"35819", "Uusimaa",
"35828", "Turku\/Pori",
"35857", "Kymi",
"35888", "Oulu",
"35815", "Mikkeli",
"35837", "Häme",
"35862", "Vaasa",
"35855", "Kymi",
"35835", "Häme",
"35823", "Turku\/Pori",
"35861", "Vaasa",
"35883", "Oulu",
"35817", "Kuopio",
"35821", "Turku\/Pori",
"35834", "Häme",
"35816", "Lapland",
"35881", "Oulu",
"35863", "Vaasa",
"35854", "Kymi",
"35852", "Kymi",
"35826", "Turku\/Pori",
"35832", "Häme",
"35867", "Vaasa",
"35886", "Oulu",
"35827", "Turku\/Pori",
"35887", "Oulu",
"35813", "North\ Karelia",
"35866", "Vaasa",
"35858", "Kymi",
"35838", "Häme",};

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