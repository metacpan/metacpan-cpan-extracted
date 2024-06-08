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
package Number::Phone::StubCountry::KY;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20240607153921;

my $formatters = [
                {
                  'format' => '$1-$2',
                  'leading_digits' => '310',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1-$2',
                  'intl_format' => 'NA',
                  'leading_digits' => '
            [24-9]|
            3(?:
              [02-9]|
              1[1-9]
            )
          ',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '($1) $2-$3',
                  'intl_format' => '$1-$2-$3',
                  'leading_digits' => '[2-9]',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          345(?:
            2(?:
              22|
              3[23]|
              44|
              66
            )|
            333|
            444|
            6(?:
              23|
              38|
              40
            )|
            7(?:
              30|
              4[35-79]|
              6[6-9]|
              77
            )|
            8(?:
              00|
              1[45]|
              [48]8
            )|
            9(?:
              14|
              4[035-9]
            )
          )\\d{4}
        ',
                'geographic' => '
          345(?:
            2(?:
              22|
              3[23]|
              44|
              66
            )|
            333|
            444|
            6(?:
              23|
              38|
              40
            )|
            7(?:
              30|
              4[35-79]|
              6[6-9]|
              77
            )|
            8(?:
              00|
              1[45]|
              [48]8
            )|
            9(?:
              14|
              4[035-9]
            )
          )\\d{4}
        ',
                'mobile' => '
          345(?:
            32[1-9]|
            42[0-4]|
            5(?:
              1[67]|
              2[5-79]|
              4[6-9]|
              50|
              76
            )|
            649|
            82[56]|
            9(?:
              1[679]|
              2[2-9]|
              3[06-9]|
              90
            )
          )\\d{4}
        ',
                'pager' => '345849\\d{4}',
                'personal_number' => '
          52(?:
            3(?:
              [2-46-9][02-9]\\d|
              5(?:
                [02-46-9]\\d|
                5[0-46-9]
              )
            )|
            4(?:
              [2-478][02-9]\\d|
              5(?:
                [034]\\d|
                2[024-9]|
                5[0-46-9]
              )|
              6(?:
                0[1-9]|
                [2-9]\\d
              )|
              9(?:
                [05-9]\\d|
                2[0-5]|
                49
              )
            )
          )\\d{4}|
          52[34][2-9]1[02-9]\\d{4}|
          5(?:
            00|
            2[125-9]|
            33|
            44|
            66|
            77|
            88
          )[2-9]\\d{6}
        ',
                'specialrate' => '(
          (?:
            345976|
            900[2-9]\\d\\d
          )\\d{4}
        )',
                'toll_free' => '
          8(?:
            00|
            33|
            44|
            55|
            66|
            77|
            88
          )[2-9]\\d{6}
        ',
                'voip' => ''
              };
use Number::Phone::NANP::Data;
sub areaname {
# uncoverable subroutine - no data for most NANP countries
                            # uncoverable statement
Number::Phone::NANP::Data::_areaname('1'.shift()->{number}); }
my $timezones = {
               '' => [
                       'America/Adak',
                       'America/Anchorage',
                       'America/Anguilla',
                       'America/Antigua',
                       'America/Barbados',
                       'America/Boise',
                       'America/Cayman',
                       'America/Chicago',
                       'America/Denver',
                       'America/Dominica',
                       'America/Edmonton',
                       'America/Fort_Nelson',
                       'America/Grand_Turk',
                       'America/Grenada',
                       'America/Halifax',
                       'America/Jamaica',
                       'America/Juneau',
                       'America/Los_Angeles',
                       'America/Lower_Princes',
                       'America/Montserrat',
                       'America/Nassau',
                       'America/New_York',
                       'America/North_Dakota/Center',
                       'America/Phoenix',
                       'America/Port_of_Spain',
                       'America/Puerto_Rico',
                       'America/Regina',
                       'America/Santo_Domingo',
                       'America/St_Johns',
                       'America/St_Kitts',
                       'America/St_Lucia',
                       'America/St_Thomas',
                       'America/St_Vincent',
                       'America/Toronto',
                       'America/Tortola',
                       'America/Vancouver',
                       'America/Winnipeg',
                       'Atlantic/Bermuda',
                       'Pacific/Guam',
                       'Pacific/Honolulu',
                       'Pacific/Pago_Pago',
                       'Pacific/Saipan'
                     ],
               '201' => [
                          'America/New_York'
                        ],
               '202' => [
                          'America/New_York'
                        ],
               '203' => [
                          'America/New_York'
                        ],
               '204' => [
                          'America/Winnipeg'
                        ],
               '205' => [
                          'America/Chicago'
                        ],
               '206' => [
                          'America/Los_Angeles'
                        ],
               '207' => [
                          'America/New_York'
                        ],
               '2082' => [
                           'America/Boise',
                           'America/Los_Angeles'
                         ],
               '208201' => [
                             'America/Denver'
                           ],
               '208215' => [
                             'America/Los_Angeles'
                           ],
               '208221' => [
                             'America/Denver'
                           ],
               '208226' => [
                             'America/Denver'
                           ],
               '208227' => [
                             'America/Denver'
                           ],
               '208228' => [
                             'America/Denver'
                           ],
               '20823' => [
                            'America/Denver'
                          ],
               '208241' => [
                             'America/Denver'
                           ],
               '208242' => [
                             'America/Denver'
                           ],
               '208245' => [
                             'America/Los_Angeles'
                           ],
               '208249' => [
                             'America/Denver'
                           ],
               '208250' => [
                             'America/Denver'
                           ],
               '208251' => [
                             'America/Denver'
                           ],
               '208253' => [
                             'America/Denver'
                           ],
               '208254' => [
                             'America/Denver'
                           ],
               '208255' => [
                             'America/Los_Angeles'
                           ],
               '208258' => [
                             'America/Denver'
                           ],
               '208262' => [
                             'America/Los_Angeles'
                           ],
               '208263' => [
                             'America/Los_Angeles'
                           ],
               '208265' => [
                             'America/Los_Angeles'
                           ],
               '208267' => [
                             'America/Los_Angeles'
                           ],
               '208278' => [
                             'America/Denver'
                           ],
               '20828' => [
                            'America/Denver'
                          ],
               '208290' => [
                             'America/Los_Angeles'
                           ],
               '208292' => [
                             'America/Los_Angeles'
                           ],
               '208297' => [
                             'America/Denver'
                           ],
               '2083' => [
                           'America/Denver'
                         ],
               '20830' => [
                            'America/Boise',
                            'America/Los_Angeles'
                          ],
               '208304' => [
                             'America/Los_Angeles'
                           ],
               '208305' => [
                             'America/Los_Angeles'
                           ],
               '20831' => [
                            'America/Boise',
                            'America/Los_Angeles'
                          ],
               '208320' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208325' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208328' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208329' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208330' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208332' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208335' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208341' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208347' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208348' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208349' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208355' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208358' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208361' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208363' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208364' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208368' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208369' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208370' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208372' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208374' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208379' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208380' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208386' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208387' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208393' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208394' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208395' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208396' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208399' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208400' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208401' => [
                             'America/Denver'
                           ],
               '208402' => [
                             'America/Denver'
                           ],
               '208403' => [
                             'America/Denver'
                           ],
               '208404' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208405' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208406' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208407' => [
                             'America/Denver'
                           ],
               '208408' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208409' => [
                             'America/Denver'
                           ],
               '20841' => [
                            'America/Boise',
                            'America/Los_Angeles'
                          ],
               '208412' => [
                             'America/Denver'
                           ],
               '208414' => [
                             'America/Denver'
                           ],
               '208419' => [
                             'America/Denver'
                           ],
               '20842' => [
                            'America/Denver'
                          ],
               '208421' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208427' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208428' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208430' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208431' => [
                             'America/Denver'
                           ],
               '208432' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208433' => [
                             'America/Denver'
                           ],
               '208434' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208435' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208436' => [
                             'America/Denver'
                           ],
               '208437' => [
                             'America/Los_Angeles'
                           ],
               '208438' => [
                             'America/Denver'
                           ],
               '208439' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208440' => [
                             'America/Denver'
                           ],
               '208441' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208442' => [
                             'America/Denver'
                           ],
               '208443' => [
                             'America/Los_Angeles'
                           ],
               '208444' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208445' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208446' => [
                             'America/Los_Angeles'
                           ],
               '208447' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208448' => [
                             'America/Los_Angeles'
                           ],
               '208449' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208450' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208451' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208452' => [
                             'America/Denver'
                           ],
               '208453' => [
                             'America/Denver'
                           ],
               '208454' => [
                             'America/Denver'
                           ],
               '208455' => [
                             'America/Denver'
                           ],
               '208456' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208457' => [
                             'America/Los_Angeles'
                           ],
               '208458' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208459' => [
                             'America/Denver'
                           ],
               '20846' => [
                            'America/Denver'
                          ],
               '208460' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208464' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208469' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208470' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208471' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208472' => [
                             'America/Denver'
                           ],
               '208473' => [
                             'America/Denver'
                           ],
               '208474' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208475' => [
                             'America/Denver'
                           ],
               '208476' => [
                             'America/Los_Angeles'
                           ],
               '208477' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208478' => [
                             'America/Denver'
                           ],
               '208479' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '20848' => [
                            'America/Boise',
                            'America/Los_Angeles'
                          ],
               '208484' => [
                             'America/Denver'
                           ],
               '208489' => [
                             'America/Denver'
                           ],
               '20849' => [
                            'America/Boise',
                            'America/Los_Angeles'
                          ],
               '208495' => [
                             'America/Denver'
                           ],
               '2085' => [
                           'America/Boise',
                           'America/Los_Angeles'
                         ],
               '208505' => [
                             'America/Denver'
                           ],
               '208514' => [
                             'America/Denver'
                           ],
               '208515' => [
                             'America/Denver'
                           ],
               '20852' => [
                            'America/Denver'
                          ],
               '208535' => [
                             'America/Denver'
                           ],
               '208536' => [
                             'America/Denver'
                           ],
               '208538' => [
                             'America/Denver'
                           ],
               '208539' => [
                             'America/Denver'
                           ],
               '208542' => [
                             'America/Denver'
                           ],
               '208543' => [
                             'America/Denver'
                           ],
               '208546' => [
                             'America/Denver'
                           ],
               '208547' => [
                             'America/Denver'
                           ],
               '208549' => [
                             'America/Denver'
                           ],
               '208552' => [
                             'America/Denver'
                           ],
               '208556' => [
                             'America/Los_Angeles'
                           ],
               '208557' => [
                             'America/Denver'
                           ],
               '208558' => [
                             'America/Denver'
                           ],
               '208559' => [
                             'America/Denver'
                           ],
               '208562' => [
                             'America/Denver'
                           ],
               '208569' => [
                             'America/Denver'
                           ],
               '208570' => [
                             'America/Denver'
                           ],
               '208571' => [
                             'America/Denver'
                           ],
               '208573' => [
                             'America/Denver'
                           ],
               '208577' => [
                             'America/Denver'
                           ],
               '208578' => [
                             'America/Denver'
                           ],
               '208585' => [
                             'America/Denver'
                           ],
               '208587' => [
                             'America/Denver'
                           ],
               '208588' => [
                             'America/Denver'
                           ],
               '208589' => [
                             'America/Denver'
                           ],
               '208595' => [
                             'America/Denver'
                           ],
               '208596' => [
                             'America/Los_Angeles'
                           ],
               '2086' => [
                           'America/Boise',
                           'America/Los_Angeles'
                         ],
               '208602' => [
                             'America/Denver'
                           ],
               '208608' => [
                             'America/Denver'
                           ],
               '208610' => [
                             'America/Los_Angeles'
                           ],
               '208622' => [
                             'America/Denver'
                           ],
               '208623' => [
                             'America/Los_Angeles'
                           ],
               '208624' => [
                             'America/Denver'
                           ],
               '208625' => [
                             'America/Los_Angeles'
                           ],
               '208628' => [
                             'America/Denver'
                           ],
               '208629' => [
                             'America/Denver'
                           ],
               '208631' => [
                             'America/Denver'
                           ],
               '208634' => [
                             'America/Denver'
                           ],
               '208637' => [
                             'America/Denver'
                           ],
               '208639' => [
                             'America/Denver'
                           ],
               '208640' => [
                             'America/Los_Angeles'
                           ],
               '208642' => [
                             'America/Denver'
                           ],
               '208651' => [
                             'America/Los_Angeles'
                           ],
               '208652' => [
                             'America/Denver'
                           ],
               '208656' => [
                             'America/Denver'
                           ],
               '208658' => [
                             'America/Denver'
                           ],
               '208659' => [
                             'America/Los_Angeles'
                           ],
               '20866' => [
                            'America/Los_Angeles'
                          ],
               '208672' => [
                             'America/Denver'
                           ],
               '208676' => [
                             'America/Los_Angeles'
                           ],
               '208677' => [
                             'America/Denver'
                           ],
               '208678' => [
                             'America/Denver'
                           ],
               '208681' => [
                             'America/Denver'
                           ],
               '208682' => [
                             'America/Los_Angeles'
                           ],
               '208683' => [
                             'America/Los_Angeles'
                           ],
               '208684' => [
                             'America/Denver'
                           ],
               '208686' => [
                             'America/Los_Angeles'
                           ],
               '208687' => [
                             'America/Los_Angeles'
                           ],
               '208691' => [
                             'America/Los_Angeles'
                           ],
               '208695' => [
                             'America/Denver'
                           ],
               '208697' => [
                             'America/Denver'
                           ],
               '208699' => [
                             'America/Los_Angeles'
                           ],
               '208700' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208701' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208702' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208703' => [
                             'America/Denver'
                           ],
               '208704' => [
                             'America/Los_Angeles'
                           ],
               '208705' => [
                             'America/Denver'
                           ],
               '208706' => [
                             'America/Denver'
                           ],
               '208707' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208708' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208709' => [
                             'America/Denver'
                           ],
               '20871' => [
                            'America/Boise',
                            'America/Los_Angeles'
                          ],
               '208713' => [
                             'America/Denver'
                           ],
               '208716' => [
                             'America/Denver'
                           ],
               '20872' => [
                            'America/Denver'
                          ],
               '208721' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208723' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208728' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208729' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '20873' => [
                            'America/Denver'
                          ],
               '208730' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208738' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208739' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '20874' => [
                            'America/Boise',
                            'America/Los_Angeles'
                          ],
               '208743' => [
                             'America/Los_Angeles'
                           ],
               '208745' => [
                             'America/Denver'
                           ],
               '208746' => [
                             'America/Los_Angeles'
                           ],
               '20875' => [
                            'America/Boise',
                            'America/Los_Angeles'
                          ],
               '208755' => [
                             'America/Los_Angeles'
                           ],
               '208756' => [
                             'America/Denver'
                           ],
               '208760' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208761' => [
                             'America/Denver'
                           ],
               '208762' => [
                             'America/Los_Angeles'
                           ],
               '208763' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208764' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208765' => [
                             'America/Los_Angeles'
                           ],
               '208766' => [
                             'America/Denver'
                           ],
               '208767' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208768' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208769' => [
                             'America/Los_Angeles'
                           ],
               '20877' => [
                            'America/Boise',
                            'America/Los_Angeles'
                          ],
               '208772' => [
                             'America/Los_Angeles'
                           ],
               '208773' => [
                             'America/Los_Angeles'
                           ],
               '208777' => [
                             'America/Los_Angeles'
                           ],
               '208780' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208781' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208782' => [
                             'America/Denver'
                           ],
               '208783' => [
                             'America/Los_Angeles'
                           ],
               '208784' => [
                             'America/Los_Angeles'
                           ],
               '208785' => [
                             'America/Denver'
                           ],
               '208786' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208787' => [
                             'America/Denver'
                           ],
               '208788' => [
                             'America/Denver'
                           ],
               '208789' => [
                             'America/Denver'
                           ],
               '20879' => [
                            'America/Boise',
                            'America/Los_Angeles'
                          ],
               '208791' => [
                             'America/Los_Angeles'
                           ],
               '208794' => [
                             'America/Denver'
                           ],
               '208798' => [
                             'America/Los_Angeles'
                           ],
               '208799' => [
                             'America/Los_Angeles'
                           ],
               '20880' => [
                            'America/Boise',
                            'America/Los_Angeles'
                          ],
               '20881' => [
                            'America/Boise',
                            'America/Los_Angeles'
                          ],
               '208814' => [
                             'America/Denver'
                           ],
               '208818' => [
                             'America/Los_Angeles'
                           ],
               '208819' => [
                             'America/Los_Angeles'
                           ],
               '20882' => [
                            'America/Boise',
                            'America/Los_Angeles'
                          ],
               '20883' => [
                            'America/Boise',
                            'America/Los_Angeles'
                          ],
               '208830' => [
                             'America/Denver'
                           ],
               '208835' => [
                             'America/Los_Angeles'
                           ],
               '208837' => [
                             'America/Denver'
                           ],
               '20884' => [
                            'America/Boise',
                            'America/Los_Angeles'
                          ],
               '208841' => [
                             'America/Denver'
                           ],
               '208843' => [
                             'America/Los_Angeles'
                           ],
               '208846' => [
                             'America/Denver'
                           ],
               '208847' => [
                             'America/Denver'
                           ],
               '20885' => [
                            'America/Denver'
                          ],
               '208851' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208856' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208857' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208858' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '20886' => [
                            'America/Denver'
                          ],
               '208862' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208864' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208865' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208868' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208870' => [
                             'America/Denver'
                           ],
               '208871' => [
                             'America/Denver'
                           ],
               '208872' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208873' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208874' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208875' => [
                             'America/Los_Angeles'
                           ],
               '208876' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208877' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208878' => [
                             'America/Denver'
                           ],
               '208879' => [
                             'America/Denver'
                           ],
               '20888' => [
                            'America/Denver'
                          ],
               '208882' => [
                             'America/Los_Angeles'
                           ],
               '208883' => [
                             'America/Los_Angeles'
                           ],
               '208885' => [
                             'America/Los_Angeles'
                           ],
               '208889' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '20889' => [
                            'America/Denver'
                          ],
               '208892' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208893' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208894' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '208897' => [
                             'America/Boise',
                             'America/Los_Angeles'
                           ],
               '2089' => [
                           'America/Boise',
                           'America/Los_Angeles'
                         ],
               '208901' => [
                             'America/Denver'
                           ],
               '208904' => [
                             'America/Denver'
                           ],
               '208906' => [
                             'America/Denver'
                           ],
               '208908' => [
                             'America/Denver'
                           ],
               '208917' => [
                             'America/Denver'
                           ],
               '208918' => [
                             'America/Denver'
                           ],
               '208921' => [
                             'America/Denver'
                           ],
               '208922' => [
                             'America/Denver'
                           ],
               '208926' => [
                             'America/Los_Angeles'
                           ],
               '208928' => [
                             'America/Denver'
                           ],
               '208934' => [
                             'America/Denver'
                           ],
               '208935' => [
                             'America/Los_Angeles'
                           ],
               '208936' => [
                             'America/Denver'
                           ],
               '208938' => [
                             'America/Denver'
                           ],
               '208939' => [
                             'America/Denver'
                           ],
               '208941' => [
                             'America/Denver'
                           ],
               '208944' => [
                             'America/Denver'
                           ],
               '208946' => [
                             'America/Los_Angeles'
                           ],
               '208947' => [
                             'America/Denver'
                           ],
               '208949' => [
                             'America/Denver'
                           ],
               '208954' => [
                             'America/Denver'
                           ],
               '208955' => [
                             'America/Denver'
                           ],
               '208962' => [
                             'America/Los_Angeles'
                           ],
               '208964' => [
                             'America/Los_Angeles'
                           ],
               '208983' => [
                             'America/Los_Angeles'
                           ],
               '208989' => [
                             'America/Denver'
                           ],
               '208991' => [
                             'America/Denver'
                           ],
               '208994' => [
                             'America/Denver'
                           ],
               '208995' => [
                             'America/Denver'
                           ],
               '208996' => [
                             'America/Denver'
                           ],
               '209' => [
                          'America/Los_Angeles'
                        ],
               '210' => [
                          'America/Chicago'
                        ],
               '212' => [
                          'America/New_York'
                        ],
               '213' => [
                          'America/Los_Angeles'
                        ],
               '214' => [
                          'America/Chicago'
                        ],
               '215' => [
                          'America/New_York'
                        ],
               '216' => [
                          'America/New_York'
                        ],
               '217' => [
                          'America/Chicago'
                        ],
               '218' => [
                          'America/Chicago'
                        ],
               '219' => [
                          'America/New_York'
                        ],
               '219226' => [
                             'America/Chicago'
                           ],
               '219227' => [
                             'America/Chicago'
                           ],
               '219242' => [
                             'America/Chicago'
                           ],
               '219261' => [
                             'America/Chicago'
                           ],
               '219263' => [
                             'America/Chicago'
                           ],
               '219285' => [
                             'America/Chicago'
                           ],
               '219286' => [
                             'America/Chicago'
                           ],
               '219299' => [
                             'America/Chicago'
                           ],
               '219322' => [
                             'America/Chicago'
                           ],
               '219324' => [
                             'America/Chicago'
                           ],
               '219325' => [
                             'America/Chicago'
                           ],
               '219326' => [
                             'America/Chicago'
                           ],
               '219345' => [
                             'America/Chicago'
                           ],
               '219362' => [
                             'America/Chicago'
                           ],
               '219365' => [
                             'America/Chicago'
                           ],
               '219369' => [
                             'America/Chicago'
                           ],
               '219374' => [
                             'America/Chicago'
                           ],
               '219392' => [
                             'America/Chicago'
                           ],
               '219393' => [
                             'America/Chicago'
                           ],
               '219395' => [
                             'America/Chicago'
                           ],
               '219397' => [
                             'America/Chicago'
                           ],
               '219398' => [
                             'America/Chicago'
                           ],
               '219427' => [
                             'America/Chicago'
                           ],
               '219440' => [
                             'America/Chicago'
                           ],
               '219462' => [
                             'America/Chicago'
                           ],
               '219464' => [
                             'America/Chicago'
                           ],
               '219465' => [
                             'America/Chicago'
                           ],
               '219472' => [
                             'America/Chicago'
                           ],
               '219473' => [
                             'America/Chicago'
                           ],
               '219474' => [
                             'America/Chicago'
                           ],
               '219476' => [
                             'America/Chicago'
                           ],
               '219477' => [
                             'America/Chicago'
                           ],
               '219513' => [
                             'America/Chicago'
                           ],
               '219531' => [
                             'America/Chicago'
                           ],
               '219548' => [
                             'America/Chicago'
                           ],
               '219558' => [
                             'America/Chicago'
                           ],
               '219595' => [
                             'America/Chicago'
                           ],
               '219659' => [
                             'America/Chicago'
                           ],
               '219661' => [
                             'America/Chicago'
                           ],
               '219662' => [
                             'America/Chicago'
                           ],
               '219663' => [
                             'America/Chicago'
                           ],
               '219690' => [
                             'America/Chicago'
                           ],
               '219696' => [
                             'America/Chicago'
                           ],
               '219707' => [
                             'America/Chicago'
                           ],
               '219728' => [
                             'America/Chicago'
                           ],
               '219733' => [
                             'America/Chicago'
                           ],
               '219736' => [
                             'America/Chicago'
                           ],
               '219738' => [
                             'America/Chicago'
                           ],
               '219755' => [
                             'America/Chicago'
                           ],
               '219756' => [
                             'America/Chicago'
                           ],
               '219757' => [
                             'America/Chicago'
                           ],
               '219759' => [
                             'America/Chicago'
                           ],
               '219762' => [
                             'America/Chicago'
                           ],
               '219763' => [
                             'America/Chicago'
                           ],
               '219764' => [
                             'America/Chicago'
                           ],
               '219766' => [
                             'America/Chicago'
                           ],
               '219769' => [
                             'America/Chicago'
                           ],
               '219778' => [
                             'America/Chicago'
                           ],
               '219779' => [
                             'America/Chicago'
                           ],
               '219785' => [
                             'America/Chicago'
                           ],
               '219787' => [
                             'America/Chicago'
                           ],
               '219791' => [
                             'America/Chicago'
                           ],
               '219803' => [
                             'America/Chicago'
                           ],
               '219836' => [
                             'America/Chicago'
                           ],
               '219838' => [
                             'America/Chicago'
                           ],
               '219844' => [
                             'America/Chicago'
                           ],
               '219845' => [
                             'America/Chicago'
                           ],
               '219852' => [
                             'America/Chicago'
                           ],
               '219853' => [
                             'America/Chicago'
                           ],
               '219864' => [
                             'America/Chicago'
                           ],
               '219865' => [
                             'America/Chicago'
                           ],
               '219866' => [
                             'America/Chicago'
                           ],
               '219872' => [
                             'America/Chicago'
                           ],
               '219873' => [
                             'America/Chicago'
                           ],
               '219874' => [
                             'America/Chicago'
                           ],
               '219878' => [
                             'America/Chicago'
                           ],
               '219879' => [
                             'America/Chicago'
                           ],
               '21988' => [
                            'America/Chicago'
                          ],
               '21992' => [
                            'America/Chicago'
                          ],
               '21993' => [
                            'America/Chicago'
                          ],
               '21994' => [
                            'America/Chicago'
                          ],
               '219956' => [
                             'America/Chicago'
                           ],
               '219962' => [
                             'America/Chicago'
                           ],
               '219963' => [
                             'America/Chicago'
                           ],
               '219972' => [
                             'America/Chicago'
                           ],
               '219977' => [
                             'America/Chicago'
                           ],
               '219980' => [
                             'America/Chicago'
                           ],
               '219983' => [
                             'America/Chicago'
                           ],
               '219987' => [
                             'America/Chicago'
                           ],
               '219989' => [
                             'America/Chicago'
                           ],
               '219996' => [
                             'America/Chicago'
                           ],
               '220' => [
                          'America/New_York'
                        ],
               '223' => [
                          'America/New_York'
                        ],
               '224' => [
                          'America/Chicago'
                        ],
               '225' => [
                          'America/Chicago'
                        ],
               '226' => [
                          'America/Toronto'
                        ],
               '227' => [
                          'America/New_York'
                        ],
               '228' => [
                          'America/Chicago'
                        ],
               '229' => [
                          'America/New_York'
                        ],
               '231' => [
                          'America/New_York'
                        ],
               '234' => [
                          'America/New_York'
                        ],
               '235' => [
                          'America/Chicago'
                        ],
               '236' => [
                          'America/Vancouver'
                        ],
               '239' => [
                          'America/New_York'
                        ],
               '240' => [
                          'America/New_York'
                        ],
               '242' => [
                          'America/Nassau'
                        ],
               '246' => [
                          'America/Barbados'
                        ],
               '248' => [
                          'America/New_York'
                        ],
               '249' => [
                          'America/Toronto'
                        ],
               '250' => [
                          'America/Vancouver'
                        ],
               '250242' => [
                             'America/Edmonton'
                           ],
               '250261' => [
                             'America/Edmonton'
                           ],
               '250262' => [
                             'America/Edmonton'
                           ],
               '250263' => [
                             'America/Edmonton'
                           ],
               '250341' => [
                             'America/Edmonton'
                           ],
               '250342' => [
                             'America/Edmonton'
                           ],
               '250344' => [
                             'America/Edmonton'
                           ],
               '250347' => [
                             'America/Edmonton'
                           ],
               '250417' => [
                             'America/Edmonton'
                           ],
               '250423' => [
                             'America/Edmonton'
                           ],
               '250425' => [
                             'America/Edmonton'
                           ],
               '250426' => [
                             'America/Edmonton'
                           ],
               '250427' => [
                             'America/Edmonton'
                           ],
               '250428' => [
                             'America/Edmonton'
                           ],
               '250489' => [
                             'America/Edmonton'
                           ],
               '250719' => [
                             'America/Edmonton'
                           ],
               '250774' => [
                             'America/Edmonton'
                           ],
               '250782' => [
                             'America/Edmonton'
                           ],
               '250784' => [
                             'America/Edmonton'
                           ],
               '250785' => [
                             'America/Edmonton'
                           ],
               '250787' => [
                             'America/Edmonton'
                           ],
               '250788' => [
                             'America/Edmonton'
                           ],
               '251' => [
                          'America/Chicago'
                        ],
               '252' => [
                          'America/New_York'
                        ],
               '253' => [
                          'America/Los_Angeles'
                        ],
               '254' => [
                          'America/Chicago'
                        ],
               '256' => [
                          'America/Chicago'
                        ],
               '260' => [
                          'America/New_York'
                        ],
               '262' => [
                          'America/Chicago'
                        ],
               '263' => [
                          'America/Toronto'
                        ],
               '264' => [
                          'America/Anguilla'
                        ],
               '267' => [
                          'America/New_York'
                        ],
               '268' => [
                          'America/Antigua'
                        ],
               '269' => [
                          'America/New_York'
                        ],
               '270' => [
                          'America/New_York'
                        ],
               '270202' => [
                             'America/Chicago'
                           ],
               '270230' => [
                             'America/Chicago'
                           ],
               '270236' => [
                             'America/Chicago'
                           ],
               '270237' => [
                             'America/Chicago'
                           ],
               '270240' => [
                             'America/Chicago'
                           ],
               '270242' => [
                             'America/Chicago'
                           ],
               '270247' => [
                             'America/Chicago'
                           ],
               '270251' => [
                             'America/Chicago'
                           ],
               '270259' => [
                             'America/Chicago'
                           ],
               '270265' => [
                             'America/Chicago'
                           ],
               '270273' => [
                             'America/Chicago'
                           ],
               '270274' => [
                             'America/Chicago'
                           ],
               '270282' => [
                             'America/Chicago'
                           ],
               '270298' => [
                             'America/Chicago'
                           ],
               '270333' => [
                             'America/Chicago'
                           ],
               '270335' => [
                             'America/Chicago'
                           ],
               '270338' => [
                             'America/Chicago'
                           ],
               '270343' => [
                             'America/Chicago'
                           ],
               '270354' => [
                             'America/Chicago'
                           ],
               '270362' => [
                             'America/Chicago'
                           ],
               '270365' => [
                             'America/Chicago'
                           ],
               '270384' => [
                             'America/Chicago'
                           ],
               '270388' => [
                             'America/Chicago'
                           ],
               '270389' => [
                             'America/Chicago'
                           ],
               '270393' => [
                             'America/Chicago'
                           ],
               '270395' => [
                             'America/Chicago'
                           ],
               '270415' => [
                             'America/Chicago'
                           ],
               '270432' => [
                             'America/Chicago'
                           ],
               '270439' => [
                             'America/Chicago'
                           ],
               '270441' => [
                             'America/Chicago'
                           ],
               '270442' => [
                             'America/Chicago'
                           ],
               '270443' => [
                             'America/Chicago'
                           ],
               '270444' => [
                             'America/Chicago'
                           ],
               '270462' => [
                             'America/Chicago'
                           ],
               '270472' => [
                             'America/Chicago'
                           ],
               '270483' => [
                             'America/Chicago'
                           ],
               '270487' => [
                             'America/Chicago'
                           ],
               '270495' => [
                             'America/Chicago'
                           ],
               '270522' => [
                             'America/Chicago'
                           ],
               '270524' => [
                             'America/Chicago'
                           ],
               '270526' => [
                             'America/Chicago'
                           ],
               '270527' => [
                             'America/Chicago'
                           ],
               '270528' => [
                             'America/Chicago'
                           ],
               '270534' => [
                             'America/Chicago'
                           ],
               '270535' => [
                             'America/Chicago'
                           ],
               '270538' => [
                             'America/Chicago'
                           ],
               '270542' => [
                             'America/Chicago'
                           ],
               '270547' => [
                             'America/Chicago'
                           ],
               '270554' => [
                             'America/Chicago'
                           ],
               '270563' => [
                             'America/Chicago'
                           ],
               '270575' => [
                             'America/Chicago'
                           ],
               '270586' => [
                             'America/Chicago'
                           ],
               '270597' => [
                             'America/Chicago'
                           ],
               '270598' => [
                             'America/Chicago'
                           ],
               '270618' => [
                             'America/Chicago'
                           ],
               '270622' => [
                             'America/Chicago'
                           ],
               '270628' => [
                             'America/Chicago'
                           ],
               '270629' => [
                             'America/Chicago'
                           ],
               '270639' => [
                             'America/Chicago'
                           ],
               '270640' => [
                             'America/Chicago'
                           ],
               '270646' => [
                             'America/Chicago'
                           ],
               '270651' => [
                             'America/Chicago'
                           ],
               '270653' => [
                             'America/Chicago'
                           ],
               '270659' => [
                             'America/Chicago'
                           ],
               '270665' => [
                             'America/Chicago'
                           ],
               '270667' => [
                             'America/Chicago'
                           ],
               '270678' => [
                             'America/Chicago'
                           ],
               '27068' => [
                            'America/Chicago'
                          ],
               '270691' => [
                             'America/Chicago'
                           ],
               '270707' => [
                             'America/Chicago'
                           ],
               '270725' => [
                             'America/Chicago'
                           ],
               '270726' => [
                             'America/Chicago'
                           ],
               '270745' => [
                             'America/Chicago'
                           ],
               '270746' => [
                             'America/Chicago'
                           ],
               '270753' => [
                             'America/Chicago'
                           ],
               '270754' => [
                             'America/Chicago'
                           ],
               '270755' => [
                             'America/Chicago'
                           ],
               '270756' => [
                             'America/Chicago'
                           ],
               '270759' => [
                             'America/Chicago'
                           ],
               '270761' => [
                             'America/Chicago'
                           ],
               '270762' => [
                             'America/Chicago'
                           ],
               '270767' => [
                             'America/Chicago'
                           ],
               '270773' => [
                             'America/Chicago'
                           ],
               '270780' => [
                             'America/Chicago'
                           ],
               '270781' => [
                             'America/Chicago'
                           ],
               '270782' => [
                             'America/Chicago'
                           ],
               '270783' => [
                             'America/Chicago'
                           ],
               '270786' => [
                             'America/Chicago'
                           ],
               '270792' => [
                             'America/Chicago'
                           ],
               '270793' => [
                             'America/Chicago'
                           ],
               '270796' => [
                             'America/Chicago'
                           ],
               '270797' => [
                             'America/Chicago'
                           ],
               '270798' => [
                             'America/Chicago'
                           ],
               '270821' => [
                             'America/Chicago'
                           ],
               '270824' => [
                             'America/Chicago'
                           ],
               '270825' => [
                             'America/Chicago'
                           ],
               '270826' => [
                             'America/Chicago'
                           ],
               '270827' => [
                             'America/Chicago'
                           ],
               '270830' => [
                             'America/Chicago'
                           ],
               '270831' => [
                             'America/Chicago'
                           ],
               '270842' => [
                             'America/Chicago'
                           ],
               '270843' => [
                             'America/Chicago'
                           ],
               '270846' => [
                             'America/Chicago'
                           ],
               '270852' => [
                             'America/Chicago'
                           ],
               '270864' => [
                             'America/Chicago'
                           ],
               '270866' => [
                             'America/Chicago'
                           ],
               '270879' => [
                             'America/Chicago'
                           ],
               '270881' => [
                             'America/Chicago'
                           ],
               '270885' => [
                             'America/Chicago'
                           ],
               '270886' => [
                             'America/Chicago'
                           ],
               '270887' => [
                             'America/Chicago'
                           ],
               '270889' => [
                             'America/Chicago'
                           ],
               '270898' => [
                             'America/Chicago'
                           ],
               '270901' => [
                             'America/Chicago'
                           ],
               '270904' => [
                             'America/Chicago'
                           ],
               '270924' => [
                             'America/Chicago'
                           ],
               '270926' => [
                             'America/Chicago'
                           ],
               '270927' => [
                             'America/Chicago'
                           ],
               '270928' => [
                             'America/Chicago'
                           ],
               '270929' => [
                             'America/Chicago'
                           ],
               '270932' => [
                             'America/Chicago'
                           ],
               '270965' => [
                             'America/Chicago'
                           ],
               '270988' => [
                             'America/Chicago'
                           ],
               '272' => [
                          'America/New_York'
                        ],
               '276' => [
                          'America/New_York'
                        ],
               '279' => [
                          'America/Los_Angeles'
                        ],
               '281' => [
                          'America/Chicago'
                        ],
               '283' => [
                          'America/New_York'
                        ],
               '284' => [
                          'America/Tortola'
                        ],
               '289' => [
                          'America/Toronto'
                        ],
               '301' => [
                          'America/New_York'
                        ],
               '302' => [
                          'America/New_York'
                        ],
               '303' => [
                          'America/Denver'
                        ],
               '304' => [
                          'America/New_York'
                        ],
               '305' => [
                          'America/New_York'
                        ],
               '306' => [
                          'America/Regina'
                        ],
               '307' => [
                          'America/Denver'
                        ],
               '308' => [
                          'America/Chicago'
                        ],
               '308235' => [
                             'America/Denver'
                           ],
               '30824' => [
                            'America/Denver'
                          ],
               '308254' => [
                             'America/Denver'
                           ],
               '308262' => [
                             'America/Denver'
                           ],
               '308282' => [
                             'America/Denver'
                           ],
               '308284' => [
                             'America/Denver'
                           ],
               '308327' => [
                             'America/Denver'
                           ],
               '308352' => [
                             'America/Denver'
                           ],
               '308394' => [
                             'America/Denver'
                           ],
               '308423' => [
                             'America/Denver'
                           ],
               '308432' => [
                             'America/Denver'
                           ],
               '308436' => [
                             'America/Denver'
                           ],
               '308546' => [
                             'America/Denver'
                           ],
               '308623' => [
                             'America/Denver'
                           ],
               '308630' => [
                             'America/Denver'
                           ],
               '308632' => [
                             'America/Denver'
                           ],
               '308633' => [
                             'America/Denver'
                           ],
               '308635' => [
                             'America/Denver'
                           ],
               '308665' => [
                             'America/Denver'
                           ],
               '308762' => [
                             'America/Denver'
                           ],
               '308772' => [
                             'America/Denver'
                           ],
               '308874' => [
                             'America/Denver'
                           ],
               '308882' => [
                             'America/Denver'
                           ],
               '309' => [
                          'America/Chicago'
                        ],
               '3102' => [
                           'America/Los_Angeles'
                         ],
               '3103' => [
                           'America/Los_Angeles'
                         ],
               '3104' => [
                           'America/Los_Angeles'
                         ],
               '3105' => [
                           'America/Los_Angeles'
                         ],
               '3106' => [
                           'America/Los_Angeles'
                         ],
               '3107' => [
                           'America/Los_Angeles'
                         ],
               '3108' => [
                           'America/Los_Angeles'
                         ],
               '3109' => [
                           'America/Los_Angeles'
                         ],
               '312' => [
                          'America/Chicago'
                        ],
               '313' => [
                          'America/New_York'
                        ],
               '314' => [
                          'America/Chicago'
                        ],
               '315' => [
                          'America/New_York'
                        ],
               '316' => [
                          'America/Chicago'
                        ],
               '317' => [
                          'America/New_York'
                        ],
               '318' => [
                          'America/Chicago'
                        ],
               '319' => [
                          'America/Chicago'
                        ],
               '320' => [
                          'America/Chicago'
                        ],
               '321' => [
                          'America/New_York'
                        ],
               '323' => [
                          'America/Los_Angeles'
                        ],
               '325' => [
                          'America/Chicago'
                        ],
               '326' => [
                          'America/New_York'
                        ],
               '329' => [
                          'America/New_York'
                        ],
               '330' => [
                          'America/New_York'
                        ],
               '331' => [
                          'America/Chicago'
                        ],
               '332' => [
                          'America/New_York'
                        ],
               '334' => [
                          'America/Chicago'
                        ],
               '336' => [
                          'America/New_York'
                        ],
               '337' => [
                          'America/Chicago'
                        ],
               '339' => [
                          'America/New_York'
                        ],
               '340' => [
                          'America/St_Thomas'
                        ],
               '341' => [
                          'America/Los_Angeles'
                        ],
               '343' => [
                          'America/Toronto'
                        ],
               '345' => [
                          'America/Cayman'
                        ],
               '346' => [
                          'America/Chicago'
                        ],
               '347' => [
                          'America/New_York'
                        ],
               '350' => [
                          'America/Los_Angeles'
                        ],
               '351' => [
                          'America/New_York'
                        ],
               '352' => [
                          'America/New_York'
                        ],
               '354' => [
                          'America/Toronto'
                        ],
               '360' => [
                          'America/Los_Angeles'
                        ],
               '361' => [
                          'America/Chicago'
                        ],
               '363' => [
                          'America/New_York'
                        ],
               '364' => [
                          'America/New_York'
                        ],
               '365' => [
                          'America/Toronto'
                        ],
               '367' => [
                          'America/Toronto'
                        ],
               '368' => [
                          'America/Edmonton'
                        ],
               '369' => [
                          'America/Los_Angeles'
                        ],
               '380' => [
                          'America/New_York'
                        ],
               '382' => [
                          'America/Toronto'
                        ],
               '385' => [
                          'America/Denver'
                        ],
               '386' => [
                          'America/New_York'
                        ],
               '401' => [
                          'America/New_York'
                        ],
               '402' => [
                          'America/Chicago'
                        ],
               '403' => [
                          'America/Edmonton'
                        ],
               '404' => [
                          'America/New_York'
                        ],
               '405' => [
                          'America/Chicago'
                        ],
               '406' => [
                          'America/Denver'
                        ],
               '407' => [
                          'America/New_York'
                        ],
               '408' => [
                          'America/Los_Angeles'
                        ],
               '409' => [
                          'America/Chicago'
                        ],
               '410' => [
                          'America/New_York'
                        ],
               '412' => [
                          'America/New_York'
                        ],
               '413' => [
                          'America/New_York'
                        ],
               '414' => [
                          'America/Chicago'
                        ],
               '415' => [
                          'America/Los_Angeles'
                        ],
               '416' => [
                          'America/Toronto'
                        ],
               '417' => [
                          'America/Chicago'
                        ],
               '418' => [
                          'America/Toronto'
                        ],
               '418937' => [
                             'America/Halifax'
                           ],
               '418986' => [
                             'America/Halifax'
                           ],
               '419' => [
                          'America/New_York'
                        ],
               '423' => [
                          'America/Chicago'
                        ],
               '423202' => [
                             'America/New_York'
                           ],
               '423209' => [
                             'America/New_York'
                           ],
               '423217' => [
                             'America/New_York'
                           ],
               '423218' => [
                             'America/New_York'
                           ],
               '423224' => [
                             'America/New_York'
                           ],
               '42323' => [
                            'America/New_York'
                          ],
               '423245' => [
                             'America/New_York'
                           ],
               '423246' => [
                             'America/New_York'
                           ],
               '423247' => [
                             'America/New_York'
                           ],
               '423253' => [
                             'America/New_York'
                           ],
               '423254' => [
                             'America/New_York'
                           ],
               '423257' => [
                             'America/New_York'
                           ],
               '423262' => [
                             'America/New_York'
                           ],
               '423263' => [
                             'America/New_York'
                           ],
               '423265' => [
                             'America/New_York'
                           ],
               '423266' => [
                             'America/New_York'
                           ],
               '423267' => [
                             'America/New_York'
                           ],
               '423272' => [
                             'America/New_York'
                           ],
               '423278' => [
                             'America/New_York'
                           ],
               '423279' => [
                             'America/New_York'
                           ],
               '423282' => [
                             'America/New_York'
                           ],
               '423283' => [
                             'America/New_York'
                           ],
               '423286' => [
                             'America/New_York'
                           ],
               '423288' => [
                             'America/New_York'
                           ],
               '423296' => [
                             'America/New_York'
                           ],
               '423305' => [
                             'America/New_York'
                           ],
               '423307' => [
                             'America/New_York'
                           ],
               '423317' => [
                             'America/New_York'
                           ],
               '423318' => [
                             'America/New_York'
                           ],
               '423323' => [
                             'America/New_York'
                           ],
               '423328' => [
                             'America/New_York'
                           ],
               '42333' => [
                            'America/New_York'
                          ],
               '423343' => [
                             'America/New_York'
                           ],
               '423344' => [
                             'America/New_York'
                           ],
               '423345' => [
                             'America/New_York'
                           ],
               '423346' => [
                             'America/New_York'
                           ],
               '423349' => [
                             'America/New_York'
                           ],
               '423357' => [
                             'America/New_York'
                           ],
               '423365' => [
                             'America/New_York'
                           ],
               '423378' => [
                             'America/New_York'
                           ],
               '423391' => [
                             'America/New_York'
                           ],
               '423392' => [
                             'America/New_York'
                           ],
               '423396' => [
                             'America/New_York'
                           ],
               '423402' => [
                             'America/New_York'
                           ],
               '423421' => [
                             'America/New_York'
                           ],
               '423422' => [
                             'America/New_York'
                           ],
               '423424' => [
                             'America/New_York'
                           ],
               '423425' => [
                             'America/New_York'
                           ],
               '423431' => [
                             'America/New_York'
                           ],
               '423434' => [
                             'America/New_York'
                           ],
               '423439' => [
                             'America/New_York'
                           ],
               '423442' => [
                             'America/New_York'
                           ],
               '423443' => [
                             'America/New_York'
                           ],
               '423451' => [
                             'America/New_York'
                           ],
               '423453' => [
                             'America/New_York'
                           ],
               '423467' => [
                             'America/New_York'
                           ],
               '423468' => [
                             'America/New_York'
                           ],
               '42347' => [
                            'America/New_York'
                          ],
               '423485' => [
                             'America/New_York'
                           ],
               '423487' => [
                             'America/New_York'
                           ],
               '42349' => [
                            'America/New_York'
                          ],
               '423503' => [
                             'America/New_York'
                           ],
               '423507' => [
                             'America/New_York'
                           ],
               '423508' => [
                             'America/New_York'
                           ],
               '423510' => [
                             'America/New_York'
                           ],
               '423521' => [
                             'America/New_York'
                           ],
               '423525' => [
                             'America/New_York'
                           ],
               '423531' => [
                             'America/New_York'
                           ],
               '423538' => [
                             'America/New_York'
                           ],
               '423542' => [
                             'America/New_York'
                           ],
               '423543' => [
                             'America/New_York'
                           ],
               '423547' => [
                             'America/New_York'
                           ],
               '423553' => [
                             'America/New_York'
                           ],
               '423559' => [
                             'America/New_York'
                           ],
               '423562' => [
                             'America/New_York'
                           ],
               '423566' => [
                             'America/New_York'
                           ],
               '423569' => [
                             'America/New_York'
                           ],
               '423570' => [
                             'America/New_York'
                           ],
               '423573' => [
                             'America/New_York'
                           ],
               '423578' => [
                             'America/New_York'
                           ],
               '423581' => [
                             'America/New_York'
                           ],
               '423585' => [
                             'America/New_York'
                           ],
               '423586' => [
                             'America/New_York'
                           ],
               '423587' => [
                             'America/New_York'
                           ],
               '423595' => [
                             'America/New_York'
                           ],
               '423602' => [
                             'America/New_York'
                           ],
               '423610' => [
                             'America/New_York'
                           ],
               '423613' => [
                             'America/New_York'
                           ],
               '423614' => [
                             'America/New_York'
                           ],
               '42362' => [
                            'America/New_York'
                          ],
               '423631' => [
                             'America/New_York'
                           ],
               '423634' => [
                             'America/New_York'
                           ],
               '423636' => [
                             'America/New_York'
                           ],
               '423638' => [
                             'America/New_York'
                           ],
               '423639' => [
                             'America/New_York'
                           ],
               '423643' => [
                             'America/New_York'
                           ],
               '423648' => [
                             'America/New_York'
                           ],
               '423652' => [
                             'America/New_York'
                           ],
               '423663' => [
                             'America/New_York'
                           ],
               '423664' => [
                             'America/New_York'
                           ],
               '423667' => [
                             'America/New_York'
                           ],
               '423697' => [
                             'America/New_York'
                           ],
               '423698' => [
                             'America/New_York'
                           ],
               '423702' => [
                             'America/New_York'
                           ],
               '423708' => [
                             'America/New_York'
                           ],
               '423710' => [
                             'America/New_York'
                           ],
               '423722' => [
                             'America/New_York'
                           ],
               '423725' => [
                             'America/New_York'
                           ],
               '423727' => [
                             'America/New_York'
                           ],
               '423728' => [
                             'America/New_York'
                           ],
               '423733' => [
                             'America/New_York'
                           ],
               '423735' => [
                             'America/New_York'
                           ],
               '423743' => [
                             'America/New_York'
                           ],
               '423744' => [
                             'America/New_York'
                           ],
               '423745' => [
                             'America/New_York'
                           ],
               '423746' => [
                             'America/New_York'
                           ],
               '423752' => [
                             'America/New_York'
                           ],
               '423753' => [
                             'America/New_York'
                           ],
               '423756' => [
                             'America/New_York'
                           ],
               '423757' => [
                             'America/New_York'
                           ],
               '423760' => [
                             'America/New_York'
                           ],
               '423764' => [
                             'America/New_York'
                           ],
               '423765' => [
                             'America/New_York'
                           ],
               '423768' => [
                             'America/New_York'
                           ],
               '423772' => [
                             'America/New_York'
                           ],
               '423775' => [
                             'America/New_York'
                           ],
               '423778' => [
                             'America/New_York'
                           ],
               '423784' => [
                             'America/New_York'
                           ],
               '423787' => [
                             'America/New_York'
                           ],
               '423788' => [
                             'America/New_York'
                           ],
               '423790' => [
                             'America/New_York'
                           ],
               '423794' => [
                             'America/New_York'
                           ],
               '423798' => [
                             'America/New_York'
                           ],
               '423800' => [
                             'America/New_York'
                           ],
               '423802' => [
                             'America/New_York'
                           ],
               '423803' => [
                             'America/New_York'
                           ],
               '423805' => [
                             'America/New_York'
                           ],
               '423821' => [
                             'America/New_York'
                           ],
               '423822' => [
                             'America/New_York'
                           ],
               '423825' => [
                             'America/New_York'
                           ],
               '423826' => [
                             'America/New_York'
                           ],
               '423839' => [
                             'America/New_York'
                           ],
               '423842' => [
                             'America/New_York'
                           ],
               '423843' => [
                             'America/New_York'
                           ],
               '423844' => [
                             'America/New_York'
                           ],
               '423847' => [
                             'America/New_York'
                           ],
               '423854' => [
                             'America/New_York'
                           ],
               '423855' => [
                             'America/New_York'
                           ],
               '423857' => [
                             'America/New_York'
                           ],
               '423867' => [
                             'America/New_York'
                           ],
               '423869' => [
                             'America/New_York'
                           ],
               '423870' => [
                             'America/New_York'
                           ],
               '423875' => [
                             'America/New_York'
                           ],
               '423876' => [
                             'America/New_York'
                           ],
               '423877' => [
                             'America/New_York'
                           ],
               '423878' => [
                             'America/New_York'
                           ],
               '423884' => [
                             'America/New_York'
                           ],
               '423886' => [
                             'America/New_York'
                           ],
               '423892' => [
                             'America/New_York'
                           ],
               '423893' => [
                             'America/New_York'
                           ],
               '423894' => [
                             'America/New_York'
                           ],
               '423899' => [
                             'America/New_York'
                           ],
               '423907' => [
                             'America/New_York'
                           ],
               '423913' => [
                             'America/New_York'
                           ],
               '423915' => [
                             'America/New_York'
                           ],
               '423921' => [
                             'America/New_York'
                           ],
               '423926' => [
                             'America/New_York'
                           ],
               '423928' => [
                             'America/New_York'
                           ],
               '423929' => [
                             'America/New_York'
                           ],
               '423933' => [
                             'America/New_York'
                           ],
               '423952' => [
                             'America/New_York'
                           ],
               '423954' => [
                             'America/New_York'
                           ],
               '423968' => [
                             'America/New_York'
                           ],
               '423975' => [
                             'America/New_York'
                           ],
               '423979' => [
                             'America/New_York'
                           ],
               '423989' => [
                             'America/New_York'
                           ],
               '424' => [
                          'America/Los_Angeles'
                        ],
               '425' => [
                          'America/Los_Angeles'
                        ],
               '428' => [
                          'America/Halifax'
                        ],
               '430' => [
                          'America/Chicago'
                        ],
               '431' => [
                          'America/Winnipeg'
                        ],
               '432' => [
                          'America/Chicago'
                        ],
               '434' => [
                          'America/New_York'
                        ],
               '435' => [
                          'America/Denver'
                        ],
               '437' => [
                          'America/Winnipeg'
                        ],
               '438' => [
                          'America/Toronto'
                        ],
               '440' => [
                          'America/New_York'
                        ],
               '441' => [
                          'Atlantic/Bermuda'
                        ],
               '442' => [
                          'America/Los_Angeles'
                        ],
               '443' => [
                          'America/New_York'
                        ],
               '445' => [
                          'America/New_York'
                        ],
               '447' => [
                          'America/Chicago'
                        ],
               '448' => [
                          'America/New_York'
                        ],
               '450' => [
                          'America/Toronto'
                        ],
               '458' => [
                          'America/Los_Angeles'
                        ],
               '463' => [
                          'America/New_York'
                        ],
               '464' => [
                          'America/Chicago'
                        ],
               '468' => [
                          'America/Toronto'
                        ],
               '469' => [
                          'America/Chicago'
                        ],
               '470' => [
                          'America/New_York'
                        ],
               '472' => [
                          'America/New_York'
                        ],
               '473' => [
                          'America/Grenada'
                        ],
               '474' => [
                          'America/Winnipeg'
                        ],
               '475' => [
                          'America/New_York'
                        ],
               '478' => [
                          'America/New_York'
                        ],
               '479' => [
                          'America/Chicago'
                        ],
               '480' => [
                          'America/Phoenix'
                        ],
               '484' => [
                          'America/New_York'
                        ],
               '501' => [
                          'America/Chicago'
                        ],
               '502' => [
                          'America/New_York'
                        ],
               '503' => [
                          'America/Los_Angeles'
                        ],
               '504' => [
                          'America/Chicago'
                        ],
               '505' => [
                          'America/Denver'
                        ],
               '506' => [
                          'America/Halifax'
                        ],
               '507' => [
                          'America/Chicago'
                        ],
               '508' => [
                          'America/New_York'
                        ],
               '509' => [
                          'America/Los_Angeles'
                        ],
               '510' => [
                          'America/Los_Angeles'
                        ],
               '512' => [
                          'America/Chicago'
                        ],
               '513' => [
                          'America/New_York'
                        ],
               '514' => [
                          'America/Toronto'
                        ],
               '515' => [
                          'America/Chicago'
                        ],
               '516' => [
                          'America/New_York'
                        ],
               '517' => [
                          'America/New_York'
                        ],
               '518' => [
                          'America/New_York'
                        ],
               '519' => [
                          'America/Toronto'
                        ],
               '520' => [
                          'America/Phoenix'
                        ],
               '530' => [
                          'America/Los_Angeles'
                        ],
               '531' => [
                          'America/Chicago'
                        ],
               '534' => [
                          'America/Chicago'
                        ],
               '539' => [
                          'America/Chicago'
                        ],
               '540' => [
                          'America/New_York'
                        ],
               '541' => [
                          'America/Los_Angeles'
                        ],
               '541372' => [
                             'America/Denver'
                           ],
               '541473' => [
                             'America/Denver'
                           ],
               '541881' => [
                             'America/Denver'
                           ],
               '541889' => [
                             'America/Denver'
                           ],
               '548' => [
                          'America/Toronto'
                        ],
               '551' => [
                          'America/New_York'
                        ],
               '557' => [
                          'America/Chicago'
                        ],
               '559' => [
                          'America/Los_Angeles'
                        ],
               '561' => [
                          'America/New_York'
                        ],
               '562' => [
                          'America/Los_Angeles'
                        ],
               '563' => [
                          'America/Chicago'
                        ],
               '564' => [
                          'America/Los_Angeles'
                        ],
               '567' => [
                          'America/New_York'
                        ],
               '570' => [
                          'America/New_York'
                        ],
               '571' => [
                          'America/New_York'
                        ],
               '572' => [
                          'America/Chicago'
                        ],
               '573' => [
                          'America/Chicago'
                        ],
               '574' => [
                          'America/New_York'
                        ],
               '574772' => [
                             'America/Chicago'
                           ],
               '574896' => [
                             'America/Chicago'
                           ],
               '575' => [
                          'America/Denver'
                        ],
               '579' => [
                          'America/Toronto'
                        ],
               '580' => [
                          'America/Chicago'
                        ],
               '581' => [
                          'America/Toronto'
                        ],
               '582' => [
                          'America/New_York'
                        ],
               '584' => [
                          'America/Winnipeg'
                        ],
               '585' => [
                          'America/New_York'
                        ],
               '586' => [
                          'America/New_York'
                        ],
               '587' => [
                          'America/Edmonton'
                        ],
               '601' => [
                          'America/Chicago'
                        ],
               '602' => [
                          'America/Phoenix'
                        ],
               '603' => [
                          'America/New_York'
                        ],
               '604' => [
                          'America/Vancouver'
                        ],
               '605' => [
                          'America/Denver',
                          'America/North_Dakota/Center'
                        ],
               '605201' => [
                             'America/Chicago'
                           ],
               '605209' => [
                             'America/Denver'
                           ],
               '605217' => [
                             'America/Chicago'
                           ],
               '605221' => [
                             'America/Chicago'
                           ],
               '605223' => [
                             'America/Denver'
                           ],
               '605224' => [
                             'America/Chicago'
                           ],
               '605225' => [
                             'America/Chicago'
                           ],
               '605226' => [
                             'America/Chicago'
                           ],
               '605229' => [
                             'America/Chicago'
                           ],
               '605232' => [
                             'America/Chicago'
                           ],
               '605234' => [
                             'America/Chicago'
                           ],
               '605255' => [
                             'America/Denver'
                           ],
               '605256' => [
                             'America/Chicago'
                           ],
               '605260' => [
                             'America/Chicago'
                           ],
               '605261' => [
                             'America/Chicago'
                           ],
               '605262' => [
                             'America/Chicago'
                           ],
               '605271' => [
                             'America/Chicago'
                           ],
               '605274' => [
                             'America/Chicago'
                           ],
               '605275' => [
                             'America/Chicago'
                           ],
               '605279' => [
                             'America/Denver'
                           ],
               '605284' => [
                             'America/Chicago'
                           ],
               '605297' => [
                             'America/Chicago'
                           ],
               '605310' => [
                             'America/Chicago'
                           ],
               '605312' => [
                             'America/Chicago'
                           ],
               '605321' => [
                             'America/Chicago'
                           ],
               '605322' => [
                             'America/Chicago'
                           ],
               '605323' => [
                             'America/Chicago'
                           ],
               '605328' => [
                             'America/Chicago'
                           ],
               '60533' => [
                            'America/Chicago'
                          ],
               '605341' => [
                             'America/Denver'
                           ],
               '605342' => [
                             'America/Denver'
                           ],
               '605343' => [
                             'America/Denver'
                           ],
               '605345' => [
                             'America/Chicago'
                           ],
               '605347' => [
                             'America/Denver'
                           ],
               '605348' => [
                             'America/Denver'
                           ],
               '60535' => [
                            'America/Chicago'
                          ],
               '605355' => [
                             'America/Denver'
                           ],
               '60536' => [
                            'America/Chicago'
                          ],
               '605370' => [
                             'America/Chicago'
                           ],
               '605371' => [
                             'America/Chicago'
                           ],
               '605373' => [
                             'America/Chicago'
                           ],
               '605374' => [
                             'America/Denver'
                           ],
               '605376' => [
                             'America/Chicago'
                           ],
               '605381' => [
                             'America/Denver'
                           ],
               '605384' => [
                             'America/Chicago'
                           ],
               '605387' => [
                             'America/Chicago'
                           ],
               '605388' => [
                             'America/Denver'
                           ],
               '605390' => [
                             'America/Denver'
                           ],
               '605391' => [
                             'America/Denver'
                           ],
               '605393' => [
                             'America/Denver'
                           ],
               '605394' => [
                             'America/Denver'
                           ],
               '605397' => [
                             'America/Chicago'
                           ],
               '605399' => [
                             'America/Denver'
                           ],
               '605415' => [
                             'America/Denver'
                           ],
               '605425' => [
                             'America/Chicago'
                           ],
               '605426' => [
                             'America/Chicago'
                           ],
               '605428' => [
                             'America/Chicago'
                           ],
               '605430' => [
                             'America/Denver'
                           ],
               '605431' => [
                             'America/Denver'
                           ],
               '605432' => [
                             'America/Chicago'
                           ],
               '605448' => [
                             'America/Chicago'
                           ],
               '605455' => [
                             'America/Denver'
                           ],
               '605472' => [
                             'America/Chicago'
                           ],
               '605484' => [
                             'America/Denver'
                           ],
               '605487' => [
                             'America/Chicago'
                           ],
               '605498' => [
                             'America/Chicago'
                           ],
               '605528' => [
                             'America/Chicago'
                           ],
               '605532' => [
                             'America/Chicago'
                           ],
               '605539' => [
                             'America/Chicago'
                           ],
               '605543' => [
                             'America/Chicago'
                           ],
               '605553' => [
                             'America/Chicago'
                           ],
               '605574' => [
                             'America/Denver'
                           ],
               '605578' => [
                             'America/Denver'
                           ],
               '605582' => [
                             'America/Chicago'
                           ],
               '605584' => [
                             'America/Denver'
                           ],
               '605589' => [
                             'America/Chicago'
                           ],
               '605593' => [
                             'America/Denver'
                           ],
               '605594' => [
                             'America/Chicago'
                           ],
               '605598' => [
                             'America/Chicago'
                           ],
               '605610' => [
                             'America/Chicago'
                           ],
               '605622' => [
                             'America/Chicago'
                           ],
               '605624' => [
                             'America/Chicago'
                           ],
               '605626' => [
                             'America/Chicago'
                           ],
               '605627' => [
                             'America/Chicago'
                           ],
               '605641' => [
                             'America/Denver'
                           ],
               '605642' => [
                             'America/Denver'
                           ],
               '605644' => [
                             'America/Denver'
                           ],
               '605647' => [
                             'America/Chicago'
                           ],
               '605649' => [
                             'America/Chicago'
                           ],
               '605665' => [
                             'America/Chicago'
                           ],
               '605666' => [
                             'America/Denver'
                           ],
               '605668' => [
                             'America/Chicago'
                           ],
               '605669' => [
                             'America/Chicago'
                           ],
               '605673' => [
                             'America/Denver'
                           ],
               '605677' => [
                             'America/Chicago'
                           ],
               '605685' => [
                             'America/Denver'
                           ],
               '60569' => [
                            'America/Chicago'
                          ],
               '605716' => [
                             'America/Denver'
                           ],
               '605717' => [
                             'America/Denver'
                           ],
               '605718' => [
                             'America/Denver'
                           ],
               '605719' => [
                             'America/Denver'
                           ],
               '605720' => [
                             'America/Denver'
                           ],
               '605721' => [
                             'America/Denver'
                           ],
               '605722' => [
                             'America/Denver'
                           ],
               '605723' => [
                             'America/Denver'
                           ],
               '605724' => [
                             'America/Chicago'
                           ],
               '605725' => [
                             'America/Chicago'
                           ],
               '605728' => [
                             'America/Chicago'
                           ],
               '605734' => [
                             'America/Chicago'
                           ],
               '605743' => [
                             'America/Chicago'
                           ],
               '605745' => [
                             'America/Denver'
                           ],
               '605747' => [
                             'America/Chicago'
                           ],
               '605753' => [
                             'America/Chicago'
                           ],
               '605755' => [
                             'America/Denver'
                           ],
               '605759' => [
                             'America/Chicago'
                           ],
               '605763' => [
                             'America/Chicago'
                           ],
               '605765' => [
                             'America/Chicago'
                           ],
               '605772' => [
                             'America/Chicago'
                           ],
               '605773' => [
                             'America/Chicago'
                           ],
               '605775' => [
                             'America/Chicago'
                           ],
               '605778' => [
                             'America/Chicago'
                           ],
               '605787' => [
                             'America/Denver'
                           ],
               '605791' => [
                             'America/Denver'
                           ],
               '605796' => [
                             'America/Chicago'
                           ],
               '605823' => [
                             'America/Denver'
                           ],
               '605835' => [
                             'America/Chicago'
                           ],
               '605837' => [
                             'America/Denver'
                           ],
               '605842' => [
                             'America/Chicago'
                           ],
               '605845' => [
                             'America/Chicago'
                           ],
               '605852' => [
                             'America/Chicago'
                           ],
               '605853' => [
                             'America/Chicago'
                           ],
               '605854' => [
                             'America/Chicago'
                           ],
               '605856' => [
                             'America/Chicago'
                           ],
               '605859' => [
                             'America/Denver'
                           ],
               '605867' => [
                             'America/Denver'
                           ],
               '605874' => [
                             'America/Chicago'
                           ],
               '605878' => [
                             'America/Chicago'
                           ],
               '605881' => [
                             'America/Chicago'
                           ],
               '605882' => [
                             'America/Chicago'
                           ],
               '605886' => [
                             'America/Chicago'
                           ],
               '605892' => [
                             'America/Denver'
                           ],
               '605923' => [
                             'America/Denver'
                           ],
               '605925' => [
                             'America/Chicago'
                           ],
               '605928' => [
                             'America/Chicago'
                           ],
               '605929' => [
                             'America/Chicago'
                           ],
               '605940' => [
                             'America/Chicago'
                           ],
               '605941' => [
                             'America/Chicago'
                           ],
               '605945' => [
                             'America/Chicago'
                           ],
               '605946' => [
                             'America/Chicago'
                           ],
               '605951' => [
                             'America/Chicago'
                           ],
               '605964' => [
                             'America/Denver'
                           ],
               '605977' => [
                             'America/Chicago'
                           ],
               '605983' => [
                             'America/Chicago'
                           ],
               '605987' => [
                             'America/Chicago'
                           ],
               '605988' => [
                             'America/Chicago'
                           ],
               '605990' => [
                             'America/Chicago'
                           ],
               '605995' => [
                             'America/Chicago'
                           ],
               '605996' => [
                             'America/Chicago'
                           ],
               '605997' => [
                             'America/Chicago'
                           ],
               '606' => [
                          'America/New_York'
                        ],
               '606387' => [
                             'America/Chicago'
                           ],
               '607' => [
                          'America/New_York'
                        ],
               '608' => [
                          'America/Chicago'
                        ],
               '609' => [
                          'America/New_York'
                        ],
               '610' => [
                          'America/New_York'
                        ],
               '612' => [
                          'America/Chicago'
                        ],
               '613' => [
                          'America/Toronto'
                        ],
               '614' => [
                          'America/New_York'
                        ],
               '615' => [
                          'America/Chicago'
                        ],
               '616' => [
                          'America/New_York'
                        ],
               '617' => [
                          'America/New_York'
                        ],
               '618' => [
                          'America/Chicago'
                        ],
               '619' => [
                          'America/Los_Angeles'
                        ],
               '620' => [
                          'America/Chicago'
                        ],
               '620376' => [
                             'America/Denver'
                           ],
               '620384' => [
                             'America/Denver'
                           ],
               '623' => [
                          'America/Phoenix'
                        ],
               '626' => [
                          'America/Los_Angeles'
                        ],
               '628' => [
                          'America/Los_Angeles'
                        ],
               '629' => [
                          'America/Chicago'
                        ],
               '630' => [
                          'America/Chicago'
                        ],
               '631' => [
                          'America/New_York'
                        ],
               '636' => [
                          'America/Chicago'
                        ],
               '639' => [
                          'America/Regina'
                        ],
               '640' => [
                          'America/New_York'
                        ],
               '641' => [
                          'America/Chicago'
                        ],
               '645' => [
                          'America/New_York'
                        ],
               '646' => [
                          'America/New_York'
                        ],
               '647' => [
                          'America/Toronto'
                        ],
               '649' => [
                          'America/Grand_Turk'
                        ],
               '650' => [
                          'America/Los_Angeles'
                        ],
               '651' => [
                          'America/Chicago'
                        ],
               '656' => [
                          'America/New_York'
                        ],
               '657' => [
                          'America/Los_Angeles'
                        ],
               '658' => [
                          'America/Jamaica'
                        ],
               '659' => [
                          'America/Chicago'
                        ],
               '660' => [
                          'America/Chicago'
                        ],
               '661' => [
                          'America/Los_Angeles'
                        ],
               '662' => [
                          'America/Chicago'
                        ],
               '664' => [
                          'America/Montserrat'
                        ],
               '667' => [
                          'America/New_York'
                        ],
               '669' => [
                          'America/Los_Angeles'
                        ],
               '670' => [
                          'Pacific/Saipan'
                        ],
               '671' => [
                          'Pacific/Guam'
                        ],
               '672' => [
                          'America/Vancouver'
                        ],
               '678' => [
                          'America/New_York'
                        ],
               '680' => [
                          'America/New_York'
                        ],
               '681' => [
                          'America/New_York'
                        ],
               '682' => [
                          'America/Chicago'
                        ],
               '683' => [
                          'America/Toronto'
                        ],
               '684' => [
                          'Pacific/Pago_Pago'
                        ],
               '689' => [
                          'America/Chicago'
                        ],
               '701' => [
                          'America/Denver',
                          'America/North_Dakota/Center'
                        ],
               '701200' => [
                             'America/Chicago'
                           ],
               '701205' => [
                             'America/Chicago'
                           ],
               '701212' => [
                             'America/Chicago'
                           ],
               '701214' => [
                             'America/Chicago'
                           ],
               '70122' => [
                            'America/Chicago'
                          ],
               '701225' => [
                             'America/Denver'
                           ],
               '701227' => [
                             'America/Denver'
                           ],
               '70123' => [
                            'America/Chicago'
                          ],
               '701241' => [
                             'America/Chicago'
                           ],
               '701242' => [
                             'America/Chicago'
                           ],
               '70125' => [
                            'America/Chicago'
                          ],
               '701261' => [
                             'America/Chicago'
                           ],
               '701265' => [
                             'America/Chicago'
                           ],
               '701271' => [
                             'America/Chicago'
                           ],
               '701277' => [
                             'America/Chicago'
                           ],
               '701280' => [
                             'America/Chicago'
                           ],
               '701281' => [
                             'America/Chicago'
                           ],
               '701282' => [
                             'America/Chicago'
                           ],
               '701284' => [
                             'America/Chicago'
                           ],
               '701288' => [
                             'America/Chicago'
                           ],
               '701290' => [
                             'America/Denver'
                           ],
               '701293' => [
                             'America/Chicago'
                           ],
               '701297' => [
                             'America/Chicago'
                           ],
               '701298' => [
                             'America/Chicago'
                           ],
               '701306' => [
                             'America/Chicago'
                           ],
               '701323' => [
                             'America/Chicago'
                           ],
               '701324' => [
                             'America/Chicago'
                           ],
               '701328' => [
                             'America/Chicago'
                           ],
               '701343' => [
                             'America/Chicago'
                           ],
               '701347' => [
                             'America/Chicago'
                           ],
               '701349' => [
                             'America/Chicago'
                           ],
               '701352' => [
                             'America/Chicago'
                           ],
               '701355' => [
                             'America/Chicago'
                           ],
               '701356' => [
                             'America/Chicago'
                           ],
               '701361' => [
                             'America/Chicago'
                           ],
               '701364' => [
                             'America/Chicago'
                           ],
               '701365' => [
                             'America/Chicago'
                           ],
               '701367' => [
                             'America/Chicago'
                           ],
               '701371' => [
                             'America/Chicago'
                           ],
               '701373' => [
                             'America/Chicago'
                           ],
               '701385' => [
                             'America/Chicago'
                           ],
               '701388' => [
                             'America/Chicago'
                           ],
               '701390' => [
                             'America/Chicago'
                           ],
               '701391' => [
                             'America/Chicago'
                           ],
               '701400' => [
                             'America/Chicago'
                           ],
               '701425' => [
                             'America/Chicago'
                           ],
               '701426' => [
                             'America/Chicago'
                           ],
               '701428' => [
                             'America/Chicago'
                           ],
               '701437' => [
                             'America/Chicago'
                           ],
               '701444' => [
                             'America/Chicago'
                           ],
               '701446' => [
                             'America/Chicago'
                           ],
               '701448' => [
                             'America/Chicago'
                           ],
               '701452' => [
                             'America/Chicago'
                           ],
               '701454' => [
                             'America/Chicago'
                           ],
               '701456' => [
                             'America/Denver'
                           ],
               '701462' => [
                             'America/Chicago'
                           ],
               '701463' => [
                             'America/Chicago'
                           ],
               '701471' => [
                             'America/Chicago'
                           ],
               '701476' => [
                             'America/Chicago'
                           ],
               '701477' => [
                             'America/Chicago'
                           ],
               '701478' => [
                             'America/Chicago'
                           ],
               '701483' => [
                             'America/Denver'
                           ],
               '701492' => [
                             'America/Chicago'
                           ],
               '701499' => [
                             'America/Chicago'
                           ],
               '701523' => [
                             'America/Denver'
                           ],
               '701527' => [
                             'America/Chicago'
                           ],
               '701530' => [
                             'America/Chicago'
                           ],
               '701532' => [
                             'America/Chicago'
                           ],
               '701540' => [
                             'America/Chicago'
                           ],
               '701549' => [
                             'America/Chicago'
                           ],
               '701566' => [
                             'America/Chicago'
                           ],
               '701567' => [
                             'America/Denver'
                           ],
               '701572' => [
                             'America/Chicago'
                           ],
               '701575' => [
                             'America/Denver'
                           ],
               '701577' => [
                             'America/Chicago'
                           ],
               '701584' => [
                             'America/Denver'
                           ],
               '701595' => [
                             'America/Chicago'
                           ],
               '701609' => [
                             'America/Chicago'
                           ],
               '701623' => [
                             'America/Denver'
                           ],
               '701627' => [
                             'America/Chicago'
                           ],
               '701628' => [
                             'America/Chicago'
                           ],
               '701636' => [
                             'America/Chicago'
                           ],
               '701642' => [
                             'America/Chicago'
                           ],
               '701652' => [
                             'America/Chicago'
                           ],
               '701662' => [
                             'America/Chicago'
                           ],
               '701663' => [
                             'America/Chicago'
                           ],
               '701664' => [
                             'America/Chicago'
                           ],
               '701667' => [
                             'America/Chicago'
                           ],
               '701683' => [
                             'America/Chicago'
                           ],
               '701724' => [
                             'America/Chicago'
                           ],
               '701730' => [
                             'America/Chicago'
                           ],
               '701738' => [
                             'America/Chicago'
                           ],
               '701739' => [
                             'America/Chicago'
                           ],
               '701742' => [
                             'America/Chicago'
                           ],
               '701746' => [
                             'America/Chicago'
                           ],
               '701748' => [
                             'America/Chicago'
                           ],
               '701751' => [
                             'America/Chicago'
                           ],
               '701754' => [
                             'America/Chicago'
                           ],
               '701756' => [
                             'America/Chicago'
                           ],
               '701757' => [
                             'America/Chicago'
                           ],
               '701764' => [
                             'America/Denver'
                           ],
               '701766' => [
                             'America/Chicago'
                           ],
               '701772' => [
                             'America/Chicago'
                           ],
               '701774' => [
                             'America/Chicago'
                           ],
               '701775' => [
                             'America/Chicago'
                           ],
               '701776' => [
                             'America/Chicago'
                           ],
               '701777' => [
                             'America/Chicago'
                           ],
               '701780' => [
                             'America/Chicago'
                           ],
               '701786' => [
                             'America/Chicago'
                           ],
               '701787' => [
                             'America/Chicago'
                           ],
               '701788' => [
                             'America/Chicago'
                           ],
               '701793' => [
                             'America/Chicago'
                           ],
               '701795' => [
                             'America/Chicago'
                           ],
               '701797' => [
                             'America/Chicago'
                           ],
               '701799' => [
                             'America/Chicago'
                           ],
               '701824' => [
                             'America/Denver'
                           ],
               '701833' => [
                             'America/Chicago'
                           ],
               '701837' => [
                             'America/Chicago'
                           ],
               '701838' => [
                             'America/Chicago'
                           ],
               '701839' => [
                             'America/Chicago'
                           ],
               '701842' => [
                             'America/Chicago'
                           ],
               '701843' => [
                             'America/Chicago'
                           ],
               '701845' => [
                             'America/Chicago'
                           ],
               '701852' => [
                             'America/Chicago'
                           ],
               '701854' => [
                             'America/Chicago'
                           ],
               '701857' => [
                             'America/Chicago'
                           ],
               '701858' => [
                             'America/Chicago'
                           ],
               '701866' => [
                             'America/Chicago'
                           ],
               '701872' => [
                             'America/Denver'
                           ],
               '701873' => [
                             'America/Chicago'
                           ],
               '701883' => [
                             'America/Chicago'
                           ],
               '701893' => [
                             'America/Chicago'
                           ],
               '701947' => [
                             'America/Chicago'
                           ],
               '701952' => [
                             'America/Chicago'
                           ],
               '701965' => [
                             'America/Chicago'
                           ],
               '701968' => [
                             'America/Chicago'
                           ],
               '702' => [
                          'America/Los_Angeles'
                        ],
               '703' => [
                          'America/New_York'
                        ],
               '704' => [
                          'America/New_York'
                        ],
               '705' => [
                          'America/Toronto'
                        ],
               '706' => [
                          'America/New_York'
                        ],
               '707' => [
                          'America/Los_Angeles'
                        ],
               '708' => [
                          'America/Chicago'
                        ],
               '709' => [
                          'America/Puerto_Rico',
                          'America/St_Johns'
                        ],
               '709227' => [
                             'America/St_Johns'
                           ],
               '709229' => [
                             'America/St_Johns'
                           ],
               '709237' => [
                             'America/St_Johns'
                           ],
               '709256' => [
                             'America/St_Johns'
                           ],
               '709257' => [
                             'America/St_Johns'
                           ],
               '709279' => [
                             'America/St_Johns'
                           ],
               '709282' => [
                             'America/Halifax'
                           ],
               '709364' => [
                             'America/St_Johns'
                           ],
               '709368' => [
                             'America/St_Johns'
                           ],
               '709437' => [
                             'America/St_Johns'
                           ],
               '709454' => [
                             'America/St_Johns'
                           ],
               '709458' => [
                             'America/St_Johns'
                           ],
               '709466' => [
                             'America/St_Johns'
                           ],
               '709468' => [
                             'America/St_Johns'
                           ],
               '709489' => [
                             'America/St_Johns'
                           ],
               '709533' => [
                             'America/St_Johns'
                           ],
               '709535' => [
                             'America/St_Johns'
                           ],
               '709576' => [
                             'America/St_Johns'
                           ],
               '709579' => [
                             'America/St_Johns'
                           ],
               '709596' => [
                             'America/St_Johns'
                           ],
               '709634' => [
                             'America/St_Johns'
                           ],
               '709635' => [
                             'America/St_Johns'
                           ],
               '709637' => [
                             'America/St_Johns'
                           ],
               '709639' => [
                             'America/St_Johns'
                           ],
               '709643' => [
                             'America/St_Johns'
                           ],
               '709651' => [
                             'America/St_Johns'
                           ],
               '709673' => [
                             'America/St_Johns'
                           ],
               '709682' => [
                             'America/St_Johns'
                           ],
               '709685' => [
                             'America/St_Johns'
                           ],
               '709687' => [
                             'America/St_Johns'
                           ],
               '709695' => [
                             'America/St_Johns'
                           ],
               '709722' => [
                             'America/St_Johns'
                           ],
               '709726' => [
                             'America/St_Johns'
                           ],
               '709729' => [
                             'America/St_Johns'
                           ],
               '709738' => [
                             'America/St_Johns'
                           ],
               '709739' => [
                             'America/St_Johns'
                           ],
               '709745' => [
                             'America/St_Johns'
                           ],
               '709747' => [
                             'America/St_Johns'
                           ],
               '709753' => [
                             'America/St_Johns'
                           ],
               '709754' => [
                             'America/St_Johns'
                           ],
               '709757' => [
                             'America/St_Johns'
                           ],
               '709758' => [
                             'America/St_Johns'
                           ],
               '709759' => [
                             'America/St_Johns'
                           ],
               '709782' => [
                             'America/St_Johns'
                           ],
               '709786' => [
                             'America/St_Johns'
                           ],
               '709832' => [
                             'America/St_Johns'
                           ],
               '709834' => [
                             'America/St_Johns'
                           ],
               '709884' => [
                             'America/St_Johns'
                           ],
               '709895' => [
                             'America/St_Johns'
                           ],
               '709896' => [
                             'America/Halifax'
                           ],
               '709944' => [
                             'America/Halifax'
                           ],
               '712' => [
                          'America/Chicago'
                        ],
               '713' => [
                          'America/Chicago'
                        ],
               '714' => [
                          'America/Los_Angeles'
                        ],
               '715' => [
                          'America/Chicago'
                        ],
               '716' => [
                          'America/New_York'
                        ],
               '717' => [
                          'America/New_York'
                        ],
               '718' => [
                          'America/New_York'
                        ],
               '719' => [
                          'America/Denver'
                        ],
               '720' => [
                          'America/Denver'
                        ],
               '721' => [
                          'America/Lower_Princes'
                        ],
               '724' => [
                          'America/New_York'
                        ],
               '725' => [
                          'America/Los_Angeles'
                        ],
               '726' => [
                          'America/Chicago'
                        ],
               '727' => [
                          'America/New_York'
                        ],
               '728' => [
                          'America/New_York'
                        ],
               '730' => [
                          'America/Chicago'
                        ],
               '731' => [
                          'America/Chicago'
                        ],
               '732' => [
                          'America/New_York'
                        ],
               '734' => [
                          'America/New_York'
                        ],
               '737' => [
                          'America/Chicago'
                        ],
               '740' => [
                          'America/New_York'
                        ],
               '742' => [
                          'America/Toronto'
                        ],
               '743' => [
                          'America/New_York'
                        ],
               '747' => [
                          'America/Los_Angeles'
                        ],
               '753' => [
                          'America/Toronto'
                        ],
               '754' => [
                          'America/New_York'
                        ],
               '757' => [
                          'America/New_York'
                        ],
               '758' => [
                          'America/St_Lucia'
                        ],
               '760' => [
                          'America/Los_Angeles'
                        ],
               '762' => [
                          'America/New_York'
                        ],
               '763' => [
                          'America/Chicago'
                        ],
               '765' => [
                          'America/New_York'
                        ],
               '767' => [
                          'America/Dominica'
                        ],
               '769' => [
                          'America/Chicago'
                        ],
               '770' => [
                          'America/New_York'
                        ],
               '771' => [
                          'America/New_York'
                        ],
               '772' => [
                          'America/New_York'
                        ],
               '773' => [
                          'America/Chicago'
                        ],
               '774' => [
                          'America/New_York'
                        ],
               '775' => [
                          'America/Boise',
                          'America/Los_Angeles'
                        ],
               '775200' => [
                             'America/Los_Angeles'
                           ],
               '775230' => [
                             'America/Los_Angeles'
                           ],
               '775232' => [
                             'America/Los_Angeles'
                           ],
               '775233' => [
                             'America/Los_Angeles'
                           ],
               '775237' => [
                             'America/Los_Angeles'
                           ],
               '775240' => [
                             'America/Los_Angeles'
                           ],
               '775246' => [
                             'America/Los_Angeles'
                           ],
               '775250' => [
                             'America/Los_Angeles'
                           ],
               '775265' => [
                             'America/Los_Angeles'
                           ],
               '775267' => [
                             'America/Los_Angeles'
                           ],
               '775273' => [
                             'America/Los_Angeles'
                           ],
               '775284' => [
                             'America/Los_Angeles'
                           ],
               '775287' => [
                             'America/Los_Angeles'
                           ],
               '775289' => [
                             'America/Los_Angeles'
                           ],
               '775298' => [
                             'America/Los_Angeles'
                           ],
               '775313' => [
                             'America/Los_Angeles'
                           ],
               '77532' => [
                            'America/Los_Angeles'
                          ],
               '77533' => [
                            'America/Los_Angeles'
                          ],
               '775345' => [
                             'America/Los_Angeles'
                           ],
               '775348' => [
                             'America/Los_Angeles'
                           ],
               '77535' => [
                            'America/Los_Angeles'
                          ],
               '775360' => [
                             'America/Los_Angeles'
                           ],
               '775376' => [
                             'America/Los_Angeles'
                           ],
               '775384' => [
                             'America/Los_Angeles'
                           ],
               '775391' => [
                             'America/Los_Angeles'
                           ],
               '775392' => [
                             'America/Los_Angeles'
                           ],
               '775423' => [
                             'America/Los_Angeles'
                           ],
               '775424' => [
                             'America/Los_Angeles'
                           ],
               '775425' => [
                             'America/Los_Angeles'
                           ],
               '775428' => [
                             'America/Los_Angeles'
                           ],
               '775432' => [
                             'America/Los_Angeles'
                           ],
               '775445' => [
                             'America/Los_Angeles'
                           ],
               '775450' => [
                             'America/Los_Angeles'
                           ],
               '775453' => [
                             'America/Los_Angeles'
                           ],
               '775461' => [
                             'America/Los_Angeles'
                           ],
               '775463' => [
                             'America/Los_Angeles'
                           ],
               '775470' => [
                             'America/Los_Angeles'
                           ],
               '775473' => [
                             'America/Los_Angeles'
                           ],
               '775482' => [
                             'America/Los_Angeles'
                           ],
               '775525' => [
                             'America/Los_Angeles'
                           ],
               '775537' => [
                             'America/Los_Angeles'
                           ],
               '775544' => [
                             'America/Los_Angeles'
                           ],
               '775575' => [
                             'America/Los_Angeles'
                           ],
               '775577' => [
                             'America/Los_Angeles'
                           ],
               '775586' => [
                             'America/Los_Angeles'
                           ],
               '775588' => [
                             'America/Los_Angeles'
                           ],
               '775622' => [
                             'America/Los_Angeles'
                           ],
               '775623' => [
                             'America/Los_Angeles'
                           ],
               '775624' => [
                             'America/Los_Angeles'
                           ],
               '775625' => [
                             'America/Los_Angeles'
                           ],
               '775626' => [
                             'America/Los_Angeles'
                           ],
               '775635' => [
                             'America/Los_Angeles'
                           ],
               '775636' => [
                             'America/Los_Angeles'
                           ],
               '775657' => [
                             'America/Los_Angeles'
                           ],
               '775664' => [
                             'America/Denver'
                           ],
               '775673' => [
                             'America/Los_Angeles'
                           ],
               '775674' => [
                             'America/Los_Angeles'
                           ],
               '775677' => [
                             'America/Los_Angeles'
                           ],
               '775684' => [
                             'America/Los_Angeles'
                           ],
               '775686' => [
                             'America/Los_Angeles'
                           ],
               '775687' => [
                             'America/Los_Angeles'
                           ],
               '775688' => [
                             'America/Los_Angeles'
                           ],
               '775689' => [
                             'America/Los_Angeles'
                           ],
               '775720' => [
                             'America/Los_Angeles'
                           ],
               '775721' => [
                             'America/Los_Angeles'
                           ],
               '775722' => [
                             'America/Los_Angeles'
                           ],
               '775726' => [
                             'America/Los_Angeles'
                           ],
               '775727' => [
                             'America/Los_Angeles'
                           ],
               '775737' => [
                             'America/Los_Angeles'
                           ],
               '775738' => [
                             'America/Los_Angeles'
                           ],
               '775742' => [
                             'America/Los_Angeles'
                           ],
               '775746' => [
                             'America/Los_Angeles'
                           ],
               '775747' => [
                             'America/Los_Angeles'
                           ],
               '775750' => [
                             'America/Los_Angeles'
                           ],
               '775751' => [
                             'America/Los_Angeles'
                           ],
               '775752' => [
                             'America/Los_Angeles'
                           ],
               '775753' => [
                             'America/Los_Angeles'
                           ],
               '775762' => [
                             'America/Los_Angeles'
                           ],
               '775770' => [
                             'America/Los_Angeles'
                           ],
               '775771' => [
                             'America/Los_Angeles'
                           ],
               '775772' => [
                             'America/Los_Angeles'
                           ],
               '775777' => [
                             'America/Los_Angeles'
                           ],
               '775778' => [
                             'America/Los_Angeles'
                           ],
               '775782' => [
                             'America/Los_Angeles'
                           ],
               '775783' => [
                             'America/Los_Angeles'
                           ],
               '775784' => [
                             'America/Los_Angeles'
                           ],
               '775786' => [
                             'America/Los_Angeles'
                           ],
               '775787' => [
                             'America/Los_Angeles'
                           ],
               '775800' => [
                             'America/Los_Angeles'
                           ],
               '77582' => [
                            'America/Los_Angeles'
                          ],
               '775830' => [
                             'America/Los_Angeles'
                           ],
               '775831' => [
                             'America/Los_Angeles'
                           ],
               '775832' => [
                             'America/Los_Angeles'
                           ],
               '775833' => [
                             'America/Los_Angeles'
                           ],
               '775835' => [
                             'America/Los_Angeles'
                           ],
               '775841' => [
                             'America/Los_Angeles'
                           ],
               '775843' => [
                             'America/Los_Angeles'
                           ],
               '775847' => [
                             'America/Los_Angeles'
                           ],
               '775849' => [
                             'America/Los_Angeles'
                           ],
               '77585' => [
                            'America/Los_Angeles'
                          ],
               '775867' => [
                             'America/Los_Angeles'
                           ],
               '775870' => [
                             'America/Los_Angeles'
                           ],
               '77588' => [
                            'America/Los_Angeles'
                          ],
               '775945' => [
                             'America/Los_Angeles'
                           ],
               '775971' => [
                             'America/Los_Angeles'
                           ],
               '775972' => [
                             'America/Los_Angeles'
                           ],
               '775982' => [
                             'America/Los_Angeles'
                           ],
               '778' => [
                          'America/Vancouver'
                        ],
               '779' => [
                          'America/Chicago'
                        ],
               '780' => [
                          'America/Edmonton'
                        ],
               '781' => [
                          'America/New_York'
                        ],
               '782' => [
                          'America/Halifax'
                        ],
               '784' => [
                          'America/St_Vincent'
                        ],
               '785' => [
                          'America/Chicago'
                        ],
               '785852' => [
                             'America/Denver'
                           ],
               '785890' => [
                             'America/Denver'
                           ],
               '785899' => [
                             'America/Denver'
                           ],
               '786' => [
                          'America/New_York'
                        ],
               '787' => [
                          'America/Puerto_Rico'
                        ],
               '801' => [
                          'America/Denver'
                        ],
               '802' => [
                          'America/New_York'
                        ],
               '803' => [
                          'America/New_York'
                        ],
               '804' => [
                          'America/New_York'
                        ],
               '805' => [
                          'America/Los_Angeles'
                        ],
               '806' => [
                          'America/Chicago'
                        ],
               '807' => [
                          'America/Toronto'
                        ],
               '807223' => [
                             'America/Winnipeg'
                           ],
               '807274' => [
                             'America/Winnipeg'
                           ],
               '807467' => [
                             'America/Winnipeg'
                           ],
               '807468' => [
                             'America/Winnipeg'
                           ],
               '807482' => [
                             'America/Winnipeg'
                           ],
               '807548' => [
                             'America/Winnipeg'
                           ],
               '807727' => [
                             'America/Winnipeg'
                           ],
               '807737' => [
                             'America/Winnipeg'
                           ],
               '807934' => [
                             'America/Winnipeg'
                           ],
               '808' => [
                          'Pacific/Honolulu'
                        ],
               '809' => [
                          'America/Santo_Domingo'
                        ],
               '810' => [
                          'America/New_York'
                        ],
               '812' => [
                          'America/New_York'
                        ],
               '812385' => [
                             'America/Chicago'
                           ],
               '812386' => [
                             'America/Chicago'
                           ],
               '812401' => [
                             'America/Chicago'
                           ],
               '812402' => [
                             'America/Chicago'
                           ],
               '81242' => [
                            'America/Chicago'
                          ],
               '812435' => [
                             'America/Chicago'
                           ],
               '812437' => [
                             'America/Chicago'
                           ],
               '812450' => [
                             'America/Chicago'
                           ],
               '812464' => [
                             'America/Chicago'
                           ],
               '81247' => [
                            'America/Chicago'
                          ],
               '812485' => [
                             'America/Chicago'
                           ],
               '812490' => [
                             'America/Chicago'
                           ],
               '812491' => [
                             'America/Chicago'
                           ],
               '812547' => [
                             'America/Chicago'
                           ],
               '812618' => [
                             'America/Chicago'
                           ],
               '812649' => [
                             'America/Chicago'
                           ],
               '812682' => [
                             'America/Chicago'
                           ],
               '812749' => [
                             'America/Chicago'
                           ],
               '812753' => [
                             'America/Chicago'
                           ],
               '812768' => [
                             'America/Chicago'
                           ],
               '812838' => [
                             'America/Chicago'
                           ],
               '812842' => [
                             'America/Chicago'
                           ],
               '812853' => [
                             'America/Chicago'
                           ],
               '812858' => [
                             'America/Chicago'
                           ],
               '812867' => [
                             'America/Chicago'
                           ],
               '812874' => [
                             'America/Chicago'
                           ],
               '812897' => [
                             'America/Chicago'
                           ],
               '812925' => [
                             'America/Chicago'
                           ],
               '812937' => [
                             'America/Chicago'
                           ],
               '812962' => [
                             'America/Chicago'
                           ],
               '812963' => [
                             'America/Chicago'
                           ],
               '812985' => [
                             'America/Chicago'
                           ],
               '813' => [
                          'America/New_York'
                        ],
               '814' => [
                          'America/New_York'
                        ],
               '815' => [
                          'America/Chicago'
                        ],
               '816' => [
                          'America/Chicago'
                        ],
               '817' => [
                          'America/Chicago'
                        ],
               '818' => [
                          'America/Los_Angeles'
                        ],
               '819' => [
                          'America/Toronto'
                        ],
               '820' => [
                          'America/Los_Angeles'
                        ],
               '825' => [
                          'America/Edmonton'
                        ],
               '826' => [
                          'America/New_York'
                        ],
               '828' => [
                          'America/New_York'
                        ],
               '829' => [
                          'America/Santo_Domingo'
                        ],
               '830' => [
                          'America/Chicago'
                        ],
               '831' => [
                          'America/Los_Angeles'
                        ],
               '832' => [
                          'America/Chicago'
                        ],
               '835' => [
                          'America/New_York'
                        ],
               '838' => [
                          'America/New_York'
                        ],
               '839' => [
                          'America/New_York'
                        ],
               '840' => [
                          'America/Los_Angeles'
                        ],
               '843' => [
                          'America/New_York'
                        ],
               '845' => [
                          'America/New_York'
                        ],
               '847' => [
                          'America/Chicago'
                        ],
               '848' => [
                          'America/New_York'
                        ],
               '849' => [
                          'America/Santo_Domingo'
                        ],
               '850' => [
                          'America/New_York'
                        ],
               '850200' => [
                             'America/Chicago'
                           ],
               '850206' => [
                             'America/Chicago'
                           ],
               '850208' => [
                             'America/Chicago'
                           ],
               '850213' => [
                             'America/Chicago'
                           ],
               '850215' => [
                             'America/Chicago'
                           ],
               '850217' => [
                             'America/Chicago'
                           ],
               '850218' => [
                             'America/Chicago'
                           ],
               '850221' => [
                             'America/Chicago'
                           ],
               '850225' => [
                             'America/Chicago'
                           ],
               '850226' => [
                             'America/Chicago'
                           ],
               '850227' => [
                             'America/Chicago'
                           ],
               '850229' => [
                             'America/Chicago'
                           ],
               '85023' => [
                            'America/Chicago'
                          ],
               '850240' => [
                             'America/Chicago'
                           ],
               '850243' => [
                             'America/Chicago'
                           ],
               '850244' => [
                             'America/Chicago'
                           ],
               '850248' => [
                             'America/Chicago'
                           ],
               '850249' => [
                             'America/Chicago'
                           ],
               '850250' => [
                             'America/Chicago'
                           ],
               '850256' => [
                             'America/Chicago'
                           ],
               '850258' => [
                             'America/Chicago'
                           ],
               '850259' => [
                             'America/Chicago'
                           ],
               '850261' => [
                             'America/Chicago'
                           ],
               '850263' => [
                             'America/Chicago'
                           ],
               '850265' => [
                             'America/Chicago'
                           ],
               '850267' => [
                             'America/Chicago'
                           ],
               '850269' => [
                             'America/Chicago'
                           ],
               '850271' => [
                             'America/Chicago'
                           ],
               '850276' => [
                             'America/Chicago'
                           ],
               '850279' => [
                             'America/Chicago'
                           ],
               '850291' => [
                             'America/Chicago'
                           ],
               '850292' => [
                             'America/Chicago'
                           ],
               '850301' => [
                             'America/Chicago'
                           ],
               '850306' => [
                             'America/Chicago'
                           ],
               '850314' => [
                             'America/Chicago'
                           ],
               '850315' => [
                             'America/Chicago'
                           ],
               '850319' => [
                             'America/Chicago'
                           ],
               '850324' => [
                             'America/Chicago'
                           ],
               '850327' => [
                             'America/Chicago'
                           ],
               '850332' => [
                             'America/Chicago'
                           ],
               '850341' => [
                             'America/Chicago'
                           ],
               '850361' => [
                             'America/Chicago'
                           ],
               '850362' => [
                             'America/Chicago'
                           ],
               '850368' => [
                             'America/Chicago'
                           ],
               '850376' => [
                             'America/Chicago'
                           ],
               '850377' => [
                             'America/Chicago'
                           ],
               '850380' => [
                             'America/Chicago'
                           ],
               '850384' => [
                             'America/Chicago'
                           ],
               '850387' => [
                             'America/Chicago'
                           ],
               '850393' => [
                             'America/Chicago'
                           ],
               '850396' => [
                             'America/Chicago'
                           ],
               '850398' => [
                             'America/Chicago'
                           ],
               '850416' => [
                             'America/Chicago'
                           ],
               '850417' => [
                             'America/Chicago'
                           ],
               '850420' => [
                             'America/Chicago'
                           ],
               '850423' => [
                             'America/Chicago'
                           ],
               '850424' => [
                             'America/Chicago'
                           ],
               '850429' => [
                             'America/Chicago'
                           ],
               '85043' => [
                            'America/Chicago'
                          ],
               '850444' => [
                             'America/Chicago'
                           ],
               '85045' => [
                            'America/Chicago'
                          ],
               '850460' => [
                             'America/Chicago'
                           ],
               '850462' => [
                             'America/Chicago'
                           ],
               '850466' => [
                             'America/Chicago'
                           ],
               '850469' => [
                             'America/Chicago'
                           ],
               '85047' => [
                            'America/Chicago'
                          ],
               '850481' => [
                             'America/Chicago'
                           ],
               '850482' => [
                             'America/Chicago'
                           ],
               '850484' => [
                             'America/Chicago'
                           ],
               '850492' => [
                             'America/Chicago'
                           ],
               '850494' => [
                             'America/Chicago'
                           ],
               '850496' => [
                             'America/Chicago'
                           ],
               '850497' => [
                             'America/Chicago'
                           ],
               '850499' => [
                             'America/Chicago'
                           ],
               '850501' => [
                             'America/Chicago'
                           ],
               '850502' => [
                             'America/Chicago'
                           ],
               '850505' => [
                             'America/Chicago'
                           ],
               '850516' => [
                             'America/Chicago'
                           ],
               '850522' => [
                             'America/Chicago'
                           ],
               '850525' => [
                             'America/Chicago'
                           ],
               '850526' => [
                             'America/Chicago'
                           ],
               '850527' => [
                             'America/Chicago'
                           ],
               '850529' => [
                             'America/Chicago'
                           ],
               '850535' => [
                             'America/Chicago'
                           ],
               '850537' => [
                             'America/Chicago'
                           ],
               '850543' => [
                             'America/Chicago'
                           ],
               '850547' => [
                             'America/Chicago'
                           ],
               '850572' => [
                             'America/Chicago'
                           ],
               '850581' => [
                             'America/Chicago'
                           ],
               '850585' => [
                             'America/Chicago'
                           ],
               '850586' => [
                             'America/Chicago'
                           ],
               '850587' => [
                             'America/Chicago'
                           ],
               '850588' => [
                             'America/Chicago'
                           ],
               '850592' => [
                             'America/Chicago'
                           ],
               '850593' => [
                             'America/Chicago'
                           ],
               '850595' => [
                             'America/Chicago'
                           ],
               '850596' => [
                             'America/Chicago'
                           ],
               '850607' => [
                             'America/Chicago'
                           ],
               '850622' => [
                             'America/Chicago'
                           ],
               '850623' => [
                             'America/Chicago'
                           ],
               '850624' => [
                             'America/Chicago'
                           ],
               '850626' => [
                             'America/Chicago'
                           ],
               '850637' => [
                             'America/Chicago'
                           ],
               '850638' => [
                             'America/Chicago'
                           ],
               '850639' => [
                             'America/Chicago'
                           ],
               '850640' => [
                             'America/Chicago'
                           ],
               '850650' => [
                             'America/Chicago'
                           ],
               '850651' => [
                             'America/Chicago'
                           ],
               '850654' => [
                             'America/Chicago'
                           ],
               '850659' => [
                             'America/Chicago'
                           ],
               '850664' => [
                             'America/Chicago'
                           ],
               '850674' => [
                             'America/Chicago'
                           ],
               '850675' => [
                             'America/Chicago'
                           ],
               '850677' => [
                             'America/Chicago'
                           ],
               '850678' => [
                             'America/Chicago'
                           ],
               '85068' => [
                            'America/Chicago'
                          ],
               '850696' => [
                             'America/Chicago'
                           ],
               '850699' => [
                             'America/Chicago'
                           ],
               '850708' => [
                             'America/Chicago'
                           ],
               '850712' => [
                             'America/Chicago'
                           ],
               '850722' => [
                             'America/Chicago'
                           ],
               '850723' => [
                             'America/Chicago'
                           ],
               '850729' => [
                             'America/Chicago'
                           ],
               '850733' => [
                             'America/Chicago'
                           ],
               '850747' => [
                             'America/Chicago'
                           ],
               '850748' => [
                             'America/Chicago'
                           ],
               '850763' => [
                             'America/Chicago'
                           ],
               '850769' => [
                             'America/Chicago'
                           ],
               '850784' => [
                             'America/Chicago'
                           ],
               '850785' => [
                             'America/Chicago'
                           ],
               '850791' => [
                             'America/Chicago'
                           ],
               '850796' => [
                             'America/Chicago'
                           ],
               '850797' => [
                             'America/Chicago'
                           ],
               '850814' => [
                             'America/Chicago'
                           ],
               '850819' => [
                             'America/Chicago'
                           ],
               '850830' => [
                             'America/Chicago'
                           ],
               '850832' => [
                             'America/Chicago'
                           ],
               '850833' => [
                             'America/Chicago'
                           ],
               '850835' => [
                             'America/Chicago'
                           ],
               '850837' => [
                             'America/Chicago'
                           ],
               '850855' => [
                             'America/Chicago'
                           ],
               '850857' => [
                             'America/Chicago'
                           ],
               '85086' => [
                            'America/Chicago'
                          ],
               '850871' => [
                             'America/Chicago'
                           ],
               '850872' => [
                             'America/Chicago'
                           ],
               '850874' => [
                             'America/Chicago'
                           ],
               '850883' => [
                             'America/Chicago'
                           ],
               '850890' => [
                             'America/Chicago'
                           ],
               '850892' => [
                             'America/Chicago'
                           ],
               '850897' => [
                             'America/Chicago'
                           ],
               '850898' => [
                             'America/Chicago'
                           ],
               '850912' => [
                             'America/Chicago'
                           ],
               '850913' => [
                             'America/Chicago'
                           ],
               '850914' => [
                             'America/Chicago'
                           ],
               '850916' => [
                             'America/Chicago'
                           ],
               '850932' => [
                             'America/Chicago'
                           ],
               '850934' => [
                             'America/Chicago'
                           ],
               '850936' => [
                             'America/Chicago'
                           ],
               '850937' => [
                             'America/Chicago'
                           ],
               '850939' => [
                             'America/Chicago'
                           ],
               '850941' => [
                             'America/Chicago'
                           ],
               '850944' => [
                             'America/Chicago'
                           ],
               '850951' => [
                             'America/Chicago'
                           ],
               '850968' => [
                             'America/Chicago'
                           ],
               '850969' => [
                             'America/Chicago'
                           ],
               '850972' => [
                             'America/Chicago'
                           ],
               '850974' => [
                             'America/Chicago'
                           ],
               '850981' => [
                             'America/Chicago'
                           ],
               '850982' => [
                             'America/Chicago'
                           ],
               '850983' => [
                             'America/Chicago'
                           ],
               '850994' => [
                             'America/Chicago'
                           ],
               '850995' => [
                             'America/Chicago'
                           ],
               '854' => [
                          'America/New_York'
                        ],
               '856' => [
                          'America/New_York'
                        ],
               '857' => [
                          'America/New_York'
                        ],
               '858' => [
                          'America/Los_Angeles'
                        ],
               '859' => [
                          'America/New_York'
                        ],
               '860' => [
                          'America/New_York'
                        ],
               '862' => [
                          'America/New_York'
                        ],
               '863' => [
                          'America/New_York'
                        ],
               '864' => [
                          'America/New_York'
                        ],
               '865' => [
                          'America/New_York'
                        ],
               '867' => [
                          'America/Fort_Nelson'
                        ],
               '867334' => [
                             'America/Vancouver'
                           ],
               '867393' => [
                             'America/Vancouver'
                           ],
               '867456' => [
                             'America/Vancouver'
                           ],
               '867536' => [
                             'America/Vancouver'
                           ],
               '867587' => [
                             'America/Edmonton'
                           ],
               '867633' => [
                             'America/Vancouver'
                           ],
               '867645' => [
                             'America/Winnipeg'
                           ],
               '867667' => [
                             'America/Vancouver'
                           ],
               '867668' => [
                             'America/Vancouver'
                           ],
               '867669' => [
                             'America/Edmonton'
                           ],
               '867695' => [
                             'America/Edmonton'
                           ],
               '867777' => [
                             'America/Edmonton'
                           ],
               '867872' => [
                             'America/Edmonton'
                           ],
               '867873' => [
                             'America/Edmonton'
                           ],
               '867874' => [
                             'America/Edmonton'
                           ],
               '867920' => [
                             'America/Edmonton'
                           ],
               '867979' => [
                             'America/Toronto'
                           ],
               '867983' => [
                             'America/Edmonton'
                           ],
               '867993' => [
                             'America/Vancouver'
                           ],
               '868' => [
                          'America/Port_of_Spain'
                        ],
               '869' => [
                          'America/St_Kitts'
                        ],
               '870' => [
                          'America/Chicago'
                        ],
               '872' => [
                          'America/Chicago'
                        ],
               '873' => [
                          'America/Toronto'
                        ],
               '876' => [
                          'America/Jamaica'
                        ],
               '878' => [
                          'America/New_York'
                        ],
               '879' => [
                          'America/Puerto_Rico',
                          'America/St_Johns'
                        ],
               '901' => [
                          'America/Chicago'
                        ],
               '902' => [
                          'America/Halifax'
                        ],
               '903' => [
                          'America/Chicago'
                        ],
               '904' => [
                          'America/New_York'
                        ],
               '905' => [
                          'America/Toronto'
                        ],
               '906' => [
                          'America/New_York'
                        ],
               '906265' => [
                             'America/Chicago'
                           ],
               '906563' => [
                             'America/Chicago'
                           ],
               '906663' => [
                             'America/Chicago'
                           ],
               '906753' => [
                             'America/Chicago'
                           ],
               '906774' => [
                             'America/Chicago'
                           ],
               '906776' => [
                             'America/Chicago'
                           ],
               '906779' => [
                             'America/Chicago'
                           ],
               '906828' => [
                             'America/Chicago'
                           ],
               '906863' => [
                             'America/Chicago'
                           ],
               '906864' => [
                             'America/Chicago'
                           ],
               '906875' => [
                             'America/Chicago'
                           ],
               '906932' => [
                             'America/Chicago'
                           ],
               '907' => [
                          'America/Adak',
                          'America/Anchorage'
                        ],
               '907209' => [
                             'America/Juneau'
                           ],
               '907212' => [
                             'America/Juneau'
                           ],
               '90722' => [
                            'America/Juneau'
                          ],
               '907230' => [
                             'America/Juneau'
                           ],
               '907232' => [
                             'America/Juneau'
                           ],
               '907235' => [
                             'America/Juneau'
                           ],
               '90724' => [
                            'America/Juneau'
                          ],
               '907250' => [
                             'America/Juneau'
                           ],
               '907252' => [
                             'America/Juneau'
                           ],
               '907257' => [
                             'America/Juneau'
                           ],
               '907258' => [
                             'America/Juneau'
                           ],
               '907260' => [
                             'America/Juneau'
                           ],
               '907262' => [
                             'America/Juneau'
                           ],
               '907264' => [
                             'America/Juneau'
                           ],
               '907269' => [
                             'America/Juneau'
                           ],
               '90727' => [
                            'America/Juneau'
                          ],
               '907283' => [
                             'America/Juneau'
                           ],
               '907299' => [
                             'America/Juneau'
                           ],
               '907301' => [
                             'America/Juneau'
                           ],
               '907306' => [
                             'America/Juneau'
                           ],
               '907317' => [
                             'America/Juneau'
                           ],
               '90733' => [
                            'America/Juneau'
                          ],
               '907343' => [
                             'America/Juneau'
                           ],
               '907344' => [
                             'America/Juneau'
                           ],
               '907345' => [
                             'America/Juneau'
                           ],
               '907346' => [
                             'America/Juneau'
                           ],
               '907349' => [
                             'America/Juneau'
                           ],
               '907350' => [
                             'America/Juneau'
                           ],
               '907351' => [
                             'America/Juneau'
                           ],
               '907352' => [
                             'America/Juneau'
                           ],
               '907357' => [
                             'America/Juneau'
                           ],
               '907360' => [
                             'America/Juneau'
                           ],
               '907373' => [
                             'America/Juneau'
                           ],
               '907374' => [
                             'America/Juneau'
                           ],
               '907375' => [
                             'America/Juneau'
                           ],
               '907376' => [
                             'America/Juneau'
                           ],
               '907378' => [
                             'America/Juneau'
                           ],
               '907388' => [
                             'America/Juneau'
                           ],
               '907424' => [
                             'America/Juneau'
                           ],
               '907442' => [
                             'America/Juneau'
                           ],
               '907443' => [
                             'America/Juneau'
                           ],
               '90745' => [
                            'America/Juneau'
                          ],
               '907463' => [
                             'America/Juneau'
                           ],
               '907465' => [
                             'America/Juneau'
                           ],
               '907474' => [
                             'America/Juneau'
                           ],
               '907479' => [
                             'America/Juneau'
                           ],
               '907486' => [
                             'America/Juneau'
                           ],
               '907487' => [
                             'America/Juneau'
                           ],
               '907488' => [
                             'America/Juneau'
                           ],
               '907490' => [
                             'America/Juneau'
                           ],
               '907495' => [
                             'America/Juneau'
                           ],
               '907522' => [
                             'America/Juneau'
                           ],
               '907523' => [
                             'America/Juneau'
                           ],
               '907543' => [
                             'America/Juneau'
                           ],
               '907561' => [
                             'America/Juneau'
                           ],
               '907562' => [
                             'America/Juneau'
                           ],
               '907563' => [
                             'America/Juneau'
                           ],
               '907567' => [
                             'America/Juneau'
                           ],
               '907569' => [
                             'America/Juneau'
                           ],
               '907580' => [
                             'America/Juneau'
                           ],
               '907581' => [
                             'Pacific/Honolulu'
                           ],
               '907586' => [
                             'America/Juneau'
                           ],
               '907622' => [
                             'America/Juneau'
                           ],
               '907631' => [
                             'America/Juneau'
                           ],
               '907644' => [
                             'America/Juneau'
                           ],
               '907646' => [
                             'America/Juneau'
                           ],
               '907677' => [
                             'America/Juneau'
                           ],
               '907683' => [
                             'America/Juneau'
                           ],
               '907688' => [
                             'America/Juneau'
                           ],
               '907694' => [
                             'America/Juneau'
                           ],
               '907696' => [
                             'America/Juneau'
                           ],
               '907714' => [
                             'America/Juneau'
                           ],
               '907723' => [
                             'America/Juneau'
                           ],
               '907727' => [
                             'America/Juneau'
                           ],
               '907729' => [
                             'America/Juneau'
                           ],
               '907733' => [
                             'America/Juneau'
                           ],
               '907742' => [
                             'America/Juneau'
                           ],
               '907743' => [
                             'America/Juneau'
                           ],
               '907745' => [
                             'America/Juneau'
                           ],
               '907746' => [
                             'America/Juneau'
                           ],
               '907747' => [
                             'America/Juneau'
                           ],
               '907766' => [
                             'America/Juneau'
                           ],
               '907770' => [
                             'America/Juneau'
                           ],
               '907772' => [
                             'America/Juneau'
                           ],
               '907776' => [
                             'America/Juneau'
                           ],
               '907780' => [
                             'America/Juneau'
                           ],
               '907783' => [
                             'America/Juneau'
                           ],
               '907786' => [
                             'America/Juneau'
                           ],
               '907789' => [
                             'America/Juneau'
                           ],
               '907790' => [
                             'America/Juneau'
                           ],
               '907822' => [
                             'America/Juneau'
                           ],
               '907826' => [
                             'America/Juneau'
                           ],
               '907830' => [
                             'America/Juneau'
                           ],
               '907835' => [
                             'America/Juneau'
                           ],
               '907841' => [
                             'America/Juneau'
                           ],
               '907842' => [
                             'America/Juneau'
                           ],
               '907852' => [
                             'America/Juneau'
                           ],
               '907868' => [
                             'America/Juneau'
                           ],
               '907874' => [
                             'America/Juneau'
                           ],
               '907883' => [
                             'America/Juneau'
                           ],
               '907892' => [
                             'America/Juneau'
                           ],
               '907895' => [
                             'America/Juneau'
                           ],
               '907929' => [
                             'America/Juneau'
                           ],
               '907966' => [
                             'America/Juneau'
                           ],
               '907983' => [
                             'America/Juneau'
                           ],
               '908' => [
                          'America/New_York'
                        ],
               '909' => [
                          'America/Los_Angeles'
                        ],
               '910' => [
                          'America/New_York'
                        ],
               '912' => [
                          'America/New_York'
                        ],
               '913' => [
                          'America/Chicago'
                        ],
               '914' => [
                          'America/New_York'
                        ],
               '915' => [
                          'America/Denver'
                        ],
               '916' => [
                          'America/Los_Angeles'
                        ],
               '917' => [
                          'America/New_York'
                        ],
               '918' => [
                          'America/Chicago'
                        ],
               '919' => [
                          'America/New_York'
                        ],
               '920' => [
                          'America/Chicago'
                        ],
               '925' => [
                          'America/Los_Angeles'
                        ],
               '928' => [
                          'America/Denver',
                          'America/Phoenix'
                        ],
               '929' => [
                          'America/New_York'
                        ],
               '930' => [
                          'America/New_York'
                        ],
               '931' => [
                          'America/Chicago'
                        ],
               '934' => [
                          'America/New_York'
                        ],
               '936' => [
                          'America/Chicago'
                        ],
               '937' => [
                          'America/New_York'
                        ],
               '938' => [
                          'America/Chicago'
                        ],
               '939' => [
                          'America/Puerto_Rico'
                        ],
               '940' => [
                          'America/Chicago'
                        ],
               '941' => [
                          'America/New_York'
                        ],
               '943' => [
                          'America/New_York'
                        ],
               '945' => [
                          'America/Chicago'
                        ],
               '947' => [
                          'America/New_York'
                        ],
               '948' => [
                          'America/New_York'
                        ],
               '949' => [
                          'America/Los_Angeles'
                        ],
               '951' => [
                          'America/Los_Angeles'
                        ],
               '952' => [
                          'America/Chicago'
                        ],
               '954' => [
                          'America/New_York'
                        ],
               '956' => [
                          'America/Chicago'
                        ],
               '959' => [
                          'America/New_York'
                        ],
               '970' => [
                          'America/Denver'
                        ],
               '971' => [
                          'America/Los_Angeles'
                        ],
               '972' => [
                          'America/Chicago'
                        ],
               '973' => [
                          'America/New_York'
                        ],
               '978' => [
                          'America/New_York'
                        ],
               '979' => [
                          'America/Chicago'
                        ],
               '980' => [
                          'America/New_York'
                        ],
               '983' => [
                          'America/Denver'
                        ],
               '984' => [
                          'America/New_York'
                        ],
               '985' => [
                          'America/Chicago'
                        ],
               '986' => [
                          'America/Boise',
                          'America/Los_Angeles'
                        ],
               '989' => [
                          'America/New_York'
                        ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+1|\D)//g;
      my $self = bless({ country_code => '1', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, }, $class);
        return $self->is_valid() ? $self : undef;
    }
1;