# https://github.com/libsdl-org/SDL/blob/main/include/SDL_video.h
package SDL2::DisplayMode {
    use SDL2::Utils;
    has
        format       => 'uint32',
        w            => 'int',
        h            => 'int',
        refresh_rate => 'int',
        driverdata   => 'opaque';

=encoding utf-8

=head1 NAME

SDL2::DisplayMode - Structure that Defines a Display Mode

=head1 SYNOPSIS

    use SDL2 qw[:all];
    SDL_Init(SDL_INIT_VIDEO);
    my $mode = SDL2::GetDisplayMode( 0, 0 );
    printf 'Display res %dx%d @ %dHz', $mode->w, $mode->h, $mode->refresh_rate;
    SDL_Quit();

=head1 DESCRIPTION

SDL2::DisplayMode

=head1 Fields

=over

=item C<format> - pixel format

=item C<w> - width, in screen coordinates

=item C<h> - height, in screen coordinates

=item C<refresh_rate> - refresh rate (or C<0> for unspecified)

=item C<driverdata> - opaque, driver-specific data

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords



=end stopwords

=cut

};
1;
