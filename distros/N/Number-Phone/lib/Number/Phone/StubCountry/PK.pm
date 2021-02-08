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
our $VERSION = 1.20210204173827;

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
$areanames{en} = {"928526", "Kech",
"928373", "Jhal\ Magsi",
"928237", "Killa\ Saifullah",
"922352", "Sanghar",
"928332", "Sibi\/Ziarat",
"928234", "Killa\ Saifullah",
"928525", "Kech",
"925422", "Narowal",
"926062", "Layyah",
"922443", "Nawabshah",
"92445", "Okara",
"929325", "Malakand",
"925478", "Hafizabad",
"928444", "Kalat",
"928339", "Sibi\/Ziarat",
"92634", "Bahawalnagar",
"92814", "Quetta",
"922359", "Sanghar",
"929326", "Malakand",
"92553", "Gujranwala",
"928447", "Kalat",
"92568", "Sheikhupura",
"92466", "Toba\ Tek\ Singh",
"92404", "Sahiwal",
"928253", "Chagai",
"925429", "Narowal",
"92863", "Gwadar",
"926069", "Layyah",
"92557", "Gujranwala",
"928488", "Khuzdar",
"925438", "Chakwal",
"92919", "Peshawar\/Charsadda",
"928379", "Jhal\ Magsi",
"92645", "Dera\ Ghazi\ Khan",
"928354", "Dera\ Bugti",
"92867", "Gwadar",
"928328", "Bolan",
"928252", "Chagai",
"922337", "Mirpur\ Khas",
"928357", "Dera\ Bugti",
"922449", "Nawabshah",
"922334", "Mirpur\ Khas",
"929958", "Haripur",
"929924", "Abottabad",
"922353", "Sanghar",
"92659", "Khanewal",
"928372", "Jhal\ Magsi",
"928333", "Sibi\/Ziarat",
"92715", "Sukkur",
"929927", "Abottabad",
"9258", "AJK\/FATA",
"922442", "Nawabshah",
"926063", "Layyah",
"922975", "Badin",
"925423", "Narowal",
"928265", "K\.Abdullah\/Pishin",
"928259", "Chagai",
"922976", "Badin",
"92666", "Muzaffargarh",
"928266", "K\.Abdullah\/Pishin",
"92574", "Attock",
"929434", "Chitral",
"92913", "Peshawar\/Charsadda",
"929437", "Chitral",
"925446", "Jhelum",
"927225", "Jacobabad",
"929663", "D\.I\.\ Khan",
"925445", "Jhelum",
"927226", "Jacobabad",
"92534", "Gujrat",
"922987", "Thatta",
"92653", "Khanewal",
"922984", "Thatta",
"92668", "Muzaffargarh",
"92474", "Jhang",
"928286", "Musakhel",
"926083", "Lodhran",
"929453", "Lower\ Dir",
"928285", "Musakhel",
"928294", "Barkhan\/Kohlu",
"92657", "Khanewal",
"928297", "Barkhan\/Kohlu",
"929655", "South\ Waziristan",
"926082", "Lodhran",
"929669", "D\.I\.\ Khan",
"929656", "South\ Waziristan",
"929452", "Lower\ Dir",
"922386", "Umerkot",
"92559", "Gujranwala",
"92917", "Peshawar\/Charsadda",
"922385", "Umerkot",
"922426", "Naushero\ Feroze",
"929459", "Lower\ Dir",
"92869", "Gwadar",
"929662", "D\.I\.\ Khan",
"926089", "Lodhran",
"929466", "Swat",
"922425", "Naushero\ Feroze",
"92566", "Sheikhupura",
"92468", "Toba\ Tek\ Singh",
"92674", "Vehari",
"929465", "Swat",
"927224", "Jacobabad",
"925447", "Jhelum",
"924543", "Khushab",
"928389", "Jaffarabad\/Nasirabad",
"927227", "Jacobabad",
"92514", "Islamabad\/Rawalpindi",
"92255", "Dadu",
"92558", "Gujranwala",
"925444", "Jhelum",
"928478", "Kharan",
"92563", "Sheikhupura",
"92469", "Toba\ Tek\ Singh",
"929435", "Chitral",
"929436", "Chitral",
"929632", "Tank",
"92868", "Gwadar",
"92682", "Rahim\ Yar\ Khan",
"928287", "Musakhel",
"928382", "Jaffarabad\/Nasirabad",
"928284", "Musakhel",
"929639", "Tank",
"922986", "Thatta",
"92622", "Bahawalpur",
"922985", "Thatta",
"92656", "Khanewal",
"929654", "South\ Waziristan",
"928383", "Jaffarabad\/Nasirabad",
"924549", "Khushab",
"928248", "Loralai",
"929657", "South\ Waziristan",
"928295", "Barkhan\/Kohlu",
"928296", "Barkhan\/Kohlu",
"92669", "Muzaffargarh",
"924542", "Khushab",
"922427", "Naushero\ Feroze",
"929467", "Swat",
"928438", "Mastung",
"92212", "Karachi",
"922424", "Naushero\ Feroze",
"92482", "Sargodha",
"929464", "Swat",
"92916", "Peshawar\/Charsadda",
"92422", "Lahore",
"92925", "Hangu\/Orakzai\ Agy",
"922387", "Umerkot",
"92567", "Sheikhupura",
"929633", "Tank",
"922384", "Umerkot",
"92658", "Khanewal",
"92614", "Multan",
"92663", "Muzaffargarh",
"928527", "Kech",
"928236", "Killa\ Saifullah",
"929229", "Kohat",
"928235", "Killa\ Saifullah",
"928558", "Panjgur",
"928524", "Kech",
"925468", "Mandi\ Bahauddin",
"92918", "Peshawar\/Charsadda",
"929693", "Lakki\ Marwat",
"929324", "Malakand",
"92744", "Larkana",
"929222", "Kohat",
"928445", "Kalat",
"92467", "Toba\ Tek\ Singh",
"92522", "Sialkot",
"929327", "Malakand",
"92494", "Kasur",
"928446", "Kalat",
"928355", "Dera\ Bugti",
"92556", "Gujranwala",
"92414", "Faisalabad",
"922336", "Mirpur\ Khas",
"929448", "Upper\ Dir",
"928356", "Dera\ Bugti",
"922335", "Mirpur\ Khas",
"929692", "Lakki\ Marwat",
"929223", "Kohat",
"92866", "Gwadar",
"92998", "Kohistan",
"92224", "Hyderabad",
"92463", "Toba\ Tek\ Singh",
"92569", "Sheikhupura",
"922974", "Badin",
"928264", "K\.Abdullah\/Pishin",
"922977", "Badin",
"928267", "K\.Abdullah\/Pishin",
"929925", "Abottabad",
"929926", "Abottabad",
"92667", "Muzaffargarh",
"929699", "Lakki\ Marwat",
"92718", "Sukkur",
"929637", "Tank",
"922383", "Umerkot",
"929634", "Tank",
"927222", "Jacobabad",
"928289", "Musakhel",
"922423", "Naushero\ Feroze",
"925442", "Jhelum",
"929463", "Swat",
"922438", "Khairpur",
"92257", "Dadu",
"92632", "Bahawalnagar",
"92812", "Quetta",
"928387", "Jaffarabad\/Nasirabad",
"929653", "South\ Waziristan",
"929398", "Buner",
"925449", "Jhelum",
"92402", "Sahiwal",
"92648", "Dera\ Ghazi\ Khan",
"928384", "Jaffarabad\/Nasirabad",
"928282", "Musakhel",
"92923", "Nowshera",
"927229", "Jacobabad",
"92253", "Dadu",
"922389", "Umerkot",
"927238", "Ghotki",
"929469", "Swat",
"92927", "Karak",
"926086", "Lodhran",
"929456", "Lower\ Dir",
"922429", "Naushero\ Feroze",
"929652", "South\ Waziristan",
"92565", "Sheikhupura",
"926085", "Lodhran",
"929455", "Lower\ Dir",
"928283", "Musakhel",
"922382", "Umerkot",
"92448", "Okara",
"924544", "Khushab",
"927223", "Jacobabad",
"929665", "D\.I\.\ Khan",
"92572", "Attock",
"924547", "Khushab",
"925443", "Jhelum",
"922422", "Naushero\ Feroze",
"929659", "South\ Waziristan",
"929462", "Swat",
"929666", "D\.I\.\ Khan",
"928336", "Sibi\/Ziarat",
"922355", "Sanghar",
"928335", "Sibi\/Ziarat",
"92259", "Dadu",
"929329", "Malakand",
"922356", "Sanghar",
"928522", "Kech",
"926065", "Layyah",
"925425", "Narowal",
"922973", "Badin",
"92465", "Toba\ Tek\ Singh",
"929378", "Mardan",
"928263", "K\.Abdullah\/Pishin",
"926066", "Layyah",
"925426", "Narowal",
"929322", "Malakand",
"928529", "Kech",
"929224", "Kohat",
"929227", "Kohat",
"92532", "Gujrat",
"92446", "Okara",
"92472", "Jhang",
"929323", "Malakand",
"929968", "Shangla",
"929694", "Lakki\ Marwat",
"92716", "Sukkur",
"929697", "Lakki\ Marwat",
"928255", "Chagai",
"928538", "Lasbela",
"928269", "K\.Abdullah\/Pishin",
"92665", "Muzaffargarh",
"922979", "Badin",
"928256", "Chagai",
"928375", "Jhal\ Magsi",
"928376", "Jhal\ Magsi",
"928523", "Kech",
"92646", "Dera\ Ghazi\ Khan",
"922972", "Badin",
"922445", "Nawabshah",
"928262", "K\.Abdullah\/Pishin",
"92672", "Vehari",
"922446", "Nawabshah",
"925424", "Narowal",
"92512", "Islamabad\/Rawalpindi",
"926064", "Layyah",
"925427", "Narowal",
"926067", "Layyah",
"929923", "Abottabad",
"928337", "Sibi\/Ziarat",
"922328", "Tharparkar",
"922354", "Sanghar",
"92643", "Dera\ Ghazi\ Khan",
"928449", "Kalat",
"928334", "Sibi\/Ziarat",
"92928", "Bannu\/N\.\ Waziristan",
"928232", "Killa\ Saifullah",
"922357", "Sanghar",
"928353", "Dera\ Bugti",
"92713", "Sukkur",
"92684", "Rahim\ Yar\ Khan",
"922333", "Mirpur\ Khas",
"928239", "Killa\ Saifullah",
"92624", "Bahawalpur",
"924538", "Bhakkar",
"929225", "Kohat",
"928442", "Kalat",
"929226", "Kohat",
"92447", "Okara",
"928568", "Awaran",
"928352", "Dera\ Bugti",
"928254", "Chagai",
"928228", "Zhob",
"929978", "Mansehra\/Batagram",
"928257", "Chagai",
"92717", "Sukkur",
"922332", "Mirpur\ Khas",
"929695", "Lakki\ Marwat",
"92443", "Okara",
"928443", "Kalat",
"929696", "Lakki\ Marwat",
"929929", "Abottabad",
"924578", "Pakpattan",
"92258", "Dadu",
"922444", "Nawabshah",
"92484", "Sargodha",
"92555", "Gujranwala",
"92214", "Karachi",
"922339", "Mirpur\ Khas",
"922447", "Nawabshah",
"928359", "Dera\ Bugti",
"929922", "Abottabad",
"92647", "Dera\ Ghazi\ Khan",
"928374", "Jhal\ Magsi",
"92865", "Gwadar",
"92424", "Lahore",
"928377", "Jhal\ Magsi",
"928233", "Killa\ Saifullah",
"92612", "Multan",
"922989", "Thatta",
"929636", "Tank",
"929432", "Chitral",
"929635", "Tank",
"92449", "Okara",
"928386", "Jaffarabad\/Nasirabad",
"927268", "Shikarpur",
"926048", "Rajanpur",
"928385", "Jaffarabad\/Nasirabad",
"92256", "Dadu",
"928293", "Barkhan\/Kohlu",
"92524", "Sialkot",
"92492", "Kasur",
"929439", "Chitral",
"92742", "Larkana",
"922982", "Thatta",
"926087", "Lodhran",
"929457", "Lower\ Dir",
"92412", "Faisalabad",
"926084", "Lodhran",
"929428", "Bajaur\ Agency",
"929454", "Lower\ Dir",
"92915", "Peshawar\/Charsadda",
"928292", "Barkhan\/Kohlu",
"92222", "Hyderabad",
"92649", "Dera\ Ghazi\ Khan",
"92926", "Kurram\ Agency",
"929388", "Swabi",
"922983", "Thatta",
"92655", "Khanewal",
"924545", "Khushab",
"929664", "D\.I\.\ Khan",
"924546", "Khushab",
"92719", "Sukkur",
"929667", "D\.I\.\ Khan",
"929433", "Chitral",
"928299", "Barkhan\/Kohlu",
"924598", "Mianwali",
"929449", "Upper\ Dir",
"92523", "Sialkot",
"92429", "Lahore",
"92675", "Vehari",
"92489", "Sargodha",
"92219", "Karachi",
"928553", "Panjgur",
"92662", "Muzaffargarh",
"928226", "Zhob",
"928537", "Lasbela",
"929976", "Mansehra\/Batagram",
"925463", "Mandi\ Bahauddin",
"928225", "Zhob",
"929442", "Upper\ Dir",
"928534", "Lasbela",
"929975", "Mansehra\/Batagram",
"929967", "Shangla",
"924575", "Pakpattan",
"929964", "Shangla",
"929698", "Lakki\ Marwat",
"924576", "Pakpattan",
"92629", "Bahawalpur",
"92475", "Jhang",
"925462", "Mandi\ Bahauddin",
"929443", "Upper\ Dir",
"924536", "Bhakkar",
"92535", "Gujrat",
"928565", "Awaran",
"928559", "Panjgur",
"924535", "Bhakkar",
"929228", "Kohat",
"92689", "Rahim\ Yar\ Khan",
"928566", "Awaran",
"92527", "Sialkot",
"925469", "Mandi\ Bahauddin",
"929377", "Mardan",
"92462", "Toba\ Tek\ Singh",
"929374", "Mardan",
"928552", "Panjgur",
"922326", "Tharparkar",
"922325", "Tharparkar",
"928473", "Kharan",
"928249", "Loralai",
"92623", "Bahawalpur",
"924548", "Khushab",
"928432", "Mastung",
"92575", "Attock",
"92683", "Rahim\ Yar\ Khan",
"924595", "Mianwali",
"92714", "Sukkur",
"924596", "Mianwali",
"928439", "Mastung",
"92644", "Dera\ Ghazi\ Khan",
"92562", "Sheikhupura",
"928242", "Loralai",
"929425", "Bajaur\ Agency",
"92427", "Lahore",
"929426", "Bajaur\ Agency",
"929385", "Swabi",
"927234", "Ghotki",
"92487", "Sargodha",
"92217", "Karachi",
"929386", "Swabi",
"927237", "Ghotki",
"92423", "Lahore",
"927266", "Shikarpur",
"926045", "Rajanpur",
"928388", "Jaffarabad\/Nasirabad",
"92405", "Sahiwal",
"929397", "Buner",
"92529", "Sialkot",
"928243", "Loralai",
"927265", "Shikarpur",
"926046", "Rajanpur",
"928479", "Kharan",
"929394", "Buner",
"922437", "Khairpur",
"92815", "Quetta",
"92635", "Bahawalnagar",
"922434", "Khairpur",
"92483", "Sargodha",
"92213", "Karachi",
"928472", "Kharan",
"92627", "Bahawalpur",
"92444", "Okara",
"928433", "Mastung",
"929638", "Tank",
"92687", "Rahim\ Yar\ Khan",
"924594", "Mianwali",
"924597", "Mianwali",
"92652", "Khanewal",
"929668", "D\.I\.\ Khan",
"927235", "Ghotki",
"929384", "Swabi",
"92225", "Hyderabad",
"92426", "Lahore",
"927236", "Ghotki",
"929387", "Swabi",
"92528", "Sialkot",
"92486", "Sargodha",
"926088", "Lodhran",
"92415", "Faisalabad",
"92216", "Karachi",
"92912", "Peshawar\/Charsadda",
"929424", "Bajaur\ Agency",
"929458", "Lower\ Dir",
"929427", "Bajaur\ Agency",
"92745", "Larkana",
"922436", "Khairpur",
"922435", "Khairpur",
"92495", "Kasur",
"926044", "Rajanpur",
"927267", "Shikarpur",
"929396", "Buner",
"926047", "Rajanpur",
"927264", "Shikarpur",
"929395", "Buner",
"92626", "Bahawalpur",
"92686", "Rahim\ Yar\ Khan",
"92615", "Multan",
"928489", "Khuzdar",
"92924", "Khyber\/Mohmand\ Agy",
"929952", "Haripur",
"92862", "Gwadar",
"928378", "Jhal\ Magsi",
"925439", "Chakwal",
"928329", "Bolan",
"92552", "Gujranwala",
"922448", "Nawabshah",
"929966", "Shangla",
"925432", "Chakwal",
"929959", "Haripur",
"924574", "Pakpattan",
"92628", "Bahawalpur",
"929965", "Shangla",
"924577", "Pakpattan",
"928482", "Khuzdar",
"925473", "Hafizabad",
"92688", "Rahim\ Yar\ Khan",
"929977", "Mansehra\/Batagram",
"928536", "Lasbela",
"928227", "Zhob",
"928322", "Bolan",
"929974", "Mansehra\/Batagram",
"928258", "Chagai",
"928224", "Zhob",
"928535", "Lasbela",
"925433", "Chakwal",
"924537", "Bhakkar",
"928564", "Awaran",
"924534", "Bhakkar",
"928567", "Awaran",
"925472", "Hafizabad",
"928483", "Khuzdar",
"928323", "Bolan",
"92428", "Lahore",
"928338", "Sibi\/Ziarat",
"925479", "Hafizabad",
"92526", "Sialkot",
"922327", "Tharparkar",
"929953", "Haripur",
"922358", "Sanghar",
"922324", "Tharparkar",
"929376", "Mardan",
"92515", "Islamabad\/Rawalpindi",
"92254", "Dadu",
"926068", "Layyah",
"92488", "Sargodha",
"925428", "Narowal",
"92218", "Karachi",
"929375", "Mardan",
"92493", "Kasur",
"928436", "Mastung",
"929429", "Bajaur\ Agency",
"92743", "Larkana",
"92227", "Hyderabad",
"928435", "Mastung",
"924592", "Mianwali",
"92417", "Faisalabad",
"929389", "Swabi",
"926043", "Rajanpur",
"928245", "Loralai",
"929422", "Bajaur\ Agency",
"927263", "Shikarpur",
"92664", "Muzaffargarh",
"92478", "Jhang",
"928246", "Loralai",
"92576", "Attock",
"92613", "Multan",
"929382", "Swabi",
"924599", "Mianwali",
"928298", "Barkhan\/Kohlu",
"92538", "Gujrat",
"926042", "Rajanpur",
"929423", "Bajaur\ Agency",
"927262", "Shikarpur",
"929383", "Swabi",
"922988", "Thatta",
"92617", "Multan",
"92223", "Hyderabad",
"928475", "Kharan",
"92406", "Sahiwal",
"92464", "Toba\ Tek\ Singh",
"92678", "Vehari",
"92747", "Larkana",
"927269", "Shikarpur",
"92497", "Kasur",
"928476", "Kharan",
"926049", "Rajanpur",
"92636", "Bahawalnagar",
"924593", "Mianwali",
"92816", "Quetta",
"92413", "Faisalabad",
"92519", "Islamabad\/Rawalpindi",
"929438", "Chitral",
"929979", "Mansehra\/Batagram",
"928229", "Zhob",
"929957", "Haripur",
"92712", "Sukkur",
"929954", "Haripur",
"929928", "Abottabad",
"924579", "Pakpattan",
"922323", "Tharparkar",
"928327", "Bolan",
"922338", "Mirpur\ Khas",
"929446", "Upper\ Dir",
"92564", "Sheikhupura",
"928358", "Dera\ Bugti",
"928324", "Bolan",
"92408", "Sahiwal",
"92642", "Dera\ Ghazi\ Khan",
"929972", "Mansehra\/Batagram",
"92676", "Vehari",
"92229", "Hyderabad",
"928222", "Zhob",
"929445", "Upper\ Dir",
"92513", "Islamabad\/Rawalpindi",
"925434", "Chakwal",
"928487", "Khuzdar",
"924572", "Pakpattan",
"92419", "Faisalabad",
"928563", "Awaran",
"924533", "Bhakkar",
"925437", "Chakwal",
"928484", "Khuzdar",
"92818", "Quetta",
"92638", "Bahawalnagar",
"925466", "Mandi\ Bahauddin",
"92749", "Larkana",
"92499", "Kasur",
"925465", "Mandi\ Bahauddin",
"928223", "Zhob",
"929973", "Mansehra\/Batagram",
"922329", "Tharparkar",
"928562", "Awaran",
"924573", "Pakpattan",
"925477", "Hafizabad",
"924532", "Bhakkar",
"92517", "Islamabad\/Rawalpindi",
"925474", "Hafizabad",
"928448", "Kalat",
"92442", "Okara",
"92476", "Jhang",
"92578", "Attock",
"92536", "Gujrat",
"924539", "Bhakkar",
"928238", "Killa\ Saifullah",
"928555", "Panjgur",
"928569", "Awaran",
"922322", "Tharparkar",
"928556", "Panjgur",
"92619", "Multan",
"929956", "Haripur",
"929969", "Shangla",
"92579", "Attock",
"929955", "Haripur",
"92473", "Jhang",
"928539", "Lasbela",
"92654", "Khanewal",
"92618", "Multan",
"922978", "Badin",
"92533", "Gujrat",
"929373", "Mardan",
"928268", "K\.Abdullah\/Pishin",
"925435", "Chakwal",
"92498", "Kasur",
"928486", "Khuzdar",
"925436", "Chakwal",
"929962", "Shangla",
"92677", "Vehari",
"92748", "Larkana",
"928485", "Khuzdar",
"928326", "Bolan",
"929447", "Upper\ Dir",
"928325", "Bolan",
"929444", "Upper\ Dir",
"928532", "Lasbela",
"92914", "Peshawar\/Charsadda",
"92228", "Hyderabad",
"92525", "Sialkot",
"92673", "Vehari",
"925476", "Hafizabad",
"92409", "Sahiwal",
"929963", "Shangla",
"929328", "Malakand",
"925475", "Hafizabad",
"925467", "Mandi\ Bahauddin",
"92639", "Bahawalnagar",
"92819", "Quetta",
"929379", "Mardan",
"92516", "Islamabad\/Rawalpindi",
"925464", "Mandi\ Bahauddin",
"92418", "Faisalabad",
"928533", "Lasbela",
"92477", "Jhang",
"928554", "Panjgur",
"928528", "Kech",
"928557", "Panjgur",
"92537", "Gujrat",
"929372", "Mardan",
"922388", "Umerkot",
"92864", "Gwadar",
"92425", "Lahore",
"92226", "Hyderabad",
"92679", "Vehari",
"92403", "Sahiwal",
"927239", "Ghotki",
"922428", "Naushero\ Feroze",
"92518", "Islamabad\/Rawalpindi",
"92485", "Sargodha",
"92554", "Gujranwala",
"92215", "Karachi",
"92416", "Faisalabad",
"928437", "Mastung",
"929468", "Swat",
"928434", "Mastung",
"92633", "Bahawalnagar",
"92813", "Quetta",
"927232", "Ghotki",
"92577", "Attock",
"922433", "Khairpur",
"928244", "Loralai",
"928247", "Loralai",
"929393", "Buner",
"929658", "South\ Waziristan",
"92625", "Bahawalpur",
"92479", "Jhang",
"927233", "Ghotki",
"92573", "Attock",
"922432", "Khairpur",
"92539", "Gujrat",
"928288", "Musakhel",
"92685", "Rahim\ Yar\ Khan",
"92616", "Multan",
"929392", "Buner",
"92746", "Larkana",
"922439", "Khairpur",
"92407", "Sahiwal",
"92496", "Kasur",
"925448", "Jhelum",
"928474", "Kharan",
"92252", "Dadu",
"92817", "Quetta",
"92637", "Bahawalnagar",
"929399", "Buner",
"928477", "Kharan",
"927228", "Jacobabad",};

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