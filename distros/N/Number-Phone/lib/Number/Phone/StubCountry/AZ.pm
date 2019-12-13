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
package Number::Phone::StubCountry::AZ;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20191211212259;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'intl_format' => 'NA',
                  'leading_digits' => '[1-9]',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '90',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{2})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            [12]|
            365(?:
              [0-46-9]|
              5[0-35-9]
            )
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[3-9]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2})(\\d{2})'
                }
              ];

my $validators = {
                'fixed_line' => '
          365(?:
            [0-46-9]\\d|
            5[0-35-9]
          )\\d{4}|
          (?:
            1[28]\\d|
            2(?:
              [045]2|
              1[24]|
              2[2-4]|
              33|
              6[23]
            )
          )\\d{6}
        ',
                'geographic' => '
          365(?:
            [0-46-9]\\d|
            5[0-35-9]
          )\\d{4}|
          (?:
            1[28]\\d|
            2(?:
              [045]2|
              1[24]|
              2[2-4]|
              33|
              6[23]
            )
          )\\d{6}
        ',
                'mobile' => '
          (?:
            36554|
            99[2-9]\\d\\d
          )\\d{4}|
          (?:
            4[04]|
            5[015]|
            60|
            7[07]
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(900200\\d{3})',
                'toll_free' => '88\\d{7}',
                'voip' => ''
              };
my %areanames = ();
$areanames{en}->{99412} = "Baku";
$areanames{en}->{99418} = "Sumgayit";
$areanames{en}->{9942020} = "Barda";
$areanames{en}->{9942021} = "Ujar";
$areanames{en}->{9942022} = "Agsu";
$areanames{en}->{9942023} = "Agdash";
$areanames{en}->{9942024} = "Gobustan";
$areanames{en}->{9942025} = "Kurdamir";
$areanames{en}->{9942026} = "Shamakhi";
$areanames{en}->{9942027} = "Goychay";
$areanames{en}->{9942028} = "Ismayilli";
$areanames{en}->{9942029} = "Zardab";
$areanames{en}->{9942120} = "Hajigabul";
$areanames{en}->{9942121} = "Shirvan";
$areanames{en}->{9942122} = "Beylagan";
$areanames{en}->{9942123} = "Sabirabad";
$areanames{en}->{9942124} = "Imishli";
$areanames{en}->{9942125} = "Salyan";
$areanames{en}->{9942126} = "Neftchala";
$areanames{en}->{9942127} = "Agjabadi";
$areanames{en}->{9942128} = "Saatli";
$areanames{en}->{99421428} = "Hajigabul";
$areanames{en}->{9942220} = "Goygol";
$areanames{en}->{9942221} = "Dashkasan";
$areanames{en}->{9942222} = "Agstafa";
$areanames{en}->{9942223} = "Tartar";
$areanames{en}->{9942224} = "Goranboy";
$areanames{en}->{9942225} = "Ganja";
$areanames{en}->{9942226} = "Ganja";
$areanames{en}->{9942227} = "Samukh";
$areanames{en}->{9942229} = "Gazakh";
$areanames{en}->{9942230} = "Shamkir";
$areanames{en}->{9942231} = "Tovuz";
$areanames{en}->{9942232} = "Gadabay";
$areanames{en}->{9942233} = "Yevlakh";
$areanames{en}->{9942235} = "Naftalan";
$areanames{en}->{99422428} = "Agstafa\/Ganja\/Yevlakh";
$areanames{en}->{9942330} = "Siyazan";
$areanames{en}->{9942331} = "Khizi";
$areanames{en}->{9942332} = "Khachmaz";
$areanames{en}->{9942333} = "Guba";
$areanames{en}->{9942335} = "Shabran";
$areanames{en}->{9942338} = "Gusar";
$areanames{en}->{9942420} = "Gabala";
$areanames{en}->{9942421} = "Oguz";
$areanames{en}->{9942422} = "Zagatala";
$areanames{en}->{9942424} = "Shaki";
$areanames{en}->{9942425} = "Gakh";
$areanames{en}->{9942427} = "Mingachevir";
$areanames{en}->{9942429} = "Balakan";
$areanames{en}->{9942520} = "Yardimli";
$areanames{en}->{9942521} = "Masalli";
$areanames{en}->{9942522} = "Astara";
$areanames{en}->{9942524} = "Jalilabad";
$areanames{en}->{9942525} = "Lankaran";
$areanames{en}->{9942527} = "Lerik";
$areanames{en}->{9942529} = "Bilasuvar";
$areanames{en}->{9942620} = "Khojali";
$areanames{en}->{9942621} = "Lachin";
$areanames{en}->{9942622} = "Khankandi";
$areanames{en}->{9942623} = "Qubadli";
$areanames{en}->{9942624} = "Askaran";
$areanames{en}->{9942625} = "Zangilan";
$areanames{en}->{9942626} = "Shusha";
$areanames{en}->{9942627} = "Kalbajar";
$areanames{en}->{9942628} = "Agdara";
$areanames{en}->{9942629} = "Khojavand";
$areanames{en}->{9942630} = "Hadrut";
$areanames{en}->{9942631} = "Fuzuli";
$areanames{en}->{9942632} = "Agdam";
$areanames{en}->{9942638} = "Jabrayil";
$areanames{en}->{99436541} = "Babek";
$areanames{en}->{99436542} = "Sharur";
$areanames{en}->{99436543} = "Shahbuz";
$areanames{en}->{99436544} = "Nakhchivan\ city";
$areanames{en}->{99436546} = "Julfa";
$areanames{en}->{99436547} = "Ordubad";
$areanames{en}->{99436548} = "Kangarli";
$areanames{en}->{99436549} = "Sadarak";
$areanames{en}->{99436550} = "Nakhchivan\ city";
$areanames{en}->{99436552} = "Sharur";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+994|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;