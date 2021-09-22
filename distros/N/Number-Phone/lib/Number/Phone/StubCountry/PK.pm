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
our $VERSION = 1.20210921211833;

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
$areanames{en} = {"92259", "Dadu",
"92216", "Karachi",
"92448", "Okara",
"926062", "Layyah",
"92469", "Toba\ Tek\ Singh",
"92676", "Vehari",
"928443", "Kalat",
"92493", "Kasur",
"92629", "Bahawalpur",
"929439", "Chitral",
"928389", "Jaffarabad\/Nasirabad",
"925468", "Mandi\ Bahauddin",
"929378", "Mardan",
"928286", "Musakhel",
"92554", "Gujranwala",
"928387", "Jaffarabad\/Nasirabad",
"929437", "Chitral",
"928482", "Khuzdar",
"92637", "Bahawalnagar",
"92866", "Gwadar",
"92675", "Vehari",
"928538", "Lasbela",
"925428", "Narowal",
"928243", "Loralai",
"922355", "Sanghar",
"927239", "Ghotki",
"928295", "Barkhan\/Kohlu",
"92817", "Quetta",
"922354", "Sanghar",
"928294", "Barkhan\/Kohlu",
"928374", "Jhal\ Magsi",
"92428", "Lahore",
"927237", "Ghotki",
"92714", "Sukkur",
"92862", "Gwadar",
"928375", "Jhal\ Magsi",
"926066", "Layyah",
"92215", "Karachi",
"928282", "Musakhel",
"92668", "Muzaffargarh",
"92865", "Gwadar",
"92533", "Gujrat",
"92914", "Peshawar\/Charsadda",
"92212", "Karachi",
"92672", "Vehari",
"929393", "Buner",
"922325", "Tharparkar",
"929975", "Mansehra\/Batagram",
"928486", "Khuzdar",
"922324", "Tharparkar",
"92649", "Dera\ Ghazi\ Khan",
"92408", "Sahiwal",
"929974", "Mansehra\/Batagram",
"92576", "Attock",
"928247", "Loralai",
"929695", "Lakki\ Marwat",
"92813", "Quetta",
"929694", "Lakki\ Marwat",
"925422", "Narowal",
"927233", "Ghotki",
"928532", "Lasbela",
"928334", "Sibi\/Ziarat",
"928249", "Loralai",
"928335", "Sibi\/Ziarat",
"92224", "Hyderabad",
"92746", "Larkana",
"929399", "Buner",
"92537", "Gujrat",
"92925", "Hangu\/Orakzai\ Agy",
"929397", "Buner",
"928288", "Musakhel",
"929376", "Mardan",
"92529", "Sialkot",
"92654", "Khanewal",
"925466", "Mandi\ Bahauddin",
"92688", "Rahim\ Yar\ Khan",
"926068", "Layyah",
"92489", "Sargodha",
"928449", "Kalat",
"92745", "Larkana",
"92575", "Attock",
"925426", "Narowal",
"928447", "Kalat",
"928536", "Lasbela",
"92497", "Kasur",
"92572", "Attock",
"928488", "Khuzdar",
"92568", "Sheikhupura",
"928383", "Jaffarabad\/Nasirabad",
"929433", "Chitral",
"925462", "Mandi\ Bahauddin",
"92926", "Kurram\ Agency",
"929372", "Mardan",
"92633", "Bahawalnagar",
"92742", "Larkana",
"92482", "Sargodha",
"92413", "Faisalabad",
"925479", "Hafizabad",
"924578", "Pakpattan",
"929456", "Lower\ Dir",
"928523", "Kech",
"925477", "Hafizabad",
"925433", "Chakwal",
"927222", "Jacobabad",
"929462", "Swat",
"924532", "Bhakkar",
"922985", "Thatta",
"92526", "Sialkot",
"9258", "AJK\/FATA",
"922984", "Thatta",
"92614", "Multan",
"928553", "Panjgur",
"929664", "D\.I\.\ Khan",
"929665", "D\.I\.\ Khan",
"92579", "Attock",
"929222", "Kohat",
"92485", "Sargodha",
"922434", "Khairpur",
"92749", "Larkana",
"922435", "Khairpur",
"922446", "Nawabshah",
"927266", "Shikarpur",
"929426", "Bajaur\ Agency",
"929452", "Lower\ Dir",
"922388", "Umerkot",
"92525", "Sialkot",
"924544", "Khushab",
"929466", "Swat",
"924536", "Bhakkar",
"924545", "Khushab",
"924593", "Mianwali",
"927226", "Jacobabad",
"929226", "Kohat",
"92486", "Sargodha",
"922979", "Badin",
"929329", "Malakand",
"929654", "South\ Waziristan",
"929422", "Bajaur\ Agency",
"928563", "Awaran",
"927262", "Shikarpur",
"922442", "Nawabshah",
"929327", "Malakand",
"929655", "South\ Waziristan",
"922977", "Badin",
"92522", "Sialkot",
"92645", "Dera\ Ghazi\ Khan",
"928224", "Zhob",
"92514", "Islamabad\/Rawalpindi",
"924599", "Mianwali",
"928225", "Zhob",
"92626", "Bahawalpur",
"92869", "Gwadar",
"929458", "Lower\ Dir",
"926084", "Lodhran",
"922382", "Umerkot",
"924576", "Pakpattan",
"926085", "Lodhran",
"924597", "Mianwali",
"928569", "Awaran",
"929428", "Bajaur\ Agency",
"922448", "Nawabshah",
"927268", "Shikarpur",
"92219", "Karachi",
"92256", "Dadu",
"92642", "Dera\ Ghazi\ Khan",
"928254", "Chagai",
"928567", "Awaran",
"92679", "Vehari",
"929323", "Malakand",
"92466", "Toba\ Tek\ Singh",
"922973", "Badin",
"928255", "Chagai",
"927228", "Jacobabad",
"92417", "Faisalabad",
"924538", "Bhakkar",
"929468", "Swat",
"928529", "Kech",
"925439", "Chakwal",
"92252", "Dadu",
"92478", "Jhang",
"925437", "Chakwal",
"925473", "Hafizabad",
"92646", "Dera\ Ghazi\ Khan",
"928527", "Kech",
"922386", "Umerkot",
"924572", "Pakpattan",
"92625", "Bahawalpur",
"92462", "Toba\ Tek\ Singh",
"928557", "Panjgur",
"928264", "K\.Abdullah\/Pishin",
"928265", "K\.Abdullah\/Pishin",
"92622", "Bahawalpur",
"92465", "Toba\ Tek\ Singh",
"928559", "Panjgur",
"92255", "Dadu",
"929228", "Kohat",
"928328", "Bolan",
"92916", "Peshawar\/Charsadda",
"922989", "Thatta",
"925474", "Hafizabad",
"929958", "Haripur",
"922987", "Thatta",
"925475", "Hafizabad",
"92555", "Gujranwala",
"922439", "Khairpur",
"929667", "D\.I\.\ Khan",
"928263", "K\.Abdullah\/Pishin",
"929928", "Abottabad",
"92552", "Gujranwala",
"92716", "Sukkur",
"929669", "D\.I\.\ Khan",
"922437", "Khairpur",
"928358", "Dera\ Bugti",
"926046", "Rajanpur",
"922332", "Mirpur\ Khas",
"928223", "Zhob",
"92519", "Islamabad\/Rawalpindi",
"925448", "Jhelum",
"924549", "Khushab",
"92556", "Gujranwala",
"929968", "Shangla",
"926083", "Lodhran",
"92712", "Sukkur",
"924547", "Khushab",
"92864", "Gwadar",
"92915", "Peshawar\/Charsadda",
"929659", "South\ Waziristan",
"92715", "Sukkur",
"92912", "Peshawar\/Charsadda",
"92473", "Jhang",
"92214", "Karachi",
"922975", "Badin",
"928253", "Chagai",
"92674", "Vehari",
"922336", "Mirpur\ Khas",
"929657", "South\ Waziristan",
"926042", "Rajanpur",
"929325", "Malakand",
"922974", "Badin",
"929324", "Malakand",
"928227", "Zhob",
"926089", "Lodhran",
"929956", "Haripur",
"92655", "Khanewal",
"925442", "Jhelum",
"926087", "Lodhran",
"924595", "Mianwali",
"924543", "Khushab",
"928229", "Zhob",
"928326", "Bolan",
"924594", "Mianwali",
"92222", "Hyderabad",
"92924", "Khyber\/Mohmand\ Agy",
"929962", "Shangla",
"92418", "Faisalabad",
"928259", "Chagai",
"926048", "Rajanpur",
"928356", "Dera\ Bugti",
"92225", "Hyderabad",
"92477", "Jhang",
"928564", "Awaran",
"928257", "Chagai",
"929653", "South\ Waziristan",
"929926", "Abottabad",
"928565", "Awaran",
"92652", "Khanewal",
"929952", "Haripur",
"929966", "Shangla",
"928524", "Kech",
"925434", "Chakwal",
"92619", "Multan",
"928322", "Bolan",
"922983", "Thatta",
"925446", "Jhelum",
"928525", "Kech",
"92656", "Khanewal",
"925435", "Chakwal",
"929663", "D\.I\.\ Khan",
"928267", "K\.Abdullah\/Pishin",
"928554", "Panjgur",
"92574", "Attock",
"928352", "Dera\ Bugti",
"922338", "Mirpur\ Khas",
"928555", "Panjgur",
"928269", "K\.Abdullah\/Pishin",
"922433", "Khairpur",
"929922", "Abottabad",
"92226", "Hyderabad",
"92744", "Larkana",
"92667", "Muzaffargarh",
"92484", "Sargodha",
"929632", "Tank",
"928476", "Kharan",
"928238", "Killa\ Saifullah",
"92407", "Sahiwal",
"92612", "Multan",
"92683", "Rahim\ Yar\ Khan",
"92818", "Quetta",
"92615", "Multan",
"92427", "Lahore",
"928384", "Jaffarabad\/Nasirabad",
"929434", "Chitral",
"922426", "Naushero\ Feroze",
"929446", "Upper\ Dir",
"929435", "Chitral",
"928385", "Jaffarabad\/Nasirabad",
"928379", "Jhal\ Magsi",
"928297", "Barkhan\/Kohlu",
"929636", "Tank",
"928438", "Mastung",
"929693", "Lakki\ Marwat",
"929388", "Swabi",
"922357", "Sanghar",
"92229", "Hyderabad",
"92563", "Sheikhupura",
"927234", "Ghotki",
"928377", "Jhal\ Magsi",
"928333", "Sibi\/Ziarat",
"922359", "Sanghar",
"92638", "Bahawalnagar",
"927235", "Ghotki",
"928472", "Kharan",
"928299", "Barkhan\/Kohlu",
"92447", "Okara",
"922329", "Tharparkar",
"929979", "Mansehra\/Batagram",
"92659", "Khanewal",
"929442", "Upper\ Dir",
"922422", "Naushero\ Feroze",
"929977", "Mansehra\/Batagram",
"92616", "Multan",
"92524", "Sialkot",
"922327", "Tharparkar",
"928339", "Sibi\/Ziarat",
"928244", "Loralai",
"92498", "Kasur",
"928293", "Barkhan\/Kohlu",
"92512", "Islamabad\/Rawalpindi",
"922353", "Sanghar",
"928236", "Killa\ Saifullah",
"929697", "Lakki\ Marwat",
"928478", "Kharan",
"928245", "Loralai",
"928373", "Jhal\ Magsi",
"928337", "Sibi\/Ziarat",
"92567", "Sheikhupura",
"929699", "Lakki\ Marwat",
"928432", "Mastung",
"929382", "Swabi",
"92719", "Sukkur",
"92919", "Peshawar\/Charsadda",
"929448", "Upper\ Dir",
"922428", "Naushero\ Feroze",
"92443", "Okara",
"92644", "Dera\ Ghazi\ Khan",
"929394", "Buner",
"92515", "Islamabad\/Rawalpindi",
"929973", "Mansehra\/Batagram",
"922323", "Tharparkar",
"929395", "Buner",
"928232", "Killa\ Saifullah",
"92663", "Muzaffargarh",
"92254", "Dadu",
"92538", "Gujrat",
"928445", "Kalat",
"928436", "Mastung",
"929386", "Swabi",
"929638", "Tank",
"928444", "Kalat",
"92403", "Sahiwal",
"92464", "Toba\ Tek\ Singh",
"92687", "Rahim\ Yar\ Khan",
"92559", "Gujranwala",
"92624", "Bahawalpur",
"92516", "Islamabad\/Rawalpindi",
"92423", "Lahore",
"928484", "Khuzdar",
"92657", "Khanewal",
"92468", "Toba\ Tek\ Singh",
"928485", "Khuzdar",
"929976", "Mansehra\/Batagram",
"922326", "Tharparkar",
"92472", "Jhang",
"92258", "Dadu",
"92913", "Peshawar\/Charsadda",
"92534", "Gujrat",
"92449", "Okara",
"92475", "Jhang",
"926065", "Layyah",
"928376", "Jhal\ Magsi",
"92227", "Hyderabad",
"92713", "Sukkur",
"926064", "Layyah",
"929639", "Tank",
"92628", "Bahawalpur",
"929637", "Tank",
"928296", "Barkhan\/Kohlu",
"922356", "Sanghar",
"928233", "Killa\ Saifullah",
"92429", "Lahore",
"922322", "Tharparkar",
"929972", "Mansehra\/Batagram",
"922427", "Naushero\ Feroze",
"929447", "Upper\ Dir",
"92553", "Gujranwala",
"928285", "Musakhel",
"929449", "Upper\ Dir",
"928284", "Musakhel",
"92494", "Kasur",
"922429", "Naushero\ Feroze",
"929698", "Lakki\ Marwat",
"928433", "Mastung",
"929383", "Swabi",
"928477", "Kharan",
"928372", "Jhal\ Magsi",
"92409", "Sahiwal",
"92648", "Dera\ Ghazi\ Khan",
"922352", "Sanghar",
"92669", "Muzaffargarh",
"928479", "Kharan",
"92476", "Jhang",
"928292", "Barkhan\/Kohlu",
"928338", "Sibi\/Ziarat",
"92634", "Bahawalnagar",
"922423", "Naushero\ Feroze",
"929443", "Upper\ Dir",
"92557", "Gujranwala",
"922328", "Tharparkar",
"929978", "Mansehra\/Batagram",
"928437", "Mastung",
"929387", "Swabi",
"928473", "Kharan",
"925425", "Narowal",
"928535", "Lasbela",
"922358", "Sanghar",
"92528", "Sialkot",
"928298", "Barkhan\/Kohlu",
"928332", "Sibi\/Ziarat",
"92689", "Rahim\ Yar\ Khan",
"925424", "Narowal",
"928534", "Lasbela",
"929692", "Lakki\ Marwat",
"929389", "Swabi",
"928439", "Mastung",
"928378", "Jhal\ Magsi",
"929374", "Mardan",
"925465", "Mandi\ Bahauddin",
"92653", "Khanewal",
"929375", "Mardan",
"925464", "Mandi\ Bahauddin",
"92917", "Peshawar\/Charsadda",
"92488", "Sargodha",
"92569", "Sheikhupura",
"928336", "Sibi\/Ziarat",
"92223", "Hyderabad",
"928239", "Killa\ Saifullah",
"92717", "Sukkur",
"92814", "Quetta",
"929633", "Tank",
"929696", "Lakki\ Marwat",
"928237", "Killa\ Saifullah",
"922337", "Mirpur\ Khas",
"929656", "South\ Waziristan",
"929923", "Abottabad",
"92686", "Rahim\ Yar\ Khan",
"928268", "K\.Abdullah\/Pishin",
"922432", "Khairpur",
"922339", "Mirpur\ Khas",
"929224", "Kohat",
"928353", "Dera\ Bugti",
"92565", "Sheikhupura",
"929662", "D\.I\.\ Khan",
"929225", "Kohat",
"927225", "Jacobabad",
"924535", "Bhakkar",
"929465", "Swat",
"924546", "Khushab",
"92748", "Larkana",
"922982", "Thatta",
"928323", "Bolan",
"927224", "Jacobabad",
"92562", "Sheikhupura",
"929464", "Swat",
"924534", "Bhakkar",
"92517", "Islamabad\/Rawalpindi",
"929953", "Haripur",
"92578", "Attock",
"929425", "Bajaur\ Agency",
"922436", "Khairpur",
"92928", "Bannu\/N\.\ Waziristan",
"927265", "Shikarpur",
"922445", "Nawabshah",
"929424", "Bajaur\ Agency",
"926047", "Rajanpur",
"929652", "South\ Waziristan",
"927264", "Shikarpur",
"92566", "Sheikhupura",
"922444", "Nawabshah",
"92685", "Rahim\ Yar\ Khan",
"929666", "D\.I\.\ Khan",
"928258", "Chagai",
"926049", "Rajanpur",
"929963", "Shangla",
"92682", "Rahim\ Yar\ Khan",
"92613", "Multan",
"922986", "Thatta",
"924542", "Khushab",
"928228", "Zhob",
"925443", "Jhelum",
"929455", "Lower\ Dir",
"929454", "Lower\ Dir",
"926088", "Lodhran",
"92414", "Faisalabad",
"92868", "Gwadar",
"926043", "Rajanpur",
"92422", "Lahore",
"92665", "Muzaffargarh",
"928252", "Chagai",
"92405", "Sahiwal",
"928266", "K\.Abdullah\/Pishin",
"929658", "South\ Waziristan",
"929967", "Shangla",
"922384", "Umerkot",
"92617", "Multan",
"92402", "Sahiwal",
"922385", "Umerkot",
"92678", "Vehari",
"926082", "Lodhran",
"925447", "Jhelum",
"92446", "Okara",
"92218", "Karachi",
"929969", "Shangla",
"925449", "Jhelum",
"92425", "Lahore",
"924548", "Khushab",
"92662", "Muzaffargarh",
"928222", "Zhob",
"928256", "Chagai",
"92406", "Sahiwal",
"922333", "Mirpur\ Khas",
"929927", "Abottabad",
"929668", "D\.I\.\ Khan",
"928359", "Dera\ Bugti",
"929929", "Abottabad",
"92442", "Okara",
"928262", "K\.Abdullah\/Pishin",
"922438", "Khairpur",
"92479", "Jhang",
"92666", "Muzaffargarh",
"928357", "Dera\ Bugti",
"929959", "Haripur",
"926086", "Lodhran",
"92445", "Okara",
"924575", "Pakpattan",
"928327", "Bolan",
"924574", "Pakpattan",
"92426", "Lahore",
"928226", "Zhob",
"929957", "Haripur",
"92513", "Islamabad\/Rawalpindi",
"922988", "Thatta",
"928329", "Bolan",
"922334", "Mirpur\ Khas",
"929229", "Kohat",
"929326", "Malakand",
"922335", "Mirpur\ Khas",
"92673", "Vehari",
"928558", "Panjgur",
"922976", "Badin",
"92213", "Karachi",
"92474", "Jhang",
"929227", "Kohat",
"92532", "Gujrat",
"92927", "Karak",
"92863", "Gwadar",
"92535", "Gujrat",
"924537", "Bhakkar",
"929467", "Swat",
"924573", "Pakpattan",
"927227", "Jacobabad",
"925472", "Hafizabad",
"92496", "Kasur",
"927229", "Jacobabad",
"924539", "Bhakkar",
"929469", "Swat",
"925438", "Chakwal",
"928528", "Kech",
"922972", "Badin",
"92747", "Larkana",
"926045", "Rajanpur",
"929322", "Malakand",
"922447", "Nawabshah",
"927267", "Shikarpur",
"926044", "Rajanpur",
"929427", "Bajaur\ Agency",
"92518", "Islamabad\/Rawalpindi",
"928568", "Awaran",
"929429", "Bajaur\ Agency",
"92577", "Attock",
"927269", "Shikarpur",
"922449", "Nawabshah",
"92492", "Kasur",
"925476", "Hafizabad",
"922383", "Umerkot",
"929459", "Lower\ Dir",
"92495", "Kasur",
"92536", "Gujrat",
"924598", "Mianwali",
"929457", "Lower\ Dir",
"92743", "Larkana",
"92632", "Bahawalnagar",
"928562", "Awaran",
"927263", "Shikarpur",
"922443", "Nawabshah",
"929423", "Bajaur\ Agency",
"92998", "Kohistan",
"928556", "Panjgur",
"922978", "Badin",
"929328", "Malakand",
"92573", "Attock",
"92816", "Quetta",
"925445", "Jhelum",
"928526", "Kech",
"925436", "Chakwal",
"924592", "Mianwali",
"922387", "Umerkot",
"929964", "Shangla",
"925444", "Jhelum",
"929965", "Shangla",
"922389", "Umerkot",
"92635", "Bahawalnagar",
"92419", "Faisalabad",
"929453", "Lower\ Dir",
"929924", "Abottabad",
"92618", "Multan",
"928566", "Awaran",
"929925", "Abottabad",
"92815", "Quetta",
"92677", "Vehari",
"929223", "Kohat",
"92217", "Karachi",
"928355", "Dera\ Bugti",
"928354", "Dera\ Bugti",
"928552", "Panjgur",
"92923", "Nowshera",
"92867", "Gwadar",
"92636", "Bahawalnagar",
"928325", "Bolan",
"929463", "Swat",
"924577", "Pakpattan",
"924533", "Bhakkar",
"924596", "Mianwali",
"928324", "Bolan",
"928522", "Kech",
"925432", "Chakwal",
"927223", "Jacobabad",
"929954", "Haripur",
"929955", "Haripur",
"92812", "Quetta",
"925478", "Hafizabad",
"924579", "Pakpattan",
"92523", "Sialkot",
"928487", "Khuzdar",
"929373", "Mardan",
"925463", "Mandi\ Bahauddin",
"92647", "Dera\ Ghazi\ Khan",
"928382", "Jaffarabad\/Nasirabad",
"929432", "Chitral",
"928489", "Khuzdar",
"92416", "Faisalabad",
"927236", "Ghotki",
"92564", "Sheikhupura",
"926067", "Layyah",
"92819", "Quetta",
"928448", "Kalat",
"929635", "Tank",
"926069", "Layyah",
"929634", "Tank",
"929445", "Upper\ Dir",
"929436", "Chitral",
"928386", "Jaffarabad\/Nasirabad",
"92228", "Hyderabad",
"922425", "Naushero\ Feroze",
"929444", "Upper\ Dir",
"92639", "Bahawalnagar",
"922424", "Naushero\ Feroze",
"928289", "Musakhel",
"92415", "Faisalabad",
"92627", "Bahawalpur",
"928287", "Musakhel",
"929398", "Buner",
"92467", "Toba\ Tek\ Singh",
"92684", "Rahim\ Yar\ Khan",
"92658", "Khanewal",
"928474", "Kharan",
"928475", "Kharan",
"925423", "Narowal",
"928248", "Loralai",
"927232", "Ghotki",
"928533", "Lasbela",
"92257", "Dadu",
"92412", "Faisalabad",
"92483", "Sargodha",
"92424", "Lahore",
"929392", "Buner",
"92718", "Sukkur",
"92623", "Bahawalpur",
"92499", "Kasur",
"928283", "Musakhel",
"92463", "Toba\ Tek\ Singh",
"92404", "Sahiwal",
"929384", "Swabi",
"928434", "Mastung",
"928446", "Kalat",
"928537", "Lasbela",
"929385", "Swabi",
"925427", "Narowal",
"928435", "Mastung",
"92918", "Peshawar\/Charsadda",
"92253", "Dadu",
"925429", "Narowal",
"928539", "Lasbela",
"92664", "Muzaffargarh",
"92487", "Sargodha",
"927238", "Ghotki",
"928242", "Loralai",
"929396", "Buner",
"92527", "Sialkot",
"928483", "Khuzdar",
"929377", "Mardan",
"925467", "Mandi\ Bahauddin",
"92643", "Dera\ Ghazi\ Khan",
"929379", "Mardan",
"92444", "Okara",
"929438", "Chitral",
"928388", "Jaffarabad\/Nasirabad",
"925469", "Mandi\ Bahauddin",
"92539", "Gujrat",
"928442", "Kalat",
"926063", "Layyah",
"928235", "Killa\ Saifullah",
"928246", "Loralai",
"92558", "Gujranwala",
"928234", "Killa\ Saifullah",};

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