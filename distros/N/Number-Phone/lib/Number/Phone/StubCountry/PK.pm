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
our $VERSION = 1.20240607153921;

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
$areanames{en} = {"92612", "Multan",
"928386", "Jaffarabad\/Nasirabad",
"92552", "Gujranwala",
"929922", "Abottabad",
"922447", "Nawabshah",
"92444", "Okara",
"928372", "Jhal\ Magsi",
"927235", "Ghotki",
"92257", "Dadu",
"924577", "Pakpattan",
"928235", "Killa\ Saifullah",
"929928", "Abottabad",
"928378", "Jhal\ Magsi",
"929953", "Haripur",
"92215", "Karachi",
"92913", "Peshawar\/Charsadda",
"928568", "Awaran",
"92672", "Vehari",
"925423", "Narowal",
"92224", "Hyderabad",
"929329", "Malakand",
"929383", "Swabi",
"929375", "Mardan",
"928439", "Mastung",
"924599", "Mianwali",
"924543", "Khushab",
"928562", "Awaran",
"927237", "Ghotki",
"92679", "Vehari",
"928237", "Killa\ Saifullah",
"925449", "Jhelum",
"929399", "Buner",
"924575", "Pakpattan",
"92228", "Hyderabad",
"928533", "Lasbela",
"929924", "Abottabad",
"928374", "Jhal\ Magsi",
"922445", "Nawabshah",
"92633", "Bahawalnagar",
"928564", "Awaran",
"928266", "K\.Abdullah\/Pishin",
"929377", "Mardan",
"92865", "Gwadar",
"927266", "Shikarpur",
"92559", "Gujranwala",
"92619", "Multan",
"92448", "Okara",
"92743", "Larkana",
"928282", "Musakhel",
"92413", "Faisalabad",
"92718", "Sukkur",
"92513", "Islamabad\/Rawalpindi",
"922325", "Tharparkar",
"92653", "Khanewal",
"92818", "Quetta",
"928288", "Musakhel",
"929423", "Bajaur\ Agency",
"928333", "Sibi\/Ziarat",
"928244", "Loralai",
"926089", "Lodhran",
"928259", "Chagai",
"922438", "Khairpur",
"92539", "Gujrat",
"922978", "Badin",
"929458", "Lower\ Dir",
"929632", "Tank",
"922356", "Sanghar",
"922432", "Khairpur",
"92473", "Jhang",
"922986", "Thatta",
"922972", "Badin",
"92573", "Attock",
"929452", "Lower\ Dir",
"929638", "Tank",
"92532", "Gujrat",
"926049", "Rajanpur",
"928284", "Musakhel",
"922327", "Tharparkar",
"929663", "D\.I\.\ Khan",
"924536", "Bhakkar",
"929449", "Upper\ Dir",
"929454", "Lower\ Dir",
"922974", "Badin",
"928248", "Loralai",
"922434", "Khairpur",
"92714", "Sukkur",
"929634", "Tank",
"92256", "Dadu",
"92814", "Quetta",
"928242", "Loralai",
"928525", "Kech",
"925466", "Mandi\ Bahauddin",
"928445", "Kalat",
"926042", "Rajanpur",
"92523", "Sialkot",
"92662", "Muzaffargarh",
"92423", "Lahore",
"926048", "Rajanpur",
"928556", "Panjgur",
"929448", "Upper\ Dir",
"928487", "Khuzdar",
"928293", "Barkhan\/Kohlu",
"928254", "Chagai",
"92407", "Sahiwal",
"926084", "Lodhran",
"925437", "Chakwal",
"928249", "Loralai",
"92492", "Kasur",
"929442", "Upper\ Dir",
"929965", "Shangla",
"92499", "Kasur",
"92483", "Sargodha",
"928447", "Kalat",
"928527", "Kech",
"926044", "Rajanpur",
"928289", "Musakhel",
"928223", "Zhob",
"92646", "Dera\ Ghazi\ Khan",
"927223", "Jacobabad",
"922386", "Umerkot",
"929226", "Kohat",
"922439", "Khairpur",
"92669", "Muzaffargarh",
"928258", "Chagai",
"929967", "Shangla",
"926088", "Lodhran",
"922979", "Badin",
"929459", "Lower\ Dir",
"929444", "Upper\ Dir",
"926082", "Lodhran",
"928252", "Chagai",
"928473", "Kharan",
"92815", "Quetta",
"928485", "Khuzdar",
"925435", "Chakwal",
"92715", "Sukkur",
"929639", "Tank",
"929398", "Buner",
"925448", "Jhelum",
"92445", "Okara",
"929977", "Mansehra\/Batagram",
"928327", "Bolan",
"929437", "Chitral",
"92463", "Toba\ Tek\ Singh",
"929392", "Buner",
"925442", "Jhelum",
"929696", "Lakki\ Marwat",
"929657", "South\ Waziristan",
"92868", "Gwadar",
"92622", "Bahawalpur",
"92563", "Sheikhupura",
"926066", "Layyah",
"929466", "Swat",
"92214", "Karachi",
"92923", "Nowshera",
"92689", "Rahim\ Yar\ Khan",
"924594", "Mianwali",
"928434", "Mastung",
"929324", "Malakand",
"92225", "Hyderabad",
"92647", "Dera\ Ghazi\ Khan",
"92682", "Rahim\ Yar\ Khan",
"922333", "Mirpur\ Khas",
"92406", "Sahiwal",
"925444", "Jhelum",
"929655", "South\ Waziristan",
"929394", "Buner",
"929975", "Mansehra\/Batagram",
"92218", "Karachi",
"928325", "Bolan",
"929435", "Chitral",
"928379", "Jhal\ Magsi",
"929929", "Abottabad",
"92864", "Gwadar",
"929322", "Malakand",
"925476", "Hafizabad",
"928569", "Awaran",
"92629", "Bahawalpur",
"924592", "Mianwali",
"928432", "Mastung",
"929328", "Malakand",
"922426", "Naushero\ Feroze",
"928356", "Dera\ Bugti",
"924598", "Mianwali",
"928438", "Mastung",
"92494", "Kasur",
"929422", "Bajaur\ Agency",
"928332", "Sibi\/Ziarat",
"924537", "Bhakkar",
"929664", "D\.I\.\ Khan",
"92253", "Dadu",
"928283", "Musakhel",
"929428", "Bajaur\ Agency",
"922326", "Tharparkar",
"928338", "Sibi\/Ziarat",
"927229", "Jacobabad",
"928229", "Zhob",
"922433", "Khairpur",
"92664", "Muzaffargarh",
"922985", "Thatta",
"92917", "Peshawar\/Charsadda",
"929453", "Lower\ Dir",
"922973", "Badin",
"922355", "Sanghar",
"929633", "Tank",
"928479", "Kharan",
"924535", "Bhakkar",
"929662", "D\.I\.\ Khan",
"928334", "Sibi\/Ziarat",
"92476", "Jhang",
"929668", "D\.I\.\ Khan",
"92576", "Attock",
"92637", "Bahawalnagar",
"92668", "Muzaffargarh",
"929424", "Bajaur\ Agency",
"92416", "Faisalabad",
"922357", "Sanghar",
"92516", "Islamabad\/Rawalpindi",
"92535", "Gujrat",
"92656", "Khanewal",
"928243", "Loralai",
"928299", "Barkhan\/Kohlu",
"92498", "Kasur",
"922987", "Thatta",
"92747", "Larkana",
"922339", "Mirpur\ Khas",
"92417", "Faisalabad",
"928534", "Lasbela",
"928236", "Killa\ Saifullah",
"92688", "Rahim\ Yar\ Khan",
"92517", "Islamabad\/Rawalpindi",
"92675", "Vehari",
"92657", "Khanewal",
"927236", "Ghotki",
"92746", "Larkana",
"929923", "Abottabad",
"92212", "Karachi",
"928373", "Jhal\ Magsi",
"928385", "Jaffarabad\/Nasirabad",
"92869", "Gwadar",
"927267", "Shikarpur",
"925422", "Narowal",
"928267", "K\.Abdullah\/Pishin",
"929376", "Mardan",
"929958", "Haripur",
"929382", "Swabi",
"928563", "Awaran",
"924542", "Khushab",
"92624", "Bahawalpur",
"925428", "Narowal",
"92477", "Jhang",
"929952", "Haripur",
"929388", "Swabi",
"92555", "Gujranwala",
"92577", "Attock",
"924548", "Khushab",
"92615", "Multan",
"92636", "Bahawalnagar",
"922446", "Nawabshah",
"928387", "Jaffarabad\/Nasirabad",
"928538", "Lasbela",
"92916", "Peshawar\/Charsadda",
"92998", "Kohistan",
"92862", "Gwadar",
"92628", "Bahawalpur",
"924576", "Pakpattan",
"928532", "Lasbela",
"92219", "Karachi",
"929954", "Haripur",
"927265", "Shikarpur",
"92684", "Rahim\ Yar\ Khan",
"929384", "Swabi",
"924544", "Khushab",
"928265", "K\.Abdullah\/Pishin",
"925424", "Narowal",
"926065", "Layyah",
"929393", "Buner",
"925443", "Jhelum",
"92674", "Vehari",
"929695", "Lakki\ Marwat",
"92222", "Hyderabad",
"928539", "Lasbela",
"922334", "Mirpur\ Khas",
"92527", "Sialkot",
"92427", "Lahore",
"92625", "Bahawalpur",
"92403", "Sahiwal",
"925477", "Hafizabad",
"92554", "Gujranwala",
"92614", "Multan",
"929465", "Swat",
"928357", "Dera\ Bugti",
"92442", "Okara",
"922427", "Naushero\ Feroze",
"92487", "Sargodha",
"929436", "Chitral",
"922338", "Mirpur\ Khas",
"92558", "Gujranwala",
"92618", "Multan",
"928326", "Bolan",
"929976", "Mansehra\/Batagram",
"92449", "Okara",
"92926", "Kurram\ Agency",
"926067", "Layyah",
"929697", "Lakki\ Marwat",
"929656", "South\ Waziristan",
"922332", "Mirpur\ Khas",
"929959", "Haripur",
"928355", "Dera\ Bugti",
"929467", "Swat",
"922425", "Naushero\ Feroze",
"92466", "Toba\ Tek\ Singh",
"929323", "Malakand",
"92229", "Hyderabad",
"925429", "Narowal",
"925475", "Hafizabad",
"92678", "Vehari",
"924549", "Khushab",
"929389", "Swabi",
"928433", "Mastung",
"92566", "Sheikhupura",
"924593", "Mianwali",
"92685", "Rahim\ Yar\ Khan",
"92495", "Kasur",
"922387", "Umerkot",
"928224", "Zhob",
"92467", "Toba\ Tek\ Singh",
"927224", "Jacobabad",
"92567", "Sheikhupura",
"926043", "Rajanpur",
"92538", "Gujrat",
"928446", "Kalat",
"925465", "Mandi\ Bahauddin",
"928526", "Kech",
"929669", "D\.I\.\ Khan",
"929443", "Upper\ Dir",
"92486", "Sargodha",
"92665", "Muzaffargarh",
"928298", "Barkhan\/Kohlu",
"929966", "Shangla",
"929227", "Kohat",
"928474", "Kharan",
"92719", "Sukkur",
"92927", "Karak",
"92819", "Quetta",
"92643", "Dera\ Ghazi\ Khan",
"928292", "Barkhan\/Kohlu",
"928555", "Panjgur",
"922385", "Umerkot",
"92712", "Sukkur",
"92812", "Quetta",
"928222", "Zhob",
"925467", "Mandi\ Bahauddin",
"927222", "Jacobabad",
"929429", "Bajaur\ Agency",
"9258", "AJK\/FATA",
"928228", "Zhob",
"927228", "Jacobabad",
"928339", "Sibi\/Ziarat",
"928294", "Barkhan\/Kohlu",
"925436", "Chakwal",
"926083", "Lodhran",
"92534", "Gujrat",
"928486", "Khuzdar",
"928253", "Chagai",
"928472", "Kharan",
"928557", "Panjgur",
"92526", "Sialkot",
"928478", "Kharan",
"92426", "Lahore",
"929225", "Kohat",
"92522", "Sialkot",
"92663", "Muzaffargarh",
"922443", "Nawabshah",
"928384", "Jaffarabad\/Nasirabad",
"92422", "Lahore",
"92645", "Dera\ Ghazi\ Khan",
"928535", "Lasbela",
"92227", "Hyderabad",
"929699", "Lakki\ Marwat",
"924573", "Pakpattan",
"926069", "Layyah",
"92489", "Sargodha",
"92493", "Kasur",
"929469", "Swat",
"927268", "Shikarpur",
"929957", "Haripur",
"92447", "Okara",
"928268", "K\.Abdullah\/Pishin",
"92816", "Quetta",
"929387", "Swabi",
"92716", "Sukkur",
"924547", "Khushab",
"92254", "Dadu",
"927262", "Shikarpur",
"925427", "Narowal",
"928262", "K\.Abdullah\/Pishin",
"928537", "Lasbela",
"928388", "Jaffarabad\/Nasirabad",
"927233", "Ghotki",
"928233", "Killa\ Saifullah",
"92258", "Dadu",
"92482", "Sargodha",
"928382", "Jaffarabad\/Nasirabad",
"928376", "Jhal\ Magsi",
"929926", "Abottabad",
"927264", "Shikarpur",
"929385", "Swabi",
"929373", "Mardan",
"924545", "Khushab",
"928264", "K\.Abdullah\/Pishin",
"925479", "Hafizabad",
"925425", "Narowal",
"928566", "Awaran",
"922429", "Naushero\ Feroze",
"92529", "Sialkot",
"928359", "Dera\ Bugti",
"92429", "Lahore",
"929955", "Haripur",
"929665", "D\.I\.\ Khan",
"92405", "Sahiwal",
"925469", "Mandi\ Bahauddin",
"92462", "Toba\ Tek\ Singh",
"92623", "Bahawalpur",
"924532", "Bhakkar",
"92562", "Sheikhupura",
"928337", "Sibi\/Ziarat",
"924538", "Bhakkar",
"929427", "Bajaur\ Agency",
"928559", "Panjgur",
"922354", "Sanghar",
"928246", "Loralai",
"922984", "Thatta",
"928335", "Sibi\/Ziarat",
"92446", "Okara",
"929425", "Bajaur\ Agency",
"922323", "Tharparkar",
"924534", "Bhakkar",
"929667", "D\.I\.\ Khan",
"92717", "Sukkur",
"92683", "Rahim\ Yar\ Khan",
"92817", "Quetta",
"928286", "Musakhel",
"922389", "Umerkot",
"929229", "Kohat",
"922982", "Thatta",
"922436", "Khairpur",
"929456", "Lower\ Dir",
"922976", "Badin",
"922358", "Sanghar",
"922988", "Thatta",
"92226", "Hyderabad",
"92469", "Toba\ Tek\ Singh",
"92569", "Sheikhupura",
"922352", "Sanghar",
"929636", "Tank",
"928225", "Zhob",
"927225", "Jacobabad",
"922382", "Umerkot",
"925464", "Mandi\ Bahauddin",
"92404", "Sahiwal",
"92613", "Multan",
"92553", "Gujranwala",
"922388", "Umerkot",
"92749", "Larkana",
"928475", "Kharan",
"928483", "Khuzdar",
"926086", "Lodhran",
"928256", "Chagai",
"928297", "Barkhan\/Kohlu",
"92673", "Vehari",
"929228", "Kohat",
"925433", "Chakwal",
"92866", "Gwadar",
"922359", "Sanghar",
"928554", "Panjgur",
"929222", "Kohat",
"922989", "Thatta",
"92639", "Bahawalnagar",
"92912", "Peshawar\/Charsadda",
"925468", "Mandi\ Bahauddin",
"92632", "Bahawalnagar",
"92919", "Peshawar\/Charsadda",
"922384", "Umerkot",
"928227", "Zhob",
"925462", "Mandi\ Bahauddin",
"927227", "Jacobabad",
"926046", "Rajanpur",
"928443", "Kalat",
"928523", "Kech",
"924539", "Bhakkar",
"929446", "Upper\ Dir",
"928558", "Panjgur",
"92742", "Larkana",
"929224", "Kohat",
"92216", "Karachi",
"929963", "Shangla",
"928295", "Barkhan\/Kohlu",
"928477", "Kharan",
"928552", "Panjgur",
"92408", "Sahiwal",
"928389", "Jaffarabad\/Nasirabad",
"929433", "Chitral",
"929973", "Mansehra\/Batagram",
"92217", "Karachi",
"928323", "Bolan",
"929653", "South\ Waziristan",
"926064", "Layyah",
"92412", "Faisalabad",
"929694", "Lakki\ Marwat",
"92512", "Islamabad\/Rawalpindi",
"92644", "Dera\ Ghazi\ Khan",
"922335", "Mirpur\ Khas",
"92652", "Khanewal",
"925478", "Hafizabad",
"928352", "Dera\ Bugti",
"92472", "Jhang",
"922422", "Naushero\ Feroze",
"929464", "Swat",
"92572", "Attock",
"928358", "Dera\ Bugti",
"925472", "Hafizabad",
"929326", "Malakand",
"922428", "Naushero\ Feroze",
"92255", "Dadu",
"924596", "Mianwali",
"928436", "Mastung",
"92867", "Gwadar",
"92533", "Gujrat",
"929396", "Buner",
"925446", "Jhelum",
"926062", "Layyah",
"922337", "Mirpur\ Khas",
"929692", "Lakki\ Marwat",
"92479", "Jhang",
"926068", "Layyah",
"92579", "Attock",
"929698", "Lakki\ Marwat",
"929468", "Swat",
"92419", "Faisalabad",
"92648", "Dera\ Ghazi\ Khan",
"925474", "Hafizabad",
"928269", "K\.Abdullah\/Pishin",
"92659", "Khanewal",
"92519", "Islamabad\/Rawalpindi",
"927269", "Shikarpur",
"929462", "Swat",
"928354", "Dera\ Bugti",
"922424", "Naushero\ Feroze",
"92638", "Bahawalnagar",
"92667", "Muzaffargarh",
"92914", "Peshawar\/Charsadda",
"92223", "Hyderabad",
"924533", "Bhakkar",
"928287", "Musakhel",
"92925", "Hangu\/Orakzai\ Agy",
"922324", "Tharparkar",
"928449", "Kalat",
"929666", "D\.I\.\ Khan",
"928529", "Kech",
"929457", "Lower\ Dir",
"922977", "Badin",
"92497", "Kasur",
"92748", "Larkana",
"922437", "Khairpur",
"92443", "Okara",
"929969", "Shangla",
"928245", "Loralai",
"929637", "Tank",
"92686", "Rahim\ Yar\ Khan",
"92565", "Sheikhupura",
"92465", "Toba\ Tek\ Singh",
"92402", "Sahiwal",
"922322", "Tharparkar",
"928285", "Musakhel",
"92409", "Sahiwal",
"929426", "Bajaur\ Agency",
"922328", "Tharparkar",
"92744", "Larkana",
"928336", "Sibi\/Ziarat",
"929635", "Tank",
"925439", "Chakwal",
"928247", "Loralai",
"928489", "Khuzdar",
"92626", "Bahawalpur",
"922353", "Sanghar",
"922983", "Thatta",
"922975", "Badin",
"929455", "Lower\ Dir",
"92918", "Peshawar\/Charsadda",
"92634", "Bahawalnagar",
"922435", "Khairpur",
"927234", "Ghotki",
"922448", "Nawabshah",
"928234", "Killa\ Saifullah",
"928536", "Lasbela",
"924572", "Pakpattan",
"92627", "Bahawalpur",
"92474", "Jhang",
"929927", "Abottabad",
"922442", "Nawabshah",
"928377", "Jhal\ Magsi",
"924578", "Pakpattan",
"92574", "Attock",
"92414", "Faisalabad",
"928567", "Awaran",
"929374", "Mardan",
"927263", "Shikarpur",
"92654", "Khanewal",
"928263", "K\.Abdullah\/Pishin",
"92514", "Islamabad\/Rawalpindi",
"92642", "Dera\ Ghazi\ Khan",
"92425", "Lahore",
"92525", "Sialkot",
"929925", "Abottabad",
"928375", "Jhal\ Magsi",
"928383", "Jaffarabad\/Nasirabad",
"92496", "Kasur",
"929439", "Chitral",
"927238", "Ghotki",
"928329", "Bolan",
"922444", "Nawabshah",
"929979", "Mansehra\/Batagram",
"928238", "Killa\ Saifullah",
"92813", "Quetta",
"92687", "Rahim\ Yar\ Khan",
"92658", "Khanewal",
"929659", "South\ Waziristan",
"92518", "Islamabad\/Rawalpindi",
"924574", "Pakpattan",
"92713", "Sukkur",
"92418", "Faisalabad",
"927232", "Ghotki",
"92649", "Dera\ Ghazi\ Khan",
"928232", "Killa\ Saifullah",
"929378", "Mardan",
"929956", "Haripur",
"92666", "Muzaffargarh",
"92578", "Attock",
"92478", "Jhang",
"92485", "Sargodha",
"929372", "Mardan",
"928565", "Awaran",
"925426", "Narowal",
"924546", "Khushab",
"929386", "Swabi",
"929438", "Chitral",
"929652", "South\ Waziristan",
"922336", "Mirpur\ Khas",
"92252", "Dadu",
"929397", "Buner",
"925447", "Jhelum",
"928239", "Killa\ Saifullah",
"929978", "Mansehra\/Batagram",
"928328", "Bolan",
"927239", "Ghotki",
"92617", "Multan",
"92557", "Gujranwala",
"929432", "Chitral",
"92575", "Attock",
"929658", "South\ Waziristan",
"92488", "Sargodha",
"929972", "Mansehra\/Batagram",
"92475", "Jhang",
"928322", "Bolan",
"92655", "Khanewal",
"92677", "Vehari",
"925473", "Hafizabad",
"92536", "Gujrat",
"92515", "Islamabad\/Rawalpindi",
"928435", "Mastung",
"924595", "Mianwali",
"929379", "Mardan",
"929325", "Malakand",
"92415", "Faisalabad",
"928353", "Dera\ Bugti",
"92524", "Sialkot",
"922423", "Naushero\ Feroze",
"92424", "Lahore",
"929974", "Mansehra\/Batagram",
"922449", "Nawabshah",
"92428", "Lahore",
"928324", "Bolan",
"929434", "Chitral",
"92528", "Sialkot",
"924579", "Pakpattan",
"926063", "Layyah",
"929654", "South\ Waziristan",
"925445", "Jhelum",
"929395", "Buner",
"929693", "Lakki\ Marwat",
"92484", "Sargodha",
"929463", "Swat",
"924597", "Mianwali",
"92259", "Dadu",
"928437", "Mastung",
"929327", "Malakand",
"92915", "Peshawar\/Charsadda",
"92213", "Karachi",
"928524", "Kech",
"928444", "Kalat",
"922329", "Tharparkar",
"926047", "Rajanpur",
"92924", "Khyber\/Mohmand\ Agy",
"922383", "Umerkot",
"927226", "Jacobabad",
"928226", "Zhob",
"928488", "Khuzdar",
"929964", "Shangla",
"925438", "Chakwal",
"929223", "Kohat",
"929447", "Upper\ Dir",
"928482", "Khuzdar",
"92464", "Toba\ Tek\ Singh",
"925432", "Chakwal",
"92564", "Sheikhupura",
"928255", "Chagai",
"926085", "Lodhran",
"928476", "Kharan",
"92568", "Sheikhupura",
"92676", "Vehari",
"92863", "Gwadar",
"926045", "Rajanpur",
"92537", "Gujrat",
"925463", "Mandi\ Bahauddin",
"928442", "Kalat",
"928522", "Kech",
"92468", "Toba\ Tek\ Singh",
"92745", "Larkana",
"928528", "Kech",
"928448", "Kalat",
"928553", "Panjgur",
"928484", "Khuzdar",
"929968", "Shangla",
"925434", "Chakwal",
"926087", "Lodhran",
"928257", "Chagai",
"92928", "Bannu\/N\.\ Waziristan",
"928296", "Barkhan\/Kohlu",
"92635", "Bahawalnagar",
"92616", "Multan",
"92556", "Gujranwala",
"929962", "Shangla",
"929445", "Upper\ Dir",};
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