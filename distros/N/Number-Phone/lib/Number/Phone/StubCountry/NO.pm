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
package Number::Phone::StubCountry::NO;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200427120031;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [489]|
            5[89]
          ',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[235-7]',
                  'pattern' => '(\\d{2})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2[1-4]|
            3[1-3578]|
            5[1-35-7]|
            6[1-4679]|
            7[0-8]
          )\\d{6}
        ',
                'geographic' => '
          (?:
            2[1-4]|
            3[1-3578]|
            5[1-35-7]|
            6[1-4679]|
            7[0-8]
          )\\d{6}
        ',
                'mobile' => '
          (?:
            4[015-8]|
            5[89]|
            9\\d
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '880\\d{5}',
                'specialrate' => '(
          810(?:
            0[0-6]|
            [2-8]\\d
          )\\d{3}
        )|(82[09]\\d{5})|(
          (?:
            0[2-9]|
            81(?:
              0(?:
                0[7-9]|
                1\\d
              )|
              5\\d\\d
            )
          )\\d{3}
        )',
                'toll_free' => '80[01]\\d{5}',
                'voip' => '85[0-5]\\d{5}'
              };
my %areanames = ();
$areanames{en}->{47210} = "Oslo";
$areanames{en}->{47211} = "Oslo";
$areanames{en}->{47212} = "Oslo";
$areanames{en}->{472132} = "Oslo";
$areanames{en}->{472133} = "Oslo";
$areanames{en}->{472134} = "Oslo";
$areanames{en}->{472135} = "Oslo";
$areanames{en}->{472136} = "Oslo";
$areanames{en}->{472137} = "Oslo";
$areanames{en}->{472138} = "Oslo";
$areanames{en}->{472139} = "Oslo";
$areanames{en}->{472140} = "Oslo";
$areanames{en}->{4721410} = "Oslo";
$areanames{en}->{4721411} = "Oslo";
$areanames{en}->{4721412} = "Oslo";
$areanames{en}->{4721413} = "Oslo";
$areanames{en}->{4721415} = "Oslo";
$areanames{en}->{4721416} = "Oslo";
$areanames{en}->{4721417} = "Oslo";
$areanames{en}->{4721418} = "Oslo";
$areanames{en}->{4721419} = "Oslo";
$areanames{en}->{472142} = "Oslo";
$areanames{en}->{472143} = "Oslo";
$areanames{en}->{4721440} = "Oslo";
$areanames{en}->{4721441} = "Oslo";
$areanames{en}->{4721442} = "Oslo";
$areanames{en}->{4721443} = "Oslo";
$areanames{en}->{4721444} = "Oslo";
$areanames{en}->{4721445} = "Oslo";
$areanames{en}->{4721446} = "Oslo";
$areanames{en}->{4721447} = "Oslo";
$areanames{en}->{4721448} = "Oslo";
$areanames{en}->{472145} = "Oslo";
$areanames{en}->{472146} = "Oslo";
$areanames{en}->{472147} = "Oslo";
$areanames{en}->{472148} = "Oslo";
$areanames{en}->{472149} = "Oslo";
$areanames{en}->{47215} = "Oslo";
$areanames{en}->{47216} = "Oslo";
$areanames{en}->{47217} = "Oslo";
$areanames{en}->{47218} = "Oslo";
$areanames{en}->{472190} = "Oslo";
$areanames{en}->{472191} = "Oslo";
$areanames{en}->{472193} = "Oslo";
$areanames{en}->{472194} = "Oslo";
$areanames{en}->{472195} = "Oslo";
$areanames{en}->{472196} = "Oslo";
$areanames{en}->{472197} = "Oslo";
$areanames{en}->{472198} = "Oslo";
$areanames{en}->{4721990} = "Oslo";
$areanames{en}->{4721991} = "Oslo";
$areanames{en}->{4721992} = "Oslo";
$areanames{en}->{4721993} = "Oslo";
$areanames{en}->{4721994} = "Oslo";
$areanames{en}->{4721995} = "Oslo";
$areanames{en}->{4721996} = "Oslo";
$areanames{en}->{4721997} = "Oslo";
$areanames{en}->{4721999} = "Oslo";
$areanames{en}->{4722} = "Oslo";
$areanames{en}->{47230} = "Oslo";
$areanames{en}->{47231} = "Oslo";
$areanames{en}->{47232} = "Oslo";
$areanames{en}->{47233} = "Oslo";
$areanames{en}->{47234} = "Oslo";
$areanames{en}->{47235} = "Oslo";
$areanames{en}->{472360} = "Oslo";
$areanames{en}->{472361} = "Oslo";
$areanames{en}->{4723620} = "Oslo";
$areanames{en}->{4723621} = "Oslo";
$areanames{en}->{4723622} = "Oslo";
$areanames{en}->{4723623} = "Oslo";
$areanames{en}->{4723624} = "Oslo";
$areanames{en}->{4723625} = "Oslo";
$areanames{en}->{4723626} = "Oslo";
$areanames{en}->{4723627} = "Oslo";
$areanames{en}->{4723628} = "Oslo";
$areanames{en}->{472363} = "Oslo";
$areanames{en}->{472364} = "Oslo";
$areanames{en}->{4723650} = "Oslo";
$areanames{en}->{4723652} = "Oslo";
$areanames{en}->{4723653} = "Oslo";
$areanames{en}->{4723654} = "Oslo";
$areanames{en}->{4723655} = "Oslo";
$areanames{en}->{4723657} = "Oslo";
$areanames{en}->{4723658} = "Oslo";
$areanames{en}->{4723659} = "Oslo";
$areanames{en}->{472366} = "Oslo";
$areanames{en}->{472367} = "Oslo";
$areanames{en}->{472368} = "Oslo";
$areanames{en}->{472369} = "Oslo";
$areanames{en}->{47237} = "Oslo";
$areanames{en}->{472380} = "Oslo";
$areanames{en}->{472381} = "Oslo";
$areanames{en}->{472382} = "Oslo";
$areanames{en}->{472383} = "Oslo";
$areanames{en}->{472384} = "Oslo";
$areanames{en}->{472385} = "Oslo";
$areanames{en}->{472386} = "Oslo";
$areanames{en}->{472387} = "Oslo";
$areanames{en}->{472388} = "Oslo";
$areanames{en}->{47239} = "Oslo";
$areanames{en}->{47240} = "Oslo";
$areanames{en}->{472410} = "Oslo";
$areanames{en}->{472411} = "Oslo";
$areanames{en}->{472412} = "Oslo";
$areanames{en}->{472413} = "Oslo";
$areanames{en}->{472414} = "Oslo";
$areanames{en}->{472415} = "Oslo";
$areanames{en}->{472416} = "Oslo";
$areanames{en}->{472417} = "Oslo";
$areanames{en}->{472418} = "Oslo";
$areanames{en}->{4724200} = "Oslo";
$areanames{en}->{4724202} = "Oslo";
$areanames{en}->{4724203} = "Oslo";
$areanames{en}->{4724204} = "Oslo";
$areanames{en}->{4724205} = "Oslo";
$areanames{en}->{4724206} = "Oslo";
$areanames{en}->{4724207} = "Oslo";
$areanames{en}->{4724208} = "Oslo";
$areanames{en}->{4724209} = "Oslo";
$areanames{en}->{472421} = "Oslo";
$areanames{en}->{472422} = "Oslo";
$areanames{en}->{472423} = "Oslo";
$areanames{en}->{472424} = "Oslo";
$areanames{en}->{472425} = "Oslo";
$areanames{en}->{472426} = "Oslo";
$areanames{en}->{472427} = "Oslo";
$areanames{en}->{472428} = "Oslo";
$areanames{en}->{472429} = "Oslo";
$areanames{en}->{47243} = "Oslo";
$areanames{en}->{47244} = "Oslo";
$areanames{en}->{47245} = "Oslo";
$areanames{en}->{47246} = "Oslo";
$areanames{en}->{47247} = "Oslo";
$areanames{en}->{47248} = "Oslo";
$areanames{en}->{47249} = "Oslo";
$areanames{en}->{4731} = "Buskerud";
$areanames{en}->{4732} = "Buskerud";
$areanames{en}->{4733} = "Vestfold";
$areanames{en}->{4735} = "Telemark";
$areanames{en}->{4737} = "Aust\-Agder";
$areanames{en}->{4738} = "Vest\-Agder";
$areanames{en}->{4751} = "Rogaland";
$areanames{en}->{4752} = "Rogaland";
$areanames{en}->{4753} = "Hordaland";
$areanames{en}->{4755} = "Hordaland";
$areanames{en}->{4756} = "Hordaland";
$areanames{en}->{4757} = "Sogn\ og\ Fjordane";
$areanames{en}->{4761} = "Oppland";
$areanames{en}->{4762} = "Hedmark";
$areanames{en}->{4763} = "Akershus";
$areanames{en}->{4764} = "Akershus";
$areanames{en}->{4766} = "Akershus";
$areanames{en}->{4767} = "Akershus";
$areanames{en}->{4769} = "Østfold";
$areanames{en}->{4770} = "Møre\ og\ Romsdal";
$areanames{en}->{4771} = "Møre\ og\ Romsdal";
$areanames{en}->{4772} = "Sør\-Trøndelag";
$areanames{en}->{4773} = "Sør\-Trøndelag";
$areanames{en}->{4774} = "Nord\-Trøndelag";
$areanames{en}->{4775} = "Nordland";
$areanames{en}->{4776} = "Nordland";
$areanames{en}->{4777} = "Troms";
$areanames{en}->{4778} = "Finnmark";
$areanames{en}->{4779} = "Svalbard\ \&\ Jan\ Mayen";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+47|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;