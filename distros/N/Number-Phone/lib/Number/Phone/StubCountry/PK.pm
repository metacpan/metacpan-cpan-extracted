# automatically generated file, don't edit



# Copyright 2024 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20240910191016;

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
$areanames{en} = {"929469", "Swat",
"922444", "Nawabshah",
"92554", "Gujranwala",
"928526", "Kech",
"922432", "Khairpur",
"927232", "Ghotki",
"92653", "Khanewal",
"92528", "Sialkot",
"922327", "Tharparkar",
"928533", "Lasbela",
"922987", "Thatta",
"92655", "Khanewal",
"927266", "Shikarpur",
"928553", "Panjgur",
"92668", "Muzaffargarh",
"924543", "Khushab",
"92618", "Multan",
"929665", "D\.I\.\ Khan",
"92418", "Faisalabad",
"922978", "Badin",
"92468", "Toba\ Tek\ Singh",
"92222", "Hyderabad",
"92742", "Larkana",
"929696", "Lakki\ Marwat",
"928476", "Kharan",
"929374", "Mardan",
"929659", "South\ Waziristan",
"929964", "Shangla",
"928378", "Jhal\ Magsi",
"925425", "Narowal",
"929435", "Chitral",
"92494", "Kasur",
"92529", "Sialkot",
"929455", "Lower\ Dir",
"92619", "Multan",
"92669", "Muzaffargarh",
"929957", "Haripur",
"92469", "Toba\ Tek\ Singh",
"925476", "Hafizabad",
"929639", "Tank",
"928387", "Jaffarabad\/Nasirabad",
"92419", "Faisalabad",
"925448", "Jhelum",
"929466", "Swat",
"928529", "Kech",
"929452", "Lower\ Dir",
"928337", "Sibi\/Ziarat",
"9258", "AJK\/FATA",
"925463", "Mandi\ Bahauddin",
"929978", "Mansehra\/Batagram",
"926048", "Rajanpur",
"929444", "Upper\ Dir",
"927269", "Shikarpur",
"92532", "Gujrat",
"92659", "Khanewal",
"92646", "Dera\ Ghazi\ Khan",
"925422", "Narowal",
"926063", "Layyah",
"929327", "Malakand",
"92446", "Okara",
"929432", "Chitral",
"928448", "Kalat",
"928357", "Dera\ Bugti",
"92564", "Sheikhupura",
"92413", "Faisalabad",
"92717", "Sukkur",
"92572", "Attock",
"929699", "Lakki\ Marwat",
"928479", "Kharan",
"928227", "Zhob",
"929656", "South\ Waziristan",
"92514", "Islamabad\/Rawalpindi",
"92463", "Toba\ Tek\ Singh",
"929662", "D\.I\.\ Khan",
"92525", "Sialkot",
"92663", "Muzaffargarh",
"92613", "Multan",
"924574", "Pakpattan",
"92658", "Khanewal",
"92523", "Sialkot",
"928268", "K\.Abdullah\/Pishin",
"92665", "Muzaffargarh",
"92615", "Multan",
"92424", "Lahore",
"927235", "Ghotki",
"922435", "Khairpur",
"92814", "Quetta",
"928243", "Loralai",
"92415", "Faisalabad",
"92624", "Bahawalpur",
"925479", "Hafizabad",
"929636", "Tank",
"92465", "Toba\ Tek\ Singh",
"92864", "Gwadar",
"928239", "Killa\ Saifullah",
"928372", "Jhal\ Magsi",
"929926", "Abottabad",
"92679", "Vehari",
"928484", "Khuzdar",
"92213", "Karachi",
"929386", "Swabi",
"928445", "Kalat",
"92407", "Sahiwal",
"926084", "Lodhran",
"926045", "Rajanpur",
"92479", "Jhang",
"92919", "Peshawar\/Charsadda",
"92224", "Hyderabad",
"92744", "Larkana",
"92638", "Bahawalnagar",
"928383", "Jaffarabad\/Nasirabad",
"922389", "Umerkot",
"929953", "Haripur",
"92488", "Sargodha",
"929975", "Mansehra\/Batagram",
"925445", "Jhelum",
"928259", "Chagai",
"92688", "Rahim\ Yar\ Khan",
"92258", "Dadu",
"929229", "Kohat",
"92215", "Karachi",
"928296", "Barkhan\/Kohlu",
"92492", "Kasur",
"92678", "Vehari",
"922438", "Khairpur",
"927238", "Ghotki",
"928564", "Awaran",
"929396", "Buner",
"928329", "Bolan",
"922323", "Tharparkar",
"928537", "Lasbela",
"922983", "Thatta",
"924536", "Bhakkar",
"928265", "K\.Abdullah\/Pishin",
"92478", "Jhang",
"922336", "Mirpur\ Khas",
"92918", "Peshawar\/Charsadda",
"927224", "Jacobabad",
"922424", "Naushero\ Feroze",
"92489", "Sargodha",
"92552", "Gujranwala",
"922356", "Sanghar",
"922972", "Badin",
"924599", "Mianwali",
"92639", "Bahawalnagar",
"928286", "Musakhel",
"92689", "Rahim\ Yar\ Khan",
"92259", "Dadu",
"928557", "Panjgur",
"924547", "Khushab",
"92675", "Vehari",
"928236", "Killa\ Saifullah",
"92924", "Khyber\/Mohmand\ Agy",
"922975", "Badin",
"929929", "Abottabad",
"929389", "Swabi",
"92422", "Lahore",
"928223", "Zhob",
"92812", "Quetta",
"92622", "Bahawalpur",
"92475", "Jhang",
"92915", "Peshawar\/Charsadda",
"92862", "Gwadar",
"929668", "D\.I\.\ Khan",
"92562", "Sheikhupura",
"92574", "Attock",
"928247", "Loralai",
"922386", "Umerkot",
"92473", "Jhang",
"92913", "Peshawar\/Charsadda",
"92512", "Islamabad\/Rawalpindi",
"928256", "Chagai",
"92219", "Karachi",
"92673", "Vehari",
"928262", "K\.Abdullah\/Pishin",
"929226", "Kohat",
"928299", "Barkhan\/Kohlu",
"925434", "Chakwal",
"929399", "Buner",
"928326", "Bolan",
"92534", "Gujrat",
"92253", "Dadu",
"929424", "Bajaur\ Agency",
"92683", "Rahim\ Yar\ Khan",
"925467", "Mandi\ Bahauddin",
"929972", "Mansehra\/Batagram",
"925442", "Jhelum",
"92633", "Bahawalnagar",
"924539", "Bhakkar",
"928333", "Sibi\/Ziarat",
"929458", "Lower\ Dir",
"922339", "Mirpur\ Khas",
"92483", "Sargodha",
"928375", "Jhal\ Magsi",
"92635", "Bahawalnagar",
"925428", "Narowal",
"928353", "Dera\ Bugti",
"929438", "Chitral",
"922359", "Sanghar",
"924596", "Mianwali",
"926067", "Layyah",
"929323", "Malakand",
"928442", "Kalat",
"92485", "Sargodha",
"928289", "Musakhel",
"926042", "Rajanpur",
"92255", "Dadu",
"92685", "Rahim\ Yar\ Khan",
"928434", "Mastung",
"92218", "Karachi",
"929666", "D\.I\.\ Khan",
"929652", "South\ Waziristan",
"927265", "Shikarpur",
"924577", "Pakpattan",
"92526", "Sialkot",
"928238", "Killa\ Saifullah",
"92616", "Multan",
"929228", "Kohat",
"928525", "Kech",
"928258", "Chagai",
"92666", "Muzaffargarh",
"922388", "Umerkot",
"929632", "Tank",
"92466", "Toba\ Tek\ Singh",
"92416", "Faisalabad",
"928224", "Zhob",
"929324", "Malakand",
"928354", "Dera\ Bugti",
"92227", "Hyderabad",
"92747", "Larkana",
"929456", "Lower\ Dir",
"929462", "Swat",
"92443", "Okara",
"928433", "Mastung",
"929447", "Upper\ Dir",
"92643", "Dera\ Ghazi\ Khan",
"928328", "Bolan",
"925475", "Hafizabad",
"927239", "Ghotki",
"922439", "Khairpur",
"928475", "Kharan",
"92645", "Dera\ Ghazi\ Khan",
"929695", "Lakki\ Marwat",
"929423", "Bajaur\ Agency",
"925433", "Chakwal",
"924598", "Mianwali",
"928334", "Sibi\/Ziarat",
"929436", "Chitral",
"92404", "Sahiwal",
"925426", "Narowal",
"92445", "Okara",
"929669", "D\.I\.\ Khan",
"928472", "Kharan",
"929954", "Haripur",
"928384", "Jaffarabad\/Nasirabad",
"929692", "Lakki\ Marwat",
"929388", "Swabi",
"929928", "Abottabad",
"928483", "Khuzdar",
"928298", "Barkhan\/Kohlu",
"92648", "Dera\ Ghazi\ Khan",
"92537", "Gujrat",
"929465", "Swat",
"929967", "Shangla",
"925472", "Hafizabad",
"929377", "Mardan",
"926083", "Lodhran",
"92448", "Okara",
"922338", "Mirpur\ Khas",
"924538", "Bhakkar",
"928522", "Kech",
"929459", "Lower\ Dir",
"922423", "Naushero\ Feroze",
"92712", "Sukkur",
"927223", "Jacobabad",
"92577", "Attock",
"929635", "Tank",
"927236", "Ghotki",
"922436", "Khairpur",
"929398", "Buner",
"922984", "Thatta",
"922324", "Tharparkar",
"929655", "South\ Waziristan",
"92656", "Khanewal",
"927262", "Shikarpur",
"92649", "Dera\ Ghazi\ Khan",
"928288", "Musakhel",
"92927", "Karak",
"928563", "Awaran",
"92449", "Okara",
"922447", "Nawabshah",
"922358", "Sanghar",
"929439", "Chitral",
"925429", "Narowal",
"929976", "Mansehra\/Batagram",
"929443", "Upper\ Dir",
"928322", "Bolan",
"928437", "Mastung",
"928295", "Barkhan\/Kohlu",
"92402", "Sahiwal",
"926064", "Layyah",
"925446", "Jhelum",
"929468", "Swat",
"929385", "Swabi",
"928446", "Kalat",
"924592", "Mianwali",
"922979", "Badin",
"92486", "Sargodha",
"929925", "Abottabad",
"92636", "Bahawalnagar",
"929427", "Bajaur\ Agency",
"925437", "Chakwal",
"92497", "Kasur",
"925464", "Mandi\ Bahauddin",
"926046", "Rajanpur",
"92686", "Rahim\ Yar\ Khan",
"92256", "Dadu",
"922355", "Sanghar",
"92676", "Vehari",
"928379", "Jhal\ Magsi",
"928232", "Killa\ Saifullah",
"924573", "Pakpattan",
"92476", "Jhang",
"92916", "Peshawar\/Charsadda",
"929658", "South\ Waziristan",
"928285", "Musakhel",
"928244", "Loralai",
"922382", "Umerkot",
"929638", "Tank",
"92557", "Gujranwala",
"929395", "Buner",
"922335", "Mirpur\ Khas",
"929222", "Kohat",
"928266", "K\.Abdullah\/Pishin",
"924535", "Bhakkar",
"928252", "Chagai",
"929979", "Mansehra\/Batagram",
"922385", "Umerkot",
"92427", "Lahore",
"924544", "Khushab",
"928554", "Panjgur",
"929392", "Buner",
"922332", "Mirpur\ Khas",
"92867", "Gwadar",
"929225", "Kohat",
"922427", "Naushero\ Feroze",
"927227", "Jacobabad",
"92817", "Quetta",
"924532", "Bhakkar",
"928528", "Kech",
"925449", "Jhelum",
"928255", "Chagai",
"92627", "Bahawalpur",
"928449", "Kalat",
"922976", "Badin",
"922352", "Sanghar",
"92517", "Islamabad\/Rawalpindi",
"92567", "Sheikhupura",
"928235", "Killa\ Saifullah",
"922443", "Nawabshah",
"92714", "Sukkur",
"928567", "Awaran",
"927268", "Shikarpur",
"928534", "Lasbela",
"928282", "Musakhel",
"926049", "Rajanpur",
"929382", "Swabi",
"924595", "Mianwali",
"929922", "Abottabad",
"928376", "Jhal\ Magsi",
"928478", "Kharan",
"929698", "Lakki\ Marwat",
"929963", "Shangla",
"929373", "Mardan",
"926087", "Lodhran",
"928325", "Bolan",
"925478", "Hafizabad",
"928292", "Barkhan\/Kohlu",
"92216", "Karachi",
"928269", "K\.Abdullah\/Pishin",
"928487", "Khuzdar",
"929956", "Haripur",
"929372", "Mardan",
"925477", "Hafizabad",
"929962", "Shangla",
"92493", "Kasur",
"926088", "Lodhran",
"92429", "Lahore",
"928386", "Jaffarabad\/Nasirabad",
"929445", "Upper\ Dir",
"92629", "Bahawalpur",
"928293", "Barkhan\/Kohlu",
"92819", "Quetta",
"928488", "Khuzdar",
"92869", "Gwadar",
"929923", "Abottabad",
"92569", "Sheikhupura",
"929383", "Swabi",
"92519", "Islamabad\/Rawalpindi",
"929697", "Lakki\ Marwat",
"92212", "Karachi",
"92495", "Kasur",
"928229", "Zhob",
"928477", "Kharan",
"922353", "Sanghar",
"929329", "Malakand",
"92428", "Lahore",
"924575", "Pakpattan",
"92654", "Khanewal",
"922442", "Nawabshah",
"928359", "Dera\ Bugti",
"92868", "Gwadar",
"927267", "Shikarpur",
"92818", "Quetta",
"922434", "Khairpur",
"928283", "Musakhel",
"927234", "Ghotki",
"928568", "Awaran",
"92553", "Gujranwala",
"92628", "Bahawalpur",
"922326", "Tharparkar",
"922986", "Thatta",
"92518", "Islamabad\/Rawalpindi",
"92568", "Sheikhupura",
"929393", "Buner",
"92555", "Gujranwala",
"922333", "Mirpur\ Khas",
"928527", "Kech",
"927228", "Jacobabad",
"922428", "Naushero\ Feroze",
"924533", "Bhakkar",
"928339", "Sibi\/Ziarat",
"92614", "Multan",
"922383", "Umerkot",
"929959", "Haripur",
"92425", "Lahore",
"929664", "D\.I\.\ Khan",
"92672", "Vehari",
"929637", "Tank",
"928389", "Jaffarabad\/Nasirabad",
"92664", "Muzaffargarh",
"92472", "Jhang",
"92912", "Peshawar\/Charsadda",
"929223", "Kohat",
"92865", "Gwadar",
"92464", "Toba\ Tek\ Singh",
"92513", "Islamabad\/Rawalpindi",
"92414", "Faisalabad",
"928253", "Chagai",
"92815", "Quetta",
"92563", "Sheikhupura",
"92625", "Bahawalpur",
"92863", "Gwadar",
"92515", "Islamabad\/Rawalpindi",
"924572", "Pakpattan",
"928233", "Killa\ Saifullah",
"92813", "Quetta",
"922445", "Nawabshah",
"92565", "Sheikhupura",
"92558", "Gujranwala",
"92623", "Bahawalpur",
"92423", "Lahore",
"92524", "Sialkot",
"928226", "Zhob",
"929657", "South\ Waziristan",
"92499", "Kasur",
"924593", "Mianwali",
"929326", "Malakand",
"928356", "Dera\ Bugti",
"929454", "Lower\ Dir",
"92406", "Sahiwal",
"925438", "Chakwal",
"929428", "Bajaur\ Agency",
"92559", "Gujranwala",
"922329", "Tharparkar",
"929375", "Mardan",
"922989", "Thatta",
"928438", "Mastung",
"92482", "Sargodha",
"929965", "Shangla",
"92632", "Bahawalnagar",
"928323", "Bolan",
"929442", "Upper\ Dir",
"929467", "Swat",
"92498", "Kasur",
"925424", "Narowal",
"928336", "Sibi\/Ziarat",
"92682", "Rahim\ Yar\ Khan",
"92252", "Dadu",
"929434", "Chitral",
"928287", "Musakhel",
"928562", "Awaran",
"92716", "Sukkur",
"92578", "Attock",
"927263", "Shikarpur",
"928556", "Panjgur",
"924546", "Khushab",
"922357", "Sanghar",
"922448", "Nawabshah",
"926069", "Layyah",
"922974", "Badin",
"92539", "Gujrat",
"924537", "Bhakkar",
"927222", "Jacobabad",
"92652", "Khanewal",
"922422", "Naushero\ Feroze",
"922337", "Mirpur\ Khas",
"928523", "Kech",
"92928", "Bannu\/N\.\ Waziristan",
"929397", "Buner",
"925469", "Mandi\ Bahauddin",
"928536", "Lasbela",
"92579", "Attock",
"928482", "Khuzdar",
"92745", "Larkana",
"928374", "Jhal\ Magsi",
"92225", "Hyderabad",
"928297", "Barkhan\/Kohlu",
"929378", "Mardan",
"928435", "Mastung",
"929968", "Shangla",
"92214", "Karachi",
"926082", "Lodhran",
"928249", "Loralai",
"925473", "Hafizabad",
"928473", "Kharan",
"92647", "Dera\ Ghazi\ Khan",
"925435", "Chakwal",
"92538", "Gujrat",
"929693", "Lakki\ Marwat",
"929425", "Bajaur\ Agency",
"92743", "Larkana",
"92223", "Hyderabad",
"929927", "Abottabad",
"929387", "Swabi",
"92447", "Okara",
"92484", "Sargodha",
"929974", "Mansehra\/Batagram",
"92228", "Hyderabad",
"92748", "Larkana",
"92634", "Bahawalnagar",
"925432", "Chakwal",
"928559", "Panjgur",
"929422", "Bajaur\ Agency",
"924549", "Khushab",
"925444", "Jhelum",
"924597", "Mianwali",
"92684", "Rahim\ Yar\ Khan",
"926066", "Layyah",
"92254", "Dadu",
"92998", "Kohistan",
"92533", "Gujrat",
"928485", "Khuzdar",
"928444", "Kalat",
"929463", "Swat",
"92535", "Gujrat",
"928432", "Mastung",
"928327", "Bolan",
"926085", "Lodhran",
"926044", "Rajanpur",
"929448", "Upper\ Dir",
"928539", "Lasbela",
"925466", "Mandi\ Bahauddin",
"928257", "Chagai",
"92229", "Hyderabad",
"92749", "Larkana",
"929227", "Kohat",
"922425", "Naushero\ Feroze",
"927225", "Jacobabad",
"92575", "Attock",
"929633", "Tank",
"928246", "Loralai",
"92522", "Sialkot",
"922387", "Umerkot",
"92923", "Nowshera",
"92612", "Multan",
"929653", "South\ Waziristan",
"92674", "Vehari",
"928565", "Awaran",
"92925", "Hangu\/Orakzai\ Agy",
"92662", "Muzaffargarh",
"92914", "Peshawar\/Charsadda",
"92474", "Jhang",
"928237", "Killa\ Saifullah",
"92462", "Toba\ Tek\ Singh",
"924578", "Pakpattan",
"92412", "Faisalabad",
"92573", "Attock",
"928264", "K\.Abdullah\/Pishin",
"928352", "Dera\ Bugti",
"926068", "Layyah",
"922449", "Nawabshah",
"929464", "Swat",
"929437", "Chitral",
"928443", "Kalat",
"929322", "Malakand",
"925427", "Narowal",
"92644", "Dera\ Ghazi\ Khan",
"92405", "Sahiwal",
"92444", "Okara",
"926043", "Rajanpur",
"928385", "Jaffarabad\/Nasirabad",
"92403", "Sahiwal",
"929446", "Upper\ Dir",
"925468", "Mandi\ Bahauddin",
"929973", "Mansehra\/Batagram",
"929955", "Haripur",
"928332", "Sibi\/Ziarat",
"925443", "Jhelum",
"929457", "Lower\ Dir",
"92217", "Karachi",
"928248", "Loralai",
"922985", "Thatta",
"929969", "Shangla",
"922325", "Tharparkar",
"929654", "South\ Waziristan",
"929379", "Mardan",
"92426", "Lahore",
"928263", "K\.Abdullah\/Pishin",
"92816", "Quetta",
"92626", "Bahawalpur",
"92866", "Gwadar",
"92566", "Sheikhupura",
"924576", "Pakpattan",
"92516", "Islamabad\/Rawalpindi",
"929667", "D\.I\.\ Khan",
"928222", "Zhob",
"929634", "Tank",
"92677", "Vehari",
"928524", "Kech",
"922446", "Nawabshah",
"922973", "Badin",
"924548", "Khushab",
"928558", "Panjgur",
"928225", "Zhob",
"92477", "Jhang",
"92917", "Peshawar\/Charsadda",
"92409", "Sahiwal",
"927264", "Shikarpur",
"929449", "Upper\ Dir",
"928538", "Lasbela",
"92556", "Gujranwala",
"922982", "Thatta",
"922322", "Tharparkar",
"927237", "Ghotki",
"922437", "Khairpur",
"928382", "Jaffarabad\/Nasirabad",
"929694", "Lakki\ Marwat",
"929966", "Shangla",
"928474", "Kharan",
"929376", "Mardan",
"929952", "Haripur",
"92408", "Sahiwal",
"928335", "Sibi\/Ziarat",
"928355", "Dera\ Bugti",
"92637", "Bahawalnagar",
"928373", "Jhal\ Magsi",
"924579", "Pakpattan",
"929325", "Malakand",
"92487", "Sargodha",
"925474", "Hafizabad",
"92687", "Rahim\ Yar\ Khan",
"92257", "Dadu",
"92496", "Kasur",
"928234", "Killa\ Saifullah",
"92718", "Sukkur",
"92576", "Attock",
"928489", "Khuzdar",
"928267", "K\.Abdullah\/Pishin",
"928535", "Lasbela",
"926089", "Lodhran",
"928242", "Loralai",
"92657", "Khanewal",
"928555", "Panjgur",
"924545", "Khushab",
"928228", "Zhob",
"92926", "Kurram\ Agency",
"929663", "D\.I\.\ Khan",
"922384", "Umerkot",
"928254", "Chagai",
"929224", "Kohat",
"928324", "Bolan",
"929426", "Bajaur\ Agency",
"925436", "Chakwal",
"928569", "Awaran",
"92719", "Sukkur",
"926047", "Rajanpur",
"928358", "Dera\ Bugti",
"926062", "Layyah",
"928447", "Kalat",
"929433", "Chitral",
"925423", "Narowal",
"929328", "Malakand",
"928338", "Sibi\/Ziarat",
"929453", "Lower\ Dir",
"922429", "Naushero\ Feroze",
"927229", "Jacobabad",
"92536", "Gujrat",
"924594", "Mianwali",
"925447", "Jhelum",
"92642", "Dera\ Ghazi\ Khan",
"929977", "Mansehra\/Batagram",
"925462", "Mandi\ Bahauddin",
"92442", "Okara",
"928436", "Mastung",
"92226", "Hyderabad",
"92746", "Larkana",
"928486", "Khuzdar",
"929384", "Swabi",
"929924", "Abottabad",
"928388", "Jaffarabad\/Nasirabad",
"925465", "Mandi\ Bahauddin",
"926086", "Lodhran",
"929958", "Haripur",
"926065", "Layyah",
"928294", "Barkhan\/Kohlu",
"928377", "Jhal\ Magsi",
"924542", "Khushab",
"928552", "Panjgur",
"929429", "Bajaur\ Agency",
"92715", "Sukkur",
"925439", "Chakwal",
"928566", "Awaran",
"929394", "Buner",
"924534", "Bhakkar",
"92527", "Sialkot",
"922977", "Badin",
"922334", "Mirpur\ Khas",
"922426", "Naushero\ Feroze",
"927226", "Jacobabad",
"92667", "Muzaffargarh",
"92617", "Multan",
"922354", "Sanghar",
"92417", "Faisalabad",
"928532", "Lasbela",
"92713", "Sukkur",
"927233", "Ghotki",
"928284", "Musakhel",
"922433", "Khairpur",
"928245", "Loralai",
"928439", "Mastung",
"922988", "Thatta",
"922328", "Tharparkar",
"92467", "Toba\ Tek\ Singh",};
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