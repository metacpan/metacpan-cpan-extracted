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
our $VERSION = 1.20220903144942;

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
            [0-24]\\d|
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
$areanames{en} = {"926064", "Layyah",
"925429", "Narowal",
"92538", "Gujrat",
"92577", "Attock",
"928337", "Sibi\/Ziarat",
"92532", "Gujrat",
"92569", "Sheikhupura",
"922444", "Nawabshah",
"929229", "Kohat",
"928233", "Killa\ Saifullah",
"92256", "Dadu",
"929393", "Buner",
"929692", "Lakki\ Marwat",
"929322", "Malakand",
"922353", "Sanghar",
"92636", "Bahawalnagar",
"929929", "Abottabad",
"92683", "Rahim\ Yar\ Khan",
"928434", "Mastung",
"924539", "Bhakkar",
"929382", "Swabi",
"928559", "Panjgur",
"928264", "K\.Abdullah\/Pishin",
"92408", "Sahiwal",
"928535", "Lasbela",
"92672", "Vehari",
"928338", "Sibi\/Ziarat",
"92678", "Vehari",
"92637", "Bahawalnagar",
"92402", "Sahiwal",
"92257", "Dadu",
"928473", "Kharan",
"929452", "Lower\ Dir",
"92515", "Islamabad\/Rawalpindi",
"929375", "Mardan",
"927234", "Ghotki",
"92468", "Toba\ Tek\ Singh",
"922423", "Naushero\ Feroze",
"92462", "Toba\ Tek\ Singh",
"929956", "Haripur",
"929449", "Upper\ Dir",
"927263", "Shikarpur",
"92576", "Attock",
"92925", "Hangu\/Orakzai\ Agy",
"92229", "Hyderabad",
"928526", "Kech",
"922984", "Thatta",
"928383", "Jaffarabad\/Nasirabad",
"924593", "Mianwali",
"92648", "Dera\ Ghazi\ Khan",
"929966", "Shangla",
"92926", "Kurram\ Agency",
"92575", "Attock",
"926087", "Lodhran",
"922977", "Badin",
"92642", "Dera\ Ghazi\ Khan",
"928299", "Barkhan\/Kohlu",
"92516", "Islamabad\/Rawalpindi",
"929462", "Swat",
"928323", "Bolan",
"929436", "Chitral",
"92612", "Multan",
"928448", "Kalat",
"929425", "Bajaur\ Agency",
"928287", "Musakhel",
"92523", "Sialkot",
"929637", "Tank",
"928227", "Zhob",
"92913", "Peshawar\/Charsadda",
"92618", "Multan",
"925432", "Chakwal",
"922438", "Khairpur",
"925466", "Mandi\ Bahauddin",
"925476", "Hafizabad",
"928254", "Chagai",
"92624", "Bahawalpur",
"928569", "Awaran",
"922334", "Mirpur\ Khas",
"924575", "Pakpattan",
"92635", "Bahawalnagar",
"926088", "Lodhran",
"922978", "Badin",
"924546", "Khushab",
"92864", "Gwadar",
"925445", "Jhelum",
"92255", "Dadu",
"92517", "Islamabad\/Rawalpindi",
"928447", "Kalat",
"928288", "Musakhel",
"92927", "Karak",
"928228", "Zhob",
"929638", "Tank",
"929976", "Mansehra\/Batagram",
"922437", "Khairpur",
"929388", "Swabi",
"928255", "Chagai",
"928479", "Kharan",
"924574", "Pakpattan",
"922335", "Mirpur\ Khas",
"928376", "Jhal\ Magsi",
"929457", "Lower\ Dir",
"92556", "Gujranwala",
"929698", "Lakki\ Marwat",
"929328", "Malakand",
"925444", "Jhelum",
"922386", "Umerkot",
"92422", "Lahore",
"927269", "Shikarpur",
"929443", "Upper\ Dir",
"92652", "Khanewal",
"92498", "Kasur",
"92492", "Kasur",
"929656", "South\ Waziristan",
"922429", "Naushero\ Feroze",
"92658", "Khanewal",
"92428", "Lahore",
"922326", "Tharparkar",
"92414", "Faisalabad",
"929387", "Swabi",
"92529", "Sialkot",
"925423", "Narowal",
"92919", "Peshawar\/Charsadda",
"929458", "Lower\ Dir",
"92215", "Karachi",
"929327", "Malakand",
"929697", "Lakki\ Marwat",
"929923", "Abottabad",
"92557", "Gujranwala",
"928553", "Panjgur",
"929424", "Bajaur\ Agency",
"924533", "Bhakkar",
"929399", "Buner",
"92444", "Okara",
"928239", "Killa\ Saifullah",
"928332", "Sibi\/Ziarat",
"929223", "Kohat",
"92485", "Sargodha",
"922359", "Sanghar",
"925438", "Chakwal",
"92486", "Sargodha",
"922432", "Khairpur",
"928534", "Lasbela",
"928356", "Dera\ Bugti",
"928563", "Awaran",
"92223", "Hyderabad",
"92664", "Muzaffargarh",
"927226", "Jacobabad",
"928442", "Kalat",
"928246", "Loralai",
"929468", "Swat",
"926046", "Rajanpur",
"92216", "Karachi",
"929374", "Mardan",
"92474", "Jhang",
"927235", "Ghotki",
"922985", "Thatta",
"925437", "Chakwal",
"926065", "Layyah",
"929666", "D\.I\.\ Khan",
"928329", "Bolan",
"929632", "Tank",
"928293", "Barkhan\/Kohlu",
"928222", "Zhob",
"928486", "Khuzdar",
"924599", "Mianwali",
"928282", "Musakhel",
"928389", "Jaffarabad\/Nasirabad",
"92689", "Rahim\ Yar\ Khan",
"92217", "Karachi",
"92744", "Larkana",
"92555", "Gujranwala",
"922445", "Nawabshah",
"929467", "Swat",
"92812", "Quetta",
"926082", "Lodhran",
"92714", "Sukkur",
"922972", "Badin",
"92818", "Quetta",
"928435", "Mastung",
"92563", "Sheikhupura",
"928265", "K\.Abdullah\/Pishin",
"92487", "Sargodha",
"92522", "Sialkot",
"929435", "Chitral",
"927268", "Shikarpur",
"92613", "Multan",
"92918", "Peshawar\/Charsadda",
"922428", "Naushero\ Feroze",
"929965", "Shangla",
"922357", "Sanghar",
"925422", "Narowal",
"92912", "Peshawar\/Charsadda",
"928237", "Killa\ Saifullah",
"929397", "Buner",
"92528", "Sialkot",
"929922", "Abottabad",
"92866", "Gwadar",
"928478", "Kharan",
"925465", "Mandi\ Bahauddin",
"924532", "Bhakkar",
"929389", "Swabi",
"928552", "Panjgur",
"928333", "Sibi\/Ziarat",
"929426", "Bajaur\ Agency",
"929222", "Kohat",
"929699", "Lakki\ Marwat",
"929329", "Malakand",
"92643", "Dera\ Ghazi\ Khan",
"92626", "Bahawalpur",
"92627", "Bahawalpur",
"925446", "Jhelum",
"927267", "Shikarpur",
"924545", "Khushab",
"924576", "Pakpattan",
"922427", "Naushero\ Feroze",
"922358", "Sanghar",
"928374", "Jhal\ Magsi",
"929398", "Buner",
"928238", "Killa\ Saifullah",
"925475", "Hafizabad",
"92867", "Gwadar",
"929442", "Upper\ Dir",
"928477", "Kharan",
"92659", "Khanewal",
"92514", "Islamabad\/Rawalpindi",
"92429", "Lahore",
"922324", "Tharparkar",
"929654", "South\ Waziristan",
"929975", "Mansehra\/Batagram",
"929459", "Lower\ Dir",
"92924", "Khyber\/Mohmand\ Agy",
"92499", "Kasur",
"922384", "Umerkot",
"92688", "Rahim\ Yar\ Khan",
"929469", "Swat",
"929633", "Tank",
"928292", "Barkhan\/Kohlu",
"928223", "Zhob",
"928484", "Khuzdar",
"92574", "Attock",
"929664", "D\.I\.\ Khan",
"928283", "Musakhel",
"92682", "Rahim\ Yar\ Khan",
"928327", "Bolan",
"922973", "Badin",
"925439", "Chakwal",
"92819", "Quetta",
"926083", "Lodhran",
"92533", "Gujrat",
"924597", "Mianwali",
"928387", "Jaffarabad\/Nasirabad",
"922433", "Khairpur",
"927224", "Jacobabad",
"92625", "Bahawalpur",
"928244", "Loralai",
"92634", "Bahawalnagar",
"928354", "Dera\ Bugti",
"928536", "Lasbela",
"928562", "Awaran",
"928443", "Kalat",
"92865", "Gwadar",
"92463", "Toba\ Tek\ Singh",
"92254", "Dadu",
"928328", "Bolan",
"928525", "Kech",
"92673", "Vehari",
"929955", "Haripur",
"929376", "Mardan",
"924598", "Mianwali",
"92403", "Sahiwal",
"926044", "Rajanpur",
"928388", "Jaffarabad\/Nasirabad",
"927225", "Jacobabad",
"928245", "Loralai",
"929228", "Kohat",
"92679", "Vehari",
"92409", "Sahiwal",
"928355", "Dera\ Bugti",
"924538", "Bhakkar",
"92667", "Muzaffargarh",
"92716", "Sukkur",
"928558", "Panjgur",
"929447", "Upper\ Dir",
"928472", "Kharan",
"929928", "Abottabad",
"92228", "Hyderabad",
"929453", "Lower\ Dir",
"92746", "Larkana",
"922986", "Thatta",
"928524", "Kech",
"92477", "Jhang",
"929954", "Haripur",
"922422", "Naushero\ Feroze",
"925428", "Narowal",
"927262", "Shikarpur",
"92469", "Toba\ Tek\ Singh",
"927236", "Ghotki",
"92222", "Hyderabad",
"926045", "Rajanpur",
"92415", "Faisalabad",
"92813", "Quetta",
"928485", "Khuzdar",
"929227", "Kohat",
"92568", "Sheikhupura",
"929665", "D\.I\.\ Khan",
"924537", "Bhakkar",
"92539", "Gujrat",
"92562", "Sheikhupura",
"92476", "Jhang",
"928557", "Panjgur",
"92747", "Larkana",
"929927", "Abottabad",
"929448", "Upper\ Dir",
"926066", "Layyah",
"92214", "Karachi",
"928232", "Killa\ Saifullah",
"929392", "Buner",
"929693", "Lakki\ Marwat",
"929323", "Malakand",
"928436", "Mastung",
"928266", "K\.Abdullah\/Pishin",
"928339", "Sibi\/Ziarat",
"92717", "Sukkur",
"925427", "Narowal",
"922352", "Sanghar",
"92666", "Muzaffargarh",
"92445", "Okara",
"92484", "Sargodha",
"922446", "Nawabshah",
"929383", "Swabi",
"92446", "Okara",
"92653", "Khanewal",
"924544", "Khushab",
"928449", "Kalat",
"92423", "Lahore",
"922336", "Mirpur\ Khas",
"92665", "Muzaffargarh",
"928375", "Jhal\ Magsi",
"922439", "Khairpur",
"925474", "Hafizabad",
"92493", "Kasur",
"928256", "Chagai",
"922325", "Tharparkar",
"929655", "South\ Waziristan",
"929974", "Mansehra\/Batagram",
"928567", "Awaran",
"92475", "Jhang",
"928298", "Barkhan\/Kohlu",
"922385", "Umerkot",
"92416", "Faisalabad",
"928289", "Musakhel",
"924592", "Mianwali",
"929434", "Chitral",
"928382", "Jaffarabad\/Nasirabad",
"92417", "Faisalabad",
"929964", "Shangla",
"92649", "Dera\ Ghazi\ Khan",
"928322", "Bolan",
"928229", "Zhob",
"92745", "Larkana",
"929639", "Tank",
"929463", "Swat",
"92619", "Multan",
"92554", "Gujranwala",
"925464", "Mandi\ Bahauddin",
"928568", "Awaran",
"92715", "Sukkur",
"928297", "Barkhan\/Kohlu",
"92447", "Okara",
"926089", "Lodhran",
"925433", "Chakwal",
"922979", "Badin",
"928352", "Dera\ Bugti",
"928564", "Awaran",
"928259", "Chagai",
"929977", "Mansehra\/Batagram",
"92742", "Larkana",
"922339", "Mirpur\ Khas",
"928475", "Kharan",
"922436", "Khairpur",
"92567", "Sheikhupura",
"925468", "Mandi\ Bahauddin",
"92483", "Sargodha",
"927222", "Jacobabad",
"92579", "Attock",
"928446", "Kalat",
"928242", "Loralai",
"92748", "Larkana",
"92226", "Hyderabad",
"928533", "Lasbela",
"927265", "Shikarpur",
"924547", "Khushab",
"92718", "Sukkur",
"92213", "Karachi",
"929438", "Chitral",
"926042", "Rajanpur",
"925477", "Hafizabad",
"92814", "Quetta",
"92712", "Sukkur",
"929968", "Shangla",
"922425", "Naushero\ Feroze",
"929373", "Mardan",
"929662", "D\.I\.\ Khan",
"92259", "Dadu",
"929636", "Tank",
"929978", "Mansehra\/Batagram",
"928226", "Zhob",
"92639", "Bahawalnagar",
"92662", "Muzaffargarh",
"925467", "Mandi\ Bahauddin",
"92668", "Muzaffargarh",
"928482", "Khuzdar",
"928294", "Barkhan\/Kohlu",
"928286", "Musakhel",
"926086", "Lodhran",
"92227", "Hyderabad",
"924548", "Khushab",
"922976", "Badin",
"92478", "Jhang",
"929437", "Chitral",
"928235", "Killa\ Saifullah",
"925478", "Hafizabad",
"92566", "Sheikhupura",
"929395", "Buner",
"92472", "Jhang",
"929967", "Shangla",
"922355", "Sanghar",
"929957", "Haripur",
"928372", "Jhal\ Magsi",
"92418", "Faisalabad",
"925443", "Jhelum",
"92565", "Sheikhupura",
"928527", "Kech",
"92553", "Gujranwala",
"92412", "Faisalabad",
"924573", "Pakpattan",
"922382", "Umerkot",
"92442", "Okara",
"927239", "Ghotki",
"929444", "Upper\ Dir",
"922322", "Tharparkar",
"92448", "Okara",
"929652", "South\ Waziristan",
"922989", "Thatta",
"929958", "Haripur",
"925424", "Narowal",
"926069", "Layyah",
"928325", "Bolan",
"928528", "Kech",
"924595", "Mianwali",
"928385", "Jaffarabad\/Nasirabad",
"922449", "Nawabshah",
"929224", "Kohat",
"92225", "Hyderabad",
"92494", "Kasur",
"929924", "Abottabad",
"92424", "Lahore",
"928439", "Mastung",
"924534", "Bhakkar",
"929423", "Bajaur\ Agency",
"928336", "Sibi\/Ziarat",
"928269", "K\.Abdullah\/Pishin",
"928554", "Panjgur",
"92519", "Islamabad\/Rawalpindi",
"92654", "Khanewal",
"92628", "Bahawalpur",
"92923", "Nowshera",
"92862", "Gwadar",
"929962", "Shangla",
"925425", "Narowal",
"928324", "Bolan",
"924594", "Mianwali",
"929466", "Swat",
"92513", "Islamabad\/Rawalpindi",
"928384", "Jaffarabad\/Nasirabad",
"926048", "Rajanpur",
"929432", "Chitral",
"92622", "Bahawalpur",
"92868", "Gwadar",
"92526", "Sialkot",
"928487", "Khuzdar",
"929225", "Kohat",
"927228", "Jacobabad",
"928248", "Loralai",
"929925", "Abottabad",
"925436", "Chakwal",
"92916", "Peshawar\/Charsadda",
"925462", "Mandi\ Bahauddin",
"929667", "D\.I\.\ Khan",
"928358", "Dera\ Bugti",
"924535", "Bhakkar",
"928555", "Panjgur",
"92685", "Rahim\ Yar\ Khan",
"928539", "Lasbela",
"92917", "Peshawar\/Charsadda",
"925472", "Hafizabad",
"92644", "Dera\ Ghazi\ Khan",
"928253", "Chagai",
"926047", "Rajanpur",
"92527", "Sialkot",
"922333", "Mirpur\ Khas",
"924542", "Khushab",
"928488", "Khuzdar",
"927227", "Jacobabad",
"929379", "Mardan",
"928247", "Loralai",
"929445", "Upper\ Dir",
"928357", "Dera\ Bugti",
"929668", "D\.I\.\ Khan",
"92614", "Multan",
"92559", "Gujranwala",
"929972", "Mansehra\/Batagram",
"929658", "South\ Waziristan",
"92404", "Sahiwal",
"922328", "Tharparkar",
"926063", "Layyah",
"92674", "Vehari",
"922388", "Umerkot",
"928295", "Barkhan\/Kohlu",
"92633", "Bahawalnagar",
"92253", "Dadu",
"92464", "Toba\ Tek\ Singh",
"928263", "K\.Abdullah\/Pishin",
"929429", "Bajaur\ Agency",
"928433", "Mastung",
"929326", "Malakand",
"929696", "Lakki\ Marwat",
"929394", "Buner",
"928234", "Killa\ Saifullah",
"929386", "Swabi",
"922443", "Nawabshah",
"92686", "Rahim\ Yar\ Khan",
"922354", "Sanghar",
"928378", "Jhal\ Magsi",
"92219", "Karachi",
"92687", "Rahim\ Yar\ Khan",
"929657", "South\ Waziristan",
"928565", "Awaran",
"928474", "Kharan",
"924579", "Pakpattan",
"922327", "Tharparkar",
"92534", "Gujrat",
"92915", "Peshawar\/Charsadda",
"922387", "Umerkot",
"92525", "Sialkot",
"925449", "Jhelum",
"927264", "Shikarpur",
"92489", "Sargodha",
"929456", "Lower\ Dir",
"922983", "Thatta",
"928522", "Kech",
"929952", "Haripur",
"922424", "Naushero\ Feroze",
"927233", "Ghotki",
"92573", "Attock",
"928377", "Jhal\ Magsi",
"929377", "Mardan",
"92426", "Lahore",
"927229", "Jacobabad",
"928249", "Loralai",
"92656", "Khanewal",
"92443", "Okara",
"925473", "Hafizabad",
"92496", "Kasur",
"928359", "Dera\ Bugti",
"928252", "Chagai",
"924543", "Khushab",
"922332", "Mirpur\ Khas",
"928537", "Lasbela",
"92558", "Gujranwala",
"92815", "Quetta",
"92413", "Faisalabad",
"92552", "Gujranwala",
"929973", "Mansehra\/Batagram",
"926049", "Rajanpur",
"929378", "Mardan",
"929963", "Shangla",
"92869", "Gwadar",
"929464", "Swat",
"928489", "Khuzdar",
"924596", "Mianwali",
"928386", "Jaffarabad\/Nasirabad",
"929433", "Chitral",
"929669", "D\.I\.\ Khan",
"928326", "Bolan",
"92629", "Bahawalpur",
"928538", "Lasbela",
"928335", "Sibi\/Ziarat",
"925434", "Chakwal",
"92497", "Kasur",
"925463", "Mandi\ Bahauddin",
"92657", "Khanewal",
"92427", "Lahore",
"929428", "Bajaur\ Agency",
"92212", "Karachi",
"92564", "Sheikhupura",
"928445", "Kalat",
"928476", "Kharan",
"922435", "Khairpur",
"928379", "Jhal\ Magsi",
"92218", "Karachi",
"92713", "Sukkur",
"924577", "Pakpattan",
"92482", "Sargodha",
"922426", "Naushero\ Feroze",
"922329", "Tharparkar",
"929659", "South\ Waziristan",
"92743", "Larkana",
"922982", "Thatta",
"928523", "Kech",
"929454", "Lower\ Dir",
"92817", "Quetta",
"925447", "Jhelum",
"922389", "Umerkot",
"927266", "Shikarpur",
"92488", "Sargodha",
"929953", "Haripur",
"927232", "Ghotki",
"929427", "Bajaur\ Agency",
"928285", "Musakhel",
"92816", "Quetta",
"926062", "Layyah",
"92473", "Jhang",
"929635", "Tank",
"928225", "Zhob",
"924578", "Pakpattan",
"92663", "Muzaffargarh",
"92224", "Hyderabad",
"922356", "Sanghar",
"929384", "Swabi",
"928236", "Killa\ Saifullah",
"929396", "Buner",
"92495", "Kasur",
"928432", "Mastung",
"928262", "K\.Abdullah\/Pishin",
"922442", "Nawabshah",
"929694", "Lakki\ Marwat",
"929324", "Malakand",
"925448", "Jhelum",
"92425", "Lahore",
"926085", "Lodhran",
"922975", "Badin",
"92655", "Khanewal",
"928284", "Musakhel",
"928296", "Barkhan\/Kohlu",
"929663", "D\.I\.\ Khan",
"929439", "Chitral",
"92252", "Dadu",
"92407", "Sahiwal",
"92632", "Bahawalnagar",
"92669", "Muzaffargarh",
"929969", "Shangla",
"92677", "Vehari",
"92638", "Bahawalnagar",
"92258", "Dadu",
"928224", "Zhob",
"928483", "Khuzdar",
"929634", "Tank",
"922338", "Mirpur\ Khas",
"925469", "Mandi\ Bahauddin",
"929385", "Swabi",
"928258", "Chagai",
"92467", "Toba\ Tek\ Singh",
"92479", "Jhang",
"92536", "Gujrat",
"929325", "Malakand",
"929695", "Lakki\ Marwat",
"926084", "Lodhran",
"922974", "Badin",
"92749", "Larkana",
"92684", "Rahim\ Yar\ Khan",
"928353", "Dera\ Bugti",
"92578", "Attock",
"92537", "Gujrat",
"924549", "Khushab",
"928444", "Kalat",
"92645", "Dera\ Ghazi\ Khan",
"928243", "Loralai",
"92466", "Toba\ Tek\ Singh",
"92572", "Attock",
"927223", "Jacobabad",
"922434", "Khairpur",
"925479", "Hafizabad",
"928532", "Lasbela",
"928566", "Awaran",
"922337", "Mirpur\ Khas",
"92676", "Vehari",
"926043", "Rajanpur",
"929979", "Mansehra\/Batagram",
"928257", "Chagai",
"92719", "Sukkur",
"929455", "Lower\ Dir",
"92406", "Sahiwal",
"929372", "Mardan",
"92615", "Multan",
"927238", "Ghotki",
"92616", "Multan",
"922447", "Nawabshah",
"929465", "Swat",
"92405", "Sahiwal",
"928437", "Mastung",
"92675", "Vehari",
"922988", "Thatta",
"928267", "K\.Abdullah\/Pishin",
"925426", "Narowal",
"924536", "Bhakkar",
"92998", "Kohistan",
"928556", "Panjgur",
"928334", "Sibi\/Ziarat",
"92518", "Islamabad\/Rawalpindi",
"92465", "Toba\ Tek\ Singh",
"929926", "Abottabad",
"925435", "Chakwal",
"92863", "Gwadar",
"926067", "Layyah",
"92928", "Bannu\/N\.\ Waziristan",
"92623", "Bahawalpur",
"92646", "Dera\ Ghazi\ Khan",
"929422", "Bajaur\ Agency",
"92512", "Islamabad\/Rawalpindi",
"929226", "Kohat",
"928373", "Jhal\ Magsi",
"927237", "Ghotki",
"92647", "Dera\ Ghazi\ Khan",
"922448", "Nawabshah",
"925442", "Jhelum",
"92535", "Gujrat",
"92914", "Peshawar\/Charsadda",
"928438", "Mastung",
"922987", "Thatta",
"9258", "AJK\/FATA",
"928268", "K\.Abdullah\/Pishin",
"924572", "Pakpattan",
"92524", "Sialkot",
"92419", "Faisalabad",
"928529", "Kech",
"929446", "Upper\ Dir",
"929959", "Haripur",
"922383", "Umerkot",
"92449", "Okara",
"926068", "Layyah",
"922323", "Tharparkar",
"92617", "Multan",
"929653", "South\ Waziristan",};

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