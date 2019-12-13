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
package Number::Phone::StubCountry::TH;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20191211212303;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '2',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d)(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            14|
            [3-9]
          ',
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
            2\\d|
            3[2-9]|
            4[2-5]|
            5[2-6]|
            7[3-7]
          )\\d{6}
        ',
                'geographic' => '
          (?:
            2\\d|
            3[2-9]|
            4[2-5]|
            5[2-6]|
            7[3-7]
          )\\d{6}
        ',
                'mobile' => '
          (?:
            14|
            6[1-6]|
            [89]\\d
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(1900\\d{6})',
                'toll_free' => '1800\\d{6}',
                'voip' => '6[08]\\d{7}'
              };
my %areanames = ();
$areanames{en}->{662} = "Bangkok\/Nonthaburi\/Pathum\ Thani\/Samut\ Prakan";
$areanames{en}->{6632} = "Phetchaburi\/Prachuap\ Khiri\ Khan\/Ratchaburi";
$areanames{en}->{6633} = "Chachoengsao\/Chon\ Buri\/Rayong";
$areanames{en}->{6634} = "Kanchanaburi\/Nakhon\ Pathom\/Samut\ Sakhon\/Samut\ Songkhram";
$areanames{en}->{6635} = "Ang\ Thong\/Phra\ Nakhon\ Si\ Ayutthaya\/Suphan\ Buri";
$areanames{en}->{6636} = "Lop\ Buri\/Saraburi\/Sing\ Buri";
$areanames{en}->{6637} = "Nakhon\ Nayok\/Prachin\ Buri\/Sa\ Kaeo";
$areanames{en}->{6638} = "Chachoengsao\/Chon\ Buri\/Rayong";
$areanames{en}->{6639} = "Chanthaburi\/Trat";
$areanames{en}->{6642} = "Loei\/Mukdahan\/Nakhon\ Phanom\/Nong\ Khai\/Sakon\ Nakhon\/Udon\ Thani";
$areanames{en}->{6643} = "Kalasin\/Khon\ Kaen\/Maha\ Sarakham\/Roi\ Et";
$areanames{en}->{6644} = "Buri\ Ram\/Chaiyaphum\/Nakhon\ Ratchasima\/Surin";
$areanames{en}->{6645} = "Amnat\ Charoen\/Si\ Sa\ Ket\/Ubon\ Ratchathani\/Yasothon";
$areanames{en}->{6652} = "Chiang\ Mai\/Chiang\ Rai\/Lamphun\/Mae\ Hong\ Son";
$areanames{en}->{6653} = "Chiang\ Mai\/Chiang\ Rai\/Lamphun\/Mae\ Hong\ Son";
$areanames{en}->{6654} = "Lampang\/Nan\/Phayao\/Phrae";
$areanames{en}->{6655} = "Kamphaeng\ Phet\/Phitsanulok\/Sukhothai\/Tak\/Uttaradit";
$areanames{en}->{6656} = "Chai\ Nat\/Nakhon\ Sawan\/Phetchabun\/Phichit\/Uthai\ Thani";
$areanames{en}->{6673} = "Narathiwat\/Pattani\/Yala";
$areanames{en}->{6674} = "Phatthalung\/Satun\/Songkhla";
$areanames{en}->{6675} = "Krabi\/Nakhon\ Si\ Thammarat\/Trang";
$areanames{en}->{6676} = "Phang\ Nga\/Phuket";
$areanames{en}->{6677} = "Chumphon\/Ranong\/Surat\ Thani";
$areanames{th}->{662} = "กรุงเทพ\/นนทบุรี\/ปทุมธานี\/สมุทรปราการ";
$areanames{th}->{6632} = "เพชรบุรี\/ประจวบคีรีขันธ์\/ราชบุรี";
$areanames{th}->{6633} = "ฉะเชิงเทรา\/ชลบุรี\/ระยอง";
$areanames{th}->{6634} = "กาญจนบุรี\/นครปฐม\/สมุทรสาคร\/สมุทรสงคราม";
$areanames{th}->{6635} = "อ่างทอง\/พระนครศรีอยุธยา\/สุพรรณบุรี";
$areanames{th}->{6636} = "ลพบุรี\/สระบุรี\/สิงห์บุรี";
$areanames{th}->{6637} = "นครนายก\/ปราจีนบุรี\/สระแก้ว";
$areanames{th}->{6638} = "ฉะเชิงเทรา\/ชลบุรี\/ระยอง";
$areanames{th}->{6639} = "จันทบุรี\/ตราด";
$areanames{th}->{6642} = "เลย\/มุกดาหาร\/นครพนม\/หนองคาย\/สกลนคร\/อุดรธานี";
$areanames{th}->{6643} = "กาฬสินธุ์\/ขอนแก่น\/มหาสารคาม\/ร้อยเอ็ด";
$areanames{th}->{6644} = "บุรีรัมย์\/ชัยภูมิ\/นครราชสีมา\/สุรินทร์";
$areanames{th}->{6645} = "อำนาจเจริญ\/ศรีสะเกษ\/อุบลราชธานี\/ยโสธร";
$areanames{th}->{6652} = "เชียงใหม่\/เชียงราย\/ลำพูน\/แม่ฮ่องสอน";
$areanames{th}->{6653} = "เชียงใหม่\/เชียงราย\/ลำพูน\/แม่ฮ่องสอน";
$areanames{th}->{6654} = "ลำปาง\/น่าน\/พะเยา\/แพร่";
$areanames{th}->{6655} = "กำแพงเพชร\/พิษณุโลก\/สุโขทัย\/ตาก\/อุตรดิตถ์";
$areanames{th}->{6656} = "ชัยนาท\/นครสวรรค์\/เพชรบูรณ์\/พิจิตร\/อุทัยธานี";
$areanames{th}->{6673} = "นราธิวาส\/ปัตตานี\/ยะลา";
$areanames{th}->{6674} = "พัทลุง\/สตูล\/สงขลา";
$areanames{th}->{6675} = "กระบี่\/นครศรีธรรมราช\/ตรัง";
$areanames{th}->{6676} = "พังงา\/ภูเก็ต";
$areanames{th}->{6677} = "ชุมพร\/ระนอง\/สุราษฎร์ธานี";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+66|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;