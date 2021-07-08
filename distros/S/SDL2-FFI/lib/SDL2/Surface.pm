package SDL2::Surface {
    use SDL2::Utils;
    has
        flags     => 'uint32',
        format    => 'opaque',     # SDL_PixelFormat*
        w         => 'int',
        h         => 'int',
        pitch     => 'int',
        pixels    => 'opaque',     # void*
        userdata  => 'opaque',     # void*
        locked    => 'int',
        lock_data => 'opaque',     # void*
        clip_rect => 'SDL_Rect',
        map       => 'opaque',     # SDL_BlitMap*
        refcount  => 'int';

=encoding utf-8

=head1 NAME

SDL2::Surface - A collection of pixels used in software blitting

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO

=head1 DESCRIPTION

SDL2::Surface should be treated as read-only, except for C<pixels>, which, if
defined, contains the raw pixel data for the surface.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

blitting

=end stopwords

=cut    

};
1;
