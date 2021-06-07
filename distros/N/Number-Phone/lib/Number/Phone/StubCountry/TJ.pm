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
package Number::Phone::StubCountry::TJ;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20210602223301;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '3317',
                  'pattern' => '(\\d{6})(\\d)(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [34]7|
            91[78]
          ',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '3[1-5]',
                  'pattern' => '(\\d{4})(\\d)(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [02-57-9]|
            11
          ',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            3(?:
              1[3-5]|
              2[245]|
              3[12]|
              4[24-7]|
              5[25]|
              72
            )|
            4(?:
              46|
              74|
              87
            )
          )\\d{6}
        ',
                'geographic' => '
          (?:
            3(?:
              1[3-5]|
              2[245]|
              3[12]|
              4[24-7]|
              5[25]|
              72
            )|
            4(?:
              46|
              74|
              87
            )
          )\\d{6}
        ',
                'mobile' => '
          41[18]\\d{6}|
          (?:
            [02-4]0|
            11|
            5[05]|
            7[07]|
            8[08]|
            9\\d
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"9923465", "Taboshar",
"9923456", "Shakhristan",
"9923139", "Hissar",
"9923153", "Varzob",
"9923445", "Matchinskiy",
"9923249", "Kumsangir",
"9923462", "Isfara",
"9923522", "Khorog",
"9923314", "Temurmalik",
"9923442", "Gafurov",
"9923245", "Bokhtar",
"9923316", "Parkhar",
"9923552", "Darvaz",
"9923135", "Fayzabad",
"9923242", "Khuroson",
"9923555", "Roshtkala",
"9923130", "Tursun\-Zade",
"9923132", "Jirgital",
"9923454", "Istravshan",
"9923240", "Shaartuz",
"9923131", "Rasht",
"9923155", "Shakhrinav",
"9923551", "Vanj",
"9923443", "Kayrakum",
"992331700", "Khovaling",
"9923248", "Djilikul",
"9923138", "Nurek",
"9923441", "Spitamen",
"9923553", "Ishkashim",
"9923133", "Nurobod",
"9923322", "Kulyab",
"9923243", "Abdurakhmana\ Jami",
"9923136", "Vakhdat",
"9923422", "Khujand",
"9923246", "Vakhsh",
"9923315", "M\.\ Khamadoni",
"9923141", "Yavan",
"9923464", "Ganchi",
"9923252", "Panj",
"9923475", "Pendjikent",
"9923312", "Dangara",
"9923250", "Sarband",
"9923556", "Rushan",
"9923554", "Murgab",
"9923222", "Kurgan\-Tube",
"9923455", "Jabarrasulov",
"9923134", "Rogun",
"9923479", "Ayni",
"9923452", "Zafarabad",
"9923154", "Tadjikabad",
"9923318", "Muminobod",
"9923451", "Chkalovsk",
"9923467", "Kanibadam",
"99237", "Dushanbe",
"9923251", "Kabodion",
"9923311", "Vose",
"9923453", "Asht",
"9923247", "Kolkhozabad",
"9923156", "Tavildara",
"9923137", "Rudaki",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+992|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:8)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;