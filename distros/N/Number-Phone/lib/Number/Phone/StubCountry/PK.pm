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
our $VERSION = 1.20240308154353;

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
$areanames{en} = {"92664", "Muzaffargarh",
"92415", "Faisalabad",
"927266", "Shikarpur",
"92474", "Jhang",
"929963", "Shangla",
"922438", "Khairpur",
"929967", "Shangla",
"924595", "Mianwali",
"92927", "Karak",
"929222", "Kohat",
"928438", "Mastung",
"928224", "Zhob",
"929329", "Malakand",
"92413", "Faisalabad",
"928522", "Kech",
"92812", "Quetta",
"924532", "Bhakkar",
"922323", "Tharparkar",
"92646", "Dera\ Ghazi\ Khan",
"922327", "Tharparkar",
"929464", "Swat",
"92652", "Khanewal",
"92426", "Lahore",
"92617", "Multan",
"92408", "Sahiwal",
"925423", "Narowal",
"928327", "Bolan",
"92538", "Gujrat",
"928323", "Bolan",
"925445", "Jhelum",
"925427", "Narowal",
"92257", "Dadu",
"92212", "Karachi",
"92254", "Dadu",
"925475", "Hafizabad",
"928375", "Jhal\ Magsi",
"92675", "Vehari",
"92614", "Multan",
"92465", "Toba\ Tek\ Singh",
"929956", "Haripur",
"922986", "Thatta",
"92673", "Vehari",
"92463", "Toba\ Tek\ Singh",
"92862", "Gwadar",
"928248", "Loralai",
"927233", "Ghotki",
"92924", "Khyber\/Mohmand\ Agy",
"929376", "Mardan",
"92477", "Jhang",
"92689", "Rahim\ Yar\ Khan",
"926048", "Rajanpur",
"927237", "Ghotki",
"92667", "Muzaffargarh",
"928242", "Loralai",
"92444", "Okara",
"928326", "Bolan",
"925426", "Narowal",
"92624", "Bahawalpur",
"926042", "Rajanpur",
"922326", "Tharparkar",
"925449", "Jhelum",
"92466", "Toba\ Tek\ Singh",
"92676", "Vehari",
"924599", "Mianwali",
"92914", "Peshawar\/Charsadda",
"92559", "Gujranwala",
"927267", "Shikarpur",
"929966", "Shangla",
"929325", "Malakand",
"927263", "Shikarpur",
"929454", "Lower\ Dir",
"929377", "Mardan",
"929373", "Mardan",
"92645", "Dera\ Ghazi\ Khan",
"924538", "Bhakkar",
"928528", "Kech",
"927236", "Ghotki",
"92917", "Peshawar\/Charsadda",
"928484", "Khuzdar",
"92425", "Lahore",
"929434", "Chitral",
"929228", "Kohat",
"92222", "Hyderabad",
"925479", "Hafizabad",
"922432", "Khairpur",
"929957", "Haripur",
"922987", "Thatta",
"922983", "Thatta",
"929953", "Haripur",
"92643", "Dera\ Ghazi\ Khan",
"928379", "Jhal\ Magsi",
"92416", "Faisalabad",
"92627", "Bahawalpur",
"92719", "Sukkur",
"928432", "Mastung",
"92447", "Okara",
"92423", "Lahore",
"92539", "Gujrat",
"92563", "Sheikhupura",
"92409", "Sahiwal",
"925444", "Jhelum",
"927262", "Shikarpur",
"92577", "Attock",
"929465", "Swat",
"929226", "Kohat",
"928225", "Zhob",
"928247", "Loralai",
"92565", "Sheikhupura",
"928243", "Loralai",
"926047", "Rajanpur",
"924536", "Bhakkar",
"927238", "Ghotki",
"928526", "Kech",
"924594", "Mianwali",
"926043", "Rajanpur",
"92513", "Islamabad\/Rawalpindi",
"92688", "Rahim\ Yar\ Khan",
"922437", "Khairpur",
"929968", "Shangla",
"922982", "Thatta",
"929952", "Haripur",
"922433", "Khairpur",
"928489", "Khuzdar",
"92526", "Sialkot",
"929459", "Lower\ Dir",
"928433", "Mastung",
"928437", "Mastung",
"92515", "Islamabad\/Rawalpindi",
"929372", "Mardan",
"92574", "Attock",
"922328", "Tharparkar",
"925474", "Hafizabad",
"929439", "Chitral",
"925428", "Narowal",
"928328", "Bolan",
"928374", "Jhal\ Magsi",
"926046", "Rajanpur",
"928527", "Kech",
"924537", "Bhakkar",
"92632", "Bahawalnagar",
"928229", "Zhob",
"929378", "Mardan",
"922322", "Tharparkar",
"924533", "Bhakkar",
"92558", "Gujranwala",
"92516", "Islamabad\/Rawalpindi",
"928523", "Kech",
"929324", "Malakand",
"928246", "Loralai",
"928322", "Bolan",
"92492", "Kasur",
"925422", "Narowal",
"92482", "Sargodha",
"92523", "Sialkot",
"929223", "Kohat",
"922988", "Thatta",
"92998", "Kohistan",
"929962", "Shangla",
"929958", "Haripur",
"929227", "Kohat",
"9258", "AJK\/FATA",
"92525", "Sialkot",
"929469", "Swat",
"92566", "Sheikhupura",
"92718", "Sukkur",
"929435", "Chitral",
"92742", "Larkana",
"927232", "Ghotki",
"928436", "Mastung",
"928485", "Khuzdar",
"929455", "Lower\ Dir",
"922436", "Khairpur",
"927268", "Shikarpur",
"929662", "D\.I\.\ Khan",
"929658", "South\ Waziristan",
"925466", "Mandi\ Bahauddin",
"92865", "Gwadar",
"929638", "Tank",
"922444", "Nawabshah",
"927223", "Jacobabad",
"929926", "Abottabad",
"929442", "Upper\ Dir",
"929398", "Buner",
"927227", "Jacobabad",
"92672", "Vehari",
"92462", "Toba\ Tek\ Singh",
"92863", "Gwadar",
"928444", "Kalat",
"928474", "Kharan",
"92655", "Khanewal",
"929699", "Lakki\ Marwat",
"928357", "Dera\ Bugti",
"928234", "Killa\ Saifullah",
"928353", "Dera\ Bugti",
"929979", "Mansehra\/Batagram",
"92215", "Karachi",
"92918", "Peshawar\/Charsadda",
"928296", "Barkhan\/Kohlu",
"928552", "Panjgur",
"928568", "Awaran",
"92815", "Quetta",
"922353", "Sanghar",
"929383", "Swabi",
"929387", "Swabi",
"922357", "Sanghar",
"922428", "Naushero\ Feroze",
"928282", "Musakhel",
"92653", "Khanewal",
"928337", "Sibi\/Ziarat",
"928254", "Chagai",
"925433", "Chakwal",
"92448", "Okara",
"925437", "Chakwal",
"928333", "Sibi\/Ziarat",
"92213", "Karachi",
"922389", "Umerkot",
"928532", "Lasbela",
"92412", "Faisalabad",
"92813", "Quetta",
"926082", "Lodhran",
"928389", "Jaffarabad\/Nasirabad",
"92628", "Bahawalpur",
"922973", "Badin",
"922333", "Mirpur\ Khas",
"922337", "Mirpur\ Khas",
"922977", "Badin",
"92226", "Hyderabad",
"928264", "K\.Abdullah\/Pishin",
"928288", "Musakhel",
"92928", "Bannu\/N\.\ Waziristan",
"92225", "Hyderabad",
"929927", "Abottabad",
"924574", "Pakpattan",
"929923", "Abottabad",
"926064", "Layyah",
"927226", "Jacobabad",
"928538", "Lasbela",
"926088", "Lodhran",
"92216", "Karachi",
"92258", "Dadu",
"92537", "Gujrat",
"925467", "Mandi\ Bahauddin",
"925463", "Mandi\ Bahauddin",
"92422", "Lahore",
"92618", "Multan",
"92656", "Khanewal",
"92407", "Sahiwal",
"92223", "Hyderabad",
"929424", "Bajaur\ Agency",
"922422", "Naushero\ Feroze",
"92642", "Dera\ Ghazi\ Khan",
"92579", "Attock",
"92816", "Quetta",
"928558", "Panjgur",
"928562", "Awaran",
"929392", "Buner",
"922385", "Umerkot",
"922336", "Mirpur\ Khas",
"929448", "Upper\ Dir",
"922976", "Badin",
"929632", "Tank",
"92404", "Sahiwal",
"928385", "Jaffarabad\/Nasirabad",
"928336", "Sibi\/Ziarat",
"925436", "Chakwal",
"92534", "Gujrat",
"92668", "Muzaffargarh",
"929695", "Lakki\ Marwat",
"924544", "Khushab",
"92478", "Jhang",
"922356", "Sanghar",
"929386", "Swabi",
"929975", "Mansehra\/Batagram",
"929668", "D\.I\.\ Khan",
"929652", "South\ Waziristan",
"928293", "Barkhan\/Kohlu",
"92866", "Gwadar",
"928356", "Dera\ Bugti",
"928297", "Barkhan\/Kohlu",
"92486", "Sargodha",
"925462", "Mandi\ Bahauddin",
"928358", "Dera\ Bugti",
"926069", "Layyah",
"924579", "Pakpattan",
"92496", "Kasur",
"928445", "Kalat",
"92557", "Gujranwala",
"929666", "D\.I\.\ Khan",
"928563", "Awaran",
"92512", "Islamabad\/Rawalpindi",
"922358", "Sanghar",
"929388", "Swabi",
"922445", "Nawabshah",
"922427", "Naushero\ Feroze",
"922423", "Naushero\ Feroze",
"928269", "K\.Abdullah\/Pishin",
"92636", "Bahawalnagar",
"928567", "Awaran",
"929429", "Bajaur\ Agency",
"925438", "Chakwal",
"928338", "Sibi\/Ziarat",
"92714", "Sukkur",
"929922", "Abottabad",
"922338", "Mirpur\ Khas",
"922978", "Badin",
"929446", "Upper\ Dir",
"928556", "Panjgur",
"929653", "South\ Waziristan",
"92746", "Larkana",
"929657", "South\ Waziristan",
"92629", "Bahawalpur",
"928255", "Chagai",
"92717", "Sukkur",
"92449", "Okara",
"92562", "Sheikhupura",
"928292", "Barkhan\/Kohlu",
"927228", "Jacobabad",
"928536", "Lasbela",
"929633", "Tank",
"926086", "Lodhran",
"929397", "Buner",
"929393", "Buner",
"929637", "Tank",
"92554", "Gujranwala",
"928286", "Musakhel",
"928235", "Killa\ Saifullah",
"92919", "Peshawar\/Charsadda",
"928475", "Kharan",
"924549", "Khushab",
"92578", "Attock",
"929425", "Bajaur\ Agency",
"929447", "Upper\ Dir",
"929443", "Upper\ Dir",
"92743", "Larkana",
"927222", "Jacobabad",
"92619", "Multan",
"92259", "Dadu",
"92684", "Rahim\ Yar\ Khan",
"929667", "D\.I\.\ Khan",
"922426", "Naushero\ Feroze",
"92745", "Larkana",
"928566", "Awaran",
"928449", "Kalat",
"924575", "Pakpattan",
"929663", "D\.I\.\ Khan",
"926065", "Layyah",
"922449", "Nawabshah",
"928298", "Barkhan\/Kohlu",
"928265", "K\.Abdullah\/Pishin",
"928287", "Musakhel",
"92493", "Kasur",
"928332", "Sibi\/Ziarat",
"925432", "Chakwal",
"928283", "Musakhel",
"92483", "Sargodha",
"92522", "Sialkot",
"928537", "Lasbela",
"924545", "Khushab",
"926087", "Lodhran",
"928479", "Kharan",
"929694", "Lakki\ Marwat",
"92633", "Bahawalnagar",
"929396", "Buner",
"928239", "Killa\ Saifullah",
"922332", "Mirpur\ Khas",
"929928", "Abottabad",
"92479", "Jhang",
"922972", "Badin",
"92669", "Muzaffargarh",
"929636", "Tank",
"926083", "Lodhran",
"929974", "Mansehra\/Batagram",
"92687", "Rahim\ Yar\ Khan",
"928533", "Lasbela",
"928384", "Jaffarabad\/Nasirabad",
"928352", "Dera\ Bugti",
"92495", "Kasur",
"925468", "Mandi\ Bahauddin",
"92485", "Sargodha",
"928557", "Panjgur",
"92635", "Bahawalnagar",
"928259", "Chagai",
"922352", "Sanghar",
"929382", "Swabi",
"922384", "Umerkot",
"929656", "South\ Waziristan",
"928553", "Panjgur",
"927234", "Ghotki",
"924598", "Mianwali",
"922435", "Khairpur",
"929456", "Lower\ Dir",
"928435", "Mastung",
"928486", "Khuzdar",
"92715", "Sukkur",
"92572", "Attock",
"929436", "Chitral",
"92649", "Dera\ Ghazi\ Khan",
"92713", "Sukkur",
"92429", "Lahore",
"925448", "Jhelum",
"929229", "Kohat",
"925478", "Hafizabad",
"925424", "Narowal",
"928324", "Bolan",
"928378", "Jhal\ Magsi",
"929322", "Malakand",
"929467", "Swat",
"922324", "Tharparkar",
"92555", "Gujranwala",
"929463", "Swat",
"928223", "Zhob",
"92528", "Sialkot",
"928227", "Zhob",
"928245", "Loralai",
"928529", "Kech",
"924539", "Bhakkar",
"929964", "Shangla",
"92686", "Rahim\ Yar\ Khan",
"92553", "Gujranwala",
"926045", "Rajanpur",
"929433", "Chitral",
"92744", "Larkana",
"929954", "Haripur",
"92685", "Rahim\ Yar\ Khan",
"922984", "Thatta",
"929437", "Chitral",
"928372", "Jhal\ Magsi",
"92497", "Kasur",
"928487", "Khuzdar",
"92487", "Sargodha",
"922439", "Khairpur",
"92469", "Toba\ Tek\ Singh",
"928483", "Khuzdar",
"925472", "Hafizabad",
"92679", "Vehari",
"92637", "Bahawalnagar",
"929453", "Lower\ Dir",
"928439", "Mastung",
"92683", "Rahim\ Yar\ Khan",
"92518", "Islamabad\/Rawalpindi",
"929374", "Mardan",
"92556", "Gujranwala",
"929328", "Malakand",
"929457", "Lower\ Dir",
"924535", "Bhakkar",
"928525", "Kech",
"927264", "Shikarpur",
"928249", "Loralai",
"92634", "Bahawalnagar",
"925442", "Jhelum",
"92484", "Sargodha",
"928226", "Zhob",
"92494", "Kasur",
"926049", "Rajanpur",
"929466", "Swat",
"929225", "Kohat",
"92419", "Faisalabad",
"924592", "Mianwali",
"92747", "Larkana",
"92568", "Sheikhupura",
"92716", "Sukkur",
"925473", "Hafizabad",
"928377", "Jhal\ Magsi",
"928482", "Khuzdar",
"92406", "Sahiwal",
"92657", "Khanewal",
"92428", "Lahore",
"92612", "Multan",
"92252", "Dadu",
"922989", "Thatta",
"929959", "Haripur",
"92217", "Karachi",
"928373", "Jhal\ Magsi",
"925477", "Hafizabad",
"92536", "Gujrat",
"92648", "Dera\ Ghazi\ Khan",
"92817", "Quetta",
"929468", "Swat",
"929452", "Lower\ Dir",
"928228", "Zhob",
"92864", "Gwadar",
"928434", "Mastung",
"929379", "Mardan",
"927235", "Ghotki",
"922434", "Khairpur",
"929432", "Chitral",
"929965", "Shangla",
"929326", "Malakand",
"924597", "Mianwali",
"924593", "Mianwali",
"92662", "Muzaffargarh",
"926044", "Rajanpur",
"92472", "Jhang",
"92529", "Sialkot",
"92867", "Gwadar",
"928244", "Loralai",
"927269", "Shikarpur",
"922325", "Tharparkar",
"92814", "Quetta",
"925425", "Narowal",
"925447", "Jhelum",
"92214", "Karachi",
"92654", "Khanewal",
"928325", "Bolan",
"925443", "Jhelum",
"92519", "Islamabad\/Rawalpindi",
"929375", "Mardan",
"92678", "Vehari",
"927239", "Ghotki",
"92468", "Toba\ Tek\ Singh",
"92224", "Hyderabad",
"922985", "Thatta",
"929955", "Haripur",
"928376", "Jhal\ Magsi",
"925476", "Hafizabad",
"925446", "Jhelum",
"92533", "Gujrat",
"922329", "Tharparkar",
"92569", "Sheikhupura",
"928222", "Zhob",
"92403", "Sahiwal",
"92442", "Okara",
"929224", "Kohat",
"929438", "Chitral",
"92227", "Hyderabad",
"925429", "Narowal",
"92418", "Faisalabad",
"928329", "Bolan",
"92622", "Bahawalpur",
"92535", "Gujrat",
"92912", "Peshawar\/Charsadda",
"929969", "Shangla",
"92405", "Sahiwal",
"928488", "Khuzdar",
"929327", "Malakand",
"929462", "Swat",
"929458", "Lower\ Dir",
"924596", "Mianwali",
"927265", "Shikarpur",
"928524", "Kech",
"924534", "Bhakkar",
"929323", "Malakand",
"929972", "Mansehra\/Batagram",
"922974", "Badin",
"922334", "Mirpur\ Khas",
"929655", "South\ Waziristan",
"929692", "Lakki\ Marwat",
"928253", "Chagai",
"92564", "Sheikhupura",
"925434", "Chakwal",
"928334", "Sibi\/Ziarat",
"928257", "Chagai",
"928559", "Panjgur",
"922382", "Umerkot",
"92552", "Gujranwala",
"929384", "Swabi",
"92517", "Islamabad\/Rawalpindi",
"922354", "Sanghar",
"929635", "Tank",
"924546", "Khushab",
"92638", "Bahawalnagar",
"928289", "Musakhel",
"929395", "Buner",
"928473", "Kharan",
"92488", "Sargodha",
"928233", "Killa\ Saifullah",
"928354", "Dera\ Bugti",
"928237", "Killa\ Saifullah",
"928539", "Lasbela",
"926089", "Lodhran",
"92498", "Kasur",
"928382", "Jaffarabad\/Nasirabad",
"928477", "Kharan",
"928447", "Kalat",
"928266", "K\.Abdullah\/Pishin",
"929669", "D\.I\.\ Khan",
"928443", "Kalat",
"927224", "Jacobabad",
"922443", "Nawabshah",
"924576", "Pakpattan",
"926066", "Layyah",
"928565", "Awaran",
"92514", "Islamabad\/Rawalpindi",
"922447", "Nawabshah",
"922425", "Naushero\ Feroze",
"92575", "Attock",
"92712", "Sukkur",
"929449", "Upper\ Dir",
"92567", "Sheikhupura",
"92748", "Larkana",
"92229", "Hyderabad",
"929426", "Bajaur\ Agency",
"92573", "Attock",
"929639", "Tank",
"928294", "Barkhan\/Kohlu",
"92524", "Sialkot",
"928285", "Musakhel",
"928236", "Killa\ Saifullah",
"929399", "Buner",
"928476", "Kharan",
"924543", "Khushab",
"926085", "Lodhran",
"924547", "Khushab",
"928535", "Lasbela",
"929659", "South\ Waziristan",
"92659", "Khanewal",
"92219", "Karachi",
"928256", "Chagai",
"92576", "Attock",
"92819", "Quetta",
"928555", "Panjgur",
"929423", "Bajaur\ Agency",
"929427", "Bajaur\ Agency",
"929445", "Upper\ Dir",
"922388", "Umerkot",
"928388", "Jaffarabad\/Nasirabad",
"925464", "Mandi\ Bahauddin",
"929698", "Lakki\ Marwat",
"924577", "Pakpattan",
"926067", "Layyah",
"924573", "Pakpattan",
"929924", "Abottabad",
"929665", "D\.I\.\ Khan",
"926063", "Layyah",
"92682", "Rahim\ Yar\ Khan",
"929978", "Mansehra\/Batagram",
"922446", "Nawabshah",
"928446", "Kalat",
"928569", "Awaran",
"928267", "K\.Abdullah\/Pishin",
"928263", "K\.Abdullah\/Pishin",
"92869", "Gwadar",
"92527", "Sialkot",
"922429", "Naushero\ Feroze",
"92499", "Kasur",
"92467", "Toba\ Tek\ Singh",
"92489", "Sargodha",
"92677", "Vehari",
"928448", "Kalat",
"928355", "Dera\ Bugti",
"922448", "Nawabshah",
"929976", "Mansehra\/Batagram",
"92639", "Bahawalnagar",
"929634", "Tank",
"928299", "Barkhan\/Kohlu",
"922355", "Sanghar",
"929385", "Swabi",
"92663", "Muzaffargarh",
"929394", "Buner",
"929696", "Lakki\ Marwat",
"92473", "Jhang",
"925435", "Chakwal",
"928386", "Jaffarabad\/Nasirabad",
"928335", "Sibi\/Ziarat",
"922975", "Badin",
"929654", "South\ Waziristan",
"922335", "Mirpur\ Khas",
"922386", "Umerkot",
"92665", "Muzaffargarh",
"924542", "Khushab",
"92414", "Faisalabad",
"92475", "Jhang",
"92626", "Bahawalpur",
"92417", "Faisalabad",
"924572", "Pakpattan",
"926062", "Layyah",
"925469", "Mandi\ Bahauddin",
"92228", "Hyderabad",
"92925", "Hangu\/Orakzai\ Agy",
"92749", "Larkana",
"92446", "Okara",
"92613", "Multan",
"928262", "K\.Abdullah\/Pishin",
"928258", "Chagai",
"92253", "Dadu",
"928564", "Awaran",
"927225", "Jacobabad",
"922424", "Naushero\ Feroze",
"92923", "Nowshera",
"929422", "Bajaur\ Agency",
"92674", "Vehari",
"928478", "Kharan",
"92615", "Multan",
"928238", "Killa\ Saifullah",
"92464", "Toba\ Tek\ Singh",
"929929", "Abottabad",
"92916", "Peshawar\/Charsadda",
"92255", "Dadu",
"929428", "Bajaur\ Agency",
"922387", "Umerkot",
"925439", "Chakwal",
"928339", "Sibi\/Ziarat",
"92623", "Bahawalpur",
"92818", "Quetta",
"922383", "Umerkot",
"92647", "Dera\ Ghazi\ Khan",
"928554", "Panjgur",
"92532", "Gujrat",
"928383", "Jaffarabad\/Nasirabad",
"922339", "Mirpur\ Khas",
"922979", "Badin",
"92256", "Dadu",
"92915", "Peshawar\/Charsadda",
"92218", "Karachi",
"92658", "Khanewal",
"92427", "Lahore",
"92616", "Multan",
"92402", "Sahiwal",
"928232", "Killa\ Saifullah",
"92443", "Okara",
"928387", "Jaffarabad\/Nasirabad",
"928472", "Kharan",
"929977", "Mansehra\/Batagram",
"92926", "Kurram\ Agency",
"929693", "Lakki\ Marwat",
"929697", "Lakki\ Marwat",
"924578", "Pakpattan",
"926068", "Layyah",
"928359", "Dera\ Bugti",
"92625", "Bahawalpur",
"926084", "Lodhran",
"928534", "Lasbela",
"929973", "Mansehra\/Batagram",
"922359", "Sanghar",
"928295", "Barkhan\/Kohlu",
"929389", "Swabi",
"92913", "Peshawar\/Charsadda",
"928268", "K\.Abdullah\/Pishin",
"928252", "Chagai",
"92445", "Okara",
"928284", "Musakhel",
"927229", "Jacobabad",
"92868", "Gwadar",
"92476", "Jhang",
"92666", "Muzaffargarh",
"924548", "Khushab",
"929925", "Abottabad",
"929664", "D\.I\.\ Khan",
"928442", "Kalat",
"92424", "Lahore",
"925465", "Mandi\ Bahauddin",
"92644", "Dera\ Ghazi\ Khan",
"929444", "Upper\ Dir",
"922442", "Nawabshah",};
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