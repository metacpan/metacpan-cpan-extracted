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
our $VERSION = 1.20180410221548;

my $formatters = [
                {
                  'leading_digits' => '[17]99',
                  'national_rule' => '0$1',
                  'format' => '$1 $2',
                  'pattern' => '([17]99)(\\d{4})'
                },
                {
                  'leading_digits' => '2[48]',
                  'national_rule' => '0$1',
                  'format' => '$1 $2 $3',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4})'
                },
                {
                  'pattern' => '(80)(\\d{5})',
                  'format' => '$1 $2',
                  'leading_digits' => '80',
                  'national_rule' => '0$1'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '69',
                  'national_rule' => '0$1',
                  'pattern' => '(69\\d)(\\d{4,5})'
                },
                {
                  'pattern' => '(\\d{3})(\\d{4})(\\d{3})',
                  'national_rule' => '0$1',
                  'leading_digits' => '2[0-35-79]',
                  'format' => '$1 $2 $3'
                },
                {
                  'pattern' => '([89]\\d)(\\d{3})(\\d{2})(\\d{2})',
                  'format' => '$1 $2 $3 $4',
                  'national_rule' => '0$1',
                  'leading_digits' => '
            8(?:
              8|
              9[89]
            )|
            9
          '
                },
                {
                  'pattern' => '(1[2689]\\d)(\\d{3})(\\d{4})',
                  'national_rule' => '0$1',
                  'leading_digits' => '
            1(?:
              [26]|
              8[68]|
              99
            )
          ',
                  'format' => '$1 $2 $3'
                },
                {
                  'pattern' => '(86[89])(\\d{3})(\\d{3})',
                  'format' => '$1 $2 $3',
                  'leading_digits' => '86[89]',
                  'national_rule' => '0$1'
                },
                {
                  'leading_digits' => '1[89]00',
                  'national_rule' => '$1',
                  'format' => '$1 $2',
                  'pattern' => '(1[89]00)(\\d{4,6})'
                }
              ];

my $validators = {
                'personal_number' => '',
                'pager' => '',
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
          8(?:
            6[89]|
            8\\d|
            9[89]
          )\\d{6}
        ',
                'specialrate' => '(1900\\d{4,6})|(
          [17]99\\d{4}|
          69\\d{5,6}|
          80\\d{5}
        )',
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
            8[2-7]|
            9[0-4679]
          )\\d{7}
        ',
                'voip' => '',
                'toll_free' => '1800\\d{4,6}',
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
            8[2-7]|
            9[0-4679]
          )\\d{7}
        '
              };
my %areanames = (
  84203 => "Quang\ Ninh\ province",
  84204 => "Bac\ Giang\ province",
  84205 => "Lang\ Son\ province",
  84206 => "Cao\ Bang\ province",
  84207 => "Tuyen\ Quang\ province",
  84208 => "Thai\ Nguyen\ province",
  84209 => "Bac\ Can\ province",
  84210 => "Phu\ Tho\ province",
  84211 => "Vinh\ Phuc\ province",
  84212 => "Son\ La\ province",
  84213 => "Lai\ Chau\ province",
  84214 => "Lao\ Cai\ province",
  84215 => "Dien\ Bien\ province",
  84216 => "Yen\ Bai\ province",
  84218 => "Hoa\ Binh\ province",
  84219 => "Ha\ Giang\ province",
  84220 => "Hai\ Duong\ province",
  84221 => "Hung\ Yen\ province",
  84222 => "Bac\ Ninh\ province",
  84225 => "Hai\ Phong\ City",
  84226 => "Ha\ Nam\ province",
  84227 => "Thai\ Binh\ province",
  84228 => "Nam\ Dinh\ province",
  84229 => "Ninh\ Binh\ province",
  84232 => "Quang\ Binh\ province",
  84233 => "Quang\ Tri\ province",
  84234 => "Thua\ Thien\-Hue\ province",
  84235 => "Quang\ Nam\ province",
  84236 => "Da\ Nang",
  84237 => "Thanh\ Hoa\ province",
  84238 => "Nghe\ An\ province",
  84239 => "Ha\ Tinh\ province",
  84242 => "Hanoi\ City",
  84243 => "Hanoi\ City",
  84244 => "Hanoi\ City",
  84245 => "Hanoi\ City",
  84246 => "Hanoi\ City",
  84247 => "Hanoi\ City",
  84248 => "Hanoi\ City",
  84251 => "Dong\ Nai\ province",
  84252 => "Binh\ Thuan\ province",
  84254 => "Ba\ Ria\ Vung\ Tau\ province",
  84255 => "Quang\ Ngai\ province",
  84256 => "Binh\ Dinh\ province",
  84257 => "Phu\ Yen\ province",
  84258 => "Khanh\ Hoa\ province",
  84259 => "Ninh\ Thuan\ province",
  84260 => "Kon\ Tum\ province",
  84261 => "Dak\ Nong\ province",
  84262 => "Dak\ Lak\ province",
  84263 => "Lam\ Dong\ province",
  84269 => "Gia\ Lai\ province",
  84270 => "Ving\ Long\ province",
  84271 => "Binh\ Phuoc\ province",
  84272 => "Long\ An\ province",
  84273 => "Tien\ Giang\ province",
  84274 => "Binh\ Duong\ province",
  84275 => "Ben\ Tre\ province",
  84276 => "Tay\ Ninh\ province",
  84277 => "Dong\ Thap\ province",
  84282 => "Ho\ Chi\ Minh\ City",
  84283 => "Ho\ Chi\ Minh\ City",
  84284 => "Ho\ Chi\ Minh\ City",
  84285 => "Ho\ Chi\ Minh\ City",
  84286 => "Ho\ Chi\ Minh\ City",
  84287 => "Ho\ Chi\ Minh\ City",
  84290 => "Ca\ Mau\ province",
  84291 => "Bac\ Lieu\ province",
  84292 => "Can\ Tho\ City",
  84293 => "Hau\ Giang\ province",
  84294 => "Tra\ Vinh\ province",
  84296 => "An\ Giang\ province",
  84297 => "Kien\ Giang\ province",
  84299 => "Soc\ Trang\ province",
);
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