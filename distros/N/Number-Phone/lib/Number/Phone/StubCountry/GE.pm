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
package Number::Phone::StubCountry::GE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20201204215956;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '70',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '32',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[57]',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[348]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            3(?:
              [256]\\d|
              4[124-9]|
              7[0-4]
            )|
            4(?:
              1\\d|
              2[2-7]|
              3[1-79]|
              4[2-8]|
              7[239]|
              9[1-7]
            )
          )\\d{6}
        ',
                'geographic' => '
          (?:
            3(?:
              [256]\\d|
              4[124-9]|
              7[0-4]
            )|
            4(?:
              1\\d|
              2[2-7]|
              3[1-79]|
              4[2-8]|
              7[239]|
              9[1-7]
            )
          )\\d{6}
        ',
                'mobile' => '
          5(?:
            0(?:
              0(?:
                0\\d|
                50
              )\\d|
              555[5-9]
            )|
            (?:
              111\\d|
              8(?:
                58[89]|
                888
              )
            )\\d|
            (?:
              2222|
              3333
            )[0-4]|
            52(?:
              00\\d|
              22[0-4]
            )|
            75(?:
              00\\d|
              7(?:
                7[7-9]|
                8[01]
              )
            )
          )\\d{3}|
          (?:
            5(?:
              [14]4|
              5[0157-9]|
              68|
              7[0147-9]|
              9[1-35-9]
            )|
            790
          )\\d{6}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '800\\d{6}',
                'voip' => '70[67]\\d{6}'
              };
my %areanames = ();
$areanames{en} = {"995493", "Poti",
"995356", "DedoplisTskaro",
"995427", "Xelvachauri",
"995370", "Gori",
"995426", "Kobuleti",
"995410", "Mestia",
"995345", "Stefanstminda\/Kazbegi",
"995344", "Tskhinvali",
"995368", "Khashuri",
"995357", "Marneuli",
"995443", "Gagra",
"995354", "Lagodekhi",
"995355", "Signagi",
"995347", "Djava",
"995472", "Tsageri",
"995479", "Chiatura",
"995346", "Dusheti",
"995424", "Shuaxevi",
"995418", "Martvili",
"995425", "Qeda",
"995360", "Dmanisi",
"995411", "Samtredia",
"995439", "Ambrolauri",
"995362", "Akhalkalaki",
"995444", "Gudauta",
"995445", "Ochamchire",
"995495", "Khoni",
"995494", "lanchxuti",
"995371", "Kaspi",
"995432", "Vani",
"995369", "Kareli",
"995423", "Xulo",
"995497", "Tkibuli",
"995412", "Abasha",
"995446", "Tkvarcheli",
"995361", "Ninotsminda",
"995372", "Gardabani",
"995431", "Kutaisi",
"995496", "Ozurgeti",
"995419", "Choxatauri",
"995447", "Gali",
"995353", "Gurdjaani",
"995341", "Rustavi",
"995413", "Senaki",
"995359", "TetriTskaro",
"995422", "Batumi",
"995352", "Kvareli",
"995373", "Mtskheta",
"995363", "Tsalka",
"995342", "Akhalgori",
"995448", "Gulripshi",
"995351", "Sagaredjo",
"995349", "Akhmeta",
"995433", "Kharagauli",
"995367", "Bordjomi",
"995473", "Oni",
"995491", "Terdjola",
"995436", "Tskaltubo",
"995358", "Bolnisi",
"995374", "Tigvi",
"995415", "Zugdidi",
"995414", "Xobi",
"995366", "Adigeni",
"995437", "Lentekhi",
"995434", "Bagdati",
"995350", "Telavi",
"995435", "Sachkhere",
"995417", "Chkhorotskhu",
"995492", "Zestafoni",
"995348", "Tianeti",
"995442", "Sukhumi",
"995416", "Tsalendjikha",
"99532", "Tbilisi",
"995365", "Akhaltsikhe",
"995364", "Aspindza",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+995|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;