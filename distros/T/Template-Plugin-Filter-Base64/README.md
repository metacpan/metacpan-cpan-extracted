# NAME

Template::Plugin::Filter::Base64 - encoding b64 filter for Template Toolkit

# SYNOPSIS

    [% USE Filter.Base64 trim => 1, use_html_entity => 'cp1251', dont_broken_into_lines_each_76_char => 1 %]
    [% FILTER b64 %]
        Hello, world!
    [% END %]

    [% USE Filter.Base64 trim => 1 %]
    [% FILTER b64 safeurl => 1 %]
        Hello, world!
    [% END %]

# OPTIONS

- trim

    Optional. If true, removes trailing blank characters (and lf, cr) of an input string

- use\_html\_entity (string)

    Optional. Value means default charset (e.g. 'cp1251'). Result - convert text with html entities before base64-encoding

- dont\_broken\_into\_lines\_each\_76\_char

    Optional. If true, call the function MIME::Base64::encode\_base64( $bytes, '' ) whith empty string for the parameter $eol. The returned encoded string is broken into lines of no more than 76 characters each and it will end with $eol unless it is empty. Pass an empty string as second argument if you do not want the encoded string to be broken into lines

- safeurl (bool)

    Optional. If true call MIME::Base64::encode\_base64url, no other options do matter except ["trim"](#trim)

# SEE ALSO

MIME::Base64 - Encoding and decoding of base64 strings [https://metacpan.org/pod/MIME::Base64](https://metacpan.org/pod/MIME::Base64)

# LICENSE

Copyright (C) bbon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# THANKS

gnatyna [https://github.com/gnatyna](https://github.com/gnatyna)

gilgamesh44

# AUTHOR

bbon <bbon@mail.ru>
