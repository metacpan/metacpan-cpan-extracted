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
our $VERSION = 1.20210309172132;

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
            [014]\\d|
            2[0-5]|
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
$areanames{en} = {"92572", "Attock",
"929447", "Upper\ Dir",
"92817", "Quetta",
"92252", "Dadu",
"92689", "Rahim\ Yar\ Khan",
"92926", "Kurram\ Agency",
"92912", "Peshawar\/Charsadda",
"922329", "Tharparkar",
"928324", "Bolan",
"92617", "Multan",
"92647", "Dera\ Ghazi\ Khan",
"924594", "Mianwali",
"928524", "Kech",
"929429", "Bajaur\ Agency",
"928479", "Kharan",
"92482", "Sargodha",
"929374", "Mardan",
"92673", "Vehari",
"928448", "Kalat",
"928437", "Mastung",
"929326", "Malakand",
"922426", "Naushero\ Feroze",
"92514", "Islamabad\/Rawalpindi",
"928372", "Jhal\ Magsi",
"929322", "Malakand",
"925427", "Narowal",
"928376", "Jhal\ Magsi",
"922422", "Naushero\ Feroze",
"929929", "Abottabad",
"925449", "Jhelum",
"929438", "Chitral",
"922974", "Badin",
"92928", "Bannu\/N\.\ Waziristan",
"925478", "Hafizabad",
"922338", "Mirpur\ Khas",
"92685", "Rahim\ Yar\ Khan",
"929388", "Swabi",
"92568", "Sheikhupura",
"927229", "Jacobabad",
"92473", "Jhang",
"928242", "Loralai",
"92682", "Rahim\ Yar\ Khan",
"928265", "K\.Abdullah\/Pishin",
"92259", "Dadu",
"92223", "Hyderabad",
"92919", "Peshawar\/Charsadda",
"928263", "K\.Abdullah\/Pishin",
"92447", "Okara",
"92417", "Faisalabad",
"92579", "Attock",
"925433", "Chakwal",
"928246", "Loralai",
"929959", "Haripur",
"925435", "Chakwal",
"925464", "Mandi\ Bahauddin",
"929654", "South\ Waziristan",
"92489", "Sargodha",
"929667", "D\.I\.\ Khan",
"926087", "Lodhran",
"928387", "Jaffarabad\/Nasirabad",
"928234", "Killa\ Saifullah",
"92746", "Larkana",
"92716", "Sukkur",
"929392", "Buner",
"922988", "Thatta",
"92485", "Sargodha",
"929694", "Lakki\ Marwat",
"926067", "Layyah",
"924576", "Pakpattan",
"928354", "Dera\ Bugti",
"929975", "Mansehra\/Batagram",
"92497", "Kasur",
"929973", "Mansehra\/Batagram",
"922359", "Sanghar",
"928554", "Panjgur",
"928567", "Awaran",
"924572", "Pakpattan",
"929459", "Lower\ Dir",
"927238", "Ghotki",
"92748", "Larkana",
"929396", "Buner",
"92718", "Sukkur",
"92915", "Peshawar\/Charsadda",
"92566", "Sheikhupura",
"92255", "Dadu",
"928285", "Musakhel",
"928283", "Musakhel",
"92575", "Attock",
"92863", "Gwadar",
"929444", "Upper\ Dir",
"928378", "Jhal\ Magsi",
"92562", "Sheikhupura",
"929328", "Malakand",
"92925", "Hangu\/Orakzai\ Agy",
"92634", "Bahawalnagar",
"922428", "Naushero\ Feroze",
"928483", "Khuzdar",
"92688", "Rahim\ Yar\ Khan",
"928485", "Khuzdar",
"926049", "Rajanpur",
"92654", "Khanewal",
"929436", "Chitral",
"928327", "Bolan",
"925476", "Hafizabad",
"924597", "Mianwali",
"922336", "Mirpur\ Khas",
"928527", "Kech",
"92663", "Muzaffargarh",
"929432", "Chitral",
"922332", "Mirpur\ Khas",
"929377", "Mardan",
"925472", "Hafizabad",
"928434", "Mastung",
"922439", "Khairpur",
"92712", "Sukkur",
"92742", "Larkana",
"925424", "Narowal",
"92427", "Lahore",
"928446", "Kalat",
"927269", "Shikarpur",
"92557", "Gujranwala",
"922977", "Badin",
"92537", "Gujrat",
"928223", "Zhob",
"924535", "Bhakkar",
"928225", "Zhob",
"92213", "Karachi",
"928442", "Kalat",
"92686", "Rahim\ Yar\ Khan",
"924533", "Bhakkar",
"92918", "Peshawar\/Charsadda",
"92258", "Dadu",
"928255", "Chagai",
"927236", "Ghotki",
"92569", "Sheikhupura",
"928253", "Chagai",
"922982", "Thatta",
"929398", "Buner",
"924549", "Khushab",
"92404", "Sahiwal",
"92578", "Attock",
"922986", "Thatta",
"929633", "Tank",
"927232", "Ghotki",
"929635", "Tank",
"92463", "Toba\ Tek\ Singh",
"924578", "Pakpattan",
"929969", "Shangla",
"929657", "South\ Waziristan",
"925467", "Mandi\ Bahauddin",
"929664", "D\.I\.\ Khan",
"922445", "Nawabshah",
"922443", "Nawabshah",
"92488", "Sargodha",
"926084", "Lodhran",
"928384", "Jaffarabad\/Nasirabad",
"928237", "Killa\ Saifullah",
"922389", "Umerkot",
"92715", "Sukkur",
"92524", "Sialkot",
"92745", "Larkana",
"929382", "Swabi",
"92998", "Kohistan",
"929697", "Lakki\ Marwat",
"926064", "Layyah",
"928248", "Loralai",
"92486", "Sargodha",
"92719", "Sukkur",
"928357", "Dera\ Bugti",
"929386", "Swabi",
"92749", "Larkana",
"92627", "Bahawalpur",
"928557", "Panjgur",
"929469", "Swat",
"928564", "Awaran",
"929229", "Kohat",
"928533", "Lasbela",
"928293", "Barkhan\/Kohlu",
"92565", "Sheikhupura",
"92916", "Peshawar\/Charsadda",
"928535", "Lasbela",
"92256", "Dadu",
"928295", "Barkhan\/Kohlu",
"928333", "Sibi\/Ziarat",
"928335", "Sibi\/Ziarat",
"92576", "Attock",
"92679", "Vehari",
"922382", "Umerkot",
"924534", "Bhakkar",
"928224", "Zhob",
"92668", "Muzaffargarh",
"922386", "Umerkot",
"929962", "Shangla",
"929458", "Lower\ Dir",
"927239", "Ghotki",
"92494", "Kasur",
"92472", "Jhang",
"928435", "Mastung",
"92216", "Karachi",
"922358", "Sanghar",
"92222", "Hyderabad",
"92683", "Rahim\ Yar\ Khan",
"928433", "Mastung",
"924542", "Khushab",
"929966", "Shangla",
"92868", "Gwadar",
"922989", "Thatta",
"925423", "Narowal",
"924546", "Khushab",
"925425", "Narowal",
"92218", "Karachi",
"92866", "Gwadar",
"929958", "Haripur",
"929222", "Kohat",
"929445", "Upper\ Dir",
"92444", "Okara",
"92414", "Faisalabad",
"929462", "Swat",
"929443", "Upper\ Dir",
"92675", "Vehari",
"929226", "Kohat",
"929466", "Swat",
"928484", "Khuzdar",
"92666", "Muzaffargarh",
"927228", "Jacobabad",
"929389", "Swabi",
"922339", "Mirpur\ Khas",
"928287", "Musakhel",
"925479", "Hafizabad",
"928334", "Sibi\/Ziarat",
"928534", "Lasbela",
"928294", "Barkhan\/Kohlu",
"925448", "Jhelum",
"929439", "Chitral",
"929928", "Abottabad",
"92483", "Sargodha",
"92672", "Vehari",
"92573", "Attock",
"926063", "Layyah",
"926042", "Rajanpur",
"926065", "Layyah",
"92468", "Toba\ Tek\ Singh",
"92479", "Jhang",
"926046", "Rajanpur",
"92253", "Dadu",
"928565", "Awaran",
"92229", "Hyderabad",
"92913", "Peshawar\/Charsadda",
"928563", "Awaran",
"929977", "Mansehra\/Batagram",
"92517", "Islamabad\/Rawalpindi",
"922444", "Nawabshah",
"926083", "Lodhran",
"926085", "Lodhran",
"928449", "Kalat",
"927262", "Shikarpur",
"929665", "D\.I\.\ Khan",
"92466", "Toba\ Tek\ Singh",
"928478", "Kharan",
"929663", "D\.I\.\ Khan",
"92614", "Multan",
"929428", "Bajaur\ Agency",
"92644", "Dera\ Ghazi\ Khan",
"928385", "Jaffarabad\/Nasirabad",
"92475", "Jhang",
"928383", "Jaffarabad\/Nasirabad",
"927266", "Shikarpur",
"922328", "Tharparkar",
"92225", "Hyderabad",
"928254", "Chagai",
"928267", "K\.Abdullah\/Pishin",
"922436", "Khairpur",
"929634", "Tank",
"925437", "Chakwal",
"922432", "Khairpur",
"92814", "Quetta",
"92678", "Vehari",
"924537", "Bhakkar",
"928227", "Zhob",
"92669", "Muzaffargarh",
"922975", "Badin",
"922973", "Badin",
"929468", "Swat",
"929228", "Kohat",
"929952", "Haripur",
"92624", "Bahawalpur",
"927226", "Jacobabad",
"92215", "Karachi",
"929956", "Haripur",
"928249", "Loralai",
"92869", "Gwadar",
"927222", "Jacobabad",
"92462", "Toba\ Tek\ Singh",
"928523", "Kech",
"924595", "Mianwali",
"92923", "Nowshera",
"928525", "Kech",
"92219", "Karachi",
"924593", "Mianwali",
"928323", "Bolan",
"92527", "Sialkot",
"922388", "Umerkot",
"928325", "Bolan",
"929375", "Mardan",
"929373", "Mardan",
"92865", "Gwadar",
"92407", "Sahiwal",
"924579", "Pakpattan",
"929452", "Lower\ Dir",
"929968", "Shangla",
"9258", "AJK\/FATA",
"924548", "Khushab",
"92676", "Vehari",
"922352", "Sanghar",
"929399", "Buner",
"929456", "Lower\ Dir",
"928487", "Khuzdar",
"922356", "Sanghar",
"92665", "Muzaffargarh",
"929426", "Bajaur\ Agency",
"928284", "Musakhel",
"928337", "Sibi\/Ziarat",
"92554", "Gujranwala",
"928472", "Kharan",
"928537", "Lasbela",
"928297", "Barkhan\/Kohlu",
"92534", "Gujrat",
"922326", "Tharparkar",
"927268", "Shikarpur",
"92662", "Muzaffargarh",
"929422", "Bajaur\ Agency",
"92424", "Lahore",
"922322", "Tharparkar",
"928476", "Kharan",
"929693", "Lakki\ Marwat",
"92862", "Gwadar",
"92469", "Toba\ Tek\ Singh",
"929695", "Lakki\ Marwat",
"928555", "Panjgur",
"928553", "Panjgur",
"92563", "Sheikhupura",
"928355", "Dera\ Bugti",
"929974", "Mansehra\/Batagram",
"922438", "Khairpur",
"92228", "Hyderabad",
"928353", "Dera\ Bugti",
"92478", "Jhang",
"922447", "Nawabshah",
"929926", "Abottabad",
"925465", "Mandi\ Bahauddin",
"929655", "South\ Waziristan",
"92465", "Toba\ Tek\ Singh",
"925442", "Jhelum",
"929653", "South\ Waziristan",
"925463", "Mandi\ Bahauddin",
"929922", "Abottabad",
"928233", "Killa\ Saifullah",
"92226", "Hyderabad",
"928235", "Killa\ Saifullah",
"92212", "Karachi",
"92476", "Jhang",
"925446", "Jhelum",
"928257", "Chagai",
"926048", "Rajanpur",
"928264", "K\.Abdullah\/Pishin",
"92637", "Bahawalnagar",
"922429", "Naushero\ Feroze",
"92713", "Sukkur",
"929329", "Malakand",
"92657", "Khanewal",
"92743", "Larkana",
"929637", "Tank",
"928379", "Jhal\ Magsi",
"925434", "Chakwal",
"928259", "Chagai",
"922427", "Naushero\ Feroze",
"929327", "Malakand",
"928436", "Mastung",
"925422", "Narowal",
"929963", "Shangla",
"929965", "Shangla",
"928377", "Jhal\ Magsi",
"92496", "Kasur",
"929639", "Tank",
"92625", "Bahawalpur",
"92214", "Karachi",
"928432", "Mastung",
"925426", "Narowal",
"924543", "Khushab",
"924545", "Khushab",
"922449", "Nawabshah",
"92567", "Sheikhupura",
"928444", "Kalat",
"929378", "Mardan",
"92418", "Faisalabad",
"92448", "Okara",
"928528", "Kech",
"924598", "Mianwali",
"928328", "Bolan",
"922383", "Umerkot",
"922385", "Umerkot",
"92552", "Gujranwala",
"929446", "Upper\ Dir",
"92532", "Gujrat",
"92664", "Muzaffargarh",
"92416", "Faisalabad",
"92422", "Lahore",
"929225", "Kohat",
"929442", "Upper\ Dir",
"929465", "Swat",
"92446", "Okara",
"929223", "Kohat",
"929463", "Swat",
"922334", "Mirpur\ Khas",
"928339", "Sibi\/Ziarat",
"92864", "Gwadar",
"925474", "Hafizabad",
"929434", "Chitral",
"922978", "Badin",
"928299", "Barkhan\/Kohlu",
"928539", "Lasbela",
"92633", "Bahawalnagar",
"92498", "Kasur",
"92717", "Sukkur",
"92653", "Khanewal",
"92629", "Bahawalpur",
"92747", "Larkana",
"92648", "Dera\ Ghazi\ Khan",
"926066", "Layyah",
"924577", "Pakpattan",
"92618", "Multan",
"928562", "Awaran",
"926043", "Rajanpur",
"929397", "Buner",
"928489", "Khuzdar",
"926045", "Rajanpur",
"928566", "Awaran",
"926062", "Layyah",
"929384", "Swabi",
"92425", "Lahore",
"928238", "Killa\ Saifullah",
"92818", "Quetta",
"92555", "Gujranwala",
"92535", "Gujrat",
"925468", "Mandi\ Bahauddin",
"929658", "South\ Waziristan",
"927234", "Ghotki",
"928558", "Panjgur",
"92429", "Lahore",
"922433", "Khairpur",
"922435", "Khairpur",
"928358", "Dera\ Bugti",
"92816", "Quetta",
"928247", "Loralai",
"92539", "Gujrat",
"92927", "Karak",
"929698", "Lakki\ Marwat",
"922984", "Thatta",
"92559", "Gujranwala",
"92523", "Sialkot",
"92646", "Dera\ Ghazi\ Khan",
"92622", "Bahawalpur",
"92616", "Multan",
"926086", "Lodhran",
"928382", "Jaffarabad\/Nasirabad",
"929666", "D\.I\.\ Khan",
"924539", "Bhakkar",
"92403", "Sahiwal",
"926082", "Lodhran",
"928229", "Zhob",
"92464", "Toba\ Tek\ Singh",
"929662", "D\.I\.\ Khan",
"927265", "Shikarpur",
"928386", "Jaffarabad\/Nasirabad",
"927263", "Shikarpur",
"928269", "K\.Abdullah\/Pishin",
"922424", "Naushero\ Feroze",
"927223", "Jacobabad",
"929324", "Malakand",
"92487", "Sargodha",
"927225", "Jacobabad",
"929953", "Haripur",
"925439", "Chakwal",
"92626", "Bahawalpur",
"928374", "Jhal\ Magsi",
"92612", "Multan",
"92642", "Dera\ Ghazi\ Khan",
"929448", "Upper\ Dir",
"92495", "Kasur",
"929955", "Haripur",
"92257", "Dadu",
"928447", "Kalat",
"92917", "Peshawar\/Charsadda",
"922972", "Badin",
"92513", "Islamabad\/Rawalpindi",
"92577", "Attock",
"92812", "Quetta",
"92449", "Okara",
"92419", "Faisalabad",
"922976", "Badin",
"925428", "Narowal",
"92445", "Okara",
"929455", "Lower\ Dir",
"92415", "Faisalabad",
"929453", "Lower\ Dir",
"922353", "Sanghar",
"929979", "Mansehra\/Batagram",
"922355", "Sanghar",
"928438", "Mastung",
"92674", "Vehari",
"928289", "Musakhel",
"929372", "Mardan",
"922337", "Mirpur\ Khas",
"928526", "Kech",
"924596", "Mianwali",
"925477", "Hafizabad",
"928326", "Bolan",
"929437", "Chitral",
"924592", "Mianwali",
"92628", "Bahawalpur",
"928522", "Kech",
"929376", "Mardan",
"92499", "Kasur",
"928322", "Bolan",
"929696", "Lakki\ Marwat",
"928552", "Panjgur",
"924574", "Pakpattan",
"928352", "Dera\ Bugti",
"92619", "Multan",
"92649", "Dera\ Ghazi\ Khan",
"929394", "Buner",
"928556", "Panjgur",
"929692", "Lakki\ Marwat",
"928356", "Dera\ Bugti",
"929387", "Swabi",
"92819", "Quetta",
"929423", "Bajaur\ Agency",
"92442", "Okara",
"929425", "Bajaur\ Agency",
"92412", "Faisalabad",
"92426", "Lahore",
"922325", "Tharparkar",
"928388", "Jaffarabad\/Nasirabad",
"922323", "Tharparkar",
"926088", "Lodhran",
"92556", "Gujranwala",
"928475", "Kharan",
"92687", "Rahim\ Yar\ Khan",
"928473", "Kharan",
"929668", "D\.I\.\ Khan",
"92536", "Gujrat",
"928568", "Awaran",
"927237", "Ghotki",
"92428", "Lahore",
"92815", "Quetta",
"928244", "Loralai",
"926068", "Layyah",
"922987", "Thatta",
"92558", "Gujranwala",
"92538", "Gujrat",
"92615", "Multan",
"92492", "Kasur",
"929925", "Abottabad",
"92645", "Dera\ Ghazi\ Khan",
"929923", "Abottabad",
"92474", "Jhang",
"925466", "Mandi\ Bahauddin",
"929656", "South\ Waziristan",
"928232", "Killa\ Saifullah",
"92224", "Hyderabad",
"925462", "Mandi\ Bahauddin",
"929652", "South\ Waziristan",
"928236", "Killa\ Saifullah",
"925445", "Jhelum",
"925443", "Jhelum",
"928228", "Zhob",
"92467", "Toba\ Tek\ Singh",
"924538", "Bhakkar",
"92518", "Islamabad\/Rawalpindi",
"92635", "Bahawalnagar",
"92924", "Khyber\/Mohmand\ Agy",
"929699", "Lakki\ Marwat",
"92655", "Khanewal",
"928359", "Dera\ Bugti",
"922354", "Sanghar",
"929454", "Lower\ Dir",
"929227", "Kohat",
"929467", "Swat",
"928559", "Panjgur",
"925469", "Mandi\ Bahauddin",
"929659", "South\ Waziristan",
"92659", "Khanewal",
"92623", "Bahawalpur",
"92639", "Bahawalnagar",
"92402", "Sahiwal",
"922387", "Umerkot",
"928239", "Killa\ Saifullah",
"929325", "Malakand",
"929323", "Malakand",
"927224", "Jacobabad",
"922423", "Naushero\ Feroze",
"928488", "Khuzdar",
"922425", "Naushero\ Feroze",
"924547", "Khushab",
"92516", "Islamabad\/Rawalpindi",
"92522", "Sialkot",
"928373", "Jhal\ Magsi",
"929967", "Shangla",
"928375", "Jhal\ Magsi",
"929954", "Haripur",
"929924", "Abottabad",
"92714", "Sukkur",
"92525", "Sialkot",
"92744", "Larkana",
"922979", "Badin",
"928298", "Barkhan\/Kohlu",
"928538", "Lasbela",
"927267", "Shikarpur",
"925444", "Jhelum",
"92867", "Gwadar",
"928338", "Sibi\/Ziarat",
"92405", "Sahiwal",
"922437", "Khairpur",
"928266", "K\.Abdullah\/Pishin",
"925432", "Chakwal",
"928245", "Loralai",
"925436", "Chakwal",
"928262", "K\.Abdullah\/Pishin",
"928243", "Loralai",
"92667", "Muzaffargarh",
"922324", "Tharparkar",
"928329", "Bolan",
"924599", "Mianwali",
"92409", "Sahiwal",
"929424", "Bajaur\ Agency",
"928529", "Kech",
"928286", "Musakhel",
"928474", "Kharan",
"92564", "Sheikhupura",
"92632", "Bahawalnagar",
"928282", "Musakhel",
"92652", "Khanewal",
"929379", "Mardan",
"922448", "Nawabshah",
"92529", "Sialkot",
"92553", "Gujranwala",
"929972", "Mansehra\/Batagram",
"92533", "Gujrat",
"924575", "Pakpattan",
"929638", "Tank",
"92217", "Karachi",
"924573", "Pakpattan",
"92423", "Lahore",
"929976", "Mansehra\/Batagram",
"929395", "Buner",
"926047", "Rajanpur",
"929393", "Buner",
"928258", "Chagai",
"929433", "Chitral",
"92443", "Okara",
"929435", "Chitral",
"92413", "Faisalabad",
"922335", "Mirpur\ Khas",
"925473", "Hafizabad",
"922333", "Mirpur\ Khas",
"925475", "Hafizabad",
"92519", "Islamabad\/Rawalpindi",
"92477", "Jhang",
"92227", "Hyderabad",
"92636", "Bahawalnagar",
"92656", "Khanewal",
"926069", "Layyah",
"928482", "Khuzdar",
"922357", "Sanghar",
"929457", "Lower\ Dir",
"929224", "Kohat",
"928569", "Awaran",
"929464", "Swat",
"928486", "Khuzdar",
"929669", "D\.I\.\ Khan",
"92493", "Kasur",
"92638", "Bahawalnagar",
"928443", "Kalat",
"924532", "Bhakkar",
"926089", "Lodhran",
"92658", "Khanewal",
"928222", "Zhob",
"928445", "Kalat",
"92684", "Rahim\ Yar\ Khan",
"928389", "Jaffarabad\/Nasirabad",
"922384", "Umerkot",
"928226", "Zhob",
"924536", "Bhakkar",
"927227", "Jacobabad",
"924544", "Khushab",
"92515", "Islamabad\/Rawalpindi",
"929964", "Shangla",
"929957", "Haripur",
"929927", "Abottabad",
"922446", "Nawabshah",
"92526", "Sialkot",
"92512", "Islamabad\/Rawalpindi",
"925447", "Jhelum",
"927264", "Shikarpur",
"922442", "Nawabshah",
"92813", "Quetta",
"928288", "Musakhel",
"928439", "Mastung",
"929978", "Mansehra\/Batagram",
"922434", "Khairpur",
"92406", "Sahiwal",
"927233", "Ghotki",
"92677", "Vehari",
"927235", "Ghotki",
"929632", "Tank",
"928256", "Chagai",
"92613", "Multan",
"925429", "Narowal",
"92643", "Dera\ Ghazi\ Khan",
"922983", "Thatta",
"929636", "Tank",
"928252", "Chagai",
"922985", "Thatta",
"928536", "Lasbela",
"928296", "Barkhan\/Kohlu",
"922327", "Tharparkar",
"92574", "Attock",
"92408", "Sahiwal",
"928336", "Sibi\/Ziarat",
"929427", "Bajaur\ Agency",
"928477", "Kharan",
"92914", "Peshawar\/Charsadda",
"928292", "Barkhan\/Kohlu",
"928532", "Lasbela",
"92254", "Dadu",
"928332", "Sibi\/Ziarat",
"925438", "Chakwal",
"929449", "Upper\ Dir",
"92528", "Sialkot",
"929383", "Swabi",
"929385", "Swabi",
"928268", "K\.Abdullah\/Pishin",
"926044", "Rajanpur",
"92484", "Sargodha",};

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