# NAME

PLON - Serialize object to Perl code

# SYNOPSIS

    use PLON;

    my $plon = encode_plon([]);
    # $plon is `[]`

# DESCRIPTION

PLON is yet another serialization library for Perl5, has the JSON.pm like interface.

# WHY?

I need data dumper library supports JSON::XS/JSON::PP like interface.
I use JSON::XS really hard. Then, I want to use other serialization library with JSON::XS/JSON::PP's interface.

Data::Dumper escapes multi byte chars. When I want copy-and-paste from Data::Dumper's output to my test code, I need to un-escape `\x{5963}` by my hand. PLON.pm don't escape multi byte characters by default.

# STABILITY

This release is a prototype. Every API will change without notice.
(But, I may not remove `encode_plon($scalar)` interface. You can use this.)

I need your feedback. If you have ideas or comments, please report to [Github Issues](https://github.com/tokuhirom/PLON/issues).

# OBJECT-ORIENTED INTERFACE

The object oriented interface lets you configure your own encoding or
decoding style, within the limits of supported formats.

- $plon = PLON->new()

    Creates a new PLON object that can be used to de/encode PLON
    strings. All boolean flags described below are by default _disabled_.

- `$plon = $plon->pretty([$enabled])`

    This enables (or disables) all of the `indent`, `space_before` and
    `space_after` (and in the future possibly more) flags in one call to
    generate the most readable (or most compact) form possible.

- `$plon->ascii([$enabled])`
- `my $enabled = $plon->get_ascii()`

        $plon = $plon->ascii([$enable])

        $enabled = $plon->get_ascii

    If $enable is true (or missing), then the encode method will not generate characters outside
    the code range 0..127. Any Unicode characters outside that range will be escaped using either
    a \\x{XXXX} escape sequence.

    If $enable is false, then the encode method will not escape Unicode characters unless
    required by the PLON syntax or other flags. This results in a faster and more compact format.

        PLON->new->ascii(1)->encode([chr 0x10401])
        => ["\x{10401}"]

- `$plon->deparse([$enabled])`
- `my $enabled = $plon->get_deparse()`

    If $enable is true (or missing), then the encode method will de-parse the code by [B::Deparse](https://metacpan.org/pod/B::Deparse).
    Otherwise, encoder generates `sub { "DUMMY" }` like [Data::Dumper](https://metacpan.org/pod/Data::Dumper).

- `$plon->canonical([$enabled])`
- `my $enabled = $plon->get_canonical()`

    If $enable is true (or missing), then the "encode" method will output
    PLON objects by sorting their keys. This is adding a comparatively
    high overhead.

# PLON Spec

- PLON only supports UTF-8. Serialized PLON string must be UTF-8.
- PLON string must be eval-able.

# LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Tokuhiro Matsuno <tokuhirom@gmail.com>

# SEE ALSO

- [Data::Dumper](https://metacpan.org/pod/Data::Dumper)
- [Data::Pond](https://metacpan.org/pod/Data::Pond)
- [Acme::PSON](https://metacpan.org/pod/Acme::PSON)
