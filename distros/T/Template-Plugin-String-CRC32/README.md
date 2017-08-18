# NAME

Template::Plugin::String::CRC32 - [Template::Toolkit](https://metacpan.org/pod/Template::Toolkit) plugin-wrapper of [String::CRC32](https://metacpan.org/pod/String::CRC32)

# SYNOPSIS

\[% USE String::CRC32 -%\]
\[% 'test\_string' | crc32 %\]
\[% text = 'test\_string'; text.crc32 %\]

# DESCRIPTION

Template::Plugin::String::CRC32 is wrapper of [String::CRC32](https://metacpan.org/pod/String::CRC32) for [Template::Toolkit](https://metacpan.org/pod/Template::Toolkit)

# LICENSE

Copyright (C) Alexander A. Gnatyna.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Alexander A. Gnatyna <gnatyna@ya.ru>
