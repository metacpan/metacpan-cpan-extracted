[![Build Status](https://travis-ci.org/kablamo/perl-string-camelsnakekebab.svg?branch=master)](https://travis-ci.org/kablamo/perl-string-camelsnakekebab) [![Coverage Status](https://img.shields.io/coveralls/kablamo/perl-string-camelsnakekebab/master.svg?style=flat)](https://coveralls.io/r/kablamo/perl-string-camelsnakekebab?branch=master)
# NAME

String::CamelSnakeKebab - word case conversion

# SYNPOSIS

    use String::CamelSnakeKebab qw/:all/;

    lower_camel_case 'flux-capacitor'
    # => 'fluxCapacitor

    upper_camel_case 'flux-capacitor'
    # => 'FluxCapacitor

    lower_snake_case 'ASnakeSlithersSlyly'
    # => 'a_snake_slithers_slyly'

    upper_snake_case 'ASnakeSlithersSlyly'
    # => 'A_Snake_Slithers_Slyly'

    constant_case "I am constant"
    # => "I_AM_CONSTANT"

    kebab_case 'Peppers_Meat_Pineapple'
    # => 'peppers-meat-pineapple'

    http_header_case "x-ssl-cipher"
    # => "X-SSL-Cipher"

    word_split 'ASnakeSlithersSlyly'
    # => ["A", "Snake", "Slithers", "Slyly"]

    word_split 'flux-capacitor'
    # => ["flux", "capacitor"]

# DESCRIPTION

Camel-Snake-Kebab is a Clojure library for word case conversions.  This library
is ported from the original Clojure.

# METHODS

## lower\_camel\_case()

## upper\_camel\_case()

## lower\_snake\_case()

## upper\_snake\_case()

## constant\_case()

## kebab\_case()

## http\_header\_case()

## word\_split()

# ERROR HANDLING

Invalid input is usually indicated by returning the empty string.  So you may
want to check the return value.  This happens if you pass in something crazy
like "\_\_\_" or "\_-- \_" or "".  Because what does it mean to lower camel case
"\_-- \_"?  I don't know and I don't want to think about it any more.

# SEE ALSO

The original Camel Snake Kebab Clojure library: [https://github.com/qerub/camel-snake-kebab](https://github.com/qerub/camel-snake-kebab)

# AUTHOR

Eric Johnson (kablamo)
