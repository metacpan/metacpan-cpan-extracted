[![Actions Status](https://github.com/tkzwtks/Nanoid-perl/workflows/test/badge.svg)](https://github.com/tkzwtks/Nanoid-perl/actions)
# NAME

Nanoid - Perl implementation of [nanoid](https://github.com/ai/nanoid)

# SYNOPSIS

    use Nanoid;

    my $default = Nanoid::generate();                    # length 21 / use URL-friendry character
    my $custom1 = Nanoid::generate(10);                  # length 10 / use URL-friendry character
    my $custom2 = Nanoid::generate(10, 'abcdef012345');  # length 10 / use 'abcdef012345'

# DESCRIPTION

Nanoid is a tiny, secure, URL-friendly, unique string ID generator.

# LICENSE

Copyright (C) Hatena Co., Ltd..

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tkzwtks <tkzwtks@gmail.com>
