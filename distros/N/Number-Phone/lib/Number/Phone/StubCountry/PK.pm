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
our $VERSION = 1.20211206222447;

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
$areanames{en} = {"92712", "Sukkur",
"929633", "Tank",
"92669", "Muzaffargarh",
"929663", "D\.I\.\ Khan",
"922439", "Khairpur",
"92212", "Karachi",
"929967", "Shangla",
"929222", "Kohat",
"928245", "Loralai",
"929635", "Tank",
"925448", "Jhelum",
"92429", "Lahore",
"928444", "Kalat",
"929665", "D\.I\.\ Khan",
"92558", "Gujranwala",
"924576", "Pakpattan",
"92748", "Larkana",
"928243", "Loralai",
"926048", "Rajanpur",
"929399", "Buner",
"928389", "Jaffarabad\/Nasirabad",
"92684", "Rahim\ Yar\ Khan",
"92514", "Islamabad\/Rawalpindi",
"92674", "Vehari",
"92255", "Dadu",
"922428", "Naushero\ Feroze",
"92819", "Quetta",
"928524", "Kech",
"92918", "Peshawar\/Charsadda",
"925433", "Chakwal",
"928268", "K\.Abdullah\/Pishin",
"929694", "Lakki\ Marwat",
"925463", "Mandi\ Bahauddin",
"928238", "Killa\ Saifullah",
"928353", "Dera\ Bugti",
"929382", "Swabi",
"925435", "Chakwal",
"92443", "Okara",
"924597", "Mianwali",
"925465", "Mandi\ Bahauddin",
"92446", "Okara",
"928355", "Dera\ Bugti",
"922322", "Tharparkar",
"92562", "Sheikhupura",
"92657", "Khanewal",
"926065", "Layyah",
"928536", "Lasbela",
"922356", "Sanghar",
"928229", "Zhob",
"928566", "Awaran",
"926063", "Layyah",
"922385", "Umerkot",
"922436", "Khairpur",
"92862", "Gwadar",
"922383", "Umerkot",
"92655", "Khanewal",
"924579", "Pakpattan",
"92572", "Attock",
"929396", "Buner",
"92612", "Multan",
"928435", "Mastung",
"929323", "Malakand",
"928386", "Jaffarabad\/Nasirabad",
"928375", "Jhal\ Magsi",
"928287", "Musakhel",
"928234", "Killa\ Saifullah",
"929325", "Malakand",
"92493", "Kasur",
"928433", "Mastung",
"924547", "Khushab",
"92648", "Dera\ Ghazi\ Khan",
"928373", "Jhal\ Magsi",
"929698", "Lakki\ Marwat",
"928264", "K\.Abdullah\/Pishin",
"92496", "Kasur",
"927223", "Jacobabad",
"92679", "Vehari",
"92533", "Gujrat",
"92689", "Rahim\ Yar\ Khan",
"92519", "Islamabad\/Rawalpindi",
"92257", "Dadu",
"922424", "Naushero\ Feroze",
"92536", "Gujrat",
"928528", "Kech",
"927225", "Jacobabad",
"926044", "Rajanpur",
"92814", "Quetta",
"929437", "Chitral",
"928448", "Kalat",
"928295", "Barkhan\/Kohlu",
"928252", "Chagai",
"929467", "Swat",
"92664", "Muzaffargarh",
"929377", "Mardan",
"925444", "Jhelum",
"928327", "Bolan",
"928539", "Lasbela",
"928293", "Barkhan\/Kohlu",
"922359", "Sanghar",
"928226", "Zhob",
"92424", "Lahore",
"928569", "Awaran",
"928525", "Kech",
"922446", "Nawabshah",
"92525", "Sialkot",
"927228", "Jacobabad",
"928523", "Kech",
"927269", "Shikarpur",
"929976", "Mansehra\/Batagram",
"929664", "D\.I\.\ Khan",
"928445", "Kalat",
"928298", "Barkhan\/Kohlu",
"929422", "Bajaur\ Agency",
"927239", "Ghotki",
"925426", "Narowal",
"929634", "Tank",
"928244", "Loralai",
"929456", "Lower\ Dir",
"928443", "Kalat",
"92494", "Kasur",
"928332", "Sibi\/Ziarat",
"92417", "Faisalabad",
"928472", "Kharan",
"92228", "Hyderabad",
"924537", "Bhakkar",
"92449", "Okara",
"92534", "Gujrat",
"92488", "Sargodha",
"926087", "Lodhran",
"922388", "Umerkot",
"92478", "Jhang",
"922977", "Badin",
"929959", "Haripur",
"926064", "Layyah",
"92816", "Quetta",
"92813", "Quetta",
"928354", "Dera\ Bugti",
"92666", "Muzaffargarh",
"929447", "Upper\ Dir",
"928438", "Mastung",
"925464", "Mandi\ Bahauddin",
"92402", "Sahiwal",
"92663", "Muzaffargarh",
"928378", "Jhal\ Magsi",
"925434", "Chakwal",
"929693", "Lakki\ Marwat",
"92426", "Lahore",
"929328", "Malakand",
"929652", "South\ Waziristan",
"92423", "Lahore",
"929695", "Lakki\ Marwat",
"92468", "Toba\ Tek\ Singh",
"928265", "K\.Abdullah\/Pishin",
"928487", "Khuzdar",
"929324", "Malakand",
"928235", "Killa\ Saifullah",
"922449", "Nawabshah",
"92628", "Bahawalpur",
"925438", "Chakwal",
"928374", "Jhal\ Magsi",
"928263", "K\.Abdullah\/Pishin",
"928358", "Dera\ Bugti",
"928434", "Mastung",
"925468", "Mandi\ Bahauddin",
"928233", "Killa\ Saifullah",
"927266", "Shikarpur",
"92686", "Rahim\ Yar\ Khan",
"92516", "Islamabad\/Rawalpindi",
"922337", "Mirpur\ Khas",
"92676", "Vehari",
"929979", "Mansehra\/Batagram",
"928557", "Panjgur",
"927236", "Ghotki",
"92683", "Rahim\ Yar\ Khan",
"925429", "Narowal",
"92513", "Islamabad\/Rawalpindi",
"926068", "Layyah",
"92673", "Vehari",
"92539", "Gujrat",
"929459", "Lower\ Dir",
"922384", "Umerkot",
"92415", "Faisalabad",
"925443", "Jhelum",
"929922", "Abottabad",
"928248", "Loralai",
"92632", "Bahawalnagar",
"925472", "Hafizabad",
"929956", "Haripur",
"925445", "Jhelum",
"92444", "Okara",
"929638", "Tank",
"92499", "Kasur",
"928294", "Barkhan\/Kohlu",
"929668", "D\.I\.\ Khan",
"922423", "Naushero\ Feroze",
"92527", "Sialkot",
"926045", "Rajanpur",
"927224", "Jacobabad",
"926043", "Rajanpur",
"922425", "Naushero\ Feroze",
"922982", "Thatta",
"928553", "Panjgur",
"922442", "Nawabshah",
"922333", "Mirpur\ Khas",
"92522", "Sialkot",
"928555", "Panjgur",
"92925", "Hangu\/Orakzai\ Agy",
"922335", "Mirpur\ Khas",
"928483", "Khuzdar",
"92637", "Bahawalnagar",
"925422", "Narowal",
"92498", "Kasur",
"92646", "Dera\ Ghazi\ Khan",
"924598", "Mianwali",
"928284", "Musakhel",
"92643", "Dera\ Ghazi\ Khan",
"929426", "Bajaur\ Agency",
"929972", "Mansehra\/Batagram",
"92224", "Hyderabad",
"928485", "Khuzdar",
"924544", "Khushab",
"928476", "Kharan",
"928267", "K\.Abdullah\/Pishin",
"928237", "Killa\ Saifullah",
"928336", "Sibi\/Ziarat",
"929452", "Lower\ Dir",
"922427", "Naushero\ Feroze",
"925479", "Hafizabad",
"929929", "Abottabad",
"92474", "Jhang",
"926047", "Rajanpur",
"92484", "Sargodha",
"92538", "Gujrat",
"929464", "Swat",
"929374", "Mardan",
"925447", "Jhelum",
"929434", "Chitral",
"92629", "Bahawalpur",
"92405", "Sahiwal",
"929656", "South\ Waziristan",
"928324", "Bolan",
"92469", "Toba\ Tek\ Singh",
"929968", "Shangla",
"922989", "Thatta",
"928328", "Bolan",
"92746", "Larkana",
"92556", "Gujranwala",
"929964", "Shangla",
"92407", "Sahiwal",
"92624", "Bahawalpur",
"92743", "Larkana",
"92553", "Gujranwala",
"924535", "Bhakkar",
"929438", "Chitral",
"928447", "Kalat",
"92464", "Toba\ Tek\ Singh",
"929468", "Swat",
"924533", "Bhakkar",
"929378", "Mardan",
"927232", "Ghotki",
"92916", "Peshawar\/Charsadda",
"927262", "Shikarpur",
"929429", "Bajaur\ Agency",
"92913", "Peshawar\/Charsadda",
"928479", "Kharan",
"92489", "Sargodha",
"928339", "Sibi\/Ziarat",
"928527", "Kech",
"92479", "Jhang",
"92229", "Hyderabad",
"925476", "Hafizabad",
"929443", "Upper\ Dir",
"92448", "Okara",
"924548", "Khushab",
"929926", "Abottabad",
"929697", "Lakki\ Marwat",
"929445", "Upper\ Dir",
"92635", "Bahawalnagar",
"929952", "Haripur",
"92412", "Faisalabad",
"928288", "Musakhel",
"924594", "Mianwali",
"92927", "Karak",
"926083", "Lodhran",
"922973", "Badin",
"926085", "Lodhran",
"929659", "South\ Waziristan",
"922986", "Thatta",
"922975", "Badin",
"929327", "Malakand",
"929226", "Kohat",
"92623", "Bahawalpur",
"928283", "Musakhel",
"92744", "Larkana",
"92626", "Bahawalpur",
"928484", "Khuzdar",
"924545", "Khushab",
"92554", "Gujranwala",
"9258", "AJK\/FATA",
"924572", "Pakpattan",
"929448", "Upper\ Dir",
"928437", "Mastung",
"92463", "Toba\ Tek\ Singh",
"92215", "Karachi",
"92715", "Sukkur",
"928285", "Musakhel",
"928377", "Jhal\ Magsi",
"92466", "Toba\ Tek\ Singh",
"924543", "Khushab",
"92252", "Dadu",
"922334", "Mirpur\ Khas",
"92914", "Peshawar\/Charsadda",
"928554", "Panjgur",
"926088", "Lodhran",
"922387", "Umerkot",
"922978", "Badin",
"92678", "Vehari",
"92518", "Islamabad\/Rawalpindi",
"92688", "Rahim\ Yar\ Khan",
"92649", "Dera\ Ghazi\ Khan",
"929433", "Chitral",
"928325", "Bolan",
"92617", "Multan",
"929373", "Mardan",
"924538", "Bhakkar",
"929463", "Swat",
"92577", "Attock",
"928323", "Bolan",
"928297", "Barkhan\/Kohlu",
"929435", "Chitral",
"929375", "Mardan",
"929386", "Swabi",
"929465", "Swat",
"927227", "Jacobabad",
"928259", "Chagai",
"922326", "Tharparkar",
"928562", "Awaran",
"928532", "Lasbela",
"922352", "Sanghar",
"92867", "Gwadar",
"92565", "Sheikhupura",
"92652", "Khanewal",
"929229", "Kohat",
"922432", "Khairpur",
"92865", "Gwadar",
"92567", "Sheikhupura",
"928382", "Jaffarabad\/Nasirabad",
"92226", "Hyderabad",
"929637", "Tank",
"929963", "Shangla",
"929392", "Buner",
"92223", "Hyderabad",
"929667", "D\.I\.\ Khan",
"92644", "Dera\ Ghazi\ Khan",
"924534", "Bhakkar",
"928247", "Loralai",
"92575", "Attock",
"929965", "Shangla",
"92615", "Multan",
"92919", "Peshawar\/Charsadda",
"922974", "Badin",
"92818", "Quetta",
"926084", "Lodhran",
"92473", "Jhang",
"922338", "Mirpur\ Khas",
"928558", "Panjgur",
"92483", "Sargodha",
"929389", "Swabi",
"92476", "Jhang",
"926067", "Layyah",
"92486", "Sargodha",
"92217", "Karachi",
"92559", "Gujranwala",
"924595", "Mianwali",
"925437", "Chakwal",
"92749", "Larkana",
"928357", "Dera\ Bugti",
"929444", "Upper\ Dir",
"925467", "Mandi\ Bahauddin",
"92717", "Sukkur",
"928256", "Chagai",
"92428", "Lahore",
"922329", "Tharparkar",
"924593", "Mianwali",
"928488", "Khuzdar",
"928222", "Zhob",
"92668", "Muzaffargarh",
"92462", "Toba\ Tek\ Singh",
"929653", "South\ Waziristan",
"929957", "Haripur",
"929384", "Swabi",
"922979", "Badin",
"92622", "Bahawalpur",
"929655", "South\ Waziristan",
"926089", "Lodhran",
"929692", "Lakki\ Marwat",
"92256", "Dadu",
"92253", "Dadu",
"922324", "Tharparkar",
"92537", "Gujrat",
"929449", "Upper\ Dir",
"928258", "Chagai",
"928333", "Sibi\/Ziarat",
"929425", "Bajaur\ Agency",
"928442", "Kalat",
"92414", "Faisalabad",
"92497", "Kasur",
"928473", "Kharan",
"92638", "Bahawalnagar",
"929224", "Kohat",
"929423", "Bajaur\ Agency",
"928335", "Sibi\/Ziarat",
"928475", "Kharan",
"928486", "Khuzdar",
"92445", "Okara",
"924539", "Bhakkar",
"928522", "Kech",
"927237", "Ghotki",
"92529", "Sialkot",
"928556", "Panjgur",
"927267", "Shikarpur",
"922336", "Mirpur\ Khas",
"922983", "Thatta",
"926042", "Rajanpur",
"92928", "Bannu\/N\.\ Waziristan",
"92653", "Khanewal",
"922976", "Badin",
"922985", "Thatta",
"922422", "Naushero\ Feroze",
"92656", "Khanewal",
"92524", "Sialkot",
"926086", "Lodhran",
"929925", "Abottabad",
"92419", "Faisalabad",
"929228", "Kohat",
"925475", "Hafizabad",
"92447", "Okara",
"929923", "Abottabad",
"925442", "Jhelum",
"928254", "Chagai",
"92222", "Hyderabad",
"925473", "Hafizabad",
"929446", "Upper\ Dir",
"92495", "Kasur",
"922328", "Tharparkar",
"92472", "Jhang",
"92482", "Sargodha",
"92535", "Gujrat",
"922447", "Nawabshah",
"928489", "Khuzdar",
"928262", "K\.Abdullah\/Pishin",
"924536", "Bhakkar",
"929457", "Lower\ Dir",
"92408", "Sahiwal",
"928232", "Killa\ Saifullah",
"925427", "Narowal",
"929388", "Swabi",
"929977", "Mansehra\/Batagram",
"928559", "Panjgur",
"922339", "Mirpur\ Khas",
"922325", "Tharparkar",
"924599", "Mianwali",
"926062", "Layyah",
"92526", "Sialkot",
"92654", "Khanewal",
"92868", "Gwadar",
"922323", "Tharparkar",
"92523", "Sialkot",
"92618", "Multan",
"929383", "Swabi",
"92578", "Attock",
"929654", "South\ Waziristan",
"928227", "Zhob",
"928326", "Bolan",
"929385", "Swabi",
"929376", "Mardan",
"925432", "Chakwal",
"929466", "Swat",
"925462", "Mandi\ Bahauddin",
"92642", "Dera\ Ghazi\ Khan",
"929436", "Chitral",
"928352", "Dera\ Bugti",
"92998", "Kohistan",
"92677", "Vehari",
"922437", "Khairpur",
"922988", "Thatta",
"929969", "Shangla",
"92259", "Dadu",
"92517", "Islamabad\/Rawalpindi",
"92687", "Rahim\ Yar\ Khan",
"92815", "Quetta",
"92665", "Muzaffargarh",
"924546", "Khushab",
"929928", "Abottabad",
"928474", "Kharan",
"925478", "Hafizabad",
"928334", "Sibi\/Ziarat",
"928242", "Loralai",
"929225", "Kohat",
"929632", "Tank",
"92425", "Lahore",
"928286", "Musakhel",
"928387", "Jaffarabad\/Nasirabad",
"929424", "Bajaur\ Agency",
"929662", "D\.I\.\ Khan",
"929223", "Kohat",
"929397", "Buner",
"928292", "Barkhan\/Kohlu",
"929428", "Bajaur\ Agency",
"92718", "Sukkur",
"928255", "Chagai",
"92427", "Lahore",
"92218", "Karachi",
"924596", "Mianwali",
"928338", "Sibi\/Ziarat",
"925474", "Hafizabad",
"92667", "Muzaffargarh",
"928253", "Chagai",
"92742", "Larkana",
"92552", "Gujranwala",
"929924", "Abottabad",
"928478", "Kharan",
"92515", "Islamabad\/Rawalpindi",
"92685", "Rahim\ Yar\ Khan",
"92817", "Quetta",
"92675", "Vehari",
"928567", "Awaran",
"922984", "Thatta",
"922357", "Sanghar",
"928329", "Bolan",
"928537", "Lasbela",
"927222", "Jacobabad",
"929379", "Mardan",
"929469", "Swat",
"92254", "Dadu",
"92912", "Peshawar\/Charsadda",
"929439", "Chitral",
"92416", "Faisalabad",
"928432", "Mastung",
"924577", "Pakpattan",
"928372", "Jhal\ Magsi",
"92413", "Faisalabad",
"929966", "Shangla",
"929322", "Malakand",
"929658", "South\ Waziristan",
"922382", "Umerkot",
"92568", "Sheikhupura",
"924549", "Khushab",
"928289", "Musakhel",
"92659", "Khanewal",
"92864", "Gwadar",
"928563", "Awaran",
"927238", "Ghotki",
"92658", "Khanewal",
"926066", "Layyah",
"928299", "Barkhan\/Kohlu",
"928533", "Lasbela",
"927268", "Shikarpur",
"922353", "Sanghar",
"928565", "Awaran",
"92926", "Kurram\ Agency",
"928535", "Lasbela",
"92569", "Sheikhupura",
"922355", "Sanghar",
"92923", "Nowshera",
"92645", "Dera\ Ghazi\ Khan",
"928322", "Bolan",
"925466", "Mandi\ Bahauddin",
"928257", "Chagai",
"92574", "Attock",
"928356", "Dera\ Bugti",
"92614", "Multan",
"929432", "Chitral",
"927229", "Jacobabad",
"929372", "Mardan",
"925436", "Chakwal",
"929462", "Swat",
"928379", "Jhal\ Magsi",
"92812", "Quetta",
"928439", "Mastung",
"92917", "Peshawar\/Charsadda",
"922444", "Nawabshah",
"929329", "Malakand",
"929454", "Lower\ Dir",
"924573", "Pakpattan",
"928246", "Loralai",
"92422", "Lahore",
"922389", "Umerkot",
"924542", "Khushab",
"924575", "Pakpattan",
"929974", "Mansehra\/Batagram",
"92557", "Gujranwala",
"92406", "Sahiwal",
"92219", "Karachi",
"929666", "D\.I\.\ Khan",
"92747", "Larkana",
"928282", "Musakhel",
"92403", "Sahiwal",
"92662", "Muzaffargarh",
"929636", "Tank",
"929958", "Haripur",
"92719", "Sukkur",
"925424", "Narowal",
"924592", "Mianwali",
"92745", "Larkana",
"929954", "Haripur",
"925428", "Narowal",
"92555", "Gujranwala",
"929387", "Swabi",
"926069", "Layyah",
"929978", "Mansehra\/Batagram",
"928296", "Barkhan\/Kohlu",
"928223", "Zhob",
"92714", "Sukkur",
"929458", "Lower\ Dir",
"928225", "Zhob",
"92214", "Karachi",
"922448", "Nawabshah",
"92915", "Peshawar\/Charsadda",
"92258", "Dadu",
"925469", "Mandi\ Bahauddin",
"922327", "Tharparkar",
"928359", "Dera\ Bugti",
"927226", "Jacobabad",
"92682", "Rahim\ Yar\ Khan",
"925439", "Chakwal",
"92512", "Islamabad\/Rawalpindi",
"92672", "Vehari",
"928376", "Jhal\ Magsi",
"928385", "Jaffarabad\/Nasirabad",
"929395", "Buner",
"928436", "Mastung",
"928383", "Jaffarabad\/Nasirabad",
"92647", "Dera\ Ghazi\ Khan",
"92636", "Bahawalnagar",
"92619", "Multan",
"929227", "Kohat",
"929962", "Shangla",
"929393", "Buner",
"92579", "Attock",
"92633", "Bahawalnagar",
"929326", "Malakand",
"928249", "Loralai",
"922435", "Khairpur",
"922386", "Umerkot",
"92869", "Gwadar",
"929669", "D\.I\.\ Khan",
"927264", "Shikarpur",
"922433", "Khairpur",
"92564", "Sheikhupura",
"929639", "Tank",
"927234", "Ghotki",
"928388", "Jaffarabad\/Nasirabad",
"92625", "Bahawalpur",
"926049", "Rajanpur",
"929398", "Buner",
"92713", "Sukkur",
"92409", "Sahiwal",
"92216", "Karachi",
"929927", "Abottabad",
"929696", "Lakki\ Marwat",
"92716", "Sukkur",
"925477", "Hafizabad",
"92213", "Karachi",
"922429", "Naushero\ Feroze",
"92465", "Toba\ Tek\ Singh",
"922438", "Khairpur",
"922987", "Thatta",
"922354", "Sanghar",
"928534", "Lasbela",
"92487", "Sargodha",
"92477", "Jhang",
"928564", "Awaran",
"925449", "Jhelum",
"925425", "Narowal",
"92442", "Okara",
"928446", "Kalat",
"929453", "Lower\ Dir",
"924574", "Pakpattan",
"929975", "Mansehra\/Batagram",
"92227", "Hyderabad",
"925423", "Narowal",
"928482", "Khuzdar",
"928228", "Zhob",
"929973", "Mansehra\/Batagram",
"92634", "Bahawalnagar",
"92418", "Faisalabad",
"929455", "Lower\ Dir",
"928526", "Kech",
"922445", "Nawabshah",
"928239", "Killa\ Saifullah",
"928269", "K\.Abdullah\/Pishin",
"928552", "Panjgur",
"922332", "Mirpur\ Khas",
"922443", "Nawabshah",
"92563", "Sheikhupura",
"92566", "Sheikhupura",
"92863", "Gwadar",
"92866", "Gwadar",
"92528", "Sialkot",
"926046", "Rajanpur",
"926082", "Lodhran",
"929699", "Lakki\ Marwat",
"922426", "Naushero\ Feroze",
"92924", "Khyber\/Mohmand\ Agy",
"922972", "Badin",
"928224", "Zhob",
"92225", "Hyderabad",
"92492", "Kasur",
"929953", "Haripur",
"929657", "South\ Waziristan",
"92573", "Attock",
"92639", "Bahawalnagar",
"929442", "Upper\ Dir",
"92613", "Multan",
"924578", "Pakpattan",
"92576", "Attock",
"925446", "Jhelum",
"929955", "Haripur",
"92616", "Multan",
"927235", "Ghotki",
"927265", "Shikarpur",
"928449", "Kalat",
"927233", "Ghotki",
"92532", "Gujrat",
"928568", "Awaran",
"922434", "Khairpur",
"927263", "Shikarpur",
"922358", "Sanghar",
"92475", "Jhang",
"92485", "Sargodha",
"928538", "Lasbela",
"928337", "Sibi\/Ziarat",
"928529", "Kech",
"928236", "Killa\ Saifullah",
"92467", "Toba\ Tek\ Singh",
"924532", "Bhakkar",
"928477", "Kharan",
"928266", "K\.Abdullah\/Pishin",
"929427", "Bajaur\ Agency",
"929394", "Buner",
"92627", "Bahawalpur",
"92404", "Sahiwal",
"928384", "Jaffarabad\/Nasirabad",};

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