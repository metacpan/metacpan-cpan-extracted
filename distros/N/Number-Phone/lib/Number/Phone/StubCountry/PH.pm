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
package Number::Phone::StubCountry::PH;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200606132001;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'leading_digits' => '2',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d)(\\d{5})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '2',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            3(?:
              230|
              397|
              461
            )|
            4(?:
              2(?:
                35|
                [46]4|
                51
              )|
              396|
              4(?:
                22|
                63
              )|
              59[347]|
              76[15]
            )|
            5(?:
              221|
              446
            )|
            642[23]|
            8(?:
              622|
              8(?:
                [24]2|
                5[13]
              )
            )
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{4})(\\d{4,6})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            3469|
            4(?:
              279|
              9(?:
                30|
                56
              )
            )|
            8834
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{5})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '2',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d)(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [3-7]|
            8[2-8]
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[89]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '1',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '1',
                  'pattern' => '(\\d{4})(\\d{1,2})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            (?:
              2[3-8]|
              3[2-68]|
              4[2-9]|
              5[2-6]|
              6[2-58]|
              7[24578]
            )\\d{3}|
            88(?:
              22\\d\\d|
              42
            )
          )\\d{4}|
          2\\d{5}(?:
            \\d{2}
          )?|
          8[2-8]\\d{7}
        ',
                'geographic' => '
          (?:
            (?:
              2[3-8]|
              3[2-68]|
              4[2-9]|
              5[2-6]|
              6[2-58]|
              7[24578]
            )\\d{3}|
            88(?:
              22\\d\\d|
              42
            )
          )\\d{4}|
          2\\d{5}(?:
            \\d{2}
          )?|
          8[2-8]\\d{7}
        ',
                'mobile' => '
          (?:
            81[37]|
            9(?:
              0[5-9]|
              1[0-24-9]|
              2[0-35-9]|
              [35]\\d|
              4[235-9]|
              6[0-35-8]|
              7[1-9]|
              8[189]|
              9[4-9]
            )
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '1800\\d{7,9}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{6332} = "Cebu";
$areanames{en}->{6333} = "Iloilo";
$areanames{en}->{633461} = "Negros\ Occidental";
$areanames{en}->{6335} = "Negros\ Oriental";
$areanames{en}->{6336} = "Antique\/Aklan\/Capiz";
$areanames{en}->{6338} = "Bohol";
$areanames{en}->{634235} = "Quezon";
$areanames{en}->{634244} = "Quezon";
$areanames{en}->{634251} = "Quezon";
$areanames{en}->{634264} = "Quezon";
$areanames{en}->{634279} = "Quezon";
$areanames{en}->{634396} = "Batangas";
$areanames{en}->{634422} = "Bulacan";
$areanames{en}->{634463} = "Bulacan";
$areanames{en}->{634593} = "Pampanga";
$areanames{en}->{634594} = "Pampanga";
$areanames{en}->{634597} = "Pampanga";
$areanames{en}->{6346} = "Cavite";
$areanames{en}->{634761} = "Zambales";
$areanames{en}->{634765} = "Zambales";
$areanames{en}->{6348} = "Palawan";
$areanames{en}->{635221} = "Albay";
$areanames{en}->{6353} = "Leyte";
$areanames{en}->{635446} = "Camarines\ Sur";
$areanames{en}->{6355} = "Western\ Samar";
$areanames{en}->{6356} = "Sorsogon\/Masbate";
$areanames{en}->{6362} = "Zamboanga\ del\ Sur";
$areanames{en}->{6363} = "Lanao\ del\ Norte\/Lanao\ del\ Sur";
$areanames{en}->{636422} = "North\ Cotabato";
$areanames{en}->{636423} = "North\ Cotabato";
$areanames{en}->{6365} = "Zamboanga\ del\ Norte\/Zamboanga\ del\ Sur";
$areanames{en}->{6372} = "La\ Union";
$areanames{en}->{6374} = "Abra\/Benguet\/Kalinga\-Apayao\/Ifugao\/Mountain\ Province";
$areanames{en}->{6375} = "Pangasinan";
$areanames{en}->{6377} = "Ilocos\ Sur\/Ilocos\ Norte";
$areanames{en}->{6378} = "Isabela\/Quirino\/Batanes\/Nueva\ Vizcaya\/Cagayan\ Valley";
$areanames{en}->{6382} = "Davao\ del\ Sur\/Davao";
$areanames{en}->{6383} = "South\ Cotabato";
$areanames{en}->{6384} = "Davao\ del\ Norte";
$areanames{en}->{6385} = "Agusan\ del\ Sur\/Agusan\ del\ Norte";
$areanames{en}->{638622} = "Surigao\ del\ Sur";
$areanames{en}->{6387} = "Davao\ Oriental";
$areanames{en}->{638822} = "Misamis\ Oriental";
$areanames{en}->{638834} = "Misamis\ Occidental";
$areanames{en}->{638842} = "Misamis\ Oriental";
$areanames{en}->{638851} = "Bukidnon";
$areanames{en}->{638853} = "Bukidnon";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+63|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;