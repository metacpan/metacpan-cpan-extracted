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
package Number::Phone::StubCountry::TH;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20241212130807;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '2',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[13-9]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{3,4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '1',
                  'pattern' => '(\\d{4})(\\d{3})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            1[0689]|
            2\\d|
            3[2-9]|
            4[2-5]|
            5[2-6]|
            7[3-7]
          )\\d{6}
        ',
                'geographic' => '
          (?:
            1[0689]|
            2\\d|
            3[2-9]|
            4[2-5]|
            5[2-6]|
            7[3-7]
          )\\d{6}
        ',
                'mobile' => '
          67(?:
            1[0-8]|
            2[4-7]
          )\\d{5}|
          (?:
            14|
            6[1-6]|
            [89]\\d
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(1900\\d{6})',
                'toll_free' => '
          (?:
            001800\\d|
            1800
          )\\d{6}
        ',
                'voip' => '6[08]\\d{7}'
              };
my %areanames = ();
$areanames{en} = {"6616", "Bangkok\/Nonthaburi\/Pathum\ Thani\/Samut\ Prakan",
"6633", "Chachoengsao\/Chon\ Buri\/Rayong",
"6638", "Chachoengsao\/Chon\ Buri\/Rayong",
"6642", "Loei\/Mukdahan\/Nakhon\ Phanom\/Nong\ Khai\/Sakon\ Nakhon\/Udon\ Thani",
"662", "Bangkok\/Nonthaburi\/Pathum\ Thani\/Samut\ Prakan",
"6637", "Nakhon\ Nayok\/Prachin\ Buri\/Sa\ Kaeo",
"6674", "Phatthalung\/Satun\/Songkhla",
"6619", "Bangkok\/Nonthaburi\/Pathum\ Thani\/Samut\ Prakan",
"6655", "Kamphaeng\ Phet\/Phitsanulok\/Sukhothai\/Tak\/Uttaradit",
"6676", "Phang\ Nga\/Phuket",
"6656", "Chai\ Nat\/Nakhon\ Sawan\/Phetchabun\/Phichit\/Uthai\ Thani",
"6675", "Krabi\/Nakhon\ Si\ Thammarat\/Trang",
"6654", "Lampang\/Nan\/Phayao\/Phrae",
"6632", "Phetchaburi\/Prachuap\ Khiri\ Khan\/Ratchaburi",
"6643", "Kalasin\/Khon\ Kaen\/Maha\ Sarakham\/Roi\ Et",
"6636", "Lop\ Buri\/Saraburi\/Sing\ Buri",
"6677", "Chumphon\/Ranong\/Surat\ Thani",
"6634", "Kanchanaburi\/Nakhon\ Pathom\/Samut\ Sakhon\/Samut\ Songkhram",
"6652", "Chiang\ Mai\/Chiang\ Rai\/Lamphun\/Mae\ Hong\ Son",
"6618", "Bangkok\/Nonthaburi\/Pathum\ Thani\/Samut\ Prakan",
"6673", "Narathiwat\/Pattani\/Yala",
"6639", "Chanthaburi\/Trat",
"6645", "Amnat\ Charoen\/Si\ Sa\ Ket\/Ubon\ Ratchathani\/Yasothon",
"6653", "Chiang\ Mai\/Chiang\ Rai\/Lamphun\/Mae\ Hong\ Son",
"6644", "Buri\ Ram\/Chaiyaphum\/Nakhon\ Ratchasima\/Surin",
"6610", "Bangkok\/Nonthaburi\/Pathum\ Thani\/Samut\ Prakan",
"6635", "Ang\ Thong\/Phra\ Nakhon\ Si\ Ayutthaya\/Suphan\ Buri",};
$areanames{th} = {"6636", "ลพบุรี\/สระบุรี\/สิงห์บุรี",
"6634", "กาญจนบุรี\/นครปฐม\/สมุทรสาคร\/สมุทรสงคราม",
"6677", "ชุมพร\/ระนอง\/สุราษฎร์ธานี",
"6618", "กรุงเทพ\/นนทบุรี\/ปทุมธานี\/สมุทรปราการ",
"6652", "เชียงใหม่\/เชียงราย\/ลำพูน\/แม่ฮ่องสอน",
"6639", "จันทบุรี\/ตราด",
"6673", "นราธิวาส\/ปัตตานี\/ยะลา",
"6645", "อำนาจเจริญ\/ศรีสะเกษ\/อุบลราชธานี\/ยโสธร",
"6653", "เชียงใหม่\/เชียงราย\/ลำพูน\/แม่ฮ่องสอน",
"6644", "บุรีรัมย์\/ชัยภูมิ\/นครราชสีมา\/สุรินทร์",
"6610", "กรุงเทพ\/นนทบุรี\/ปทุมธานี\/สมุทรปราการ",
"6635", "อ่างทอง\/พระนครศรีอยุธยา\/สุพรรณบุรี",
"6616", "กรุงเทพ\/นนทบุรี\/ปทุมธานี\/สมุทรปราการ",
"6638", "ฉะเชิงเทรา\/ชลบุรี\/ระยอง",
"6642", "เลย\/มุกดาหาร\/นครพนม\/หนองคาย\/สกลนคร\/อุดรธานี",
"6633", "ฉะเชิงเทรา\/ชลบุรี\/ระยอง",
"662", "กรุงเทพ\/นนทบุรี\/ปทุมธานี\/สมุทรปราการ",
"6674", "พัทลุง\/สตูล\/สงขลา",
"6637", "นครนายก\/ปราจีนบุรี\/สระแก้ว",
"6619", "กรุงเทพ\/นนทบุรี\/ปทุมธานี\/สมุทรปราการ",
"6655", "กำแพงเพชร\/พิษณุโลก\/สุโขทัย\/ตาก\/อุตรดิตถ์",
"6676", "พังงา\/ภูเก็ต",
"6656", "ชัยนาท\/นครสวรรค์\/เพชรบูรณ์\/พิจิตร\/อุทัยธานี",
"6675", "กระบี่\/นครศรีธรรมราช\/ตรัง",
"6654", "ลำปาง\/น่าน\/พะเยา\/แพร่",
"6643", "กาฬสินธุ์\/ขอนแก่น\/มหาสารคาม\/ร้อยเอ็ด",
"6632", "เพชรบุรี\/ประจวบคีรีขันธ์\/ราชบุรี",};
my $timezones = {
               '' => [
                       'Asia/Bangkok'
                     ]
             };

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+66|\D)//g;
      my $self = bless({ country_code => '66', number => $number, formatters => $formatters, validators => $validators, timezones => $timezones, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '66', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;