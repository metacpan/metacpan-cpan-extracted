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
our $VERSION = 1.20250913135858;

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
$areanames{en} = {"928533", "Lasbela",
"92257", "Dadu",
"92646", "Dera\ Ghazi\ Khan",
"929653", "South\ Waziristan",
"92443", "Okara",
"928438", "Mastung",
"922336", "Mirpur\ Khas",
"92718", "Sukkur",
"929977", "Mansehra\/Batagram",
"929328", "Malakand",
"929922", "Abottabad",
"928448", "Kalat",
"92444", "Okara",
"929457", "Lower\ Dir",
"928353", "Dera\ Bugti",
"92573", "Attock",
"92866", "Gwadar",
"928527", "Kech",
"928388", "Jaffarabad\/Nasirabad",
"92462", "Toba\ Tek\ Singh",
"922334", "Mirpur\ Khas",
"92677", "Vehari",
"92574", "Attock",
"928332", "Sibi\/Ziarat",
"92493", "Kasur",
"92669", "Muzaffargarh",
"922359", "Sanghar",
"922325", "Tharparkar",
"92255", "Dadu",
"926047", "Rajanpur",
"92688", "Rahim\ Yar\ Khan",
"929422", "Bajaur\ Agency",
"92494", "Kasur",
"928223", "Zhob",
"929957", "Haripur",
"929395", "Buner",
"922984", "Thatta",
"928552", "Panjgur",
"928247", "Loralai",
"929632", "Tank",
"922986", "Thatta",
"924593", "Mianwali",
"928373", "Jhal\ Magsi",
"928482", "Khuzdar",
"92675", "Vehari",
"928237", "Killa\ Saifullah",
"925469", "Mandi\ Bahauddin",
"92416", "Faisalabad",
"929455", "Lower\ Dir",
"92613", "Multan",
"924548", "Khushab",
"929429", "Bajaur\ Agency",
"92652", "Khanewal",
"92525", "Sialkot",
"929975", "Mansehra\/Batagram",
"92614", "Multan",
"92409", "Sahiwal",
"928224", "Zhob",
"928339", "Sibi\/Ziarat",
"92517", "Islamabad\/Rawalpindi",
"922983", "Thatta",
"924538", "Bhakkar",
"928376", "Jhal\ Magsi",
"924596", "Mianwali",
"922352", "Sanghar",
"92812", "Quetta",
"92918", "Peshawar\/Charsadda",
"924594", "Mianwali",
"928374", "Jhal\ Magsi",
"928226", "Zhob",
"925462", "Mandi\ Bahauddin",
"929639", "Tank",
"928525", "Kech",
"928559", "Panjgur",
"928489", "Khuzdar",
"929397", "Buner",
"929955", "Haripur",
"92527", "Sialkot",
"92624", "Bahawalpur",
"929929", "Abottabad",
"928534", "Lasbela",
"929654", "South\ Waziristan",
"92623", "Bahawalpur",
"92426", "Lahore",
"926045", "Rajanpur",
"922978", "Badin",
"922327", "Tharparkar",
"928268", "K\.Abdullah\/Pishin",
"928356", "Dera\ Bugti",
"92515", "Islamabad\/Rawalpindi",
"928235", "Killa\ Saifullah",
"928354", "Dera\ Bugti",
"92568", "Sheikhupura",
"928536", "Lasbela",
"92928", "Bannu\/N\.\ Waziristan",
"92532", "Gujrat",
"929656", "South\ Waziristan",
"926068", "Layyah",
"928245", "Loralai",
"922333", "Mirpur\ Khas",
"92528", "Sialkot",
"924543", "Khushab",
"928297", "Barkhan\/Kohlu",
"92642", "Dera\ Ghazi\ Khan",
"922988", "Thatta",
"924533", "Bhakkar",
"922382", "Umerkot",
"929962", "Shangla",
"929692", "Lakki\ Marwat",
"927232", "Ghotki",
"928567", "Awaran",
"92862", "Gwadar",
"92567", "Sheikhupura",
"92664", "Muzaffargarh",
"92915", "Peshawar\/Charsadda",
"922442", "Nawabshah",
"92927", "Karak",
"92499", "Kasur",
"92663", "Muzaffargarh",
"924572", "Pakpattan",
"92466", "Toba\ Tek\ Singh",
"925475", "Hafizabad",
"922432", "Khairpur",
"928434", "Mastung",
"928263", "K\.Abdullah\/Pishin",
"922973", "Badin",
"92579", "Attock",
"92518", "Islamabad\/Rawalpindi",
"929324", "Malakand",
"929462", "Swat",
"928444", "Kalat",
"928386", "Jaffarabad\/Nasirabad",
"929326", "Malakand",
"92917", "Peshawar\/Charsadda",
"928446", "Kalat",
"928384", "Jaffarabad\/Nasirabad",
"92565", "Sheikhupura",
"925429", "Narowal",
"928436", "Mastung",
"926063", "Layyah",
"92925", "Hangu\/Orakzai\ Agy",
"92449", "Okara",
"922338", "Mirpur\ Khas",
"928479", "Kharan",
"928538", "Lasbela",
"92656", "Khanewal",
"929658", "South\ Waziristan",
"92715", "Sukkur",
"928433", "Mastung",
"926066", "Layyah",
"92412", "Faisalabad",
"929469", "Swat",
"929323", "Malakand",
"928443", "Kalat",
"92687", "Rahim\ Yar\ Khan",
"928295", "Barkhan\/Kohlu",
"92816", "Quetta",
"922974", "Badin",
"928264", "K\.Abdullah\/Pishin",
"928266", "K\.Abdullah\/Pishin",
"922976", "Badin",
"928358", "Dera\ Bugti",
"925477", "Hafizabad",
"925422", "Narowal",
"928472", "Kharan",
"92629", "Bahawalpur",
"928383", "Jaffarabad\/Nasirabad",
"926064", "Layyah",
"928565", "Awaran",
"922389", "Umerkot",
"92258", "Dadu",
"92717", "Sukkur",
"929699", "Lakki\ Marwat",
"924544", "Khushab",
"929969", "Shangla",
"92422", "Lahore",
"928228", "Zhob",
"92685", "Rahim\ Yar\ Khan",
"924534", "Bhakkar",
"924536", "Bhakkar",
"922439", "Khairpur",
"924598", "Mianwali",
"928378", "Jhal\ Magsi",
"92403", "Sahiwal",
"924579", "Pakpattan",
"924546", "Khushab",
"927239", "Ghotki",
"92536", "Gujrat",
"922449", "Nawabshah",
"92678", "Vehari",
"92404", "Sahiwal",
"92619", "Multan",
"928568", "Awaran",
"92653", "Khanewal",
"92814", "Quetta",
"92612", "Multan",
"928244", "Loralai",
"929956", "Haripur",
"929439", "Chitral",
"92654", "Khanewal",
"92557", "Gujranwala",
"92487", "Sargodha",
"92813", "Quetta",
"928329", "Bolan",
"928234", "Killa\ Saifullah",
"926046", "Rajanpur",
"928355", "Dera\ Bugti",
"929449", "Upper\ Dir",
"926044", "Rajanpur",
"928236", "Killa\ Saifullah",
"929389", "Swabi",
"92635", "Bahawalnagar",
"928298", "Barkhan\/Kohlu",
"92429", "Lahore",
"929954", "Haripur",
"928246", "Loralai",
"922987", "Thatta",
"928535", "Lasbela",
"929655", "South\ Waziristan",
"928524", "Kech",
"929976", "Mansehra\/Batagram",
"929456", "Lower\ Dir",
"924595", "Mianwali",
"928375", "Jhal\ Magsi",
"922337", "Mirpur\ Khas",
"92485", "Sargodha",
"92622", "Bahawalpur",
"92555", "Gujranwala",
"928225", "Zhob",
"928259", "Chagai",
"929393", "Buner",
"92637", "Bahawalnagar",
"92534", "Gujrat",
"92406", "Sahiwal",
"929454", "Lower\ Dir",
"927269", "Shikarpur",
"922323", "Tharparkar",
"92533", "Gujrat",
"928526", "Kech",
"92419", "Faisalabad",
"92478", "Jhang",
"929974", "Mansehra\/Batagram",
"92217", "Karachi",
"928357", "Dera\ Bugti",
"92745", "Larkana",
"925478", "Hafizabad",
"922326", "Tharparkar",
"928523", "Kech",
"92442", "Okara",
"929396", "Buner",
"92225", "Hyderabad",
"92572", "Attock",
"927262", "Shikarpur",
"929657", "South\ Waziristan",
"928537", "Lasbela",
"92464", "Toba\ Tek\ Singh",
"929394", "Buner",
"922985", "Thatta",
"928252", "Chagai",
"929973", "Mansehra\/Batagram",
"92666", "Muzaffargarh",
"929453", "Lower\ Dir",
"92463", "Toba\ Tek\ Singh",
"922324", "Tharparkar",
"928243", "Loralai",
"922335", "Mirpur\ Khas",
"929442", "Upper\ Dir",
"928377", "Jhal\ Magsi",
"92747", "Larkana",
"92492", "Kasur",
"92215", "Karachi",
"924597", "Mianwali",
"928322", "Bolan",
"92869", "Gwadar",
"928233", "Killa\ Saifullah",
"92227", "Hyderabad",
"929432", "Chitral",
"926043", "Rajanpur",
"929382", "Swabi",
"929953", "Haripur",
"92649", "Dera\ Ghazi\ Khan",
"928227", "Zhob",
"92413", "Faisalabad",
"92616", "Multan",
"925473", "Hafizabad",
"92539", "Gujrat",
"929222", "Kohat",
"928528", "Kech",
"92748", "Larkana",
"928387", "Jaffarabad\/Nasirabad",
"926082", "Lodhran",
"92414", "Faisalabad",
"92228", "Hyderabad",
"928437", "Mastung",
"925432", "Chakwal",
"924535", "Bhakkar",
"929669", "D\.I\.\ Khan",
"928447", "Kalat",
"929372", "Mardan",
"929978", "Mansehra\/Batagram",
"929327", "Malakand",
"928282", "Musakhel",
"929458", "Lower\ Dir",
"924545", "Khushab",
"925442", "Jhelum",
"92424", "Lahore",
"926065", "Layyah",
"928248", "Loralai",
"92218", "Karachi",
"928564", "Awaran",
"92626", "Bahawalpur",
"928238", "Killa\ Saifullah",
"92423", "Lahore",
"928296", "Barkhan\/Kohlu",
"922429", "Naushero\ Feroze",
"928294", "Barkhan\/Kohlu",
"92402", "Sahiwal",
"92819", "Quetta",
"926048", "Rajanpur",
"922975", "Badin",
"928265", "K\.Abdullah\/Pishin",
"928566", "Awaran",
"929958", "Haripur",
"927229", "Jacobabad",
"92659", "Khanewal",
"928563", "Awaran",
"92643", "Dera\ Ghazi\ Khan",
"92446", "Okara",
"92644", "Dera\ Ghazi\ Khan",
"928385", "Jaffarabad\/Nasirabad",
"924547", "Khushab",
"927222", "Jacobabad",
"92576", "Attock",
"929325", "Malakand",
"92863", "Gwadar",
"92638", "Bahawalnagar",
"928445", "Kalat",
"928293", "Barkhan\/Kohlu",
"92662", "Muzaffargarh",
"924537", "Bhakkar",
"922422", "Naushero\ Feroze",
"92477", "Jhang",
"928435", "Mastung",
"92864", "Gwadar",
"9258", "AJK\/FATA",
"92496", "Kasur",
"926089", "Lodhran",
"92469", "Toba\ Tek\ Singh",
"925474", "Hafizabad",
"929229", "Kohat",
"92488", "Sargodha",
"92558", "Gujranwala",
"926067", "Layyah",
"929379", "Mardan",
"929398", "Buner",
"92998", "Kohistan",
"929662", "D\.I\.\ Khan",
"925449", "Jhelum",
"928289", "Musakhel",
"925476", "Hafizabad",
"92475", "Jhang",
"922977", "Badin",
"922328", "Tharparkar",
"928267", "K\.Abdullah\/Pishin",
"925439", "Chakwal",
"92647", "Dera\ Ghazi\ Khan",
"927223", "Jacobabad",
"92256", "Dadu",
"928292", "Barkhan\/Kohlu",
"929697", "Lakki\ Marwat",
"929967", "Shangla",
"922387", "Umerkot",
"922423", "Naushero\ Feroze",
"922447", "Nawabshah",
"92562", "Sheikhupura",
"92867", "Gwadar",
"928562", "Awaran",
"92229", "Hyderabad",
"92474", "Jhang",
"927237", "Ghotki",
"922437", "Khairpur",
"925425", "Narowal",
"92749", "Larkana",
"924577", "Pakpattan",
"92538", "Gujrat",
"928475", "Kharan",
"92676", "Vehari",
"92473", "Jhang",
"92658", "Khanewal",
"926086", "Lodhran",
"929663", "D\.I\.\ Khan",
"92645", "Dera\ Ghazi\ Khan",
"925434", "Chakwal",
"929374", "Mardan",
"929467", "Swat",
"92818", "Quetta",
"928284", "Musakhel",
"925444", "Jhelum",
"929226", "Kohat",
"928286", "Musakhel",
"925446", "Jhelum",
"929224", "Kohat",
"92865", "Gwadar",
"92912", "Peshawar\/Charsadda",
"929376", "Mardan",
"926084", "Lodhran",
"925436", "Chakwal",
"92219", "Karachi",
"925479", "Hafizabad",
"929664", "D\.I\.\ Khan",
"92417", "Faisalabad",
"922385", "Umerkot",
"925433", "Chakwal",
"927268", "Shikarpur",
"929695", "Lakki\ Marwat",
"929965", "Shangla",
"92639", "Bahawalnagar",
"928283", "Musakhel",
"925443", "Jhelum",
"92516", "Islamabad\/Rawalpindi",
"92425", "Lahore",
"928258", "Chagai",
"92682", "Rahim\ Yar\ Khan",
"929373", "Mardan",
"928477", "Kharan",
"925472", "Hafizabad",
"925427", "Narowal",
"924575", "Pakpattan",
"922435", "Khairpur",
"929223", "Kohat",
"927235", "Ghotki",
"926083", "Lodhran",
"929666", "D\.I\.\ Khan",
"922445", "Nawabshah",
"92526", "Sialkot",
"92712", "Sukkur",
"929465", "Swat",
"927224", "Jacobabad",
"92415", "Faisalabad",
"928299", "Barkhan\/Kohlu",
"922424", "Naushero\ Feroze",
"92427", "Lahore",
"929388", "Swabi",
"929448", "Upper\ Dir",
"928328", "Bolan",
"92559", "Gujranwala",
"92489", "Sargodha",
"922426", "Naushero\ Feroze",
"929438", "Chitral",
"927226", "Jacobabad",
"92468", "Toba\ Tek\ Singh",
"928569", "Awaran",
"92213", "Karachi",
"925438", "Chakwal",
"927263", "Shikarpur",
"922329", "Tharparkar",
"92252", "Dadu",
"922355", "Sanghar",
"929452", "Lower\ Dir",
"92428", "Lahore",
"928288", "Musakhel",
"925448", "Jhelum",
"92214", "Karachi",
"929399", "Buner",
"928253", "Chagai",
"929972", "Mansehra\/Batagram",
"929927", "Abottabad",
"929378", "Mardan",
"928522", "Kech",
"92566", "Sheikhupura",
"929228", "Kohat",
"92926", "Kurram\ Agency",
"92672", "Vehari",
"926088", "Lodhran",
"925465", "Mandi\ Bahauddin",
"92467", "Toba\ Tek\ Singh",
"92418", "Faisalabad",
"926042", "Rajanpur",
"92479", "Jhang",
"92224", "Hyderabad",
"928337", "Sibi\/Ziarat",
"92743", "Larkana",
"929952", "Haripur",
"92223", "Hyderabad",
"929383", "Swabi",
"92744", "Larkana",
"929427", "Bajaur\ Agency",
"92916", "Peshawar\/Charsadda",
"929443", "Upper\ Dir",
"928487", "Khuzdar",
"928323", "Bolan",
"929637", "Tank",
"928242", "Loralai",
"928557", "Panjgur",
"929433", "Chitral",
"92465", "Toba\ Tek\ Singh",
"928232", "Killa\ Saifullah",
"929925", "Abottabad",
"929436", "Chitral",
"92484", "Sargodha",
"927228", "Jacobabad",
"92554", "Gujranwala",
"929959", "Haripur",
"92657", "Khanewal",
"929384", "Swabi",
"92686", "Rahim\ Yar\ Khan",
"92483", "Sargodha",
"92817", "Quetta",
"929446", "Upper\ Dir",
"922357", "Sanghar",
"928326", "Bolan",
"926049", "Rajanpur",
"92553", "Gujranwala",
"92512", "Islamabad\/Rawalpindi",
"922428", "Naushero\ Feroze",
"925467", "Mandi\ Bahauddin",
"929386", "Swabi",
"929444", "Upper\ Dir",
"928324", "Bolan",
"928239", "Killa\ Saifullah",
"92535", "Gujrat",
"929434", "Chitral",
"928249", "Loralai",
"927264", "Shikarpur",
"929425", "Bajaur\ Agency",
"92648", "Dera\ Ghazi\ Khan",
"929459", "Lower\ Dir",
"92655", "Khanewal",
"929979", "Mansehra\/Batagram",
"929668", "D\.I\.\ Khan",
"92716", "Sukkur",
"929392", "Buner",
"92522", "Sialkot",
"928254", "Chagai",
"928335", "Sibi\/Ziarat",
"92815", "Quetta",
"922322", "Tharparkar",
"928256", "Chagai",
"92868", "Gwadar",
"92633", "Bahawalnagar",
"928555", "Panjgur",
"929635", "Tank",
"928529", "Kech",
"927266", "Shikarpur",
"92537", "Gujrat",
"92634", "Bahawalnagar",
"928485", "Khuzdar",
"929466", "Swat",
"92684", "Rahim\ Yar\ Khan",
"928473", "Kharan",
"928382", "Jaffarabad\/Nasirabad",
"926069", "Layyah",
"92498", "Kasur",
"929227", "Kohat",
"925423", "Narowal",
"92683", "Rahim\ Yar\ Khan",
"92486", "Sargodha",
"92556", "Gujranwala",
"926087", "Lodhran",
"925437", "Chakwal",
"92405", "Sahiwal",
"922425", "Naushero\ Feroze",
"928432", "Mastung",
"928269", "K\.Abdullah\/Pishin",
"922979", "Badin",
"925447", "Jhelum",
"928287", "Musakhel",
"929464", "Swat",
"929928", "Abottabad",
"929377", "Mardan",
"929322", "Malakand",
"92529", "Sialkot",
"927225", "Jacobabad",
"928442", "Kalat",
"929696", "Lakki\ Marwat",
"927234", "Ghotki",
"929966", "Shangla",
"928488", "Khuzdar",
"92448", "Okara",
"928558", "Panjgur",
"92713", "Sukkur",
"922386", "Umerkot",
"929638", "Tank",
"922444", "Nawabshah",
"924574", "Pakpattan",
"922434", "Khairpur",
"92714", "Sukkur",
"924576", "Pakpattan",
"922436", "Khairpur",
"92578", "Attock",
"92407", "Sahiwal",
"92519", "Islamabad\/Rawalpindi",
"924539", "Bhakkar",
"92636", "Bahawalnagar",
"928338", "Sibi\/Ziarat",
"929665", "D\.I\.\ Khan",
"922384", "Umerkot",
"922446", "Nawabshah",
"924549", "Khushab",
"927236", "Ghotki",
"929694", "Lakki\ Marwat",
"929428", "Bajaur\ Agency",
"929964", "Shangla",
"926085", "Lodhran",
"92216", "Karachi",
"925468", "Mandi\ Bahauddin",
"922443", "Nawabshah",
"927233", "Ghotki",
"92628", "Bahawalpur",
"924573", "Pakpattan",
"922433", "Khairpur",
"929225", "Kohat",
"92924", "Khyber\/Mohmand\ Agy",
"929375", "Mardan",
"927227", "Jacobabad",
"928285", "Musakhel",
"92563", "Sheikhupura",
"925445", "Jhelum",
"924542", "Khushab",
"929693", "Lakki\ Marwat",
"929963", "Shangla",
"92923", "Nowshera",
"92472", "Jhang",
"922358", "Sanghar",
"922427", "Naushero\ Feroze",
"922383", "Umerkot",
"92667", "Muzaffargarh",
"924532", "Bhakkar",
"925435", "Chakwal",
"92564", "Sheikhupura",
"92679", "Vehari",
"92618", "Multan",
"925424", "Narowal",
"928474", "Kharan",
"92746", "Larkana",
"928389", "Jaffarabad\/Nasirabad",
"926062", "Layyah",
"92226", "Hyderabad",
"92913", "Peshawar\/Charsadda",
"929667", "D\.I\.\ Khan",
"928449", "Kalat",
"929329", "Malakand",
"929463", "Swat",
"92665", "Muzaffargarh",
"928476", "Kharan",
"92914", "Peshawar\/Charsadda",
"922972", "Badin",
"928262", "K\.Abdullah\/Pishin",
"92259", "Dadu",
"928439", "Mastung",
"925426", "Narowal",
"928554", "Panjgur",
"92514", "Islamabad\/Rawalpindi",
"929634", "Tank",
"922448", "Nawabshah",
"925463", "Mandi\ Bahauddin",
"92617", "Multan",
"927238", "Ghotki",
"929426", "Bajaur\ Agency",
"928484", "Khuzdar",
"924578", "Pakpattan",
"922438", "Khairpur",
"928379", "Jhal\ Magsi",
"92513", "Islamabad\/Rawalpindi",
"924599", "Mianwali",
"92482", "Sargodha",
"92625", "Bahawalpur",
"92552", "Gujranwala",
"928336", "Sibi\/Ziarat",
"928255", "Chagai",
"928229", "Zhob",
"928334", "Sibi\/Ziarat",
"92719", "Sukkur",
"927265", "Shikarpur",
"929698", "Lakki\ Marwat",
"929424", "Bajaur\ Agency",
"929968", "Shangla",
"922353", "Sanghar",
"928486", "Khuzdar",
"928556", "Panjgur",
"929636", "Tank",
"922388", "Umerkot",
"922982", "Thatta",
"92523", "Sialkot",
"92615", "Multan",
"929435", "Chitral",
"929926", "Abottabad",
"92627", "Bahawalpur",
"922332", "Mirpur\ Khas",
"92524", "Sialkot",
"928359", "Dera\ Bugti",
"929445", "Upper\ Dir",
"928325", "Bolan",
"929385", "Swabi",
"92632", "Bahawalnagar",
"92689", "Rahim\ Yar\ Khan",
"929924", "Abottabad",
"929468", "Swat",
"92668", "Muzaffargarh",
"929659", "South\ Waziristan",
"928539", "Lasbela",
"922339", "Mirpur\ Khas",
"92447", "Okara",
"928478", "Kharan",
"92253", "Dadu",
"925428", "Narowal",
"92212", "Karachi",
"928352", "Dera\ Bugti",
"92495", "Kasur",
"92254", "Dadu",
"92919", "Peshawar\/Charsadda",
"928532", "Lasbela",
"92408", "Sahiwal",
"927267", "Shikarpur",
"92577", "Attock",
"929652", "South\ Waziristan",
"92674", "Vehari",
"929923", "Abottabad",
"92673", "Vehari",
"928257", "Chagai",
"92476", "Jhang",
"928372", "Jhal\ Magsi",
"92497", "Kasur",
"928327", "Bolan",
"924592", "Mianwali",
"92742", "Larkana",
"928483", "Khuzdar",
"922356", "Sanghar",
"929447", "Upper\ Dir",
"928553", "Panjgur",
"929633", "Tank",
"92445", "Okara",
"925464", "Mandi\ Bahauddin",
"92569", "Sheikhupura",
"929437", "Chitral",
"92222", "Hyderabad",
"92575", "Attock",
"922989", "Thatta",
"928333", "Sibi\/Ziarat",
"928222", "Zhob",
"925466", "Mandi\ Bahauddin",
"929423", "Bajaur\ Agency",
"929387", "Swabi",
"922354", "Sanghar",};
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