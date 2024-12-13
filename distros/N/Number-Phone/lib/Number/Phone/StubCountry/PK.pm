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
package Number::Phone::StubCountry::PK;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20241212130806;

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
            [0-247]\\d|
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
$areanames{en} = {"927237", "Ghotki",
"92626", "Bahawalpur",
"927225", "Jacobabad",
"92409", "Sahiwal",
"929324", "Malakand",
"929452", "Lower\ Dir",
"92868", "Gwadar",
"929372", "Mardan",
"928525", "Kech",
"928537", "Lasbela",
"92424", "Lahore",
"92654", "Khanewal",
"928268", "K\.Abdullah\/Pishin",
"928233", "Killa\ Saifullah",
"929667", "D\.I\.\ Khan",
"929424", "Bajaur\ Agency",
"929962", "Shangla",
"929439", "Chitral",
"929656", "South\ Waziristan",
"92572", "Attock",
"92715", "Sukkur",
"92447", "Okara",
"928524", "Kech",
"927239", "Ghotki",
"922353", "Sanghar",
"927224", "Jacobabad",
"92496", "Kasur",
"92565", "Sheikhupura",
"928539", "Lasbela",
"928336", "Sibi\/Ziarat",
"929325", "Malakand",
"924596", "Mianwali",
"92408", "Sahiwal",
"929669", "D\.I\.\ Khan",
"928552", "Panjgur",
"929448", "Upper\ Dir",
"92567", "Sheikhupura",
"92914", "Peshawar\/Charsadda",
"925426", "Narowal",
"922446", "Nawabshah",
"92553", "Gujranwala",
"92445", "Okara",
"92869", "Gwadar",
"928436", "Mastung",
"92717", "Sukkur",
"929425", "Bajaur\ Agency",
"929437", "Chitral",
"926046", "Rajanpur",
"925466", "Mandi\ Bahauddin",
"924548", "Khushab",
"928244", "Loralai",
"929692", "Lakki\ Marwat",
"929975", "Mansehra\/Batagram",
"929465", "Swat",
"929634", "Tank",
"929396", "Buner",
"924537", "Bhakkar",
"92468", "Toba\ Tek\ Singh",
"928489", "Khuzdar",
"928375", "Jhal\ Magsi",
"92538", "Gujrat",
"928355", "Dera\ Bugti",
"92473", "Jhang",
"928564", "Awaran",
"925477", "Hafizabad",
"929955", "Haripur",
"92219", "Karachi",
"92223", "Hyderabad",
"928389", "Jaffarabad\/Nasirabad",
"928475", "Kharan",
"92492", "Kasur",
"927264", "Shikarpur",
"929635", "Tank",
"929464", "Swat",
"929922", "Abottabad",
"928228", "Zhob",
"926088", "Lodhran",
"928374", "Jhal\ Magsi",
"92576", "Attock",
"928322", "Bolan",
"928245", "Loralai",
"92218", "Karachi",
"92615", "Multan",
"92485", "Sargodha",
"928487", "Khuzdar",
"929974", "Mansehra\/Batagram",
"924539", "Bhakkar",
"924572", "Pakpattan",
"929954", "Haripur",
"925479", "Hafizabad",
"925432", "Chakwal",
"92487", "Sargodha",
"92617", "Multan",
"928474", "Kharan",
"92622", "Bahawalpur",
"927265", "Shikarpur",
"929386", "Swabi",
"928354", "Dera\ Bugti",
"922388", "Umerkot",
"928565", "Awaran",
"928387", "Jaffarabad\/Nasirabad",
"92539", "Gujrat",
"92469", "Toba\ Tek\ Singh",
"928297", "Barkhan\/Kohlu",
"929698", "Lakki\ Marwat",
"922334", "Mirpur\ Khas",
"924542", "Khushab",
"92528", "Sialkot",
"92686", "Rahim\ Yar\ Khan",
"92416", "Faisalabad",
"929383", "Swabi",
"922329", "Tharparkar",
"92746", "Larkana",
"922434", "Khairpur",
"928289", "Musakhel",
"928255", "Chagai",
"92614", "Multan",
"928444", "Kalat",
"92484", "Sargodha",
"922429", "Naushero\ Feroze",
"925449", "Jhelum",
"926082", "Lodhran",
"928222", "Zhob",
"929928", "Abottabad",
"928299", "Barkhan\/Kohlu",
"922335", "Mirpur\ Khas",
"922327", "Tharparkar",
"928328", "Bolan",
"924578", "Pakpattan",
"92642", "Dera\ Ghazi\ Khan",
"92926", "Kurram\ Agency",
"925438", "Chakwal",
"928254", "Chagai",
"928445", "Kalat",
"925463", "Mandi\ Bahauddin",
"928287", "Musakhel",
"92513", "Islamabad\/Rawalpindi",
"92529", "Sialkot",
"92812", "Quetta",
"922382", "Umerkot",
"922427", "Naushero\ Feroze",
"922435", "Khairpur",
"925447", "Jhelum",
"929393", "Buner",
"92632", "Bahawalnagar",
"922977", "Badin",
"929458", "Lower\ Dir",
"926067", "Layyah",
"922443", "Nawabshah",
"92915", "Peshawar\/Charsadda",
"925423", "Narowal",
"929378", "Mardan",
"92444", "Okara",
"92636", "Bahawalnagar",
"928433", "Mastung",
"92816", "Quetta",
"926043", "Rajanpur",
"929224", "Kohat",
"92259", "Dadu",
"92714", "Sukkur",
"929968", "Shangla",
"922356", "Sanghar",
"928262", "K\.Abdullah\/Pishin",
"92646", "Dera\ Ghazi\ Khan",
"92564", "Sheikhupura",
"92917", "Peshawar\/Charsadda",
"92679", "Vehari",
"928333", "Sibi\/Ziarat",
"922984", "Thatta",
"924593", "Mianwali",
"92425", "Lahore",
"92258", "Dadu",
"92655", "Khanewal",
"926069", "Layyah",
"928236", "Killa\ Saifullah",
"922979", "Badin",
"92742", "Larkana",
"929225", "Kohat",
"929653", "South\ Waziristan",
"92678", "Vehari",
"92663", "Muzaffargarh",
"929442", "Upper\ Dir",
"922985", "Thatta",
"928558", "Panjgur",
"92427", "Lahore",
"92682", "Rahim\ Yar\ Khan",
"92657", "Khanewal",
"92412", "Faisalabad",
"928323", "Bolan",
"92919", "Peshawar\/Charsadda",
"92677", "Vehari",
"92923", "Nowshera",
"924573", "Pakpattan",
"92257", "Dadu",
"929923", "Abottabad",
"922989", "Thatta",
"92864", "Gwadar",
"929398", "Buner",
"92658", "Khanewal",
"92255", "Dadu",
"92428", "Lahore",
"92675", "Vehari",
"92516", "Islamabad\/Rawalpindi",
"926065", "Layyah",
"924546", "Khushab",
"925468", "Mandi\ Bahauddin",
"925433", "Chakwal",
"922975", "Badin",
"929229", "Kohat",
"922386", "Umerkot",
"92683", "Rahim\ Yar\ Khan",
"92413", "Faisalabad",
"929388", "Swabi",
"92429", "Lahore",
"92659", "Khanewal",
"929693", "Lakki\ Marwat",
"922987", "Thatta",
"92662", "Muzaffargarh",
"926064", "Layyah",
"92918", "Peshawar\/Charsadda",
"922974", "Badin",
"92404", "Sahiwal",
"928226", "Zhob",
"926086", "Lodhran",
"92743", "Larkana",
"929227", "Kohat",
"922439", "Khairpur",
"928257", "Chagai",
"928284", "Musakhel",
"929658", "South\ Waziristan",
"92534", "Gujrat",
"928449", "Kalat",
"92464", "Toba\ Tek\ Singh",
"922424", "Naushero\ Feroze",
"928266", "K\.Abdullah\/Pishin",
"925444", "Jhelum",
"922352", "Sanghar",
"922339", "Mirpur\ Khas",
"92666", "Muzaffargarh",
"928295", "Barkhan\/Kohlu",
"928553", "Panjgur",
"922324", "Tharparkar",
"928259", "Chagai",
"92633", "Bahawalnagar",
"929373", "Mardan",
"926048", "Rajanpur",
"92813", "Quetta",
"922437", "Khairpur",
"922425", "Naushero\ Feroze",
"928438", "Mastung",
"925445", "Jhelum",
"928447", "Kalat",
"925428", "Narowal",
"922448", "Nawabshah",
"92527", "Sialkot",
"928285", "Musakhel",
"92214", "Karachi",
"929446", "Upper\ Dir",
"92512", "Islamabad\/Rawalpindi",
"929453", "Lower\ Dir",
"92525", "Sialkot",
"92643", "Dera\ Ghazi\ Khan",
"928294", "Barkhan\/Kohlu",
"924598", "Mianwali",
"922325", "Tharparkar",
"922337", "Mirpur\ Khas",
"928338", "Sibi\/Ziarat",
"928232", "Killa\ Saifullah",
"929963", "Shangla",
"92524", "Sialkot",
"92222", "Hyderabad",
"928569", "Awaran",
"928477", "Kharan",
"92217", "Karachi",
"92493", "Kasur",
"929957", "Haripur",
"929652", "South\ Waziristan",
"925475", "Hafizabad",
"922358", "Sanghar",
"927269", "Shikarpur",
"928357", "Dera\ Bugti",
"929966", "Shangla",
"928384", "Jaffarabad\/Nasirabad",
"92472", "Jhang",
"92998", "Kohistan",
"928377", "Jhal\ Magsi",
"929376", "Mardan",
"92556", "Gujranwala",
"928249", "Loralai",
"929467", "Swat",
"924535", "Bhakkar",
"929977", "Mansehra\/Batagram",
"929639", "Tank",
"929456", "Lower\ Dir",
"929443", "Upper\ Dir",
"92488", "Sargodha",
"92618", "Multan",
"92215", "Karachi",
"928484", "Khuzdar",
"929959", "Haripur",
"925474", "Hafizabad",
"928432", "Mastung",
"92537", "Gujrat",
"926042", "Rajanpur",
"92467", "Toba\ Tek\ Singh",
"928567", "Awaran",
"928385", "Jaffarabad\/Nasirabad",
"928479", "Kharan",
"927267", "Shikarpur",
"928359", "Dera\ Bugti",
"92623", "Bahawalpur",
"92619", "Multan",
"928556", "Panjgur",
"92489", "Sargodha",
"922442", "Nawabshah",
"925422", "Narowal",
"929469", "Swat",
"928332", "Sibi\/Ziarat",
"928247", "Loralai",
"924592", "Mianwali",
"928379", "Jhal\ Magsi",
"928485", "Khuzdar",
"92535", "Gujrat",
"92465", "Toba\ Tek\ Singh",
"929637", "Tank",
"928238", "Killa\ Saifullah",
"929979", "Mansehra\/Batagram",
"924534", "Bhakkar",
"928263", "K\.Abdullah\/Pishin",
"92573", "Attock",
"929429", "Bajaur\ Agency",
"92405", "Sahiwal",
"926083", "Lodhran",
"928223", "Zhob",
"929665", "D\.I\.\ Khan",
"929434", "Chitral",
"92448", "Okara",
"922383", "Umerkot",
"928535", "Lasbela",
"928527", "Kech",
"929392", "Buner",
"929329", "Malakand",
"92718", "Sukkur",
"929696", "Lakki\ Marwat",
"925462", "Mandi\ Bahauddin",
"92407", "Sahiwal",
"92568", "Sheikhupura",
"927227", "Jacobabad",
"927235", "Ghotki",
"92867", "Gwadar",
"929382", "Swabi",
"929435", "Chitral",
"929664", "D\.I\.\ Khan",
"929427", "Bajaur\ Agency",
"92552", "Gujranwala",
"92254", "Dadu",
"92719", "Sukkur",
"92674", "Vehari",
"925436", "Chakwal",
"924543", "Khushab",
"92569", "Sheikhupura",
"928326", "Bolan",
"929327", "Malakand",
"927234", "Ghotki",
"92226", "Hyderabad",
"924576", "Pakpattan",
"928529", "Kech",
"929926", "Abottabad",
"92476", "Jhang",
"928534", "Lasbela",
"927229", "Jacobabad",
"92865", "Gwadar",
"92449", "Okara",
"929636", "Tank",
"929394", "Buner",
"929459", "Lower\ Dir",
"92402", "Sahiwal",
"925464", "Mandi\ Bahauddin",
"929379", "Mardan",
"928246", "Loralai",
"928253", "Chagai",
"92466", "Toba\ Tek\ Singh",
"92536", "Gujrat",
"928557", "Panjgur",
"929969", "Shangla",
"927266", "Shikarpur",
"929385", "Swabi",
"92579", "Attock",
"928566", "Awaran",
"929432", "Chitral",
"92664", "Muzaffargarh",
"925465", "Mandi\ Bahauddin",
"928443", "Kalat",
"929457", "Lower\ Dir",
"926068", "Layyah",
"92555", "Gujranwala",
"929976", "Mansehra\/Batagram",
"927232", "Ghotki",
"92443", "Okara",
"922978", "Badin",
"929466", "Swat",
"928532", "Lasbela",
"92578", "Attock",
"92216", "Karachi",
"929395", "Buner",
"922433", "Khairpur",
"928376", "Jhal\ Magsi",
"929377", "Mardan",
"929384", "Swabi",
"928356", "Dera\ Bugti",
"929967", "Shangla",
"929662", "D\.I\.\ Khan",
"92563", "Sheikhupura",
"928559", "Panjgur",
"929956", "Haripur",
"92557", "Gujranwala",
"922333", "Mirpur\ Khas",
"928476", "Kharan",
"92713", "Sukkur",
"92862", "Gwadar",
"92628", "Bahawalpur",
"92225", "Hyderabad",
"929699", "Lakki\ Marwat",
"929927", "Abottabad",
"924577", "Pakpattan",
"92866", "Gwadar",
"922328", "Tharparkar",
"928335", "Sibi\/Ziarat",
"928327", "Bolan",
"929326", "Malakand",
"928482", "Khuzdar",
"924595", "Mianwali",
"92475", "Jhang",
"9258", "AJK\/FATA",
"92477", "Jhang",
"928288", "Musakhel",
"929654", "South\ Waziristan",
"925437", "Chakwal",
"925425", "Narowal",
"922445", "Nawabshah",
"92499", "Kasur",
"922428", "Naushero\ Feroze",
"925448", "Jhelum",
"928435", "Mastung",
"92227", "Hyderabad",
"928382", "Jaffarabad\/Nasirabad",
"929426", "Bajaur\ Agency",
"926045", "Rajanpur",
"92514", "Islamabad\/Rawalpindi",
"92212", "Karachi",
"927226", "Jacobabad",
"929929", "Abottabad",
"929697", "Lakki\ Marwat",
"928334", "Sibi\/Ziarat",
"928298", "Barkhan\/Kohlu",
"922983", "Thatta",
"924594", "Mianwali",
"92498", "Kasur",
"928329", "Bolan",
"928526", "Kech",
"924579", "Pakpattan",
"924532", "Bhakkar",
"925439", "Chakwal",
"92406", "Sahiwal",
"925472", "Hafizabad",
"92629", "Bahawalpur",
"928434", "Mastung",
"92613", "Multan",
"92483", "Sargodha",
"929223", "Kohat",
"926044", "Rajanpur",
"92532", "Gujrat",
"92462", "Toba\ Tek\ Singh",
"929655", "South\ Waziristan",
"925424", "Narowal",
"922444", "Nawabshah",
"924549", "Khushab",
"928235", "Killa\ Saifullah",
"928227", "Zhob",
"926087", "Lodhran",
"929226", "Kohat",
"92638", "Bahawalnagar",
"928488", "Khuzdar",
"92818", "Quetta",
"922322", "Tharparkar",
"927223", "Jacobabad",
"922986", "Thatta",
"928282", "Musakhel",
"92648", "Dera\ Ghazi\ Khan",
"922387", "Umerkot",
"928523", "Kech",
"928388", "Jaffarabad\/Nasirabad",
"925442", "Jhelum",
"922354", "Sanghar",
"922422", "Naushero\ Feroze",
"92256", "Dadu",
"928229", "Zhob",
"926089", "Lodhran",
"928292", "Barkhan\/Kohlu",
"924547", "Khushab",
"92649", "Dera\ Ghazi\ Khan",
"928234", "Killa\ Saifullah",
"924538", "Bhakkar",
"92676", "Vehari",
"929423", "Bajaur\ Agency",
"92515", "Islamabad\/Rawalpindi",
"92224", "Hyderabad",
"925478", "Hafizabad",
"92522", "Sialkot",
"92517", "Islamabad\/Rawalpindi",
"922355", "Sanghar",
"922389", "Umerkot",
"92639", "Bahawalnagar",
"92819", "Quetta",
"92474", "Jhang",
"929323", "Malakand",
"928353", "Dera\ Bugti",
"92526", "Sialkot",
"92418", "Faisalabad",
"92688", "Rahim\ Yar\ Khan",
"929953", "Haripur",
"922336", "Mirpur\ Khas",
"928473", "Kharan",
"928446", "Kalat",
"92748", "Larkana",
"929447", "Upper\ Dir",
"92252", "Dadu",
"928269", "K\.Abdullah\/Pishin",
"92554", "Gujranwala",
"929973", "Mansehra\/Batagram",
"929438", "Chitral",
"92672", "Vehari",
"929463", "Swat",
"922436", "Khairpur",
"92913", "Peshawar\/Charsadda",
"928373", "Jhal\ Magsi",
"926062", "Layyah",
"92749", "Larkana",
"922972", "Badin",
"927263", "Shikarpur",
"927238", "Ghotki",
"928563", "Awaran",
"928538", "Lasbela",
"92665", "Muzaffargarh",
"92928", "Bannu\/N\.\ Waziristan",
"929668", "D\.I\.\ Khan",
"92667", "Muzaffargarh",
"929633", "Tank",
"928267", "K\.Abdullah\/Pishin",
"929449", "Upper\ Dir",
"928256", "Chagai",
"928243", "Loralai",
"92689", "Rahim\ Yar\ Khan",
"92419", "Faisalabad",
"92423", "Lahore",
"92653", "Khanewal",
"92673", "Vehari",
"929428", "Bajaur\ Agency",
"92927", "Karak",
"928264", "K\.Abdullah\/Pishin",
"922426", "Naushero\ Feroze",
"924533", "Bhakkar",
"92912", "Peshawar\/Charsadda",
"925446", "Jhelum",
"92253", "Dadu",
"928286", "Musakhel",
"922982", "Thatta",
"929445", "Upper\ Dir",
"929328", "Malakand",
"922326", "Tharparkar",
"92925", "Hangu\/Orakzai\ Agy",
"92668", "Muzaffargarh",
"925473", "Hafizabad",
"929222", "Kohat",
"92422", "Lahore",
"92417", "Faisalabad",
"92687", "Rahim\ Yar\ Khan",
"92652", "Khanewal",
"92745", "Larkana",
"928483", "Khuzdar",
"929444", "Upper\ Dir",
"92669", "Muzaffargarh",
"928265", "K\.Abdullah\/Pishin",
"92574", "Attock",
"928383", "Jaffarabad\/Nasirabad",
"928528", "Kech",
"92747", "Larkana",
"927228", "Jacobabad",
"928296", "Barkhan\/Kohlu",
"92685", "Rahim\ Yar\ Khan",
"92415", "Faisalabad",
"922385", "Umerkot",
"928533", "Lasbela",
"928568", "Awaran",
"922432", "Khairpur",
"92624", "Bahawalpur",
"928442", "Kalat",
"927233", "Ghotki",
"922359", "Sanghar",
"927268", "Shikarpur",
"924544", "Khushab",
"922332", "Mirpur\ Khas",
"928248", "Loralai",
"92656", "Khanewal",
"92426", "Lahore",
"928225", "Zhob",
"928237", "Killa\ Saifullah",
"92518", "Islamabad\/Rawalpindi",
"926085", "Lodhran",
"929638", "Tank",
"929663", "D\.I\.\ Khan",
"928252", "Chagai",
"92637", "Bahawalnagar",
"929958", "Haripur",
"92817", "Quetta",
"928478", "Kharan",
"922384", "Umerkot",
"922357", "Sanghar",
"92519", "Islamabad\/Rawalpindi",
"928358", "Dera\ Bugti",
"92523", "Sialkot",
"92645", "Dera\ Ghazi\ Khan",
"92494", "Kasur",
"928224", "Zhob",
"92916", "Peshawar\/Charsadda",
"926084", "Lodhran",
"92647", "Dera\ Ghazi\ Khan",
"929468", "Swat",
"929433", "Chitral",
"928378", "Jhal\ Magsi",
"92815", "Quetta",
"926066", "Layyah",
"924545", "Khushab",
"922976", "Badin",
"929978", "Mansehra\/Batagram",
"928239", "Killa\ Saifullah",
"92635", "Bahawalnagar",
"922438", "Khairpur",
"928437", "Mastung",
"926047", "Rajanpur",
"929436", "Chitral",
"928562", "Awaran",
"92497", "Kasur",
"92213", "Karachi",
"92229", "Hyderabad",
"929659", "South\ Waziristan",
"926063", "Layyah",
"92814", "Quetta",
"925427", "Narowal",
"928448", "Kalat",
"925435", "Chakwal",
"92479", "Jhang",
"922447", "Nawabshah",
"922973", "Badin",
"927262", "Shikarpur",
"92634", "Bahawalnagar",
"92446", "Okara",
"928242", "Loralai",
"929694", "Lakki\ Marwat",
"922338", "Mirpur\ Khas",
"928325", "Bolan",
"928337", "Sibi\/Ziarat",
"924597", "Mianwali",
"92716", "Sukkur",
"924575", "Pakpattan",
"929925", "Abottabad",
"929632", "Tank",
"92566", "Sheikhupura",
"92644", "Dera\ Ghazi\ Khan",
"92495", "Kasur",
"929657", "South\ Waziristan",
"929952", "Haripur",
"925434", "Chakwal",
"928258", "Chagai",
"92533", "Gujrat",
"926049", "Rajanpur",
"928472", "Kharan",
"928439", "Mastung",
"92463", "Toba\ Tek\ Singh",
"928352", "Dera\ Bugti",
"92612", "Multan",
"92482", "Sargodha",
"929666", "D\.I\.\ Khan",
"92627", "Bahawalpur",
"925429", "Narowal",
"922449", "Nawabshah",
"929924", "Abottabad",
"928536", "Lasbela",
"929462", "Swat",
"928372", "Jhal\ Magsi",
"924599", "Mianwali",
"92228", "Hyderabad",
"928339", "Sibi\/Ziarat",
"92625", "Bahawalpur",
"929695", "Lakki\ Marwat",
"928324", "Bolan",
"92478", "Jhang",
"929972", "Mansehra\/Batagram",
"927236", "Ghotki",
"924574", "Pakpattan",
"92577", "Attock",
"929387", "Swabi",
"929964", "Shangla",
"928386", "Jaffarabad\/Nasirabad",
"929422", "Bajaur\ Agency",
"922988", "Thatta",
"928555", "Panjgur",
"928293", "Barkhan\/Kohlu",
"92684", "Rahim\ Yar\ Khan",
"92414", "Faisalabad",
"929399", "Buner",
"92558", "Gujranwala",
"929454", "Lower\ Dir",
"929322", "Malakand",
"92744", "Larkana",
"928486", "Khuzdar",
"925469", "Mandi\ Bahauddin",
"92403", "Sahiwal",
"929374", "Mardan",
"929228", "Kohat",
"92575", "Attock",
"92616", "Multan",
"92486", "Sargodha",
"92559", "Gujranwala",
"92712", "Sukkur",
"92863", "Gwadar",
"929389", "Swabi",
"928554", "Panjgur",
"922323", "Tharparkar",
"92924", "Khyber\/Mohmand\ Agy",
"925476", "Hafizabad",
"92562", "Sheikhupura",
"929965", "Shangla",
"929375", "Mardan",
"928522", "Kech",
"929397", "Buner",
"925443", "Jhelum",
"922423", "Naushero\ Feroze",
"924536", "Bhakkar",
"927222", "Jacobabad",
"92442", "Okara",
"925467", "Mandi\ Bahauddin",
"929455", "Lower\ Dir",
"928283", "Musakhel",};
my $timezones = {
               '' => [
                       'Asia/Karachi'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+92|\D)//g;
      my $self = bless({ country_code => '92', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '92', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;