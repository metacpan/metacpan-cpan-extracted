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
package Number::Phone::StubCountry::TH;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20230307181422;

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
          671[0-8]\\d{5}|
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
$areanames{th} = {"6618", "กรุงเทพ\/นนทบุรี\/ปทุมธานี\/สมุทรปราการ",
"6676", "พังงา\/ภูเก็ต",
"6632", "เพชรบุรี\/ประจวบคีรีขันธ์\/ราชบุรี",
"6644", "บุรีรัมย์\/ชัยภูมิ\/นครราชสีมา\/สุรินทร์",
"6656", "ชัยนาท\/นครสวรรค์\/เพชรบูรณ์\/พิจิตร\/อุทัยธานี",
"6619", "กรุงเทพ\/นนทบุรี\/ปทุมธานี\/สมุทรปราการ",
"6645", "อำนาจเจริญ\/ศรีสะเกษ\/อุบลราชธานี\/ยโสธร",
"662", "กรุงเทพ\/นนทบุรี\/ปทุมธานี\/สมุทรปราการ",
"6633", "ฉะเชิงเทรา\/ชลบุรี\/ระยอง",
"6616", "กรุงเทพ\/นนทบุรี\/ปทุมธานี\/สมุทรปราการ",
"6674", "พัทลุง\/สตูล\/สงขลา",
"6654", "ลำปาง\/น่าน\/พะเยา\/แพร่",
"6675", "กระบี่\/นครศรีธรรมราช\/ตรัง",
"6655", "กำแพงเพชร\/พิษณุโลก\/สุโขทัย\/ตาก\/อุตรดิตถ์",
"6637", "นครนายก\/ปราจีนบุรี\/สระแก้ว",
"6643", "กาฬสินธุ์\/ขอนแก่น\/มหาสารคาม\/ร้อยเอ็ด",
"6652", "เชียงใหม่\/เชียงราย\/ลำพูน\/แม่ฮ่องสอน",
"6610", "กรุงเทพ\/นนทบุรี\/ปทุมธานี\/สมุทรปราการ",
"6636", "ลพบุรี\/สระบุรี\/สิงห์บุรี",
"6653", "เชียงใหม่\/เชียงราย\/ลำพูน\/แม่ฮ่องสอน",
"6673", "นราธิวาส\/ปัตตานี\/ยะลา",
"6638", "ฉะเชิงเทรา\/ชลบุรี\/ระยอง",
"6642", "เลย\/มุกดาหาร\/นครพนม\/หนองคาย\/สกลนคร\/อุดรธานี",
"6634", "กาญจนบุรี\/นครปฐม\/สมุทรสาคร\/สมุทรสงคราม",
"6677", "ชุมพร\/ระนอง\/สุราษฎร์ธานี",
"6635", "อ่างทอง\/พระนครศรีอยุธยา\/สุพรรณบุรี",
"6639", "จันทบุรี\/ตราด",};
$areanames{en} = {"6634", "Kanchanaburi\/Nakhon\ Pathom\/Samut\ Sakhon\/Samut\ Songkhram",
"6638", "Chachoengsao\/Chon\ Buri\/Rayong",
"6642", "Loei\/Mukdahan\/Nakhon\ Phanom\/Nong\ Khai\/Sakon\ Nakhon\/Udon\ Thani",
"6673", "Narathiwat\/Pattani\/Yala",
"6653", "Chiang\ Mai\/Chiang\ Rai\/Lamphun\/Mae\ Hong\ Son",
"6639", "Chanthaburi\/Trat",
"6635", "Ang\ Thong\/Phra\ Nakhon\ Si\ Ayutthaya\/Suphan\ Buri",
"6677", "Chumphon\/Ranong\/Surat\ Thani",
"6636", "Lop\ Buri\/Saraburi\/Sing\ Buri",
"6652", "Chiang\ Mai\/Chiang\ Rai\/Lamphun\/Mae\ Hong\ Son",
"6610", "Bangkok\/Nonthaburi\/Pathum\ Thani\/Samut\ Prakan",
"6643", "Kalasin\/Khon\ Kaen\/Maha\ Sarakham\/Roi\ Et",
"6654", "Lampang\/Nan\/Phayao\/Phrae",
"6674", "Phatthalung\/Satun\/Songkhla",
"6616", "Bangkok\/Nonthaburi\/Pathum\ Thani\/Samut\ Prakan",
"6633", "Chachoengsao\/Chon\ Buri\/Rayong",
"6655", "Kamphaeng\ Phet\/Phitsanulok\/Sukhothai\/Tak\/Uttaradit",
"6637", "Nakhon\ Nayok\/Prachin\ Buri\/Sa\ Kaeo",
"6675", "Krabi\/Nakhon\ Si\ Thammarat\/Trang",
"6644", "Buri\ Ram\/Chaiyaphum\/Nakhon\ Ratchasima\/Surin",
"6656", "Chai\ Nat\/Nakhon\ Sawan\/Phetchabun\/Phichit\/Uthai\ Thani",
"6632", "Phetchaburi\/Prachuap\ Khiri\ Khan\/Ratchaburi",
"6676", "Phang\ Nga\/Phuket",
"6618", "Bangkok\/Nonthaburi\/Pathum\ Thani\/Samut\ Prakan",
"662", "Bangkok\/Nonthaburi\/Pathum\ Thani\/Samut\ Prakan",
"6619", "Bangkok\/Nonthaburi\/Pathum\ Thani\/Samut\ Prakan",
"6645", "Amnat\ Charoen\/Si\ Sa\ Ket\/Ubon\ Ratchathani\/Yasothon",};

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+66|\D)//g;
      my $self = bless({ country_code => '66', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ country_code => '66', number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;