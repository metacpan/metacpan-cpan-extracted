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
our $VERSION = 1.20230307181422;

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
$areanames{en} = {"922336", "Mirpur\ Khas",
"928329", "Bolan",
"924593", "Mianwali",
"92417", "Faisalabad",
"92218", "Karachi",
"922984", "Thatta",
"929392", "Buner",
"92215", "Karachi",
"925448", "Jhelum",
"929957", "Haripur",
"92627", "Bahawalpur",
"92405", "Sahiwal",
"92676", "Vehari",
"925475", "Hafizabad",
"92444", "Okara",
"926089", "Lodhran",
"92408", "Sahiwal",
"929426", "Bajaur\ Agency",
"925427", "Narowal",
"927225", "Jacobabad",
"92467", "Toba\ Tek\ Singh",
"92258", "Dadu",
"928537", "Lasbela",
"929444", "Upper\ Dir",
"928486", "Khuzdar",
"929972", "Mansehra\/Batagram",
"92255", "Dadu",
"922447", "Nawabshah",
"929453", "Lower\ Dir",
"92229", "Hyderabad",
"929389", "Swabi",
"928245", "Loralai",
"929373", "Mardan",
"92719", "Sukkur",
"92924", "Khyber\/Mohmand\ Agy",
"922428", "Naushero\ Feroze",
"92532", "Gujrat",
"929663", "D\.I\.\ Khan",
"928376", "Jhal\ Magsi",
"924572", "Pakpattan",
"928566", "Awaran",
"92682", "Rahim\ Yar\ Khan",
"928233", "Killa\ Saifullah",
"926064", "Layyah",
"925449", "Jhelum",
"92576", "Attock",
"929966", "Shangla",
"92403", "Sahiwal",
"92867", "Gwadar",
"924537", "Bhakkar",
"925474", "Hafizabad",
"928328", "Bolan",
"922985", "Thatta",
"929223", "Kohat",
"92472", "Jhang",
"92213", "Karachi",
"928226", "Zhob",
"922356", "Sanghar",
"92527", "Sialkot",
"927232", "Ghotki",
"922386", "Umerkot",
"926088", "Lodhran",
"928283", "Musakhel",
"925463", "Mandi\ Bahauddin",
"922323", "Tharparkar",
"926065", "Layyah",
"928253", "Chagai",
"928244", "Loralai",
"92742", "Larkana",
"92632", "Bahawalnagar",
"928442", "Kalat",
"929696", "Lakki\ Marwat",
"92817", "Quetta",
"929433", "Chitral",
"928297", "Barkhan\/Kohlu",
"92486", "Sargodha",
"928436", "Mastung",
"928557", "Panjgur",
"922429", "Naushero\ Feroze",
"927224", "Jacobabad",
"929445", "Upper\ Dir",
"929388", "Swabi",
"92253", "Dadu",
"92223", "Hyderabad",
"928287", "Musakhel",
"922327", "Tharparkar",
"928257", "Chagai",
"929324", "Malakand",
"922976", "Badin",
"925467", "Mandi\ Bahauddin",
"92672", "Vehari",
"929398", "Buner",
"929466", "Swat",
"925442", "Jhelum",
"92517", "Islamabad\/Rawalpindi",
"922434", "Khairpur",
"927239", "Ghotki",
"929437", "Chitral",
"928293", "Barkhan\/Kohlu",
"926046", "Rajanpur",
"928553", "Panjgur",
"925436", "Chakwal",
"929656", "South\ Waziristan",
"92713", "Sukkur",
"928449", "Kalat",
"92536", "Gujrat",
"924545", "Khushab",
"92557", "Gujranwala",
"92686", "Rahim\ Yar\ Khan",
"928526", "Kech",
"929978", "Mansehra\/Batagram",
"924533", "Bhakkar",
"928474", "Kharan",
"92567", "Sheikhupura",
"928335", "Sibi\/Ziarat",
"928354", "Dera\ Bugti",
"929227", "Kohat",
"928384", "Jaffarabad\/Nasirabad",
"922422", "Naushero\ Feroze",
"927265", "Shikarpur",
"924578", "Pakpattan",
"928533", "Lasbela",
"928266", "K\.Abdullah\/Pishin",
"92718", "Sukkur",
"922443", "Nawabshah",
"92715", "Sukkur",
"929399", "Buner",
"929636", "Tank",
"922435", "Khairpur",
"929457", "Lower\ Dir",
"928322", "Bolan",
"92644", "Dera\ Ghazi\ Khan",
"92476", "Jhang",
"929377", "Mardan",
"92427", "Lahore",
"929926", "Abottabad",
"92259", "Dadu",
"92494", "Kasur",
"929667", "D\.I\.\ Khan",
"92225", "Hyderabad",
"92617", "Multan",
"92572", "Attock",
"92228", "Hyderabad",
"928237", "Killa\ Saifullah",
"927238", "Ghotki",
"926082", "Lodhran",
"929325", "Malakand",
"92914", "Peshawar\/Charsadda",
"927264", "Shikarpur",
"924597", "Mianwali",
"92409", "Sahiwal",
"92482", "Sargodha",
"928334", "Sibi\/Ziarat",
"928355", "Dera\ Bugti",
"929979", "Mansehra\/Batagram",
"929953", "Haripur",
"928385", "Jaffarabad\/Nasirabad",
"928448", "Kalat",
"92746", "Larkana",
"92657", "Khanewal",
"928475", "Kharan",
"924579", "Pakpattan",
"92636", "Bahawalnagar",
"929382", "Swabi",
"924544", "Khushab",
"925423", "Narowal",
"92219", "Karachi",
"92667", "Muzaffargarh",
"928562", "Awaran",
"927223", "Jacobabad",
"924576", "Pakpattan",
"928372", "Jhal\ Magsi",
"92526", "Sialkot",
"929455", "Lower\ Dir",
"929434", "Chitral",
"922437", "Khairpur",
"92612", "Multan",
"92577", "Attock",
"929375", "Mardan",
"928243", "Loralai",
"929327", "Malakand",
"92866", "Gwadar",
"928482", "Khuzdar",
"925464", "Mandi\ Bahauddin",
"929976", "Mansehra\/Batagram",
"922324", "Tharparkar",
"928528", "Kech",
"928254", "Chagai",
"928235", "Killa\ Saifullah",
"92422", "Lahore",
"92923", "Nowshera",
"928284", "Musakhel",
"929665", "D\.I\.\ Khan",
"929929", "Abottabad",
"929658", "South\ Waziristan",
"925438", "Chakwal",
"924595", "Mianwali",
"926048", "Rajanpur",
"92487", "Sargodha",
"928387", "Jaffarabad\/Nasirabad",
"929422", "Bajaur\ Agency",
"929224", "Kohat",
"928357", "Dera\ Bugti",
"929468", "Swat",
"928269", "K\.Abdullah\/Pishin",
"928477", "Kharan",
"929639", "Tank",
"929396", "Buner",
"925473", "Hafizabad",
"92662", "Muzaffargarh",
"92652", "Khanewal",
"92443", "Okara",
"922978", "Badin",
"92816", "Quetta",
"922332", "Mirpur\ Khas",
"92677", "Vehari",
"925465", "Mandi\ Bahauddin",
"92928", "Bannu\/N\.\ Waziristan",
"928255", "Chagai",
"928234", "Killa\ Saifullah",
"926063", "Layyah",
"922325", "Tharparkar",
"928432", "Mastung",
"92925", "Hangu\/Orakzai\ Agy",
"92512", "Islamabad\/Rawalpindi",
"929664", "D\.I\.\ Khan",
"928285", "Musakhel",
"92649", "Dera\ Ghazi\ Khan",
"929374", "Mardan",
"928446", "Kalat",
"929692", "Lakki\ Marwat",
"929435", "Chitral",
"929454", "Lower\ Dir",
"92416", "Faisalabad",
"92499", "Kasur",
"928529", "Kech",
"92254", "Dadu",
"929443", "Upper\ Dir",
"92626", "Bahawalpur",
"927236", "Ghotki",
"922382", "Umerkot",
"92404", "Sahiwal",
"92919", "Peshawar\/Charsadda",
"92562", "Sheikhupura",
"924547", "Khushab",
"92445", "Okara",
"928222", "Zhob",
"922352", "Sanghar",
"926049", "Rajanpur",
"92448", "Okara",
"925439", "Chakwal",
"92552", "Gujranwala",
"929928", "Abottabad",
"929659", "South\ Waziristan",
"92466", "Toba\ Tek\ Singh",
"929962", "Shangla",
"929225", "Kohat",
"922983", "Thatta",
"928337", "Sibi\/Ziarat",
"922979", "Badin",
"929638", "Tank",
"92214", "Karachi",
"929469", "Swat",
"928268", "K\.Abdullah\/Pishin",
"927267", "Shikarpur",
"924594", "Mianwali",
"92426", "Lahore",
"928568", "Awaran",
"924543", "Khushab",
"925424", "Narowal",
"92862", "Gwadar",
"928378", "Jhal\ Magsi",
"92616", "Multan",
"928439", "Mastung",
"922426", "Naushero\ Feroze",
"924535", "Bhakkar",
"92915", "Peshawar\/Charsadda",
"929954", "Haripur",
"92449", "Okara",
"9258", "AJK\/FATA",
"92522", "Sialkot",
"928333", "Sibi\/Ziarat",
"92918", "Peshawar\/Charsadda",
"922987", "Thatta",
"928488", "Khuzdar",
"928522", "Kech",
"927263", "Shikarpur",
"929699", "Lakki\ Marwat",
"92477", "Jhang",
"926067", "Layyah",
"929652", "South\ Waziristan",
"92656", "Khanewal",
"92747", "Larkana",
"92498", "Kasur",
"925432", "Chakwal",
"92637", "Bahawalnagar",
"92495", "Kasur",
"92812", "Quetta",
"922359", "Sanghar",
"92224", "Hyderabad",
"928229", "Zhob",
"929428", "Bajaur\ Agency",
"926042", "Rajanpur",
"92666", "Muzaffargarh",
"922389", "Umerkot",
"928295", "Barkhan\/Kohlu",
"929462", "Swat",
"925446", "Jhelum",
"92714", "Sukkur",
"922444", "Nawabshah",
"929969", "Shangla",
"929447", "Upper\ Dir",
"922972", "Badin",
"92648", "Dera\ Ghazi\ Khan",
"922338", "Mirpur\ Khas",
"928555", "Panjgur",
"928534", "Lasbela",
"92645", "Dera\ Ghazi\ Khan",
"929386", "Swabi",
"928438", "Mastung",
"92622", "Bahawalpur",
"928383", "Jaffarabad\/Nasirabad",
"92913", "Peshawar\/Charsadda",
"929955", "Haripur",
"928379", "Jhal\ Magsi",
"928569", "Awaran",
"928353", "Dera\ Bugti",
"92412", "Faisalabad",
"929698", "Lakki\ Marwat",
"928489", "Khuzdar",
"924534", "Bhakkar",
"925477", "Hafizabad",
"928473", "Kharan",
"925425", "Narowal",
"92516", "Islamabad\/Rawalpindi",
"922445", "Nawabshah",
"922388", "Umerkot",
"926086", "Lodhran",
"928554", "Panjgur",
"928535", "Lasbela",
"927227", "Jacobabad",
"922358", "Sanghar",
"928228", "Zhob",
"929429", "Bajaur\ Agency",
"92643", "Dera\ Ghazi\ Khan",
"928294", "Barkhan\/Kohlu",
"92462", "Toba\ Tek\ Singh",
"922433", "Khairpur",
"929922", "Abottabad",
"92537", "Gujrat",
"922339", "Mirpur\ Khas",
"928326", "Bolan",
"929968", "Shangla",
"928247", "Loralai",
"92687", "Rahim\ Yar\ Khan",
"92556", "Gujranwala",
"92566", "Sheikhupura",
"929323", "Malakand",
"929632", "Tank",
"92493", "Kasur",
"928262", "K\.Abdullah\/Pishin",
"928282", "Musakhel",
"92529", "Sialkot",
"92653", "Khanewal",
"92442", "Okara",
"928435", "Mastung",
"92565", "Sheikhupura",
"922322", "Tharparkar",
"928252", "Chagai",
"92568", "Sheikhupura",
"929446", "Upper\ Dir",
"928484", "Khuzdar",
"924539", "Bhakkar",
"925462", "Mandi\ Bahauddin",
"92558", "Gujranwala",
"925447", "Jhelum",
"92555", "Gujranwala",
"928443", "Kalat",
"92663", "Muzaffargarh",
"929958", "Haripur",
"92869", "Gwadar",
"929432", "Chitral",
"929695", "Lakki\ Marwat",
"928374", "Jhal\ Magsi",
"926066", "Layyah",
"925428", "Narowal",
"928564", "Awaran",
"928538", "Lasbela",
"922355", "Sanghar",
"92518", "Islamabad\/Rawalpindi",
"922334", "Mirpur\ Khas",
"92423", "Lahore",
"928225", "Zhob",
"922448", "Nawabshah",
"922385", "Umerkot",
"92515", "Islamabad\/Rawalpindi",
"92534", "Gujrat",
"922986", "Thatta",
"92613", "Multan",
"92684", "Rahim\ Yar\ Khan",
"929222", "Kohat",
"929965", "Shangla",
"92819", "Quetta",
"929424", "Bajaur\ Agency",
"928559", "Panjgur",
"922427", "Naushero\ Feroze",
"928299", "Barkhan\/Kohlu",
"927233", "Ghotki",
"928375", "Jhal\ Magsi",
"929959", "Haripur",
"92646", "Dera\ Ghazi\ Khan",
"929973", "Mansehra\/Batagram",
"92474", "Jhang",
"928565", "Awaran",
"928246", "Loralai",
"929452", "Lower\ Dir",
"924538", "Bhakkar",
"928327", "Bolan",
"929694", "Lakki\ Marwat",
"929372", "Mardan",
"925429", "Narowal",
"92668", "Muzaffargarh",
"92553", "Gujranwala",
"92629", "Bahawalpur",
"92665", "Muzaffargarh",
"92655", "Khanewal",
"929662", "D\.I\.\ Khan",
"927226", "Jacobabad",
"924573", "Pakpattan",
"92563", "Sheikhupura",
"928434", "Mastung",
"928232", "Killa\ Saifullah",
"92419", "Faisalabad",
"92658", "Khanewal",
"92496", "Kasur",
"926087", "Lodhran",
"928485", "Khuzdar",
"924592", "Mianwali",
"925476", "Hafizabad",
"929393", "Buner",
"92916", "Peshawar\/Charsadda",
"929964", "Shangla",
"922449", "Nawabshah",
"929425", "Bajaur\ Agency",
"92717", "Sukkur",
"928539", "Lasbela",
"92227", "Hyderabad",
"92615", "Multan",
"928298", "Barkhan\/Kohlu",
"92618", "Multan",
"92469", "Toba\ Tek\ Singh",
"928224", "Zhob",
"92744", "Larkana",
"92425", "Lahore",
"922335", "Mirpur\ Khas",
"922354", "Sanghar",
"928558", "Panjgur",
"929387", "Swabi",
"92634", "Bahawalnagar",
"922384", "Umerkot",
"92513", "Islamabad\/Rawalpindi",
"92428", "Lahore",
"92619", "Multan",
"928288", "Musakhel",
"928258", "Chagai",
"928524", "Kech",
"922328", "Tharparkar",
"925468", "Mandi\ Bahauddin",
"929459", "Lower\ Dir",
"92429", "Lahore",
"928476", "Kharan",
"92465", "Toba\ Tek\ Singh",
"929397", "Buner",
"929952", "Haripur",
"92257", "Dadu",
"92468", "Toba\ Tek\ Singh",
"928239", "Killa\ Saifullah",
"929438", "Chitral",
"928356", "Dera\ Bugti",
"929669", "D\.I\.\ Khan",
"928386", "Jaffarabad\/Nasirabad",
"92674", "Vehari",
"92446", "Okara",
"925422", "Narowal",
"929379", "Mardan",
"92998", "Kohistan",
"929383", "Swabi",
"92813", "Quetta",
"92628", "Bahawalpur",
"928532", "Lasbela",
"92669", "Muzaffargarh",
"922974", "Badin",
"929326", "Malakand",
"92217", "Karachi",
"929977", "Mansehra\/Batagram",
"922442", "Nawabshah",
"92625", "Bahawalpur",
"929925", "Abottabad",
"92418", "Faisalabad",
"92659", "Khanewal",
"92523", "Sialkot",
"928323", "Bolan",
"924599", "Mianwali",
"929464", "Swat",
"92415", "Faisalabad",
"929228", "Kohat",
"922436", "Khairpur",
"926044", "Rajanpur",
"928265", "K\.Abdullah\/Pishin",
"92407", "Sahiwal",
"925434", "Chakwal",
"924577", "Pakpattan",
"92863", "Gwadar",
"929654", "South\ Waziristan",
"926083", "Lodhran",
"929635", "Tank",
"92926", "Kurram\ Agency",
"927266", "Shikarpur",
"92818", "Quetta",
"92492", "Kasur",
"92815", "Quetta",
"928259", "Chagai",
"922329", "Tharparkar",
"925469", "Mandi\ Bahauddin",
"924532", "Bhakkar",
"928336", "Sibi\/Ziarat",
"929458", "Lower\ Dir",
"92574", "Attock",
"928289", "Musakhel",
"929378", "Mardan",
"92463", "Toba\ Tek\ Singh",
"922423", "Naushero\ Feroze",
"92519", "Islamabad\/Rawalpindi",
"929668", "D\.I\.\ Khan",
"927237", "Ghotki",
"928525", "Kech",
"928238", "Killa\ Saifullah",
"929439", "Chitral",
"924546", "Khushab",
"92642", "Dera\ Ghazi\ Khan",
"924598", "Mianwali",
"928264", "K\.Abdullah\/Pishin",
"92865", "Gwadar",
"925435", "Chakwal",
"929634", "Tank",
"929655", "South\ Waziristan",
"92868", "Gwadar",
"926045", "Rajanpur",
"928447", "Kalat",
"925443", "Jhelum",
"92569", "Sheikhupura",
"929924", "Abottabad",
"92912", "Peshawar\/Charsadda",
"92525", "Sialkot",
"92484", "Sargodha",
"92413", "Faisalabad",
"929465", "Swat",
"928292", "Barkhan\/Kohlu",
"92528", "Sialkot",
"928552", "Panjgur",
"922975", "Badin",
"92623", "Bahawalpur",
"929229", "Kohat",
"92559", "Gujranwala",
"92533", "Gujrat",
"92614", "Multan",
"922383", "Umerkot",
"928223", "Zhob",
"92683", "Rahim\ Yar\ Khan",
"922353", "Sanghar",
"92638", "Bahawalnagar",
"92424", "Lahore",
"92745", "Larkana",
"92635", "Bahawalnagar",
"922438", "Khairpur",
"929226", "Kohat",
"92497", "Kasur",
"92748", "Larkana",
"929394", "Buner",
"929963", "Shangla",
"92647", "Dera\ Ghazi\ Khan",
"922982", "Thatta",
"929328", "Malakand",
"92679", "Vehari",
"928527", "Kech",
"927235", "Ghotki",
"926062", "Layyah",
"929657", "South\ Waziristan",
"92226", "Hyderabad",
"925437", "Chakwal",
"924574", "Pakpattan",
"92664", "Muzaffargarh",
"928433", "Mastung",
"92654", "Khanewal",
"928445", "Kalat",
"928388", "Jaffarabad\/Nasirabad",
"926047", "Rajanpur",
"924549", "Khushab",
"928358", "Dera\ Bugti",
"929436", "Chitral",
"92478", "Jhang",
"929467", "Swat",
"927269", "Shikarpur",
"929693", "Lakki\ Marwat",
"928478", "Kharan",
"92475", "Jhang",
"922326", "Tharparkar",
"929974", "Mansehra\/Batagram",
"92917", "Peshawar\/Charsadda",
"928256", "Chagai",
"929442", "Upper\ Dir",
"922977", "Badin",
"928339", "Sibi\/Ziarat",
"925466", "Mandi\ Bahauddin",
"928286", "Musakhel",
"92716", "Sukkur",
"927234", "Ghotki",
"922439", "Khairpur",
"92252", "Dadu",
"929423", "Bajaur\ Agency",
"929395", "Buner",
"92579", "Attock",
"92743", "Larkana",
"92633", "Bahawalnagar",
"929329", "Malakand",
"925472", "Hafizabad",
"92514", "Islamabad\/Rawalpindi",
"92535", "Gujrat",
"92688", "Rahim\ Yar\ Khan",
"92538", "Gujrat",
"924596", "Mianwali",
"922333", "Mirpur\ Khas",
"92685", "Rahim\ Yar\ Khan",
"928236", "Killa\ Saifullah",
"929975", "Mansehra\/Batagram",
"928359", "Dera\ Bugti",
"924548", "Khushab",
"928563", "Awaran",
"927222", "Jacobabad",
"929666", "D\.I\.\ Khan",
"928373", "Jhal\ Magsi",
"928389", "Jaffarabad\/Nasirabad",
"92473", "Jhang",
"929376", "Mardan",
"92212", "Karachi",
"929927", "Abottabad",
"92489", "Sargodha",
"92402", "Sahiwal",
"928444", "Kalat",
"92564", "Sheikhupura",
"928242", "Loralai",
"929456", "Lower\ Dir",
"928338", "Sibi\/Ziarat",
"928479", "Kharan",
"928483", "Khuzdar",
"929637", "Tank",
"924575", "Pakpattan",
"92554", "Gujranwala",
"927268", "Shikarpur",
"928267", "K\.Abdullah\/Pishin",
"928567", "Awaran",
"92524", "Sialkot",
"92485", "Sargodha",
"928377", "Jhal\ Magsi",
"92488", "Sargodha",
"928325", "Bolan",
"929923", "Abottabad",
"922432", "Khairpur",
"92864", "Gwadar",
"925444", "Jhelum",
"922988", "Thatta",
"929322", "Malakand",
"925479", "Hafizabad",
"928487", "Khuzdar",
"926085", "Lodhran",
"929633", "Tank",
"922446", "Nawabshah",
"928263", "K\.Abdullah\/Pishin",
"928536", "Lasbela",
"925426", "Narowal",
"926068", "Layyah",
"92712", "Sukkur",
"927229", "Jacobabad",
"922424", "Naushero\ Feroze",
"928382", "Jaffarabad\/Nasirabad",
"92539", "Gujrat",
"929427", "Bajaur\ Agency",
"92689", "Rahim\ Yar\ Khan",
"928352", "Dera\ Bugti",
"92673", "Vehari",
"929956", "Haripur",
"928472", "Kharan",
"92814", "Quetta",
"92578", "Attock",
"92222", "Hyderabad",
"928249", "Loralai",
"929385", "Swabi",
"929448", "Upper\ Dir",
"922337", "Mirpur\ Khas",
"92575", "Attock",
"929653", "South\ Waziristan",
"926084", "Lodhran",
"928437", "Mastung",
"928556", "Panjgur",
"925433", "Chakwal",
"92479", "Jhang",
"926043", "Rajanpur",
"925445", "Jhelum",
"92447", "Okara",
"928296", "Barkhan\/Kohlu",
"928324", "Bolan",
"929697", "Lakki\ Marwat",
"929463", "Swat",
"925478", "Hafizabad",
"92624", "Bahawalpur",
"922973", "Badin",
"922989", "Thatta",
"92483", "Sargodha",
"92256", "Dadu",
"92414", "Faisalabad",
"922387", "Umerkot",
"929384", "Swabi",
"924542", "Khushab",
"928227", "Zhob",
"92573", "Attock",
"922357", "Sanghar",
"927228", "Jacobabad",
"92675", "Vehari",
"92406", "Sahiwal",
"926069", "Layyah",
"92927", "Karak",
"92678", "Vehari",
"922425", "Naushero\ Feroze",
"929967", "Shangla",
"928248", "Loralai",
"92216", "Karachi",
"928332", "Sibi\/Ziarat",
"924536", "Bhakkar",
"929449", "Upper\ Dir",
"92749", "Larkana",
"928523", "Kech",
"92464", "Toba\ Tek\ Singh",
"927262", "Shikarpur",
"92639", "Bahawalnagar",};

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