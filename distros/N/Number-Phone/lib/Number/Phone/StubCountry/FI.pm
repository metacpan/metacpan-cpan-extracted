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
our $VERSION = 1.20190912215425;

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
            (?:
              [12]0|
              7
            )0|
            [368]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3,7})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[12457]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{4,8})'
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
                'toll_free' => '800\\d{4,6}',
                'voip' => ''
              };
my %areanames = ();
$areanames{sv}->{35813} = "Norra\ Karelen";
$areanames{sv}->{35814} = "Mellersta\ Finland";
$areanames{sv}->{35815} = "St\ Michel";
$areanames{sv}->{35816} = "Lappland";
$areanames{sv}->{35817} = "Kuopio";
$areanames{sv}->{35819} = "Nyland";
$areanames{sv}->{35821} = "Åbo\/Björneborg";
$areanames{sv}->{35822} = "Åbo\/Björneborg";
$areanames{sv}->{35823} = "Åbo\/Björneborg";
$areanames{sv}->{35824} = "Åbo\/Björneborg";
$areanames{sv}->{35825} = "Åbo\/Björneborg";
$areanames{sv}->{35826} = "Åbo\/Björneborg";
$areanames{sv}->{35827} = "Åbo\/Björneborg";
$areanames{sv}->{35828} = "Åbo\/Björneborg";
$areanames{sv}->{35831} = "Tavastland";
$areanames{sv}->{35832} = "Tavastland";
$areanames{sv}->{35833} = "Tavastland";
$areanames{sv}->{35834} = "Tavastland";
$areanames{sv}->{35835} = "Tavastland";
$areanames{sv}->{35836} = "Tavastland";
$areanames{sv}->{35837} = "Tavastland";
$areanames{sv}->{35838} = "Tavastland";
$areanames{sv}->{35851} = "Kymmene";
$areanames{sv}->{35852} = "Kymmene";
$areanames{sv}->{35853} = "Kymmene";
$areanames{sv}->{35854} = "Kymmene";
$areanames{sv}->{35855} = "Kymmene";
$areanames{sv}->{35856} = "Kymmene";
$areanames{sv}->{35857} = "Kymmene";
$areanames{sv}->{35858} = "Kymmene";
$areanames{sv}->{35861} = "Vasa";
$areanames{sv}->{35862} = "Vasa";
$areanames{sv}->{35863} = "Vasa";
$areanames{sv}->{35864} = "Vasa";
$areanames{sv}->{35865} = "Vasa";
$areanames{sv}->{35866} = "Vasa";
$areanames{sv}->{35867} = "Vasa";
$areanames{sv}->{35868} = "Vasa";
$areanames{sv}->{35881} = "Uleåborg";
$areanames{sv}->{35882} = "Uleåborg";
$areanames{sv}->{35883} = "Uleåborg";
$areanames{sv}->{35884} = "Uleåborg";
$areanames{sv}->{35885} = "Uleåborg";
$areanames{sv}->{35886} = "Uleåborg";
$areanames{sv}->{35887} = "Uleåborg";
$areanames{sv}->{35888} = "Uleåborg";
$areanames{sv}->{3589} = "Helsingfors";
$areanames{fi}->{35813} = "Pohjois\-Karjala";
$areanames{fi}->{35814} = "Keski\-Suomi";
$areanames{fi}->{35815} = "Mikkeli";
$areanames{fi}->{35816} = "Lappi";
$areanames{fi}->{35817} = "Kuopio";
$areanames{fi}->{35819} = "Uusimaa";
$areanames{fi}->{35821} = "Turku\/Pori";
$areanames{fi}->{35822} = "Turku\/Pori";
$areanames{fi}->{35823} = "Turku\/Pori";
$areanames{fi}->{35824} = "Turku\/Pori";
$areanames{fi}->{35825} = "Turku\/Pori";
$areanames{fi}->{35826} = "Turku\/Pori";
$areanames{fi}->{35827} = "Turku\/Pori";
$areanames{fi}->{35828} = "Turku\/Pori";
$areanames{fi}->{35831} = "Häme";
$areanames{fi}->{35832} = "Häme";
$areanames{fi}->{35833} = "Häme";
$areanames{fi}->{35834} = "Häme";
$areanames{fi}->{35835} = "Häme";
$areanames{fi}->{35836} = "Häme";
$areanames{fi}->{35837} = "Häme";
$areanames{fi}->{35838} = "Häme";
$areanames{fi}->{35851} = "Kymi";
$areanames{fi}->{35852} = "Kymi";
$areanames{fi}->{35853} = "Kymi";
$areanames{fi}->{35854} = "Kymi";
$areanames{fi}->{35855} = "Kymi";
$areanames{fi}->{35856} = "Kymi";
$areanames{fi}->{35857} = "Kymi";
$areanames{fi}->{35858} = "Kymi";
$areanames{fi}->{35861} = "Vaasa";
$areanames{fi}->{35862} = "Vaasa";
$areanames{fi}->{35863} = "Vaasa";
$areanames{fi}->{35864} = "Vaasa";
$areanames{fi}->{35865} = "Vaasa";
$areanames{fi}->{35866} = "Vaasa";
$areanames{fi}->{35867} = "Vaasa";
$areanames{fi}->{35868} = "Vaasa";
$areanames{fi}->{35881} = "Oulu";
$areanames{fi}->{35882} = "Oulu";
$areanames{fi}->{35883} = "Oulu";
$areanames{fi}->{35884} = "Oulu";
$areanames{fi}->{35885} = "Oulu";
$areanames{fi}->{35886} = "Oulu";
$areanames{fi}->{35887} = "Oulu";
$areanames{fi}->{35888} = "Oulu";
$areanames{fi}->{3589} = "Helsinki";
$areanames{en}->{35813} = "North\ Karelia";
$areanames{en}->{35814} = "Central\ Finland";
$areanames{en}->{35815} = "Mikkeli";
$areanames{en}->{35816} = "Lapland";
$areanames{en}->{35817} = "Kuopio";
$areanames{en}->{35819} = "Uusimaa";
$areanames{en}->{35821} = "Turku\/Pori";
$areanames{en}->{35822} = "Turku\/Pori";
$areanames{en}->{35823} = "Turku\/Pori";
$areanames{en}->{35824} = "Turku\/Pori";
$areanames{en}->{35825} = "Turku\/Pori";
$areanames{en}->{35826} = "Turku\/Pori";
$areanames{en}->{35827} = "Turku\/Pori";
$areanames{en}->{35828} = "Turku\/Pori";
$areanames{en}->{35831} = "Häme";
$areanames{en}->{35832} = "Häme";
$areanames{en}->{35833} = "Häme";
$areanames{en}->{35834} = "Häme";
$areanames{en}->{35835} = "Häme";
$areanames{en}->{35836} = "Häme";
$areanames{en}->{35837} = "Häme";
$areanames{en}->{35838} = "Häme";
$areanames{en}->{35851} = "Kymi";
$areanames{en}->{35852} = "Kymi";
$areanames{en}->{35853} = "Kymi";
$areanames{en}->{35854} = "Kymi";
$areanames{en}->{35855} = "Kymi";
$areanames{en}->{35856} = "Kymi";
$areanames{en}->{35857} = "Kymi";
$areanames{en}->{35858} = "Kymi";
$areanames{en}->{35861} = "Vaasa";
$areanames{en}->{35862} = "Vaasa";
$areanames{en}->{35863} = "Vaasa";
$areanames{en}->{35864} = "Vaasa";
$areanames{en}->{35865} = "Vaasa";
$areanames{en}->{35866} = "Vaasa";
$areanames{en}->{35867} = "Vaasa";
$areanames{en}->{35868} = "Vaasa";
$areanames{en}->{35881} = "Oulu";
$areanames{en}->{35882} = "Oulu";
$areanames{en}->{35883} = "Oulu";
$areanames{en}->{35884} = "Oulu";
$areanames{en}->{35885} = "Oulu";
$areanames{en}->{35886} = "Oulu";
$areanames{en}->{35887} = "Oulu";
$areanames{en}->{35888} = "Oulu";
$areanames{en}->{3589} = "Helsinki";

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