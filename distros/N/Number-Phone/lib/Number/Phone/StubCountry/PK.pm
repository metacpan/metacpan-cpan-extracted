# automatically generated file, don't edit



# Copyright 2025 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20250605193636;

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
$areanames{en} = {"92912", "Peshawar\/Charsadda",
"924594", "Mianwali",
"92817", "Quetta",
"926068", "Layyah",
"929453", "Lower\ Dir",
"92573", "Attock",
"922327", "Tharparkar",
"929226", "Kohat",
"92662", "Muzaffargarh",
"929459", "Lower\ Dir",
"928357", "Dera\ Bugti",
"92572", "Attock",
"922337", "Mirpur\ Khas",
"92663", "Muzaffargarh",
"925474", "Hafizabad",
"928554", "Panjgur",
"924538", "Bhakkar",
"92216", "Karachi",
"928252", "Chagai",
"92913", "Peshawar\/Charsadda",
"922386", "Umerkot",
"92462", "Toba\ Tek\ Singh",
"928443", "Kalat",
"928338", "Sibi\/Ziarat",
"922358", "Sanghar",
"929667", "D\.I\.\ Khan",
"922984", "Thatta",
"922973", "Badin",
"929382", "Swabi",
"92633", "Bahawalnagar",
"928449", "Kalat",
"926048", "Rajanpur",
"922979", "Badin",
"92632", "Bahawalnagar",
"92255", "Dadu",
"929959", "Haripur",
"92463", "Toba\ Tek\ Singh",
"929378", "Mardan",
"929953", "Haripur",
"92214", "Karachi",
"928328", "Bolan",
"92745", "Larkana",
"92413", "Faisalabad",
"926065", "Layyah",
"929229", "Kohat",
"929654", "South\ Waziristan",
"929456", "Lower\ Dir",
"928284", "Musakhel",
"929223", "Kohat",
"928432", "Mastung",
"92219", "Karachi",
"924535", "Bhakkar",
"927267", "Shikarpur",
"92412", "Faisalabad",
"929397", "Buner",
"92405", "Sahiwal",
"92657", "Khanewal",
"92527", "Sialkot",
"922355", "Sanghar",
"922383", "Umerkot",
"929697", "Lakki\ Marwat",
"928335", "Sibi\/Ziarat",
"925437", "Chakwal",
"928446", "Kalat",
"922976", "Badin",
"926045", "Rajanpur",
"922389", "Umerkot",
"924544", "Khushab",
"92228", "Hyderabad",
"929972", "Mansehra\/Batagram",
"92613", "Multan",
"92612", "Multan",
"928567", "Awaran",
"928325", "Bolan",
"929375", "Mardan",
"929956", "Haripur",
"92867", "Gwadar",
"925427", "Narowal",
"928438", "Mastung",
"92492", "Kasur",
"92536", "Gujrat",
"92519", "Islamabad\/Rawalpindi",
"929967", "Shangla",
"92658", "Khanewal",
"92674", "Vehari",
"92476", "Jhang",
"928556", "Panjgur",
"92643", "Dera\ Ghazi\ Khan",
"925476", "Hafizabad",
"928283", "Musakhel",
"928255", "Chagai",
"929224", "Kohat",
"92642", "Dera\ Ghazi\ Khan",
"92564", "Sheikhupura",
"929447", "Upper\ Dir",
"929659", "South\ Waziristan",
"928289", "Musakhel",
"92493", "Kasur",
"924596", "Mianwali",
"929653", "South\ Waziristan",
"92715", "Sukkur",
"92443", "Okara",
"929385", "Swabi",
"929978", "Mansehra\/Batagram",
"92676", "Vehari",
"92474", "Jhang",
"92868", "Gwadar",
"92534", "Gujrat",
"92925", "Hangu\/Orakzai\ Agy",
"922427", "Naushero\ Feroze",
"924543", "Khushab",
"92227", "Hyderabad",
"922437", "Khairpur",
"92528", "Sialkot",
"922384", "Umerkot",
"92442", "Okara",
"924549", "Khushab",
"92566", "Sheikhupura",
"922986", "Thatta",
"929467", "Swat",
"92516", "Islamabad\/Rawalpindi",
"92539", "Gujrat",
"925479", "Hafizabad",
"928559", "Panjgur",
"928435", "Mastung",
"926062", "Layyah",
"92479", "Jhang",
"928553", "Panjgur",
"925473", "Hafizabad",
"928286", "Musakhel",
"92685", "Rahim\ Yar\ Khan",
"924599", "Mianwali",
"928258", "Chagai",
"92625", "Bahawalpur",
"924532", "Bhakkar",
"924593", "Mianwali",
"929454", "Lower\ Dir",
"929656", "South\ Waziristan",
"92818", "Quetta",
"926042", "Rajanpur",
"928237", "Killa\ Saifullah",
"92679", "Vehari",
"929388", "Swabi",
"929954", "Haripur",
"929975", "Mansehra\/Batagram",
"92555", "Gujranwala",
"922352", "Sanghar",
"928332", "Sibi\/Ziarat",
"92514", "Islamabad\/Rawalpindi",
"928322", "Bolan",
"929372", "Mardan",
"924546", "Khushab",
"92425", "Lahore",
"922989", "Thatta",
"928227", "Zhob",
"926087", "Lodhran",
"92485", "Sargodha",
"92569", "Sheikhupura",
"928444", "Kalat",
"922983", "Thatta",
"922974", "Badin",
"92447", "Okara",
"92429", "Lahore",
"922323", "Tharparkar",
"927222", "Jacobabad",
"925442", "Jhelum",
"92222", "Hyderabad",
"928245", "Loralai",
"922329", "Tharparkar",
"929457", "Lower\ Dir",
"92489", "Sargodha",
"92565", "Sheikhupura",
"92675", "Vehari",
"922339", "Mirpur\ Khas",
"928359", "Dera\ Bugti",
"92223", "Hyderabad",
"92559", "Gujranwala",
"92716", "Sukkur",
"929396", "Buner",
"92618", "Multan",
"929928", "Abottabad",
"922448", "Nawabshah",
"922333", "Mirpur\ Khas",
"92926", "Kurram\ Agency",
"928385", "Jaffarabad\/Nasirabad",
"928353", "Dera\ Bugti",
"927266", "Shikarpur",
"927232", "Ghotki",
"928478", "Kharan",
"92689", "Rahim\ Yar\ Khan",
"928265", "K\.Abdullah\/Pishin",
"928298", "Barkhan\/Kohlu",
"929428", "Bajaur\ Agency",
"928522", "Kech",
"929669", "D\.I\.\ Khan",
"926084", "Lodhran",
"929696", "Lakki\ Marwat",
"928224", "Zhob",
"92629", "Bahawalpur",
"922977", "Badin",
"929663", "D\.I\.\ Khan",
"925462", "Mandi\ Bahauddin",
"925436", "Chakwal",
"92647", "Dera\ Ghazi\ Khan",
"928447", "Kalat",
"928234", "Killa\ Saifullah",
"92535", "Gujrat",
"92924", "Khyber\/Mohmand\ Agy",
"925426", "Narowal",
"929957", "Haripur",
"928482", "Khuzdar",
"929438", "Chitral",
"92418", "Faisalabad",
"92714", "Sukkur",
"92497", "Kasur",
"928566", "Awaran",
"92475", "Jhang",
"928532", "Lasbela",
"929227", "Kohat",
"92468", "Toba\ Tek\ Singh",
"92624", "Bahawalpur",
"922326", "Tharparkar",
"92426", "Lahore",
"929444", "Upper\ Dir",
"929322", "Malakand",
"92486", "Sargodha",
"928372", "Jhal\ Magsi",
"928248", "Loralai",
"92684", "Rahim\ Yar\ Khan",
"92638", "Bahawalnagar",
"92719", "Sukkur",
"92556", "Gujranwala",
"927269", "Shikarpur",
"929393", "Buner",
"929964", "Shangla",
"922336", "Mirpur\ Khas",
"928356", "Dera\ Bugti",
"927263", "Shikarpur",
"928388", "Jaffarabad\/Nasirabad",
"922445", "Nawabshah",
"929399", "Buner",
"929925", "Abottabad",
"92484", "Sargodha",
"929699", "Lakki\ Marwat",
"928268", "K\.Abdullah\/Pishin",
"922434", "Khairpur",
"929425", "Bajaur\ Agency",
"928295", "Barkhan\/Kohlu",
"92918", "Peshawar\/Charsadda",
"925439", "Chakwal",
"928475", "Kharan",
"92686", "Rahim\ Yar\ Khan",
"922387", "Umerkot",
"92626", "Bahawalpur",
"929693", "Lakki\ Marwat",
"929464", "Swat",
"929666", "D\.I\.\ Khan",
"92424", "Lahore",
"929632", "Tank",
"925433", "Chakwal",
"92668", "Muzaffargarh",
"92578", "Attock",
"925423", "Narowal",
"928569", "Awaran",
"92515", "Islamabad\/Rawalpindi",
"924572", "Pakpattan",
"928563", "Awaran",
"92554", "Gujranwala",
"9258", "AJK\/FATA",
"925429", "Narowal",
"929435", "Chitral",
"922424", "Naushero\ Feroze",
"928242", "Loralai",
"927264", "Shikarpur",
"928378", "Jhal\ Magsi",
"929328", "Malakand",
"92256", "Dadu",
"929969", "Shangla",
"92637", "Bahawalnagar",
"925445", "Jhelum",
"927225", "Jacobabad",
"929963", "Shangla",
"929394", "Buner",
"928382", "Jaffarabad\/Nasirabad",
"929449", "Upper\ Dir",
"929657", "South\ Waziristan",
"927235", "Ghotki",
"92467", "Toba\ Tek\ Singh",
"928287", "Musakhel",
"929443", "Upper\ Dir",
"929638", "Tank",
"92215", "Karachi",
"928564", "Awaran",
"925465", "Mandi\ Bahauddin",
"92813", "Quetta",
"922423", "Naushero\ Feroze",
"928236", "Killa\ Saifullah",
"92577", "Attock",
"92409", "Sahiwal",
"928262", "K\.Abdullah\/Pishin",
"925424", "Narowal",
"928525", "Kech",
"92254", "Dadu",
"922429", "Naushero\ Feroze",
"926086", "Lodhran",
"928226", "Zhob",
"929694", "Lakki\ Marwat",
"92749", "Larkana",
"929463", "Swat",
"922439", "Khairpur",
"924578", "Pakpattan",
"92667", "Muzaffargarh",
"925434", "Chakwal",
"928535", "Lasbela",
"924547", "Khushab",
"922433", "Khairpur",
"92998", "Kohistan",
"92812", "Quetta",
"929469", "Swat",
"928485", "Khuzdar",
"92917", "Peshawar\/Charsadda",
"92259", "Dadu",
"929325", "Malakand",
"922334", "Mirpur\ Khas",
"92523", "Sialkot",
"928375", "Jhal\ Magsi",
"928354", "Dera\ Bugti",
"925477", "Hafizabad",
"92862", "Gwadar",
"928557", "Panjgur",
"92404", "Sahiwal",
"927228", "Jacobabad",
"925448", "Jhelum",
"929966", "Shangla",
"92617", "Multan",
"927238", "Ghotki",
"924597", "Mianwali",
"929922", "Abottabad",
"922442", "Nawabshah",
"92448", "Okara",
"922324", "Tharparkar",
"92522", "Sialkot",
"92744", "Larkana",
"929446", "Upper\ Dir",
"92863", "Gwadar",
"92417", "Faisalabad",
"928239", "Killa\ Saifullah",
"925468", "Mandi\ Bahauddin",
"92498", "Kasur",
"92652", "Khanewal",
"929635", "Tank",
"922426", "Naushero\ Feroze",
"928233", "Killa\ Saifullah",
"928528", "Kech",
"928292", "Barkhan\/Kohlu",
"929422", "Bajaur\ Agency",
"928472", "Kharan",
"92406", "Sahiwal",
"924575", "Pakpattan",
"928538", "Lasbela",
"926083", "Lodhran",
"928223", "Zhob",
"92746", "Larkana",
"922987", "Thatta",
"929664", "D\.I\.\ Khan",
"929466", "Swat",
"929432", "Chitral",
"92648", "Dera\ Ghazi\ Khan",
"928488", "Khuzdar",
"928229", "Zhob",
"926089", "Lodhran",
"922436", "Khairpur",
"92653", "Khanewal",
"929445", "Upper\ Dir",
"927239", "Ghotki",
"92553", "Gujranwala",
"92229", "Hyderabad",
"92482", "Sargodha",
"928257", "Chagai",
"92422", "Lahore",
"927233", "Ghotki",
"922332", "Mirpur\ Khas",
"928352", "Dera\ Bugti",
"925443", "Jhelum",
"927223", "Jacobabad",
"929965", "Shangla",
"92423", "Lahore",
"922322", "Tharparkar",
"927229", "Jacobabad",
"925449", "Jhelum",
"92552", "Gujranwala",
"929924", "Abottabad",
"922444", "Nawabshah",
"929326", "Malakand",
"928376", "Jhal\ Magsi",
"92483", "Sargodha",
"922435", "Khairpur",
"928294", "Barkhan\/Kohlu",
"929424", "Bajaur\ Agency",
"928474", "Kharan",
"928539", "Lasbela",
"928483", "Khuzdar",
"92622", "Bahawalpur",
"929465", "Swat",
"926088", "Lodhran",
"928228", "Zhob",
"92682", "Rahim\ Yar\ Khan",
"928533", "Lasbela",
"928489", "Khuzdar",
"924576", "Pakpattan",
"925469", "Mandi\ Bahauddin",
"928523", "Kech",
"92683", "Rahim\ Yar\ Khan",
"928238", "Killa\ Saifullah",
"92517", "Islamabad\/Rawalpindi",
"929387", "Swabi",
"92218", "Karachi",
"929662", "D\.I\.\ Khan",
"928529", "Kech",
"925463", "Mandi\ Bahauddin",
"929636", "Tank",
"929434", "Chitral",
"922425", "Naushero\ Feroze",
"92623", "Bahawalpur",
"929392", "Buner",
"92226", "Hyderabad",
"92445", "Okara",
"92713", "Sukkur",
"929448", "Upper\ Dir",
"927262", "Shikarpur",
"92567", "Sheikhupura",
"927236", "Ghotki",
"92923", "Nowshera",
"928244", "Loralai",
"925446", "Jhelum",
"928437", "Mastung",
"927226", "Jacobabad",
"92677", "Vehari",
"929968", "Shangla",
"929329", "Malakand",
"928379", "Jhal\ Magsi",
"929323", "Malakand",
"92712", "Sukkur",
"928384", "Jaffarabad\/Nasirabad",
"928373", "Jhal\ Magsi",
"925422", "Narowal",
"928486", "Khuzdar",
"924579", "Pakpattan",
"928264", "K\.Abdullah\/Pishin",
"922438", "Khairpur",
"928562", "Awaran",
"92645", "Dera\ Ghazi\ Khan",
"928536", "Lasbela",
"924573", "Pakpattan",
"92224", "Hyderabad",
"929468", "Swat",
"926085", "Lodhran",
"928225", "Zhob",
"928526", "Kech",
"929977", "Mansehra\/Batagram",
"929639", "Tank",
"928235", "Killa\ Saifullah",
"92537", "Gujrat",
"925466", "Mandi\ Bahauddin",
"929633", "Tank",
"92477", "Jhang",
"925432", "Chakwal",
"922428", "Naushero\ Feroze",
"92495", "Kasur",
"929692", "Lakki\ Marwat",
"92654", "Khanewal",
"922446", "Nawabshah",
"929926", "Abottabad",
"929324", "Malakand",
"922335", "Mirpur\ Khas",
"928355", "Dera\ Bugti",
"928374", "Jhal\ Magsi",
"927268", "Shikarpur",
"928383", "Jaffarabad\/Nasirabad",
"92866", "Gwadar",
"929442", "Upper\ Dir",
"92615", "Multan",
"92678", "Vehari",
"929398", "Buner",
"928389", "Jaffarabad\/Nasirabad",
"92568", "Sheikhupura",
"928243", "Loralai",
"92526", "Sialkot",
"929962", "Shangla",
"922325", "Tharparkar",
"928249", "Loralai",
"929462", "Swat",
"92864", "Gwadar",
"92478", "Jhang",
"929436", "Chitral",
"929634", "Tank",
"92402", "Sahiwal",
"92743", "Larkana",
"92415", "Faisalabad",
"928568", "Awaran",
"92656", "Khanewal",
"922432", "Khairpur",
"92538", "Gujrat",
"925428", "Narowal",
"929665", "D\.I\.\ Khan",
"929698", "Lakki\ Marwat",
"922422", "Naushero\ Feroze",
"924574", "Pakpattan",
"925438", "Chakwal",
"928269", "K\.Abdullah\/Pishin",
"92819", "Quetta",
"92403", "Sahiwal",
"929426", "Bajaur\ Agency",
"928296", "Barkhan\/Kohlu",
"928476", "Kharan",
"92524", "Sialkot",
"928263", "K\.Abdullah\/Pishin",
"92742", "Larkana",
"928358", "Dera\ Bugti",
"927265", "Shikarpur",
"922443", "Nawabshah",
"922338", "Mirpur\ Khas",
"929923", "Abottabad",
"924537", "Bhakkar",
"928386", "Jaffarabad\/Nasirabad",
"927224", "Jacobabad",
"925444", "Jhelum",
"929929", "Abottabad",
"929395", "Buner",
"92252", "Dadu",
"922449", "Nawabshah",
"92635", "Bahawalnagar",
"92869", "Gwadar",
"92529", "Sialkot",
"92253", "Dadu",
"927234", "Ghotki",
"926067", "Layyah",
"928246", "Loralai",
"922328", "Tharparkar",
"92814", "Quetta",
"92465", "Toba\ Tek\ Singh",
"92217", "Karachi",
"928565", "Awaran",
"925464", "Mandi\ Bahauddin",
"929433", "Chitral",
"926082", "Lodhran",
"928222", "Zhob",
"928524", "Kech",
"925425", "Narowal",
"92518", "Islamabad\/Rawalpindi",
"929439", "Chitral",
"92575", "Attock",
"929377", "Mardan",
"928327", "Bolan",
"92659", "Khanewal",
"928299", "Barkhan\/Kohlu",
"92816", "Quetta",
"929429", "Bajaur\ Agency",
"928479", "Kharan",
"928534", "Lasbela",
"925435", "Chakwal",
"92665", "Muzaffargarh",
"928337", "Sibi\/Ziarat",
"929668", "D\.I\.\ Khan",
"922357", "Sanghar",
"929695", "Lakki\ Marwat",
"929423", "Bajaur\ Agency",
"928293", "Barkhan\/Kohlu",
"92915", "Peshawar\/Charsadda",
"928484", "Khuzdar",
"928473", "Kharan",
"928232", "Killa\ Saifullah",
"928266", "K\.Abdullah\/Pishin",
"926047", "Rajanpur",
"927237", "Ghotki",
"929655", "South\ Waziristan",
"928259", "Chagai",
"92747", "Larkana",
"926064", "Layyah",
"924598", "Mianwali",
"92669", "Muzaffargarh",
"928253", "Chagai",
"928285", "Musakhel",
"92919", "Peshawar\/Charsadda",
"92614", "Multan",
"929452", "Lower\ Dir",
"925478", "Hafizabad",
"928558", "Panjgur",
"924534", "Bhakkar",
"92416", "Faisalabad",
"92579", "Attock",
"92407", "Sahiwal",
"925447", "Jhelum",
"927227", "Jacobabad",
"928436", "Mastung",
"92655", "Khanewal",
"928537", "Lasbela",
"922354", "Sanghar",
"92525", "Sialkot",
"922988", "Thatta",
"928334", "Sibi\/Ziarat",
"928487", "Khuzdar",
"92469", "Toba\ Tek\ Singh",
"929952", "Haripur",
"926044", "Rajanpur",
"924545", "Khushab",
"928442", "Kalat",
"925467", "Mandi\ Bahauddin",
"922972", "Badin",
"92928", "Bannu\/N\.\ Waziristan",
"929389", "Swabi",
"92616", "Multan",
"929976", "Mansehra\/Batagram",
"92639", "Bahawalnagar",
"928527", "Kech",
"92865", "Gwadar",
"92718", "Sukkur",
"928324", "Bolan",
"929383", "Swabi",
"929374", "Mardan",
"92414", "Faisalabad",
"924595", "Mianwali",
"92666", "Muzaffargarh",
"92213", "Karachi",
"92815", "Quetta",
"92628", "Bahawalpur",
"929658", "South\ Waziristan",
"92464", "Toba\ Tek\ Singh",
"92688", "Rahim\ Yar\ Khan",
"92916", "Peshawar\/Charsadda",
"928288", "Musakhel",
"928256", "Chagai",
"92419", "Faisalabad",
"925475", "Hafizabad",
"928439", "Mastung",
"928555", "Panjgur",
"928377", "Jhal\ Magsi",
"92634", "Bahawalnagar",
"929327", "Malakand",
"92212", "Karachi",
"928433", "Mastung",
"929222", "Kohat",
"92576", "Attock",
"92914", "Peshawar\/Charsadda",
"922985", "Thatta",
"92488", "Sargodha",
"924577", "Pakpattan",
"924548", "Khushab",
"92664", "Muzaffargarh",
"92428", "Lahore",
"92466", "Toba\ Tek\ Singh",
"929979", "Mansehra\/Batagram",
"92257", "Dadu",
"929637", "Tank",
"922382", "Umerkot",
"92574", "Attock",
"929973", "Mansehra\/Batagram",
"92558", "Gujranwala",
"92636", "Bahawalnagar",
"929386", "Swabi",
"92619", "Multan",
"928434", "Mastung",
"928282", "Musakhel",
"92512", "Islamabad\/Rawalpindi",
"929652", "South\ Waziristan",
"92499", "Kasur",
"928387", "Jaffarabad\/Nasirabad",
"924536", "Bhakkar",
"929228", "Kohat",
"92687", "Rahim\ Yar\ Khan",
"92513", "Islamabad\/Rawalpindi",
"929455", "Lower\ Dir",
"928247", "Loralai",
"92627", "Bahawalpur",
"926066", "Layyah",
"92649", "Dera\ Ghazi\ Khan",
"929974", "Mansehra\/Batagram",
"929955", "Haripur",
"92557", "Gujranwala",
"928326", "Bolan",
"924542", "Khushab",
"929376", "Mardan",
"92258", "Dadu",
"92449", "Okara",
"92427", "Lahore",
"926046", "Rajanpur",
"928267", "K\.Abdullah\/Pishin",
"928445", "Kalat",
"922388", "Umerkot",
"922975", "Badin",
"922356", "Sanghar",
"928336", "Sibi\/Ziarat",
"92487", "Sargodha",
"92472", "Jhang",
"92408", "Sahiwal",
"924539", "Bhakkar",
"922447", "Nawabshah",
"929927", "Abottabad",
"924592", "Mianwali",
"92496", "Kasur",
"92532", "Gujrat",
"924533", "Bhakkar",
"926069", "Layyah",
"928254", "Chagai",
"929225", "Kohat",
"92533", "Gujrat",
"92646", "Dera\ Ghazi\ Khan",
"925472", "Hafizabad",
"928552", "Panjgur",
"92473", "Jhang",
"92748", "Larkana",
"926063", "Layyah",
"929458", "Lower\ Dir",
"92444", "Okara",
"92717", "Sukkur",
"928323", "Bolan",
"92494", "Kasur",
"929373", "Mardan",
"929384", "Swabi",
"929958", "Haripur",
"929437", "Chitral",
"92563", "Sheikhupura",
"922982", "Thatta",
"928329", "Bolan",
"92927", "Karak",
"92672", "Vehari",
"929379", "Mardan",
"92644", "Dera\ Ghazi\ Khan",
"92562", "Sheikhupura",
"928477", "Kharan",
"929427", "Bajaur\ Agency",
"928297", "Barkhan\/Kohlu",
"926043", "Rajanpur",
"922359", "Sanghar",
"92673", "Vehari",
"92446", "Okara",
"92225", "Hyderabad",
"928339", "Sibi\/Ziarat",
"922385", "Umerkot",
"922353", "Sanghar",
"922978", "Badin",
"926049", "Rajanpur",
"928448", "Kalat",
"928333", "Sibi\/Ziarat",};
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