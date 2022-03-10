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
our $VERSION = 1.20220307120122;

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
$areanames{en} = {"925439", "Chakwal",
"92405", "Sahiwal",
"928389", "Jaffarabad\/Nasirabad",
"92818", "Quetta",
"929974", "Mansehra\/Batagram",
"922333", "Mirpur\ Khas",
"928485", "Khuzdar",
"924544", "Khushab",
"92426", "Lahore",
"922983", "Thatta",
"92494", "Kasur",
"925475", "Hafizabad",
"92517", "Islamabad\/Rawalpindi",
"929962", "Shangla",
"92463", "Toba\ Tek\ Singh",
"92524", "Sialkot",
"926082", "Lodhran",
"926046", "Rajanpur",
"929653", "South\ Waziristan",
"92675", "Vehari",
"92579", "Attock",
"929388", "Swabi",
"928294", "Barkhan\/Kohlu",
"929223", "Kohat",
"92646", "Dera\ Ghazi\ Khan",
"92618", "Multan",
"929467", "Swat",
"926066", "Layyah",
"92479", "Jhang",
"928358", "Dera\ Bugti",
"929668", "D\.I\.\ Khan",
"922424", "Naushero\ Feroze",
"927224", "Jacobabad",
"922352", "Sanghar",
"92644", "Dera\ Ghazi\ Khan",
"929923", "Abottabad",
"929447", "Upper\ Dir",
"924572", "Pakpattan",
"928322", "Bolan",
"92659", "Khanewal",
"92555", "Gujranwala",
"928256", "Chagai",
"92563", "Sheikhupura",
"928529", "Kech",
"92424", "Lahore",
"928239", "Killa\ Saifullah",
"929632", "Tank",
"92496", "Kasur",
"922328", "Tharparkar",
"92417", "Faisalabad",
"929455", "Lower\ Dir",
"928566", "Awaran",
"92915", "Peshawar\/Charsadda",
"92526", "Sialkot",
"92663", "Muzaffargarh",
"929423", "Bajaur\ Agency",
"92919", "Peshawar\/Charsadda",
"92626", "Bahawalpur",
"922449", "Nawabshah",
"929399", "Buner",
"929637", "Tank",
"926044", "Rajanpur",
"92252", "Dadu",
"92223", "Hyderabad",
"92743", "Larkana",
"924577", "Pakpattan",
"928327", "Bolan",
"92559", "Gujranwala",
"92655", "Khanewal",
"928296", "Barkhan\/Kohlu",
"929442", "Upper\ Dir",
"929976", "Mansehra\/Batagram",
"929955", "Haripur",
"922357", "Sanghar",
"92418", "Faisalabad",
"92446", "Okara",
"92475", "Jhang",
"928285", "Musakhel",
"92863", "Gwadar",
"924546", "Khushab",
"929462", "Swat",
"928254", "Chagai",
"92518", "Islamabad\/Rawalpindi",
"92444", "Okara",
"928439", "Mastung",
"922973", "Badin",
"928335", "Sibi\/Ziarat",
"92817", "Quetta",
"928475", "Kharan",
"928379", "Jhal\ Magsi",
"928564", "Awaran",
"92575", "Attock",
"929693", "Lakki\ Marwat",
"926087", "Lodhran",
"92679", "Vehari",
"927226", "Jacobabad",
"929967", "Shangla",
"922426", "Naushero\ Feroze",
"92617", "Multan",
"927269", "Shikarpur",
"929378", "Mardan",
"926064", "Layyah",
"92624", "Bahawalpur",
"929438", "Chitral",
"92409", "Sahiwal",
"922437", "Khairpur",
"92477", "Jhang",
"92558", "Gujranwala",
"927237", "Ghotki",
"928242", "Loralai",
"928286", "Musakhel",
"925474", "Hafizabad",
"92482", "Sargodha",
"924545", "Khushab",
"928484", "Khuzdar",
"929975", "Mansehra\/Batagram",
"92918", "Peshawar\/Charsadda",
"929389", "Swabi",
"925462", "Mandi\ Bahauddin",
"929956", "Haripur",
"925438", "Chakwal",
"924592", "Mianwali",
"928223", "Zhob",
"928533", "Lasbela",
"928295", "Barkhan\/Kohlu",
"92657", "Khanewal",
"928388", "Jaffarabad\/Nasirabad",
"92419", "Faisalabad",
"922382", "Umerkot",
"92678", "Vehari",
"928447", "Kalat",
"922329", "Tharparkar",
"927225", "Jacobabad",
"928528", "Kech",
"928238", "Killa\ Saifullah",
"92212", "Karachi",
"922425", "Naushero\ Feroze",
"92519", "Islamabad\/Rawalpindi",
"925423", "Narowal",
"92615", "Multan",
"928359", "Dera\ Bugti",
"929669", "D\.I\.\ Khan",
"928476", "Kharan",
"92815", "Quetta",
"929454", "Lower\ Dir",
"928262", "K\.Abdullah\/Pishin",
"92577", "Attock",
"92408", "Sahiwal",
"928552", "Panjgur",
"925442", "Jhelum",
"92532", "Gujrat",
"929322", "Malakand",
"928336", "Sibi\/Ziarat",
"929327", "Malakand",
"92632", "Bahawalnagar",
"924533", "Bhakkar",
"928557", "Panjgur",
"925447", "Jhelum",
"926045", "Rajanpur",
"92682", "Rahim\ Yar\ Khan",
"92819", "Quetta",
"92677", "Vehari",
"928267", "K\.Abdullah\/Pishin",
"92926", "Kurram\ Agency",
"925476", "Hafizabad",
"928284", "Musakhel",
"922448", "Nawabshah",
"929398", "Buner",
"92619", "Multan",
"92515", "Islamabad\/Rawalpindi",
"92578", "Attock",
"92407", "Sahiwal",
"929954", "Haripur",
"928442", "Kalat",
"928486", "Khuzdar",
"922387", "Umerkot",
"92415", "Faisalabad",
"929456", "Lower\ Dir",
"929379", "Mardan",
"928565", "Awaran",
"92924", "Khyber\/Mohmand\ Agy",
"928474", "Kharan",
"927268", "Shikarpur",
"92917", "Peshawar\/Charsadda",
"928334", "Sibi\/Ziarat",
"929439", "Chitral",
"928255", "Chagai",
"92478", "Jhang",
"92557", "Gujranwala",
"924597", "Mianwali",
"92712", "Sukkur",
"925467", "Mandi\ Bahauddin",
"928438", "Mastung",
"926065", "Layyah",
"928378", "Jhal\ Magsi",
"92658", "Khanewal",
"922432", "Khairpur",
"928247", "Loralai",
"927232", "Ghotki",
"929636", "Tank",
"92428", "Lahore",
"929229", "Kohat",
"928562", "Awaran",
"928297", "Barkhan\/Kohlu",
"92533", "Gujrat",
"924576", "Pakpattan",
"928326", "Bolan",
"92816", "Quetta",
"928252", "Chagai",
"929464", "Swat",
"929659", "South\ Waziristan",
"92616", "Multan",
"92648", "Dera\ Ghazi\ Khan",
"922356", "Sanghar",
"922989", "Thatta",
"929977", "Mansehra\/Batagram",
"924547", "Khushab",
"926062", "Layyah",
"925433", "Chakwal",
"927235", "Ghotki",
"922339", "Mirpur\ Khas",
"922435", "Khairpur",
"928383", "Jaffarabad\/Nasirabad",
"92213", "Karachi",
"928538", "Lasbela",
"928228", "Zhob",
"92614", "Multan",
"92627", "Bahawalpur",
"928523", "Kech",
"928233", "Killa\ Saifullah",
"925428", "Narowal",
"926086", "Lodhran",
"926042", "Rajanpur",
"92498", "Kasur",
"929929", "Abottabad",
"92447", "Okara",
"92483", "Sargodha",
"92528", "Sialkot",
"929966", "Shangla",
"922427", "Naushero\ Feroze",
"927227", "Jacobabad",
"928445", "Kalat",
"929444", "Upper\ Dir",
"92814", "Quetta",
"92713", "Sukkur",
"922354", "Sanghar",
"922422", "Naushero\ Feroze",
"927222", "Jacobabad",
"92628", "Bahawalpur",
"924538", "Bhakkar",
"928265", "K\.Abdullah\/Pishin",
"926047", "Rajanpur",
"929634", "Tank",
"92514", "Islamabad\/Rawalpindi",
"925445", "Jhelum",
"929466", "Swat",
"92527", "Sialkot",
"928555", "Panjgur",
"922443", "Nawabshah",
"929393", "Buner",
"929325", "Malakand",
"928324", "Bolan",
"924574", "Pakpattan",
"929429", "Bajaur\ Agency",
"92497", "Kasur",
"92448", "Okara",
"92416", "Faisalabad",
"928245", "Loralai",
"929964", "Shangla",
"924542", "Khushab",
"926067", "Layyah",
"925465", "Mandi\ Bahauddin",
"92516", "Islamabad\/Rawalpindi",
"929972", "Mansehra\/Batagram",
"92925", "Hangu\/Orakzai\ Agy",
"929446", "Upper\ Dir",
"92427", "Lahore",
"92414", "Faisalabad",
"927263", "Shikarpur",
"928257", "Chagai",
"928373", "Jhal\ Magsi",
"924595", "Mianwali",
"92633", "Bahawalnagar",
"928292", "Barkhan\/Kohlu",
"929699", "Lakki\ Marwat",
"928567", "Awaran",
"92683", "Rahim\ Yar\ Khan",
"926084", "Lodhran",
"922979", "Badin",
"928433", "Mastung",
"922385", "Umerkot",
"92647", "Dera\ Ghazi\ Khan",
"92525", "Sialkot",
"925446", "Jhelum",
"922988", "Thatta",
"92629", "Bahawalpur",
"929465", "Swat",
"92916", "Peshawar\/Charsadda",
"928556", "Panjgur",
"92495", "Kasur",
"928332", "Sibi\/Ziarat",
"929326", "Malakand",
"928266", "K\.Abdullah\/Pishin",
"928472", "Kharan",
"92556", "Gujranwala",
"928229", "Zhob",
"928539", "Lasbela",
"92404", "Sahiwal",
"92562", "Sheikhupura",
"922338", "Mirpur\ Khas",
"929228", "Kohat",
"929383", "Swabi",
"922434", "Khairpur",
"92449", "Okara",
"925477", "Hafizabad",
"927234", "Ghotki",
"928487", "Khuzdar",
"92674", "Vehari",
"929658", "South\ Waziristan",
"929928", "Abottabad",
"929457", "Lower\ Dir",
"92645", "Dera\ Ghazi\ Khan",
"922386", "Umerkot",
"924596", "Mianwali",
"92676", "Vehari",
"928353", "Dera\ Bugti",
"929663", "D\.I\.\ Khan",
"92927", "Karak",
"929952", "Haripur",
"925466", "Mandi\ Bahauddin",
"922323", "Tharparkar",
"92914", "Peshawar\/Charsadda",
"929445", "Upper\ Dir",
"928444", "Kalat",
"925429", "Narowal",
"92425", "Lahore",
"928246", "Loralai",
"928282", "Musakhel",
"92554", "Gujranwala",
"92462", "Toba\ Tek\ Singh",
"92406", "Sahiwal",
"92654", "Khanewal",
"927236", "Ghotki",
"928287", "Musakhel",
"922436", "Khairpur",
"922355", "Sanghar",
"929428", "Bajaur\ Agency",
"929957", "Haripur",
"92429", "Lahore",
"924575", "Pakpattan",
"929324", "Malakand",
"92576", "Attock",
"928325", "Bolan",
"928554", "Panjgur",
"92474", "Jhang",
"925444", "Jhelum",
"929635", "Tank",
"92649", "Dera\ Ghazi\ Khan",
"92928", "Bannu\/N\.\ Waziristan",
"928264", "K\.Abdullah\/Pishin",
"924539", "Bhakkar",
"929452", "Lower\ Dir",
"92574", "Attock",
"929698", "Lakki\ Marwat",
"928446", "Kalat",
"928482", "Khuzdar",
"92476", "Jhang",
"925464", "Mandi\ Bahauddin",
"92862", "Gwadar",
"92445", "Okara",
"92998", "Kohistan",
"929965", "Shangla",
"928244", "Loralai",
"922978", "Badin",
"925472", "Hafizabad",
"922384", "Umerkot",
"929433", "Chitral",
"926085", "Lodhran",
"92656", "Khanewal",
"92662", "Muzaffargarh",
"928477", "Kharan",
"92625", "Bahawalpur",
"92529", "Sialkot",
"928337", "Sibi\/Ziarat",
"92499", "Kasur",
"92222", "Hyderabad",
"92253", "Dadu",
"924594", "Mianwali",
"929373", "Mardan",
"92742", "Larkana",
"929432", "Chitral",
"92572", "Attock",
"929655", "South\ Waziristan",
"928534", "Lasbela",
"928224", "Zhob",
"929225", "Kohat",
"929372", "Mardan",
"924536", "Bhakkar",
"92537", "Gujrat",
"92864", "Gwadar",
"92664", "Muzaffargarh",
"922439", "Khairpur",
"92688", "Rahim\ Yar\ Khan",
"927239", "Ghotki",
"928483", "Khuzdar",
"922335", "Mirpur\ Khas",
"922985", "Thatta",
"92217", "Karachi",
"92744", "Larkana",
"92638", "Bahawalnagar",
"92224", "Hyderabad",
"929468", "Swat",
"925473", "Hafizabad",
"929387", "Swabi",
"92255", "Dadu",
"9258", "AJK\/FATA",
"92666", "Muzaffargarh",
"929667", "D\.I\.\ Khan",
"928357", "Dera\ Bugti",
"92623", "Bahawalpur",
"92652", "Khanewal",
"92746", "Larkana",
"92718", "Sukkur",
"929448", "Upper\ Dir",
"92226", "Hyderabad",
"929453", "Lower\ Dir",
"925424", "Narowal",
"92472", "Jhang",
"92487", "Sargodha",
"928449", "Kalat",
"92443", "Okara",
"929925", "Abottabad",
"922327", "Tharparkar",
"92866", "Gwadar",
"929638", "Tank",
"922322", "Tharparkar",
"929953", "Haripur",
"92717", "Sukkur",
"928283", "Musakhel",
"928328", "Bolan",
"924578", "Pakpattan",
"928559", "Panjgur",
"922358", "Sanghar",
"925449", "Jhelum",
"929425", "Bajaur\ Agency",
"92912", "Peshawar\/Charsadda",
"929329", "Malakand",
"92259", "Dadu",
"929662", "D\.I\.\ Khan",
"928352", "Dera\ Bugti",
"92493", "Kasur",
"928269", "K\.Abdullah\/Pishin",
"924534", "Bhakkar",
"92488", "Sargodha",
"92566", "Sheikhupura",
"92464", "Toba\ Tek\ Singh",
"92552", "Gujranwala",
"92523", "Sialkot",
"928536", "Lasbela",
"928226", "Zhob",
"92538", "Gujrat",
"925469", "Mandi\ Bahauddin",
"929382", "Swabi",
"925426", "Narowal",
"92402", "Sahiwal",
"92564", "Sheikhupura",
"926088", "Lodhran",
"928249", "Loralai",
"92423", "Lahore",
"92466", "Toba\ Tek\ Singh",
"929377", "Mardan",
"922389", "Umerkot",
"929968", "Shangla",
"92218", "Karachi",
"922975", "Badin",
"92637", "Bahawalnagar",
"928333", "Sibi\/Ziarat",
"92643", "Dera\ Ghazi\ Khan",
"928473", "Kharan",
"92687", "Rahim\ Yar\ Khan",
"924599", "Mianwali",
"92672", "Vehari",
"929695", "Lakki\ Marwat",
"929437", "Chitral",
"928372", "Jhal\ Magsi",
"927238", "Ghotki",
"928535", "Lasbela",
"928225", "Zhob",
"929224", "Kohat",
"928293", "Barkhan\/Kohlu",
"922438", "Khairpur",
"929469", "Swat",
"92412", "Faisalabad",
"929654", "South\ Waziristan",
"929426", "Bajaur\ Agency",
"928432", "Mastung",
"928387", "Jaffarabad\/Nasirabad",
"92258", "Dadu",
"925437", "Chakwal",
"92489", "Sargodha",
"924543", "Khushab",
"922984", "Thatta",
"922334", "Mirpur\ Khas",
"929973", "Mansehra\/Batagram",
"927262", "Shikarpur",
"92715", "Sukkur",
"92685", "Rahim\ Yar\ Khan",
"928448", "Kalat",
"929696", "Lakki\ Marwat",
"92635", "Bahawalnagar",
"92539", "Gujrat",
"928237", "Killa\ Saifullah",
"928527", "Kech",
"922976", "Badin",
"929392", "Buner",
"922442", "Nawabshah",
"929924", "Abottabad",
"92923", "Nowshera",
"929449", "Upper\ Dir",
"927223", "Jacobabad",
"922423", "Naushero\ Feroze",
"92219", "Karachi",
"925425", "Narowal",
"92512", "Islamabad\/Rawalpindi",
"922986", "Thatta",
"925448", "Jhelum",
"922359", "Sanghar",
"928558", "Panjgur",
"92215", "Karachi",
"929328", "Malakand",
"92612", "Multan",
"928268", "K\.Abdullah\/Pishin",
"922336", "Mirpur\ Khas",
"928232", "Killa\ Saifullah",
"928522", "Kech",
"929226", "Kohat",
"929397", "Buner",
"922447", "Nawabshah",
"929639", "Tank",
"92535", "Gujrat",
"92639", "Bahawalnagar",
"924535", "Bhakkar",
"926043", "Rajanpur",
"928329", "Bolan",
"924579", "Pakpattan",
"92689", "Rahim\ Yar\ Khan",
"92812", "Quetta",
"929424", "Bajaur\ Agency",
"929656", "South\ Waziristan",
"927267", "Shikarpur",
"929926", "Abottabad",
"92719", "Sukkur",
"922388", "Umerkot",
"929969", "Shangla",
"924598", "Mianwali",
"925432", "Chakwal",
"926063", "Layyah",
"928382", "Jaffarabad\/Nasirabad",
"92485", "Sargodha",
"928437", "Mastung",
"925468", "Mandi\ Bahauddin",
"929694", "Lakki\ Marwat",
"928563", "Awaran",
"928248", "Loralai",
"922974", "Badin",
"926089", "Lodhran",
"92257", "Dadu",
"928377", "Jhal\ Magsi",
"928253", "Chagai",
"925479", "Hafizabad",
"92467", "Toba\ Tek\ Singh",
"92513", "Islamabad\/Rawalpindi",
"925435", "Chakwal",
"927233", "Ghotki",
"928489", "Khuzdar",
"928385", "Jaffarabad\/Nasirabad",
"929384", "Swabi",
"922433", "Khairpur",
"928298", "Barkhan\/Kohlu",
"929978", "Mansehra\/Batagram",
"92636", "Bahawalnagar",
"92714", "Sukkur",
"928537", "Lasbela",
"928227", "Zhob",
"924548", "Khushab",
"92686", "Rahim\ Yar\ Khan",
"925427", "Narowal",
"92228", "Hyderabad",
"92748", "Larkana",
"92634", "Bahawalnagar",
"92716", "Sukkur",
"92668", "Muzaffargarh",
"928443", "Kalat",
"922324", "Tharparkar",
"92684", "Rahim\ Yar\ Khan",
"927228", "Jacobabad",
"922428", "Naushero\ Feroze",
"928235", "Killa\ Saifullah",
"928525", "Kech",
"92868", "Gwadar",
"928354", "Dera\ Bugti",
"929664", "D\.I\.\ Khan",
"929459", "Lower\ Dir",
"924532", "Bhakkar",
"929376", "Mardan",
"929436", "Chitral",
"92413", "Faisalabad",
"92567", "Sheikhupura",
"928263", "K\.Abdullah\/Pishin",
"92667", "Muzaffargarh",
"925443", "Jhelum",
"924537", "Bhakkar",
"928553", "Panjgur",
"929395", "Buner",
"922445", "Nawabshah",
"92747", "Larkana",
"92214", "Karachi",
"929323", "Malakand",
"92227", "Hyderabad",
"928289", "Musakhel",
"926048", "Rajanpur",
"92568", "Sheikhupura",
"92486", "Sargodha",
"929959", "Haripur",
"929386", "Swabi",
"92867", "Gwadar",
"92534", "Gujrat",
"925422", "Narowal",
"92484", "Sargodha",
"929374", "Mardan",
"928375", "Jhal\ Magsi",
"926068", "Layyah",
"924593", "Mianwali",
"929666", "D\.I\.\ Khan",
"928356", "Dera\ Bugti",
"928479", "Kharan",
"928532", "Lasbela",
"928222", "Zhob",
"92468", "Toba\ Tek\ Singh",
"92536", "Gujrat",
"928339", "Sibi\/Ziarat",
"922383", "Umerkot",
"929434", "Chitral",
"928435", "Mastung",
"92813", "Quetta",
"928243", "Loralai",
"92613", "Multan",
"928258", "Chagai",
"925463", "Mandi\ Bahauddin",
"922326", "Tharparkar",
"92216", "Karachi",
"928568", "Awaran",
"927265", "Shikarpur",
"92865", "Gwadar",
"929385", "Swabi",
"928384", "Jaffarabad\/Nasirabad",
"92442", "Okara",
"929979", "Mansehra\/Batagram",
"925434", "Chakwal",
"922987", "Thatta",
"92473", "Jhang",
"922337", "Mirpur\ Khas",
"924549", "Khushab",
"92622", "Bahawalpur",
"92653", "Khanewal",
"929463", "Swat",
"929396", "Buner",
"922446", "Nawabshah",
"922972", "Badin",
"925478", "Hafizabad",
"92225", "Hyderabad",
"92745", "Larkana",
"929227", "Kohat",
"929657", "South\ Waziristan",
"92569", "Sheikhupura",
"92665", "Muzaffargarh",
"928299", "Barkhan\/Kohlu",
"928488", "Khuzdar",
"92256", "Dadu",
"929692", "Lakki\ Marwat",
"922429", "Naushero\ Feroze",
"922325", "Tharparkar",
"929443", "Upper\ Dir",
"927229", "Jacobabad",
"929458", "Lower\ Dir",
"929927", "Abottabad",
"927266", "Shikarpur",
"92469", "Toba\ Tek\ Singh",
"92254", "Dadu",
"92573", "Attock",
"928436", "Mastung",
"929422", "Bajaur\ Agency",
"928376", "Jhal\ Magsi",
"929665", "D\.I\.\ Khan",
"928355", "Dera\ Bugti",
"928234", "Killa\ Saifullah",
"928524", "Kech",
"926049", "Rajanpur",
"928323", "Bolan",
"924573", "Pakpattan",
"922444", "Nawabshah",
"928288", "Musakhel",
"929394", "Buner",
"92673", "Vehari",
"929633", "Tank",
"929958", "Haripur",
"929427", "Bajaur\ Agency",
"92642", "Dera\ Ghazi\ Khan",
"92465", "Toba\ Tek\ Singh",
"925436", "Chakwal",
"928386", "Jaffarabad\/Nasirabad",
"929922", "Abottabad",
"922353", "Sanghar",
"92422", "Lahore",
"92403", "Sahiwal",
"92913", "Peshawar\/Charsadda",
"929435", "Chitral",
"928434", "Mastung",
"926083", "Lodhran",
"929697", "Lakki\ Marwat",
"92669", "Muzaffargarh",
"928259", "Chagai",
"92565", "Sheikhupura",
"929652", "South\ Waziristan",
"92522", "Sialkot",
"922977", "Badin",
"92553", "Gujranwala",
"929222", "Kohat",
"928236", "Killa\ Saifullah",
"928526", "Kech",
"92492", "Kasur",
"92229", "Hyderabad",
"92749", "Larkana",
"928374", "Jhal\ Magsi",
"928569", "Awaran",
"929375", "Mardan",
"928478", "Kharan",
"927264", "Shikarpur",
"926069", "Layyah",
"922332", "Mirpur\ Khas",
"92869", "Gwadar",
"922982", "Thatta",
"929963", "Shangla",
"928338", "Sibi\/Ziarat",};

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