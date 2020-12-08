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
our $VERSION = 1.20201204215957;

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
$areanames{en} = {"92748", "Larkana",
"92477", "Jhang",
"929393", "Buner",
"92449", "Okara",
"922333", "Mirpur\ Khas",
"92427", "Lahore",
"92864", "Gwadar",
"928484", "Khuzdar",
"928568", "Awaran",
"926044", "Rajanpur",
"929443", "Upper\ Dir",
"929438", "Chitral",
"928282", "Musakhel",
"929925", "Abottabad",
"922359", "Sanghar",
"929969", "Shangla",
"92565", "Sheikhupura",
"925462", "Mandi\ Bahauddin",
"92417", "Faisalabad",
"929378", "Mardan",
"925426", "Narowal",
"929653", "South\ Waziristan",
"922446", "Nawabshah",
"928477", "Kharan",
"928297", "Barkhan\/Kohlu",
"92712", "Sukkur",
"929375", "Mardan",
"92513", "Islamabad\/Rawalpindi",
"92228", "Hyderabad",
"92404", "Sahiwal",
"928537", "Lasbela",
"929435", "Chitral",
"929928", "Abottabad",
"928337", "Sibi\/Ziarat",
"929467", "Swat",
"928224", "Zhob",
"92218", "Karachi",
"928565", "Awaran",
"92523", "Sialkot",
"92573", "Attock",
"928529", "Kech",
"92485", "Sargodha",
"92559", "Gujranwala",
"922986", "Thatta",
"929639", "Tank",
"92688", "Rahim\ Yar\ Khan",
"928329", "Bolan",
"92539", "Gujrat",
"929694", "Lakki\ Marwat",
"92252", "Dadu",
"92413", "Faisalabad",
"92869", "Gwadar",
"928263", "K\.Abdullah\/Pishin",
"92444", "Okara",
"929454", "Lower\ Dir",
"922988", "Thatta",
"92616", "Multan",
"92912", "Peshawar\/Charsadda",
"92676", "Vehari",
"928289", "Musakhel",
"922448", "Nawabshah",
"92626", "Bahawalpur",
"922433", "Khairpur",
"925425", "Narowal",
"925469", "Mandi\ Bahauddin",
"929962", "Shangla",
"92473", "Jhang",
"928384", "Jaffarabad\/Nasirabad",
"92498", "Kasur",
"929926", "Abottabad",
"92423", "Lahore",
"922352", "Sanghar",
"928247", "Loralai",
"929436", "Chitral",
"92527", "Sialkot",
"922445", "Nawabshah",
"92577", "Attock",
"92409", "Sahiwal",
"929376", "Mardan",
"925428", "Narowal",
"92668", "Muzaffargarh",
"922985", "Thatta",
"928377", "Jhal\ Magsi",
"92465", "Toba\ Tek\ Singh",
"92517", "Islamabad\/Rawalpindi",
"928437", "Mastung",
"92534", "Gujrat",
"928322", "Bolan",
"929632", "Tank",
"92554", "Gujranwala",
"928566", "Awaran",
"928522", "Kech",
"927233", "Ghotki",
"929327", "Malakand",
"928288", "Musakhel",
"922449", "Nawabshah",
"929432", "Chitral",
"926043", "Rajanpur",
"929444", "Upper\ Dir",
"92445", "Okara",
"929372", "Mardan",
"925468", "Mandi\ Bahauddin",
"92648", "Dera\ Ghazi\ Khan",
"924537", "Bhakkar",
"922334", "Mirpur\ Khas",
"92569", "Sheikhupura",
"929394", "Buner",
"928526", "Kech",
"928562", "Awaran",
"929636", "Tank",
"922989", "Thatta",
"928326", "Bolan",
"928483", "Khuzdar",
"92817", "Quetta",
"926067", "Layyah",
"92256", "Dadu",
"928223", "Zhob",
"92612", "Multan",
"92926", "Kurram\ Agency",
"929693", "Lakki\ Marwat",
"925437", "Chakwal",
"928257", "Chagai",
"92555", "Gujranwala",
"929977", "Mansehra\/Batagram",
"92489", "Sargodha",
"925465", "Mandi\ Bahauddin",
"92916", "Peshawar\/Charsadda",
"92672", "Vehari",
"92535", "Gujrat",
"929654", "South\ Waziristan",
"92622", "Bahawalpur",
"922356", "Sanghar",
"929922", "Abottabad",
"929966", "Shangla",
"928285", "Musakhel",
"92464", "Toba\ Tek\ Singh",
"925429", "Narowal",
"922434", "Khairpur",
"92716", "Sukkur",
"929439", "Chitral",
"922442", "Nawabshah",
"92865", "Gwadar",
"922358", "Sanghar",
"924577", "Pakpattan",
"928383", "Jaffarabad\/Nasirabad",
"929968", "Shangla",
"929667", "D\.I\.\ Khan",
"929379", "Mardan",
"928525", "Kech",
"92564", "Sheikhupura",
"929635", "Tank",
"928325", "Bolan",
"929427", "Bajaur\ Agency",
"928264", "K\.Abdullah\/Pishin",
"92638", "Bahawalnagar",
"922982", "Thatta",
"92658", "Khanewal",
"928569", "Awaran",
"929453", "Lower\ Dir",
"922387", "Umerkot",
"92405", "Sahiwal",
"928528", "Kech",
"927234", "Ghotki",
"929638", "Tank",
"928328", "Bolan",
"925477", "Hafizabad",
"922355", "Sanghar",
"928286", "Musakhel",
"929965", "Shangla",
"92484", "Sargodha",
"925422", "Narowal",
"925466", "Mandi\ Bahauddin",
"92469", "Toba\ Tek\ Singh",
"92813", "Quetta",
"929929", "Abottabad",
"92487", "Sargodha",
"927239", "Ghotki",
"929456", "Lower\ Dir",
"929698", "Lakki\ Marwat",
"92642", "Dera\ Ghazi\ Khan",
"925447", "Jhelum",
"929387", "Swabi",
"928228", "Zhob",
"928485", "Khuzdar",
"927227", "Jacobabad",
"926045", "Rajanpur",
"92463", "Toba\ Tek\ Singh",
"92819", "Quetta",
"928386", "Jaffarabad\/Nasirabad",
"929924", "Abottabad",
"929652", "South\ Waziristan",
"92666", "Muzaffargarh",
"92618", "Multan",
"925463", "Mandi\ Bahauddin",
"92567", "Sheikhupura",
"929374", "Mardan",
"92415", "Faisalabad",
"926048", "Rajanpur",
"922439", "Khairpur",
"929442", "Upper\ Dir",
"929434", "Chitral",
"928283", "Musakhel",
"92496", "Kasur",
"928488", "Khuzdar",
"928225", "Zhob",
"928564", "Awaran",
"922332", "Mirpur\ Khas",
"92425", "Lahore",
"929392", "Buner",
"92475", "Jhang",
"922427", "Naushero\ Feroze",
"92678", "Vehari",
"928269", "K\.Abdullah\/Pishin",
"92628", "Bahawalpur",
"929695", "Lakki\ Marwat",
"924547", "Khushab",
"928323", "Bolan",
"928486", "Khuzdar",
"928523", "Kech",
"927232", "Ghotki",
"92226", "Hyderabad",
"929633", "Tank",
"928357", "Dera\ Bugti",
"929455", "Lower\ Dir",
"928557", "Panjgur",
"92467", "Toba\ Tek\ Singh",
"92515", "Islamabad\/Rawalpindi",
"92686", "Rahim\ Yar\ Khan",
"92575", "Attock",
"92632", "Bahawalnagar",
"92525", "Sialkot",
"92814", "Quetta",
"92652", "Khanewal",
"925424", "Narowal",
"92216", "Karachi",
"926046", "Rajanpur",
"928385", "Jaffarabad\/Nasirabad",
"929659", "South\ Waziristan",
"922977", "Badin",
"92483", "Sargodha",
"922353", "Sanghar",
"928388", "Jaffarabad\/Nasirabad",
"929227", "Kohat",
"929963", "Shangla",
"922444", "Nawabshah",
"922327", "Tharparkar",
"92746", "Larkana",
"929449", "Upper\ Dir",
"922432", "Khairpur",
"922984", "Thatta",
"929458", "Lower\ Dir",
"929696", "Lakki\ Marwat",
"924597", "Mianwali",
"928262", "K\.Abdullah\/Pishin",
"92563", "Sheikhupura",
"928226", "Zhob",
"929399", "Buner",
"922339", "Mirpur\ Khas",
"92514", "Islamabad\/Rawalpindi",
"92403", "Sahiwal",
"929923", "Abottabad",
"929445", "Upper\ Dir",
"92742", "Larkana",
"922436", "Khairpur",
"92557", "Gujranwala",
"929957", "Haripur",
"929658", "South\ Waziristan",
"92537", "Gujrat",
"929692", "Lakki\ Marwat",
"922335", "Mirpur\ Khas",
"929395", "Buner",
"92815", "Quetta",
"928222", "Zhob",
"92574", "Attock",
"92524", "Sialkot",
"928266", "K\.Abdullah\/Pishin",
"928563", "Awaran",
"929459", "Lower\ Dir",
"927236", "Ghotki",
"92222", "Hyderabad",
"928482", "Khuzdar",
"92419", "Faisalabad",
"929398", "Buner",
"922338", "Mirpur\ Khas",
"92718", "Sukkur",
"92863", "Gwadar",
"92656", "Khanewal",
"92479", "Jhang",
"929373", "Mardan",
"92429", "Lahore",
"925464", "Mandi\ Bahauddin",
"92447", "Okara",
"92636", "Bahawalnagar",
"928389", "Jaffarabad\/Nasirabad",
"929655", "South\ Waziristan",
"92682", "Rahim\ Yar\ Khan",
"929433", "Chitral",
"928284", "Musakhel",
"92212", "Karachi",
"929448", "Upper\ Dir",
"926042", "Rajanpur",
"922435", "Khairpur",
"925423", "Narowal",
"92928", "Bannu\/N\.\ Waziristan",
"92519", "Islamabad\/Rawalpindi",
"928237", "Killa\ Saifullah",
"926087", "Lodhran",
"92258", "Dadu",
"929446", "Upper\ Dir",
"928524", "Kech",
"928447", "Kalat",
"929634", "Tank",
"92533", "Gujrat",
"927238", "Ghotki",
"92492", "Kasur",
"928324", "Bolan",
"929699", "Lakki\ Marwat",
"928265", "K\.Abdullah\/Pishin",
"92553", "Gujranwala",
"92918", "Peshawar\/Charsadda",
"92529", "Sialkot",
"92579", "Attock",
"928229", "Zhob",
"92407", "Sahiwal",
"929396", "Buner",
"922336", "Mirpur\ Khas",
"928489", "Khuzdar",
"92646", "Dera\ Ghazi\ Khan",
"929452", "Lower\ Dir",
"922983", "Thatta",
"92414", "Faisalabad",
"927235", "Ghotki",
"92443", "Okara",
"928268", "K\.Abdullah\/Pishin",
"922354", "Sanghar",
"928382", "Jaffarabad\/Nasirabad",
"929964", "Shangla",
"92867", "Gwadar",
"92424", "Lahore",
"927267", "Shikarpur",
"92474", "Jhang",
"926049", "Rajanpur",
"922438", "Khairpur",
"92662", "Muzaffargarh",
"929656", "South\ Waziristan",
"922443", "Nawabshah",
"929664", "D\.I\.\ Khan",
"927268", "Shikarpur",
"92536", "Gujrat",
"92915", "Peshawar\/Charsadda",
"929222", "Kohat",
"92556", "Gujranwala",
"928235", "Killa\ Saifullah",
"924574", "Pakpattan",
"926085", "Lodhran",
"929956", "Haripur",
"922322", "Tharparkar",
"922437", "Khairpur",
"92255", "Dadu",
"928267", "K\.Abdullah\/Pishin",
"929424", "Bajaur\ Agency",
"924592", "Mianwali",
"924549", "Khushab",
"92925", "Hangu\/Orakzai\ Agy",
"928445", "Kalat",
"922429", "Naushero\ Feroze",
"925449", "Jhelum",
"928433", "Mastung",
"92462", "Toba\ Tek\ Singh",
"928448", "Kalat",
"927237", "Ghotki",
"928373", "Jhal\ Magsi",
"92624", "Bahawalpur",
"928352", "Dera\ Bugti",
"922384", "Umerkot",
"92674", "Vehari",
"928552", "Panjgur",
"929389", "Swabi",
"92643", "Dera\ Ghazi\ Khan",
"927229", "Jacobabad",
"92614", "Multan",
"928243", "Loralai",
"92637", "Bahawalnagar",
"927265", "Shikarpur",
"9258", "AJK\/FATA",
"92657", "Khanewal",
"922972", "Badin",
"926088", "Lodhran",
"925474", "Hafizabad",
"928238", "Killa\ Saifullah",
"92446", "Okara",
"929229", "Kohat",
"92818", "Quetta",
"929955", "Haripur",
"929447", "Upper\ Dir",
"922329", "Tharparkar",
"926086", "Lodhran",
"928236", "Killa\ Saifullah",
"92562", "Sheikhupura",
"929324", "Malakand",
"92406", "Sahiwal",
"928446", "Kalat",
"929397", "Buner",
"922337", "Mirpur\ Khas",
"924534", "Bhakkar",
"922422", "Naushero\ Feroze",
"924542", "Khushab",
"924599", "Mianwali",
"928254", "Chagai",
"92653", "Khanewal",
"925434", "Chakwal",
"92633", "Bahawalnagar",
"925442", "Jhelum",
"92482", "Sargodha",
"929463", "Swat",
"929382", "Swabi",
"928559", "Panjgur",
"926064", "Layyah",
"92679", "Vehari",
"92647", "Dera\ Ghazi\ Khan",
"928359", "Dera\ Bugti",
"92629", "Bahawalpur",
"92619", "Multan",
"927222", "Jacobabad",
"928533", "Lasbela",
"927266", "Shikarpur",
"92715", "Sukkur",
"928333", "Sibi\/Ziarat",
"922979", "Badin",
"929657", "South\ Waziristan",
"929958", "Haripur",
"929974", "Mansehra\/Batagram",
"928473", "Kharan",
"92866", "Gwadar",
"928293", "Barkhan\/Kohlu",
"925446", "Jhelum",
"92683", "Rahim\ Yar\ Khan",
"928555", "Panjgur",
"929457", "Lower\ Dir",
"928355", "Dera\ Bugti",
"92213", "Karachi",
"92528", "Sialkot",
"92919", "Peshawar\/Charsadda",
"92578", "Attock",
"92486", "Sargodha",
"929423", "Bajaur\ Agency",
"924598", "Mianwali",
"929386", "Swabi",
"92667", "Muzaffargarh",
"929228", "Kohat",
"924573", "Pakpattan",
"928387", "Jaffarabad\/Nasirabad",
"922975", "Badin",
"927262", "Shikarpur",
"927226", "Jacobabad",
"92223", "Hyderabad",
"92518", "Islamabad\/Rawalpindi",
"929663", "D\.I\.\ Khan",
"92259", "Dadu",
"922328", "Tharparkar",
"92862", "Gwadar",
"922325", "Tharparkar",
"929225", "Kohat",
"928232", "Killa\ Saifullah",
"926082", "Lodhran",
"922978", "Badin",
"925473", "Hafizabad",
"92566", "Sheikhupura",
"929959", "Haripur",
"928244", "Loralai",
"928442", "Kalat",
"92402", "Sahiwal",
"924595", "Mianwali",
"928434", "Mastung",
"924546", "Khushab",
"92714", "Sukkur",
"928558", "Panjgur",
"92497", "Kasur",
"92743", "Larkana",
"928374", "Jhal\ Magsi",
"922426", "Naushero\ Feroze",
"928358", "Dera\ Bugti",
"922383", "Umerkot",
"92466", "Toba\ Tek\ Singh",
"928487", "Khuzdar",
"929385", "Swabi",
"924548", "Khushab",
"925445", "Jhelum",
"928556", "Panjgur",
"92227", "Hyderabad",
"92663", "Muzaffargarh",
"922428", "Naushero\ Feroze",
"92914", "Peshawar\/Charsadda",
"928356", "Dera\ Bugti",
"924533", "Bhakkar",
"92924", "Khyber\/Mohmand\ Agy",
"927269", "Shikarpur",
"92217", "Karachi",
"922976", "Badin",
"929323", "Malakand",
"92442", "Okara",
"92687", "Rahim\ Yar\ Khan",
"926047", "Rajanpur",
"92254", "Dadu",
"927225", "Jacobabad",
"92747", "Larkana",
"928334", "Sibi\/Ziarat",
"92478", "Jhang",
"92493", "Kasur",
"929226", "Kohat",
"92552", "Gujranwala",
"92428", "Lahore",
"928534", "Lasbela",
"92625", "Bahawalpur",
"92532", "Gujrat",
"927228", "Jacobabad",
"92675", "Vehari",
"928294", "Barkhan\/Kohlu",
"922326", "Tharparkar",
"929973", "Mansehra\/Batagram",
"928474", "Kharan",
"929952", "Haripur",
"926089", "Lodhran",
"928239", "Killa\ Saifullah",
"929697", "Lakki\ Marwat",
"925448", "Jhelum",
"924545", "Khushab",
"922425", "Naushero\ Feroze",
"928449", "Kalat",
"928253", "Chagai",
"925433", "Chakwal",
"92615", "Multan",
"92418", "Faisalabad",
"928227", "Zhob",
"929464", "Swat",
"926063", "Layyah",
"92719", "Sukkur",
"924596", "Mianwali",
"929388", "Swabi",
"92522", "Sialkot",
"929665", "D\.I\.\ Khan",
"928299", "Barkhan\/Kohlu",
"928242", "Loralai",
"92635", "Bahawalnagar",
"92572", "Attock",
"928479", "Kharan",
"929326", "Malakand",
"922973", "Badin",
"92655", "Khanewal",
"926084", "Lodhran",
"928234", "Killa\ Saifullah",
"925478", "Hafizabad",
"924575", "Pakpattan",
"928339", "Sibi\/Ziarat",
"92499", "Kasur",
"928539", "Lasbela",
"928353", "Dera\ Bugti",
"92868", "Gwadar",
"924536", "Bhakkar",
"928372", "Jhal\ Magsi",
"92713", "Sukkur",
"922388", "Umerkot",
"929469", "Swat",
"928553", "Panjgur",
"92744", "Larkana",
"929425", "Bajaur\ Agency",
"928432", "Mastung",
"928327", "Bolan",
"929637", "Tank",
"928444", "Kalat",
"928527", "Kech",
"92512", "Islamabad\/Rawalpindi",
"92669", "Muzaffargarh",
"929428", "Bajaur\ Agency",
"924593", "Mianwali",
"92214", "Karachi",
"926066", "Layyah",
"92927", "Karak",
"92257", "Dadu",
"928256", "Chagai",
"922385", "Umerkot",
"92684", "Rahim\ Yar\ Khan",
"925436", "Chakwal",
"92816", "Quetta",
"929976", "Mansehra\/Batagram",
"922323", "Tharparkar",
"92917", "Peshawar\/Charsadda",
"927264", "Shikarpur",
"929668", "D\.I\.\ Khan",
"92224", "Hyderabad",
"929223", "Kohat",
"929967", "Shangla",
"92408", "Sahiwal",
"925475", "Hafizabad",
"924578", "Pakpattan",
"922357", "Sanghar",
"928472", "Kharan",
"928292", "Barkhan\/Kohlu",
"928249", "Loralai",
"929954", "Haripur",
"929978", "Mansehra\/Batagram",
"928532", "Lasbela",
"927223", "Jacobabad",
"92494", "Kasur",
"929666", "D\.I\.\ Khan",
"924576", "Pakpattan",
"92717", "Sukkur",
"928332", "Sibi\/Ziarat",
"929325", "Malakand",
"92749", "Larkana",
"929426", "Bajaur\ Agency",
"92448", "Okara",
"926068", "Layyah",
"929383", "Swabi",
"929462", "Swat",
"928379", "Jhal\ Magsi",
"92645", "Dera\ Ghazi\ Khan",
"928258", "Chagai",
"925438", "Chakwal",
"924535", "Bhakkar",
"925443", "Jhelum",
"928439", "Mastung",
"928255", "Chagai",
"922423", "Naushero\ Feroze",
"925435", "Chakwal",
"924538", "Bhakkar",
"922386", "Umerkot",
"92913", "Peshawar\/Charsadda",
"924543", "Khushab",
"92219", "Karachi",
"92664", "Muzaffargarh",
"92472", "Jhang",
"926065", "Layyah",
"92422", "Lahore",
"92558", "Gujranwala",
"92689", "Rahim\ Yar\ Khan",
"92538", "Gujrat",
"928287", "Musakhel",
"92412", "Faisalabad",
"92253", "Dadu",
"929328", "Malakand",
"925476", "Hafizabad",
"92998", "Kohistan",
"92923", "Nowshera",
"92229", "Hyderabad",
"925467", "Mandi\ Bahauddin",
"929975", "Mansehra\/Batagram",
"92673", "Vehari",
"926069", "Layyah",
"92623", "Bahawalpur",
"928554", "Panjgur",
"922382", "Umerkot",
"928378", "Jhal\ Magsi",
"92495", "Kasur",
"928354", "Dera\ Bugti",
"928443", "Kalat",
"928259", "Chagai",
"92639", "Bahawalnagar",
"925439", "Chakwal",
"92476", "Jhang",
"92659", "Khanewal",
"92426", "Lahore",
"928438", "Mastung",
"925472", "Hafizabad",
"92416", "Faisalabad",
"928233", "Killa\ Saifullah",
"926083", "Lodhran",
"922974", "Badin",
"928248", "Loralai",
"929979", "Mansehra\/Batagram",
"92644", "Dera\ Ghazi\ Khan",
"925427", "Narowal",
"92613", "Multan",
"928296", "Barkhan\/Kohlu",
"922324", "Tharparkar",
"928476", "Kharan",
"922447", "Nawabshah",
"929329", "Malakand",
"929224", "Kohat",
"928336", "Sibi\/Ziarat",
"924572", "Pakpattan",
"92665", "Muzaffargarh",
"929662", "D\.I\.\ Khan",
"92468", "Toba\ Tek\ Singh",
"928536", "Lasbela",
"928245", "Loralai",
"927263", "Shikarpur",
"924539", "Bhakkar",
"929466", "Swat",
"929422", "Bajaur\ Agency",
"928435", "Mastung",
"924594", "Mianwali",
"922987", "Thatta",
"928375", "Jhal\ Magsi",
"92617", "Multan",
"922389", "Umerkot",
"929468", "Swat",
"926062", "Layyah",
"929384", "Swabi",
"92568", "Sheikhupura",
"925444", "Jhelum",
"92654", "Khanewal",
"92812", "Quetta",
"925432", "Chakwal",
"928252", "Chagai",
"92634", "Bahawalnagar",
"929953", "Haripur",
"929972", "Mansehra\/Batagram",
"928298", "Barkhan\/Kohlu",
"928478", "Kharan",
"925479", "Hafizabad",
"929927", "Abottabad",
"928338", "Sibi\/Ziarat",
"92745", "Larkana",
"92677", "Vehari",
"928538", "Lasbela",
"92627", "Bahawalpur",
"92649", "Dera\ Ghazi\ Khan",
"927224", "Jacobabad",
"928335", "Sibi\/Ziarat",
"92488", "Sargodha",
"929322", "Malakand",
"929437", "Chitral",
"928535", "Lasbela",
"92526", "Sialkot",
"928246", "Loralai",
"92576", "Attock",
"92685", "Rahim\ Yar\ Khan",
"929377", "Mardan",
"928475", "Kharan",
"928295", "Barkhan\/Kohlu",
"929669", "D\.I\.\ Khan",
"924579", "Pakpattan",
"92215", "Karachi",
"924544", "Khushab",
"92225", "Hyderabad",
"929429", "Bajaur\ Agency",
"928376", "Jhal\ Magsi",
"924532", "Bhakkar",
"922424", "Naushero\ Feroze",
"92516", "Islamabad\/Rawalpindi",
"928567", "Awaran",
"929465", "Swat",
"928436", "Mastung",};

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