# NAME

PDL::IO::Sereal - Load/save complete PDL content serialized via Sereal

# SYNOPSIS

    use PDL;
    use PDL::IO::Sereal ':all';

    my $pdl = random(100, 100, 100);
    # write piddle to file
    $pdl->wsereal('saved-piddle1.sereal');
    # read piddle from file
    my $new_pdl = rsereal('saved-piddle1.sereal');

# DESCRIPTION

Loading and saving PDL piddle serialized via [Sereal](https://metacpan.org/pod/Sereal) (by default with ZLIB compression).
Saved files should be portable across different architectures and PDL versions (there might
be some troubles with piddles of 'indx' type which are not portable between perls with
64bit vs. 32bit integers).

# FUNCTIONS

By default PDL::IO::Sereal doesn't import any function. You can import individual functions like this:

    use PDL::IO::Sereal qw(rsereal wsereal);

Or import all available functions:

    use PDL::IO::Sereal ':all';

**BEWARE:** any `use PDL::IO::Sereal` also installs `FREEZE` and `THAW` functions
into `PDL` namespace - see [Sereal::Encoder](https://metacpan.org/pod/Sereal::Encoder).

## wsereal

    wsereal($pdl, 'piddle1.sereal');
    # or
    $pdl->wsereal('piddle2.sereal');
    # or even
    $pdl->wsereal('piddle3.sereal')->minus($x, 0)->wsereal('piddle4.sereal');

## rsereal

    $pdl = rsereal('saved-piddle.sereal');

# SEE ALSO

[PDL](https://metacpan.org/pod/PDL), [Sereal](https://metacpan.org/pod/Sereal), [Sereal::Encoder](https://metacpan.org/pod/Sereal::Encoder), [Sereal::Decoder](https://metacpan.org/pod/Sereal::Decoder)

# LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# COPYRIGHT

2015 KMX <kmx@cpan.org>
