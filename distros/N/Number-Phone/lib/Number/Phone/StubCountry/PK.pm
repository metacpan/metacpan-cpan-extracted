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
our $VERSION = 1.20250323211834;

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
$areanames{en} = {"92522", "Sialkot",
"928338", "Sibi\/Ziarat",
"927226", "Jacobabad",
"92487", "Sargodha",
"922385", "Umerkot",
"926082", "Lodhran",
"92923", "Nowshera",
"92539", "Gujrat",
"927233", "Ghotki",
"92535", "Gujrat",
"928525", "Kech",
"929979", "Mansehra\/Batagram",
"929464", "Swat",
"929422", "Bajaur\ Agency",
"929323", "Malakand",
"92643", "Dera\ Ghazi\ Khan",
"922444", "Nawabshah",
"929662", "D\.I\.\ Khan",
"922978", "Badin",
"928434", "Mastung",
"924544", "Khushab",
"929953", "Haripur",
"92576", "Attock",
"925432", "Chakwal",
"922337", "Mirpur\ Khas",
"925448", "Jhelum",
"92252", "Dadu",
"92466", "Toba\ Tek\ Singh",
"92442", "Okara",
"926087", "Lodhran",
"92677", "Vehari",
"929639", "Tank",
"929667", "D\.I\.\ Khan",
"929427", "Bajaur\ Agency",
"929375", "Mardan",
"92513", "Islamabad\/Rawalpindi",
"924533", "Bhakkar",
"922426", "Naushero\ Feroze",
"922433", "Khairpur",
"928443", "Kalat",
"92912", "Peshawar\/Charsadda",
"928559", "Panjgur",
"922332", "Mirpur\ Khas",
"925469", "Mandi\ Bahauddin",
"925437", "Chakwal",
"922989", "Thatta",
"928286", "Musakhel",
"928234", "Killa\ Saifullah",
"929964", "Shangla",
"92623", "Bahawalpur",
"927265", "Shikarpur",
"929222", "Kohat",
"929922", "Abottabad",
"92749", "Larkana",
"929392", "Buner",
"924578", "Pakpattan",
"928566", "Awaran",
"92745", "Larkana",
"929453", "Lower\ Dir",
"92413", "Faisalabad",
"92817", "Quetta",
"928295", "Barkhan\/Kohlu",
"92566", "Sheikhupura",
"92686", "Rahim\ Yar\ Khan",
"928538", "Lasbela",
"928255", "Chagai",
"92862", "Gwadar",
"929698", "Lakki\ Marwat",
"928477", "Kharan",
"92555", "Gujranwala",
"928325", "Bolan",
"92559", "Gujranwala",
"929658", "South\ Waziristan",
"929927", "Abottabad",
"92476", "Jhang",
"928229", "Zhob",
"929227", "Kohat",
"929384", "Swabi",
"928486", "Khuzdar",
"922356", "Sanghar",
"929397", "Buner",
"928359", "Dera\ Bugti",
"928243", "Loralai",
"92612", "Multan",
"925474", "Hafizabad",
"929445", "Upper\ Dir",
"92492", "Kasur",
"92667", "Muzaffargarh",
"92229", "Hyderabad",
"928472", "Kharan",
"92225", "Hyderabad",
"928373", "Jhal\ Magsi",
"92422", "Lahore",
"92408", "Sahiwal",
"926063", "Layyah",
"92813", "Quetta",
"92634", "Bahawalnagar",
"92214", "Karachi",
"922334", "Mirpur\ Khas",
"925429", "Narowal",
"924547", "Khushab",
"92916", "Peshawar\/Charsadda",
"925443", "Jhelum",
"928437", "Mastung",
"922447", "Nawabshah",
"929439", "Chitral",
"929467", "Swat",
"929446", "Upper\ Dir",
"928485", "Khuzdar",
"92627", "Bahawalpur",
"922438", "Khairpur",
"922355", "Sanghar",
"928448", "Kalat",
"92446", "Okara",
"92462", "Toba\ Tek\ Singh",
"924538", "Bhakkar",
"92256", "Dadu",
"92417", "Faisalabad",
"92538", "Gujrat",
"924542", "Khushab",
"922329", "Tharparkar",
"92572", "Attock",
"928326", "Bolan",
"925434", "Chakwal",
"927238", "Ghotki",
"928296", "Barkhan\/Kohlu",
"92663", "Muzaffargarh",
"929462", "Swat",
"928333", "Sibi\/Ziarat",
"929664", "D\.I\.\ Khan",
"922442", "Nawabshah",
"928432", "Mastung",
"928256", "Chagai",
"929424", "Bajaur\ Agency",
"929958", "Haripur",
"926084", "Lodhran",
"928565", "Awaran",
"929328", "Malakand",
"927266", "Shikarpur",
"922973", "Badin",
"92526", "Sialkot",
"928248", "Loralai",
"92426", "Lahore",
"928285", "Musakhel",
"92647", "Dera\ Ghazi\ Khan",
"92496", "Kasur",
"928474", "Kharan",
"92558", "Gujranwala",
"929376", "Mardan",
"926049", "Rajanpur",
"925472", "Hafizabad",
"92616", "Multan",
"922425", "Naushero\ Feroze",
"928378", "Jhal\ Magsi",
"926068", "Layyah",
"92483", "Sargodha",
"92654", "Khanewal",
"92927", "Karak",
"928237", "Killa\ Saifullah",
"928269", "K\.Abdullah\/Pishin",
"929382", "Swabi",
"92748", "Larkana",
"92472", "Jhang",
"929967", "Shangla",
"92673", "Vehari",
"929458", "Lower\ Dir",
"92517", "Islamabad\/Rawalpindi",
"924573", "Pakpattan",
"92714", "Sukkur",
"92866", "Gwadar",
"925477", "Hafizabad",
"92562", "Sheikhupura",
"92409", "Sahiwal",
"92682", "Rahim\ Yar\ Khan",
"92405", "Sahiwal",
"92228", "Hyderabad",
"924599", "Mianwali",
"929653", "South\ Waziristan",
"929394", "Buner",
"928526", "Kech",
"929693", "Lakki\ Marwat",
"929224", "Kohat",
"929962", "Shangla",
"929387", "Swabi",
"928232", "Killa\ Saifullah",
"928533", "Lasbela",
"927225", "Jacobabad",
"928389", "Jaffarabad\/Nasirabad",
"929924", "Abottabad",
"922386", "Umerkot",
"924592", "Mianwali",
"929378", "Mardan",
"92486", "Sargodha",
"928483", "Khuzdar",
"928382", "Jaffarabad\/Nasirabad",
"929969", "Shangla",
"928246", "Loralai",
"922353", "Sanghar",
"928267", "K\.Abdullah\/Pishin",
"928239", "Killa\ Saifullah",
"925445", "Jhelum",
"92423", "Lahore",
"92493", "Kasur",
"92613", "Multan",
"926066", "Layyah",
"928376", "Jhal\ Magsi",
"926047", "Rajanpur",
"92577", "Attock",
"922975", "Badin",
"928354", "Dera\ Bugti",
"924597", "Mianwali",
"92412", "Faisalabad",
"92215", "Karachi",
"92635", "Bahawalnagar",
"92639", "Bahawalnagar",
"92219", "Karachi",
"928563", "Awaran",
"928262", "K\.Abdullah\/Pishin",
"929389", "Swabi",
"92467", "Toba\ Tek\ Singh",
"929456", "Lower\ Dir",
"928224", "Zhob",
"92622", "Bahawalpur",
"928387", "Jaffarabad\/Nasirabad",
"922388", "Umerkot",
"92676", "Vehari",
"92863", "Gwadar",
"928335", "Sibi\/Ziarat",
"926042", "Rajanpur",
"928528", "Kech",
"925479", "Hafizabad",
"929974", "Mansehra\/Batagram",
"929448", "Upper\ Dir",
"92719", "Sukkur",
"92443", "Okara",
"92715", "Sukkur",
"92253", "Dadu",
"92404", "Sahiwal",
"92816", "Quetta",
"922423", "Naushero\ Feroze",
"92913", "Peshawar\/Charsadda",
"922322", "Tharparkar",
"924549", "Khushab",
"925427", "Narowal",
"92567", "Sheikhupura",
"924536", "Bhakkar",
"92687", "Rahim\ Yar\ Khan",
"922449", "Nawabshah",
"928439", "Mastung",
"922436", "Khairpur",
"928446", "Kalat",
"929469", "Swat",
"929437", "Chitral",
"928283", "Musakhel",
"92512", "Islamabad\/Rawalpindi",
"928535", "Lasbela",
"928258", "Chagai",
"92477", "Jhang",
"928298", "Barkhan\/Kohlu",
"927223", "Jacobabad",
"927236", "Ghotki",
"929655", "South\ Waziristan",
"92523", "Sialkot",
"928328", "Bolan",
"929695", "Lakki\ Marwat",
"92659", "Khanewal",
"925422", "Narowal",
"922327", "Tharparkar",
"92655", "Khanewal",
"922984", "Thatta",
"927268", "Shikarpur",
"929326", "Malakand",
"928554", "Panjgur",
"925464", "Mandi\ Bahauddin",
"929432", "Chitral",
"92642", "Dera\ Ghazi\ Khan",
"92666", "Muzaffargarh",
"929956", "Haripur",
"929634", "Tank",
"924575", "Pakpattan",
"926044", "Rajanpur",
"928568", "Awaran",
"92917", "Peshawar\/Charsadda",
"929955", "Haripur",
"92563", "Sheikhupura",
"924576", "Pakpattan",
"92683", "Rahim\ Yar\ Khan",
"928479", "Kharan",
"92672", "Vehari",
"929325", "Malakand",
"927235", "Ghotki",
"929656", "South\ Waziristan",
"92626", "Bahawalpur",
"928264", "K\.Abdullah\/Pishin",
"928222", "Zhob",
"928523", "Kech",
"929696", "Lakki\ Marwat",
"92447", "Okara",
"928536", "Lasbela",
"92257", "Dadu",
"928352", "Dera\ Bugti",
"92416", "Faisalabad",
"922383", "Umerkot",
"922435", "Khairpur",
"922358", "Sanghar",
"928445", "Kalat",
"928488", "Khuzdar",
"929373", "Mardan",
"924535", "Bhakkar",
"92534", "Gujrat",
"928227", "Zhob",
"92638", "Bahawalnagar",
"92218", "Karachi",
"92473", "Jhang",
"928384", "Jaffarabad\/Nasirabad",
"929929", "Abottabad",
"929229", "Kohat",
"9258", "AJK\/FATA",
"92482", "Sargodha",
"92527", "Sialkot",
"928357", "Dera\ Bugti",
"929399", "Buner",
"924594", "Mianwali",
"928323", "Bolan",
"92427", "Lahore",
"929434", "Chitral",
"92662", "Muzaffargarh",
"929632", "Tank",
"92497", "Kasur",
"92646", "Dera\ Ghazi\ Khan",
"925424", "Narowal",
"927228", "Jacobabad",
"928293", "Barkhan\/Kohlu",
"922339", "Mirpur\ Khas",
"925462", "Mandi\ Bahauddin",
"928552", "Panjgur",
"92617", "Multan",
"928253", "Chagai",
"92573", "Attock",
"928336", "Sibi\/Ziarat",
"922982", "Thatta",
"929455", "Lower\ Dir",
"92718", "Sukkur",
"922976", "Badin",
"927263", "Shikarpur",
"92926", "Kurram\ Agency",
"929977", "Mansehra\/Batagram",
"92224", "Hyderabad",
"92516", "Islamabad\/Rawalpindi",
"929429", "Bajaur\ Agency",
"929669", "D\.I\.\ Khan",
"929637", "Tank",
"926065", "Layyah",
"92867", "Gwadar",
"92658", "Khanewal",
"928375", "Jhal\ Magsi",
"922987", "Thatta",
"925446", "Jhelum",
"925439", "Chakwal",
"925467", "Mandi\ Bahauddin",
"928557", "Panjgur",
"92744", "Larkana",
"929443", "Upper\ Dir",
"92812", "Quetta",
"922324", "Tharparkar",
"928288", "Musakhel",
"928245", "Loralai",
"922428", "Naushero\ Feroze",
"92554", "Gujranwala",
"929972", "Mansehra\/Batagram",
"92463", "Toba\ Tek\ Singh",
"926089", "Lodhran",
"922338", "Mirpur\ Khas",
"92868", "Gwadar",
"928385", "Jaffarabad\/Nasirabad",
"927229", "Jacobabad",
"92657", "Khanewal",
"922977", "Badin",
"924595", "Mianwali",
"92924", "Khyber\/Mohmand\ Agy",
"92226", "Hyderabad",
"929976", "Mansehra\/Batagram",
"92475", "Jhang",
"92644", "Dera\ Ghazi\ Khan",
"928444", "Kalat",
"92479", "Jhang",
"922434", "Khairpur",
"924534", "Bhakkar",
"925442", "Jhelum",
"928337", "Sibi\/Ziarat",
"92428", "Lahore",
"92569", "Sheikhupura",
"92402", "Sahiwal",
"92689", "Rahim\ Yar\ Khan",
"92498", "Kasur",
"92685", "Rahim\ Yar\ Khan",
"927234", "Ghotki",
"92565", "Sheikhupura",
"928265", "K\.Abdullah\/Pishin",
"925438", "Chakwal",
"92556", "Gujranwala",
"92618", "Multan",
"929428", "Bajaur\ Agency",
"922972", "Badin",
"929668", "D\.I\.\ Khan",
"926088", "Lodhran",
"92514", "Islamabad\/Rawalpindi",
"929636", "Tank",
"929954", "Haripur",
"92717", "Sukkur",
"922429", "Naushero\ Feroze",
"924543", "Khushab",
"926045", "Rajanpur",
"928433", "Mastung",
"922443", "Nawabshah",
"928332", "Sibi\/Ziarat",
"922986", "Thatta",
"925447", "Jhelum",
"928556", "Panjgur",
"925466", "Mandi\ Bahauddin",
"929324", "Malakand",
"929463", "Swat",
"928289", "Musakhel",
"92746", "Larkana",
"928244", "Loralai",
"929657", "South\ Waziristan",
"92624", "Bahawalpur",
"928478", "Kharan",
"929697", "Lakki\ Marwat",
"928537", "Lasbela",
"928569", "Awaran",
"929383", "Swabi",
"92414", "Faisalabad",
"92217", "Karachi",
"92637", "Bahawalnagar",
"926064", "Layyah",
"928374", "Jhal\ Magsi",
"924577", "Pakpattan",
"92465", "Toba\ Tek\ Singh",
"922325", "Tharparkar",
"925473", "Hafizabad",
"92528", "Sialkot",
"92469", "Toba\ Tek\ Singh",
"928226", "Zhob",
"929692", "Lakki\ Marwat",
"929454", "Lower\ Dir",
"92918", "Peshawar\/Charsadda",
"929652", "South\ Waziristan",
"928489", "Khuzdar",
"92579", "Attock",
"92575", "Attock",
"929963", "Shangla",
"928356", "Dera\ Bugti",
"928532", "Lasbela",
"922359", "Sanghar",
"928233", "Killa\ Saifullah",
"929398", "Buner",
"924572", "Pakpattan",
"929435", "Chitral",
"92448", "Okara",
"929228", "Kohat",
"92258", "Dadu",
"925425", "Narowal",
"92536", "Gujrat",
"929928", "Abottabad",
"929322", "Malakand",
"92742", "Larkana",
"92213", "Karachi",
"92633", "Bahawalnagar",
"92814", "Quetta",
"929423", "Bajaur\ Agency",
"928334", "Sibi\/Ziarat",
"92478", "Jhang",
"929663", "D\.I\.\ Khan",
"925426", "Narowal",
"924537", "Bhakkar",
"929952", "Haripur",
"925433", "Chakwal",
"922437", "Khairpur",
"928447", "Kalat",
"929449", "Upper\ Dir",
"929436", "Chitral",
"92869", "Gwadar",
"929468", "Swat",
"928355", "Dera\ Bugti",
"928438", "Mastung",
"92552", "Gujranwala",
"922448", "Nawabshah",
"922974", "Badin",
"92865", "Gwadar",
"928225", "Zhob",
"924548", "Khushab",
"92406", "Sahiwal",
"926083", "Lodhran",
"927232", "Ghotki",
"928329", "Bolan",
"924532", "Bhakkar",
"922326", "Tharparkar",
"925444", "Jhelum",
"929327", "Malakand",
"92664", "Muzaffargarh",
"928299", "Barkhan\/Kohlu",
"922333", "Mirpur\ Khas",
"928442", "Kalat",
"928259", "Chagai",
"922432", "Khairpur",
"929957", "Haripur",
"92499", "Kasur",
"92425", "Lahore",
"92222", "Hyderabad",
"92429", "Lahore",
"92495", "Kasur",
"92568", "Sheikhupura",
"92688", "Rahim\ Yar\ Khan",
"92619", "Multan",
"927237", "Ghotki",
"927269", "Shikarpur",
"92615", "Multan",
"922985", "Thatta",
"929968", "Shangla",
"928238", "Killa\ Saifullah",
"928555", "Panjgur",
"925465", "Mandi\ Bahauddin",
"92532", "Gujrat",
"929379", "Mardan",
"92529", "Sialkot",
"924574", "Pakpattan",
"929635", "Tank",
"92468", "Toba\ Tek\ Singh",
"926067", "Layyah",
"928377", "Jhal\ Magsi",
"926046", "Rajanpur",
"92525", "Sialkot",
"929923", "Abottabad",
"92484", "Sargodha",
"928534", "Lasbela",
"929223", "Kohat",
"92653", "Khanewal",
"929694", "Lakki\ Marwat",
"929452", "Lower\ Dir",
"929654", "South\ Waziristan",
"928247", "Loralai",
"929393", "Buner",
"928266", "K\.Abdullah\/Pishin",
"92674", "Vehari",
"92449", "Okara",
"929388", "Swabi",
"92445", "Okara",
"92713", "Sukkur",
"928372", "Jhal\ Magsi",
"92255", "Dadu",
"928473", "Kharan",
"926062", "Layyah",
"92259", "Dadu",
"92919", "Peshawar\/Charsadda",
"924596", "Mianwali",
"929975", "Mansehra\/Batagram",
"92915", "Peshawar\/Charsadda",
"925478", "Hafizabad",
"928529", "Kech",
"928242", "Loralai",
"929457", "Lower\ Dir",
"922389", "Umerkot",
"92578", "Attock",
"928386", "Jaffarabad\/Nasirabad",
"926048", "Rajanpur",
"928522", "Kech",
"928223", "Zhob",
"92518", "Islamabad\/Rawalpindi",
"92656", "Khanewal",
"928564", "Awaran",
"926085", "Lodhran",
"922382", "Umerkot",
"92665", "Muzaffargarh",
"928236", "Killa\ Saifullah",
"92669", "Muzaffargarh",
"928353", "Dera\ Bugti",
"92227", "Hyderabad",
"928249", "Loralai",
"929966", "Shangla",
"928268", "K\.Abdullah\/Pishin",
"92424", "Lahore",
"925435", "Chakwal",
"92494", "Kasur",
"929665", "D\.I\.\ Khan",
"929425", "Bajaur\ Agency",
"929377", "Mardan",
"92614", "Multan",
"928379", "Jhal\ Magsi",
"926069", "Layyah",
"922354", "Sanghar",
"92815", "Quetta",
"928527", "Kech",
"92819", "Quetta",
"92648", "Dera\ Ghazi\ Khan",
"928484", "Khuzdar",
"92557", "Gujranwala",
"929386", "Swabi",
"922387", "Umerkot",
"929459", "Lower\ Dir",
"928388", "Jaffarabad\/Nasirabad",
"92864", "Gwadar",
"92716", "Sukkur",
"922335", "Mirpur\ Khas",
"925476", "Hafizabad",
"92928", "Bannu\/N\.\ Waziristan",
"924598", "Mianwali",
"92747", "Larkana",
"929372", "Mardan",
"92998", "Kohistan",
"929438", "Chitral",
"92675", "Vehari",
"92679", "Vehari",
"92444", "Okara",
"929395", "Buner",
"929925", "Abottabad",
"927224", "Jacobabad",
"92254", "Dadu",
"925428", "Narowal",
"929225", "Kohat",
"927262", "Shikarpur",
"92403", "Sahiwal",
"929633", "Tank",
"92216", "Karachi",
"92636", "Bahawalnagar",
"92914", "Peshawar\/Charsadda",
"928322", "Bolan",
"924539", "Bhakkar",
"924546", "Khushab",
"928252", "Chagai",
"928449", "Kalat",
"922439", "Khairpur",
"925463", "Mandi\ Bahauddin",
"928553", "Panjgur",
"922983", "Thatta",
"928436", "Mastung",
"922446", "Nawabshah",
"929466", "Swat",
"929447", "Upper\ Dir",
"928292", "Barkhan\/Kohlu",
"927267", "Shikarpur",
"927239", "Ghotki",
"92524", "Sialkot",
"922328", "Tharparkar",
"929973", "Mansehra\/Batagram",
"92489", "Sargodha",
"928284", "Musakhel",
"928475", "Kharan",
"92628", "Bahawalpur",
"928327", "Bolan",
"929329", "Malakand",
"92485", "Sargodha",
"928297", "Barkhan\/Kohlu",
"929442", "Upper\ Dir",
"922424", "Naushero\ Feroze",
"929959", "Haripur",
"928257", "Chagai",
"92418", "Faisalabad",
"92537", "Gujrat",
"924579", "Pakpattan",
"929374", "Mardan",
"92684", "Rahim\ Yar\ Khan",
"92564", "Sheikhupura",
"92712", "Sukkur",
"928476", "Kharan",
"924593", "Mianwali",
"92515", "Islamabad\/Rawalpindi",
"929659", "South\ Waziristan",
"929699", "Lakki\ Marwat",
"92519", "Islamabad\/Rawalpindi",
"92668", "Muzaffargarh",
"928567", "Awaran",
"922352", "Sanghar",
"928539", "Lasbela",
"928383", "Jaffarabad\/Nasirabad",
"928482", "Khuzdar",
"92407", "Sahiwal",
"928435", "Mastung",
"928358", "Dera\ Bugti",
"922445", "Nawabshah",
"929465", "Swat",
"92925", "Hangu\/Orakzai\ Agy",
"926043", "Rajanpur",
"928228", "Zhob",
"92533", "Gujrat",
"924545", "Khushab",
"929926", "Abottabad",
"92818", "Quetta",
"92649", "Dera\ Ghazi\ Khan",
"922384", "Umerkot",
"92474", "Jhang",
"929226", "Kohat",
"92645", "Dera\ Ghazi\ Khan",
"928524", "Kech",
"92652", "Khanewal",
"928487", "Khuzdar",
"928263", "K\.Abdullah\/Pishin",
"922357", "Sanghar",
"928562", "Awaran",
"929396", "Buner",
"925475", "Hafizabad",
"922323", "Tharparkar",
"922422", "Naushero\ Feroze",
"929444", "Upper\ Dir",
"929978", "Mansehra\/Batagram",
"928282", "Musakhel",
"928339", "Sibi\/Ziarat",
"92574", "Attock",
"922336", "Mirpur\ Khas",
"92678", "Vehari",
"929385", "Swabi",
"927227", "Jacobabad",
"922979", "Badin",
"92223", "Hyderabad",
"92625", "Bahawalpur",
"929666", "D\.I\.\ Khan",
"929426", "Bajaur\ Agency",
"928254", "Chagai",
"92488", "Sargodha",
"928294", "Barkhan\/Kohlu",
"925423", "Narowal",
"92629", "Bahawalpur",
"922427", "Naushero\ Feroze",
"925436", "Chakwal",
"925449", "Jhelum",
"92419", "Faisalabad",
"928287", "Musakhel",
"92743", "Larkana",
"92212", "Karachi",
"92632", "Bahawalnagar",
"92415", "Faisalabad",
"929433", "Chitral",
"928324", "Bolan",
"927222", "Jacobabad",
"928235", "Killa\ Saifullah",
"928558", "Panjgur",
"925468", "Mandi\ Bahauddin",
"927264", "Shikarpur",
"922988", "Thatta",
"929965", "Shangla",
"92553", "Gujranwala",
"92464", "Toba\ Tek\ Singh",
"929638", "Tank",
"926086", "Lodhran",};
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