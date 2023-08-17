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
our $VERSION = 1.20230614174404;

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
$areanames{en} = {"925464", "Mandi\ Bahauddin",
"929696", "Lakki\ Marwat",
"929448", "Upper\ Dir",
"924538", "Bhakkar",
"92536", "Gujrat",
"925442", "Jhelum",
"92565", "Sheikhupura",
"928334", "Sibi\/Ziarat",
"929929", "Abottabad",
"928257", "Chagai",
"929372", "Mardan",
"925479", "Hafizabad",
"928447", "Kalat",
"92408", "Sahiwal",
"929326", "Malakand",
"928376", "Jhal\ Magsi",
"928322", "Bolan",
"92717", "Sukkur",
"922359", "Sanghar",
"926087", "Lodhran",
"92514", "Islamabad\/Rawalpindi",
"922972", "Badin",
"925423", "Narowal",
"922428", "Naushero\ Feroze",
"922329", "Tharparkar",
"929973", "Mansehra\/Batagram",
"928352", "Dera\ Bugti",
"92418", "Faisalabad",
"929639", "Tank",
"92562", "Sheikhupura",
"92427", "Lahore",
"929975", "Mansehra\/Batagram",
"927229", "Jacobabad",
"929228", "Kohat",
"925425", "Narowal",
"929666", "D\.I\.\ Khan",
"928227", "Zhob",
"926069", "Layyah",
"929959", "Haripur",
"92998", "Kohistan",
"92539", "Gujrat",
"92533", "Gujrat",
"928527", "Kech",
"92477", "Jhang",
"925434", "Chakwal",
"922975", "Badin",
"928355", "Dera\ Bugti",
"92688", "Rahim\ Yar\ Khan",
"922356", "Sanghar",
"92512", "Islamabad\/Rawalpindi",
"928478", "Kharan",
"928379", "Jhal\ Magsi",
"928353", "Dera\ Bugti",
"929428", "Bajaur\ Agency",
"929972", "Mansehra\/Batagram",
"925422", "Narowal",
"922973", "Badin",
"929329", "Malakand",
"92447", "Okara",
"929926", "Abottabad",
"925476", "Hafizabad",
"929699", "Lakki\ Marwat",
"92468", "Toba\ Tek\ Singh",
"929669", "D\.I\.\ Khan",
"92564", "Sheikhupura",
"926066", "Layyah",
"929956", "Haripur",
"928323", "Bolan",
"929458", "Lower\ Dir",
"925445", "Jhelum",
"92748", "Larkana",
"92638", "Bahawalnagar",
"927226", "Jacobabad",
"928247", "Loralai",
"929375", "Mardan",
"925443", "Jhelum",
"922448", "Nawabshah",
"928325", "Bolan",
"928557", "Panjgur",
"929373", "Mardan",
"92515", "Islamabad\/Rawalpindi",
"924598", "Mianwali",
"922326", "Tharparkar",
"929636", "Tank",
"922985", "Thatta",
"924575", "Pakpattan",
"92478", "Jhang",
"928563", "Awaran",
"928488", "Khuzdar",
"928244", "Loralai",
"928389", "Jaffarabad\/Nasirabad",
"928262", "K\.Abdullah\/Pishin",
"92687", "Rahim\ Yar\ Khan",
"927238", "Ghotki",
"92866", "Gwadar",
"928565", "Awaran",
"928554", "Panjgur",
"924573", "Pakpattan",
"926048", "Rajanpur",
"92448", "Okara",
"922983", "Thatta",
"929398", "Buner",
"922338", "Mirpur\ Khas",
"922439", "Khairpur",
"92467", "Toba\ Tek\ Singh",
"92522", "Sialkot",
"92747", "Larkana",
"925437", "Chakwal",
"928524", "Kech",
"929469", "Swat",
"92525", "Sialkot",
"929385", "Swabi",
"92637", "Bahawalnagar",
"929658", "South\ Waziristan",
"928235", "Killa\ Saifullah",
"928432", "Mastung",
"92554", "Gujranwala",
"92813", "Quetta",
"92869", "Gwadar",
"924546", "Khushab",
"928292", "Barkhan\/Kohlu",
"929436", "Chitral",
"928532", "Lasbela",
"92574", "Attock",
"928233", "Killa\ Saifullah",
"929383", "Swabi",
"922382", "Umerkot",
"928533", "Lasbela",
"928293", "Barkhan\/Kohlu",
"922436", "Khairpur",
"928232", "Killa\ Saifullah",
"928435", "Mastung",
"92407", "Sahiwal",
"9258", "AJK\/FATA",
"92863", "Gwadar",
"922383", "Umerkot",
"92819", "Quetta",
"92524", "Sialkot",
"927268", "Shikarpur",
"929382", "Swabi",
"928295", "Barkhan\/Kohlu",
"92718", "Sukkur",
"928535", "Lasbela",
"92555", "Gujranwala",
"928386", "Jaffarabad\/Nasirabad",
"928224", "Zhob",
"922385", "Umerkot",
"92575", "Attock",
"928433", "Mastung",
"92552", "Gujranwala",
"924572", "Pakpattan",
"928337", "Sibi\/Ziarat",
"925467", "Mandi\ Bahauddin",
"922982", "Thatta",
"92417", "Faisalabad",
"924549", "Khushab",
"92572", "Attock",
"929439", "Chitral",
"928254", "Chagai",
"928444", "Kalat",
"928288", "Musakhel",
"928265", "K\.Abdullah\/Pishin",
"929968", "Shangla",
"92428", "Lahore",
"92816", "Quetta",
"926084", "Lodhran",
"929466", "Swat",
"928562", "Awaran",
"928263", "K\.Abdullah\/Pishin",
"927239", "Ghotki",
"925435", "Chakwal",
"922974", "Badin",
"92563", "Sheikhupura",
"928388", "Jaffarabad\/Nasirabad",
"928489", "Khuzdar",
"928354", "Dera\ Bugti",
"92519", "Islamabad\/Rawalpindi",
"928237", "Killa\ Saifullah",
"929387", "Swabi",
"925433", "Chakwal",
"922438", "Khairpur",
"922339", "Mirpur\ Khas",
"929399", "Buner",
"926049", "Rajanpur",
"927266", "Shikarpur",
"924577", "Pakpattan",
"92647", "Dera\ Ghazi\ Khan",
"929659", "South\ Waziristan",
"928332", "Sibi\/Ziarat",
"929966", "Shangla",
"922987", "Thatta",
"925462", "Mandi\ Bahauddin",
"92534", "Gujrat",
"929468", "Swat",
"925444", "Jhelum",
"92668", "Muzaffargarh",
"92218", "Karachi",
"929374", "Mardan",
"92677", "Vehari",
"928324", "Bolan",
"928567", "Awaran",
"92657", "Khanewal",
"92488", "Sargodha",
"92227", "Hyderabad",
"92516", "Islamabad\/Rawalpindi",
"928286", "Musakhel",
"925465", "Mandi\ Bahauddin",
"92535", "Gujrat",
"92498", "Kasur",
"927269", "Shikarpur",
"929396", "Buner",
"92257", "Dadu",
"926046", "Rajanpur",
"92627", "Bahawalpur",
"928335", "Sibi\/Ziarat",
"92566", "Sheikhupura",
"922336", "Mirpur\ Khas",
"928267", "K\.Abdullah\/Pishin",
"92927", "Karak",
"928333", "Sibi\/Ziarat",
"92618", "Multan",
"925463", "Mandi\ Bahauddin",
"928486", "Khuzdar",
"92918", "Peshawar\/Charsadda",
"927236", "Ghotki",
"928289", "Musakhel",
"929438", "Chitral",
"924548", "Khushab",
"925432", "Chakwal",
"928437", "Mastung",
"92532", "Gujrat",
"929974", "Mansehra\/Batagram",
"928537", "Lasbela",
"928297", "Barkhan\/Kohlu",
"925424", "Narowal",
"92513", "Islamabad\/Rawalpindi",
"92569", "Sheikhupura",
"929656", "South\ Waziristan",
"922387", "Umerkot",
"929969", "Shangla",
"92258", "Dadu",
"92628", "Bahawalpur",
"929426", "Bajaur\ Agency",
"928522", "Kech",
"92497", "Kasur",
"92812", "Quetta",
"925478", "Hafizabad",
"929928", "Abottabad",
"928434", "Mastung",
"924539", "Bhakkar",
"92928", "Bannu\/N\.\ Waziristan",
"928223", "Zhob",
"929449", "Upper\ Dir",
"929977", "Mansehra\/Batagram",
"928294", "Barkhan\/Kohlu",
"925427", "Narowal",
"928534", "Lasbela",
"92617", "Multan",
"92556", "Gujranwala",
"922358", "Sanghar",
"92917", "Peshawar\/Charsadda",
"928225", "Zhob",
"922384", "Umerkot",
"92576", "Attock",
"928476", "Kharan",
"92579", "Attock",
"922446", "Nawabshah",
"926083", "Lodhran",
"92864", "Gwadar",
"92523", "Sialkot",
"92559", "Gujranwala",
"929638", "Tank",
"928255", "Chagai",
"922328", "Tharparkar",
"928242", "Loralai",
"922429", "Naushero\ Feroze",
"928264", "K\.Abdullah\/Pishin",
"924596", "Mianwali",
"928445", "Kalat",
"92815", "Quetta",
"926085", "Lodhran",
"926068", "Layyah",
"929958", "Haripur",
"929456", "Lower\ Dir",
"928552", "Panjgur",
"929229", "Kohat",
"928443", "Kalat",
"927228", "Jacobabad",
"928253", "Chagai",
"928378", "Jhal\ Magsi",
"922984", "Thatta",
"925447", "Jhelum",
"928479", "Kharan",
"924574", "Pakpattan",
"928553", "Panjgur",
"928252", "Chagai",
"928245", "Loralai",
"928442", "Kalat",
"929377", "Mardan",
"92865", "Gwadar",
"928564", "Awaran",
"924536", "Bhakkar",
"928555", "Panjgur",
"929698", "Lakki\ Marwat",
"929446", "Upper\ Dir",
"92553", "Gujranwala",
"92529", "Sialkot",
"92814", "Quetta",
"926082", "Lodhran",
"928327", "Bolan",
"929328", "Malakand",
"92573", "Attock",
"928243", "Loralai",
"929429", "Bajaur\ Agency",
"922977", "Badin",
"928357", "Dera\ Bugti",
"929226", "Kohat",
"92648", "Dera\ Ghazi\ Khan",
"928525", "Kech",
"92217", "Karachi",
"92667", "Muzaffargarh",
"92526", "Sialkot",
"929459", "Lower\ Dir",
"929384", "Swabi",
"928234", "Killa\ Saifullah",
"929668", "D\.I\.\ Khan",
"928523", "Kech",
"922426", "Naushero\ Feroze",
"924599", "Mianwali",
"92678", "Vehari",
"92862", "Gwadar",
"928222", "Zhob",
"92658", "Khanewal",
"922449", "Nawabshah",
"92228", "Hyderabad",
"92487", "Sargodha",
"92216", "Karachi",
"92666", "Muzaffargarh",
"92527", "Sialkot",
"928487", "Khuzdar",
"92635", "Bahawalnagar",
"92462", "Toba\ Tek\ Singh",
"92404", "Sahiwal",
"927237", "Ghotki",
"929465", "Swat",
"92745", "Larkana",
"929454", "Lower\ Dir",
"929389", "Swabi",
"928239", "Killa\ Saifullah",
"92682", "Rahim\ Yar\ Khan",
"924594", "Mianwali",
"928266", "K\.Abdullah\/Pishin",
"922337", "Mirpur\ Khas",
"92518", "Islamabad\/Rawalpindi",
"92486", "Sargodha",
"929397", "Buner",
"922444", "Nawabshah",
"929463", "Swat",
"926047", "Rajanpur",
"922989", "Thatta",
"928474", "Kharan",
"924579", "Pakpattan",
"92685", "Rahim\ Yar\ Khan",
"922386", "Umerkot",
"929657", "South\ Waziristan",
"92489", "Sargodha",
"928385", "Jaffarabad\/Nasirabad",
"92414", "Faisalabad",
"925438", "Chakwal",
"924542", "Khushab",
"922433", "Khairpur",
"92493", "Kasur",
"928296", "Barkhan\/Kohlu",
"929432", "Chitral",
"928536", "Lasbela",
"928569", "Awaran",
"92913", "Peshawar\/Charsadda",
"92632", "Bahawalnagar",
"92465", "Toba\ Tek\ Singh",
"928436", "Mastung",
"922435", "Khairpur",
"928383", "Jaffarabad\/Nasirabad",
"92613", "Multan",
"92219", "Karachi",
"929424", "Bajaur\ Agency",
"92669", "Muzaffargarh",
"92742", "Larkana",
"92663", "Muzaffargarh",
"92684", "Rahim\ Yar\ Khan",
"92213", "Karachi",
"92619", "Multan",
"927267", "Shikarpur",
"924545", "Khushab",
"929435", "Chitral",
"928269", "K\.Abdullah\/Pishin",
"92415", "Faisalabad",
"922424", "Naushero\ Feroze",
"928382", "Jaffarabad\/Nasirabad",
"92919", "Peshawar\/Charsadda",
"928236", "Killa\ Saifullah",
"92499", "Kasur",
"92464", "Toba\ Tek\ Singh",
"92483", "Sargodha",
"92402", "Sahiwal",
"929386", "Swabi",
"929224", "Kohat",
"929433", "Chitral",
"922432", "Khairpur",
"924543", "Khushab",
"92634", "Bahawalnagar",
"92405", "Sahiwal",
"928287", "Musakhel",
"92568", "Sheikhupura",
"928338", "Sibi\/Ziarat",
"928439", "Mastung",
"928566", "Awaran",
"929462", "Swat",
"924534", "Bhakkar",
"92496", "Kasur",
"929444", "Upper\ Dir",
"92744", "Larkana",
"925468", "Mandi\ Bahauddin",
"928299", "Barkhan\/Kohlu",
"92916", "Peshawar\/Charsadda",
"928539", "Lasbela",
"92577", "Attock",
"924576", "Pakpattan",
"922389", "Umerkot",
"929967", "Shangla",
"92412", "Faisalabad",
"922986", "Thatta",
"92557", "Gujranwala",
"92616", "Multan",
"927223", "Jacobabad",
"928284", "Musakhel",
"928448", "Kalat",
"922325", "Tharparkar",
"928258", "Chagai",
"929635", "Tank",
"92643", "Dera\ Ghazi\ Khan",
"924537", "Bhakkar",
"929447", "Upper\ Dir",
"929953", "Haripur",
"926063", "Layyah",
"92712", "Sukkur",
"928372", "Jhal\ Magsi",
"92474", "Jhang",
"928326", "Bolan",
"92629", "Bahawalpur",
"92653", "Khanewal",
"929376", "Mardan",
"92259", "Dadu",
"92223", "Hyderabad",
"929633", "Tank",
"929979", "Mansehra\/Batagram",
"922323", "Tharparkar",
"927225", "Jacobabad",
"925429", "Narowal",
"929322", "Malakand",
"929692", "Lakki\ Marwat",
"92673", "Vehari",
"925446", "Jhelum",
"92425", "Lahore",
"926088", "Lodhran",
"929955", "Haripur",
"926065", "Layyah",
"92444", "Okara",
"929964", "Shangla",
"922353", "Sanghar",
"927264", "Shikarpur",
"92926", "Kurram\ Agency",
"929662", "D\.I\.\ Khan",
"929925", "Abottabad",
"92422", "Lahore",
"925475", "Hafizabad",
"922427", "Naushero\ Feroze",
"92626", "Bahawalpur",
"92567", "Sheikhupura",
"92256", "Dadu",
"92578", "Attock",
"928228", "Zhob",
"922355", "Sanghar",
"92558", "Gujranwala",
"922976", "Badin",
"928356", "Dera\ Bugti",
"925473", "Hafizabad",
"929227", "Kohat",
"92715", "Sukkur",
"929923", "Abottabad",
"929665", "D\.I\.\ Khan",
"929654", "South\ Waziristan",
"928477", "Kharan",
"92528", "Sialkot",
"925449", "Jhelum",
"928528", "Kech",
"929976", "Mansehra\/Batagram",
"92646", "Dera\ Ghazi\ Khan",
"925426", "Narowal",
"929922", "Abottabad",
"92442", "Okara",
"929379", "Mardan",
"925472", "Hafizabad",
"92226", "Hyderabad",
"92517", "Islamabad\/Rawalpindi",
"92656", "Khanewal",
"928329", "Bolan",
"922352", "Sanghar",
"929663", "D\.I\.\ Khan",
"929427", "Bajaur\ Agency",
"92714", "Sukkur",
"92676", "Vehari",
"92472", "Jhang",
"92923", "Nowshera",
"927234", "Ghotki",
"929323", "Malakand",
"922979", "Badin",
"928248", "Loralai",
"922322", "Tharparkar",
"928484", "Khuzdar",
"928359", "Dera\ Bugti",
"92679", "Vehari",
"929632", "Tank",
"92475", "Jhang",
"929693", "Lakki\ Marwat",
"92229", "Hyderabad",
"92253", "Dadu",
"92659", "Khanewal",
"92623", "Bahawalpur",
"928375", "Jhal\ Magsi",
"929457", "Lower\ Dir",
"927222", "Jacobabad",
"929325", "Malakand",
"922334", "Mirpur\ Khas",
"924597", "Mianwali",
"92649", "Dera\ Ghazi\ Khan",
"928373", "Jhal\ Magsi",
"929394", "Buner",
"929952", "Haripur",
"92424", "Lahore",
"926062", "Layyah",
"926044", "Rajanpur",
"92445", "Okara",
"922447", "Nawabshah",
"929695", "Lakki\ Marwat",
"928558", "Panjgur",
"92912", "Peshawar\/Charsadda",
"92633", "Bahawalnagar",
"928472", "Kharan",
"92612", "Multan",
"924544", "Khushab",
"929434", "Chitral",
"92743", "Larkana",
"928259", "Chagai",
"92416", "Faisalabad",
"929927", "Abottabad",
"922425", "Naushero\ Feroze",
"928449", "Kalat",
"925477", "Hafizabad",
"929223", "Kohat",
"922357", "Sanghar",
"926089", "Lodhran",
"92817", "Quetta",
"929225", "Kohat",
"925428", "Narowal",
"922423", "Naushero\ Feroze",
"92492", "Kasur",
"929978", "Mansehra\/Batagram",
"929422", "Bajaur\ Agency",
"928526", "Kech",
"92409", "Sahiwal",
"92406", "Sahiwal",
"92664", "Muzaffargarh",
"92683", "Rahim\ Yar\ Khan",
"92214", "Karachi",
"929637", "Tank",
"922327", "Tharparkar",
"92495", "Kasur",
"92538", "Gujrat",
"924535", "Bhakkar",
"928556", "Panjgur",
"929452", "Lower\ Dir",
"929445", "Upper\ Dir",
"92419", "Faisalabad",
"92915", "Peshawar\/Charsadda",
"92484", "Sargodha",
"92463", "Toba\ Tek\ Singh",
"927227", "Jacobabad",
"928246", "Loralai",
"924592", "Mianwali",
"929957", "Haripur",
"929443", "Upper\ Dir",
"926067", "Layyah",
"928229", "Zhob",
"922442", "Nawabshah",
"924533", "Bhakkar",
"92615", "Multan",
"92215", "Karachi",
"929378", "Mardan",
"92665", "Muzaffargarh",
"924593", "Mianwali",
"92636", "Bahawalnagar",
"928529", "Kech",
"92746", "Larkana",
"925448", "Jhelum",
"929464", "Swat",
"924532", "Bhakkar",
"922443", "Nawabshah",
"92494", "Kasur",
"929455", "Lower\ Dir",
"928377", "Jhal\ Magsi",
"929442", "Upper\ Dir",
"92469", "Toba\ Tek\ Singh",
"926086", "Lodhran",
"92413", "Faisalabad",
"928256", "Chagai",
"924595", "Mianwali",
"928446", "Kalat",
"92914", "Peshawar\/Charsadda",
"929327", "Malakand",
"92485", "Sargodha",
"92614", "Multan",
"929697", "Lakki\ Marwat",
"92689", "Rahim\ Yar\ Khan",
"929453", "Lower\ Dir",
"928328", "Bolan",
"922445", "Nawabshah",
"92482", "Sargodha",
"92403", "Sahiwal",
"928475", "Kharan",
"928226", "Zhob",
"92867", "Gwadar",
"929667", "D\.I\.\ Khan",
"92686", "Rahim\ Yar\ Khan",
"929423", "Bajaur\ Agency",
"928358", "Dera\ Bugti",
"928249", "Loralai",
"928384", "Jaffarabad\/Nasirabad",
"922422", "Naushero\ Feroze",
"922978", "Badin",
"92466", "Toba\ Tek\ Singh",
"928559", "Panjgur",
"92749", "Larkana",
"92662", "Muzaffargarh",
"928473", "Kharan",
"92212", "Karachi",
"922434", "Khairpur",
"92639", "Bahawalnagar",
"929222", "Kohat",
"929425", "Bajaur\ Agency",
"929664", "D\.I\.\ Khan",
"928238", "Killa\ Saifullah",
"929655", "South\ Waziristan",
"929388", "Swabi",
"927262", "Shikarpur",
"92449", "Okara",
"92924", "Khyber\/Mohmand\ Agy",
"92254", "Dadu",
"92645", "Dera\ Ghazi\ Khan",
"92624", "Bahawalpur",
"928387", "Jaffarabad\/Nasirabad",
"92655", "Khanewal",
"92225", "Hyderabad",
"92479", "Jhang",
"929653", "South\ Waziristan",
"92675", "Vehari",
"92423", "Lahore",
"922437", "Khairpur",
"92868", "Gwadar",
"922333", "Mirpur\ Khas",
"927235", "Ghotki",
"925439", "Chakwal",
"928282", "Musakhel",
"92652", "Khanewal",
"928485", "Khuzdar",
"92222", "Hyderabad",
"92476", "Jhang",
"924578", "Pakpattan",
"92672", "Vehari",
"926043", "Rajanpur",
"929467", "Swat",
"922988", "Thatta",
"928374", "Jhal\ Magsi",
"929393", "Buner",
"928483", "Khuzdar",
"929324", "Malakand",
"927233", "Ghotki",
"922335", "Mirpur\ Khas",
"929395", "Buner",
"92446", "Okara",
"926045", "Rajanpur",
"928336", "Sibi\/Ziarat",
"929962", "Shangla",
"929694", "Lakki\ Marwat",
"92642", "Dera\ Ghazi\ Khan",
"925466", "Mandi\ Bahauddin",
"92713", "Sukkur",
"928568", "Awaran",
"92719", "Sukkur",
"928285", "Musakhel",
"928268", "K\.Abdullah\/Pishin",
"922324", "Tharparkar",
"928482", "Khuzdar",
"929634", "Tank",
"927232", "Ghotki",
"929963", "Shangla",
"922332", "Mirpur\ Khas",
"927224", "Jacobabad",
"928283", "Musakhel",
"92252", "Dadu",
"92622", "Bahawalpur",
"929392", "Buner",
"929954", "Haripur",
"926064", "Layyah",
"92818", "Quetta",
"92426", "Lahore",
"926042", "Rajanpur",
"929965", "Shangla",
"925469", "Mandi\ Bahauddin",
"927265", "Shikarpur",
"92429", "Lahore",
"92925", "Hangu\/Orakzai\ Agy",
"928438", "Mastung",
"929652", "South\ Waziristan",
"928339", "Sibi\/Ziarat",
"929924", "Abottabad",
"92537", "Gujrat",
"925474", "Hafizabad",
"92473", "Jhang",
"924547", "Khushab",
"92644", "Dera\ Ghazi\ Khan",
"92255", "Dadu",
"929437", "Chitral",
"92625", "Bahawalpur",
"922388", "Umerkot",
"92654", "Khanewal",
"927263", "Shikarpur",
"922354", "Sanghar",
"92224", "Hyderabad",
"92443", "Okara",
"92674", "Vehari",
"928538", "Lasbela",
"92716", "Sukkur",
"928298", "Barkhan\/Kohlu",
"925436", "Chakwal",};

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