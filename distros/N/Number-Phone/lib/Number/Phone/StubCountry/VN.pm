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
our $VERSION = 1.20170314173055;

my $formatters = [
                {
                  'leading_digits' => '[17]99',
                  'pattern' => '([17]99)(\\d{4})'
                },
                {
                  'pattern' => '([48])(\\d{4})(\\d{4})',
                  'leading_digits' => '
            4|
            8(?:
              [1-57]|
              [689][0-79]
            )
          '
                },
                {
                  'leading_digits' => '
            2[025-79]|
            3[0136-9]|
            5[2-9]|
            6[0-46-8]|
            7[02-79]
          ',
                  'pattern' => '([235-7]\\d)(\\d{4})(\\d{3})'
                },
                {
                  'leading_digits' => '80',
                  'pattern' => '(80)(\\d{5})'
                },
                {
                  'leading_digits' => '69',
                  'pattern' => '(69\\d)(\\d{4,5})'
                },
                {
                  'leading_digits' => '
            2[1348]|
            3[25]|
            5[01]|
            65|
            7[18]
          ',
                  'pattern' => '([235-7]\\d{2})(\\d{4})(\\d{3})'
                },
                {
                  'pattern' => '([89]\\d)(\\d{3})(\\d{2})(\\d{2})',
                  'leading_digits' => '
            8[689]8|
            9
          '
                },
                {
                  'leading_digits' => '
            1(?:
              [26]|
              8[68]|
              99
            )
          ',
                  'pattern' => '(1[2689]\\d)(\\d{3})(\\d{4})'
                },
                {
                  'pattern' => '(1[89]00)(\\d{4,6})',
                  'leading_digits' => '1[89]0'
                }
              ];

my $validators = {
                'fixed_line' => '
          (?:
            2(?:
              [025-79]|
              1[0-689]|
              3\\d|
              [48][01]
            )|
            3(?:
              [0136-9]|
              [25][01]
            )|
            4\\d|
            5(?:
              [01][01]|
              [2-9]
            )|
            6(?:
              [0-46-8]|
              5[01]
            )|
            7(?:
              [02-79]|
              [18][01]
            )
          )\\d{7}|
          8(?:
            [1-57]\\d|
            [689][0-79]
          )\\d{6}
        ',
                'voip' => '',
                'pager' => '',
                'personal_number' => '',
                'geographic' => '
          (?:
            2(?:
              [025-79]|
              1[0-689]|
              3\\d|
              [48][01]
            )|
            3(?:
              [0136-9]|
              [25][01]
            )|
            4\\d|
            5(?:
              [01][01]|
              [2-9]
            )|
            6(?:
              [0-46-8]|
              5[01]
            )|
            7(?:
              [02-79]|
              [18][01]
            )
          )\\d{7}|
          8(?:
            [1-57]\\d|
            [689][0-79]
          )\\d{6}
        ',
                'toll_free' => '1800\\d{4,6}',
                'mobile' => '
          (?:
            9\\d|
            1(?:
              2\\d|
              6[2-9]|
              8[68]|
              99
            )
          )\\d{7}|
          8[689]8\\d{6}
        ',
                'specialrate' => '(1900\\d{4,6})|(
          [17]99\\d{4}|
          69\\d{5,6}|
          80\\d{5}
        )'
              };
my %areanames = (
  8420 => "Lao\ Cai\ province",
  84210 => "Phu\ Tho\ province",
  84211 => "Vinh\ Phuc\ province",
  84212 => "Son\ La\ province",
  84213 => "Lai\ Chau\ province",
  84214 => "Lao\ Cai\ province",
  84215 => "Dien\ Bien\ province",
  84216 => "Yen\ Bai\ province",
  84218 => "Hoa\ Binh\ province",
  84219 => "Ha\ Giang\ province",
  8422 => "Son\ La\ province",
  84230 => "Dien\ Bien\ province",
  84231 => "Lai\ Chau\ province",
  84232 => "Quang\ Binh\ province",
  84233 => "Quang\ Tri\ province",
  84234 => "Thua\ Thien\-Hue\ province",
  84235 => "Quang\ Nam\ province",
  84236 => "Da\ Nang",
  84237 => "Thanh\ Hoa\ province",
  84238 => "Nghe\ An\ province",
  84239 => "Ha\ Tinh\ province",
  84240 => "Bac\ Giang\ province",
  84241 => "Bac\ Ninh\ province",
  8425 => "Lang\ Son\ province",
  8426 => "Cao\ Bang\ province",
  8427 => "Tuyen\ Quang\ province",
  84280 => "Thai\ Nguyen\ province",
  84281 => "Bac\ Kan\ province",
  8429 => "Yen\ Bai\ province",
  8430 => "Ninh\ Binh\ province",
  8431 => "Hai\ Phong",
  84320 => "Hai\ Duong\ province",
  84321 => "Hung\ Yen\ province",
  8433 => "Quang\ Ninh\ province",
  84350 => "Nam\ Dinh\ province",
  84351 => "Ha\ Nam\ province",
  8436 => "Thai\ Binh\ province",
  8437 => "Thanh\ Hoa\ province",
  8438 => "Nghe\ An\ province",
  8439 => "Ha\ Tinh\ province",
  844 => "Hanoi",
  84500 => "Dak\ Lak\ province",
  84501 => "Dak\ Nong\ province",
  84510 => "Quang\ Nam\ province",
  84511 => "Da\ Nang",
  8452 => "Quang\ Binh\ province",
  8453 => "Quang\ Tri\ province",
  8454 => "Thua\ Thien\-Hue\ province",
  8455 => "Quang\ Ngai\ province",
  8456 => "Binh\ Dinh\ province",
  8457 => "Phu\ Yen\ province",
  8458 => "Khanh\ Hoa\ province",
  8459 => "Gia\ Lai\ province",
  8460 => "Kon\ Tum\ province",
  8461 => "Dong\ Nai\ province",
  8462 => "Binh\ Thuan\ province",
  8463 => "Lam\ Dong\ province",
  8464 => "Ba\ Ria\-Vung\ Tau\ province",
  84650 => "Binh\ Duong\ province",
  84651 => "Binh\ Phuoc\ province",
  8466 => "Tay\ Ninh\ province",
  8467 => "Dong\ Thap\ province",
  8468 => "Ninh\ Thuan\ province",
  8470 => "Vinh\ Long\ province",
  84710 => "Can\ Tho",
  84711 => "Hau\ Giang\ province",
  8472 => "Long\ An\ province",
  8473 => "Tien\ Giang\ province",
  8474 => "Tra\ Vinh\ province",
  8475 => "Ben\ Tre\ province",
  8476 => "An\ Giang\ province",
  8477 => "Kien\ Giang\ province",
  84780 => "Ca\ Mau\ province",
  84781 => "Bac\ Lieu\ province",
  8479 => "Soc\ Trang\ province",
  8482 => "Ho\ Chi\ Minh\ City",
  8483 => "Ho\ Chi\ Minh\ City",
  8484 => "Ho\ Chi\ Minh\ City",
  8485 => "Ho\ Chi\ Minh\ City",
  84862 => "Ho\ Chi\ Minh\ City",
  84863 => "Ho\ Chi\ Minh\ City",
  84866 => "Ho\ Chi\ Minh\ City",
  84871 => "Ho\ Chi\ Minh\ City",
  84873 => "Ho\ Chi\ Minh\ City",
);
    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+84|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
  
      return $self if ($self->is_valid());
      $number =~ s/(^0)//g;
      $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
    return $self->is_valid() ? $self : undef;
}
1;