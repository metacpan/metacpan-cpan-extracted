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
our $VERSION = 1.20200606132001;

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
                  'leading_digits' => '3',
                  'pattern' => '(\\d{4})(\\d)(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            [0457-9]|
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
            [04]0|
            11|
            5[05]|
            7[07]|
            88|
            9\\d
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '800\\d{6}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{9923130} = "Tursun\-Zade";
$areanames{en}->{9923131} = "Rasht";
$areanames{en}->{9923132} = "Jirgital";
$areanames{en}->{9923133} = "Nurobod";
$areanames{en}->{9923134} = "Rogun";
$areanames{en}->{9923135} = "Fayzabad";
$areanames{en}->{9923136} = "Vakhdat";
$areanames{en}->{9923137} = "Rudaki";
$areanames{en}->{9923138} = "Nurek";
$areanames{en}->{9923139} = "Hissar";
$areanames{en}->{9923141} = "Yavan";
$areanames{en}->{9923153} = "Varzob";
$areanames{en}->{9923154} = "Tadjikabad";
$areanames{en}->{9923155} = "Shakhrinav";
$areanames{en}->{9923156} = "Tavildara";
$areanames{en}->{9923222} = "Kurgan\-Tube";
$areanames{en}->{9923240} = "Shaartuz";
$areanames{en}->{9923242} = "Khuroson";
$areanames{en}->{9923243} = "Abdurakhmana\ Jami";
$areanames{en}->{9923245} = "Bokhtar";
$areanames{en}->{9923246} = "Vakhsh";
$areanames{en}->{9923247} = "Kolkhozabad";
$areanames{en}->{9923248} = "Djilikul";
$areanames{en}->{9923249} = "Kumsangir";
$areanames{en}->{9923250} = "Sarband";
$areanames{en}->{9923251} = "Kabodion";
$areanames{en}->{9923252} = "Panj";
$areanames{en}->{9923311} = "Vose";
$areanames{en}->{9923312} = "Dangara";
$areanames{en}->{9923314} = "Temurmalik";
$areanames{en}->{9923315} = "M\.\ Khamadoni";
$areanames{en}->{9923316} = "Parkhar";
$areanames{en}->{992331700} = "Khovaling";
$areanames{en}->{9923318} = "Muminobod";
$areanames{en}->{9923322} = "Kulyab";
$areanames{en}->{9923422} = "Khujand";
$areanames{en}->{9923441} = "Spitamen";
$areanames{en}->{9923442} = "Gafurov";
$areanames{en}->{9923443} = "Kayrakum";
$areanames{en}->{9923445} = "Matchinskiy";
$areanames{en}->{9923451} = "Chkalovsk";
$areanames{en}->{9923452} = "Zafarabad";
$areanames{en}->{9923453} = "Asht";
$areanames{en}->{9923454} = "Istravshan";
$areanames{en}->{9923455} = "Jabarrasulov";
$areanames{en}->{9923456} = "Shakhristan";
$areanames{en}->{9923462} = "Isfara";
$areanames{en}->{9923464} = "Ganchi";
$areanames{en}->{9923465} = "Taboshar";
$areanames{en}->{9923467} = "Kanibadam";
$areanames{en}->{9923475} = "Pendjikent";
$areanames{en}->{9923479} = "Ayni";
$areanames{en}->{9923522} = "Khorog";
$areanames{en}->{9923551} = "Vanj";
$areanames{en}->{9923552} = "Darvaz";
$areanames{en}->{9923553} = "Ishkashim";
$areanames{en}->{9923554} = "Murgab";
$areanames{en}->{9923555} = "Roshtkala";
$areanames{en}->{9923556} = "Rushan";
$areanames{en}->{99237} = "Dushanbe";

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