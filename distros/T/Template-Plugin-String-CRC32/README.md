# NAME

Template::Plugin::String::CRC32 - [Template::Toolkit](https://metacpan.org/pod/Template::Toolkit) plugin-wrapper of [String::CRC32](https://metacpan.org/pod/String::CRC32)

# SYNOPSIS

    [% USE String::CRC32 -%]
    [% 'test_string' | crc32 %]
    [% text = 'test_string'; text.crc32 %]

# DESCRIPTION

_Template::Plugin::String::CRC32_ is wrapper of [String::CRC32](https://metacpan.org/pod/String::CRC32) module for [Template::Toolkit](https://metacpan.org/pod/Template::Toolkit).
It provides access to CRC32 algorithm via the `String::CRC32` module.
It is used like a plugin but installs filter and vmethod into the current context.

When you invoke

    [% USE String::CRC32 %]

the following filter (and vmethod of the same name) is installed
into the current context:

- `crc32`

    Calculate the CRC 32bit checksum of the input, and return it as 4-bytes integer.

As the filter is also available as vmethod the following are all
equivalent:

    FILTER crc32; content; END;
    content FILTER crc32;
    content.crc32;

# SEE ALSO

[String::CRC32](https://metacpan.org/pod/String::CRC32), [Template](https://metacpan.org/pod/Template)

# ACKNOWLEDGEMENTS

Code and documentation was inspired by [Template::Plugin::Digest::MD5](https://metacpan.org/pod/Template::Plugin::Digest::MD5) module.

# LICENSE

Copyright (C) Alexander A. Gnatyna.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Alexander A. Gnatyna <gnatyna@cpan.org>
