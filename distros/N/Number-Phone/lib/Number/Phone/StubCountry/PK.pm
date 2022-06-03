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
package Number::Phone::StubCountry::PK;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20220601185319;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[89]0',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{2,7})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '1',
                  'pattern' => '(\\d{4})(\\d{5})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            9(?:
              2[3-8]|
              98
            )|
            (?:
              2(?:
                3[2358]|
                4[2-4]|
                9[2-8]
              )|
              45[3479]|
              54[2-467]|
              60[468]|
              72[236]|
              8(?:
                2[2-689]|
                3[23578]|
                4[3478]|
                5[2356]
              )|
              9(?:
                22|
                3[27-9]|
                4[2-6]|
                6[3569]|
                9[25-7]
              )
            )[2-9]
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{3})(\\d{6,7})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            (?:
              2[125]|
              4[0-246-9]|
              5[1-35-7]|
              6[1-8]|
              7[14]|
              8[16]|
              91
            )[2-9]
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{2})(\\d{7,8})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '58',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{5})(\\d{5})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '3',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{7})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '
            2[125]|
            4[0-246-9]|
            5[1-35-7]|
            6[1-8]|
            7[14]|
            8[16]|
            91
          ',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[24-9]',
                  'national_rule' => '(0$1)',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            (?:
              21|
              42
            )[2-9]|
            58[126]
          )\\d{7}|
          (?:
            2[25]|
            4[0146-9]|
            5[1-35-7]|
            6[1-8]|
            7[14]|
            8[16]|
            91
          )[2-9]\\d{6,7}|
          (?:
            2(?:
              3[2358]|
              4[2-4]|
              9[2-8]
            )|
            45[3479]|
            54[2-467]|
            60[468]|
            72[236]|
            8(?:
              2[2-689]|
              3[23578]|
              4[3478]|
              5[2356]
            )|
            9(?:
              2[2-8]|
              3[27-9]|
              4[2-6]|
              6[3569]|
              9[25-8]
            )
          )[2-9]\\d{5,6}
        ',
                'geographic' => '
          (?:
            (?:
              21|
              42
            )[2-9]|
            58[126]
          )\\d{7}|
          (?:
            2[25]|
            4[0146-9]|
            5[1-35-7]|
            6[1-8]|
            7[14]|
            8[16]|
            91
          )[2-9]\\d{6,7}|
          (?:
            2(?:
              3[2358]|
              4[2-4]|
              9[2-8]
            )|
            45[3479]|
            54[2-467]|
            60[468]|
            72[236]|
            8(?:
              2[2-689]|
              3[23578]|
              4[3478]|
              5[2356]
            )|
            9(?:
              2[2-8]|
              3[27-9]|
              4[2-6]|
              6[3569]|
              9[25-8]
            )
          )[2-9]\\d{5,6}
        ',
                'mobile' => '
          3(?:
            [0-24]\\d|
            3[0-7]|
            55|
            64
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '122\\d{6}',
                'specialrate' => '(900\\d{5})|(
          (?:
            2(?:
              [125]|
              3[2358]|
              4[2-4]|
              9[2-8]
            )|
            4(?:
              [0-246-9]|
              5[3479]
            )|
            5(?:
              [1-35-7]|
              4[2-467]
            )|
            6(?:
              0[468]|
              [1-8]
            )|
            7(?:
              [14]|
              2[236]
            )|
            8(?:
              [16]|
              2[2-689]|
              3[23578]|
              4[3478]|
              5[2356]
            )|
            9(?:
              1|
              22|
              3[27-9]|
              4[2-6]|
              6[3569]|
              9[2-7]
            )
          )111\\d{6}
        )',
                'toll_free' => '
          800\\d{5}(?:
            \\d{3}
          )?
        ',
                'voip' => ''
              };
my %areanames = ();
$areanames{en} = {"929386", "Swabi",
"928228", "Zhob",
"92713", "Sukkur",
"92412", "Faisalabad",
"929394", "Buner",
"928562", "Awaran",
"929443", "Upper\ Dir",
"929399", "Buner",
"928376", "Jhal\ Magsi",
"929662", "D\.I\.\ Khan",
"929432", "Chitral",
"922356", "Sanghar",
"922445", "Nawabshah",
"92527", "Sialkot",
"929458", "Lower\ Dir",
"924573", "Pakpattan",
"922389", "Umerkot",
"92927", "Karak",
"92522", "Sialkot",
"922384", "Umerkot",
"92494", "Kasur",
"925432", "Chakwal",
"928269", "K\.Abdullah\/Pishin",
"928437", "Mastung",
"925443", "Jhelum",
"92417", "Faisalabad",
"928264", "K\.Abdullah\/Pishin",
"928326", "Bolan",
"922332", "Mirpur\ Khas",
"928557", "Panjgur",
"929456", "Lower\ Dir",
"922358", "Sanghar",
"929657", "South\ Waziristan",
"92677", "Vehari",
"92563", "Sheikhupura",
"929977", "Mansehra\/Batagram",
"92532", "Gujrat",
"928378", "Jhal\ Magsi",
"92683", "Rahim\ Yar\ Khan",
"92486", "Sargodha",
"928226", "Zhob",
"92226", "Hyderabad",
"929388", "Swabi",
"928328", "Bolan",
"926069", "Layyah",
"928474", "Kharan",
"929697", "Lakki\ Marwat",
"928479", "Kharan",
"926064", "Layyah",
"92672", "Vehari",
"92537", "Gujrat",
"929927", "Abottabad",
"928235", "Killa\ Saifullah",
"929447", "Upper\ Dir",
"92516", "Islamabad\/Rawalpindi",
"928433", "Mastung",
"92916", "Peshawar\/Charsadda",
"925447", "Jhelum",
"928442", "Kalat",
"929965", "Shangla",
"92623", "Bahawalpur",
"924577", "Pakpattan",
"92426", "Lahore",
"92442", "Okara",
"92743", "Larkana",
"927222", "Jacobabad",
"922975", "Badin",
"92815", "Quetta",
"929653", "South\ Waziristan",
"92864", "Gwadar",
"929973", "Mansehra\/Batagram",
"92217", "Karachi",
"928553", "Panjgur",
"92633", "Bahawalnagar",
"92662", "Muzaffargarh",
"92554", "Gujranwala",
"929923", "Abottabad",
"92212", "Karachi",
"928335", "Sibi\/Ziarat",
"92658", "Khanewal",
"92573", "Attock",
"92667", "Muzaffargarh",
"929693", "Lakki\ Marwat",
"92819", "Quetta",
"924539", "Bhakkar",
"92447", "Okara",
"924534", "Bhakkar",
"922433", "Khairpur",
"929665", "D\.I\.\ Khan",
"927267", "Shikarpur",
"928247", "Loralai",
"928565", "Awaran",
"927236", "Ghotki",
"929435", "Chitral",
"922442", "Nawabshah",
"925435", "Chakwal",
"924597", "Mianwali",
"92656", "Khanewal",
"92474", "Jhang",
"92445", "Okara",
"92614", "Multan",
"926047", "Rajanpur",
"922335", "Mirpur\ Khas",
"92812", "Quetta",
"927238", "Ghotki",
"92518", "Islamabad\/Rawalpindi",
"92665", "Muzaffargarh",
"92219", "Karachi",
"928523", "Kech",
"92215", "Karachi",
"929953", "Haripur",
"92428", "Lahore",
"92669", "Muzaffargarh",
"92918", "Peshawar\/Charsadda",
"922983", "Thatta",
"92817", "Quetta",
"92449", "Okara",
"92415", "Faisalabad",
"92644", "Dera\ Ghazi\ Khan",
"928258", "Chagai",
"928384", "Jaffarabad\/Nasirabad",
"929379", "Mardan",
"924548", "Khushab",
"92228", "Hyderabad",
"928389", "Jaffarabad\/Nasirabad",
"92488", "Sargodha",
"928232", "Killa\ Saifullah",
"929374", "Mardan",
"92529", "Sialkot",
"92925", "Hangu\/Orakzai\ Agy",
"925478", "Hafizabad",
"928243", "Loralai",
"922326", "Tharparkar",
"925469", "Mandi\ Bahauddin",
"927263", "Shikarpur",
"92464", "Toba\ Tek\ Singh",
"929428", "Bajaur\ Agency",
"922437", "Khairpur",
"925464", "Mandi\ Bahauddin",
"928488", "Khuzdar",
"929464", "Swat",
"925428", "Narowal",
"926084", "Lodhran",
"924593", "Mianwali",
"929469", "Swat",
"92525", "Sialkot",
"926089", "Lodhran",
"929639", "Tank",
"929329", "Malakand",
"928534", "Lasbela",
"92403", "Sahiwal",
"928445", "Kalat",
"928356", "Dera\ Bugti",
"928539", "Lasbela",
"929962", "Shangla",
"929324", "Malakand",
"92419", "Faisalabad",
"929634", "Tank",
"928298", "Barkhan\/Kohlu",
"922972", "Badin",
"929426", "Bajaur\ Agency",
"928527", "Kech",
"92679", "Vehari",
"92535", "Gujrat",
"925476", "Hafizabad",
"927225", "Jacobabad",
"922328", "Tharparkar",
"929229", "Kohat",
"926043", "Rajanpur",
"92253", "Dadu",
"929224", "Kohat",
"924546", "Khushab",
"928256", "Chagai",
"928296", "Barkhan\/Kohlu",
"928284", "Musakhel",
"928358", "Dera\ Bugti",
"922429", "Naushero\ Feroze",
"922987", "Thatta",
"922424", "Naushero\ Feroze",
"928332", "Sibi\/Ziarat",
"928289", "Musakhel",
"92539", "Gujrat",
"929957", "Haripur",
"92675", "Vehari",
"928486", "Khuzdar",
"925426", "Narowal",
"924535", "Bhakkar",
"928227", "Zhob",
"92477", "Jhang",
"92566", "Sheikhupura",
"928556", "Panjgur",
"92686", "Rahim\ Yar\ Khan",
"929457", "Lower\ Dir",
"928282", "Musakhel",
"92483", "Sargodha",
"928339", "Sibi\/Ziarat",
"929656", "South\ Waziristan",
"92223", "Hyderabad",
"922422", "Naushero\ Feroze",
"929976", "Mansehra\/Batagram",
"928334", "Sibi\/Ziarat",
"929696", "Lakki\ Marwat",
"929222", "Kohat",
"92408", "Sahiwal",
"929926", "Abottabad",
"922974", "Badin",
"922979", "Badin",
"92472", "Jhang",
"928438", "Mastung",
"929978", "Mansehra\/Batagram",
"929658", "South\ Waziristan",
"92612", "Multan",
"929969", "Shangla",
"928532", "Lasbela",
"922357", "Sanghar",
"92716", "Sukkur",
"92258", "Dadu",
"92814", "Quetta",
"929964", "Shangla",
"928558", "Panjgur",
"929322", "Malakand",
"929632", "Tank",
"929462", "Swat",
"929387", "Swabi",
"926082", "Lodhran",
"92865", "Gwadar",
"92998", "Kohistan",
"92559", "Gujranwala",
"928377", "Jhal\ Magsi",
"928436", "Mastung",
"92555", "Gujranwala",
"92869", "Gwadar",
"925462", "Mandi\ Bahauddin",
"928327", "Bolan",
"929928", "Abottabad",
"928239", "Killa\ Saifullah",
"928382", "Jaffarabad\/Nasirabad",
"92617", "Multan",
"929698", "Lakki\ Marwat",
"928234", "Killa\ Saifullah",
"929372", "Mardan",
"926065", "Layyah",
"92642", "Dera\ Ghazi\ Khan",
"92746", "Larkana",
"928475", "Kharan",
"929453", "Lower\ Dir",
"928223", "Zhob",
"92499", "Kasur",
"929448", "Upper\ Dir",
"92462", "Toba\ Tek\ Singh",
"92636", "Bahawalnagar",
"925448", "Jhelum",
"92495", "Kasur",
"92576", "Attock",
"92467", "Toba\ Tek\ Singh",
"92647", "Dera\ Ghazi\ Khan",
"924578", "Pakpattan",
"929446", "Upper\ Dir",
"928265", "K\.Abdullah\/Pishin",
"928373", "Jhal\ Magsi",
"929383", "Swabi",
"92513", "Islamabad\/Rawalpindi",
"922385", "Umerkot",
"922353", "Sanghar",
"922449", "Nawabshah",
"924576", "Pakpattan",
"92913", "Peshawar\/Charsadda",
"922444", "Nawabshah",
"928323", "Bolan",
"92626", "Bahawalpur",
"92423", "Lahore",
"929395", "Buner",
"925446", "Jhelum",
"925473", "Hafizabad",
"92414", "Faisalabad",
"92645", "Dera\ Ghazi\ Khan",
"928248", "Loralai",
"927268", "Shikarpur",
"924532", "Bhakkar",
"929423", "Bajaur\ Agency",
"924543", "Khushab",
"928253", "Chagai",
"922425", "Naushero\ Feroze",
"92924", "Khyber\/Mohmand\ Agy",
"92465", "Toba\ Tek\ Singh",
"926046", "Rajanpur",
"92497", "Kasur",
"928285", "Musakhel",
"929225", "Kohat",
"92469", "Toba\ Tek\ Singh",
"92628", "Bahawalpur",
"92524", "Sialkot",
"928293", "Barkhan\/Kohlu",
"92492", "Kasur",
"927224", "Jacobabad",
"928483", "Khuzdar",
"925423", "Narowal",
"92649", "Dera\ Ghazi\ Khan",
"924598", "Mianwali",
"927229", "Jacobabad",
"92638", "Bahawalnagar",
"928444", "Kalat",
"929325", "Malakand",
"929635", "Tank",
"927237", "Ghotki",
"926048", "Rajanpur",
"928449", "Kalat",
"928535", "Lasbela",
"92534", "Gujrat",
"927266", "Shikarpur",
"928246", "Loralai",
"922323", "Tharparkar",
"929465", "Swat",
"92748", "Larkana",
"926085", "Lodhran",
"924596", "Mianwali",
"925465", "Mandi\ Bahauddin",
"9258", "AJK\/FATA",
"928353", "Dera\ Bugti",
"92578", "Attock",
"92653", "Khanewal",
"929375", "Mardan",
"928385", "Jaffarabad\/Nasirabad",
"92674", "Vehari",
"928472", "Kharan",
"92479", "Jhang",
"926062", "Layyah",
"924547", "Khushab",
"928257", "Chagai",
"922438", "Khairpur",
"929427", "Bajaur\ Agency",
"92256", "Dadu",
"928526", "Kech",
"92718", "Sukkur",
"925477", "Hafizabad",
"929956", "Haripur",
"925427", "Narowal",
"928487", "Khuzdar",
"928297", "Barkhan\/Kohlu",
"922334", "Mirpur\ Khas",
"922339", "Mirpur\ Khas",
"92475", "Jhang",
"922986", "Thatta",
"922327", "Tharparkar",
"92444", "Okara",
"92615", "Multan",
"928262", "K\.Abdullah\/Pishin",
"92688", "Rahim\ Yar\ Khan",
"928528", "Kech",
"922436", "Khairpur",
"92568", "Sheikhupura",
"92862", "Gwadar",
"925439", "Chakwal",
"92557", "Gujranwala",
"922382", "Umerkot",
"927233", "Ghotki",
"925434", "Chakwal",
"92664", "Muzaffargarh",
"929434", "Chitral",
"92867", "Gwadar",
"922988", "Thatta",
"92552", "Gujranwala",
"92214", "Karachi",
"928357", "Dera\ Bugti",
"929439", "Chitral",
"929669", "D\.I\.\ Khan",
"929958", "Haripur",
"929392", "Buner",
"928564", "Awaran",
"92406", "Sahiwal",
"928569", "Awaran",
"92619", "Multan",
"929664", "D\.I\.\ Khan",
"92646", "Dera\ Ghazi\ Khan",
"92742", "Larkana",
"924579", "Pakpattan",
"92443", "Okara",
"922383", "Umerkot",
"927232", "Ghotki",
"924574", "Pakpattan",
"922446", "Nawabshah",
"922355", "Sanghar",
"928263", "K\.Abdullah\/Pishin",
"925449", "Jhelum",
"928375", "Jhal\ Magsi",
"929385", "Swabi",
"92577", "Attock",
"92466", "Toba\ Tek\ Singh",
"92663", "Muzaffargarh",
"92632", "Bahawalnagar",
"925444", "Jhelum",
"929444", "Upper\ Dir",
"928325", "Bolan",
"92213", "Karachi",
"929449", "Upper\ Dir",
"92572", "Attock",
"929393", "Buner",
"92637", "Bahawalnagar",
"92747", "Larkana",
"928225", "Zhob",
"92627", "Bahawalpur",
"924537", "Bhakkar",
"922448", "Nawabshah",
"926063", "Layyah",
"928473", "Kharan",
"929455", "Lower\ Dir",
"92498", "Kasur",
"92622", "Bahawalpur",
"928434", "Mastung",
"922322", "Tharparkar",
"928439", "Mastung",
"928267", "K\.Abdullah\/Pishin",
"922978", "Badin",
"92868", "Gwadar",
"92562", "Sheikhupura",
"92533", "Gujrat",
"92255", "Dadu",
"92682", "Rahim\ Yar\ Khan",
"928236", "Killa\ Saifullah",
"922387", "Umerkot",
"928338", "Sibi\/Ziarat",
"92687", "Rahim\ Yar\ Khan",
"928352", "Dera\ Bugti",
"929966", "Shangla",
"92259", "Dadu",
"92654", "Khanewal",
"929397", "Buner",
"92558", "Gujranwala",
"92673", "Vehari",
"92476", "Jhang",
"92567", "Sheikhupura",
"928477", "Kharan",
"92616", "Multan",
"929929", "Abottabad",
"92413", "Faisalabad",
"929694", "Lakki\ Marwat",
"928238", "Killa\ Saifullah",
"92712", "Sukkur",
"924542", "Khushab",
"926067", "Layyah",
"928252", "Chagai",
"929924", "Abottabad",
"929699", "Lakki\ Marwat",
"92409", "Sahiwal",
"922976", "Badin",
"924533", "Bhakkar",
"929422", "Bajaur\ Agency",
"92923", "Nowshera",
"925472", "Hafizabad",
"92523", "Sialkot",
"928482", "Khuzdar",
"925422", "Narowal",
"929968", "Shangla",
"928554", "Panjgur",
"92405", "Sahiwal",
"928292", "Barkhan\/Kohlu",
"929659", "South\ Waziristan",
"92717", "Sukkur",
"929979", "Mansehra\/Batagram",
"929654", "South\ Waziristan",
"928559", "Panjgur",
"928336", "Sibi\/Ziarat",
"929974", "Mansehra\/Batagram",
"929436", "Chitral",
"928537", "Lasbela",
"922352", "Sanghar",
"92565", "Sheikhupura",
"929327", "Malakand",
"929637", "Tank",
"922338", "Mirpur\ Khas",
"927235", "Ghotki",
"929382", "Swabi",
"92685", "Rahim\ Yar\ Khan",
"929467", "Swat",
"92514", "Islamabad\/Rawalpindi",
"92252", "Dadu",
"928566", "Awaran",
"926087", "Lodhran",
"92618", "Multan",
"928372", "Jhal\ Magsi",
"929666", "D\.I\.\ Khan",
"922439", "Khairpur",
"92257", "Dadu",
"92914", "Peshawar\/Charsadda",
"925467", "Mandi\ Bahauddin",
"928322", "Bolan",
"92689", "Rahim\ Yar\ Khan",
"922434", "Khairpur",
"928387", "Jaffarabad\/Nasirabad",
"92569", "Sheikhupura",
"92424", "Lahore",
"929377", "Mardan",
"925436", "Chakwal",
"929959", "Haripur",
"92715", "Sukkur",
"929668", "D\.I\.\ Khan",
"92407", "Sahiwal",
"929954", "Haripur",
"928222", "Zhob",
"928568", "Awaran",
"922336", "Mirpur\ Khas",
"92866", "Gwadar",
"922989", "Thatta",
"929452", "Lower\ Dir",
"928287", "Musakhel",
"929438", "Chitral",
"922984", "Thatta",
"922427", "Naushero\ Feroze",
"92478", "Jhang",
"925438", "Chakwal",
"92556", "Gujranwala",
"929227", "Kohat",
"928524", "Kech",
"92402", "Sahiwal",
"928529", "Kech",
"92719", "Sukkur",
"924594", "Mianwali",
"92745", "Larkana",
"92813", "Quetta",
"927228", "Jacobabad",
"929463", "Swat",
"922325", "Tharparkar",
"924599", "Mianwali",
"926083", "Lodhran",
"92579", "Attock",
"929323", "Malakand",
"929633", "Tank",
"92635", "Bahawalnagar",
"928533", "Lasbela",
"928355", "Dera\ Bugti",
"928446", "Kalat",
"92639", "Bahawalnagar",
"929373", "Mardan",
"928383", "Jaffarabad\/Nasirabad",
"92575", "Attock",
"92496", "Kasur",
"928249", "Loralai",
"927264", "Shikarpur",
"925463", "Mandi\ Bahauddin",
"928244", "Loralai",
"92749", "Larkana",
"927269", "Shikarpur",
"92629", "Bahawalpur",
"92468", "Toba\ Tek\ Singh",
"924545", "Khushab",
"922423", "Naushero\ Feroze",
"928255", "Chagai",
"928283", "Musakhel",
"925475", "Hafizabad",
"927226", "Jacobabad",
"92484", "Sargodha",
"92224", "Hyderabad",
"929425", "Bajaur\ Agency",
"92648", "Dera\ Ghazi\ Khan",
"925425", "Narowal",
"928485", "Khuzdar",
"929223", "Kohat",
"926049", "Rajanpur",
"928295", "Barkhan\/Kohlu",
"926044", "Rajanpur",
"928448", "Kalat",
"92625", "Bahawalpur",
"929655", "South\ Waziristan",
"929975", "Mansehra\/Batagram",
"92427", "Lahore",
"926042", "Rajanpur",
"928555", "Panjgur",
"92659", "Khanewal",
"92512", "Islamabad\/Rawalpindi",
"92818", "Quetta",
"92254", "Dadu",
"922973", "Badin",
"924536", "Bhakkar",
"92917", "Peshawar\/Charsadda",
"92517", "Islamabad\/Rawalpindi",
"92912", "Peshawar\/Charsadda",
"92655", "Khanewal",
"928333", "Sibi\/Ziarat",
"929925", "Abottabad",
"92422", "Lahore",
"929695", "Lakki\ Marwat",
"92643", "Dera\ Ghazi\ Khan",
"92446", "Okara",
"927262", "Shikarpur",
"924538", "Bhakkar",
"928242", "Loralai",
"928233", "Killa\ Saifullah",
"92463", "Toba\ Tek\ Singh",
"922447", "Nawabshah",
"92666", "Muzaffargarh",
"929963", "Shangla",
"92216", "Karachi",
"924592", "Mianwali",
"92404", "Sahiwal",
"928435", "Mastung",
"922977", "Badin",
"92613", "Multan",
"92416", "Faisalabad",
"928268", "K\.Abdullah\/Pishin",
"928522", "Kech",
"922388", "Umerkot",
"928476", "Kharan",
"92926", "Kurram\ Agency",
"926066", "Layyah",
"929454", "Lower\ Dir",
"92526", "Sialkot",
"929459", "Lower\ Dir",
"928337", "Sibi\/Ziarat",
"922982", "Thatta",
"928229", "Zhob",
"929398", "Buner",
"929952", "Haripur",
"928224", "Zhob",
"922443", "Nawabshah",
"926068", "Layyah",
"928237", "Killa\ Saifullah",
"922386", "Umerkot",
"92536", "Gujrat",
"928478", "Kharan",
"928329", "Bolan",
"92482", "Sargodha",
"929445", "Upper\ Dir",
"928266", "K\.Abdullah\/Pishin",
"92222", "Hyderabad",
"928324", "Bolan",
"922432", "Khairpur",
"929384", "Swabi",
"925445", "Jhelum",
"92487", "Sargodha",
"929396", "Buner",
"928379", "Jhal\ Magsi",
"929389", "Swabi",
"92227", "Hyderabad",
"928374", "Jhal\ Magsi",
"924575", "Pakpattan",
"922354", "Sanghar",
"92676", "Vehari",
"929967", "Shangla",
"92473", "Jhang",
"922359", "Sanghar",
"922337", "Mirpur\ Khas",
"928552", "Panjgur",
"926045", "Rajanpur",
"929638", "Tank",
"929328", "Malakand",
"928294", "Barkhan\/Kohlu",
"92744", "Larkana",
"928286", "Musakhel",
"928299", "Barkhan\/Kohlu",
"929652", "South\ Waziristan",
"928538", "Lasbela",
"922426", "Naushero\ Feroze",
"929972", "Mansehra\/Batagram",
"92538", "Gujrat",
"92863", "Gwadar",
"925429", "Narowal",
"928489", "Khuzdar",
"926088", "Lodhran",
"927223", "Jacobabad",
"928484", "Khuzdar",
"929468", "Swat",
"92634", "Bahawalnagar",
"925424", "Narowal",
"929424", "Bajaur\ Agency",
"925468", "Mandi\ Bahauddin",
"92678", "Vehari",
"92553", "Gujranwala",
"925479", "Hafizabad",
"929429", "Bajaur\ Agency",
"92574", "Attock",
"925474", "Hafizabad",
"924549", "Khushab",
"929378", "Mardan",
"928259", "Chagai",
"929692", "Lakki\ Marwat",
"929226", "Kohat",
"924544", "Khushab",
"929922", "Abottabad",
"928254", "Chagai",
"928388", "Jaffarabad\/Nasirabad",
"929466", "Swat",
"928245", "Loralai",
"926086", "Lodhran",
"928567", "Awaran",
"92928", "Bannu\/N\.\ Waziristan",
"929667", "D\.I\.\ Khan",
"927265", "Shikarpur",
"928359", "Dera\ Bugti",
"922428", "Naushero\ Feroze",
"92485", "Sargodha",
"929437", "Chitral",
"928536", "Lasbela",
"92418", "Faisalabad",
"928288", "Musakhel",
"928354", "Dera\ Bugti",
"92225", "Hyderabad",
"929326", "Malakand",
"929636", "Tank",
"928386", "Jaffarabad\/Nasirabad",
"92229", "Hyderabad",
"929228", "Kohat",
"928443", "Kalat",
"925437", "Chakwal",
"92489", "Sargodha",
"929376", "Mardan",
"928432", "Mastung",
"922324", "Tharparkar",
"92528", "Sialkot",
"92624", "Bahawalpur",
"922329", "Tharparkar",
"924595", "Mianwali",
"925466", "Mandi\ Bahauddin",
"92668", "Muzaffargarh",
"92429", "Lahore",
"92657", "Khanewal",
"927227", "Jacobabad",
"928525", "Kech",
"92564", "Sheikhupura",
"92919", "Peshawar\/Charsadda",
"92515", "Islamabad\/Rawalpindi",
"92684", "Rahim\ Yar\ Khan",
"922333", "Mirpur\ Khas",
"92448", "Okara",
"922985", "Thatta",
"92915", "Peshawar\/Charsadda",
"92519", "Islamabad\/Rawalpindi",
"929955", "Haripur",
"92652", "Khanewal",
"92218", "Karachi",
"92425", "Lahore",
"92714", "Sukkur",
"929433", "Chitral",
"92816", "Quetta",
"929442", "Upper\ Dir",
"929663", "D\.I\.\ Khan",
"922435", "Khairpur",
"928563", "Awaran",
"92493", "Kasur",
"925442", "Jhelum",
"928447", "Kalat",
"927234", "Ghotki",
"925433", "Chakwal",
"924572", "Pakpattan",
"927239", "Ghotki",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+92|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;