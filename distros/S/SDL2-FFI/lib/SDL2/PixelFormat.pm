package SDL2::PixelFormat {
    use SDL2::Utils;
    has
        format        => 'uint32',
        palette       => 'SDL_Palette',
        BitsPerPixel  => 'uint8',
        BytesPerPixel => 'uint8',
        padding       => 'uint8[2]',
        Rmask         => 'uint32',
        Gmask         => 'uint32',
        Bmask         => 'uint32',
        Amask         => 'uint32',
        Rloss         => 'uint8',
        Gloss         => 'uint8',
        Bloss         => 'uint8',
        Aloss         => 'uint8',
        Rshift        => 'uint8',
        Gshift        => 'uint8',
        Bshift        => 'uint8',
        Ashift        => 'uint8',
        refcount      => 'int',
        next          => 'opaque'         # SDL_PixelFormat *
        ;

=encoding utf-8

=head1 NAME

SDL2::PixelFormat - RGBA pixel structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION

Everything in the pixel format structure is read-only.

=head1 Fields

=over

=item C<format>

=item C<palette>

=item C<BitsPerPixel>

=item C<BytesPerPixel>

=item C<padding>

=item C<Rmask>

=item C<Gmask>

=item C<Bmask>

=item C<Amask>

=item C<Rloss>

=item C<Gloss>

=item C<Bloss>

=item C<Aloss>

=item C<Rshift>

=item C<Gshift>

=item C<Bshift>

=item C<Ashift> 

=item C<refcount>

=item C<next>

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
