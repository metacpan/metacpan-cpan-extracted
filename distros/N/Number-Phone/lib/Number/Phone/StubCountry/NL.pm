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
package Number::Phone::StubCountry::NL;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200606132001;

my $formatters = [
                {
                  'format' => '$1',
                  'intl_format' => 'NA',
                  'leading_digits' => '
            1[238]|
            [34]
          ',
                  'pattern' => '(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'intl_format' => 'NA',
                  'leading_digits' => '14',
                  'pattern' => '(\\d{2})(\\d{3,4})'
                },
                {
                  'format' => '$1',
                  'intl_format' => 'NA',
                  'leading_digits' => '1',
                  'pattern' => '(\\d{6})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '[89]0',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{4,7})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '66',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{7})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '6',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{8})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            1[16-8]|
            2[259]|
            3[124]|
            4[17-9]|
            5[124679]
          ',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[1-57-9]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            1(?:
              [035]\\d|
              1[13-578]|
              6[124-8]|
              7[24]|
              8[0-467]
            )|
            2(?:
              [0346]\\d|
              2[2-46-9]|
              5[125]|
              9[479]
            )|
            3(?:
              [03568]\\d|
              1[3-8]|
              2[01]|
              4[1-8]
            )|
            4(?:
              [0356]\\d|
              1[1-368]|
              7[58]|
              8[15-8]|
              9[23579]
            )|
            5(?:
              [0358]\\d|
              [19][1-9]|
              2[1-57-9]|
              4[13-8]|
              6[126]|
              7[0-3578]
            )|
            7\\d\\d
          )\\d{6}
        ',
                'geographic' => '
          (?:
            1(?:
              [035]\\d|
              1[13-578]|
              6[124-8]|
              7[24]|
              8[0-467]
            )|
            2(?:
              [0346]\\d|
              2[2-46-9]|
              5[125]|
              9[479]
            )|
            3(?:
              [03568]\\d|
              1[3-8]|
              2[01]|
              4[1-8]
            )|
            4(?:
              [0356]\\d|
              1[1-368]|
              7[58]|
              8[15-8]|
              9[23579]
            )|
            5(?:
              [0358]\\d|
              [19][1-9]|
              2[1-57-9]|
              4[13-8]|
              6[126]|
              7[0-3578]
            )|
            7\\d\\d
          )\\d{6}
        ',
                'mobile' => '6[1-58]\\d{7}',
                'pager' => '66\\d{7}',
                'personal_number' => '',
                'specialrate' => '(90[069]\\d{4,7})|(
          140(?:
            1[035]|
            2[0346]|
            3[03568]|
            4[0356]|
            5[0358]|
            8[458]
          )|
          (?:
            140(?:
              1[16-8]|
              2[259]|
              3[124]|
              4[17-9]|
              5[124679]|
              7
            )|
            8[478]\\d{6}
          )\\d
        )',
                'toll_free' => '800\\d{4,7}',
                'voip' => '
          (?:
            85|
            91
          )\\d{7}
        '
              };
my %areanames = ();
$areanames{nl}->{3110} = "Rotterdam";
$areanames{nl}->{31111} = "Zierikzee";
$areanames{nl}->{31113} = "Goes";
$areanames{nl}->{31114} = "Hulst";
$areanames{nl}->{31115} = "Terneuzen";
$areanames{nl}->{31117} = "Oostburg";
$areanames{nl}->{31118} = "Middelburg";
$areanames{nl}->{3113} = "Tilburg";
$areanames{nl}->{3115} = "Delft";
$areanames{nl}->{31161} = "Rijen";
$areanames{nl}->{31162} = "Oosterhout";
$areanames{nl}->{31164} = "Bergen\ op\ Zoom";
$areanames{nl}->{31165} = "Roosendaal";
$areanames{nl}->{31166} = "Tholen";
$areanames{nl}->{31167} = "Steenbergen";
$areanames{nl}->{31168} = "Zevenbergen";
$areanames{nl}->{31172} = "Alphen\ aan\ den\ Rijn";
$areanames{nl}->{31174} = "Naaldwijk";
$areanames{nl}->{31180} = "Barendrecht";
$areanames{nl}->{31181} = "Spijkenisse";
$areanames{nl}->{31182} = "Gouda";
$areanames{nl}->{31183} = "Gorinchem";
$areanames{nl}->{31184} = "Sliedrecht";
$areanames{nl}->{31186} = "Oud\-Beijerland";
$areanames{nl}->{31187} = "Middelharnis";
$areanames{nl}->{3120} = "Amsterdam";
$areanames{nl}->{31222} = "Den\ Burg";
$areanames{nl}->{31223} = "Den\ Helder";
$areanames{nl}->{31224} = "Schagen";
$areanames{nl}->{31226} = "Noord\ Scharwoude";
$areanames{nl}->{31227} = "Medemblik";
$areanames{nl}->{31228} = "Enkhuizen";
$areanames{nl}->{31229} = "Hoorn";
$areanames{nl}->{3123} = "Haarlem";
$areanames{nl}->{3124} = "Nijmegen";
$areanames{nl}->{31251} = "Beverwijk";
$areanames{nl}->{31252} = "Nieuw\-Vennep";
$areanames{nl}->{31255} = "IJmuiden";
$areanames{nl}->{3126} = "Arnhem";
$areanames{nl}->{31294} = "Weesp";
$areanames{nl}->{31297} = "Aalsmeer";
$areanames{nl}->{31299} = "Purmerend";
$areanames{nl}->{3130} = "Utrecht";
$areanames{nl}->{31313} = "Dieren";
$areanames{nl}->{31314} = "Doetinchem";
$areanames{nl}->{31315} = "Terborg";
$areanames{nl}->{31316} = "Zevenaar";
$areanames{nl}->{31317} = "Wageningen";
$areanames{nl}->{31318} = "Veenendaal";
$areanames{nl}->{31320} = "Lelystad";
$areanames{nl}->{31321} = "Dronten";
$areanames{nl}->{3133} = "Amersfoort";
$areanames{nl}->{31341} = "Harderwijk";
$areanames{nl}->{31342} = "Barneveld";
$areanames{nl}->{31343} = "Driebergen\-Rijsenburg";
$areanames{nl}->{31344} = "Tiel";
$areanames{nl}->{31345} = "Culemborg";
$areanames{nl}->{31346} = "Maarssen";
$areanames{nl}->{31347} = "Vianen";
$areanames{nl}->{31348} = "Woerden";
$areanames{nl}->{3135} = "Hilversum";
$areanames{nl}->{3136} = "Almere";
$areanames{nl}->{3138} = "Zwolle";
$areanames{nl}->{3140} = "Eindhoven";
$areanames{nl}->{31411} = "Boxtel";
$areanames{nl}->{31412} = "Oss";
$areanames{nl}->{31413} = "Uden";
$areanames{nl}->{31416} = "Waalwijk";
$areanames{nl}->{31418} = "Zaltbommel";
$areanames{nl}->{3143} = "Maastricht";
$areanames{nl}->{3145} = "Heerlen";
$areanames{nl}->{3146} = "Sittard";
$areanames{nl}->{31475} = "Roermond";
$areanames{nl}->{31478} = "Venray";
$areanames{nl}->{31481} = "Elst";
$areanames{nl}->{31485} = "Cuyk";
$areanames{nl}->{31486} = "Schaijk";
$areanames{nl}->{31487} = "Druten";
$areanames{nl}->{31488} = "Zetten";
$areanames{nl}->{31492} = "Helmond";
$areanames{nl}->{31493} = "Deurne";
$areanames{nl}->{31495} = "Weert";
$areanames{nl}->{31497} = "Eersel";
$areanames{nl}->{31499} = "Best";
$areanames{nl}->{3150} = "Groningen";
$areanames{nl}->{31511} = "Veenwouden";
$areanames{nl}->{31512} = "Drachten";
$areanames{nl}->{31513} = "Heerenveen";
$areanames{nl}->{31514} = "Lemmer";
$areanames{nl}->{31515} = "Sneek";
$areanames{nl}->{31516} = "Oosterwolde";
$areanames{nl}->{31517} = "Harlingen";
$areanames{nl}->{31518} = "St\.\ Annaparochie";
$areanames{nl}->{31519} = "Dokkum";
$areanames{nl}->{31521} = "Steenwijk";
$areanames{nl}->{31522} = "Meppel";
$areanames{nl}->{31523} = "Hardenberg";
$areanames{nl}->{31524} = "Coevorden";
$areanames{nl}->{31525} = "Elburg";
$areanames{nl}->{31527} = "Emmeloord";
$areanames{nl}->{31528} = "Hoogeveen";
$areanames{nl}->{31529} = "Dalfsen";
$areanames{nl}->{3153} = "Enschede";
$areanames{nl}->{31541} = "Oldenzaal";
$areanames{nl}->{31543} = "Winterswijk";
$areanames{nl}->{31544} = "Lichtenvoorde";
$areanames{nl}->{31545} = "Eibergen";
$areanames{nl}->{31546} = "Almelo";
$areanames{nl}->{31547} = "Goor";
$areanames{nl}->{31548} = "Rijssen";
$areanames{nl}->{3155} = "Apeldoorn";
$areanames{nl}->{31561} = "Wolvega";
$areanames{nl}->{31562} = "West\-Terschelling";
$areanames{nl}->{31566} = "Grou";
$areanames{nl}->{31570} = "Deventer";
$areanames{nl}->{31571} = "Twello";
$areanames{nl}->{31572} = "Raalte";
$areanames{nl}->{31573} = "Lochem";
$areanames{nl}->{31575} = "Zutphen";
$areanames{nl}->{31577} = "Elspeet";
$areanames{nl}->{31578} = "Epe";
$areanames{nl}->{3158} = "Leeuwarden";
$areanames{nl}->{31591} = "Emmen";
$areanames{nl}->{31592} = "Assen";
$areanames{nl}->{31593} = "Beilen";
$areanames{nl}->{31594} = "Zuidhorn";
$areanames{nl}->{31595} = "Warffum";
$areanames{nl}->{31596} = "Delfzijl";
$areanames{nl}->{31597} = "Winschoten";
$areanames{nl}->{31598} = "Veendam";
$areanames{nl}->{31599} = "Stadskanaal";
$areanames{nl}->{3170} = "Den\ Haag";
$areanames{nl}->{3171} = "Leiden";
$areanames{nl}->{3172} = "Alkmaar";
$areanames{nl}->{3173} = "\'s\-Hertogenbosch";
$areanames{nl}->{3174} = "Hengelo";
$areanames{nl}->{3175} = "Zaandam";
$areanames{nl}->{3176} = "Breda";
$areanames{nl}->{3177} = "Venlo";
$areanames{nl}->{3178} = "Dordrecht";
$areanames{nl}->{3179} = "Zoetermeer";
$areanames{en}->{3110} = "Rotterdam";
$areanames{en}->{31111} = "Zierikzee";
$areanames{en}->{31113} = "Goes";
$areanames{en}->{31114} = "Hulst";
$areanames{en}->{31115} = "Terneuzen";
$areanames{en}->{31117} = "Oostburg";
$areanames{en}->{31118} = "Middelburg";
$areanames{en}->{3113} = "Tilburg";
$areanames{en}->{3115} = "Delft";
$areanames{en}->{31161} = "Rijen";
$areanames{en}->{31162} = "Oosterhout";
$areanames{en}->{31164} = "Bergen\ op\ Zoom";
$areanames{en}->{31165} = "Roosendaal";
$areanames{en}->{31166} = "Tholen";
$areanames{en}->{31167} = "Steenbergen";
$areanames{en}->{31168} = "Zevenbergen";
$areanames{en}->{31172} = "Alphen\ aan\ den\ Rijn";
$areanames{en}->{31174} = "Naaldwijk";
$areanames{en}->{31180} = "Barendrecht";
$areanames{en}->{31181} = "Spijkenisse";
$areanames{en}->{31182} = "Gouda";
$areanames{en}->{31183} = "Gorinchem";
$areanames{en}->{31184} = "Sliedrecht";
$areanames{en}->{31186} = "Oud\-Beijerland";
$areanames{en}->{31187} = "Middelharnis";
$areanames{en}->{3120} = "Amsterdam";
$areanames{en}->{31222} = "Den\ Burg";
$areanames{en}->{31223} = "Den\ Helder";
$areanames{en}->{31224} = "Schagen";
$areanames{en}->{31226} = "Noord\ Scharwoude";
$areanames{en}->{31227} = "Medemblik";
$areanames{en}->{31228} = "Enkhuizen";
$areanames{en}->{31229} = "Horn";
$areanames{en}->{3123} = "Haarlem";
$areanames{en}->{3124} = "Nijmegen";
$areanames{en}->{31251} = "Beverwijk";
$areanames{en}->{31252} = "Nieuw\-Vennep";
$areanames{en}->{31255} = "IJmuiden";
$areanames{en}->{3126} = "Arnhem";
$areanames{en}->{31294} = "Weesp";
$areanames{en}->{31297} = "Aalsmeer";
$areanames{en}->{31299} = "Purmerend";
$areanames{en}->{3130} = "Utrecht";
$areanames{en}->{31313} = "Dieren";
$areanames{en}->{31314} = "Doetinchem";
$areanames{en}->{31315} = "Terborg";
$areanames{en}->{31316} = "Zevenaar";
$areanames{en}->{31317} = "Wageningen";
$areanames{en}->{31318} = "Veenendaal";
$areanames{en}->{31320} = "Lelystad";
$areanames{en}->{31321} = "Dronten";
$areanames{en}->{3133} = "Amersfoort";
$areanames{en}->{31341} = "Harderwijk";
$areanames{en}->{31342} = "Barneveld";
$areanames{en}->{31343} = "Driebergen\-Rijsenburg";
$areanames{en}->{31344} = "Tiel";
$areanames{en}->{31345} = "Culemborg";
$areanames{en}->{31346} = "Maarssen";
$areanames{en}->{31347} = "Vianen";
$areanames{en}->{31348} = "Woerden";
$areanames{en}->{3135} = "Hilversum";
$areanames{en}->{3136} = "Almere";
$areanames{en}->{3138} = "Zwolle";
$areanames{en}->{3140} = "Eindhoven";
$areanames{en}->{31411} = "Boxtel";
$areanames{en}->{31412} = "Oss";
$areanames{en}->{31413} = "Uden";
$areanames{en}->{31416} = "Waalwijk";
$areanames{en}->{31418} = "Zaltbommel";
$areanames{en}->{3143} = "Maastricht";
$areanames{en}->{3145} = "Heerlen";
$areanames{en}->{3146} = "Sittard";
$areanames{en}->{31475} = "Roermond";
$areanames{en}->{31478} = "Venray";
$areanames{en}->{31481} = "Bemmel";
$areanames{en}->{31485} = "Cuyk";
$areanames{en}->{31486} = "Grave";
$areanames{en}->{31487} = "Druten";
$areanames{en}->{31488} = "Zetten";
$areanames{en}->{31492} = "Helmond";
$areanames{en}->{31493} = "Deurne";
$areanames{en}->{31495} = "Weert";
$areanames{en}->{31497} = "Eersel";
$areanames{en}->{31499} = "Best";
$areanames{en}->{3150} = "Groningen";
$areanames{en}->{31511} = "Veenwouden";
$areanames{en}->{31512} = "Drachten";
$areanames{en}->{31513} = "Heerenveen";
$areanames{en}->{31514} = "Lemmer";
$areanames{en}->{31515} = "Sneek";
$areanames{en}->{31516} = "Oosterwolde";
$areanames{en}->{31517} = "Harlingen";
$areanames{en}->{31518} = "St\.\ Annaparochie";
$areanames{en}->{31519} = "Dokkum";
$areanames{en}->{31521} = "Steenwijk";
$areanames{en}->{31522} = "Meppel";
$areanames{en}->{31523} = "Hardenberg";
$areanames{en}->{31524} = "Coevorden";
$areanames{en}->{31525} = "Elburg";
$areanames{en}->{31527} = "Emmeloord";
$areanames{en}->{31528} = "Hoogeveen";
$areanames{en}->{31529} = "Dalfsen";
$areanames{en}->{3153} = "Enschede";
$areanames{en}->{31541} = "Oldenzaal";
$areanames{en}->{31543} = "Winterswijk";
$areanames{en}->{31544} = "Lichtenvoorde";
$areanames{en}->{31545} = "Eibergen";
$areanames{en}->{31546} = "Almelo";
$areanames{en}->{31547} = "Goor";
$areanames{en}->{31548} = "Rijssen";
$areanames{en}->{3155} = "Apeldoorn";
$areanames{en}->{31561} = "Wolvega";
$areanames{en}->{31562} = "West\-Terschelling";
$areanames{en}->{31566} = "Grou";
$areanames{en}->{31570} = "Deventer";
$areanames{en}->{31571} = "Twello";
$areanames{en}->{31572} = "Raalte";
$areanames{en}->{31573} = "Lochem";
$areanames{en}->{31575} = "Zutphen";
$areanames{en}->{31577} = "Elspeet";
$areanames{en}->{31578} = "Epe";
$areanames{en}->{3158} = "Leeuwarden";
$areanames{en}->{31591} = "Emmen";
$areanames{en}->{31592} = "Assen";
$areanames{en}->{31593} = "Beilen";
$areanames{en}->{31594} = "Zuidhorn";
$areanames{en}->{31595} = "Warffum";
$areanames{en}->{31596} = "Delfzijl";
$areanames{en}->{31597} = "Winschoten";
$areanames{en}->{31598} = "Veendam";
$areanames{en}->{31599} = "Stadskanaal";
$areanames{en}->{3170} = "The\ Hague";
$areanames{en}->{3171} = "Leiden";
$areanames{en}->{3172} = "Alkmaar";
$areanames{en}->{3173} = "\'s\-Hertogenbosch";
$areanames{en}->{3174} = "Hengelo";
$areanames{en}->{3175} = "Zaandam";
$areanames{en}->{3176} = "Breda";
$areanames{en}->{3177} = "Venlo";
$areanames{en}->{3178} = "Dordrecht";
$areanames{en}->{3179} = "Zoetermeer";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+31|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;