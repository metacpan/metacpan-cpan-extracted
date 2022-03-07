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
our $VERSION = 1.20220305001843;

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
$areanames{en} = {"92639", "Bahawalnagar",
"92402", "Sahiwal",
"92407", "Sahiwal",
"924597", "Mianwali",
"928253", "Chagai",
"929435", "Chitral",
"928352", "Dera\ Bugti",
"929376", "Mardan",
"929326", "Malakand",
"925465", "Mandi\ Bahauddin",
"929969", "Shangla",
"92447", "Okara",
"92442", "Okara",
"929422", "Bajaur\ Agency",
"928528", "Kech",
"928262", "K\.Abdullah\/Pishin",
"929446", "Upper\ Dir",
"929638", "Tank",
"929974", "Mansehra\/Batagram",
"929924", "Abottabad",
"929667", "D\.I\.\ Khan",
"922356", "Sanghar",
"92216", "Karachi",
"92679", "Vehari",
"929973", "Mansehra\/Batagram",
"929923", "Abottabad",
"928438", "Mastung",
"922338", "Mirpur\ Khas",
"929227", "Kohat",
"92474", "Jhang",
"928295", "Barkhan\/Kohlu",
"928329", "Bolan",
"922429", "Naushero\ Feroze",
"928379", "Jhal\ Magsi",
"924578", "Pakpattan",
"929656", "South\ Waziristan",
"92613", "Multan",
"92926", "Kurram\ Agency",
"92569", "Sheikhupura",
"929459", "Lower\ Dir",
"92523", "Sialkot",
"928449", "Kalat",
"927227", "Jacobabad",
"928254", "Chagai",
"922385", "Umerkot",
"928485", "Khuzdar",
"92483", "Sargodha",
"92626", "Bahawalpur",
"928239", "Killa\ Saifullah",
"92913", "Peshawar\/Charsadda",
"92223", "Hyderabad",
"92493", "Kasur",
"92658", "Khanewal",
"92418", "Faisalabad",
"92998", "Kohistan",
"922383", "Umerkot",
"929434", "Chitral",
"928483", "Khuzdar",
"929975", "Mansehra\/Batagram",
"929925", "Abottabad",
"92688", "Rahim\ Yar\ Khan",
"92635", "Bahawalnagar",
"925429", "Narowal",
"925479", "Hafizabad",
"92532", "Gujrat",
"928248", "Loralai",
"92537", "Gujrat",
"928293", "Barkhan\/Kohlu",
"928286", "Musakhel",
"92516", "Islamabad\/Rawalpindi",
"92713", "Sukkur",
"925464", "Mandi\ Bahauddin",
"928566", "Awaran",
"925463", "Mandi\ Bahauddin",
"922986", "Thatta",
"928557", "Panjgur",
"926046", "Rajanpur",
"926088", "Lodhran",
"928294", "Barkhan\/Kohlu",
"92675", "Vehari",
"92572", "Attock",
"92577", "Attock",
"929696", "Lakki\ Marwat",
"928255", "Chagai",
"928484", "Khuzdar",
"927236", "Ghotki",
"929433", "Chitral",
"922384", "Umerkot",
"92565", "Sheikhupura",
"92818", "Quetta",
"92667", "Muzaffargarh",
"92662", "Muzaffargarh",
"928387", "Jaffarabad\/Nasirabad",
"929324", "Malakand",
"929374", "Mardan",
"929662", "D\.I\.\ Khan",
"92466", "Toba\ Tek\ Singh",
"92714", "Sukkur",
"929427", "Bajaur\ Agency",
"928238", "Killa\ Saifullah",
"928267", "K\.Abdullah\/Pishin",
"929976", "Mansehra\/Batagram",
"929926", "Abottabad",
"929444", "Upper\ Dir",
"92678", "Vehari",
"929653", "South\ Waziristan",
"92746", "Larkana",
"928285", "Musakhel",
"922354", "Sanghar",
"925478", "Hafizabad",
"925428", "Narowal",
"92224", "Hyderabad",
"92494", "Kasur",
"92815", "Quetta",
"92568", "Sheikhupura",
"928565", "Awaran",
"928357", "Dera\ Bugti",
"928249", "Loralai",
"92914", "Peshawar\/Charsadda",
"924592", "Mianwali",
"927222", "Jacobabad",
"926089", "Lodhran",
"922985", "Thatta",
"92655", "Khanewal",
"929443", "Upper\ Dir",
"92415", "Faisalabad",
"929654", "South\ Waziristan",
"926045", "Rajanpur",
"92557", "Gujranwala",
"92552", "Gujranwala",
"922353", "Sanghar",
"92685", "Rahim\ Yar\ Khan",
"92638", "Bahawalnagar",
"929695", "Lakki\ Marwat",
"928256", "Chagai",
"92866", "Gwadar",
"927235", "Ghotki",
"92422", "Lahore",
"92427", "Lahore",
"929222", "Kohat",
"929323", "Malakand",
"929373", "Mardan",
"929436", "Chitral",
"927233", "Ghotki",
"929693", "Lakki\ Marwat",
"92819", "Quetta",
"929375", "Mardan",
"929325", "Malakand",
"925466", "Mandi\ Bahauddin",
"929639", "Tank",
"928564", "Awaran",
"922983", "Thatta",
"929968", "Shangla",
"929445", "Upper\ Dir",
"92252", "Dadu",
"92257", "Dadu",
"928284", "Musakhel",
"922355", "Sanghar",
"926043", "Rajanpur",
"928529", "Kech",
"92484", "Sargodha",
"92689", "Rahim\ Yar\ Khan",
"928296", "Barkhan\/Kohlu",
"928283", "Musakhel",
"929655", "South\ Waziristan",
"928382", "Jaffarabad\/Nasirabad",
"926044", "Rajanpur",
"922339", "Mirpur\ Khas",
"928439", "Mastung",
"92646", "Dera\ Ghazi\ Khan",
"928563", "Awaran",
"922428", "Naushero\ Feroze",
"922984", "Thatta",
"928378", "Jhal\ Magsi",
"92524", "Sialkot",
"928328", "Bolan",
"924579", "Pakpattan",
"92419", "Faisalabad",
"929458", "Lower\ Dir",
"92659", "Khanewal",
"92614", "Multan",
"928552", "Panjgur",
"922386", "Umerkot",
"927234", "Ghotki",
"928486", "Khuzdar",
"929694", "Lakki\ Marwat",
"92473", "Jhang",
"928448", "Kalat",
"929668", "D\.I\.\ Khan",
"929637", "Tank",
"925435", "Chakwal",
"928527", "Kech",
"928232", "Killa\ Saifullah",
"922433", "Khairpur",
"928333", "Sibi\/Ziarat",
"929384", "Swabi",
"92665", "Muzaffargarh",
"92562", "Sheikhupura",
"92567", "Sheikhupura",
"925446", "Jhelum",
"926063", "Layyah",
"92575", "Attock",
"924543", "Khushab",
"928225", "Zhob",
"924598", "Mianwali",
"925422", "Narowal",
"925472", "Hafizabad",
"92672", "Vehari",
"92677", "Vehari",
"929465", "Swat",
"926064", "Layyah",
"924544", "Khushab",
"92558", "Gujranwala",
"927228", "Jacobabad",
"92486", "Sargodha",
"92526", "Sialkot",
"922975", "Badin",
"92449", "Okara",
"92644", "Dera\ Ghazi\ Khan",
"92428", "Lahore",
"922434", "Khairpur",
"928334", "Sibi\/Ziarat",
"929383", "Swabi",
"929396", "Buner",
"92535", "Gujrat",
"924577", "Pakpattan",
"92213", "Karachi",
"929955", "Haripur",
"92923", "Nowshera",
"928437", "Mastung",
"922337", "Mirpur\ Khas",
"92409", "Sahiwal",
"929228", "Kohat",
"92616", "Multan",
"92632", "Bahawalnagar",
"92637", "Bahawalnagar",
"92464", "Toba\ Tek\ Singh",
"925434", "Chakwal",
"92716", "Sukkur",
"92669", "Muzaffargarh",
"929385", "Swabi",
"928536", "Lasbela",
"928359", "Dera\ Bugti",
"92579", "Attock",
"928247", "Loralai",
"92513", "Islamabad\/Rawalpindi",
"929953", "Haripur",
"928224", "Zhob",
"92744", "Larkana",
"929464", "Swat",
"92258", "Dadu",
"92916", "Peshawar\/Charsadda",
"928269", "K\.Abdullah\/Pishin",
"92623", "Bahawalpur",
"922973", "Badin",
"929429", "Bajaur\ Agency",
"92496", "Kasur",
"929962", "Shangla",
"92226", "Hyderabad",
"922446", "Nawabshah",
"922974", "Badin",
"928388", "Jaffarabad\/Nasirabad",
"928223", "Zhob",
"922422", "Naushero\ Feroze",
"92539", "Gujrat",
"928372", "Jhal\ Magsi",
"926065", "Layyah",
"928322", "Bolan",
"924545", "Khushab",
"929463", "Swat",
"927266", "Shikarpur",
"92405", "Sahiwal",
"922326", "Tharparkar",
"928476", "Kharan",
"92864", "Gwadar",
"926087", "Lodhran",
"929954", "Haripur",
"924536", "Bhakkar",
"928558", "Panjgur",
"925433", "Chakwal",
"928442", "Kalat",
"922435", "Khairpur",
"928335", "Sibi\/Ziarat",
"929452", "Lower\ Dir",
"92445", "Okara",
"928358", "Dera\ Bugti",
"92624", "Bahawalpur",
"929386", "Swabi",
"929393", "Buner",
"925477", "Hafizabad",
"925427", "Narowal",
"928535", "Lasbela",
"92429", "Lahore",
"92743", "Larkana",
"92408", "Sahiwal",
"92559", "Gujranwala",
"928522", "Kech",
"92514", "Islamabad\/Rawalpindi",
"928268", "K\.Abdullah\/Pishin",
"928237", "Killa\ Saifullah",
"929428", "Bajaur\ Agency",
"925444", "Jhelum",
"929632", "Tank",
"92463", "Toba\ Tek\ Singh",
"92448", "Okara",
"922445", "Nawabshah",
"924572", "Pakpattan",
"925443", "Jhelum",
"922332", "Mirpur\ Khas",
"928432", "Mastung",
"928389", "Jaffarabad\/Nasirabad",
"926066", "Layyah",
"924546", "Khushab",
"92863", "Gwadar",
"927265", "Shikarpur",
"928475", "Kharan",
"922325", "Tharparkar",
"928559", "Panjgur",
"92255", "Dadu",
"924535", "Bhakkar",
"928336", "Sibi\/Ziarat",
"922436", "Khairpur",
"929394", "Buner",
"92555", "Gujranwala",
"928473", "Kharan",
"922323", "Tharparkar",
"92657", "Khanewal",
"92652", "Khanewal",
"924533", "Bhakkar",
"92417", "Faisalabad",
"92412", "Faisalabad",
"929967", "Shangla",
"929669", "D\.I\.\ Khan",
"925436", "Chakwal",
"928534", "Lasbela",
"928242", "Loralai",
"924599", "Mianwali",
"922443", "Nawabshah",
"92425", "Lahore",
"925445", "Jhelum",
"92538", "Gujrat",
"928226", "Zhob",
"92682", "Rahim\ Yar\ Khan",
"92687", "Rahim\ Yar\ Khan",
"929466", "Swat",
"927263", "Shikarpur",
"928447", "Kalat",
"92924", "Khyber\/Mohmand\ Agy",
"929457", "Lower\ Dir",
"92476", "Jhang",
"92214", "Karachi",
"927264", "Shikarpur",
"92259", "Dadu",
"922976", "Badin",
"922444", "Nawabshah",
"926082", "Lodhran",
"927229", "Jacobabad",
"92668", "Muzaffargarh",
"922427", "Naushero\ Feroze",
"928377", "Jhal\ Magsi",
"928327", "Bolan",
"92643", "Dera\ Ghazi\ Khan",
"928533", "Lasbela",
"92812", "Quetta",
"929229", "Kohat",
"92817", "Quetta",
"929395", "Buner",
"92578", "Attock",
"922324", "Tharparkar",
"928474", "Kharan",
"929956", "Haripur",
"924534", "Bhakkar",
"928567", "Awaran",
"92468", "Toba\ Tek\ Singh",
"928355", "Dera\ Bugti",
"92443", "Okara",
"929432", "Chitral",
"928538", "Lasbela",
"928287", "Musakhel",
"929389", "Swabi",
"928265", "K\.Abdullah\/Pishin",
"92748", "Larkana",
"92403", "Sahiwal",
"92254", "Dadu",
"92219", "Karachi",
"92676", "Vehari",
"929425", "Bajaur\ Agency",
"925462", "Mandi\ Bahauddin",
"92566", "Sheikhupura",
"928386", "Jaffarabad\/Nasirabad",
"924549", "Khushab",
"928292", "Barkhan\/Kohlu",
"92527", "Sialkot",
"92522", "Sialkot",
"922448", "Nawabshah",
"926069", "Layyah",
"92625", "Bahawalpur",
"929697", "Lakki\ Marwat",
"927237", "Ghotki",
"92482", "Sargodha",
"92487", "Sargodha",
"927268", "Shikarpur",
"92515", "Islamabad\/Rawalpindi",
"92868", "Gwadar",
"926047", "Rajanpur",
"922328", "Tharparkar",
"928478", "Kharan",
"928339", "Sibi\/Ziarat",
"922439", "Khairpur",
"924538", "Bhakkar",
"92636", "Bahawalnagar",
"92617", "Multan",
"92612", "Multan",
"922987", "Thatta",
"922382", "Umerkot",
"928482", "Khuzdar",
"928556", "Panjgur",
"92925", "Hangu\/Orakzai\ Agy",
"922357", "Sanghar",
"929666", "D\.I\.\ Khan",
"925439", "Chakwal",
"92533", "Gujrat",
"929447", "Upper\ Dir",
"92215", "Karachi",
"92717", "Sukkur",
"92712", "Sukkur",
"928354", "Dera\ Bugti",
"92912", "Peshawar\/Charsadda",
"92917", "Peshawar\/Charsadda",
"928229", "Zhob",
"92222", "Hyderabad",
"925448", "Jhelum",
"92227", "Hyderabad",
"929327", "Malakand",
"929377", "Mardan",
"929469", "Swat",
"929922", "Abottabad",
"929972", "Mansehra\/Batagram",
"92492", "Kasur",
"92497", "Kasur",
"924596", "Mianwali",
"928264", "K\.Abdullah\/Pishin",
"929424", "Bajaur\ Agency",
"922979", "Badin",
"92519", "Islamabad\/Rawalpindi",
"928263", "K\.Abdullah\/Pishin",
"92554", "Gujranwala",
"92573", "Attock",
"929423", "Bajaur\ Agency",
"927226", "Jacobabad",
"92663", "Muzaffargarh",
"92648", "Dera\ Ghazi\ Khan",
"928252", "Chagai",
"928353", "Dera\ Bugti",
"929398", "Buner",
"92424", "Lahore",
"929959", "Haripur",
"92629", "Bahawalpur",
"929657", "South\ Waziristan",
"929226", "Kohat",
"929665", "D\.I\.\ Khan",
"92869", "Gwadar",
"928553", "Panjgur",
"925438", "Chakwal",
"925467", "Mandi\ Bahauddin",
"92645", "Dera\ Ghazi\ Khan",
"928282", "Musakhel",
"928383", "Jaffarabad\/Nasirabad",
"924595", "Mianwali",
"928228", "Zhob",
"929437", "Chitral",
"92534", "Gujrat",
"928562", "Awaran",
"929468", "Swat",
"925449", "Jhelum",
"92928", "Bannu\/N\.\ Waziristan",
"92749", "Larkana",
"928487", "Khuzdar",
"922387", "Umerkot",
"922982", "Thatta",
"927225", "Jacobabad",
"92218", "Karachi",
"92423", "Lahore",
"928384", "Jaffarabad\/Nasirabad",
"922978", "Badin",
"926042", "Rajanpur",
"92664", "Muzaffargarh",
"927232", "Ghotki",
"928554", "Panjgur",
"92469", "Toba\ Tek\ Singh",
"929692", "Lakki\ Marwat",
"928297", "Barkhan\/Kohlu",
"92574", "Attock",
"929399", "Buner",
"92553", "Gujranwala",
"929225", "Kohat",
"929958", "Haripur",
"928356", "Dera\ Bugti",
"92628", "Bahawalpur",
"929388", "Swabi",
"92253", "Dadu",
"929664", "D\.I\.\ Khan",
"929977", "Mansehra\/Batagram",
"929223", "Kohat",
"929927", "Abottabad",
"92416", "Faisalabad",
"929372", "Mardan",
"92404", "Sahiwal",
"929322", "Malakand",
"928539", "Lasbela",
"92656", "Khanewal",
"92865", "Gwadar",
"92518", "Islamabad\/Rawalpindi",
"928266", "K\.Abdullah\/Pishin",
"924594", "Mianwali",
"927223", "Jacobabad",
"929426", "Bajaur\ Agency",
"92686", "Rahim\ Yar\ Khan",
"922352", "Sanghar",
"92649", "Dera\ Ghazi\ Khan",
"929442", "Upper\ Dir",
"92444", "Okara",
"929652", "South\ Waziristan",
"92465", "Toba\ Tek\ Singh",
"928385", "Jaffarabad\/Nasirabad",
"927269", "Shikarpur",
"924548", "Khushab",
"922449", "Nawabshah",
"926068", "Layyah",
"924593", "Mianwali",
"928257", "Chagai",
"927224", "Jacobabad",
"92477", "Jhang",
"92472", "Jhang",
"92745", "Larkana",
"929663", "D\.I\.\ Khan",
"929224", "Kohat",
"922329", "Tharparkar",
"928479", "Kharan",
"928555", "Panjgur",
"92816", "Quetta",
"928338", "Sibi\/Ziarat",
"922438", "Khairpur",
"924539", "Bhakkar",
"92563", "Sheikhupura",
"92406", "Sahiwal",
"92619", "Multan",
"92654", "Khanewal",
"928235", "Killa\ Saifullah",
"929453", "Lower\ Dir",
"92414", "Faisalabad",
"925432", "Chakwal",
"928443", "Kalat",
"92673", "Vehari",
"92684", "Rahim\ Yar\ Khan",
"929964", "Shangla",
"92489", "Sargodha",
"928288", "Musakhel",
"928246", "Loralai",
"929929", "Abottabad",
"929979", "Mansehra\/Batagram",
"929462", "Swat",
"92446", "Okara",
"925475", "Hafizabad",
"925425", "Narowal",
"928537", "Lasbela",
"928222", "Zhob",
"92529", "Sialkot",
"928373", "Jhal\ Magsi",
"922423", "Naushero\ Feroze",
"928323", "Bolan",
"928568", "Awaran",
"92715", "Sukkur",
"928374", "Jhal\ Magsi",
"928324", "Bolan",
"922424", "Naushero\ Feroze",
"922988", "Thatta",
"929963", "Shangla",
"924537", "Bhakkar",
"92217", "Karachi",
"92212", "Karachi",
"92927", "Karak",
"922327", "Tharparkar",
"928477", "Kharan",
"926086", "Lodhran",
"92633", "Bahawalnagar",
"926048", "Rajanpur",
"922972", "Badin",
"927267", "Shikarpur",
"929454", "Lower\ Dir",
"927238", "Ghotki",
"928444", "Kalat",
"929698", "Lakki\ Marwat",
"92225", "Hyderabad",
"92814", "Quetta",
"92495", "Kasur",
"929952", "Haripur",
"922447", "Nawabshah",
"928259", "Chagai",
"92915", "Peshawar\/Charsadda",
"928234", "Killa\ Saifullah",
"92485", "Sargodha",
"929382", "Swabi",
"92622", "Bahawalpur",
"92627", "Bahawalpur",
"929378", "Mardan",
"929328", "Malakand",
"925447", "Jhelum",
"929439", "Chitral",
"92525", "Sialkot",
"925474", "Hafizabad",
"925424", "Narowal",
"928526", "Kech",
"925469", "Mandi\ Bahauddin",
"92615", "Multan",
"929636", "Tank",
"929448", "Upper\ Dir",
"929965", "Shangla",
"92517", "Islamabad\/Rawalpindi",
"92512", "Islamabad\/Rawalpindi",
"9258", "AJK\/FATA",
"922358", "Sanghar",
"92536", "Gujrat",
"928436", "Mastung",
"922336", "Mirpur\ Khas",
"92478", "Jhang",
"929658", "South\ Waziristan",
"924576", "Pakpattan",
"925423", "Narowal",
"925473", "Hafizabad",
"92499", "Kasur",
"92229", "Hyderabad",
"929397", "Buner",
"924542", "Khushab",
"928375", "Jhal\ Magsi",
"922425", "Naushero\ Feroze",
"928325", "Bolan",
"926062", "Layyah",
"928299", "Barkhan\/Kohlu",
"92919", "Peshawar\/Charsadda",
"922389", "Umerkot",
"928489", "Khuzdar",
"92719", "Sukkur",
"92666", "Muzaffargarh",
"928233", "Killa\ Saifullah",
"929455", "Lower\ Dir",
"928332", "Sibi\/Ziarat",
"922432", "Khairpur",
"928445", "Kalat",
"92576", "Attock",
"928532", "Lasbela",
"929379", "Mardan",
"929329", "Malakand",
"92475", "Jhang",
"929467", "Swat",
"929438", "Chitral",
"928227", "Zhob",
"92462", "Toba\ Tek\ Singh",
"92467", "Toba\ Tek\ Singh",
"929449", "Upper\ Dir",
"925468", "Mandi\ Bahauddin",
"922359", "Sanghar",
"925437", "Chakwal",
"928525", "Kech",
"929635", "Tank",
"929966", "Shangla",
"928244", "Loralai",
"92742", "Larkana",
"92747", "Larkana",
"926083", "Lodhran",
"929957", "Haripur",
"928435", "Mastung",
"92488", "Sargodha",
"922335", "Mirpur\ Khas",
"92556", "Gujranwala",
"928243", "Loralai",
"924575", "Pakpattan",
"926084", "Lodhran",
"928298", "Barkhan\/Kohlu",
"922442", "Nawabshah",
"927262", "Shikarpur",
"928376", "Jhal\ Magsi",
"922426", "Naushero\ Feroze",
"928326", "Bolan",
"92528", "Sialkot",
"929659", "South\ Waziristan",
"924532", "Bhakkar",
"92426", "Lahore",
"922977", "Badin",
"922322", "Tharparkar",
"928472", "Kharan",
"929456", "Lower\ Dir",
"92618", "Multan",
"92867", "Gwadar",
"92862", "Gwadar",
"928446", "Kalat",
"928488", "Khuzdar",
"922388", "Umerkot",
"92718", "Sukkur",
"928236", "Killa\ Saifullah",
"92683", "Rahim\ Yar\ Khan",
"929634", "Tank",
"925442", "Jhelum",
"92479", "Jhang",
"92256", "Dadu",
"929978", "Mansehra\/Batagram",
"929928", "Abottabad",
"928433", "Mastung",
"922333", "Mirpur\ Khas",
"92674", "Vehari",
"924573", "Pakpattan",
"92653", "Khanewal",
"928569", "Awaran",
"92413", "Faisalabad",
"928245", "Loralai",
"92228", "Hyderabad",
"929387", "Swabi",
"925476", "Hafizabad",
"925426", "Narowal",
"92564", "Sheikhupura",
"92498", "Kasur",
"928524", "Kech",
"92918", "Peshawar\/Charsadda",
"928289", "Musakhel",
"922437", "Khairpur",
"928337", "Sibi\/Ziarat",
"92642", "Dera\ Ghazi\ Khan",
"92647", "Dera\ Ghazi\ Khan",
"928523", "Kech",
"926049", "Rajanpur",
"92813", "Quetta",
"929633", "Tank",
"928434", "Mastung",
"922334", "Mirpur\ Khas",
"924574", "Pakpattan",
"922989", "Thatta",
"926085", "Lodhran",
"929392", "Buner",
"92634", "Bahawalnagar",
"928258", "Chagai",
"926067", "Layyah",
"924547", "Khushab",
"929699", "Lakki\ Marwat",
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