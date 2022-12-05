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
our $VERSION = 1.20221202211027;

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
$areanames{en} = {"922335", "Mirpur\ Khas",
"924547", "Khushab",
"929663", "D\.I\.\ Khan",
"92214", "Karachi",
"92666", "Muzaffargarh",
"92402", "Sahiwal",
"929634", "Tank",
"928487", "Khuzdar",
"922388", "Umerkot",
"92746", "Larkana",
"92637", "Bahawalnagar",
"929373", "Mardan",
"926065", "Layyah",
"929959", "Haripur",
"92468", "Toba\ Tek\ Singh",
"928235", "Killa\ Saifullah",
"928386", "Jaffarabad\/Nasirabad",
"928374", "Jhal\ Magsi",
"928288", "Musakhel",
"927268", "Shikarpur",
"92612", "Multan",
"928474", "Kharan",
"928486", "Khuzdar",
"924546", "Khushab",
"922355", "Sanghar",
"92228", "Hyderabad",
"929654", "South\ Waziristan",
"929923", "Abottabad",
"92869", "Gwadar",
"92558", "Gujranwala",
"92672", "Vehari",
"922435", "Khairpur",
"92449", "Okara",
"924534", "Bhakkar",
"925473", "Hafizabad",
"928325", "Bolan",
"928255", "Chagai",
"92647", "Dera\ Ghazi\ Khan",
"929962", "Shangla",
"92482", "Sargodha",
"92564", "Sheikhupura",
"928387", "Jaffarabad\/Nasirabad",
"925449", "Jhelum",
"928568", "Awaran",
"926066", "Layyah",
"929449", "Upper\ Dir",
"92496", "Kasur",
"928442", "Kalat",
"922978", "Badin",
"92817", "Quetta",
"92719", "Sukkur",
"922357", "Sanghar",
"922336", "Mirpur\ Khas",
"928244", "Loralai",
"92222", "Hyderabad",
"92686", "Rahim\ Yar\ Khan",
"928338", "Sibi\/Ziarat",
"922437", "Khairpur",
"92552", "Gujranwala",
"926043", "Rajanpur",
"92678", "Vehari",
"92624", "Bahawalpur",
"928293", "Barkhan\/Kohlu",
"92476", "Jhang",
"928385", "Jaffarabad\/Nasirabad",
"928236", "Killa\ Saifullah",
"928257", "Chagai",
"928327", "Bolan",
"922428", "Naushero\ Feroze",
"92488", "Sargodha",
"924545", "Khushab",
"922356", "Sanghar",
"928438", "Mastung",
"922337", "Mirpur\ Khas",
"92408", "Sahiwal",
"92526", "Sialkot",
"922444", "Nawabshah",
"926067", "Layyah",
"922328", "Tharparkar",
"92926", "Kurram\ Agency",
"928485", "Khuzdar",
"92462", "Toba\ Tek\ Singh",
"92256", "Dadu",
"928237", "Killa\ Saifullah",
"928256", "Chagai",
"92416", "Faisalabad",
"928326", "Bolan",
"929468", "Swat",
"92618", "Multan",
"925468", "Mandi\ Bahauddin",
"928228", "Zhob",
"922982", "Thatta",
"928358", "Dera\ Bugti",
"922436", "Khairpur",
"924578", "Pakpattan",
"929392", "Buner",
"92812", "Quetta",
"924544", "Khushab",
"928282", "Musakhel",
"927262", "Shikarpur",
"929656", "South\ Waziristan",
"929637", "Tank",
"92563", "Sheikhupura",
"92227", "Hyderabad",
"926089", "Lodhran",
"928476", "Kharan",
"928484", "Khuzdar",
"922445", "Nawabshah",
"92648", "Dera\ Ghazi\ Khan",
"922382", "Umerkot",
"92215", "Karachi",
"924536", "Bhakkar",
"927223", "Jacobabad",
"928377", "Jhal\ Magsi",
"924593", "Mianwali",
"92866", "Gwadar",
"92557", "Gujranwala",
"927239", "Ghotki",
"92446", "Okara",
"928477", "Kharan",
"92749", "Larkana",
"929968", "Shangla",
"92467", "Toba\ Tek\ Singh",
"92638", "Bahawalnagar",
"929383", "Swabi",
"928245", "Loralai",
"929693", "Lakki\ Marwat",
"92669", "Muzaffargarh",
"929657", "South\ Waziristan",
"929636", "Tank",
"92565", "Sheikhupura",
"924537", "Bhakkar",
"92213", "Karachi",
"928384", "Jaffarabad\/Nasirabad",
"928376", "Jhal\ Magsi",
"92529", "Sialkot",
"928539", "Lasbela",
"922446", "Nawabshah",
"92632", "Bahawalnagar",
"929323", "Malakand",
"922422", "Naushero\ Feroze",
"92625", "Bahawalpur",
"928475", "Kharan",
"928332", "Sibi\/Ziarat",
"929655", "South\ Waziristan",
"928523", "Kech",
"92407", "Sahiwal",
"928247", "Loralai",
"922354", "Sanghar",
"929459", "Lower\ Dir",
"922972", "Badin",
"922434", "Khairpur",
"92617", "Multan",
"928562", "Awaran",
"924535", "Bhakkar",
"92259", "Dadu",
"928448", "Kalat",
"92419", "Faisalabad",
"928324", "Bolan",
"928254", "Chagai",
"929462", "Swat",
"928352", "Dera\ Bugti",
"925462", "Mandi\ Bahauddin",
"92818", "Quetta",
"928222", "Zhob",
"929635", "Tank",
"92716", "Sukkur",
"922988", "Thatta",
"928246", "Loralai",
"922334", "Mirpur\ Khas",
"929229", "Kohat",
"929398", "Buner",
"924572", "Pakpattan",
"929973", "Mansehra\/Batagram",
"928559", "Panjgur",
"926064", "Layyah",
"922447", "Nawabshah",
"92499", "Kasur",
"92623", "Bahawalpur",
"928263", "K\.Abdullah\/Pishin",
"925423", "Narowal",
"92479", "Jhang",
"928375", "Jhal\ Magsi",
"929423", "Bajaur\ Agency",
"92642", "Dera\ Ghazi\ Khan",
"922322", "Tharparkar",
"928234", "Killa\ Saifullah",
"92487", "Sargodha",
"925439", "Chakwal",
"92689", "Rahim\ Yar\ Khan",
"929439", "Chitral",
"92677", "Vehari",
"928432", "Mastung",
"928372", "Jhal\ Magsi",
"922325", "Tharparkar",
"929953", "Haripur",
"92403", "Sahiwal",
"928488", "Khuzdar",
"929379", "Mardan",
"922387", "Umerkot",
"929669", "D\.I\.\ Khan",
"924548", "Khushab",
"928435", "Mastung",
"929465", "Swat",
"928355", "Dera\ Bugti",
"925465", "Mandi\ Bahauddin",
"928225", "Zhob",
"929632", "Tank",
"92485", "Sargodha",
"924575", "Pakpattan",
"928287", "Musakhel",
"927267", "Shikarpur",
"92613", "Multan",
"92579", "Attock",
"92675", "Vehari",
"922975", "Badin",
"929929", "Abottabad",
"92627", "Bahawalpur",
"929964", "Shangla",
"92429", "Lahore",
"928565", "Awaran",
"92405", "Sahiwal",
"924532", "Bhakkar",
"922386", "Umerkot",
"928388", "Jaffarabad\/Nasirabad",
"925479", "Hafizabad",
"92615", "Multan",
"922425", "Naushero\ Feroze",
"92919", "Peshawar\/Charsadda",
"928472", "Kharan",
"92519", "Islamabad\/Rawalpindi",
"92673", "Vehari",
"928335", "Sibi\/Ziarat",
"929652", "South\ Waziristan",
"92814", "Quetta",
"928286", "Musakhel",
"927266", "Shikarpur",
"92483", "Sargodha",
"92536", "Gujrat",
"928436", "Mastung",
"922358", "Sanghar",
"92465", "Toba\ Tek\ Singh",
"922977", "Badin",
"92644", "Dera\ Ghazi\ Khan",
"929443", "Upper\ Dir",
"925443", "Jhelum",
"92223", "Hyderabad",
"928567", "Awaran",
"922326", "Tharparkar",
"92567", "Sheikhupura",
"92553", "Gujranwala",
"928258", "Chagai",
"928328", "Bolan",
"928299", "Barkhan\/Kohlu",
"922427", "Naushero\ Feroze",
"928444", "Kalat",
"928242", "Loralai",
"924576", "Pakpattan",
"929466", "Swat",
"928226", "Zhob",
"925466", "Mandi\ Bahauddin",
"926049", "Rajanpur",
"928337", "Sibi\/Ziarat",
"922438", "Khairpur",
"928356", "Dera\ Bugti",
"922385", "Umerkot",
"922327", "Tharparkar",
"928566", "Awaran",
"926068", "Layyah",
"92225", "Hyderabad",
"928437", "Mastung",
"922338", "Mirpur\ Khas",
"929394", "Buner",
"922976", "Badin",
"92463", "Toba\ Tek\ Singh",
"922984", "Thatta",
"928285", "Musakhel",
"927265", "Shikarpur",
"924577", "Pakpattan",
"92217", "Karachi",
"925467", "Mandi\ Bahauddin",
"928227", "Zhob",
"928336", "Sibi\/Ziarat",
"928357", "Dera\ Bugti",
"929467", "Swat",
"928238", "Killa\ Saifullah",
"922426", "Naushero\ Feroze",
"92555", "Gujranwala",
"92634", "Bahawalnagar",
"922442", "Nawabshah",
"92659", "Khanewal",
"92426", "Lahore",
"929966", "Shangla",
"92813", "Quetta",
"922384", "Umerkot",
"92484", "Sargodha",
"92562", "Sheikhupura",
"929638", "Tank",
"922985", "Thatta",
"926083", "Lodhran",
"92628", "Bahawalpur",
"929395", "Buner",
"92674", "Vehari",
"927233", "Ghotki",
"927264", "Shikarpur",
"928284", "Musakhel",
"924542", "Khushab",
"927229", "Jacobabad",
"928378", "Jhal\ Magsi",
"92916", "Peshawar\/Charsadda",
"92516", "Islamabad\/Rawalpindi",
"928482", "Khuzdar",
"924599", "Mianwali",
"92614", "Multan",
"929658", "South\ Waziristan",
"929699", "Lakki\ Marwat",
"92815", "Quetta",
"928382", "Jaffarabad\/Nasirabad",
"929967", "Shangla",
"929389", "Swabi",
"928478", "Kharan",
"92576", "Attock",
"924538", "Bhakkar",
"928445", "Kalat",
"92212", "Karachi",
"92404", "Sahiwal",
"928248", "Loralai",
"928529", "Kech",
"929396", "Buner",
"922974", "Badin",
"92633", "Bahawalnagar",
"922432", "Khairpur",
"922986", "Thatta",
"928533", "Lasbela",
"928322", "Bolan",
"928252", "Chagai",
"929965", "Shangla",
"928564", "Awaran",
"929329", "Malakand",
"928447", "Kalat",
"922424", "Naushero\ Feroze",
"92464", "Toba\ Tek\ Singh",
"92656", "Khanewal",
"92218", "Karachi",
"922352", "Sanghar",
"92645", "Dera\ Ghazi\ Khan",
"929453", "Lower\ Dir",
"928334", "Sibi\/Ziarat",
"928232", "Killa\ Saifullah",
"928553", "Panjgur",
"92568", "Sheikhupura",
"922324", "Tharparkar",
"922448", "Nawabshah",
"929397", "Buner",
"92539", "Gujrat",
"92554", "Gujranwala",
"928434", "Mastung",
"92635", "Bahawalnagar",
"929223", "Kohat",
"92622", "Bahawalpur",
"929979", "Mansehra\/Batagram",
"922987", "Thatta",
"929433", "Chitral",
"92643", "Dera\ Ghazi\ Khan",
"922332", "Mirpur\ Khas",
"924574", "Pakpattan",
"925433", "Chakwal",
"92224", "Hyderabad",
"929464", "Swat",
"928354", "Dera\ Bugti",
"925464", "Mandi\ Bahauddin",
"928224", "Zhob",
"929429", "Bajaur\ Agency",
"928446", "Kalat",
"928269", "K\.Abdullah\/Pishin",
"925429", "Narowal",
"926062", "Layyah",
"92688", "Rahim\ Yar\ Khan",
"92676", "Vehari",
"924539", "Bhakkar",
"92478", "Jhang",
"92424", "Lahore",
"929455", "Lower\ Dir",
"927236", "Ghotki",
"92486", "Sargodha",
"929922", "Abottabad",
"926086", "Lodhran",
"929698", "Lakki\ Marwat",
"92498", "Kasur",
"929659", "South\ Waziristan",
"92914", "Peshawar\/Charsadda",
"92514", "Islamabad\/Rawalpindi",
"92717", "Sukkur",
"925472", "Hafizabad",
"928535", "Lasbela",
"92819", "Quetta",
"929963", "Shangla",
"929388", "Swabi",
"928479", "Kharan",
"929435", "Chitral",
"925435", "Chakwal",
"929662", "D\.I\.\ Khan",
"92258", "Dadu",
"927237", "Ghotki",
"92418", "Faisalabad",
"928379", "Jhal\ Magsi",
"92616", "Multan",
"927228", "Jacobabad",
"929372", "Mardan",
"924598", "Mianwali",
"92662", "Muzaffargarh",
"928555", "Panjgur",
"929954", "Haripur",
"92406", "Sahiwal",
"92574", "Attock",
"92528", "Sialkot",
"929639", "Tank",
"92742", "Larkana",
"926087", "Lodhran",
"92928", "Bannu\/N\.\ Waziristan",
"929225", "Kohat",
"927235", "Ghotki",
"92412", "Faisalabad",
"925437", "Chakwal",
"929437", "Chitral",
"92252", "Dadu",
"929456", "Lower\ Dir",
"928268", "K\.Abdullah\/Pishin",
"925428", "Narowal",
"929428", "Bajaur\ Agency",
"92668", "Muzaffargarh",
"922449", "Nawabshah",
"928557", "Panjgur",
"928536", "Lasbela",
"92522", "Sialkot",
"92748", "Larkana",
"929227", "Kohat",
"92535", "Gujrat",
"922983", "Thatta",
"926085", "Lodhran",
"92466", "Toba\ Tek\ Singh",
"92639", "Bahawalnagar",
"929393", "Buner",
"92654", "Khanewal",
"929978", "Mansehra\/Batagram",
"92556", "Gujranwala",
"92867", "Gwadar",
"92682", "Rahim\ Yar\ Khan",
"92447", "Okara",
"928443", "Kalat",
"92649", "Dera\ Ghazi\ Khan",
"92472", "Jhang",
"929436", "Chitral",
"929457", "Lower\ Dir",
"925436", "Chakwal",
"92492", "Kasur",
"92533", "Gujrat",
"929226", "Kohat",
"928249", "Loralai",
"928528", "Kech",
"926042", "Rajanpur",
"928292", "Barkhan\/Kohlu",
"929328", "Malakand",
"929444", "Upper\ Dir",
"92226", "Hyderabad",
"925444", "Jhelum",
"928556", "Panjgur",
"928537", "Lasbela",
"92619", "Multan",
"92573", "Attock",
"925478", "Hafizabad",
"928389", "Jaffarabad\/Nasirabad",
"92515", "Islamabad\/Rawalpindi",
"929382", "Swabi",
"92915", "Peshawar\/Charsadda",
"929692", "Lakki\ Marwat",
"92417", "Faisalabad",
"92257", "Dadu",
"92927", "Karak",
"92527", "Sialkot",
"929928", "Abottabad",
"929445", "Upper\ Dir",
"925445", "Jhelum",
"929956", "Haripur",
"92425", "Lahore",
"92409", "Sahiwal",
"928283", "Musakhel",
"927263", "Shikarpur",
"92477", "Jhang",
"927234", "Ghotki",
"92489", "Sargodha",
"92575", "Attock",
"92862", "Gwadar",
"92687", "Rahim\ Yar\ Khan",
"92442", "Okara",
"92913", "Peshawar\/Charsadda",
"92513", "Islamabad\/Rawalpindi",
"92679", "Vehari",
"929957", "Haripur",
"92423", "Lahore",
"922383", "Umerkot",
"92816", "Quetta",
"92718", "Sukkur",
"927222", "Jacobabad",
"928489", "Khuzdar",
"929378", "Mardan",
"924592", "Mianwali",
"92497", "Kasur",
"926084", "Lodhran",
"929668", "D\.I\.\ Khan",
"924549", "Khushab",
"929463", "Swat",
"92646", "Dera\ Ghazi\ Khan",
"925463", "Mandi\ Bahauddin",
"928223", "Zhob",
"928353", "Dera\ Bugti",
"929434", "Chitral",
"925434", "Chakwal",
"924573", "Pakpattan",
"929972", "Mansehra\/Batagram",
"92534", "Gujrat",
"92559", "Gujranwala",
"92868", "Gwadar",
"928239", "Killa\ Saifullah",
"92655", "Khanewal",
"92448", "Okara",
"928262", "K\.Abdullah\/Pishin",
"925422", "Narowal",
"92712", "Sukkur",
"929422", "Bajaur\ Agency",
"922323", "Tharparkar",
"92229", "Hyderabad",
"929446", "Upper\ Dir",
"928554", "Panjgur",
"925446", "Jhelum",
"929955", "Haripur",
"926069", "Layyah",
"929224", "Kohat",
"922339", "Mirpur\ Khas",
"928433", "Mastung",
"928329", "Bolan",
"928298", "Barkhan\/Kohlu",
"928259", "Chagai",
"929322", "Malakand",
"922423", "Naushero\ Feroze",
"92653", "Khanewal",
"928333", "Sibi\/Ziarat",
"928522", "Kech",
"922439", "Khairpur",
"926048", "Rajanpur",
"929454", "Lower\ Dir",
"922973", "Badin",
"922359", "Sanghar",
"92747", "Larkana",
"92469", "Toba\ Tek\ Singh",
"92636", "Bahawalnagar",
"92667", "Muzaffargarh",
"928563", "Awaran",
"928534", "Lasbela",
"925447", "Jhelum",
"929447", "Upper\ Dir",
"924596", "Mianwali",
"925474", "Hafizabad",
"924533", "Bhakkar",
"927226", "Jacobabad",
"92538", "Gujrat",
"92864", "Gwadar",
"929387", "Swabi",
"92745", "Larkana",
"928473", "Kharan",
"929325", "Malakand",
"929969", "Shangla",
"92444", "Okara",
"929653", "South\ Waziristan",
"92665", "Muzaffargarh",
"928525", "Kech",
"929924", "Abottabad",
"929697", "Lakki\ Marwat",
"92569", "Sheikhupura",
"928265", "K\.Abdullah\/Pishin",
"925425", "Narowal",
"929425", "Bajaur\ Agency",
"928373", "Jhal\ Magsi",
"92219", "Karachi",
"924597", "Mianwali",
"927227", "Jacobabad",
"929952", "Haripur",
"927238", "Ghotki",
"92657", "Khanewal",
"92663", "Muzaffargarh",
"929633", "Tank",
"9258", "AJK\/FATA",
"926088", "Lodhran",
"929664", "D\.I\.\ Khan",
"929696", "Lakki\ Marwat",
"929975", "Mansehra\/Batagram",
"929374", "Mardan",
"929386", "Swabi",
"92743", "Larkana",
"92475", "Jhang",
"927225", "Jacobabad",
"924595", "Mianwali",
"929427", "Bajaur\ Agency",
"92253", "Dadu",
"92413", "Faisalabad",
"928267", "K\.Abdullah\/Pishin",
"925427", "Narowal",
"929438", "Chitral",
"92577", "Attock",
"925438", "Chakwal",
"92685", "Rahim\ Yar\ Khan",
"929977", "Mansehra\/Batagram",
"922989", "Thatta",
"929399", "Buner",
"929228", "Kohat",
"928526", "Kech",
"929326", "Malakand",
"92523", "Sialkot",
"92495", "Kasur",
"92923", "Nowshera",
"928558", "Panjgur",
"922443", "Nawabshah",
"926044", "Rajanpur",
"92683", "Rahim\ Yar\ Khan",
"929458", "Lower\ Dir",
"92517", "Islamabad\/Rawalpindi",
"92917", "Peshawar\/Charsadda",
"929442", "Upper\ Dir",
"92473", "Jhang",
"925442", "Jhelum",
"92714", "Sukkur",
"92415", "Faisalabad",
"928449", "Kalat",
"925426", "Narowal",
"928266", "K\.Abdullah\/Pishin",
"928294", "Barkhan\/Kohlu",
"929426", "Bajaur\ Agency",
"92255", "Dadu",
"92925", "Hangu\/Orakzai\ Agy",
"928538", "Lasbela",
"929327", "Malakand",
"92493", "Kasur",
"92525", "Sialkot",
"92532", "Gujrat",
"929385", "Swabi",
"92629", "Bahawalpur",
"928243", "Loralai",
"929976", "Mansehra\/Batagram",
"92427", "Lahore",
"929695", "Lakki\ Marwat",
"928527", "Kech",
"92865", "Gwadar",
"92572", "Attock",
"92744", "Larkana",
"926045", "Rajanpur",
"92445", "Okara",
"92658", "Khanewal",
"928383", "Jaffarabad\/Nasirabad",
"928295", "Barkhan\/Kohlu",
"92664", "Muzaffargarh",
"92216", "Karachi",
"925477", "Hafizabad",
"929376", "Mardan",
"929384", "Swabi",
"929927", "Abottabad",
"929694", "Lakki\ Marwat",
"929666", "D\.I\.\ Khan",
"924594", "Mianwali",
"925476", "Hafizabad",
"927224", "Jacobabad",
"92863", "Gwadar",
"928289", "Musakhel",
"927269", "Shikarpur",
"92512", "Islamabad\/Rawalpindi",
"926082", "Lodhran",
"92912", "Peshawar\/Charsadda",
"92443", "Okara",
"927232", "Ghotki",
"929926", "Abottabad",
"92422", "Lahore",
"92566", "Sheikhupura",
"924543", "Khushab",
"929667", "D\.I\.\ Khan",
"922389", "Umerkot",
"929377", "Mardan",
"92537", "Gujrat",
"929958", "Haripur",
"928483", "Khuzdar",
"928233", "Killa\ Saifullah",
"928552", "Panjgur",
"928296", "Barkhan\/Kohlu",
"928264", "K\.Abdullah\/Pishin",
"925424", "Narowal",
"929424", "Bajaur\ Agency",
"928359", "Dera\ Bugti",
"925469", "Mandi\ Bahauddin",
"928229", "Zhob",
"926046", "Rajanpur",
"92494", "Kasur",
"929469", "Swat",
"929222", "Kohat",
"92918", "Peshawar\/Charsadda",
"924579", "Pakpattan",
"92518", "Islamabad\/Rawalpindi",
"929432", "Chitral",
"92428", "Lahore",
"922333", "Mirpur\ Khas",
"92474", "Jhang",
"925432", "Chakwal",
"92713", "Sukkur",
"929665", "D\.I\.\ Khan",
"929974", "Mansehra\/Batagram",
"928439", "Mastung",
"92684", "Rahim\ Yar\ Khan",
"922329", "Tharparkar",
"926063", "Layyah",
"929375", "Mardan",
"92626", "Bahawalpur",
"92524", "Sialkot",
"92578", "Attock",
"928339", "Sibi\/Ziarat",
"92924", "Khyber\/Mohmand\ Agy",
"926047", "Rajanpur",
"92652", "Khanewal",
"922433", "Khairpur",
"925475", "Hafizabad",
"928532", "Lasbela",
"928253", "Chagai",
"928323", "Bolan",
"928297", "Barkhan\/Kohlu",
"922429", "Naushero\ Feroze",
"929448", "Upper\ Dir",
"929324", "Malakand",
"925448", "Jhelum",
"928569", "Awaran",
"92715", "Sukkur",
"92998", "Kohistan",
"922353", "Sanghar",
"929452", "Lower\ Dir",
"922979", "Badin",
"92254", "Dadu",
"928524", "Kech",
"92414", "Faisalabad",
"929925", "Abottabad",};

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