[![Actions Status](https://github.com/tkzwtks/Nanoid-perl/workflows/test/badge.svg)](https://github.com/tkzwtks/Nanoid-perl/actions)
# NAME

Nanoid - Perl implementation of [Nano ID](https://github.com/ai/nanoid)

# SYNOPSIS

    use Nanoid;

    my $default = Nanoid::generate();                                        # length 21 / use URL-friendly characters
    my $custom1 = Nanoid::generate(size => 10);                              # length 10 / use URL-friendly characters
    my $custom2 = Nanoid::generate(size => 10, alphabet => 'abcdef012345');  # length 10 / use 'abcdef012345' characters

# DESCRIPTION

Nanoid is a tiny, secure, URL-friendly, unique string ID generator.

# LICENSE

Copyright (C) Hatena Co., Ltd..

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tkzwtks <tkzwtks@gmail.com>
