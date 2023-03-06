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
our $VERSION = 1.20230305170053;

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
$areanames{en} = {"92923", "Nowshera",
"922338", "Mirpur\ Khas",
"929657", "South\ Waziristan",
"925435", "Chakwal",
"929464", "Swat",
"922443", "Nawabshah",
"929952", "Haripur",
"92407", "Sahiwal",
"92477", "Jhang",
"92748", "Larkana",
"92419", "Faisalabad",
"929224", "Kohat",
"92869", "Gwadar",
"928526", "Kech",
"92422", "Lahore",
"928386", "Jaffarabad\/Nasirabad",
"92666", "Muzaffargarh",
"924572", "Pakpattan",
"92576", "Attock",
"92446", "Okara",
"928229", "Zhob",
"928433", "Mastung",
"925464", "Mandi\ Bahauddin",
"929435", "Chitral",
"92523", "Sialkot",
"92633", "Bahawalnagar",
"929429", "Bajaur\ Agency",
"929394", "Buner",
"928235", "Killa\ Saifullah",
"92499", "Kasur",
"92613", "Multan",
"928382", "Jaffarabad\/Nasirabad",
"924576", "Pakpattan",
"929658", "South\ Waziristan",
"922337", "Mirpur\ Khas",
"925473", "Hafizabad",
"928522", "Kech",
"928475", "Kharan",
"929695", "Lakki\ Marwat",
"928264", "K\.Abdullah\/Pishin",
"92688", "Rahim\ Yar\ Khan",
"929956", "Haripur",
"925429", "Narowal",
"929373", "Mardan",
"92484", "Sargodha",
"92257", "Dadu",
"928375", "Jhal\ Magsi",
"92866", "Gwadar",
"928324", "Bolan",
"928447", "Kalat",
"92669", "Muzaffargarh",
"92579", "Attock",
"92449", "Okara",
"929929", "Abottabad",
"92517", "Islamabad\/Rawalpindi",
"92718", "Sukkur",
"92917", "Peshawar\/Charsadda",
"928252", "Chagai",
"929329", "Malakand",
"929456", "Lower\ Dir",
"922354", "Sanghar",
"927228", "Jacobabad",
"928482", "Khuzdar",
"929973", "Mansehra\/Batagram",
"922437", "Khairpur",
"92416", "Faisalabad",
"92463", "Toba\ Tek\ Singh",
"92214", "Karachi",
"929665", "D\.I\.\ Khan",
"928559", "Panjgur",
"928486", "Khuzdar",
"92672", "Vehari",
"928448", "Kalat",
"929452", "Lower\ Dir",
"92562", "Sheikhupura",
"92554", "Gujranwala",
"928294", "Barkhan\/Kohlu",
"924544", "Khushab",
"92643", "Dera\ Ghazi\ Khan",
"929964", "Shangla",
"928333", "Sibi\/Ziarat",
"928256", "Chagai",
"922989", "Thatta",
"922438", "Khairpur",
"922389", "Umerkot",
"927227", "Jacobabad",
"92496", "Kasur",
"92537", "Gujrat",
"92627", "Bahawalpur",
"929634", "Tank",
"926065", "Layyah",
"92813", "Quetta",
"922982", "Thatta",
"929326", "Malakand",
"922424", "Naushero\ Feroze",
"927223", "Jacobabad",
"929978", "Mansehra\/Batagram",
"929459", "Lower\ Dir",
"92614", "Multan",
"928552", "Panjgur",
"928245", "Loralai",
"924595", "Mianwali",
"92686", "Rahim\ Yar\ Khan",
"928337", "Sibi\/Ziarat",
"928284", "Musakhel",
"929378", "Mardan",
"92227", "Hyderabad",
"929926", "Abottabad",
"922382", "Umerkot",
"922386", "Umerkot",
"929922", "Abottabad",
"92657", "Khanewal",
"922433", "Khairpur",
"927234", "Ghotki",
"929977", "Mansehra\/Batagram",
"92746", "Larkana",
"925445", "Jhelum",
"92924", "Khyber\/Mohmand\ Agy",
"92524", "Sialkot",
"92634", "Bahawalnagar",
"929445", "Upper\ Dir",
"928443", "Kalat",
"92425", "Lahore",
"928338", "Sibi\/Ziarat",
"928556", "Panjgur",
"928489", "Khuzdar",
"92668", "Muzaffargarh",
"927265", "Shikarpur",
"929377", "Mardan",
"92578", "Attock",
"92448", "Okara",
"928259", "Chagai",
"929322", "Malakand",
"922986", "Thatta",
"92719", "Sukkur",
"92675", "Vehari",
"928529", "Kech",
"92644", "Dera\ Ghazi\ Khan",
"924534", "Bhakkar",
"92553", "Gujranwala",
"928389", "Jaffarabad\/Nasirabad",
"928438", "Mastung",
"926044", "Rajanpur",
"928226", "Zhob",
"92213", "Karachi",
"92689", "Rahim\ Yar\ Khan",
"92464", "Toba\ Tek\ Singh",
"929422", "Bajaur\ Agency",
"92565", "Sheikhupura",
"929384", "Swabi",
"925422", "Narowal",
"92814", "Quetta",
"92498", "Kasur",
"922333", "Mirpur\ Khas",
"926085", "Lodhran",
"925477", "Hafizabad",
"922448", "Nawabshah",
"92868", "Gwadar",
"928564", "Awaran",
"928354", "Dera\ Bugti",
"929959", "Haripur",
"922975", "Badin",
"928437", "Mastung",
"925426", "Narowal",
"92716", "Sukkur",
"92483", "Sargodha",
"922324", "Tharparkar",
"922447", "Nawabshah",
"929426", "Bajaur\ Agency",
"928222", "Zhob",
"929653", "South\ Waziristan",
"925478", "Hafizabad",
"92749", "Larkana",
"924579", "Pakpattan",
"92418", "Faisalabad",
"928535", "Lasbela",
"929386", "Swabi",
"929469", "Swat",
"928562", "Awaran",
"92224", "Hyderabad",
"928352", "Dera\ Bugti",
"929229", "Kohat",
"929433", "Chitral",
"928435", "Mastung",
"922977", "Badin",
"92679", "Vehari",
"926088", "Lodhran",
"925433", "Chakwal",
"922445", "Nawabshah",
"92617", "Multan",
"924536", "Bhakkar",
"922322", "Tharparkar",
"92685", "Rahim\ Yar\ Khan",
"925469", "Mandi\ Bahauddin",
"928537", "Lasbela",
"928224", "Zhob",
"926046", "Rajanpur",
"92569", "Sheikhupura",
"926042", "Rajanpur",
"92527", "Sialkot",
"92637", "Bahawalnagar",
"922978", "Badin",
"928473", "Kharan",
"929399", "Buner",
"922326", "Tharparkar",
"929424", "Bajaur\ Agency",
"929693", "Lakki\ Marwat",
"92745", "Larkana",
"924532", "Bhakkar",
"92662", "Muzaffargarh",
"92426", "Lahore",
"92654", "Khanewal",
"92473", "Jhang",
"928566", "Awaran",
"928538", "Lasbela",
"928356", "Dera\ Bugti",
"928233", "Killa\ Saifullah",
"929382", "Swabi",
"92403", "Sahiwal",
"925424", "Narowal",
"926087", "Lodhran",
"928269", "K\.Abdullah\/Pishin",
"92927", "Karak",
"92442", "Okara",
"92572", "Attock",
"925475", "Hafizabad",
"92817", "Quetta",
"927232", "Ghotki",
"928248", "Loralai",
"928329", "Bolan",
"92676", "Vehari",
"924598", "Mianwali",
"92623", "Bahawalpur",
"92533", "Gujrat",
"929924", "Abottabad",
"925447", "Jhelum",
"92566", "Sheikhupura",
"928286", "Musakhel",
"929975", "Mansehra\/Batagram",
"928373", "Jhal\ Magsi",
"922359", "Sanghar",
"92492", "Kasur",
"927267", "Shikarpur",
"929375", "Mardan",
"92647", "Dera\ Ghazi\ Khan",
"929324", "Malakand",
"929447", "Upper\ Dir",
"922426", "Naushero\ Feroze",
"92467", "Toba\ Tek\ Singh",
"928554", "Panjgur",
"92429", "Lahore",
"925448", "Jhelum",
"92862", "Gwadar",
"922984", "Thatta",
"924597", "Mianwali",
"926063", "Layyah",
"922422", "Naushero\ Feroze",
"924549", "Khushab",
"929969", "Shangla",
"92715", "Sukkur",
"928299", "Barkhan\/Kohlu",
"92913", "Peshawar\/Charsadda",
"928247", "Loralai",
"92513", "Islamabad\/Rawalpindi",
"928282", "Musakhel",
"929663", "D\.I\.\ Khan",
"922384", "Umerkot",
"929448", "Upper\ Dir",
"92412", "Faisalabad",
"928335", "Sibi\/Ziarat",
"927236", "Ghotki",
"927268", "Shikarpur",
"929639", "Tank",
"92253", "Dadu",
"929454", "Lower\ Dir",
"929667", "D\.I\.\ Khan",
"922356", "Sanghar",
"928292", "Barkhan\/Kohlu",
"924542", "Khushab",
"922429", "Naushero\ Feroze",
"929962", "Shangla",
"928378", "Jhal\ Magsi",
"92742", "Larkana",
"928326", "Bolan",
"92428", "Lahore",
"927225", "Jacobabad",
"929632", "Tank",
"92404", "Sahiwal",
"92665", "Muzaffargarh",
"928243", "Loralai",
"92575", "Attock",
"92445", "Okara",
"92474", "Jhang",
"92653", "Khanewal",
"926067", "Layyah",
"928289", "Musakhel",
"924593", "Mianwali",
"928445", "Kalat",
"929443", "Upper\ Dir",
"92223", "Hyderabad",
"928377", "Jhal\ Magsi",
"927263", "Shikarpur",
"928322", "Bolan",
"927239", "Ghotki",
"929668", "D\.I\.\ Khan",
"929636", "Tank",
"928484", "Khuzdar",
"926068", "Layyah",
"924546", "Khushab",
"929966", "Shangla",
"922435", "Khairpur",
"928254", "Chagai",
"925443", "Jhelum",
"92682", "Rahim\ Yar\ Khan",
"928296", "Barkhan\/Kohlu",
"922352", "Sanghar",
"928384", "Jaffarabad\/Nasirabad",
"92865", "Gwadar",
"92914", "Peshawar\/Charsadda",
"928237", "Killa\ Saifullah",
"924539", "Bhakkar",
"928524", "Kech",
"925466", "Mandi\ Bahauddin",
"922335", "Mirpur\ Khas",
"926083", "Lodhran",
"925438", "Chakwal",
"929392", "Buner",
"92712", "Sukkur",
"926049", "Rajanpur",
"928262", "K\.Abdullah\/Pishin",
"92487", "Sargodha",
"92254", "Dadu",
"929697", "Lakki\ Marwat",
"928477", "Kharan",
"929438", "Chitral",
"929389", "Swabi",
"929466", "Swat",
"929226", "Kohat",
"92415", "Faisalabad",
"92514", "Islamabad\/Rawalpindi",
"92678", "Vehari",
"928569", "Awaran",
"929655", "South\ Waziristan",
"929222", "Kohat",
"928359", "Dera\ Bugti",
"925437", "Chakwal",
"92534", "Gujrat",
"92624", "Bahawalpur",
"929462", "Swat",
"928266", "K\.Abdullah\/Pishin",
"92568", "Sheikhupura",
"928533", "Lasbela",
"928238", "Killa\ Saifullah",
"929954", "Haripur",
"92217", "Karachi",
"925462", "Mandi\ Bahauddin",
"929396", "Buner",
"92495", "Kasur",
"922329", "Tharparkar",
"922973", "Badin",
"928478", "Kharan",
"929437", "Chitral",
"92557", "Gujranwala",
"9258", "AJK\/FATA",
"929698", "Lakki\ Marwat",
"924574", "Pakpattan",
"92664", "Muzaffargarh",
"928449", "Kalat",
"92405", "Sahiwal",
"929972", "Mansehra\/Batagram",
"92652", "Khanewal",
"92638", "Bahawalnagar",
"92528", "Sialkot",
"92489", "Sargodha",
"928483", "Khuzdar",
"922988", "Thatta",
"925444", "Jhelum",
"929927", "Abottabad",
"92475", "Jhang",
"92574", "Attock",
"927235", "Ghotki",
"928336", "Sibi\/Ziarat",
"928558", "Panjgur",
"928253", "Chagai",
"92444", "Okara",
"92743", "Larkana",
"927264", "Shikarpur",
"929444", "Upper\ Dir",
"929327", "Malakand",
"922388", "Umerkot",
"92928", "Bannu\/N\.\ Waziristan",
"922439", "Khairpur",
"929372", "Mardan",
"929376", "Mardan",
"92683", "Rahim\ Yar\ Khan",
"928557", "Panjgur",
"92219", "Karachi",
"922425", "Naushero\ Feroze",
"929928", "Abottabad",
"924594", "Mianwali",
"922987", "Thatta",
"92559", "Gujranwala",
"928244", "Loralai",
"927229", "Jacobabad",
"92618", "Multan",
"928332", "Sibi\/Ziarat",
"929453", "Lower\ Dir",
"922387", "Umerkot",
"92222", "Hyderabad",
"929328", "Malakand",
"929976", "Mansehra\/Batagram",
"928285", "Musakhel",
"928432", "Mastung",
"928355", "Dera\ Bugti",
"928565", "Awaran",
"929659", "South\ Waziristan",
"92255", "Dadu",
"924573", "Pakpattan",
"92515", "Islamabad\/Rawalpindi",
"929428", "Bajaur\ Agency",
"92414", "Faisalabad",
"925476", "Hafizabad",
"922974", "Badin",
"92713", "Sukkur",
"92486", "Sargodha",
"92864", "Gwadar",
"925428", "Narowal",
"92915", "Peshawar\/Charsadda",
"922325", "Tharparkar",
"928534", "Lasbela",
"922442", "Nawabshah",
"929953", "Haripur",
"928227", "Zhob",
"92494", "Kasur",
"924535", "Bhakkar",
"929427", "Bajaur\ Agency",
"92818", "Quetta",
"922446", "Nawabshah",
"922339", "Mirpur\ Khas",
"926045", "Rajanpur",
"925472", "Hafizabad",
"92216", "Karachi",
"928228", "Zhob",
"928523", "Kech",
"928383", "Jaffarabad\/Nasirabad",
"92648", "Dera\ Ghazi\ Khan",
"929385", "Swabi",
"92468", "Toba\ Tek\ Singh",
"925427", "Narowal",
"926084", "Lodhran",
"928436", "Mastung",
"92535", "Gujrat",
"92625", "Bahawalpur",
"92556", "Gujranwala",
"929958", "Haripur",
"928234", "Killa\ Saifullah",
"928387", "Jaffarabad\/Nasirabad",
"92649", "Dera\ Ghazi\ Khan",
"928527", "Kech",
"929395", "Buner",
"922332", "Mirpur\ Khas",
"92469", "Toba\ Tek\ Singh",
"925423", "Narowal",
"92684", "Rahim\ Yar\ Khan",
"924578", "Pakpattan",
"92616", "Multan",
"929694", "Lakki\ Marwat",
"929423", "Bajaur\ Agency",
"929656", "South\ Waziristan",
"928474", "Kharan",
"92819", "Quetta",
"92225", "Hyderabad",
"925479", "Hafizabad",
"928265", "K\.Abdullah\/Pishin",
"92573", "Attock",
"92443", "Okara",
"929465", "Swat",
"92655", "Khanewal",
"92636", "Bahawalnagar",
"92526", "Sialkot",
"925434", "Chakwal",
"92402", "Sahiwal",
"928223", "Zhob",
"928528", "Kech",
"929225", "Kohat",
"92472", "Jhang",
"929652", "South\ Waziristan",
"929957", "Haripur",
"928388", "Jaffarabad\/Nasirabad",
"928439", "Mastung",
"92663", "Muzaffargarh",
"922449", "Nawabshah",
"92427", "Lahore",
"929434", "Chitral",
"92926", "Kurram\ Agency",
"922336", "Mirpur\ Khas",
"925465", "Mandi\ Bahauddin",
"92744", "Larkana",
"924577", "Pakpattan",
"922383", "Umerkot",
"92619", "Multan",
"929664", "D\.I\.\ Khan",
"929457", "Lower\ Dir",
"92816", "Quetta",
"92677", "Vehari",
"92567", "Sheikhupura",
"922436", "Khairpur",
"929965", "Shangla",
"924545", "Khushab",
"928295", "Barkhan\/Kohlu",
"92493", "Kasur",
"92218", "Karachi",
"928446", "Kalat",
"928553", "Panjgur",
"928258", "Chagai",
"92646", "Dera\ Ghazi\ Khan",
"92466", "Toba\ Tek\ Singh",
"92532", "Gujrat",
"92622", "Bahawalpur",
"929635", "Tank",
"926064", "Layyah",
"928339", "Sibi\/Ziarat",
"928488", "Khuzdar",
"922983", "Thatta",
"92558", "Gujranwala",
"927222", "Jacobabad",
"929323", "Malakand",
"92252", "Dadu",
"927226", "Jacobabad",
"928325", "Bolan",
"928374", "Jhal\ Magsi",
"92413", "Faisalabad",
"929458", "Lower\ Dir",
"92512", "Islamabad\/Rawalpindi",
"928442", "Kalat",
"929979", "Mansehra\/Batagram",
"922355", "Sanghar",
"92912", "Peshawar\/Charsadda",
"928487", "Khuzdar",
"929379", "Mardan",
"92488", "Sargodha",
"922432", "Khairpur",
"92529", "Sialkot",
"92639", "Bahawalnagar",
"92863", "Gwadar",
"928257", "Chagai",
"92714", "Sukkur",
"929923", "Abottabad",
"929968", "Shangla",
"924548", "Khushab",
"928298", "Barkhan\/Kohlu",
"928444", "Kalat",
"928327", "Bolan",
"926066", "Layyah",
"928372", "Jhal\ Magsi",
"925449", "Jhelum",
"929449", "Upper\ Dir",
"92615", "Multan",
"929638", "Tank",
"927269", "Shikarpur",
"922357", "Sanghar",
"929666", "D\.I\.\ Khan",
"928485", "Khuzdar",
"92687", "Rahim\ Yar\ Khan",
"927233", "Ghotki",
"928255", "Chagai",
"922434", "Khairpur",
"92226", "Hyderabad",
"92408", "Sahiwal",
"92424", "Lahore",
"92656", "Khanewal",
"929455", "Lower\ Dir",
"92525", "Sialkot",
"92635", "Bahawalnagar",
"928297", "Barkhan\/Kohlu",
"929662", "D\.I\.\ Khan",
"928249", "Loralai",
"928328", "Bolan",
"928283", "Musakhel",
"924599", "Mianwali",
"929967", "Shangla",
"924547", "Khushab",
"92478", "Jhang",
"92747", "Larkana",
"928376", "Jhal\ Magsi",
"926062", "Layyah",
"927224", "Jacobabad",
"922423", "Naushero\ Feroze",
"922358", "Sanghar",
"92925", "Hangu\/Orakzai\ Agy",
"929637", "Tank",
"929467", "Swat",
"929654", "South\ Waziristan",
"928476", "Kharan",
"922323", "Tharparkar",
"929696", "Lakki\ Marwat",
"92815", "Quetta",
"929955", "Haripur",
"922979", "Badin",
"929398", "Buner",
"92229", "Hyderabad",
"929227", "Kohat",
"925432", "Chakwal",
"929432", "Chitral",
"92645", "Dera\ Ghazi\ Khan",
"92212", "Karachi",
"92674", "Vehari",
"928353", "Dera\ Bugti",
"928236", "Killa\ Saifullah",
"928563", "Awaran",
"928268", "K\.Abdullah\/Pishin",
"92564", "Sheikhupura",
"924575", "Pakpattan",
"92552", "Gujranwala",
"92465", "Toba\ Tek\ Singh",
"92628", "Bahawalpur",
"92538", "Gujrat",
"928539", "Lasbela",
"92998", "Kohistan",
"925467", "Mandi\ Bahauddin",
"928525", "Kech",
"929397", "Buner",
"929228", "Kohat",
"92258", "Dadu",
"929383", "Swabi",
"928385", "Jaffarabad\/Nasirabad",
"92717", "Sukkur",
"928232", "Killa\ Saifullah",
"92518", "Islamabad\/Rawalpindi",
"929468", "Swat",
"929436", "Chitral",
"922334", "Mirpur\ Khas",
"92482", "Sargodha",
"925436", "Chakwal",
"925468", "Mandi\ Bahauddin",
"92659", "Khanewal",
"92918", "Peshawar\/Charsadda",
"924533", "Bhakkar",
"929692", "Lakki\ Marwat",
"928267", "K\.Abdullah\/Pishin",
"926089", "Lodhran",
"926043", "Rajanpur",
"928472", "Kharan",
"924537", "Bhakkar",
"92632", "Bahawalnagar",
"92522", "Sialkot",
"929425", "Bajaur\ Agency",
"92406", "Sahiwal",
"928239", "Killa\ Saifullah",
"92658", "Khanewal",
"92919", "Peshawar\/Charsadda",
"926047", "Rajanpur",
"92423", "Lahore",
"928536", "Lasbela",
"928358", "Dera\ Bugti",
"928263", "K\.Abdullah\/Pishin",
"928568", "Awaran",
"92476", "Jhang",
"92667", "Muzaffargarh",
"928479", "Kharan",
"929387", "Swabi",
"929699", "Lakki\ Marwat",
"926082", "Lodhran",
"929393", "Buner",
"92259", "Dadu",
"925474", "Hafizabad",
"92519", "Islamabad\/Rawalpindi",
"922976", "Badin",
"92447", "Okara",
"925425", "Narowal",
"92577", "Attock",
"922328", "Tharparkar",
"925439", "Chakwal",
"928357", "Dera\ Bugti",
"928567", "Awaran",
"922972", "Badin",
"926048", "Rajanpur",
"925463", "Mandi\ Bahauddin",
"928434", "Mastung",
"926086", "Lodhran",
"924538", "Bhakkar",
"92539", "Gujrat",
"92629", "Bahawalpur",
"928532", "Lasbela",
"922444", "Nawabshah",
"922327", "Tharparkar",
"929463", "Swat",
"92612", "Multan",
"929223", "Kohat",
"928225", "Zhob",
"92228", "Hyderabad",
"929388", "Swabi",
"929439", "Chitral",
"922427", "Naushero\ Feroze",
"924592", "Mianwali",
"929446", "Upper\ Dir",
"92256", "Dadu",
"928242", "Loralai",
"927266", "Shikarpur",
"927238", "Ghotki",
"929669", "D\.I\.\ Khan",
"928555", "Panjgur",
"92867", "Gwadar",
"92516", "Islamabad\/Rawalpindi",
"929633", "Tank",
"922985", "Thatta",
"92409", "Sahiwal",
"922385", "Umerkot",
"92916", "Peshawar\/Charsadda",
"92485", "Sargodha",
"929963", "Shangla",
"924543", "Khushab",
"928287", "Musakhel",
"926069", "Layyah",
"928334", "Sibi\/Ziarat",
"92417", "Faisalabad",
"925446", "Jhelum",
"92479", "Jhang",
"928293", "Barkhan\/Kohlu",
"92812", "Quetta",
"925442", "Jhelum",
"922353", "Sanghar",
"928379", "Jhal\ Magsi",
"929974", "Mansehra\/Batagram",
"927237", "Ghotki",
"922428", "Naushero\ Feroze",
"929925", "Abottabad",
"92497", "Kasur",
"928323", "Bolan",
"92215", "Karachi",
"92642", "Dera\ Ghazi\ Khan",
"929325", "Malakand",
"929374", "Mardan",
"928288", "Musakhel",
"92563", "Sheikhupura",
"92673", "Vehari",
"928246", "Loralai",
"927262", "Shikarpur",
"92536", "Gujrat",
"92626", "Bahawalpur",
"92555", "Gujranwala",
"92462", "Toba\ Tek\ Singh",
"929442", "Upper\ Dir",
"924596", "Mianwali",};

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