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
our $VERSION = 1.20210309172133;

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
            5(?:
              2[238]|
              59
            )|
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
            0[13]|
            28
          )\\d{4}
        ',
                'voip' => '672\\d{6}'
              };
my %areanames = ();
$areanames{en} = {"84238", "Nghe\ An\ province",
"84259", "Ninh\ Thuan\ province",
"84203", "Quang\ Ninh\ province",
"84258", "Khanh\ Hoa\ province",
"84239", "Ha\ Tinh\ province",
"84299", "Soc\ Trang\ province",
"84232", "Quang\ Binh\ province",
"84227", "Thai\ Binh\ province",
"84207", "Tuyen\ Quang\ province",
"84214", "Lao\ Cai\ province",
"84292", "Can\ Tho\ City",
"84274", "Binh\ Duong\ province",
"84220", "Hai\ Duong\ province",
"84252", "Binh\ Thuan\ province",
"84216", "Yen\ Bai\ province",
"84237", "Thanh\ Hoa\ province",
"84222", "Bac\ Ninh\ province",
"84297", "Kien\ Giang\ province",
"8424", "Hanoi\ City",
"84215", "Dien\ Bien\ province",
"84290", "Ca\ Mau\ province",
"84275", "Ben\ Tre\ province",
"84261", "Dak\ Nong\ province",
"84276", "Tay\ Ninh\ province",
"84257", "Phu\ Yen\ province",
"84211", "Vinh\ Phuc\ province",
"84208", "Thai\ Nguyen\ province",
"84228", "Nam\ Dinh\ province",
"84233", "Quang\ Tri\ province",
"84293", "Hau\ Giang\ province",
"8428", "Ho\ Chi\ Minh\ City",
"84229", "Ninh\ Binh\ province",
"84209", "Bac\ Can\ province",
"84271", "Binh\ Phuoc\ province",
"84218", "Hoa\ Binh\ province",
"84221", "Hung\ Yen\ province",
"84262", "Dak\ Lak\ province",
"84219", "Ha\ Giang\ province",
"84225", "Hai\ Phong\ City",
"84205", "Lang\ Son\ province",
"84269", "Gia\ Lai\ province",
"84234", "Thua\ Thien\-Hue\ province",
"84294", "Tra\ Vinh\ province",
"84212", "Son\ La\ province",
"84226", "Ha\ Nam\ province",
"84206", "Cao\ Bang\ province",
"84254", "Ba\ Ria\ Vung\ Tau\ province",
"84272", "Long\ An\ province",
"84296", "An\ Giang\ province",
"84235", "Quang\ Nam\ province",
"84204", "Bac\ Giang\ province",
"84236", "Da\ Nang",
"84270", "Ving\ Long\ province",
"84255", "Quang\ Ngai\ province",
"84263", "Lam\ Dong\ province",
"84256", "Binh\ Dinh\ province",
"84277", "Dong\ Thap\ province",
"84210", "Phu\ Tho\ province",
"84213", "Lai\ Chau\ province",
"84291", "Bac\ Lieu\ province",
"84260", "Kon\ Tum\ province",
"84273", "Tien\ Giang\ province",
"84251", "Dong\ Nai\ province",};
$areanames{vi} = {"84204", "Bắc\ Giang",
"84235", "Quảng\ Nam",
"84296", "An\ Giang",
"84270", "Vĩnh\ Long",
"84236", "TP\ Đà\ Nẵng",
"84210", "Phú\ Thọ",
"84277", "Đồng\ Tháp",
"84263", "Lâm\ Đồng",
"84255", "Quảng\ Ngãi",
"84256", "Bình\ Định",
"84291", "Bạc\ Liêu",
"84260", "Kon\ Tum",
"84213", "Lai\ Châu",
"84273", "Tiền\ Giang",
"84251", "Đồng\ Nai",
"84218", "Hòa\ Bình",
"84221", "Hưng\ Yên",
"84262", "Đăk\ Lăk",
"84219", "Hà\ Giang",
"84234", "Thừa\ Thiên\-Huế",
"84269", "Gia\ Lai",
"84205", "Lạng\ Sơn",
"84225", "Thành\ phố\ Hải\ Phòng",
"84206", "Cao\ Bằng",
"84294", "Trà\ Vinh",
"84212", "Sơn\ La",
"84226", "Hà\ Nam",
"84272", "Long\ An",
"84254", "Bà\ Rịa\-Vũng\ Tàu",
"84222", "Bắc\ Ninh",
"84216", "Yên\ Bái",
"84237", "Thanh\ Hóa",
"8424", "Thủ\ đô\ Hà\ Nội",
"84215", "Điện\ Biên",
"84297", "Kiên\ Giang",
"84257", "Phú\ Yên",
"84275", "Bến\ Tre",
"84290", "Cà\ Mau",
"84276", "Tây\ Ninh",
"84261", "Đăk\ Nông",
"84233", "Quảng\ Trị",
"84293", "Hậu\ Giang",
"84211", "Vĩnh\ Phúc",
"84228", "Nam\ Định",
"84208", "Thái\ Nguyên",
"84209", "Tỉnh\ Bắc\ Kạn",
"84229", "Ninh\ Bình",
"84271", "Bình\ Phước",
"8428", "Thành\ phố\ Hồ\ Chí\ Minh",
"84203", "Quảng\ Ninh",
"84259", "Ninh\ Thuận",
"84238", "Nghệ\ An",
"84239", "Hà\ Tĩnh",
"84299", "Sóc\ Trăng",
"84258", "Khánh\ Hòa",
"84207", "Tuyên\ Quang",
"84227", "Thái\ Bình",
"84232", "Quảng\ Bình",
"84214", "Lào\ Cai",
"84292", "Thành\ phố\ Cần\ Thơ",
"84252", "Bình\ Thuận",
"84274", "Bình\ Dương",
"84220", "Hải\ Dương",};

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