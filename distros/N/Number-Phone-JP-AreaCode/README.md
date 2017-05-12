[![Build Status](https://travis-ci.org/moznion/Number-Phone-JP-AreaCode.png?branch=master)](https://travis-ci.org/moznion/Number-Phone-JP-AreaCode)
# NAME

Number::Phone::JP::AreaCode - Utilities for Japanese area code of phone

# SYNOPSIS

    use Number::Phone::JP::AreaCode qw/
        area_code_by_address
        area_code_by_address_prefix_match
        area_code_by_address_fuzzy
        address_by_area_code
    /;

    address_by_area_code('1456'); # => { addresses => [ '北海道新冠郡新冠町里平', '北海道沙流郡日高町', ], local_code_digits => '1' }
    address_by_area_code('01456'); # => same as above
    area_code_by_address('大阪府東大阪市岩田町'); # => { area_code => '72', local_code_digits => '3' }
    area_code_by_address_prefix_match('大阪府東大阪市岩田町一丁目'); # => { area_code => '72', local_code_digits => '3' }
    area_code_by_address_fuzzy('大阪府東大阪市岩田'); # => {
                                                      #        '大阪府東大阪市岩田町' => {
                                                      #            area_code         => '72',
                                                      #            local_code_digits => '3',
                                                      #        },
                                                      #        '大阪府東大阪市岩田町三丁目' => {
                                                      #            area_code         => '6',
                                                      #            local_code_digits => '4',
                                                      #        },
                                                      #        '大阪府大阪市' => {
                                                      #            area_code         => '6',
                                                      #            local_code_digits => '4',
                                                      #        },
                                                      #        '大阪府東大阪市' => {
                                                      #            area_code         => '6',
                                                      #            local_code_digits => '4',
                                                      #        }
                                                      #    }

# DESCRIPTION

Number::Phone::JP::AreaCode provides utilities for Japanese area code of phone.
You can retrieve area code by address and opposite.

If you want to know about Japanese area code of phone, please refer [http://www.soumu.go.jp/main\_sosiki/joho\_tsusin/top/tel\_number/shigai\_list.html](http://www.soumu.go.jp/main_sosiki/joho_tsusin/top/tel_number/shigai_list.html) (Japanese web page).

# FUNCTIONS

All of functions return `undef` if result of retrieving is nothing.

- address\_by\_area\_code($area\_code)

    Retrieve addresses list by area code.
    This function returns hash reference like;

        {
            addresses         => [ '北海道◯◯市××町', '北海道◯◯市△△町' ],
            local_code_digits => '3'
        }

    `addresses` is the list of addresses that belong with area code.
    `local_code_digits` is the number of digits of local code.

    You can append country code (0) or not. As you like it!

- area\_code\_by\_address($address)

    Retrieve area code by address (perfect matching). `$address` __MUST__ have prefecture name.
    This function returns hash reference like;

        {
            area_code => '72',
            local_code_digits => '3'
        }

    `area_code` is the area code which excepted country code (0).
    `local_code_digits` is the number of digits of local code.

- area\_code\_by\_address\_prefix\_match($address)

    Retrieve area code by address (prefix matching and longest matching). `$address` __MUST__ have prefecture name.
    This function returns hash reference that is the same as `area_code_by_address`.

- area\_code\_by\_address\_fuzzy($address)

    Retrieve area code by address (partial match). `$address` __MUST__ have prefecture name.
    This function returns hash reference like;

        {
            '大阪府◯◯市' => {
                area_code         => '6',
                local_code_digits => '4',
            },
            '大阪府△△市' => {
                area_code         => '72',
                local_code_digits => '3',
            }
        }

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# CONTRIBUTOR

ytnobody

# AUTHOR

moznion <moznion@gmail.com>
