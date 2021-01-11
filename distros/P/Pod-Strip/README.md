# NAME

Pod::Strip - Remove POD from Perl code

# VERSION

version 1.100

# SYNOPSIS

    use Pod::Strip;

    my $p=Pod::Strip->new;              # create parser
    my $podless;                        # set output string
    $p->output_string(\$podless);       # see Pod::Simple
    $p->parse_string_document($code);   # or some other parsing method
                                        #    from Pod::Simple
    # $podless will now contain code without any POD

# DESCRIPTION

Pod::Strip is a subclass of Pod::Simple that strips all POD from Perl Code.

# METHODS

All methods besides those listed here are inherited from Pod::Simple

## new

Generate a new parser object.

## replace\_with\_comments

Call this method with a true argument to replace POD with comments (looking like "# stripped POD") instead of stripping it.

This has the effect that line numbers get reported correctly in error
messages etc.

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2004 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
