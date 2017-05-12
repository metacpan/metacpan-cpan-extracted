# NAME

Template::Plugin::Filter::Base64 - encoding b64 filter for Template Toolkit

# SYNOPSIS

    [% USE Filter.Base64 trim => 1, use_html_entity => 'cp1251' %]
    [% FILTER b64 %]
        Hello, world!
    [% END %]

# OPTIONS

- trim

    Optional. If true, removes trailing blank characters (and lf, cr) of an input string

- use\_html\_entity (string)

    Optional. Value means default charset (e.g. 'cp1251'). Result - convert text with html entities before base64-encoding

# SEE ALSO

MIME::Base64 - Encoding and decoding of base64 strings [http://search.cpan.org/~gaas/MIME-Base64/Base64.pm](http://search.cpan.org/~gaas/MIME-Base64/Base64.pm)

# LICENSE

Copyright (C) bbon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

bbon <bbon@mail.ru>
