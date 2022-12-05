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
package Number::Phone::StubCountry::BE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20221202211023;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            (?:
              80|
              9
            )0
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            [239]|
            4[23]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[15-8]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '4',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          80[2-8]\\d{5}|
          (?:
            1[0-69]|
            [23][2-8]|
            4[23]|
            5\\d|
            6[013-57-9]|
            71|
            8[1-79]|
            9[2-4]
          )\\d{6}
        ',
                'geographic' => '
          80[2-8]\\d{5}|
          (?:
            1[0-69]|
            [23][2-8]|
            4[23]|
            5\\d|
            6[013-57-9]|
            71|
            8[1-79]|
            9[2-4]
          )\\d{6}
        ',
                'mobile' => '4[5-9]\\d{7}',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(7879\\d{4})|(
          (?:
            70(?:
              2[0-57]|
              3[04-7]|
              44|
              6[569]|
              7[0579]
            )|
            90(?:
              0[0-8]|
              1[36]|
              2[0-3568]|
              3[0-689]|
              [47][2-68]|
              5[1-68]|
              6[0-378]|
              9[34679]
            )
          )\\d{4}
        )|(
          78(?:
            0[57]|
            1[014-8]|
            2[25]|
            3[15-8]|
            48|
            [56]0|
            7[06-8]|
            9\\d
          )\\d{4}
        )',
                'toll_free' => '800[1-9]\\d{4}',
                'voip' => ''
              };
my %areanames = ();
$areanames{fr} = {"3251", "Roulers",
"3216", "Louvain",
"323", "Anvers",
"322", "Bruxelles",
"3256", "Courtrai",
"3259", "Ostende",
"3252", "Termonde",
"3212", "Tongres",
"329", "Gand",
"3253", "Alost",
"3255", "Renaix",
"3258", "Furnes",
"3215", "Malines",};
$areanames{nl} = {"3267", "Nijvel",
"3242", "Luik",
"329", "Gent",
"3285", "Hoei",
"3219", "Borgworm",
"3243", "Luik",
"3259", "Oostende",
"322", "Brussel",
"3265", "Bergen",
"3263", "Aarlen",
"3257", "Ieper",
"3268", "Aat",
"3281", "Namen",
"323", "Antwerpen",
"3269", "Doornik",
"3250", "Brugge",
"3210", "Waver",};
$areanames{en} = {"323", "Antwerp",
"3216", "Leuven",
"3280", "Stavelot",
"3281", "Namur",
"3268", "Ath",
"3257", "Ypres",
"3214", "Herentals",
"3265", "Mons",
"3254", "Ninove",
"3263", "Arlon",
"3256", "Kortrijk",
"322", "Brussels",
"3284", "Marche\-en\-Famenne",
"3211", "Hasselt",
"3210", "Wavre",
"3286", "Durbuy",
"3250", "Bruges",
"3251", "Roeselare",
"3287", "Verviers",
"3269", "Tournai",
"3271", "Charleroi",
"329", "Ghent",
"3255", "Ronse",
"3264", "La\ Louvière",
"3253", "Aalst",
"3242", "Liège",
"3267", "Nivelles",
"3213", "Diest",
"3215", "Mechelen",
"3289", "Genk",
"3258", "Veurne",
"3282", "Dinant",
"3259", "Ostend",
"3260", "Chimay",
"3243", "Liège",
"3261", "Libramont\-Chevigny",
"3252", "Dendermonde",
"3212", "Tongeren",
"3219", "Waremme",
"3285", "Huy",
"3283", "Ciney",};
$areanames{de} = {"3243", "Lüttich",
"3259", "Ostende",
"3212", "Tongern",
"3242", "Lüttich",
"329", "Gent",
"3215", "Mecheln",
"3250", "Brügge",
"3257", "Ypern",
"323", "Antwerpen",
"3216", "Löwen",
"3280", "Stablo",
"3281", "Namür",
"322", "Brüssel",
"3265", "Bergen",
"3263", "Arel",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+32|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;