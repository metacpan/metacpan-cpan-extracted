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
package Number::Phone::StubCountry::GE;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20240910191015;

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
            (?:
              (?:
                0555|
                1(?:
                  [17]77|
                  555
                )
              )[5-9]|
              757(?:
                7[7-9]|
                8[01]
              )
            )\\d|
            22252[0-4]
          )\\d\\d|
          (?:
            5(?:
              0(?:
                0(?:
                  0\\d|
                  11|
                  22|
                  3[0-6]|
                  44|
                  5[05]|
                  77|
                  88|
                  9[09]
                )|
                111|
                22[02]|
                77\\d
              )|
              1(?:
                1(?:
                  [03][01]|
                  [124]\\d
                )|
                4\\d\\d
              )|
              [23]555|
              4(?:
                4\\d\\d|
                555
              )|
              5(?:
                [0157-9]\\d\\d|
                200
              )|
              6[89]\\d\\d|
              7(?:
                [0147-9]\\d\\d|
                5(?:
                  00|
                  [57]5
                )
              )|
              8(?:
                0(?:
                  [018]\\d|
                  2[0-4]
                )|
                5(?:
                  55|
                  8[89]
                )|
                8(?:
                  55|
                  88
                )
              )|
              9(?:
                090|
                [1-35-9]\\d\\d
              )
            )|
            790\\d\\d
          )\\d{4}|
          5(?:
            0(?:
              0[17]0|
              505
            )|
            1(?:
              0[01]0|
              1(?:
                07|
                33|
                51
              )
            )|
            2(?:
              0[02]0|
              2[25]2
            )|
            3(?:
              0[03]0|
              3[35]3
            )|
            (?:
              40[04]|
              900
            )0|
            5222
          )[0-4]\\d{3}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '',
                'toll_free' => '800\\d{6}',
                'voip' => '70[67]\\d{6}'
              };
my %areanames = ();
$areanames{en} = {"995442", "Sukhumi",
"995425", "Qeda",
"995493", "Poti",
"995361", "Ninotsminda",
"995342", "Akhalgori",
"995495", "Khoni",
"995423", "Xulo",
"995373", "Mtskheta",
"995353", "Gurdjaani",
"995473", "Oni",
"995355", "Signagi",
"995412", "Abasha",
"995434", "Bagdati",
"995436", "Tskaltubo",
"995439", "Ambrolauri",
"995367", "Bordjomi",
"995356", "DedoplisTskaro",
"995359", "TetriTskaro",
"995370", "Gori",
"995350", "Telavi",
"995341", "Rustavi",
"995354", "Lagodekhi",
"995362", "Akhalkalaki",
"995479", "Chiatura",
"995374", "Tigvi",
"995424", "Shuaxevi",
"995496", "Ozurgeti",
"995494", "lanchxuti",
"995417", "Chkhorotskhu",
"995426", "Kobuleti",
"995411", "Samtredia",
"995435", "Sachkhere",
"995347", "Djava",
"995433", "Kharagauli",
"995358", "Bolnisi",
"995447", "Gali",
"995418", "Martvili",
"995363", "Tsalka",
"995491", "Terdjola",
"995365", "Akhaltsikhe",
"995349", "Akhmeta",
"995444", "Gudauta",
"995346", "Dusheti",
"995371", "Kaspi",
"995446", "Tkvarcheli",
"995344", "Tskhinvali",
"995351", "Sagaredjo",
"995448", "Gulripshi",
"995357", "Marneuli",
"995348", "Tianeti",
"995497", "Tkibuli",
"995414", "Xobi",
"995410", "Mestia",
"995432", "Vani",
"995416", "Tsalendjikha",
"995419", "Choxatauri",
"995427", "Xelvachauri",
"995445", "Ochamchire",
"995422", "Batumi",
"995437", "Lentekhi",
"995345", "Stefanstminda\/Kazbegi",
"995443", "Gagra",
"995492", "Zestafoni",
"995369", "Kareli",
"995472", "Tsageri",
"995366", "Adigeni",
"995360", "Dmanisi",
"995352", "Kvareli",
"995372", "Gardabani",
"995364", "Aspindza",
"995415", "Zugdidi",
"995413", "Senaki",
"995368", "Khashuri",
"99532", "Tbilisi",
"995431", "Kutaisi",};
my $timezones = {
               '' => [
                       'Asia/Tbilisi'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+995|\D)//g;
      my $self = bless({ country_code => '995', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '995', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;