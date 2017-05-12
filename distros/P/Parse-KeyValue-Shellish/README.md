[![Build Status](https://travis-ci.org/moznion/Parse-KeyValue-Shellish.png?branch=master)](https://travis-ci.org/moznion/Parse-KeyValue-Shellish) [![Coverage Status](https://coveralls.io/repos/moznion/Parse-KeyValue-Shellish/badge.png?branch=master)](https://coveralls.io/r/moznion/Parse-KeyValue-Shellish?branch=master)
# NAME

Parse::KeyValue::Shellish - Parses the key-value pairs like a shell script

# SYNOPSIS

    use Parse::KeyValue::Shellish qw/parse_key_value/;

    my $str    = 'foo=bar hoge=(fuga piyo)';
    my $parsed = parse_key_value($str); # => is_deeply {foo => 'bar', hoge => ['fuga', 'piyo']}

# DESCRIPTION

Parse::KeyValue::Shellish parses the key-value pairs like a shell script, means key and value are separated by '=' (for example `foo=bar`).

This is just \*\*\* shellish \*\*\*, means this module doesn't emulates the shell completely, It's spec.  But I'm willing to support features if someone so wish it :)

# FUNCTIONS

- parse\_key\_value($str)

    Parses `$str` as shellish key-value and returns hash reference of parsed result.
    If value is surrounded by parenthesis, it will be evaluated as array.
    Blocks of key-value must be separated by white-space.

    e.g.

        parse_key_value('foo=bar buz=q\ ux hoge=(fuga piyo)');
        # Result:
        #   {
        #       foo  => 'bar',
        #       buz  => 'q uz',
        #       hoge => ['fuga', 'piyo']
        #   }

    This function will croak if it has given a string which cannot be parsed.

# NOTES

## Value can contain '='

For example, this module can parse string like a `foo=bar=buz`. Result of it will be `{foo => 'bar=buz'}`.

## You can quote the value

Of course you can quote the value like a `foo='bar buz'`. Result will be `foo => 'bar buz'`.

## You can escape the character which in value

You can escape the character by backslash, for example `foo=ba\ r buz=\(\)`. Result of parsing it will be `foo => 'ba r', buz => '()'`.

### You cannot escape the character if it is quoted by single quotes.

You cannot escape the character if it is quoted by single quotes. For example, `foo='\'` will be parsed as `for => '\'`.

So it will be fail to parse `foo='\''` because single quotes are unbalanced. As the reason for this, `\'` isn't escaped.

### Shell recognizes `foo=\\` as `foo => '\'`, but this module doesn't

If you require an equivalent function, please give like so `foo=\\\\`.

This notation unlike the shells one, this is not intuitive. But I have no ideas of the way to handle this well...

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

moznion <moznion@gmail.com>
