package SDL2::endian {
    use strictures 2;
    use SDL2::Utils;
    use Config;
    #
    use SDL2::stdinc;
    #
    define endian => [
        [ SDL_LIL_ENDIAN => 1234 ],
        [ SDL_BIG_ENDIAN => 4321 ],
        [ SDL_BYTEORDER  => $Config{byteorder} ],
    ];

=encoding utf-8

=head1 NAME

SDL2::endian - Basic Endian-specific Values

=head1 SYNOPSIS

    use SDL2 qw[:endian];

=head1 DESCRIPTION

SDL2::endian contains values which might be useful for reading and writing
endian-specific values.

=head1 Defined Values

These may be imported with the C<:endian> tag.

=head2 The two types of endianness

=over

=item C<SDL_BYTEORDER> - System's byteorder

=item C<SDL_LIL_ENDIAN> - Example little endian value to compare against

=item C<SDL_BIG_ENDIAN> - Example big endian value to compare against

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

endian-specific endian byteorder

=end stopwords

=cut

};
1;
