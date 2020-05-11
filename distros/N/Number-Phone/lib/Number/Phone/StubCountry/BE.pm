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
our $VERSION = 1.20200511123710;

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
              3[0457]|
              44|
              69|
              7[0579]
            )|
            90(?:
              0[0-35-8]|
              1[36]|
              2[0-3568]|
              3[0135689]|
              4[2-68]|
              5[1-68]|
              6[0-378]|
              7[23568]|
              9[34679]
            )
          )\\d{4}
        )|(
          78(?:
            0[57]|
            1[0458]|
            2[25]|
            3[15-8]|
            48|
            [56]0|
            7[078]
          )\\d{4}
        )',
                'toll_free' => '800[1-9]\\d{4}',
                'voip' => ''
              };
my %areanames = ();
$areanames{nl}->{3210} = "Waver";
$areanames{nl}->{3211} = "Hasselt";
$areanames{nl}->{3212} = "Tongeren";
$areanames{nl}->{3213} = "Diest";
$areanames{nl}->{3214} = "Herentals";
$areanames{nl}->{3215} = "Mechelen";
$areanames{nl}->{3216} = "Leuven";
$areanames{nl}->{3219} = "Borgworm";
$areanames{nl}->{322} = "Brussel";
$areanames{nl}->{323} = "Antwerpen";
$areanames{nl}->{3242} = "Luik";
$areanames{nl}->{3243} = "Luik";
$areanames{nl}->{3250} = "Brugge";
$areanames{nl}->{3251} = "Roeselare";
$areanames{nl}->{3252} = "Dendermonde";
$areanames{nl}->{3253} = "Aalst";
$areanames{nl}->{3254} = "Ninove";
$areanames{nl}->{3255} = "Ronse";
$areanames{nl}->{3256} = "Kortrijk";
$areanames{nl}->{3257} = "Ieper";
$areanames{nl}->{3258} = "Veurne";
$areanames{nl}->{3259} = "Oostende";
$areanames{nl}->{3260} = "Chimay";
$areanames{nl}->{3261} = "Libramont\-Chevigny";
$areanames{nl}->{3263} = "Aarlen";
$areanames{nl}->{3264} = "La\ Louvière";
$areanames{nl}->{3265} = "Bergen";
$areanames{nl}->{3267} = "Nijvel";
$areanames{nl}->{3268} = "Aat";
$areanames{nl}->{3269} = "Doornik";
$areanames{nl}->{3271} = "Charleroi";
$areanames{nl}->{3280} = "Stavelot";
$areanames{nl}->{3281} = "Namen";
$areanames{nl}->{3282} = "Dinant";
$areanames{nl}->{3283} = "Ciney";
$areanames{nl}->{3284} = "Marche\-en\-Famenne";
$areanames{nl}->{3285} = "Hoei";
$areanames{nl}->{3286} = "Durbuy";
$areanames{nl}->{3287} = "Verviers";
$areanames{nl}->{3289} = "Genk";
$areanames{nl}->{329} = "Gent";
$areanames{de}->{3210} = "Wavre";
$areanames{de}->{3211} = "Hasselt";
$areanames{de}->{3212} = "Tongern";
$areanames{de}->{3213} = "Diest";
$areanames{de}->{3214} = "Herentals";
$areanames{de}->{3215} = "Mecheln";
$areanames{de}->{3216} = "Löwen";
$areanames{de}->{3219} = "Waremme";
$areanames{de}->{322} = "Brüssel";
$areanames{de}->{323} = "Antwerpen";
$areanames{de}->{3242} = "Lüttich";
$areanames{de}->{3243} = "Lüttich";
$areanames{de}->{3250} = "Brügge";
$areanames{de}->{3251} = "Roeselare";
$areanames{de}->{3252} = "Dendermonde";
$areanames{de}->{3253} = "Aalst";
$areanames{de}->{3254} = "Ninove";
$areanames{de}->{3255} = "Ronse";
$areanames{de}->{3256} = "Kortrijk";
$areanames{de}->{3257} = "Ypern";
$areanames{de}->{3258} = "Veurne";
$areanames{de}->{3259} = "Ostende";
$areanames{de}->{3260} = "Chimay";
$areanames{de}->{3261} = "Libramont\-Chevigny";
$areanames{de}->{3263} = "Arel";
$areanames{de}->{3264} = "La\ Louvière";
$areanames{de}->{3265} = "Bergen";
$areanames{de}->{3267} = "Nivelles";
$areanames{de}->{3268} = "Ath";
$areanames{de}->{3269} = "Tournai";
$areanames{de}->{3271} = "Charleroi";
$areanames{de}->{3280} = "Stablo";
$areanames{de}->{3281} = "Namür";
$areanames{de}->{3282} = "Dinant";
$areanames{de}->{3283} = "Ciney";
$areanames{de}->{3284} = "Marche\-en\-Famenne";
$areanames{de}->{3285} = "Huy";
$areanames{de}->{3286} = "Durbuy";
$areanames{de}->{3287} = "Verviers";
$areanames{de}->{3289} = "Genk";
$areanames{de}->{329} = "Gent";
$areanames{fr}->{3210} = "Wavre";
$areanames{fr}->{3211} = "Hasselt";
$areanames{fr}->{3212} = "Tongres";
$areanames{fr}->{3213} = "Diest";
$areanames{fr}->{3214} = "Herentals";
$areanames{fr}->{3215} = "Malines";
$areanames{fr}->{3216} = "Louvain";
$areanames{fr}->{3219} = "Waremme";
$areanames{fr}->{322} = "Bruxelles";
$areanames{fr}->{323} = "Anvers";
$areanames{fr}->{3242} = "Liège";
$areanames{fr}->{3243} = "Liège";
$areanames{fr}->{3250} = "Bruges";
$areanames{fr}->{3251} = "Roulers";
$areanames{fr}->{3252} = "Termonde";
$areanames{fr}->{3253} = "Alost";
$areanames{fr}->{3254} = "Ninove";
$areanames{fr}->{3255} = "Renaix";
$areanames{fr}->{3256} = "Courtrai";
$areanames{fr}->{3257} = "Ypres";
$areanames{fr}->{3258} = "Furnes";
$areanames{fr}->{3259} = "Ostende";
$areanames{fr}->{3260} = "Chimay";
$areanames{fr}->{3261} = "Libramont\-Chevigny";
$areanames{fr}->{3263} = "Arlon";
$areanames{fr}->{3264} = "La\ Louvière";
$areanames{fr}->{3265} = "Mons";
$areanames{fr}->{3267} = "Nivelles";
$areanames{fr}->{3268} = "Ath";
$areanames{fr}->{3269} = "Tournai";
$areanames{fr}->{3271} = "Charleroi";
$areanames{fr}->{3280} = "Stavelot";
$areanames{fr}->{3281} = "Namur";
$areanames{fr}->{3282} = "Dinant";
$areanames{fr}->{3283} = "Ciney";
$areanames{fr}->{3284} = "Marche\-en\-Famenne";
$areanames{fr}->{3285} = "Huy";
$areanames{fr}->{3286} = "Durbuy";
$areanames{fr}->{3287} = "Verviers";
$areanames{fr}->{3289} = "Genk";
$areanames{fr}->{329} = "Gand";
$areanames{en}->{3210} = "Wavre";
$areanames{en}->{3211} = "Hasselt";
$areanames{en}->{3212} = "Tongeren";
$areanames{en}->{3213} = "Diest";
$areanames{en}->{3214} = "Herentals";
$areanames{en}->{3215} = "Mechelen";
$areanames{en}->{3216} = "Leuven";
$areanames{en}->{3219} = "Waremme";
$areanames{en}->{322} = "Brussels";
$areanames{en}->{323} = "Antwerp";
$areanames{en}->{3242} = "Liège";
$areanames{en}->{3243} = "Liège";
$areanames{en}->{3250} = "Bruges";
$areanames{en}->{3251} = "Roeselare";
$areanames{en}->{3252} = "Dendermonde";
$areanames{en}->{3253} = "Aalst";
$areanames{en}->{3254} = "Ninove";
$areanames{en}->{3255} = "Ronse";
$areanames{en}->{3256} = "Kortrijk";
$areanames{en}->{3257} = "Ypres";
$areanames{en}->{3258} = "Veurne";
$areanames{en}->{3259} = "Ostend";
$areanames{en}->{3260} = "Chimay";
$areanames{en}->{3261} = "Libramont\-Chevigny";
$areanames{en}->{3263} = "Arlon";
$areanames{en}->{3264} = "La\ Louvière";
$areanames{en}->{3265} = "Mons";
$areanames{en}->{3267} = "Nivelles";
$areanames{en}->{3268} = "Ath";
$areanames{en}->{3269} = "Tournai";
$areanames{en}->{3271} = "Charleroi";
$areanames{en}->{3280} = "Stavelot";
$areanames{en}->{3281} = "Namur";
$areanames{en}->{3282} = "Dinant";
$areanames{en}->{3283} = "Ciney";
$areanames{en}->{3284} = "Marche\-en\-Famenne";
$areanames{en}->{3285} = "Huy";
$areanames{en}->{3286} = "Durbuy";
$areanames{en}->{3287} = "Verviers";
$areanames{en}->{3289} = "Genk";
$areanames{en}->{329} = "Ghent";

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