# NAME

Module::Build::Pluggable::XSUtil - Utility for XS

# SYNOPSIS

    use Module::Build::Pluggable (
        'XSUtil' => {
            cc_warnings => 1,
            ppport      => 1,
            xshelper    => 1,
            'c++'       => 1,
            'c99'       => 1,
        },
    );

# DESCRIPTION

Module::Build::Pluggable::XSUtil is a utility for XS library.

This library is port of [Module::Install::XSUtil](https://metacpan.org/pod/Module::Install::XSUtil)

# OPTIONS

- c++

        use Module::Build::Pluggable (
            'XSUtil' => {
                'c++' => 1,
            },
        );

    This option checks C++ compiler's availability. If it's not available, Build.PL exits by 0.

- c99

        use Module::Build::Pluggable (
            'XSUtil' => {
                'c99' => 1,
            },
        );

    This option checks C99 compiler's availability. If it's not available, Build.PL exits by 0.

- ppport

        use Module::Build::Pluggable (
            'XSUtil' => {
                'ppport' => 1,
            },
        );

    Generate ppport.h automatically. If you want to specify the path for ppport.h, use following form:

        use Module::Build::Pluggable (
            'XSUtil' => {
                'ppport' => 'lib/My/ppport.h',
            },
        );

    If you want to specify the version of ppport.h, use configure\_requires in `Module::Build::Pluggable->new`.

- xshelper

        use Module::Build::Pluggable (
            'XSUtil' => {
                'xshelper' => 1,
            },
        );

    XSUtil generates xshelper.h. If you want to specify the path for xsutil.h, use following form:

        use Module::Build::Pluggable (
            'XSUtil' => {
                'xshelper' => 'lib/My/xshelper.h',
            },
        );

    XSUtil generates ppport.h to same directory(xshelper.h depend to ppport.h).

- cc\_warnings

        use Module::Build::Pluggable (
            'XSUtil' => {
                'cc_warnings' => 1,
            },
        );

    This option enables warnings flag for compiler.

# Options for Build.PL

Under the control of this module, `Build.PL` accepts `-g` option, which
sets `Module::Build`'s `extra_compiler_flags` `-g` (or something like). It will disable
optimization and enable some debugging features.

# AUTHOR

Goro Fuji, is original author of Module::Install::XSUtil.

Tokuhiro Matsuno &lt;tokuhirom AAJKLFJEF@ GMAIL COM>

# SEE ALSO

[Module::Install::XSUtil](https://metacpan.org/pod/Module::Install::XSUtil), [Module::Build::Pluggable](https://metacpan.org/pod/Module::Build::Pluggable)

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
