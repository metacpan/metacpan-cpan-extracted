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
our $VERSION = 1.20210602223300;

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
$areanames{en} = {"922439", "Khairpur",
"92866", "Gwadar",
"922977", "Badin",
"929653", "South\ Waziristan",
"929928", "Abottabad",
"924545", "Khushab",
"92526", "Sialkot",
"929953", "Haripur",
"92743", "Larkana",
"928472", "Kharan",
"92418", "Faisalabad",
"92556", "Gujranwala",
"929455", "Lower\ Dir",
"928438", "Mastung",
"928296", "Barkhan\/Kohlu",
"928294", "Barkhan\/Kohlu",
"928287", "Musakhel",
"922384", "Umerkot",
"92402", "Sahiwal",
"922386", "Umerkot",
"922355", "Sanghar",
"928485", "Khuzdar",
"925429", "Narowal",
"926069", "Layyah",
"929395", "Buner",
"92716", "Sukkur",
"925448", "Jhelum",
"928387", "Jaffarabad\/Nasirabad",
"92816", "Quetta",
"92912", "Peshawar\/Charsadda",
"92498", "Kasur",
"92536", "Gujrat",
"92478", "Jhang",
"929975", "Mansehra\/Batagram",
"92468", "Toba\ Tek\ Singh",
"924579", "Pakpattan",
"92217", "Karachi",
"928299", "Barkhan\/Kohlu",
"92229", "Hyderabad",
"928443", "Kalat",
"928522", "Kech",
"922389", "Umerkot",
"92426", "Lahore",
"928335", "Sibi\/Ziarat",
"92518", "Islamabad\/Rawalpindi",
"928222", "Zhob",
"922436", "Khairpur",
"922423", "Naushero\ Feroze",
"922434", "Khairpur",
"92634", "Bahawalnagar",
"92259", "Dadu",
"927222", "Jacobabad",
"925447", "Jhelum",
"928388", "Jaffarabad\/Nasirabad",
"92646", "Dera\ Ghazi\ Khan",
"92673", "Vehari",
"929323", "Malakand",
"92663", "Muzaffargarh",
"927235", "Ghotki",
"929223", "Kohat",
"925465", "Mandi\ Bahauddin",
"928437", "Mastung",
"928288", "Musakhel",
"928563", "Awaran",
"928322", "Bolan",
"924574", "Pakpattan",
"92624", "Bahawalpur",
"92689", "Rahim\ Yar\ Khan",
"924576", "Pakpattan",
"928235", "Killa\ Saifullah",
"926064", "Layyah",
"92485", "Sargodha",
"928535", "Lasbela",
"926066", "Layyah",
"925433", "Chakwal",
"92654", "Khanewal",
"925424", "Narowal",
"927263", "Shikarpur",
"922978", "Badin",
"92613", "Multan",
"925426", "Narowal",
"929927", "Abottabad",
"928263", "K\.Abdullah\/Pishin",
"92568", "Sheikhupura",
"929442", "Upper\ Dir",
"92444", "Okara",
"92578", "Attock",
"92925", "Hangu\/Orakzai\ Agy",
"925473", "Hafizabad",
"92617", "Multan",
"92629", "Bahawalpur",
"92684", "Rahim\ Yar\ Khan",
"922972", "Badin",
"929429", "Bajaur\ Agency",
"922985", "Thatta",
"92645", "Dera\ Ghazi\ Khan",
"929448", "Upper\ Dir",
"922329", "Tharparkar",
"928477", "Kharan",
"92449", "Okara",
"928353", "Dera\ Bugti",
"92512", "Islamabad\/Rawalpindi",
"928282", "Musakhel",
"928328", "Bolan",
"92659", "Khanewal",
"92425", "Lahore",
"924534", "Bhakkar",
"924536", "Bhakkar",
"929383", "Swabi",
"92486", "Sargodha",
"928228", "Zhob",
"928375", "Jhal\ Magsi",
"926085", "Lodhran",
"929374", "Mardan",
"92224", "Hyderabad",
"928253", "Chagai",
"92677", "Vehari",
"927228", "Jacobabad",
"928382", "Jaffarabad\/Nasirabad",
"92667", "Muzaffargarh",
"929376", "Mardan",
"928249", "Loralai",
"92926", "Kurram\ Agency",
"92213", "Karachi",
"928553", "Panjgur",
"92254", "Dadu",
"929696", "Lakki\ Marwat",
"92639", "Bahawalnagar",
"928528", "Kech",
"929694", "Lakki\ Marwat",
"92572", "Attock",
"92562", "Sheikhupura",
"929635", "Tank",
"922445", "Nawabshah",
"92555", "Gujranwala",
"929465", "Swat",
"924539", "Bhakkar",
"928527", "Kech",
"929433", "Chitral",
"929424", "Bajaur\ Agency",
"92412", "Faisalabad",
"929426", "Bajaur\ Agency",
"92865", "Gwadar",
"928227", "Zhob",
"929663", "D\.I\.\ Khan",
"92998", "Kohistan",
"922326", "Tharparkar",
"925442", "Jhelum",
"927227", "Jacobabad",
"929963", "Shangla",
"92525", "Sialkot",
"922333", "Mirpur\ Khas",
"922324", "Tharparkar",
"92408", "Sahiwal",
"928478", "Kharan",
"928432", "Mastung",
"92535", "Gujrat",
"924595", "Mianwali",
"928327", "Bolan",
"929699", "Lakki\ Marwat",
"92918", "Peshawar\/Charsadda",
"926043", "Rajanpur",
"92715", "Sukkur",
"929922", "Abottabad",
"92492", "Kasur",
"928244", "Loralai",
"92462", "Toba\ Tek\ Singh",
"92472", "Jhang",
"92815", "Quetta",
"928246", "Loralai",
"929447", "Upper\ Dir",
"929379", "Mardan",
"92747", "Larkana",
"92256", "Dadu",
"929229", "Kohat",
"92649", "Dera\ Ghazi\ Khan",
"9258", "AJK\/FATA",
"92913", "Peshawar\/Charsadda",
"928569", "Awaran",
"922987", "Thatta",
"924542", "Khushab",
"92625", "Bahawalpur",
"922352", "Sanghar",
"928482", "Khuzdar",
"92655", "Khanewal",
"92417", "Faisalabad",
"92484", "Sargodha",
"92429", "Lahore",
"927269", "Shikarpur",
"925439", "Chakwal",
"92924", "Khyber\/Mohmand\ Agy",
"924598", "Mianwali",
"929452", "Lower\ Dir",
"92445", "Okara",
"928269", "K\.Abdullah\/Pishin",
"92226", "Hyderabad",
"928475", "Kharan",
"928293", "Barkhan\/Kohlu",
"926087", "Lodhran",
"929392", "Buner",
"928377", "Jhal\ Magsi",
"928449", "Kalat",
"92403", "Sahiwal",
"922383", "Umerkot",
"92635", "Bahawalnagar",
"929656", "South\ Waziristan",
"92686", "Rahim\ Yar\ Khan",
"929654", "South\ Waziristan",
"92497", "Kasur",
"929972", "Mansehra\/Batagram",
"922429", "Naushero\ Feroze",
"92477", "Jhang",
"929468", "Swat",
"92467", "Toba\ Tek\ Singh",
"922448", "Nawabshah",
"929954", "Haripur",
"92742", "Larkana",
"929329", "Malakand",
"929638", "Tank",
"929956", "Haripur",
"92612", "Multan",
"927266", "Shikarpur",
"92218", "Karachi",
"925436", "Chakwal",
"925434", "Chakwal",
"925423", "Narowal",
"927264", "Shikarpur",
"928525", "Kech",
"926063", "Layyah",
"929467", "Swat",
"92559", "Gujranwala",
"922447", "Nawabshah",
"928266", "K\.Abdullah\/Pishin",
"929637", "Tank",
"928264", "K\.Abdullah\/Pishin",
"928564", "Awaran",
"92529", "Sialkot",
"928566", "Awaran",
"929226", "Kohat",
"92517", "Islamabad\/Rawalpindi",
"927225", "Jacobabad",
"929224", "Kohat",
"926088", "Lodhran",
"928225", "Zhob",
"928378", "Jhal\ Magsi",
"92869", "Gwadar",
"924573", "Pakpattan",
"928332", "Sibi\/Ziarat",
"922424", "Naushero\ Feroze",
"922433", "Khairpur",
"928232", "Killa\ Saifullah",
"922426", "Naushero\ Feroze",
"929659", "South\ Waziristan",
"928325", "Bolan",
"92662", "Muzaffargarh",
"924597", "Mianwali",
"929326", "Malakand",
"929959", "Haripur",
"92672", "Vehari",
"929324", "Malakand",
"925462", "Mandi\ Bahauddin",
"92539", "Gujrat",
"927232", "Ghotki",
"929445", "Upper\ Dir",
"92819", "Quetta",
"922988", "Thatta",
"928532", "Lasbela",
"928446", "Kalat",
"92567", "Sheikhupura",
"92719", "Sukkur",
"928444", "Kalat",
"92577", "Attock",
"928554", "Panjgur",
"92534", "Gujrat",
"92618", "Multan",
"92212", "Karachi",
"928556", "Panjgur",
"922982", "Thatta",
"924547", "Khushab",
"92563", "Sheikhupura",
"92573", "Attock",
"922975", "Badin",
"928538", "Lasbela",
"929693", "Lakki\ Marwat",
"92714", "Sukkur",
"922357", "Sanghar",
"928487", "Khuzdar",
"928238", "Killa\ Saifullah",
"926049", "Rajanpur",
"928285", "Musakhel",
"929457", "Lower\ Dir",
"928256", "Chagai",
"92814", "Quetta",
"929373", "Mardan",
"928254", "Chagai",
"925468", "Mandi\ Bahauddin",
"927238", "Ghotki",
"92513", "Islamabad\/Rawalpindi",
"928356", "Dera\ Bugti",
"928354", "Dera\ Bugti",
"92554", "Gujranwala",
"928385", "Jaffarabad\/Nasirabad",
"929397", "Buner",
"926082", "Lodhran",
"92678", "Vehari",
"929384", "Swabi",
"92668", "Muzaffargarh",
"929386", "Swabi",
"924533", "Bhakkar",
"928372", "Jhal\ Magsi",
"928338", "Sibi\/Ziarat",
"929439", "Chitral",
"929977", "Mansehra\/Batagram",
"925476", "Hafizabad",
"92864", "Gwadar",
"929669", "D\.I\.\ Khan",
"925474", "Hafizabad",
"922339", "Mirpur\ Khas",
"929969", "Shangla",
"92524", "Sialkot",
"92493", "Kasur",
"92656", "Khanewal",
"929978", "Mansehra\/Batagram",
"926046", "Rajanpur",
"926044", "Rajanpur",
"929462", "Swat",
"928259", "Chagai",
"92446", "Okara",
"922442", "Nawabshah",
"92473", "Jhang",
"92463", "Toba\ Tek\ Singh",
"92225", "Hyderabad",
"928243", "Loralai",
"929632", "Tank",
"92255", "Dadu",
"928559", "Panjgur",
"925445", "Jhelum",
"929398", "Buner",
"92407", "Sahiwal",
"92626", "Bahawalpur",
"928337", "Sibi\/Ziarat",
"929666", "D\.I\.\ Khan",
"92636", "Bahawalnagar",
"928488", "Khuzdar",
"922358", "Sanghar",
"92685", "Rahim\ Yar\ Khan",
"925479", "Hafizabad",
"928237", "Killa\ Saifullah",
"929664", "D\.I\.\ Khan",
"929436", "Chitral",
"929434", "Chitral",
"92413", "Faisalabad",
"929423", "Bajaur\ Agency",
"924592", "Mianwali",
"929458", "Lower\ Dir",
"928435", "Mastung",
"929964", "Shangla",
"92644", "Dera\ Ghazi\ Khan",
"922334", "Mirpur\ Khas",
"922323", "Tharparkar",
"927237", "Ghotki",
"922336", "Mirpur\ Khas",
"929966", "Shangla",
"925467", "Mandi\ Bahauddin",
"92917", "Peshawar\/Charsadda",
"924548", "Khushab",
"928359", "Dera\ Bugti",
"929925", "Abottabad",
"92489", "Sargodha",
"92424", "Lahore",
"929389", "Swabi",
"928537", "Lasbela",
"92748", "Larkana",
"922438", "Khairpur",
"929385", "Swabi",
"929929", "Abottabad",
"92665", "Muzaffargarh",
"92675", "Vehari",
"928355", "Dera\ Bugti",
"928384", "Jaffarabad\/Nasirabad",
"928386", "Jaffarabad\/Nasirabad",
"929372", "Mardan",
"92404", "Sahiwal",
"92499", "Kasur",
"922983", "Thatta",
"928439", "Mastung",
"929692", "Lakki\ Marwat",
"92469", "Toba\ Tek\ Singh",
"925475", "Hafizabad",
"92479", "Jhang",
"922976", "Badin",
"922974", "Badin",
"925428", "Narowal",
"92923", "Nowshera",
"92647", "Dera\ Ghazi\ Khan",
"926068", "Layyah",
"928555", "Panjgur",
"92483", "Sargodha",
"925449", "Jhelum",
"92615", "Multan",
"928297", "Barkhan\/Kohlu",
"928284", "Musakhel",
"928286", "Musakhel",
"92427", "Lahore",
"92419", "Faisalabad",
"928255", "Chagai",
"926083", "Lodhran",
"92914", "Peshawar\/Charsadda",
"928373", "Jhal\ Magsi",
"924532", "Bhakkar",
"924578", "Pakpattan",
"92216", "Karachi",
"922387", "Umerkot",
"928436", "Mastung",
"928298", "Barkhan\/Kohlu",
"928434", "Mastung",
"929965", "Shangla",
"922335", "Mirpur\ Khas",
"92537", "Gujrat",
"929665", "D\.I\.\ Khan",
"92688", "Rahim\ Yar\ Khan",
"924577", "Pakpattan",
"922388", "Umerkot",
"929435", "Chitral",
"92745", "Larkana",
"929924", "Abottabad",
"925427", "Narowal",
"929926", "Abottabad",
"92817", "Quetta",
"926067", "Layyah",
"92717", "Sukkur",
"928389", "Jaffarabad\/Nasirabad",
"92579", "Attock",
"929463", "Swat",
"92569", "Sheikhupura",
"92632", "Bahawalnagar",
"922443", "Nawabshah",
"929633", "Tank",
"928242", "Loralai",
"92228", "Hyderabad",
"92622", "Bahawalpur",
"928289", "Musakhel",
"92557", "Gujranwala",
"926045", "Rajanpur",
"922437", "Khairpur",
"92519", "Islamabad\/Rawalpindi",
"92527", "Sialkot",
"92442", "Okara",
"922979", "Badin",
"929422", "Bajaur\ Agency",
"924593", "Mianwali",
"925446", "Jhelum",
"922322", "Tharparkar",
"92867", "Gwadar",
"925444", "Jhelum",
"92652", "Khanewal",
"92258", "Dadu",
"928483", "Khuzdar",
"922353", "Sanghar",
"92746", "Larkana",
"92523", "Sialkot",
"929428", "Bajaur\ Agency",
"92863", "Gwadar",
"929453", "Lower\ Dir",
"922328", "Tharparkar",
"929449", "Upper\ Dir",
"929377", "Mardan",
"92682", "Rahim\ Yar\ Khan",
"929955", "Haripur",
"924543", "Khushab",
"928329", "Bolan",
"929655", "South\ Waziristan",
"929697", "Lakki\ Marwat",
"92514", "Islamabad\/Rawalpindi",
"92638", "Bahawalnagar",
"92553", "Gujranwala",
"92813", "Quetta",
"92222", "Hyderabad",
"92628", "Bahawalpur",
"929973", "Mansehra\/Batagram",
"928229", "Zhob",
"927229", "Jacobabad",
"92713", "Sukkur",
"928248", "Loralai",
"928292", "Barkhan\/Kohlu",
"928476", "Kharan",
"92448", "Okara",
"92564", "Sheikhupura",
"92574", "Attock",
"928474", "Kharan",
"929393", "Buner",
"928529", "Kech",
"924537", "Bhakkar",
"92658", "Khanewal",
"92533", "Gujrat",
"92252", "Dadu",
"922382", "Umerkot",
"929325", "Malakand",
"92423", "Lahore",
"922425", "Naushero\ Feroze",
"924538", "Bhakkar",
"928326", "Bolan",
"928324", "Bolan",
"924572", "Pakpattan",
"928333", "Sibi\/Ziarat",
"92643", "Dera\ Ghazi\ Khan",
"92927", "Karak",
"925422", "Narowal",
"92666", "Muzaffargarh",
"92676", "Vehari",
"926062", "Layyah",
"92919", "Peshawar\/Charsadda",
"928445", "Kalat",
"929446", "Upper\ Dir",
"929444", "Upper\ Dir",
"92414", "Faisalabad",
"92487", "Sargodha",
"928247", "Loralai",
"928479", "Kharan",
"928265", "K\.Abdullah\/Pishin",
"925435", "Chakwal",
"927265", "Shikarpur",
"929698", "Lakki\ Marwat",
"928524", "Kech",
"928533", "Lasbela",
"928526", "Kech",
"92215", "Karachi",
"928226", "Zhob",
"92474", "Jhang",
"922432", "Khairpur",
"92464", "Toba\ Tek\ Singh",
"928233", "Killa\ Saifullah",
"928224", "Zhob",
"929427", "Bajaur\ Agency",
"928565", "Awaran",
"92409", "Sahiwal",
"92494", "Kasur",
"922327", "Tharparkar",
"92616", "Multan",
"927226", "Jacobabad",
"927224", "Jacobabad",
"927233", "Ghotki",
"925463", "Mandi\ Bahauddin",
"929225", "Kohat",
"929378", "Mardan",
"929228", "Kohat",
"929375", "Mardan",
"92576", "Attock",
"92566", "Sheikhupura",
"928352", "Dera\ Bugti",
"928568", "Awaran",
"928283", "Musakhel",
"928374", "Jhal\ Magsi",
"926086", "Lodhran",
"929382", "Swabi",
"926084", "Lodhran",
"928376", "Jhal\ Magsi",
"925472", "Hafizabad",
"929695", "Lakki\ Marwat",
"927268", "Shikarpur",
"922973", "Badin",
"929657", "South\ Waziristan",
"925438", "Chakwal",
"928268", "K\.Abdullah\/Pishin",
"929957", "Haripur",
"924599", "Mianwali",
"92482", "Sargodha",
"922986", "Thatta",
"922984", "Thatta",
"92648", "Dera\ Ghazi\ Khan",
"928552", "Panjgur",
"928448", "Kalat",
"92516", "Islamabad\/Rawalpindi",
"92428", "Lahore",
"924535", "Bhakkar",
"92744", "Larkana",
"922428", "Naushero\ Feroze",
"929469", "Swat",
"928252", "Chagai",
"928383", "Jaffarabad\/Nasirabad",
"929328", "Malakand",
"929639", "Tank",
"922449", "Nawabshah",
"92443", "Okara",
"929432", "Chitral",
"929662", "D\.I\.\ Khan",
"92466", "Toba\ Tek\ Singh",
"922427", "Naushero\ Feroze",
"92476", "Jhang",
"92538", "Gujrat",
"925443", "Jhelum",
"92653", "Khanewal",
"922332", "Mirpur\ Khas",
"92496", "Kasur",
"929962", "Shangla",
"92614", "Multan",
"92687", "Rahim\ Yar\ Khan",
"929327", "Malakand",
"924596", "Mianwali",
"924594", "Mianwali",
"928245", "Loralai",
"92818", "Quetta",
"92623", "Bahawalpur",
"928379", "Jhal\ Magsi",
"928447", "Kalat",
"92718", "Sukkur",
"926089", "Lodhran",
"92915", "Peshawar\/Charsadda",
"92227", "Hyderabad",
"92674", "Vehari",
"926042", "Rajanpur",
"92664", "Muzaffargarh",
"925437", "Chakwal",
"929658", "South\ Waziristan",
"927267", "Shikarpur",
"92219", "Karachi",
"929923", "Abottabad",
"922446", "Nawabshah",
"929634", "Tank",
"928267", "K\.Abdullah\/Pishin",
"929636", "Tank",
"929958", "Haripur",
"92558", "Gujranwala",
"922444", "Nawabshah",
"92633", "Bahawalnagar",
"92416", "Faisalabad",
"929464", "Swat",
"929466", "Swat",
"929227", "Kohat",
"922325", "Tharparkar",
"928433", "Mastung",
"92405", "Sahiwal",
"92528", "Sialkot",
"928567", "Awaran",
"922989", "Thatta",
"929425", "Bajaur\ Agency",
"92868", "Gwadar",
"92257", "Dadu",
"928473", "Kharan",
"928357", "Dera\ Bugti",
"92214", "Karachi",
"92253", "Dadu",
"92532", "Gujrat",
"929396", "Buner",
"92669", "Muzaffargarh",
"928539", "Lasbela",
"929394", "Buner",
"92679", "Vehari",
"92916", "Peshawar\/Charsadda",
"929387", "Swabi",
"928239", "Killa\ Saifullah",
"926048", "Rajanpur",
"929976", "Mansehra\/Batagram",
"925477", "Hafizabad",
"929974", "Mansehra\/Batagram",
"929652", "South\ Waziristan",
"92223", "Hyderabad",
"92465", "Toba\ Tek\ Singh",
"92812", "Quetta",
"92475", "Jhang",
"92495", "Kasur",
"92712", "Sukkur",
"929952", "Haripur",
"925469", "Mandi\ Bahauddin",
"927239", "Ghotki",
"92637", "Bahawalnagar",
"924544", "Khushab",
"92627", "Bahawalpur",
"924546", "Khushab",
"92406", "Sahiwal",
"92619", "Multan",
"928557", "Panjgur",
"92552", "Gujranwala",
"928339", "Sibi\/Ziarat",
"922385", "Umerkot",
"929438", "Chitral",
"929668", "D\.I\.\ Khan",
"928486", "Khuzdar",
"92447", "Okara",
"922356", "Sanghar",
"928484", "Khuzdar",
"922354", "Sanghar",
"92522", "Sialkot",
"928257", "Chagai",
"92683", "Rahim\ Yar\ Khan",
"922338", "Mirpur\ Khas",
"929968", "Shangla",
"92657", "Khanewal",
"929454", "Lower\ Dir",
"92415", "Faisalabad",
"92862", "Gwadar",
"929456", "Lower\ Dir",
"928295", "Barkhan\/Kohlu",
"924575", "Pakpattan",
"929437", "Chitral",
"929667", "D\.I\.\ Khan",
"928234", "Killa\ Saifullah",
"928223", "Zhob",
"928236", "Killa\ Saifullah",
"929979", "Mansehra\/Batagram",
"922422", "Naushero\ Feroze",
"927223", "Jacobabad",
"927234", "Ghotki",
"925464", "Mandi\ Bahauddin",
"928258", "Chagai",
"925466", "Mandi\ Bahauddin",
"929967", "Shangla",
"927236", "Ghotki",
"922337", "Mirpur\ Khas",
"929322", "Malakand",
"92575", "Attock",
"92928", "Bannu\/N\.\ Waziristan",
"92565", "Sheikhupura",
"928558", "Panjgur",
"928536", "Lasbela",
"928442", "Kalat",
"926065", "Layyah",
"92749", "Larkana",
"928523", "Kech",
"929399", "Buner",
"928534", "Lasbela",
"925425", "Narowal",
"92488", "Sargodha",
"926047", "Rajanpur",
"925478", "Hafizabad",
"928489", "Khuzdar",
"922359", "Sanghar",
"927262", "Shikarpur",
"925432", "Chakwal",
"92642", "Dera\ Ghazi\ Khan",
"929459", "Lower\ Dir",
"928262", "K\.Abdullah\/Pishin",
"929443", "Upper\ Dir",
"929222", "Kohat",
"92422", "Lahore",
"924549", "Khushab",
"928358", "Dera\ Bugti",
"928562", "Awaran",
"928323", "Bolan",
"928334", "Sibi\/Ziarat",
"928336", "Sibi\/Ziarat",
"92515", "Islamabad\/Rawalpindi",
"922435", "Khairpur",
"929388", "Swabi",};

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