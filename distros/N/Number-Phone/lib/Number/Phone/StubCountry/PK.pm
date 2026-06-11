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
our $VERSION = 1.20260610205504;

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
$areanames{en} = {"92554", "Gujranwala",
"92524", "Sialkot",
"929327", "Malakand",
"925449", "Jhelum",
"92519", "Islamabad\/Rawalpindi",
"92744", "Larkana",
"92618", "Multan",
"92479", "Jhang",
"922353", "Sanghar",
"929328", "Malakand",
"928297", "Barkhan\/Kohlu",
"926089", "Lodhran",
"928298", "Barkhan\/Kohlu",
"928335", "Sibi\/Ziarat",
"928487", "Khuzdar",
"928359", "Dera\ Bugti",
"928488", "Khuzdar",
"92485", "Sargodha",
"92718", "Sukkur",
"92644", "Dera\ Ghazi\ Khan",
"92664", "Muzaffargarh",
"925473", "Hafizabad",
"92923", "Nowshera",
"92646", "Dera\ Ghazi\ Khan",
"92815", "Quetta",
"92673", "Vehari",
"929439", "Chitral",
"925476", "Hafizabad",
"92666", "Muzaffargarh",
"922985", "Thatta",
"929639", "Tank",
"928234", "Killa\ Saifullah",
"928534", "Lasbela",
"925422", "Narowal",
"92639", "Bahawalnagar",
"92538", "Gujrat",
"927222", "Jacobabad",
"929965", "Shangla",
"928532", "Lasbela",
"928232", "Killa\ Saifullah",
"92403", "Sahiwal",
"929455", "Lower\ Dir",
"925469", "Mandi\ Bahauddin",
"92526", "Sialkot",
"92556", "Gujranwala",
"927224", "Jacobabad",
"922356", "Sanghar",
"929655", "South\ Waziristan",
"927269", "Shikarpur",
"92746", "Larkana",
"925424", "Narowal",
"929323", "Malakand",
"922358", "Sanghar",
"929399", "Buner",
"92228", "Hyderabad",
"92258", "Dadu",
"922357", "Sanghar",
"929469", "Swat",
"92676", "Vehari",
"92643", "Dera\ Ghazi\ Khan",
"928229", "Zhob",
"928529", "Kech",
"928382", "Jaffarabad\/Nasirabad",
"92926", "Kurram\ Agency",
"928293", "Barkhan\/Kohlu",
"92862", "Gwadar",
"928264", "K\.Abdullah\/Pishin",
"928564", "Awaran",
"929669", "D\.I\.\ Khan",
"924574", "Pakpattan",
"92663", "Muzaffargarh",
"929424", "Bajaur\ Agency",
"92523", "Sialkot",
"92553", "Gujranwala",
"928483", "Khuzdar",
"925439", "Chakwal",
"92743", "Larkana",
"927239", "Ghotki",
"929422", "Bajaur\ Agency",
"925478", "Hafizabad",
"924572", "Pakpattan",
"928562", "Awaran",
"928262", "K\.Abdullah\/Pishin",
"928384", "Jaffarabad\/Nasirabad",
"925477", "Hafizabad",
"92406", "Sahiwal",
"929959", "Haripur",
"928242", "Loralai",
"929374", "Mardan",
"92404", "Sahiwal",
"928486", "Khuzdar",
"92469", "Toba\ Tek\ Singh",
"924599", "Mianwali",
"92449", "Okara",
"92924", "Khyber\/Mohmand\ Agy",
"928296", "Barkhan\/Kohlu",
"92674", "Vehari",
"929449", "Upper\ Dir",
"92919", "Peshawar\/Charsadda",
"928285", "Musakhel",
"92428", "Lahore",
"929372", "Mardan",
"928244", "Loralai",
"929326", "Malakand",
"922425", "Naushero\ Feroze",
"929329", "Malakand",
"929393", "Buner",
"925447", "Jhelum",
"928375", "Jhal\ Magsi",
"925448", "Jhelum",
"924542", "Khushab",
"929446", "Upper\ Dir",
"926087", "Lodhran",
"929463", "Swat",
"928523", "Kech",
"929694", "Lakki\ Marwat",
"928223", "Zhob",
"928299", "Barkhan\/Kohlu",
"926088", "Lodhran",
"92869", "Gwadar",
"929663", "D\.I\.\ Khan",
"922384", "Umerkot",
"924544", "Khushab",
"925433", "Chakwal",
"928358", "Dera\ Bugti",
"928489", "Khuzdar",
"928357", "Dera\ Bugti",
"924596", "Mianwali",
"927233", "Ghotki",
"922382", "Umerkot",
"929692", "Lakki\ Marwat",
"929953", "Haripur",
"929437", "Chitral",
"929638", "Tank",
"929637", "Tank",
"929438", "Chitral",
"929956", "Haripur",
"925436", "Chakwal",
"92565", "Sheikhupura",
"92462", "Toba\ Tek\ Singh",
"924593", "Mianwali",
"92927", "Karak",
"927236", "Ghotki",
"92442", "Okara",
"92677", "Vehari",
"928226", "Zhob",
"928526", "Kech",
"929443", "Upper\ Dir",
"929466", "Swat",
"92912", "Peshawar\/Charsadda",
"92625", "Bahawalpur",
"92655", "Khanewal",
"929666", "D\.I\.\ Khan",
"92407", "Sahiwal",
"925467", "Mandi\ Bahauddin",
"927268", "Shikarpur",
"929396", "Buner",
"927267", "Shikarpur",
"925468", "Mandi\ Bahauddin",
"929385", "Swabi",
"924534", "Bhakkar",
"925466", "Mandi\ Bahauddin",
"929397", "Buner",
"92667", "Muzaffargarh",
"925443", "Jhelum",
"92512", "Islamabad\/Rawalpindi",
"92575", "Attock",
"929398", "Buner",
"922359", "Sanghar",
"92415", "Faisalabad",
"927266", "Shikarpur",
"92647", "Dera\ Ghazi\ Khan",
"92472", "Jhang",
"928227", "Zhob",
"929975", "Mansehra\/Batagram",
"928527", "Kech",
"929668", "D\.I\.\ Khan",
"929467", "Swat",
"926083", "Lodhran",
"928528", "Kech",
"928228", "Zhob",
"929468", "Swat",
"929667", "D\.I\.\ Khan",
"927238", "Ghotki",
"925437", "Chakwal",
"925438", "Chakwal",
"928353", "Dera\ Bugti",
"927237", "Ghotki",
"92688", "Rahim\ Yar\ Khan",
"924532", "Bhakkar",
"92747", "Larkana",
"929958", "Haripur",
"929436", "Chitral",
"929636", "Tank",
"92527", "Sialkot",
"92557", "Gujranwala",
"922335", "Mirpur\ Khas",
"929957", "Haripur",
"925479", "Hafizabad",
"929433", "Chitral",
"929633", "Tank",
"92632", "Bahawalnagar",
"924598", "Mianwali",
"928356", "Dera\ Bugti",
"924597", "Mianwali",
"922972", "Badin",
"929447", "Upper\ Dir",
"926086", "Lodhran",
"92215", "Karachi",
"929448", "Upper\ Dir",
"92498", "Kasur",
"925463", "Mandi\ Bahauddin",
"922974", "Badin",
"925446", "Jhelum",
"927263", "Shikarpur",
"92417", "Faisalabad",
"92816", "Quetta",
"92645", "Dera\ Ghazi\ Khan",
"925435", "Chakwal",
"92577", "Attock",
"922442", "Nawabshah",
"92665", "Muzaffargarh",
"927235", "Ghotki",
"928472", "Kharan",
"922338", "Mirpur\ Khas",
"929955", "Haripur",
"92484", "Sargodha",
"922337", "Mirpur\ Khas",
"929395", "Buner",
"922444", "Nawabshah",
"928373", "Jhal\ Magsi",
"929386", "Swabi",
"929465", "Swat",
"92422", "Lahore",
"92525", "Sialkot",
"92555", "Gujranwala",
"928525", "Kech",
"929977", "Mansehra\/Batagram",
"928225", "Zhob",
"929665", "D\.I\.\ Khan",
"928474", "Kharan",
"929978", "Mansehra\/Batagram",
"92745", "Larkana",
"92868", "Gwadar",
"929445", "Upper\ Dir",
"928289", "Musakhel",
"928322", "Bolan",
"928376", "Jhal\ Magsi",
"92252", "Dadu",
"92222", "Hyderabad",
"929383", "Swabi",
"922429", "Naushero\ Feroze",
"928324", "Bolan",
"92486", "Sargodha",
"92217", "Karachi",
"92814", "Quetta",
"924595", "Mianwali",
"922434", "Khairpur",
"92532", "Gujrat",
"928355", "Dera\ Bugti",
"922333", "Mirpur\ Khas",
"926042", "Rajanpur",
"928377", "Jhal\ Magsi",
"925445", "Jhelum",
"928378", "Jhal\ Magsi",
"922432", "Khairpur",
"926044", "Rajanpur",
"92499", "Kasur",
"929973", "Mansehra\/Batagram",
"926085", "Lodhran",
"92483", "Sargodha",
"928339", "Sibi\/Ziarat",
"929976", "Mansehra\/Batagram",
"926064", "Layyah",
"92612", "Multan",
"925465", "Mandi\ Bahauddin",
"929459", "Lower\ Dir",
"92675", "Vehari",
"929388", "Swabi",
"92813", "Quetta",
"92925", "Hangu\/Orakzai\ Agy",
"928254", "Chagai",
"929387", "Swabi",
"928554", "Panjgur",
"927265", "Shikarpur",
"929659", "South\ Waziristan",
"929922", "Abottabad",
"92567", "Sheikhupura",
"92627", "Bahawalpur",
"92657", "Khanewal",
"9258", "AJK\/FATA",
"929435", "Chitral",
"926062", "Layyah",
"922336", "Mirpur\ Khas",
"922989", "Thatta",
"929635", "Tank",
"92712", "Sukkur",
"929924", "Abottabad",
"92689", "Rahim\ Yar\ Khan",
"928552", "Panjgur",
"928252", "Chagai",
"92405", "Sahiwal",
"929969", "Shangla",
"92539", "Gujrat",
"929966", "Shangla",
"92638", "Bahawalnagar",
"928432", "Mastung",
"92566", "Sheikhupura",
"922339", "Mirpur\ Khas",
"92413", "Faisalabad",
"922986", "Thatta",
"92573", "Attock",
"925475", "Hafizabad",
"928434", "Mastung",
"929456", "Lower\ Dir",
"92626", "Bahawalpur",
"92656", "Khanewal",
"929656", "South\ Waziristan",
"922355", "Sanghar",
"92492", "Kasur",
"929979", "Mansehra\/Batagram",
"928333", "Sibi\/Ziarat",
"928288", "Musakhel",
"928336", "Sibi\/Ziarat",
"928287", "Musakhel",
"922428", "Naushero\ Feroze",
"929453", "Lower\ Dir",
"92478", "Jhang",
"92619", "Multan",
"92518", "Islamabad\/Rawalpindi",
"922427", "Naushero\ Feroze",
"92654", "Khanewal",
"929653", "South\ Waziristan",
"92624", "Bahawalpur",
"92564", "Sheikhupura",
"92719", "Sukkur",
"922983", "Thatta",
"92213", "Karachi",
"92682", "Rahim\ Yar\ Khan",
"929963", "Shangla",
"928444", "Kalat",
"92448", "Okara",
"928485", "Khuzdar",
"92468", "Toba\ Tek\ Singh",
"929325", "Malakand",
"928379", "Jhal\ Magsi",
"92487", "Sargodha",
"92216", "Karachi",
"922426", "Naushero\ Feroze",
"928442", "Kalat",
"928338", "Sibi\/Ziarat",
"92429", "Lahore",
"928295", "Barkhan\/Kohlu",
"92918", "Peshawar\/Charsadda",
"928337", "Sibi\/Ziarat",
"92414", "Faisalabad",
"92574", "Attock",
"928286", "Musakhel",
"922324", "Tharparkar",
"92563", "Sheikhupura",
"928283", "Musakhel",
"92576", "Attock",
"92416", "Faisalabad",
"92817", "Quetta",
"92214", "Karachi",
"929658", "South\ Waziristan",
"929457", "Lower\ Dir",
"92259", "Dadu",
"92229", "Hyderabad",
"929389", "Swabi",
"929458", "Lower\ Dir",
"929222", "Kohat",
"929657", "South\ Waziristan",
"922423", "Naushero\ Feroze",
"922988", "Thatta",
"922987", "Thatta",
"922322", "Tharparkar",
"929968", "Shangla",
"929224", "Kohat",
"92623", "Bahawalpur",
"929967", "Shangla",
"92653", "Khanewal",
"92444", "Okara",
"928484", "Khuzdar",
"924549", "Khushab",
"928445", "Kalat",
"92464", "Toba\ Tek\ Singh",
"929322", "Malakand",
"929376", "Mardan",
"92409", "Sahiwal",
"928383", "Jaffarabad\/Nasirabad",
"928292", "Barkhan\/Kohlu",
"92685", "Rahim\ Yar\ Khan",
"929324", "Malakand",
"928482", "Khuzdar",
"92633", "Bahawalnagar",
"929699", "Lakki\ Marwat",
"928294", "Barkhan\/Kohlu",
"92914", "Peshawar\/Charsadda",
"92418", "Faisalabad",
"92679", "Vehari",
"922389", "Umerkot",
"929423", "Bajaur\ Agency",
"928563", "Awaran",
"928263", "K\.Abdullah\/Pishin",
"92578", "Attock",
"924573", "Pakpattan",
"928246", "Loralai",
"92916", "Peshawar\/Charsadda",
"922325", "Tharparkar",
"928266", "K\.Abdullah\/Pishin",
"928566", "Awaran",
"924576", "Pakpattan",
"928243", "Loralai",
"929426", "Bajaur\ Agency",
"92218", "Karachi",
"927227", "Jacobabad",
"925428", "Narowal",
"92495", "Kasur",
"925427", "Narowal",
"927228", "Jacobabad",
"929373", "Mardan",
"928538", "Lasbela",
"928238", "Killa\ Saifullah",
"928386", "Jaffarabad\/Nasirabad",
"928237", "Killa\ Saifullah",
"928537", "Lasbela",
"92473", "Jhang",
"929225", "Kohat",
"92446", "Okara",
"92513", "Islamabad\/Rawalpindi",
"92867", "Gwadar",
"92466", "Toba\ Tek\ Singh",
"922352", "Sanghar",
"92634", "Bahawalnagar",
"928388", "Jaffarabad\/Nasirabad",
"92913", "Peshawar\/Charsadda",
"925474", "Hafizabad",
"928387", "Jaffarabad\/Nasirabad",
"928236", "Killa\ Saifullah",
"928536", "Lasbela",
"92443", "Okara",
"92516", "Islamabad\/Rawalpindi",
"924539", "Bhakkar",
"927226", "Jacobabad",
"928435", "Mastung",
"92476", "Jhang",
"922354", "Sanghar",
"92463", "Toba\ Tek\ Singh",
"925426", "Narowal",
"924578", "Pakpattan",
"928568", "Awaran",
"928268", "K\.Abdullah\/Pishin",
"929428", "Bajaur\ Agency",
"925472", "Hafizabad",
"928267", "K\.Abdullah\/Pishin",
"928567", "Awaran",
"924577", "Pakpattan",
"929427", "Bajaur\ Agency",
"928248", "Loralai",
"928247", "Loralai",
"927223", "Jacobabad",
"92474", "Jhang",
"92749", "Larkana",
"922979", "Badin",
"92514", "Islamabad\/Rawalpindi",
"92658", "Khanewal",
"925423", "Narowal",
"92628", "Bahawalpur",
"92529", "Sialkot",
"92559", "Gujranwala",
"92669", "Muzaffargarh",
"929377", "Mardan",
"92568", "Sheikhupura",
"92649", "Dera\ Ghazi\ Khan",
"928533", "Lasbela",
"929378", "Mardan",
"928233", "Killa\ Saifullah",
"92636", "Bahawalnagar",
"924547", "Khushab",
"922435", "Khairpur",
"924548", "Khushab",
"928354", "Dera\ Bugti",
"925442", "Jhelum",
"926082", "Lodhran",
"925444", "Jhelum",
"922976", "Badin",
"928352", "Dera\ Bugti",
"924533", "Bhakkar",
"926084", "Lodhran",
"92255", "Dadu",
"92225", "Hyderabad",
"92637", "Bahawalnagar",
"929697", "Lakki\ Marwat",
"922388", "Umerkot",
"926045", "Rajanpur",
"922387", "Umerkot",
"929698", "Lakki\ Marwat",
"926065", "Layyah",
"929632", "Tank",
"929432", "Chitral",
"924536", "Bhakkar",
"927229", "Jacobabad",
"92742", "Larkana",
"925464", "Mandi\ Bahauddin",
"922973", "Badin",
"92425", "Lahore",
"925429", "Narowal",
"92522", "Sialkot",
"92552", "Gujranwala",
"927264", "Shikarpur",
"928555", "Panjgur",
"928255", "Chagai",
"929434", "Chitral",
"92662", "Muzaffargarh",
"92863", "Gwadar",
"929634", "Tank",
"92642", "Dera\ Ghazi\ Khan",
"928239", "Killa\ Saifullah",
"928539", "Lasbela",
"92477", "Jhang",
"92517", "Islamabad\/Rawalpindi",
"927262", "Shikarpur",
"929925", "Abottabad",
"925462", "Mandi\ Bahauddin",
"925434", "Chakwal",
"924543", "Khushab",
"92715", "Sukkur",
"929392", "Buner",
"927234", "Ghotki",
"92917", "Peshawar\/Charsadda",
"929662", "D\.I\.\ Khan",
"92402", "Sahiwal",
"929462", "Swat",
"929954", "Haripur",
"928389", "Jaffarabad\/Nasirabad",
"928522", "Kech",
"92488", "Sargodha",
"928222", "Zhob",
"924537", "Bhakkar",
"922445", "Nawabshah",
"927232", "Ghotki",
"929394", "Buner",
"924538", "Bhakkar",
"925432", "Chakwal",
"928224", "Zhob",
"92866", "Gwadar",
"929693", "Lakki\ Marwat",
"928524", "Kech",
"92467", "Toba\ Tek\ Singh",
"929952", "Haripur",
"929464", "Swat",
"922383", "Umerkot",
"92615", "Multan",
"92447", "Okara",
"92672", "Vehari",
"929429", "Bajaur\ Agency",
"928269", "K\.Abdullah\/Pishin",
"928569", "Awaran",
"928475", "Kharan",
"924579", "Pakpattan",
"929664", "D\.I\.\ Khan",
"929444", "Upper\ Dir",
"929696", "Lakki\ Marwat",
"92864", "Gwadar",
"928249", "Loralai",
"922386", "Umerkot",
"922977", "Badin",
"924592", "Mianwali",
"922978", "Badin",
"92535", "Gujrat",
"928325", "Bolan",
"929379", "Mardan",
"929442", "Upper\ Dir",
"924546", "Khushab",
"92818", "Quetta",
"924594", "Mianwali",
"92915", "Peshawar\/Charsadda",
"92622", "Bahawalpur",
"928439", "Mastung",
"92652", "Khanewal",
"922447", "Nawabshah",
"924535", "Bhakkar",
"928256", "Chagai",
"928556", "Panjgur",
"92717", "Sukkur",
"922448", "Nawabshah",
"928478", "Kharan",
"922332", "Mirpur\ Khas",
"926043", "Rajanpur",
"929974", "Mansehra\/Batagram",
"926066", "Layyah",
"92496", "Kasur",
"928477", "Kharan",
"922433", "Khairpur",
"929926", "Abottabad",
"92684", "Rahim\ Yar\ Khan",
"92617", "Multan",
"92445", "Okara",
"929972", "Mansehra\/Batagram",
"92562", "Sheikhupura",
"922334", "Mirpur\ Khas",
"92465", "Toba\ Tek\ Singh",
"928327", "Bolan",
"928328", "Bolan",
"922436", "Khairpur",
"929923", "Abottabad",
"92686", "Rahim\ Yar\ Khan",
"926046", "Rajanpur",
"92998", "Kohistan",
"926063", "Layyah",
"92537", "Gujrat",
"92494", "Kasur",
"922975", "Badin",
"928553", "Panjgur",
"928253", "Chagai",
"922443", "Nawabshah",
"928374", "Jhal\ Magsi",
"92683", "Rahim\ Yar\ Khan",
"92212", "Karachi",
"926047", "Rajanpur",
"929695", "Lakki\ Marwat",
"922385", "Umerkot",
"926048", "Rajanpur",
"928473", "Kharan",
"922437", "Khairpur",
"928449", "Kalat",
"924545", "Khushab",
"92819", "Quetta",
"922438", "Khairpur",
"928372", "Jhal\ Magsi",
"928326", "Bolan",
"92635", "Bahawalnagar",
"92257", "Dadu",
"92227", "Hyderabad",
"92489", "Sargodha",
"928323", "Bolan",
"92493", "Kasur",
"929927", "Abottabad",
"92427", "Lahore",
"929229", "Kohat",
"929382", "Swabi",
"929928", "Abottabad",
"92515", "Islamabad\/Rawalpindi",
"92572", "Attock",
"922329", "Tharparkar",
"92412", "Faisalabad",
"926067", "Layyah",
"92475", "Jhang",
"928476", "Kharan",
"926068", "Layyah",
"928558", "Panjgur",
"928258", "Chagai",
"922446", "Nawabshah",
"929384", "Swabi",
"928257", "Chagai",
"928557", "Panjgur",
"928437", "Mastung",
"922449", "Nawabshah",
"92224", "Hyderabad",
"92254", "Dadu",
"928438", "Mastung",
"92219", "Karachi",
"922326", "Tharparkar",
"92713", "Sukkur",
"929425", "Bajaur\ Agency",
"92426", "Lahore",
"924575", "Pakpattan",
"928565", "Awaran",
"928479", "Kharan",
"928265", "K\.Abdullah\/Pishin",
"929226", "Kohat",
"928443", "Kalat",
"92812", "Quetta",
"92613", "Multan",
"928385", "Jaffarabad\/Nasirabad",
"928329", "Bolan",
"928282", "Musakhel",
"92482", "Sargodha",
"929375", "Mardan",
"92408", "Sahiwal",
"928446", "Kalat",
"929223", "Kohat",
"922422", "Naushero\ Feroze",
"92579", "Attock",
"92928", "Bannu\/N\.\ Waziristan",
"922323", "Tharparkar",
"92678", "Vehari",
"92419", "Faisalabad",
"928245", "Loralai",
"928284", "Musakhel",
"92424", "Lahore",
"92256", "Dadu",
"92226", "Hyderabad",
"92533", "Gujrat",
"922424", "Naushero\ Feroze",
"92558", "Gujranwala",
"92528", "Sialkot",
"928433", "Mastung",
"92629", "Bahawalpur",
"92659", "Khanewal",
"92748", "Larkana",
"92614", "Multan",
"92687", "Rahim\ Yar\ Khan",
"926049", "Rajanpur",
"928334", "Sibi\/Ziarat",
"92536", "Gujrat",
"922439", "Khairpur",
"928447", "Kalat",
"92253", "Dadu",
"92223", "Hyderabad",
"928448", "Kalat",
"92714", "Sukkur",
"928332", "Sibi\/Ziarat",
"92648", "Dera\ Ghazi\ Khan",
"92569", "Sheikhupura",
"92668", "Muzaffargarh",
"92716", "Sukkur",
"928535", "Lasbela",
"928235", "Killa\ Saifullah",
"922984", "Thatta",
"92423", "Lahore",
"929227", "Kohat",
"929652", "South\ Waziristan",
"92497", "Kasur",
"929929", "Abottabad",
"92534", "Gujrat",
"929452", "Lower\ Dir",
"929228", "Kohat",
"929964", "Shangla",
"922327", "Tharparkar",
"926069", "Layyah",
"922982", "Thatta",
"922328", "Tharparkar",
"92865", "Gwadar",
"928436", "Mastung",
"927225", "Jacobabad",
"929962", "Shangla",
"929454", "Lower\ Dir",
"92616", "Multan",
"925425", "Narowal",
"928259", "Chagai",
"928559", "Panjgur",
"929654", "South\ Waziristan",};
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