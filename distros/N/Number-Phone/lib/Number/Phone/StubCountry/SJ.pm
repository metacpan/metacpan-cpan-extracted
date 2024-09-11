# automatically generated file, don't edit



# Copyright 2024 David Cantrell, derived from data from libphonenumber
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
package Number::Phone::StubCountry::SJ;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20240910191017;

my $formatters = [];

my $validators = {
                'fixed_line' => '79\\d{6}',
                'geographic' => '79\\d{6}',
                'mobile' => '
          (?:
            4[015-8]|
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
$areanames{en} = {"4723653", "Oslo",
"4761", "Oppland",
"4721443", "Oslo",
"4723622", "Oslo",
"4721992", "Oslo",
"472387", "Oslo",
"47244", "Oslo",
"472412", "Oslo",
"4763", "Akershus",
"4724207", "Oslo",
"4721441", "Oslo",
"472134", "Oslo",
"4766", "Akershus",
"472367", "Oslo",
"4738", "Vest\-Agder",
"472139", "Oslo",
"4721417", "Oslo",
"47231", "Oslo",
"4731", "Buskerud",
"472423", "Oslo",
"472138", "Oslo",
"4724208", "Oslo",
"4721418", "Oslo",
"472425", "Oslo",
"472142", "Oslo",
"4733", "Vestfold",
"47211", "Oslo",
"472193", "Oslo",
"472195", "Oslo",
"4723624", "Oslo",
"4721994", "Oslo",
"47218", "Oslo",
"4776", "Nordland",
"4757", "Sogn\ og\ Fjordane",
"472411", "Oslo",
"4773", "Sør\-Trøndelag",
"47216", "Oslo",
"4723625", "Oslo",
"4771", "Møre\ og\ Romsdal",
"4721995", "Oslo",
"4778", "Finnmark",
"472196", "Oslo",
"472190", "Oslo",
"4752", "Rogaland",
"472426", "Oslo",
"4756", "Hordaland",
"472197", "Oslo",
"472132", "Oslo",
"4777", "Troms",
"4723626", "Oslo",
"4753", "Hordaland",
"4721996", "Oslo",
"472148", "Oslo",
"472427", "Oslo",
"4751", "Rogaland",
"472414", "Oslo",
"4721999", "Oslo",
"472149", "Oslo",
"472418", "Oslo",
"472363", "Oslo",
"472385", "Oslo",
"4772", "Sør\-Trøndelag",
"472383", "Oslo",
"47243", "Oslo",
"4721411", "Oslo",
"4732", "Buskerud",
"4721447", "Oslo",
"47239", "Oslo",
"4723657", "Oslo",
"4721413", "Oslo",
"4767", "Akershus",
"47240", "Oslo",
"47247", "Oslo",
"4724203", "Oslo",
"47245", "Oslo",
"4721990", "Oslo",
"4723620", "Oslo",
"472380", "Oslo",
"4762", "Hedmark",
"472386", "Oslo",
"472360", "Oslo",
"4737", "Aust\-Agder",
"4723658", "Oslo",
"4721448", "Oslo",
"472366", "Oslo",
"47234", "Oslo",
"4755", "Hordaland",
"4721997", "Oslo",
"4723627", "Oslo",
"4721412", "Oslo",
"4721440", "Oslo",
"4724202", "Oslo",
"4764", "Akershus",
"472136", "Oslo",
"4723650", "Oslo",
"472361", "Oslo",
"472381", "Oslo",
"4723628", "Oslo",
"4724205", "Oslo",
"472135", "Oslo",
"4774", "Nord\-Trøndelag",
"4722", "Oslo",
"4721415", "Oslo",
"47246", "Oslo",
"472428", "Oslo",
"4721446", "Oslo",
"472133", "Oslo",
"472147", "Oslo",
"47248", "Oslo",
"472198", "Oslo",
"4724204", "Oslo",
"4723659", "Oslo",
"472194", "Oslo",
"472417", "Oslo",
"472382", "Oslo",
"472429", "Oslo",
"472424", "Oslo",
"4723654", "Oslo",
"4721444", "Oslo",
"4769", "Østfold",
"472416", "Oslo",
"4724206", "Oslo",
"4770", "Møre\ og\ Romsdal",
"4721416", "Oslo",
"4721445", "Oslo",
"472410", "Oslo",
"4723655", "Oslo",
"472140", "Oslo",
"472146", "Oslo",
"472421", "Oslo",
"47233", "Oslo",
"4735", "Telemark",
"4721419", "Oslo",
"472191", "Oslo",
"4724209", "Oslo",
"4721442", "Oslo",
"472413", "Oslo",
"4724200", "Oslo",
"4721993", "Oslo",
"4723623", "Oslo",
"47210", "Oslo",
"47249", "Oslo",
"4723652", "Oslo",
"47217", "Oslo",
"47215", "Oslo",
"472368", "Oslo",
"47232", "Oslo",
"4775", "Nordland",
"472415", "Oslo",
"4721410", "Oslo",
"47230", "Oslo",
"4721991", "Oslo",
"4723621", "Oslo",
"4779", "Svalbard\ \&\ Jan\ Mayen",
"47235", "Oslo",
"47212", "Oslo",
"472388", "Oslo",
"47237", "Oslo",
"472384", "Oslo",
"472422", "Oslo",
"472145", "Oslo",
"472364", "Oslo",
"472137", "Oslo",
"472143", "Oslo",
"472369", "Oslo",};
my $timezones = {
               '' => [
                       'Arctic/Longyearbyen',
                       'Europe/Oslo'
                     ],
               '0' => [
                        'Europe/Oslo'
                      ],
               '2' => [
                        'Europe/Oslo'
                      ],
               '3' => [
                        'Europe/Oslo'
                      ],
               '4' => [
                        'Europe/Oslo'
                      ],
               '5' => [
                        'Europe/Oslo'
                      ],
               '6' => [
                        'Europe/Oslo'
                      ],
               '7' => [
                        'Europe/Oslo'
                      ],
               '79' => [
                         'Arctic/Longyearbyen'
                       ],
               '8' => [
                        'Europe/Oslo'
                      ],
               '9' => [
                        'Europe/Oslo'
                      ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+47|\D)//g;
      my $self = bless({ country_code => '47', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;