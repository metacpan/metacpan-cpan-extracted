# automatically generated file, don't edit



# Copyright 2023 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20230903131448;

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
            3[0-79]|
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
$areanames{en} = {"929396", "Buner",
"929226", "Kohat",
"922422", "Naushero\ Feroze",
"922335", "Mirpur\ Khas",
"929428", "Bajaur\ Agency",
"92566", "Sheikhupura",
"92494", "Kasur",
"928536", "Lasbela",
"929693", "Lakki\ Marwat",
"926084", "Lodhran",
"929425", "Bajaur\ Agency",
"922338", "Mirpur\ Khas",
"928223", "Zhob",
"928477", "Kharan",
"92659", "Khanewal",
"925464", "Mandi\ Bahauddin",
"92615", "Multan",
"929383", "Swabi",
"92634", "Bahawalnagar",
"928386", "Jaffarabad\/Nasirabad",
"92663", "Muzaffargarh",
"929456", "Lower\ Dir",
"922429", "Naushero\ Feroze",
"926069", "Layyah",
"928249", "Loralai",
"92816", "Quetta",
"928485", "Khuzdar",
"92718", "Sukkur",
"92652", "Khanewal",
"92743", "Larkana",
"92624", "Bahawalpur",
"928286", "Musakhel",
"928488", "Khuzdar",
"928529", "Kech",
"922352", "Sanghar",
"927266", "Shikarpur",
"925446", "Jhelum",
"928522", "Kech",
"922359", "Sanghar",
"922443", "Nawabshah",
"929326", "Malakand",
"924533", "Bhakkar",
"929976", "Mansehra\/Batagram",
"9258", "AJK\/FATA",
"925433", "Chakwal",
"924546", "Khushab",
"927227", "Jacobabad",
"922436", "Khairpur",
"92226", "Hyderabad",
"926062", "Layyah",
"928293", "Barkhan\/Kohlu",
"928242", "Loralai",
"928323", "Bolan",
"92622", "Bahawalpur",
"922385", "Umerkot",
"92639", "Bahawalnagar",
"928474", "Kharan",
"922388", "Umerkot",
"928229", "Zhob",
"925467", "Mandi\ Bahauddin",
"92654", "Khanewal",
"929699", "Lakki\ Marwat",
"929382", "Swabi",
"929389", "Swabi",
"929692", "Lakki\ Marwat",
"926087", "Lodhran",
"928222", "Zhob",
"92867", "Gwadar",
"92427", "Lahore",
"929636", "Tank",
"925426", "Narowal",
"92256", "Dadu",
"922423", "Naushero\ Feroze",
"92499", "Kasur",
"92645", "Dera\ Ghazi\ Khan",
"92668", "Muzaffargarh",
"928336", "Sibi\/Ziarat",
"928435", "Mastung",
"924596", "Mianwali",
"925432", "Chakwal",
"927224", "Jacobabad",
"92713", "Sukkur",
"926063", "Layyah",
"929445", "Upper\ Dir",
"928292", "Barkhan\/Kohlu",
"928243", "Loralai",
"928322", "Bolan",
"928523", "Kech",
"928438", "Mastung",
"922442", "Nawabshah",
"924532", "Bhakkar",
"92748", "Larkana",
"92686", "Rahim\ Yar\ Khan",
"929448", "Upper\ Dir",
"92492", "Kasur",
"92927", "Karak",
"928236", "Killa\ Saifullah",
"92632", "Bahawalnagar",
"92629", "Bahawalpur",
"92476", "Jhang",
"922449", "Nawabshah",
"922353", "Sanghar",
"924539", "Bhakkar",
"928299", "Barkhan\/Kohlu",
"928329", "Bolan",
"925439", "Chakwal",
"92517", "Islamabad\/Rawalpindi",
"92923", "Nowshera",
"92464", "Toba\ Tek\ Singh",
"924572", "Pakpattan",
"928478", "Kharan",
"929466", "Swat",
"922384", "Umerkot",
"92717", "Sukkur",
"928475", "Kharan",
"92616", "Multan",
"925472", "Hafizabad",
"92513", "Islamabad\/Rawalpindi",
"929427", "Bajaur\ Agency",
"925479", "Hafizabad",
"924579", "Pakpattan",
"922337", "Mirpur\ Khas",
"92214", "Karachi",
"92572", "Attock",
"92565", "Sheikhupura",
"929444", "Upper\ Dir",
"92225", "Hyderabad",
"927225", "Jacobabad",
"928434", "Mastung",
"92579", "Attock",
"927228", "Jacobabad",
"928376", "Jhal\ Magsi",
"92863", "Gwadar",
"92423", "Lahore",
"929923", "Abottabad",
"928487", "Khuzdar",
"92815", "Quetta",
"929373", "Mardan",
"92219", "Karachi",
"926088", "Lodhran",
"922334", "Mirpur\ Khas",
"92255", "Dadu",
"92928", "Bannu\/N\.\ Waziristan",
"92646", "Dera\ Ghazi\ Khan",
"92747", "Larkana",
"926085", "Lodhran",
"929424", "Bajaur\ Agency",
"925465", "Mandi\ Bahauddin",
"92518", "Islamabad\/Rawalpindi",
"925473", "Hafizabad",
"925468", "Mandi\ Bahauddin",
"924573", "Pakpattan",
"922387", "Umerkot",
"92469", "Toba\ Tek\ Singh",
"929922", "Abottabad",
"928484", "Khuzdar",
"929372", "Mardan",
"92475", "Jhang",
"92462", "Toba\ Tek\ Singh",
"92212", "Karachi",
"92574", "Attock",
"92868", "Gwadar",
"92428", "Lahore",
"92685", "Rahim\ Yar\ Khan",
"92667", "Muzaffargarh",
"929379", "Mardan",
"929447", "Upper\ Dir",
"929929", "Abottabad",
"928437", "Mastung",
"92642", "Dera\ Ghazi\ Khan",
"92678", "Vehari",
"928252", "Chagai",
"922386", "Umerkot",
"929464", "Swat",
"928335", "Sibi\/Ziarat",
"92557", "Gujranwala",
"928259", "Chagai",
"929635", "Tank",
"925425", "Narowal",
"928338", "Sibi\/Ziarat",
"92447", "Okara",
"92488", "Sargodha",
"92625", "Bahawalpur",
"929638", "Tank",
"925428", "Narowal",
"929659", "South\ Waziristan",
"928235", "Killa\ Saifullah",
"92614", "Multan",
"929433", "Chitral",
"929962", "Shangla",
"924598", "Mianwali",
"928359", "Dera\ Bugti",
"928443", "Kalat",
"928238", "Killa\ Saifullah",
"92466", "Toba\ Tek\ Singh",
"929446", "Upper\ Dir",
"922323", "Tharparkar",
"922973", "Badin",
"92635", "Bahawalnagar",
"928436", "Mastung",
"924595", "Mianwali",
"92495", "Kasur",
"92649", "Dera\ Ghazi\ Khan",
"928553", "Panjgur",
"92216", "Karachi",
"928374", "Jhal\ Magsi",
"929969", "Shangla",
"928352", "Dera\ Bugti",
"929652", "South\ Waziristan",
"92673", "Vehari",
"929426", "Bajaur\ Agency",
"92537", "Gujrat",
"929228", "Kohat",
"928535", "Lasbela",
"929398", "Buner",
"922336", "Mirpur\ Khas",
"92612", "Multan",
"929225", "Kohat",
"929395", "Buner",
"928538", "Lasbela",
"929455", "Lower\ Dir",
"92417", "Faisalabad",
"928253", "Chagai",
"928385", "Jaffarabad\/Nasirabad",
"929467", "Swat",
"929458", "Lower\ Dir",
"92407", "Sahiwal",
"928388", "Jaffarabad\/Nasirabad",
"92576", "Attock",
"92483", "Sargodha",
"928377", "Jhal\ Magsi",
"927265", "Shikarpur",
"928449", "Kalat",
"928353", "Dera\ Bugti",
"92917", "Peshawar\/Charsadda",
"928285", "Musakhel",
"929653", "South\ Waziristan",
"929439", "Chitral",
"92644", "Dera\ Ghazi\ Khan",
"927268", "Shikarpur",
"922979", "Badin",
"928486", "Khuzdar",
"928552", "Panjgur",
"928288", "Musakhel",
"922329", "Tharparkar",
"928559", "Panjgur",
"922322", "Tharparkar",
"929978", "Mansehra\/Batagram",
"924545", "Khushab",
"92527", "Sialkot",
"922972", "Badin",
"922435", "Khairpur",
"929328", "Malakand",
"925448", "Jhelum",
"92619", "Multan",
"929975", "Mansehra\/Batagram",
"929432", "Chitral",
"92655", "Khanewal",
"922438", "Khairpur",
"929325", "Malakand",
"924548", "Khushab",
"929963", "Shangla",
"925445", "Jhelum",
"928442", "Kalat",
"928534", "Lasbela",
"92626", "Bahawalpur",
"926086", "Lodhran",
"92479", "Jhang",
"922983", "Thatta",
"929394", "Buner",
"929637", "Tank",
"925427", "Narowal",
"92913", "Peshawar\/Charsadda",
"929224", "Kohat",
"927233", "Ghotki",
"926049", "Rajanpur",
"92814", "Quetta",
"928269", "K\.Abdullah\/Pishin",
"928337", "Sibi\/Ziarat",
"92224", "Hyderabad",
"926042", "Rajanpur",
"928384", "Jaffarabad\/Nasirabad",
"928262", "K\.Abdullah\/Pishin",
"929454", "Lower\ Dir",
"92523", "Sialkot",
"92689", "Rahim\ Yar\ Khan",
"925466", "Mandi\ Bahauddin",
"92252", "Dadu",
"929959", "Haripur",
"928284", "Musakhel",
"929662", "D\.I\.\ Khan",
"927264", "Shikarpur",
"92564", "Sheikhupura",
"92682", "Rahim\ Yar\ Khan",
"92533", "Gujrat",
"92496", "Kasur",
"928563", "Awaran",
"92259", "Dadu",
"92215", "Karachi",
"92677", "Vehari",
"924597", "Mianwali",
"92465", "Toba\ Tek\ Singh",
"92487", "Sargodha",
"924544", "Khushab",
"92448", "Okara",
"922434", "Khairpur",
"92636", "Bahawalnagar",
"92403", "Sahiwal",
"92472", "Jhang",
"925444", "Jhelum",
"92558", "Gujranwala",
"929669", "D\.I\.\ Khan",
"929324", "Malakand",
"929974", "Mansehra\/Batagram",
"92413", "Faisalabad",
"929952", "Haripur",
"928237", "Killa\ Saifullah",
"92684", "Rahim\ Yar\ Khan",
"929468", "Swat",
"928476", "Kharan",
"92562", "Sheikhupura",
"922989", "Thatta",
"92575", "Attock",
"926043", "Rajanpur",
"929465", "Swat",
"928387", "Jaffarabad\/Nasirabad",
"92229", "Hyderabad",
"928263", "K\.Abdullah\/Pishin",
"929457", "Lower\ Dir",
"92918", "Peshawar\/Charsadda",
"927239", "Ghotki",
"929397", "Buner",
"925424", "Narowal",
"929634", "Tank",
"929227", "Kohat",
"927232", "Ghotki",
"92819", "Quetta",
"928334", "Sibi\/Ziarat",
"928537", "Lasbela",
"92474", "Jhang",
"92528", "Sialkot",
"922982", "Thatta",
"925447", "Jhelum",
"929327", "Malakand",
"92656", "Khanewal",
"929977", "Mansehra\/Batagram",
"929953", "Haripur",
"928234", "Killa\ Saifullah",
"92812", "Quetta",
"928569", "Awaran",
"924594", "Mianwali",
"924547", "Khushab",
"927226", "Jacobabad",
"922437", "Khairpur",
"92538", "Gujrat",
"92408", "Sahiwal",
"92569", "Sheikhupura",
"928562", "Awaran",
"92254", "Dadu",
"928378", "Jhal\ Magsi",
"92443", "Okara",
"92222", "Hyderabad",
"92418", "Faisalabad",
"928287", "Musakhel",
"929663", "D\.I\.\ Khan",
"92553", "Gujranwala",
"927267", "Shikarpur",
"928375", "Jhal\ Magsi",
"922988", "Thatta",
"92555", "Gujranwala",
"92519", "Islamabad\/Rawalpindi",
"929469", "Swat",
"927235", "Ghotki",
"92468", "Toba\ Tek\ Singh",
"922985", "Thatta",
"92445", "Okara",
"927238", "Ghotki",
"92627", "Bahawalpur",
"92422", "Lahore",
"92862", "Gwadar",
"92218", "Karachi",
"925476", "Hafizabad",
"928254", "Chagai",
"924576", "Pakpattan",
"929462", "Swat",
"92497", "Kasur",
"928565", "Awaran",
"928557", "Panjgur",
"92869", "Gwadar",
"92429", "Lahore",
"92676", "Vehari",
"928372", "Jhal\ Magsi",
"928354", "Dera\ Bugti",
"928568", "Awaran",
"929654", "South\ Waziristan",
"92512", "Islamabad\/Rawalpindi",
"929437", "Chitral",
"928379", "Jhal\ Magsi",
"929964", "Shangla",
"928447", "Kalat",
"922327", "Tharparkar",
"92573", "Attock",
"92486", "Sargodha",
"922977", "Badin",
"92637", "Bahawalnagar",
"92415", "Faisalabad",
"928257", "Chagai",
"928265", "K\.Abdullah\/Pishin",
"929463", "Swat",
"926045", "Rajanpur",
"92405", "Sahiwal",
"92924", "Khyber\/Mohmand\ Agy",
"928268", "K\.Abdullah\/Pishin",
"92463", "Toba\ Tek\ Singh",
"926048", "Rajanpur",
"92213", "Karachi",
"92535", "Gujrat",
"92514", "Islamabad\/Rawalpindi",
"929958", "Haripur",
"922324", "Tharparkar",
"922974", "Badin",
"92525", "Sialkot",
"929955", "Haripur",
"92657", "Khanewal",
"929434", "Chitral",
"929967", "Shangla",
"928444", "Kalat",
"928373", "Jhal\ Magsi",
"929665", "D\.I\.\ Khan",
"928357", "Dera\ Bugti",
"929657", "South\ Waziristan",
"92915", "Peshawar\/Charsadda",
"929668", "D\.I\.\ Khan",
"929926", "Abottabad",
"929376", "Mardan",
"928554", "Panjgur",
"92578", "Attock",
"92424", "Lahore",
"92864", "Gwadar",
"926044", "Rajanpur",
"928382", "Jaffarabad\/Nasirabad",
"928264", "K\.Abdullah\/Pishin",
"929399", "Buner",
"929229", "Kohat",
"92653", "Khanewal",
"929452", "Lower\ Dir",
"92742", "Larkana",
"92669", "Muzaffargarh",
"92498", "Kasur",
"928539", "Lasbela",
"928532", "Lasbela",
"92446", "Okara",
"92638", "Bahawalnagar",
"922987", "Thatta",
"929392", "Buner",
"929633", "Tank",
"925423", "Narowal",
"92556", "Gujranwala",
"929222", "Kohat",
"922426", "Naushero\ Feroze",
"927237", "Ghotki",
"929459", "Lower\ Dir",
"928389", "Jaffarabad\/Nasirabad",
"928333", "Sibi\/Ziarat",
"928448", "Kalat",
"924593", "Mianwali",
"924542", "Khushab",
"922975", "Badin",
"92485", "Sargodha",
"922432", "Khairpur",
"92467", "Toba\ Tek\ Singh",
"922325", "Tharparkar",
"929438", "Chitral",
"926066", "Layyah",
"92628", "Bahawalpur",
"928246", "Loralai",
"928526", "Kech",
"925442", "Jhelum",
"928445", "Kalat",
"92714", "Sukkur",
"929322", "Malakand",
"922978", "Badin",
"927269", "Shikarpur",
"929972", "Mansehra\/Batagram",
"929435", "Chitral",
"922328", "Tharparkar",
"929954", "Haripur",
"928289", "Musakhel",
"928233", "Killa\ Saifullah",
"929979", "Mansehra\/Batagram",
"928282", "Musakhel",
"928558", "Panjgur",
"925449", "Jhelum",
"929664", "D\.I\.\ Khan",
"929329", "Malakand",
"922356", "Sanghar",
"927262", "Shikarpur",
"92749", "Larkana",
"928555", "Panjgur",
"92662", "Muzaffargarh",
"92217", "Karachi",
"928567", "Awaran",
"92998", "Kohistan",
"92675", "Vehari",
"924549", "Khushab",
"922439", "Khairpur",
"929393", "Buner",
"925422", "Narowal",
"929632", "Tank",
"92658", "Khanewal",
"929223", "Kohat",
"927234", "Ghotki",
"92712", "Sukkur",
"928332", "Sibi\/Ziarat",
"928533", "Lasbela",
"929696", "Lakki\ Marwat",
"92536", "Gujrat",
"92493", "Kasur",
"922984", "Thatta",
"928226", "Zhob",
"92406", "Sahiwal",
"92633", "Bahawalnagar",
"92664", "Muzaffargarh",
"928258", "Chagai",
"92577", "Attock",
"929386", "Swabi",
"92416", "Faisalabad",
"926047", "Rajanpur",
"928383", "Jaffarabad\/Nasirabad",
"928267", "K\.Abdullah\/Pishin",
"928339", "Sibi\/Ziarat",
"928255", "Chagai",
"929639", "Tank",
"925429", "Narowal",
"929453", "Lower\ Dir",
"92623", "Bahawalpur",
"92744", "Larkana",
"929658", "South\ Waziristan",
"928358", "Dera\ Bugti",
"928564", "Awaran",
"924599", "Mianwali",
"928283", "Musakhel",
"929655", "South\ Waziristan",
"928239", "Killa\ Saifullah",
"928355", "Dera\ Bugti",
"929667", "D\.I\.\ Khan",
"92916", "Peshawar\/Charsadda",
"927263", "Shikarpur",
"929965", "Shangla",
"925443", "Jhelum",
"92719", "Sukkur",
"922446", "Nawabshah",
"929323", "Malakand",
"924536", "Bhakkar",
"929973", "Mansehra\/Batagram",
"929957", "Haripur",
"928232", "Killa\ Saifullah",
"929968", "Shangla",
"925436", "Chakwal",
"924592", "Mianwali",
"924543", "Khushab",
"922433", "Khairpur",
"928296", "Barkhan\/Kohlu",
"92526", "Sialkot",
"928326", "Bolan",
"928473", "Kharan",
"926089", "Lodhran",
"92818", "Quetta",
"92617", "Multan",
"925462", "Mandi\ Bahauddin",
"92716", "Sukkur",
"929387", "Swabi",
"92529", "Sialkot",
"926046", "Rajanpur",
"92683", "Rahim\ Yar\ Khan",
"92532", "Gujrat",
"928266", "K\.Abdullah\/Pishin",
"922424", "Naushero\ Feroze",
"92402", "Sahiwal",
"92473", "Jhang",
"92919", "Peshawar\/Charsadda",
"925469", "Mandi\ Bahauddin",
"929697", "Lakki\ Marwat",
"92412", "Faisalabad",
"92228", "Hyderabad",
"926082", "Lodhran",
"928227", "Zhob",
"928524", "Kech",
"922447", "Nawabshah",
"924537", "Bhakkar",
"92568", "Sheikhupura",
"92409", "Sahiwal",
"929956", "Haripur",
"925437", "Chakwal",
"92912", "Peshawar\/Charsadda",
"927223", "Jacobabad",
"926064", "Layyah",
"928297", "Barkhan\/Kohlu",
"928244", "Loralai",
"92419", "Faisalabad",
"928327", "Bolan",
"929375", "Mardan",
"929925", "Abottabad",
"92554", "Gujranwala",
"92539", "Gujrat",
"92522", "Sialkot",
"929378", "Mardan",
"929928", "Abottabad",
"929666", "D\.I\.\ Khan",
"922354", "Sanghar",
"92444", "Okara",
"92253", "Dadu",
"929694", "Lakki\ Marwat",
"92914", "Peshawar\/Charsadda",
"928479", "Kharan",
"926083", "Lodhran",
"922986", "Thatta",
"928224", "Zhob",
"92813", "Quetta",
"92425", "Lahore",
"92865", "Gwadar",
"922427", "Naushero\ Feroze",
"927236", "Ghotki",
"92688", "Rahim\ Yar\ Khan",
"92746", "Larkana",
"92647", "Dera\ Ghazi\ Khan",
"925478", "Hafizabad",
"92478", "Jhang",
"924575", "Pakpattan",
"92524", "Sialkot",
"92442", "Okara",
"928472", "Kharan",
"92223", "Hyderabad",
"925475", "Hafizabad",
"924578", "Pakpattan",
"925463", "Mandi\ Bahauddin",
"92552", "Gujranwala",
"929384", "Swabi",
"92563", "Sheikhupura",
"92534", "Gujrat",
"92449", "Okara",
"922357", "Sanghar",
"928566", "Awaran",
"92515", "Islamabad\/Rawalpindi",
"92559", "Gujranwala",
"927229", "Jacobabad",
"925434", "Chakwal",
"927222", "Jacobabad",
"926067", "Layyah",
"92414", "Faisalabad",
"928294", "Barkhan\/Kohlu",
"928247", "Loralai",
"928324", "Bolan",
"928527", "Kech",
"92258", "Dadu",
"922444", "Nawabshah",
"924534", "Bhakkar",
"92925", "Hangu\/Orakzai\ Agy",
"92404", "Sahiwal",
"92666", "Muzaffargarh",
"928225", "Zhob",
"929423", "Bajaur\ Agency",
"929695", "Lakki\ Marwat",
"92674", "Vehari",
"928228", "Zhob",
"922333", "Mirpur\ Khas",
"922389", "Umerkot",
"929698", "Lakki\ Marwat",
"92567", "Sheikhupura",
"929388", "Swabi",
"928256", "Chagai",
"924574", "Pakpattan",
"92484", "Sargodha",
"922382", "Umerkot",
"929385", "Swabi",
"92715", "Sukkur",
"925474", "Hafizabad",
"92643", "Dera\ Ghazi\ Khan",
"928356", "Dera\ Bugti",
"929656", "South\ Waziristan",
"92817", "Quetta",
"928439", "Mastung",
"929927", "Abottabad",
"928483", "Khuzdar",
"929377", "Mardan",
"929449", "Upper\ Dir",
"92618", "Multan",
"928325", "Bolan",
"929442", "Upper\ Dir",
"928295", "Barkhan\/Kohlu",
"924538", "Bhakkar",
"922448", "Nawabshah",
"92227", "Hyderabad",
"928432", "Mastung",
"925435", "Chakwal",
"928328", "Bolan",
"928298", "Barkhan\/Kohlu",
"922445", "Nawabshah",
"924535", "Bhakkar",
"925438", "Chakwal",
"929966", "Shangla",
"929429", "Bajaur\ Agency",
"925477", "Hafizabad",
"924577", "Pakpattan",
"92489", "Sargodha",
"922339", "Mirpur\ Khas",
"922383", "Umerkot",
"92257", "Dadu",
"92426", "Lahore",
"92866", "Gwadar",
"922332", "Mirpur\ Khas",
"92679", "Vehari",
"92745", "Larkana",
"922425", "Naushero\ Feroze",
"929422", "Bajaur\ Agency",
"922428", "Naushero\ Feroze",
"92672", "Vehari",
"928248", "Loralai",
"929436", "Chitral",
"926068", "Layyah",
"92648", "Dera\ Ghazi\ Khan",
"92926", "Kurram\ Agency",
"928525", "Kech",
"928446", "Kalat",
"92665", "Muzaffargarh",
"92687", "Rahim\ Yar\ Khan",
"928245", "Loralai",
"929443", "Upper\ Dir",
"926065", "Layyah",
"92613", "Multan",
"922326", "Tharparkar",
"922976", "Badin",
"928433", "Mastung",
"928489", "Khuzdar",
"928528", "Kech",
"922358", "Sanghar",
"929924", "Abottabad",
"928482", "Khuzdar",
"928556", "Panjgur",
"929374", "Mardan",
"92516", "Islamabad\/Rawalpindi",
"922355", "Sanghar",
"92477", "Jhang",
"92482", "Sargodha",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+92|\D)//g;
      my $self = bless({ country_code => '92', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '92', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;