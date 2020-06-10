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
our $VERSION = 1.20200606131959;

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
$areanames{en}->{99532} = "Tbilisi";
$areanames{en}->{995341} = "Rustavi";
$areanames{en}->{995342} = "Akhalgori";
$areanames{en}->{995344} = "Tskhinvali";
$areanames{en}->{995345} = "Stefanstminda\/Kazbegi";
$areanames{en}->{995346} = "Dusheti";
$areanames{en}->{995347} = "Djava";
$areanames{en}->{995348} = "Tianeti";
$areanames{en}->{995349} = "Akhmeta";
$areanames{en}->{995350} = "Telavi";
$areanames{en}->{995351} = "Sagaredjo";
$areanames{en}->{995352} = "Kvareli";
$areanames{en}->{995353} = "Gurdjaani";
$areanames{en}->{995354} = "Lagodekhi";
$areanames{en}->{995355} = "Signagi";
$areanames{en}->{995356} = "DedoplisTskaro";
$areanames{en}->{995357} = "Marneuli";
$areanames{en}->{995358} = "Bolnisi";
$areanames{en}->{995359} = "TetriTskaro";
$areanames{en}->{995360} = "Dmanisi";
$areanames{en}->{995361} = "Ninotsminda";
$areanames{en}->{995362} = "Akhalkalaki";
$areanames{en}->{995363} = "Tsalka";
$areanames{en}->{995364} = "Aspindza";
$areanames{en}->{995365} = "Akhaltsikhe";
$areanames{en}->{995366} = "Adigeni";
$areanames{en}->{995367} = "Bordjomi";
$areanames{en}->{995368} = "Khashuri";
$areanames{en}->{995369} = "Kareli";
$areanames{en}->{995370} = "Gori";
$areanames{en}->{995371} = "Kaspi";
$areanames{en}->{995372} = "Gardabani";
$areanames{en}->{995373} = "Mtskheta";
$areanames{en}->{995374} = "Tigvi";
$areanames{en}->{995410} = "Mestia";
$areanames{en}->{995411} = "Samtredia";
$areanames{en}->{995412} = "Abasha";
$areanames{en}->{995413} = "Senaki";
$areanames{en}->{995414} = "Xobi";
$areanames{en}->{995415} = "Zugdidi";
$areanames{en}->{995416} = "Tsalendjikha";
$areanames{en}->{995417} = "Chkhorotskhu";
$areanames{en}->{995418} = "Martvili";
$areanames{en}->{995419} = "Choxatauri";
$areanames{en}->{995422} = "Batumi";
$areanames{en}->{995423} = "Xulo";
$areanames{en}->{995424} = "Shuaxevi";
$areanames{en}->{995425} = "Qeda";
$areanames{en}->{995426} = "Kobuleti";
$areanames{en}->{995427} = "Xelvachauri";
$areanames{en}->{995431} = "Kutaisi";
$areanames{en}->{995432} = "Vani";
$areanames{en}->{995433} = "Kharagauli";
$areanames{en}->{995434} = "Bagdati";
$areanames{en}->{995435} = "Sachkhere";
$areanames{en}->{995436} = "Tskaltubo";
$areanames{en}->{995437} = "Lentekhi";
$areanames{en}->{995439} = "Ambrolauri";
$areanames{en}->{995442} = "Sukhumi";
$areanames{en}->{995443} = "Gagra";
$areanames{en}->{995444} = "Gudauta";
$areanames{en}->{995445} = "Ochamchire";
$areanames{en}->{995446} = "Tkvarcheli";
$areanames{en}->{995447} = "Gali";
$areanames{en}->{995448} = "Gulripshi";
$areanames{en}->{995472} = "Tsageri";
$areanames{en}->{995473} = "Oni";
$areanames{en}->{995479} = "Chiatura";
$areanames{en}->{995491} = "Terdjola";
$areanames{en}->{995492} = "Zestafoni";
$areanames{en}->{995493} = "Poti";
$areanames{en}->{995494} = "lanchxuti";
$areanames{en}->{995495} = "Khoni";
$areanames{en}->{995496} = "Ozurgeti";
$areanames{en}->{995497} = "Tkibuli";

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