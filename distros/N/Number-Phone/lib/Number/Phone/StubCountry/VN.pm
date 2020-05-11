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
package Number::Phone::StubCountry::VN;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200511123716;

my $formatters = [
                {
                  'format' => '$1 $2',
                  'intl_format' => 'NA',
                  'leading_digits' => '[17]99',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '80',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{5})'
                },
                {
                  'format' => '$1 $2',
                  'intl_format' => 'NA',
                  'leading_digits' => '69',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{4,5})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '1',
                  'pattern' => '(\\d{4})(\\d{4,6})'
                },
                {
                  'format' => '$1 $2 $3 $4',
                  'leading_digits' => '[69]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{3})(\\d{2})(\\d{2})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[3578]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{3})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '2[48]',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '2',
                  'national_rule' => '0$1',
                  'pattern' => '(\\d{3})(\\d{4})(\\d{3})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2(?:
            0[3-9]|
            1[0-689]|
            2[0-25-9]|
            3[2-9]|
            4[2-8]|
            5[124-9]|
            6[0-39]|
            7[0-7]|
            8[2-79]|
            9[0-4679]
          )\\d{7}
        ',
                'geographic' => '
          2(?:
            0[3-9]|
            1[0-689]|
            2[0-25-9]|
            3[2-9]|
            4[2-8]|
            5[124-9]|
            6[0-39]|
            7[0-7]|
            8[2-79]|
            9[0-4679]
          )\\d{7}
        ',
                'mobile' => '
          (?:
            52[238]|
            89[689]|
            99[013-9]
          )\\d{6}|
          (?:
            3\\d|
            5[689]|
            7[06-9]|
            8[1-8]|
            9[0-8]
          )\\d{7}
        ',
                'pager' => '',
                'personal_number' => '',
                'specialrate' => '(1900\\d{4,6})|(
          (?:
            [17]99|
            80\\d
          )\\d{4}|
          69\\d{5,6}
        )',
                'toll_free' => '
          1800\\d{4,6}|
          12(?:
            03|
            28
          )\\d{4}
        ',
                'voip' => '672\\d{6}'
              };
my %areanames = ();
$areanames{vi}->{84203} = "Quảng\ Ninh";
$areanames{vi}->{84204} = "Bắc\ Giang";
$areanames{vi}->{84205} = "Lạng\ Sơn";
$areanames{vi}->{84206} = "Cao\ Bằng";
$areanames{vi}->{84207} = "Tuyên\ Quang";
$areanames{vi}->{84208} = "Thái\ Nguyên";
$areanames{vi}->{84209} = "Tỉnh\ Bắc\ Kạn";
$areanames{vi}->{84210} = "Phú\ Thọ";
$areanames{vi}->{84211} = "Vĩnh\ Phúc";
$areanames{vi}->{84212} = "Sơn\ La";
$areanames{vi}->{84213} = "Lai\ Châu";
$areanames{vi}->{84214} = "Lào\ Cai";
$areanames{vi}->{84215} = "Điện\ Biên";
$areanames{vi}->{84216} = "Yên\ Bái";
$areanames{vi}->{84218} = "Hòa\ Bình";
$areanames{vi}->{84219} = "Hà\ Giang";
$areanames{vi}->{84220} = "Hải\ Dương";
$areanames{vi}->{84221} = "Hưng\ Yên";
$areanames{vi}->{84222} = "Bắc\ Ninh";
$areanames{vi}->{84225} = "Thành\ phố\ Hải\ Phòng";
$areanames{vi}->{84226} = "Hà\ Nam";
$areanames{vi}->{84227} = "Thái\ Bình";
$areanames{vi}->{84228} = "Nam\ Định";
$areanames{vi}->{84229} = "Ninh\ Bình";
$areanames{vi}->{84232} = "Quảng\ Bình";
$areanames{vi}->{84233} = "Quảng\ Trị";
$areanames{vi}->{84234} = "Thừa\ Thiên\-Huế";
$areanames{vi}->{84235} = "Quảng\ Nam";
$areanames{vi}->{84236} = "TP\ Đà\ Nẵng";
$areanames{vi}->{84237} = "Thanh\ Hóa";
$areanames{vi}->{84238} = "Nghệ\ An";
$areanames{vi}->{84239} = "Hà\ Tĩnh";
$areanames{vi}->{8424} = "Thủ\ đô\ Hà\ Nội";
$areanames{vi}->{84251} = "Đồng\ Nai";
$areanames{vi}->{84252} = "Bình\ Thuận";
$areanames{vi}->{84254} = "Bà\ Rịa\-Vũng\ Tàu";
$areanames{vi}->{84255} = "Quảng\ Ngãi";
$areanames{vi}->{84256} = "Bình\ Định";
$areanames{vi}->{84257} = "Phú\ Yên";
$areanames{vi}->{84258} = "Khánh\ Hòa";
$areanames{vi}->{84259} = "Ninh\ Thuận";
$areanames{vi}->{84260} = "Kon\ Tum";
$areanames{vi}->{84261} = "Đăk\ Nông";
$areanames{vi}->{84262} = "Đăk\ Lăk";
$areanames{vi}->{84263} = "Lâm\ Đồng";
$areanames{vi}->{84269} = "Gia\ Lai";
$areanames{vi}->{84270} = "Vĩnh\ Long";
$areanames{vi}->{84271} = "Bình\ Phước";
$areanames{vi}->{84272} = "Long\ An";
$areanames{vi}->{84273} = "Tiền\ Giang";
$areanames{vi}->{84274} = "Bình\ Dương";
$areanames{vi}->{84275} = "Bến\ Tre";
$areanames{vi}->{84276} = "Tây\ Ninh";
$areanames{vi}->{84277} = "Đồng\ Tháp";
$areanames{vi}->{8428} = "Thành\ phố\ Hồ\ Chí\ Minh";
$areanames{vi}->{84290} = "Cà\ Mau";
$areanames{vi}->{84291} = "Bạc\ Liêu";
$areanames{vi}->{84292} = "Thành\ phố\ Cần\ Thơ";
$areanames{vi}->{84293} = "Hậu\ Giang";
$areanames{vi}->{84294} = "Trà\ Vinh";
$areanames{vi}->{84296} = "An\ Giang";
$areanames{vi}->{84297} = "Kiên\ Giang";
$areanames{vi}->{84299} = "Sóc\ Trăng";
$areanames{en}->{84203} = "Quang\ Ninh\ province";
$areanames{en}->{84204} = "Bac\ Giang\ province";
$areanames{en}->{84205} = "Lang\ Son\ province";
$areanames{en}->{84206} = "Cao\ Bang\ province";
$areanames{en}->{84207} = "Tuyen\ Quang\ province";
$areanames{en}->{84208} = "Thai\ Nguyen\ province";
$areanames{en}->{84209} = "Bac\ Can\ province";
$areanames{en}->{84210} = "Phu\ Tho\ province";
$areanames{en}->{84211} = "Vinh\ Phuc\ province";
$areanames{en}->{84212} = "Son\ La\ province";
$areanames{en}->{84213} = "Lai\ Chau\ province";
$areanames{en}->{84214} = "Lao\ Cai\ province";
$areanames{en}->{84215} = "Dien\ Bien\ province";
$areanames{en}->{84216} = "Yen\ Bai\ province";
$areanames{en}->{84218} = "Hoa\ Binh\ province";
$areanames{en}->{84219} = "Ha\ Giang\ province";
$areanames{en}->{84220} = "Hai\ Duong\ province";
$areanames{en}->{84221} = "Hung\ Yen\ province";
$areanames{en}->{84222} = "Bac\ Ninh\ province";
$areanames{en}->{84225} = "Hai\ Phong\ City";
$areanames{en}->{84226} = "Ha\ Nam\ province";
$areanames{en}->{84227} = "Thai\ Binh\ province";
$areanames{en}->{84228} = "Nam\ Dinh\ province";
$areanames{en}->{84229} = "Ninh\ Binh\ province";
$areanames{en}->{84232} = "Quang\ Binh\ province";
$areanames{en}->{84233} = "Quang\ Tri\ province";
$areanames{en}->{84234} = "Thua\ Thien\-Hue\ province";
$areanames{en}->{84235} = "Quang\ Nam\ province";
$areanames{en}->{84236} = "Da\ Nang";
$areanames{en}->{84237} = "Thanh\ Hoa\ province";
$areanames{en}->{84238} = "Nghe\ An\ province";
$areanames{en}->{84239} = "Ha\ Tinh\ province";
$areanames{en}->{8424} = "Hanoi\ City";
$areanames{en}->{84251} = "Dong\ Nai\ province";
$areanames{en}->{84252} = "Binh\ Thuan\ province";
$areanames{en}->{84254} = "Ba\ Ria\ Vung\ Tau\ province";
$areanames{en}->{84255} = "Quang\ Ngai\ province";
$areanames{en}->{84256} = "Binh\ Dinh\ province";
$areanames{en}->{84257} = "Phu\ Yen\ province";
$areanames{en}->{84258} = "Khanh\ Hoa\ province";
$areanames{en}->{84259} = "Ninh\ Thuan\ province";
$areanames{en}->{84260} = "Kon\ Tum\ province";
$areanames{en}->{84261} = "Dak\ Nong\ province";
$areanames{en}->{84262} = "Dak\ Lak\ province";
$areanames{en}->{84263} = "Lam\ Dong\ province";
$areanames{en}->{84269} = "Gia\ Lai\ province";
$areanames{en}->{84270} = "Ving\ Long\ province";
$areanames{en}->{84271} = "Binh\ Phuoc\ province";
$areanames{en}->{84272} = "Long\ An\ province";
$areanames{en}->{84273} = "Tien\ Giang\ province";
$areanames{en}->{84274} = "Binh\ Duong\ province";
$areanames{en}->{84275} = "Ben\ Tre\ province";
$areanames{en}->{84276} = "Tay\ Ninh\ province";
$areanames{en}->{84277} = "Dong\ Thap\ province";
$areanames{en}->{8428} = "Ho\ Chi\ Minh\ City";
$areanames{en}->{84290} = "Ca\ Mau\ province";
$areanames{en}->{84291} = "Bac\ Lieu\ province";
$areanames{en}->{84292} = "Can\ Tho\ City";
$areanames{en}->{84293} = "Hau\ Giang\ province";
$areanames{en}->{84294} = "Tra\ Vinh\ province";
$areanames{en}->{84296} = "An\ Giang\ province";
$areanames{en}->{84297} = "Kien\ Giang\ province";
$areanames{en}->{84299} = "Soc\ Trang\ province";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+84|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self if ($self->is_valid());
      $number =~ s/^(?:0)//;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
      return $self->is_valid() ? $self : undef;
    }
1;