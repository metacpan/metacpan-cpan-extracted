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
our $VERSION = 1.20251210153524;

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
$areanames{en} = {"929924", "Abottabad",
"925443", "Jhelum",
"92912", "Peshawar\/Charsadda",
"925424", "Narowal",
"92222", "Hyderabad",
"929962", "Shangla",
"928482", "Khuzdar",
"928378", "Jhal\ Magsi",
"929449", "Upper\ Dir",
"928535", "Lasbela",
"925462", "Mandi\ Bahauddin",
"926049", "Rajanpur",
"922333", "Mirpur\ Khas",
"92654", "Khanewal",
"92627", "Bahawalpur",
"929455", "Lower\ Dir",
"92449", "Okara",
"924576", "Pakpattan",
"928476", "Kharan",
"925432", "Chakwal",
"928565", "Awaran",
"92408", "Sahiwal",
"92483", "Sargodha",
"928435", "Mastung",
"929463", "Swat",
"929442", "Upper\ Dir",
"924535", "Bhakkar",
"925469", "Mandi\ Bahauddin",
"929969", "Shangla",
"928489", "Khuzdar",
"928553", "Panjgur",
"922355", "Sanghar",
"928246", "Loralai",
"92486", "Sargodha",
"926042", "Rajanpur",
"929433", "Chitral",
"926063", "Layyah",
"925439", "Chakwal",
"92644", "Dera\ Ghazi\ Khan",
"92749", "Larkana",
"92443", "Okara",
"925428", "Narowal",
"929928", "Abottabad",
"928477", "Kharan",
"92446", "Okara",
"924577", "Pakpattan",
"928374", "Jhal\ Magsi",
"92684", "Rahim\ Yar\ Khan",
"92558", "Gujranwala",
"92743", "Larkana",
"92489", "Sargodha",
"92998", "Kohistan",
"92494", "Kasur",
"924595", "Mianwali",
"928247", "Loralai",
"92746", "Larkana",
"928245", "Loralai",
"922356", "Sanghar",
"928338", "Sibi\/Ziarat",
"924597", "Mianwali",
"92626", "Bahawalpur",
"925472", "Hafizabad",
"928436", "Mastung",
"929972", "Mansehra\/Batagram",
"929224", "Kohat",
"924536", "Bhakkar",
"928259", "Chagai",
"92623", "Bahawalpur",
"929456", "Lower\ Dir",
"924575", "Pakpattan",
"928475", "Kharan",
"92487", "Sargodha",
"928566", "Awaran",
"92532", "Gujrat",
"929979", "Mansehra\/Batagram",
"928283", "Musakhel",
"922988", "Thatta",
"925479", "Hafizabad",
"928536", "Lasbela",
"928252", "Chagai",
"929228", "Kohat",
"92525", "Sialkot",
"92862", "Gwadar",
"924596", "Mianwali",
"92447", "Okara",
"922357", "Sanghar",
"928322", "Bolan",
"92629", "Bahawalpur",
"924537", "Bhakkar",
"928334", "Sibi\/Ziarat",
"928437", "Mastung",
"92572", "Attock",
"922984", "Thatta",
"928567", "Awaran",
"92424", "Lahore",
"92218", "Karachi",
"92747", "Larkana",
"92928", "Bannu\/N\.\ Waziristan",
"929457", "Lower\ Dir",
"928329", "Bolan",
"92462", "Toba\ Tek\ Singh",
"928537", "Lasbela",
"929926", "Abottabad",
"925426", "Narowal",
"92665", "Muzaffargarh",
"92569", "Sheikhupura",
"929652", "South\ Waziristan",
"92674", "Vehari",
"928377", "Jhal\ Magsi",
"924574", "Pakpattan",
"928474", "Kharan",
"92255", "Dadu",
"929225", "Kohat",
"929393", "Buner",
"928244", "Loralai",
"929659", "South\ Waziristan",
"92538", "Gujrat",
"928223", "Zhob",
"927223", "Jacobabad",
"92479", "Jhang",
"924578", "Pakpattan",
"928353", "Dera\ Bugti",
"92566", "Sheikhupura",
"928382", "Jaffarabad\/Nasirabad",
"925427", "Narowal",
"92868", "Gwadar",
"922442", "Nawabshah",
"928478", "Kharan",
"929927", "Abottabad",
"922985", "Thatta",
"922433", "Khairpur",
"92563", "Sheikhupura",
"928376", "Jhal\ Magsi",
"92578", "Attock",
"928335", "Sibi\/Ziarat",
"928248", "Loralai",
"92212", "Karachi",
"92473", "Jhang",
"92468", "Toba\ Tek\ Singh",
"922449", "Nawabshah",
"928389", "Jaffarabad\/Nasirabad",
"92617", "Multan",
"92634", "Bahawalnagar",
"92476", "Jhang",
"928529", "Kech",
"92414", "Faisalabad",
"922354", "Sanghar",
"92228", "Hyderabad",
"92918", "Peshawar\/Charsadda",
"928434", "Mastung",
"929226", "Kohat",
"928337", "Sibi\/Ziarat",
"924534", "Bhakkar",
"924598", "Mianwali",
"92515", "Islamabad\/Rawalpindi",
"928522", "Kech",
"92814", "Quetta",
"92402", "Sahiwal",
"929454", "Lower\ Dir",
"92714", "Sukkur",
"92619", "Multan",
"928564", "Awaran",
"922987", "Thatta",
"929925", "Abottabad",
"925425", "Narowal",
"928534", "Lasbela",
"928438", "Mastung",
"924594", "Mianwali",
"924538", "Bhakkar",
"92567", "Sheikhupura",
"922979", "Badin",
"922358", "Sanghar",
"928336", "Sibi\/Ziarat",
"92552", "Gujranwala",
"929227", "Kohat",
"922986", "Thatta",
"92477", "Jhang",
"928375", "Jhal\ Magsi",
"928538", "Lasbela",
"92616", "Multan",
"922972", "Badin",
"929458", "Lower\ Dir",
"929373", "Mardan",
"928568", "Awaran",
"92613", "Multan",
"92713", "Sukkur",
"926084", "Lodhran",
"92813", "Quetta",
"922325", "Tharparkar",
"928523", "Kech",
"92716", "Sukkur",
"929387", "Swabi",
"92518", "Islamabad\/Rawalpindi",
"92816", "Quetta",
"929666", "D\.I\.\ Khan",
"92413", "Faisalabad",
"929425", "Bajaur\ Agency",
"929697", "Lakki\ Marwat",
"924544", "Khushab",
"92677", "Vehari",
"929636", "Tank",
"92416", "Faisalabad",
"922384", "Umerkot",
"92225", "Hyderabad",
"929954", "Haripur",
"92915", "Peshawar\/Charsadda",
"928444", "Kalat",
"922973", "Badin",
"929372", "Mardan",
"92719", "Sukkur",
"92614", "Multan",
"926088", "Lodhran",
"92637", "Bahawalnagar",
"92819", "Quetta",
"929386", "Swabi",
"929696", "Lakki\ Marwat",
"924548", "Khushab",
"929379", "Mardan",
"929958", "Haripur",
"928448", "Kalat",
"929667", "D\.I\.\ Khan",
"922388", "Umerkot",
"92419", "Faisalabad",
"929637", "Tank",
"92817", "Quetta",
"92639", "Bahawalnagar",
"929635", "Tank",
"928222", "Zhob",
"927264", "Shikarpur",
"928264", "K\.Abdullah\/Pishin",
"927222", "Jacobabad",
"92535", "Gujrat",
"92717", "Sukkur",
"929328", "Malakand",
"929392", "Buner",
"929665", "D\.I\.\ Khan",
"927234", "Ghotki",
"929426", "Bajaur\ Agency",
"928234", "Killa\ Saifullah",
"928298", "Barkhan\/Kohlu",
"929653", "South\ Waziristan",
"928229", "Zhob",
"92258", "Dadu",
"92417", "Faisalabad",
"922428", "Naushero\ Feroze",
"927229", "Jacobabad",
"92676", "Vehari",
"929399", "Buner",
"92673", "Vehari",
"922326", "Tharparkar",
"92668", "Muzaffargarh",
"922439", "Khairpur",
"92636", "Bahawalnagar",
"92474", "Jhang",
"927238", "Ghotki",
"928294", "Barkhan\/Kohlu",
"928238", "Killa\ Saifullah",
"929695", "Lakki\ Marwat",
"92633", "Bahawalnagar",
"92465", "Toba\ Tek\ Singh",
"927268", "Shikarpur",
"929427", "Bajaur\ Agency",
"928359", "Dera\ Bugti",
"929324", "Malakand",
"928268", "K\.Abdullah\/Pishin",
"92575", "Attock",
"922432", "Khairpur",
"92679", "Vehari",
"929385", "Swabi",
"922327", "Tharparkar",
"928352", "Dera\ Bugti",
"92564", "Sheikhupura",
"92865", "Gwadar",
"922443", "Nawabshah",
"928383", "Jaffarabad\/Nasirabad",
"922424", "Naushero\ Feroze",
"92522", "Sialkot",
"926086", "Lodhran",
"928282", "Musakhel",
"929388", "Swabi",
"928253", "Chagai",
"92429", "Lahore",
"92647", "Dera\ Ghazi\ Khan",
"92252", "Dadu",
"929973", "Mansehra\/Batagram",
"928289", "Musakhel",
"929664", "D\.I\.\ Khan",
"925473", "Hafizabad",
"927235", "Ghotki",
"928235", "Killa\ Saifullah",
"924546", "Khushab",
"929634", "Tank",
"92657", "Khanewal",
"929698", "Lakki\ Marwat",
"927265", "Shikarpur",
"92624", "Bahawalpur",
"928265", "K\.Abdullah\/Pishin",
"92662", "Muzaffargarh",
"922386", "Umerkot",
"929956", "Haripur",
"928446", "Kalat",
"92423", "Lahore",
"922425", "Naushero\ Feroze",
"926087", "Lodhran",
"92497", "Kasur",
"92426", "Lahore",
"92215", "Karachi",
"929384", "Swabi",
"92925", "Hangu\/Orakzai\ Agy",
"929694", "Lakki\ Marwat",
"929638", "Tank",
"929325", "Malakand",
"928447", "Kalat",
"929957", "Haripur",
"922387", "Umerkot",
"929668", "D\.I\.\ Khan",
"928323", "Bolan",
"92687", "Rahim\ Yar\ Khan",
"92528", "Sialkot",
"928295", "Barkhan\/Kohlu",
"924547", "Khushab",
"92646", "Dera\ Ghazi\ Khan",
"926043", "Rajanpur",
"924545", "Khushab",
"922339", "Mirpur\ Khas",
"929432", "Chitral",
"928297", "Barkhan\/Kohlu",
"927266", "Shikarpur",
"928266", "K\.Abdullah\/Pishin",
"92484", "Sargodha",
"922385", "Umerkot",
"929955", "Haripur",
"926062", "Layyah",
"928445", "Kalat",
"92499", "Kasur",
"92643", "Dera\ Ghazi\ Khan",
"929462", "Swat",
"925449", "Jhelum",
"929327", "Malakand",
"927236", "Ghotki",
"929424", "Bajaur\ Agency",
"92405", "Sahiwal",
"928236", "Killa\ Saifullah",
"928552", "Panjgur",
"929443", "Upper\ Dir",
"92512", "Islamabad\/Rawalpindi",
"92689", "Rahim\ Yar\ Khan",
"929439", "Chitral",
"922332", "Mirpur\ Khas",
"926069", "Layyah",
"925433", "Chakwal",
"92656", "Khanewal",
"926085", "Lodhran",
"922427", "Naushero\ Feroze",
"929469", "Swat",
"925442", "Jhelum",
"92653", "Khanewal",
"925463", "Mandi\ Bahauddin",
"929963", "Shangla",
"928483", "Khuzdar",
"922324", "Tharparkar",
"928559", "Panjgur",
"92649", "Dera\ Ghazi\ Khan",
"92427", "Lahore",
"92744", "Larkana",
"928267", "K\.Abdullah\/Pishin",
"927267", "Shikarpur",
"928296", "Barkhan\/Kohlu",
"929428", "Bajaur\ Agency",
"92496", "Kasur",
"928237", "Killa\ Saifullah",
"927237", "Ghotki",
"929326", "Malakand",
"92493", "Kasur",
"92555", "Gujranwala",
"92686", "Rahim\ Yar\ Khan",
"92659", "Khanewal",
"922328", "Tharparkar",
"92444", "Okara",
"92683", "Rahim\ Yar\ Khan",
"922426", "Naushero\ Feroze",
"92866", "Gwadar",
"929978", "Mansehra\/Batagram",
"92568", "Sheikhupura",
"922989", "Thatta",
"925478", "Hafizabad",
"92573", "Attock",
"928324", "Bolan",
"92863", "Gwadar",
"928332", "Sibi\/Ziarat",
"929693", "Lakki\ Marwat",
"92576", "Attock",
"922982", "Thatta",
"92466", "Toba\ Tek\ Singh",
"929383", "Swabi",
"928258", "Chagai",
"928527", "Kech",
"922976", "Badin",
"928339", "Sibi\/Ziarat",
"92478", "Jhang",
"92463", "Toba\ Tek\ Singh",
"92635", "Bahawalnagar",
"92539", "Gujrat",
"928385", "Jaffarabad\/Nasirabad",
"922445", "Nawabshah",
"92869", "Gwadar",
"92622", "Bahawalpur",
"929633", "Tank",
"92664", "Muzaffargarh",
"92227", "Hyderabad",
"925474", "Hafizabad",
"92254", "Dadu",
"929663", "D\.I\.\ Khan",
"92917", "Peshawar\/Charsadda",
"92579", "Attock",
"929974", "Mansehra\/Batagram",
"929222", "Kohat",
"92675", "Vehari",
"928328", "Bolan",
"92469", "Toba\ Tek\ Singh",
"929655", "South\ Waziristan",
"928526", "Kech",
"92533", "Gujrat",
"929229", "Kohat",
"92536", "Gujrat",
"928254", "Chagai",
"922977", "Badin",
"922975", "Badin",
"925438", "Chakwal",
"92919", "Peshawar\/Charsadda",
"92577", "Attock",
"928386", "Jaffarabad\/Nasirabad",
"92229", "Hyderabad",
"922446", "Nawabshah",
"929657", "South\ Waziristan",
"925468", "Mandi\ Bahauddin",
"928372", "Jhal\ Magsi",
"928488", "Khuzdar",
"929968", "Shangla",
"92442", "Okara",
"92867", "Gwadar",
"926048", "Rajanpur",
"92618", "Multan",
"92742", "Larkana",
"92467", "Toba\ Tek\ Singh",
"928379", "Jhal\ Magsi",
"929448", "Upper\ Dir",
"922447", "Nawabshah",
"929922", "Abottabad",
"928387", "Jaffarabad\/Nasirabad",
"925422", "Narowal",
"929964", "Shangla",
"922323", "Tharparkar",
"928484", "Khuzdar",
"92916", "Peshawar\/Charsadda",
"92415", "Faisalabad",
"925464", "Mandi\ Bahauddin",
"92226", "Hyderabad",
"928525", "Kech",
"929656", "South\ Waziristan",
"92913", "Peshawar\/Charsadda",
"925434", "Chakwal",
"92223", "Hyderabad",
"925429", "Narowal",
"929929", "Abottabad",
"92715", "Sukkur",
"92537", "Gujrat",
"929444", "Upper\ Dir",
"92815", "Quetta",
"92514", "Islamabad\/Rawalpindi",
"929423", "Bajaur\ Agency",
"926044", "Rajanpur",
"92482", "Sargodha",
"92553", "Gujranwala",
"924592", "Mianwali",
"928326", "Bolan",
"92556", "Gujranwala",
"92685", "Rahim\ Yar\ Khan",
"92448", "Okara",
"929977", "Mansehra\/Batagram",
"925477", "Hafizabad",
"92612", "Multan",
"924599", "Mianwali",
"92409", "Sahiwal",
"92748", "Larkana",
"92217", "Karachi",
"928528", "Kech",
"928257", "Chagai",
"922974", "Badin",
"92927", "Karak",
"92495", "Kasur",
"929459", "Lower\ Dir",
"922352", "Sanghar",
"928327", "Bolan",
"924543", "Khushab",
"926045", "Rajanpur",
"928443", "Kalat",
"928569", "Awaran",
"929953", "Haripur",
"922383", "Umerkot",
"925476", "Hafizabad",
"92559", "Gujranwala",
"928432", "Mastung",
"929976", "Mansehra\/Batagram",
"929445", "Upper\ Dir",
"928539", "Lasbela",
"924532", "Bhakkar",
"92655", "Khanewal",
"928524", "Kech",
"922978", "Badin",
"922359", "Sanghar",
"929452", "Lower\ Dir",
"928562", "Awaran",
"925435", "Chakwal",
"92406", "Sahiwal",
"928439", "Mastung",
"926083", "Lodhran",
"92645", "Dera\ Ghazi\ Khan",
"929965", "Shangla",
"928485", "Khuzdar",
"92403", "Sahiwal",
"925465", "Mandi\ Bahauddin",
"928532", "Lasbela",
"924539", "Bhakkar",
"928256", "Chagai",
"92488", "Sargodha",
"92562", "Sheikhupura",
"925467", "Mandi\ Bahauddin",
"929658", "South\ Waziristan",
"928487", "Khuzdar",
"929967", "Shangla",
"928384", "Jaffarabad\/Nasirabad",
"922423", "Naushero\ Feroze",
"92524", "Sialkot",
"922444", "Nawabshah",
"92557", "Gujranwala",
"925437", "Chakwal",
"929447", "Upper\ Dir",
"92926", "Kurram\ Agency",
"929323", "Malakand",
"92425", "Lahore",
"92216", "Karachi",
"92472", "Jhang",
"92923", "Nowshera",
"926047", "Rajanpur",
"928293", "Barkhan\/Kohlu",
"92213", "Karachi",
"928325", "Bolan",
"92628", "Bahawalpur",
"928486", "Khuzdar",
"929966", "Shangla",
"928255", "Chagai",
"925466", "Mandi\ Bahauddin",
"924572", "Pakpattan",
"928249", "Loralai",
"929654", "South\ Waziristan",
"928472", "Kharan",
"922448", "Nawabshah",
"925436", "Chakwal",
"928388", "Jaffarabad\/Nasirabad",
"927233", "Ghotki",
"925475", "Hafizabad",
"929975", "Mansehra\/Batagram",
"929446", "Upper\ Dir",
"92219", "Karachi",
"928233", "Killa\ Saifullah",
"928242", "Loralai",
"927263", "Shikarpur",
"92407", "Sahiwal",
"924579", "Pakpattan",
"926046", "Rajanpur",
"928479", "Kharan",
"928263", "K\.Abdullah\/Pishin",
"926067", "Layyah",
"929398", "Buner",
"928292", "Barkhan\/Kohlu",
"92632", "Bahawalnagar",
"929437", "Chitral",
"92924", "Khyber\/Mohmand\ Agy",
"928557", "Panjgur",
"928228", "Zhob",
"92214", "Karachi",
"92428", "Lahore",
"929322", "Malakand",
"922429", "Naushero\ Feroze",
"927228", "Jacobabad",
"929467", "Swat",
"922434", "Khairpur",
"92523", "Sialkot",
"922337", "Mirpur\ Khas",
"928299", "Barkhan\/Kohlu",
"928354", "Dera\ Bugti",
"92526", "Sialkot",
"925447", "Jhelum",
"929329", "Malakand",
"922422", "Naushero\ Feroze",
"928224", "Zhob",
"929436", "Chitral",
"928243", "Loralai",
"927262", "Shikarpur",
"928262", "K\.Abdullah\/Pishin",
"926066", "Layyah",
"927224", "Jacobabad",
"929466", "Swat",
"929394", "Buner",
"927232", "Ghotki",
"928232", "Killa\ Saifullah",
"928556", "Panjgur",
"924573", "Pakpattan",
"927269", "Shikarpur",
"92672", "Vehari",
"928358", "Dera\ Bugti",
"922336", "Mirpur\ Khas",
"928269", "K\.Abdullah\/Pishin",
"928473", "Kharan",
"922438", "Khairpur",
"927239", "Ghotki",
"928285", "Musakhel",
"92529", "Sialkot",
"925446", "Jhelum",
"92625", "Bahawalpur",
"928239", "Killa\ Saifullah",
"92498", "Kasur",
"92745", "Larkana",
"928287", "Musakhel",
"929374", "Mardan",
"92445", "Okara",
"92527", "Sialkot",
"92554", "Gujranwala",
"92688", "Rahim\ Yar\ Khan",
"924593", "Mianwali",
"926082", "Lodhran",
"928286", "Musakhel",
"92485", "Sargodha",
"925445", "Jhelum",
"928533", "Lasbela",
"92648", "Dera\ Ghazi\ Khan",
"929453", "Lower\ Dir",
"922335", "Mirpur\ Khas",
"924549", "Khushab",
"92404", "Sahiwal",
"92812", "Quetta",
"929378", "Mardan",
"928563", "Awaran",
"929959", "Haripur",
"92712", "Sukkur",
"928449", "Kalat",
"922389", "Umerkot",
"929465", "Swat",
"928433", "Mastung",
"92658", "Khanewal",
"926089", "Lodhran",
"928555", "Panjgur",
"924533", "Bhakkar",
"924542", "Khushab",
"929435", "Chitral",
"92412", "Faisalabad",
"922353", "Sanghar",
"922382", "Umerkot",
"928442", "Kalat",
"929952", "Haripur",
"926065", "Layyah",
"927227", "Jacobabad",
"929468", "Swat",
"92492", "Kasur",
"928227", "Zhob",
"928558", "Panjgur",
"929438", "Chitral",
"92519", "Islamabad\/Rawalpindi",
"92615", "Multan",
"926068", "Layyah",
"929397", "Buner",
"925448", "Jhelum",
"922436", "Khairpur",
"92682", "Rahim\ Yar\ Khan",
"928373", "Jhal\ Magsi",
"928356", "Dera\ Bugti",
"922338", "Mirpur\ Khas",
"929375", "Mardan",
"928226", "Zhob",
"929434", "Chitral",
"92513", "Islamabad\/Rawalpindi",
"92642", "Dera\ Ghazi\ Khan",
"926064", "Layyah",
"927226", "Jacobabad",
"929464", "Swat",
"929396", "Buner",
"92818", "Quetta",
"92516", "Islamabad\/Rawalpindi",
"929422", "Bajaur\ Agency",
"922329", "Tharparkar",
"928554", "Panjgur",
"92718", "Sukkur",
"92652", "Khanewal",
"922334", "Mirpur\ Khas",
"922437", "Khairpur",
"92667", "Muzaffargarh",
"92914", "Peshawar\/Charsadda",
"925423", "Narowal",
"92418", "Faisalabad",
"92224", "Hyderabad",
"929923", "Abottabad",
"92257", "Dadu",
"925444", "Jhelum",
"929429", "Bajaur\ Agency",
"922322", "Tharparkar",
"928357", "Dera\ Bugti",
"928355", "Dera\ Bugti",
"929699", "Lakki\ Marwat",
"92475", "Jhang",
"929376", "Mardan",
"92638", "Bahawalnagar",
"92422", "Lahore",
"928288", "Musakhel",
"922435", "Khairpur",
"922983", "Thatta",
"929382", "Swabi",
"92464", "Toba\ Tek\ Singh",
"928333", "Sibi\/Ziarat",
"929692", "Lakki\ Marwat",
"92259", "Dadu",
"92574", "Attock",
"92669", "Muzaffargarh",
"929389", "Swabi",
"92864", "Gwadar",
"92565", "Sheikhupura",
"92534", "Gujrat",
"929377", "Mardan",
"928284", "Musakhel",
"929669", "D\.I\.\ Khan",
"92517", "Islamabad\/Rawalpindi",
"9258", "AJK\/FATA",
"929639", "Tank",
"929662", "D\.I\.\ Khan",
"929395", "Buner",
"92678", "Vehari",
"929223", "Kohat",
"92663", "Muzaffargarh",
"92256", "Dadu",
"929632", "Tank",
"928225", "Zhob",
"92666", "Muzaffargarh",
"92253", "Dadu",
"927225", "Jacobabad",};
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