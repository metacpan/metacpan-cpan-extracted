# automatically generated file, don't edit



# Copyright 2026 David Cantrell, derived from data from libphonenumber
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
our $VERSION = 1.20260306161714;

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
$areanames{en} = {"928386", "Jaffarabad\/Nasirabad",
"925443", "Jhelum",
"929954", "Haripur",
"92254", "Dadu",
"928372", "Jhal\ Magsi",
"929427", "Bajaur\ Agency",
"929658", "South\ Waziristan",
"924592", "Mianwali",
"929223", "Kohat",
"929696", "Lakki\ Marwat",
"928478", "Kharan",
"929375", "Mardan",
"928555", "Panjgur",
"929664", "D\.I\.\ Khan",
"92647", "Dera\ Ghazi\ Khan",
"92746", "Larkana",
"929968", "Shangla",
"929438", "Chitral",
"928335", "Sibi\/Ziarat",
"92516", "Islamabad\/Rawalpindi",
"92223", "Hyderabad",
"929387", "Swabi",
"929929", "Abottabad",
"927223", "Jacobabad",
"92866", "Gwadar",
"926065", "Layyah",
"928352", "Dera\ Bugti",
"926042", "Rajanpur",
"922327", "Tharparkar",
"922989", "Thatta",
"922432", "Khairpur",
"928532", "Lasbela",
"929974", "Mansehra\/Batagram",
"927262", "Shikarpur",
"92663", "Muzaffargarh",
"92618", "Multan",
"922338", "Mirpur\ Khas",
"925425", "Narowal",
"929444", "Upper\ Dir",
"928242", "Loralai",
"928265", "K\.Abdullah\/Pishin",
"92645", "Dera\ Ghazi\ Khan",
"925469", "Mandi\ Bahauddin",
"929632", "Tank",
"925476", "Hafizabad",
"922335", "Mirpur\ Khas",
"925428", "Narowal",
"922426", "Naushero\ Feroze",
"928229", "Zhob",
"92414", "Faisalabad",
"928526", "Kech",
"924549", "Khushab",
"928268", "K\.Abdullah\/Pishin",
"92657", "Khanewal",
"924577", "Pakpattan",
"92927", "Karak",
"92626", "Bahawalpur",
"926068", "Layyah",
"929452", "Lower\ Dir",
"92489", "Sargodha",
"928254", "Chagai",
"92422", "Lahore",
"929396", "Buner",
"925437", "Chakwal",
"922386", "Umerkot",
"92673", "Vehari",
"924536", "Bhakkar",
"92482", "Sargodha",
"92429", "Lahore",
"92498", "Kasur",
"92655", "Khanewal",
"928475", "Kharan",
"929378", "Mardan",
"928558", "Panjgur",
"92925", "Hangu\/Orakzai\ Agy",
"929326", "Malakand",
"92633", "Bahawalnagar",
"929965", "Shangla",
"929435", "Chitral",
"928338", "Sibi\/Ziarat",
"926083", "Lodhran",
"928487", "Khuzdar",
"928283", "Musakhel",
"928432", "Mastung",
"927234", "Ghotki",
"928327", "Bolan",
"92528", "Sialkot",
"929655", "South\ Waziristan",
"928299", "Barkhan\/Kohlu",
"928564", "Awaran",
"922352", "Sanghar",
"92686", "Rahim\ Yar\ Khan",
"928384", "Jaffarabad\/Nasirabad",
"925465", "Mandi\ Bahauddin",
"92537", "Gujrat",
"925442", "Jhelum",
"92463", "Toba\ Tek\ Singh",
"92418", "Faisalabad",
"929956", "Haripur",
"922339", "Mirpur\ Khas",
"924593", "Mianwali",
"928225", "Zhob",
"92215", "Karachi",
"924545", "Khushab",
"928373", "Jhal\ Magsi",
"929694", "Lakki\ Marwat",
"92445", "Okara",
"92862", "Gwadar",
"922988", "Thatta",
"929666", "D\.I\.\ Khan",
"929222", "Kohat",
"927222", "Jacobabad",
"92575", "Attock",
"92519", "Islamabad\/Rawalpindi",
"92749", "Larkana",
"92217", "Karachi",
"926043", "Rajanpur",
"928447", "Kalat",
"928479", "Kharan",
"92553", "Gujranwala",
"92869", "Gwadar",
"928353", "Dera\ Bugti",
"927263", "Shikarpur",
"92535", "Gujrat",
"92494", "Kasur",
"929969", "Shangla",
"928533", "Lasbela",
"929439", "Chitral",
"929928", "Abottabad",
"922433", "Khairpur",
"92512", "Islamabad\/Rawalpindi",
"929976", "Mansehra\/Batagram",
"92742", "Larkana",
"92524", "Sialkot",
"92577", "Attock",
"929446", "Upper\ Dir",
"928295", "Barkhan\/Kohlu",
"929659", "South\ Waziristan",
"92447", "Okara",
"929467", "Swat",
"928243", "Loralai",
"92258", "Dadu",
"92567", "Sheikhupura",
"925474", "Hafizabad",
"929633", "Tank",
"92629", "Bahawalpur",
"922424", "Naushero\ Feroze",
"928298", "Barkhan\/Kohlu",
"92682", "Rahim\ Yar\ Khan",
"928524", "Kech",
"928256", "Chagai",
"929379", "Mardan",
"929394", "Buner",
"92486", "Sargodha",
"929453", "Lower\ Dir",
"928559", "Panjgur",
"92815", "Quetta",
"928339", "Sibi\/Ziarat",
"922384", "Umerkot",
"929925", "Abottabad",
"924534", "Bhakkar",
"926069", "Layyah",
"92426", "Lahore",
"922985", "Thatta",
"929324", "Malakand",
"92614", "Multan",
"928237", "Killa\ Saifullah",
"92565", "Sheikhupura",
"926082", "Lodhran",
"922977", "Badin",
"928433", "Mastung",
"92913", "Peshawar\/Charsadda",
"928282", "Musakhel",
"925468", "Mandi\ Bahauddin",
"92473", "Jhang",
"92403", "Sahiwal",
"925429", "Narowal",
"927236", "Ghotki",
"92622", "Bahawalpur",
"922447", "Nawabshah",
"928566", "Awaran",
"928228", "Zhob",
"922353", "Sanghar",
"92689", "Rahim\ Yar\ Khan",
"928269", "K\.Abdullah\/Pishin",
"924548", "Khushab",
"92817", "Quetta",
"92713", "Sukkur",
"929424", "Bajaur\ Agency",
"928222", "Zhob",
"92259", "Dadu",
"924542", "Khushab",
"928288", "Musakhel",
"925462", "Mandi\ Bahauddin",
"929639", "Tank",
"92628", "Bahawalpur",
"925445", "Jhelum",
"929957", "Haripur",
"927225", "Jacobabad",
"929384", "Swabi",
"928333", "Sibi\/Ziarat",
"926088", "Lodhran",
"92555", "Gujranwala",
"929459", "Lower\ Dir",
"928553", "Panjgur",
"92533", "Gujrat",
"929373", "Mardan",
"929667", "D\.I\.\ Khan",
"92467", "Toba\ Tek\ Singh",
"929225", "Kohat",
"929977", "Mansehra\/Batagram",
"92496", "Kasur",
"92443", "Okara",
"928446", "Kalat",
"926063", "Layyah",
"922324", "Tharparkar",
"92573", "Attock",
"929447", "Upper\ Dir",
"928263", "K\.Abdullah\/Pishin",
"928292", "Barkhan\/Kohlu",
"92252", "Dadu",
"922359", "Sanghar",
"929466", "Swat",
"92465", "Toba\ Tek\ Singh",
"92213", "Karachi",
"92688", "Rahim\ Yar\ Khan",
"925423", "Narowal",
"92557", "Gujranwala",
"928439", "Mastung",
"92526", "Sialkot",
"928379", "Jhal\ Magsi",
"92915", "Peshawar\/Charsadda",
"924574", "Pakpattan",
"92405", "Sahiwal",
"924599", "Mianwali",
"92419", "Faisalabad",
"92475", "Jhang",
"922333", "Mirpur\ Khas",
"92715", "Sukkur",
"929922", "Abottabad",
"928257", "Chagai",
"92484", "Sargodha",
"92748", "Larkana",
"925434", "Chakwal",
"92518", "Islamabad\/Rawalpindi",
"92563", "Sheikhupura",
"927228", "Jacobabad",
"928236", "Killa\ Saifullah",
"922439", "Khairpur",
"929963", "Shangla",
"929433", "Chitral",
"928484", "Khuzdar",
"928539", "Lasbela",
"92868", "Gwadar",
"926085", "Lodhran",
"92813", "Quetta",
"92717", "Sukkur",
"927269", "Shikarpur",
"922976", "Badin",
"928359", "Dera\ Bugti",
"92424", "Lahore",
"92917", "Peshawar\/Charsadda",
"92616", "Multan",
"928473", "Kharan",
"92407", "Sahiwal",
"926049", "Rajanpur",
"92477", "Jhang",
"929228", "Kohat",
"922982", "Thatta",
"927237", "Ghotki",
"928249", "Loralai",
"922446", "Nawabshah",
"928324", "Bolan",
"928567", "Awaran",
"929653", "South\ Waziristan",
"92412", "Faisalabad",
"928285", "Musakhel",
"925448", "Jhelum",
"928375", "Jhal\ Magsi",
"929426", "Bajaur\ Agency",
"924543", "Khushab",
"928223", "Zhob",
"922358", "Sanghar",
"92256", "Dadu",
"92227", "Hyderabad",
"924595", "Mianwali",
"928387", "Jaffarabad\/Nasirabad",
"92522", "Sialkot",
"92643", "Dera\ Ghazi\ Khan",
"928438", "Mastung",
"925463", "Mandi\ Bahauddin",
"92492", "Kasur",
"928332", "Sibi\/Ziarat",
"92488", "Sargodha",
"929386", "Swabi",
"92744", "Larkana",
"92514", "Islamabad\/Rawalpindi",
"929697", "Lakki\ Marwat",
"92665", "Muzaffargarh",
"929372", "Mardan",
"928552", "Panjgur",
"92499", "Kasur",
"92428", "Lahore",
"922435", "Khairpur",
"928535", "Lasbela",
"926089", "Lodhran",
"927265", "Shikarpur",
"929458", "Lower\ Dir",
"928355", "Dera\ Bugti",
"926062", "Layyah",
"928444", "Kalat",
"92864", "Gwadar",
"926045", "Rajanpur",
"92225", "Hyderabad",
"922326", "Tharparkar",
"928245", "Loralai",
"92667", "Muzaffargarh",
"929464", "Swat",
"928293", "Barkhan\/Kohlu",
"928262", "K\.Abdullah\/Pishin",
"929638", "Tank",
"928289", "Musakhel",
"92529", "Sialkot",
"925422", "Narowal",
"928248", "Loralai",
"92416", "Faisalabad",
"922427", "Naushero\ Feroze",
"92624", "Bahawalpur",
"924576", "Pakpattan",
"92677", "Vehari",
"928527", "Kech",
"929635", "Tank",
"925449", "Jhelum",
"925477", "Hafizabad",
"922332", "Mirpur\ Khas",
"927229", "Jacobabad",
"922438", "Khairpur",
"929923", "Abottabad",
"92923", "Nowshera",
"922387", "Umerkot",
"928538", "Lasbela",
"924537", "Bhakkar",
"927268", "Shikarpur",
"92653", "Khanewal",
"929455", "Lower\ Dir",
"928358", "Dera\ Bugti",
"92635", "Bahawalnagar",
"92612", "Multan",
"926048", "Rajanpur",
"925436", "Chakwal",
"929397", "Buner",
"929229", "Kohat",
"928234", "Killa\ Saifullah",
"929962", "Shangla",
"929432", "Chitral",
"928486", "Khuzdar",
"922974", "Badin",
"922983", "Thatta",
"92619", "Multan",
"92675", "Vehari",
"928472", "Kharan",
"929327", "Malakand",
"922444", "Nawabshah",
"928378", "Jhal\ Magsi",
"92684", "Rahim\ Yar\ Khan",
"92637", "Bahawalnagar",
"929652", "South\ Waziristan",
"928326", "Bolan",
"922355", "Sanghar",
"924598", "Mianwali",
"928435", "Mastung",
"922437", "Khairpur",
"924538", "Bhakkar",
"927267", "Shikarpur",
"92714", "Sukkur",
"928537", "Lasbela",
"922388", "Umerkot",
"928443", "Kalat",
"92914", "Peshawar\/Charsadda",
"926066", "Layyah",
"928357", "Dera\ Bugti",
"92427", "Lahore",
"922322", "Tharparkar",
"929398", "Buner",
"92474", "Jhang",
"926047", "Rajanpur",
"92404", "Sahiwal",
"92816", "Quetta",
"922428", "Naushero\ Feroze",
"929463", "Swat",
"92485", "Sargodha",
"928569", "Awaran",
"928294", "Barkhan\/Kohlu",
"927239", "Ghotki",
"928247", "Loralai",
"92652", "Khanewal",
"928266", "K\.Abdullah\/Pishin",
"928528", "Kech",
"925426", "Narowal",
"925478", "Hafizabad",
"92668", "Muzaffargarh",
"92613", "Multan",
"929422", "Bajaur\ Agency",
"928224", "Zhob",
"92425", "Lahore",
"928377", "Jhal\ Magsi",
"92659", "Khanewal",
"924597", "Mianwali",
"924544", "Khushab",
"92998", "Kohistan",
"92566", "Sheikhupura",
"925464", "Mandi\ Bahauddin",
"928385", "Jaffarabad\/Nasirabad",
"92228", "Hyderabad",
"928336", "Sibi\/Ziarat",
"9258", "AJK\/FATA",
"929382", "Swabi",
"92487", "Sargodha",
"928259", "Chagai",
"929695", "Lakki\ Marwat",
"928556", "Panjgur",
"929328", "Malakand",
"929376", "Mardan",
"929436", "Chitral",
"929966", "Shangla",
"922973", "Badin",
"929979", "Mansehra\/Batagram",
"928482", "Khuzdar",
"928233", "Killa\ Saifullah",
"92523", "Sialkot",
"929698", "Lakki\ Marwat",
"92216", "Karachi",
"929325", "Malakand",
"922984", "Thatta",
"928476", "Kharan",
"92642", "Dera\ Ghazi\ Khan",
"928322", "Bolan",
"929656", "South\ Waziristan",
"929449", "Upper\ Dir",
"92493", "Kasur",
"92446", "Okara",
"922443", "Nawabshah",
"922357", "Sanghar",
"92638", "Bahawalnagar",
"92576", "Attock",
"928388", "Jaffarabad\/Nasirabad",
"928437", "Mastung",
"92554", "Gujranwala",
"922425", "Naushero\ Feroze",
"928525", "Kech",
"924572", "Pakpattan",
"929637", "Tank",
"922336", "Mirpur\ Khas",
"92536", "Gujrat",
"929959", "Haripur",
"925475", "Hafizabad",
"92678", "Vehari",
"924535", "Bhakkar",
"922385", "Umerkot",
"929924", "Abottabad",
"929457", "Lower\ Dir",
"929669", "D\.I\.\ Khan",
"92464", "Toba\ Tek\ Singh",
"925432", "Chakwal",
"929395", "Buner",
"92649", "Dera\ Ghazi\ Khan",
"929975", "Mansehra\/Batagram",
"92625", "Bahawalpur",
"928258", "Chagai",
"926064", "Layyah",
"922323", "Tharparkar",
"929329", "Malakand",
"928442", "Kalat",
"928296", "Barkhan\/Kohlu",
"92634", "Bahawalnagar",
"92687", "Rahim\ Yar\ Khan",
"929445", "Upper\ Dir",
"929462", "Swat",
"92558", "Gujranwala",
"92819", "Quetta",
"928264", "K\.Abdullah\/Pishin",
"92562", "Sheikhupura",
"925424", "Narowal",
"928226", "Zhob",
"922429", "Naushero\ Feroze",
"928568", "Awaran",
"92926", "Kurram\ Agency",
"92627", "Bahawalpur",
"927238", "Ghotki",
"92656", "Khanewal",
"92674", "Vehari",
"92812", "Quetta",
"924546", "Khushab",
"928529", "Kech",
"929423", "Bajaur\ Agency",
"925466", "Mandi\ Bahauddin",
"92569", "Sheikhupura",
"929955", "Haripur",
"925447", "Jhelum",
"925479", "Hafizabad",
"928334", "Sibi\/Ziarat",
"929383", "Swabi",
"927227", "Jacobabad",
"92413", "Faisalabad",
"92468", "Toba\ Tek\ Singh",
"924539", "Bhakkar",
"922389", "Umerkot",
"92685", "Rahim\ Yar\ Khan",
"929399", "Buner",
"929665", "D\.I\.\ Khan",
"929227", "Kohat",
"928554", "Panjgur",
"929374", "Mardan",
"928232", "Killa\ Saifullah",
"929964", "Shangla",
"929434", "Chitral",
"928483", "Khuzdar",
"92918", "Peshawar\/Charsadda",
"922972", "Badin",
"92478", "Jhang",
"92408", "Sahiwal",
"926087", "Lodhran",
"92219", "Karachi",
"922986", "Thatta",
"929668", "D\.I\.\ Khan",
"92718", "Sukkur",
"92867", "Gwadar",
"928474", "Kharan",
"928565", "Awaran",
"929654", "South\ Waziristan",
"922442", "Nawabshah",
"927235", "Ghotki",
"92449", "Okara",
"92664", "Muzaffargarh",
"928323", "Bolan",
"92532", "Gujrat",
"928287", "Musakhel",
"929958", "Haripur",
"92579", "Attock",
"92515", "Islamabad\/Rawalpindi",
"92745", "Larkana",
"924573", "Pakpattan",
"929448", "Upper\ Dir",
"92442", "Okara",
"92224", "Hyderabad",
"92865", "Gwadar",
"928389", "Jaffarabad\/Nasirabad",
"92539", "Gujrat",
"92572", "Attock",
"922334", "Mirpur\ Khas",
"92253", "Dadu",
"92517", "Islamabad\/Rawalpindi",
"929978", "Mansehra\/Batagram",
"929926", "Abottabad",
"92747", "Larkana",
"92646", "Dera\ Ghazi\ Khan",
"925433", "Chakwal",
"929699", "Lakki\ Marwat",
"928255", "Chagai",
"92212", "Karachi",
"928354", "Dera\ Bugti",
"92919", "Peshawar\/Charsadda",
"92409", "Sahiwal",
"92415", "Faisalabad",
"92479", "Jhang",
"928445", "Kalat",
"926044", "Rajanpur",
"92683", "Rahim\ Yar\ Khan",
"922434", "Khairpur",
"92218", "Karachi",
"927264", "Shikarpur",
"929972", "Mansehra\/Batagram",
"92719", "Sukkur",
"928489", "Khuzdar",
"928534", "Lasbela",
"92448", "Okara",
"928329", "Bolan",
"928297", "Barkhan\/Kohlu",
"929442", "Upper\ Dir",
"928244", "Loralai",
"92636", "Bahawalnagar",
"92578", "Attock",
"929465", "Swat",
"925467", "Mandi\ Bahauddin",
"928383", "Jaffarabad\/Nasirabad",
"929952", "Haripur",
"925446", "Jhelum",
"92538", "Gujrat",
"928227", "Zhob",
"922448", "Nawabshah",
"928374", "Jhal\ Magsi",
"92676", "Vehari",
"924594", "Mianwali",
"92924", "Khyber\/Mohmand\ Agy",
"92654", "Khanewal",
"924547", "Khushab",
"924579", "Pakpattan",
"92417", "Faisalabad",
"92912", "Peshawar\/Charsadda",
"929662", "D\.I\.\ Khan",
"929226", "Kohat",
"925439", "Chakwal",
"929693", "Lakki\ Marwat",
"92402", "Sahiwal",
"92472", "Jhang",
"928238", "Killa\ Saifullah",
"92623", "Bahawalpur",
"927226", "Jacobabad",
"92712", "Sukkur",
"922978", "Badin",
"92255", "Dadu",
"929323", "Malakand",
"922329", "Tharparkar",
"922987", "Thatta",
"92462", "Toba\ Tek\ Singh",
"928235", "Killa\ Saifullah",
"922975", "Badin",
"926086", "Lodhran",
"928286", "Musakhel",
"928434", "Mastung",
"92818", "Quetta",
"92863", "Gwadar",
"92559", "Gujranwala",
"928562", "Awaran",
"92666", "Muzaffargarh",
"922445", "Nawabshah",
"927232", "Ghotki",
"922354", "Sanghar",
"925473", "Hafizabad",
"929634", "Tank",
"92552", "Gujranwala",
"928523", "Kech",
"929429", "Bajaur\ Agency",
"92226", "Hyderabad",
"92257", "Dadu",
"92743", "Larkana",
"92568", "Sheikhupura",
"92513", "Islamabad\/Rawalpindi",
"929468", "Swat",
"922423", "Naushero\ Feroze",
"929454", "Lower\ Dir",
"928252", "Chagai",
"929393", "Buner",
"92644", "Dera\ Ghazi\ Khan",
"928448", "Kalat",
"92469", "Toba\ Tek\ Singh",
"922383", "Umerkot",
"924533", "Bhakkar",
"929389", "Swabi",
"929927", "Abottabad",
"92476", "Jhang",
"928356", "Dera\ Bugti",
"92406", "Sahiwal",
"926067", "Layyah",
"925438", "Chakwal",
"92916", "Peshawar\/Charsadda",
"92617", "Multan",
"922325", "Tharparkar",
"926046", "Rajanpur",
"928239", "Killa\ Saifullah",
"922436", "Khairpur",
"92716", "Sukkur",
"929973", "Mansehra\/Batagram",
"922979", "Badin",
"927266", "Shikarpur",
"928536", "Lasbela",
"92423", "Lahore",
"925427", "Narowal",
"922449", "Nawabshah",
"928246", "Loralai",
"92639", "Bahawalnagar",
"929443", "Upper\ Dir",
"92814", "Quetta",
"92672", "Vehari",
"924578", "Pakpattan",
"928267", "K\.Abdullah\/Pishin",
"928382", "Jaffarabad\/Nasirabad",
"929953", "Haripur",
"92483", "Sargodha",
"925444", "Jhelum",
"92564", "Sheikhupura",
"929425", "Bajaur\ Agency",
"928328", "Bolan",
"928376", "Jhal\ Magsi",
"92632", "Bahawalnagar",
"92615", "Multan",
"924596", "Mianwali",
"92679", "Vehari",
"929692", "Lakki\ Marwat",
"929663", "D\.I\.\ Khan",
"929224", "Kohat",
"928557", "Panjgur",
"929377", "Mardan",
"928337", "Sibi\/Ziarat",
"927224", "Jacobabad",
"92648", "Dera\ Ghazi\ Khan",
"928488", "Khuzdar",
"929385", "Swabi",
"92214", "Karachi",
"929322", "Malakand",
"928449", "Kalat",
"928477", "Kharan",
"929437", "Chitral",
"929967", "Shangla",
"92497", "Kasur",
"928485", "Khuzdar",
"929388", "Swabi",
"926084", "Lodhran",
"92527", "Sialkot",
"928284", "Musakhel",
"92556", "Gujranwala",
"928436", "Mastung",
"92574", "Attock",
"929657", "South\ Waziristan",
"928325", "Bolan",
"929428", "Bajaur\ Agency",
"927233", "Ghotki",
"92669", "Muzaffargarh",
"928563", "Awaran",
"929469", "Swat",
"922356", "Sanghar",
"92222", "Hyderabad",
"92444", "Okara",
"92495", "Kasur",
"92534", "Gujrat",
"929636", "Tank",
"92928", "Bannu\/N\.\ Waziristan",
"922337", "Mirpur\ Khas",
"92658", "Khanewal",
"925472", "Hafizabad",
"922422", "Naushero\ Feroze",
"92662", "Muzaffargarh",
"924575", "Pakpattan",
"92229", "Hyderabad",
"928522", "Kech",
"92466", "Toba\ Tek\ Singh",
"929456", "Lower\ Dir",
"925435", "Chakwal",
"928253", "Chagai",
"929392", "Buner",
"922328", "Tharparkar",
"92525", "Sialkot",
"924532", "Bhakkar",
"922382", "Umerkot",};
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