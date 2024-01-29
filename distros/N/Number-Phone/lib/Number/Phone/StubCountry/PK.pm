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
our $VERSION = 1.20231210185946;

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
$areanames{en} = {"92472", "Jhang",
"922333", "Mirpur\ Khas",
"928323", "Bolan",
"926067", "Layyah",
"929385", "Swabi",
"925479", "Hafizabad",
"922385", "Umerkot",
"92256", "Dadu",
"928338", "Sibi\/Ziarat",
"92258", "Dadu",
"929392", "Buner",
"922357", "Sanghar",
"92487", "Sargodha",
"922328", "Tharparkar",
"92533", "Gujrat",
"929328", "Malakand",
"926087", "Lodhran",
"922354", "Sanghar",
"92558", "Gujranwala",
"929669", "D\.I\.\ Khan",
"92618", "Multan",
"92534", "Gujrat",
"924578", "Pakpattan",
"922989", "Thatta",
"926084", "Lodhran",
"926064", "Layyah",
"92719", "Sukkur",
"928525", "Kech",
"92616", "Multan",
"928568", "Awaran",
"928472", "Kharan",
"92556", "Gujranwala",
"929969", "Shangla",
"92639", "Bahawalnagar",
"928356", "Dera\ Bugti",
"92632", "Bahawalnagar",
"922983", "Thatta",
"92417", "Faisalabad",
"92818", "Quetta",
"929663", "D\.I\.\ Khan",
"925466", "Mandi\ Bahauddin",
"928267", "K\.Abdullah\/Pishin",
"928487", "Khuzdar",
"92712", "Sukkur",
"928255", "Chagai",
"928478", "Kharan",
"928562", "Awaran",
"92568", "Sheikhupura",
"924572", "Pakpattan",
"92566", "Sheikhupura",
"928287", "Musakhel",
"929963", "Shangla",
"92527", "Sialkot",
"92816", "Quetta",
"927227", "Jacobabad",
"929635", "Tank",
"922322", "Tharparkar",
"92675", "Vehari",
"928332", "Sibi\/Ziarat",
"92227", "Hyderabad",
"929398", "Buner",
"928284", "Musakhel",
"922339", "Mirpur\ Khas",
"92927", "Karak",
"92686", "Rahim\ Yar\ Khan",
"925473", "Hafizabad",
"927224", "Jacobabad",
"929322", "Malakand",
"928329", "Bolan",
"92998", "Kohistan",
"929976", "Mansehra\/Batagram",
"92688", "Rahim\ Yar\ Khan",
"927236", "Ghotki",
"929466", "Swat",
"928484", "Khuzdar",
"928264", "K\.Abdullah\/Pishin",
"92479", "Jhang",
"922976", "Badin",
"929664", "D\.I\.\ Khan",
"9258", "AJK\/FATA",
"922359", "Sanghar",
"926089", "Lodhran",
"922984", "Thatta",
"925425", "Narowal",
"92498", "Kasur",
"928352", "Dera\ Bugti",
"925468", "Mandi\ Bahauddin",
"92466", "Toba\ Tek\ Singh",
"92427", "Lahore",
"928476", "Kharan",
"928445", "Kalat",
"92673", "Vehari",
"928245", "Loralai",
"92447", "Okara",
"925477", "Hafizabad",
"92468", "Toba\ Tek\ Singh",
"92867", "Gwadar",
"92496", "Kasur",
"926069", "Layyah",
"929964", "Shangla",
"92742", "Larkana",
"92657", "Khanewal",
"92517", "Islamabad\/Rawalpindi",
"928235", "Killa\ Saifullah",
"925474", "Hafizabad",
"927223", "Jacobabad",
"92917", "Peshawar\/Charsadda",
"929396", "Buner",
"92579", "Attock",
"92407", "Sahiwal",
"929225", "Kohat",
"928283", "Musakhel",
"929967", "Shangla",
"929955", "Haripur",
"92217", "Karachi",
"929667", "D\.I\.\ Khan",
"929655", "South\ Waziristan",
"929978", "Mansehra\/Batagram",
"928483", "Khuzdar",
"928263", "K\.Abdullah\/Pishin",
"929425", "Bajaur\ Agency",
"927238", "Ghotki",
"929468", "Swat",
"922425", "Naushero\ Feroze",
"922987", "Thatta",
"922978", "Badin",
"928435", "Mastung",
"92674", "Vehari",
"928289", "Musakhel",
"929462", "Swat",
"927232", "Ghotki",
"929972", "Mansehra\/Batagram",
"928324", "Bolan",
"927229", "Jacobabad",
"922972", "Badin",
"922334", "Mirpur\ Khas",
"928336", "Sibi\/Ziarat",
"924535", "Bhakkar",
"922326", "Tharparkar",
"929326", "Malakand",
"926045", "Rajanpur",
"92572", "Attock",
"928269", "K\.Abdullah\/Pishin",
"928489", "Khuzdar",
"928375", "Jhal\ Magsi",
"926083", "Lodhran",
"924545", "Khushab",
"92749", "Larkana",
"924576", "Pakpattan",
"922353", "Sanghar",
"92646", "Dera\ Ghazi\ Khan",
"92628", "Bahawalpur",
"92626", "Bahawalpur",
"92648", "Dera\ Ghazi\ Khan",
"92667", "Muzaffargarh",
"922337", "Mirpur\ Khas",
"92535", "Gujrat",
"928566", "Awaran",
"928327", "Bolan",
"926063", "Layyah",
"925462", "Mandi\ Bahauddin",
"928358", "Dera\ Bugti",
"92678", "Vehari",
"92493", "Kasur",
"928254", "Chagai",
"92222", "Hyderabad",
"928443", "Kalat",
"929456", "Lower\ Dir",
"924549", "Khushab",
"92489", "Sargodha",
"929372", "Mardan",
"928379", "Jhal\ Magsi",
"925423", "Narowal",
"929926", "Abottabad",
"929448", "Upper\ Dir",
"92685", "Rahim\ Yar\ Khan",
"929634", "Tank",
"928243", "Loralai",
"92463", "Toba\ Tek\ Singh",
"925438", "Chakwal",
"922448", "Nawabshah",
"92676", "Vehari",
"92637", "Bahawalnagar",
"929637", "Tank",
"929438", "Chitral",
"927268", "Shikarpur",
"928233", "Killa\ Saifullah",
"92412", "Faisalabad",
"927225", "Jacobabad",
"92815", "Quetta",
"92464", "Toba\ Tek\ Singh",
"925448", "Jhelum",
"922438", "Khairpur",
"929953", "Haripur",
"929223", "Kohat",
"928285", "Musakhel",
"92565", "Sheikhupura",
"92717", "Sukkur",
"928228", "Zhob",
"928485", "Khuzdar",
"928552", "Panjgur",
"928265", "K\.Abdullah\/Pishin",
"929423", "Bajaur\ Agency",
"928257", "Chagai",
"926049", "Rajanpur",
"92494", "Kasur",
"92522", "Sialkot",
"929653", "South\ Waziristan",
"924539", "Bhakkar",
"924598", "Mianwali",
"928433", "Mastung",
"928292", "Barkhan\/Kohlu",
"922423", "Naushero\ Feroze",
"922384", "Umerkot",
"929959", "Haripur",
"92555", "Gujranwala",
"928558", "Panjgur",
"92615", "Multan",
"928222", "Zhob",
"929229", "Kohat",
"928527", "Kech",
"92529", "Sialkot",
"928298", "Barkhan\/Kohlu",
"928239", "Killa\ Saifullah",
"924592", "Mianwali",
"92644", "Dera\ Ghazi\ Khan",
"929384", "Swabi",
"92624", "Bahawalpur",
"928439", "Mastung",
"927262", "Shikarpur",
"924533", "Bhakkar",
"929432", "Chitral",
"922429", "Naushero\ Feroze",
"929429", "Bajaur\ Agency",
"92419", "Faisalabad",
"922432", "Khairpur",
"929659", "South\ Waziristan",
"925442", "Jhelum",
"928386", "Jaffarabad\/Nasirabad",
"926043", "Rajanpur",
"92623", "Bahawalpur",
"92477", "Jhang",
"929442", "Upper\ Dir",
"924543", "Khushab",
"928449", "Kalat",
"925429", "Narowal",
"926085", "Lodhran",
"928373", "Jhal\ Magsi",
"928536", "Lasbela",
"922355", "Sanghar",
"922442", "Nawabshah",
"925432", "Chakwal",
"929696", "Lakki\ Marwat",
"92255", "Dadu",
"928524", "Kech",
"922387", "Umerkot",
"92482", "Sargodha",
"926065", "Layyah",
"92229", "Hyderabad",
"929378", "Mardan",
"929387", "Swabi",
"928249", "Loralai",
"92643", "Dera\ Ghazi\ Khan",
"92519", "Islamabad\/Rawalpindi",
"928325", "Bolan",
"929383", "Swabi",
"928556", "Panjgur",
"92659", "Khanewal",
"92536", "Gujrat",
"922335", "Mirpur\ Khas",
"92869", "Gwadar",
"922383", "Umerkot",
"92449", "Okara",
"92625", "Bahawalpur",
"928296", "Barkhan\/Kohlu",
"92645", "Dera\ Ghazi\ Khan",
"926044", "Rajanpur",
"92429", "Lahore",
"92662", "Muzaffargarh",
"92614", "Multan",
"924547", "Khushab",
"92538", "Gujrat",
"92554", "Gujranwala",
"92253", "Dadu",
"928377", "Jhal\ Magsi",
"924534", "Bhakkar",
"928388", "Jaffarabad\/Nasirabad",
"928259", "Chagai",
"929922", "Abottabad",
"926047", "Rajanpur",
"92613", "Multan",
"928538", "Lasbela",
"928374", "Jhal\ Magsi",
"924537", "Bhakkar",
"92553", "Gujranwala",
"924544", "Khushab",
"92254", "Dadu",
"929639", "Tank",
"929698", "Lakki\ Marwat",
"92219", "Karachi",
"92577", "Attock",
"92409", "Sahiwal",
"929376", "Mardan",
"92919", "Peshawar\/Charsadda",
"929452", "Lower\ Dir",
"928523", "Kech",
"92912", "Peshawar\/Charsadda",
"928437", "Mastung",
"922985", "Thatta",
"925424", "Narowal",
"92563", "Sheikhupura",
"922427", "Naushero\ Feroze",
"928444", "Kalat",
"92402", "Sahiwal",
"929692", "Lakki\ Marwat",
"929458", "Lower\ Dir",
"92684", "Rahim\ Yar\ Khan",
"92813", "Quetta",
"928253", "Chagai",
"929427", "Bajaur\ Agency",
"929665", "D\.I\.\ Khan",
"929657", "South\ Waziristan",
"92212", "Karachi",
"929928", "Abottabad",
"929965", "Shangla",
"929957", "Haripur",
"929446", "Upper\ Dir",
"929227", "Kohat",
"928529", "Kech",
"925436", "Chakwal",
"929633", "Tank",
"928244", "Loralai",
"922446", "Nawabshah",
"928237", "Killa\ Saifullah",
"928532", "Lasbela",
"929224", "Kohat",
"929436", "Chitral",
"927266", "Shikarpur",
"929954", "Haripur",
"922389", "Umerkot",
"929389", "Swabi",
"928382", "Jaffarabad\/Nasirabad",
"92495", "Kasur",
"925446", "Jhelum",
"928234", "Killa\ Saifullah",
"922436", "Khairpur",
"925475", "Hafizabad",
"92669", "Muzaffargarh",
"92422", "Lahore",
"928247", "Loralai",
"928226", "Zhob",
"928447", "Kalat",
"922424", "Naushero\ Feroze",
"92442", "Okara",
"92564", "Sheikhupura",
"92862", "Gwadar",
"928434", "Mastung",
"92465", "Toba\ Tek\ Singh",
"925427", "Narowal",
"92683", "Rahim\ Yar\ Khan",
"924596", "Mianwali",
"92747", "Larkana",
"92652", "Khanewal",
"929654", "South\ Waziristan",
"92814", "Quetta",
"92512", "Islamabad\/Rawalpindi",
"929424", "Bajaur\ Agency",
"924538", "Bhakkar",
"928384", "Jaffarabad\/Nasirabad",
"924599", "Mianwali",
"92484", "Sargodha",
"928537", "Lasbela",
"928232", "Killa\ Saifullah",
"928229", "Zhob",
"929222", "Kohat",
"92576", "Attock",
"926048", "Rajanpur",
"929952", "Haripur",
"929386", "Swabi",
"925449", "Jhelum",
"929652", "South\ Waziristan",
"922439", "Khairpur",
"92578", "Attock",
"929422", "Bajaur\ Agency",
"928553", "Panjgur",
"922422", "Naushero\ Feroze",
"929697", "Lakki\ Marwat",
"928432", "Mastung",
"929439", "Chitral",
"927269", "Shikarpur",
"928293", "Barkhan\/Kohlu",
"922386", "Umerkot",
"92469", "Toba\ Tek\ Singh",
"925439", "Chakwal",
"922449", "Nawabshah",
"92622", "Bahawalpur",
"929373", "Mardan",
"928355", "Dera\ Bugti",
"925422", "Narowal",
"929449", "Upper\ Dir",
"928526", "Kech",
"928442", "Kalat",
"929694", "Lakki\ Marwat",
"92537", "Gujrat",
"924548", "Khushab",
"928242", "Loralai",
"92483", "Sargodha",
"928387", "Jaffarabad\/Nasirabad",
"928378", "Jhal\ Magsi",
"928534", "Lasbela",
"92642", "Dera\ Ghazi\ Khan",
"92499", "Kasur",
"92665", "Muzaffargarh",
"92524", "Sialkot",
"92492", "Kasur",
"92223", "Hyderabad",
"929379", "Mardan",
"928372", "Jhal\ Magsi",
"928248", "Loralai",
"92425", "Lahore",
"929443", "Upper\ Dir",
"92649", "Dera\ Ghazi\ Khan",
"924542", "Khushab",
"922443", "Nawabshah",
"929636", "Tank",
"925433", "Chakwal",
"92923", "Nowshera",
"92746", "Larkana",
"929924", "Abottabad",
"92655", "Khanewal",
"92748", "Larkana",
"92414", "Faisalabad",
"92515", "Islamabad\/Rawalpindi",
"929454", "Lower\ Dir",
"928256", "Chagai",
"92629", "Bahawalpur",
"92445", "Okara",
"928448", "Kalat",
"92865", "Gwadar",
"925428", "Narowal",
"92462", "Toba\ Tek\ Singh",
"925465", "Mandi\ Bahauddin",
"929428", "Bajaur\ Agency",
"929465", "Swat",
"927235", "Ghotki",
"929457", "Lower\ Dir",
"92413", "Faisalabad",
"928223", "Zhob",
"929658", "South\ Waziristan",
"92215", "Karachi",
"929975", "Mansehra\/Batagram",
"922975", "Badin",
"92915", "Peshawar\/Charsadda",
"928438", "Mastung",
"924593", "Mianwali",
"92405", "Sahiwal",
"922428", "Naushero\ Feroze",
"92523", "Sialkot",
"92224", "Hyderabad",
"928299", "Barkhan\/Kohlu",
"928238", "Killa\ Saifullah",
"927263", "Shikarpur",
"929433", "Chitral",
"924532", "Bhakkar",
"929958", "Haripur",
"922433", "Khairpur",
"925443", "Jhelum",
"926042", "Rajanpur",
"929927", "Abottabad",
"92924", "Khyber\/Mohmand\ Agy",
"928559", "Panjgur",
"929228", "Kohat",
"92864", "Gwadar",
"92403", "Sahiwal",
"922437", "Khairpur",
"925447", "Jhelum",
"929923", "Abottabad",
"922444", "Nawabshah",
"928246", "Loralai",
"92718", "Sukkur",
"92913", "Peshawar\/Charsadda",
"92444", "Okara",
"92562", "Sheikhupura",
"925434", "Chakwal",
"92514", "Islamabad\/Rawalpindi",
"929638", "Tank",
"929699", "Lakki\ Marwat",
"92213", "Karachi",
"92638", "Bahawalnagar",
"929444", "Upper\ Dir",
"92654", "Khanewal",
"929437", "Chitral",
"92415", "Faisalabad",
"927267", "Shikarpur",
"92812", "Quetta",
"92619", "Multan",
"928539", "Lasbela",
"924597", "Mianwali",
"92559", "Gujranwala",
"92636", "Bahawalnagar",
"928258", "Chagai",
"928475", "Kharan",
"928522", "Kech",
"92716", "Sukkur",
"92424", "Lahore",
"928227", "Zhob",
"929453", "Lower\ Dir",
"928446", "Kalat",
"925426", "Narowal",
"92525", "Sialkot",
"92925", "Hangu\/Orakzai\ Agy",
"929426", "Bajaur\ Agency",
"929656", "South\ Waziristan",
"92259", "Dadu",
"929382", "Swabi",
"928389", "Jaffarabad\/Nasirabad",
"924594", "Mianwali",
"92677", "Vehari",
"922382", "Umerkot",
"928436", "Mastung",
"92423", "Lahore",
"922426", "Naushero\ Feroze",
"928224", "Zhob",
"92225", "Hyderabad",
"92404", "Sahiwal",
"929395", "Buner",
"922447", "Nawabshah",
"92863", "Gwadar",
"925437", "Chakwal",
"92914", "Peshawar\/Charsadda",
"92443", "Okara",
"922434", "Khairpur",
"928236", "Killa\ Saifullah",
"925444", "Jhelum",
"92513", "Islamabad\/Rawalpindi",
"929956", "Haripur",
"927264", "Shikarpur",
"929434", "Chitral",
"92214", "Karachi",
"92653", "Khanewal",
"92682", "Rahim\ Yar\ Khan",
"929447", "Upper\ Dir",
"929226", "Kohat",
"924536", "Bhakkar",
"92689", "Rahim\ Yar\ Khan",
"922325", "Tharparkar",
"928335", "Sibi\/Ziarat",
"92478", "Jhang",
"928383", "Jaffarabad\/Nasirabad",
"926046", "Rajanpur",
"929325", "Malakand",
"929388", "Swabi",
"929377", "Mardan",
"928294", "Barkhan\/Kohlu",
"92663", "Muzaffargarh",
"92476", "Jhang",
"928554", "Panjgur",
"92252", "Dadu",
"92485", "Sargodha",
"922388", "Umerkot",
"929693", "Lakki\ Marwat",
"92664", "Muzaffargarh",
"929374", "Mardan",
"928297", "Barkhan\/Kohlu",
"929929", "Abottabad",
"92552", "Gujranwala",
"928528", "Kech",
"92612", "Multan",
"928565", "Awaran",
"928252", "Chagai",
"928557", "Panjgur",
"929459", "Lower\ Dir",
"924546", "Khushab",
"92819", "Quetta",
"924575", "Pakpattan",
"928376", "Jhal\ Magsi",
"928533", "Lasbela",
"92569", "Sheikhupura",
"929632", "Tank",
"928569", "Awaran",
"929925", "Abottabad",
"929968", "Shangla",
"92218", "Karachi",
"92633", "Bahawalnagar",
"92918", "Peshawar\/Charsadda",
"92713", "Sukkur",
"92408", "Sahiwal",
"92406", "Sahiwal",
"925464", "Mandi\ Bahauddin",
"922977", "Badin",
"922988", "Thatta",
"92916", "Peshawar\/Charsadda",
"92216", "Karachi",
"929977", "Mansehra\/Batagram",
"929668", "D\.I\.\ Khan",
"927237", "Ghotki",
"929467", "Swat",
"929455", "Lower\ Dir",
"928473", "Kharan",
"924579", "Pakpattan",
"929329", "Malakand",
"925467", "Mandi\ Bahauddin",
"928322", "Bolan",
"922974", "Badin",
"92866", "Gwadar",
"92497", "Kasur",
"922332", "Mirpur\ Khas",
"92446", "Okara",
"92428", "Lahore",
"928266", "K\.Abdullah\/Pishin",
"928486", "Khuzdar",
"929464", "Swat",
"927234", "Ghotki",
"928339", "Sibi\/Ziarat",
"92516", "Islamabad\/Rawalpindi",
"929974", "Mansehra\/Batagram",
"92656", "Khanewal",
"922329", "Tharparkar",
"92539", "Gujrat",
"92658", "Khanewal",
"92745", "Larkana",
"927226", "Jacobabad",
"92518", "Islamabad\/Rawalpindi",
"92634", "Bahawalnagar",
"929393", "Buner",
"928286", "Musakhel",
"92426", "Lahore",
"92714", "Sukkur",
"92448", "Okara",
"92868", "Gwadar",
"925478", "Hafizabad",
"92467", "Toba\ Tek\ Singh",
"928333", "Sibi\/Ziarat",
"92666", "Muzaffargarh",
"922323", "Tharparkar",
"92473", "Jhang",
"92627", "Bahawalpur",
"925472", "Hafizabad",
"928385", "Jaffarabad\/Nasirabad",
"929323", "Malakand",
"92532", "Gujrat",
"922338", "Mirpur\ Khas",
"928357", "Dera\ Bugti",
"928328", "Bolan",
"92647", "Dera\ Ghazi\ Khan",
"929399", "Buner",
"92668", "Muzaffargarh",
"928354", "Dera\ Bugti",
"922982", "Thatta",
"929695", "Lakki\ Marwat",
"928563", "Awaran",
"929662", "D\.I\.\ Khan",
"926066", "Layyah",
"926086", "Lodhran",
"929962", "Shangla",
"92575", "Attock",
"924573", "Pakpattan",
"92474", "Jhang",
"928479", "Kharan",
"928535", "Lasbela",
"922356", "Sanghar",
"927222", "Jacobabad",
"922979", "Badin",
"929324", "Malakand",
"922324", "Tharparkar",
"929979", "Mansehra\/Batagram",
"92557", "Gujranwala",
"924577", "Pakpattan",
"928334", "Sibi\/Ziarat",
"928282", "Musakhel",
"927239", "Ghotki",
"92617", "Multan",
"929469", "Swat",
"928567", "Awaran",
"928482", "Khuzdar",
"928555", "Panjgur",
"928262", "K\.Abdullah\/Pishin",
"922336", "Mirpur\ Khas",
"928326", "Bolan",
"928295", "Barkhan\/Kohlu",
"92573", "Attock",
"92486", "Sargodha",
"928564", "Awaran",
"92475", "Jhang",
"928353", "Dera\ Bugti",
"929375", "Mardan",
"926068", "Layyah",
"92574", "Attock",
"926088", "Lodhran",
"925469", "Mandi\ Bahauddin",
"929327", "Malakand",
"92679", "Vehari",
"924574", "Pakpattan",
"928337", "Sibi\/Ziarat",
"92257", "Dadu",
"922327", "Tharparkar",
"92488", "Sargodha",
"922358", "Sanghar",
"92928", "Bannu\/N\.\ Waziristan",
"929445", "Upper\ Dir",
"926082", "Lodhran",
"929966", "Shangla",
"928359", "Dera\ Bugti",
"922352", "Sanghar",
"92672", "Vehari",
"925435", "Chakwal",
"922445", "Nawabshah",
"929397", "Buner",
"92228", "Hyderabad",
"92226", "Hyderabad",
"928474", "Kharan",
"922986", "Thatta",
"926062", "Layyah",
"925463", "Mandi\ Bahauddin",
"929666", "D\.I\.\ Khan",
"92743", "Larkana",
"92926", "Kurram\ Agency",
"92687", "Rahim\ Yar\ Khan",
"929973", "Mansehra\/Batagram",
"92526", "Sialkot",
"929463", "Swat",
"92567", "Sheikhupura",
"927233", "Ghotki",
"928225", "Zhob",
"92715", "Sukkur",
"928477", "Kharan",
"928268", "K\.Abdullah\/Pishin",
"928488", "Khuzdar",
"92635", "Bahawalnagar",
"924595", "Mianwali",
"92817", "Quetta",
"92744", "Larkana",
"922973", "Badin",
"92418", "Faisalabad",
"927265", "Shikarpur",
"929435", "Chitral",
"92416", "Faisalabad",
"927228", "Jacobabad",
"928288", "Musakhel",
"929394", "Buner",
"925445", "Jhelum",
"92528", "Sialkot",
"925476", "Hafizabad",
"922435", "Khairpur",};

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