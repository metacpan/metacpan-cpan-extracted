package SDL2::WindowShaper {
    use SDL2::Utils;
    has
        window     => 'opaque',    # SDL_Window
        usery      => 'uint32',
        userx      => 'uint32',
        mode       => 'opaque',    # SDL_WindowShapeMode
        hasshape   => 'bool',
        driverdata => 'opaque';    # void *

=encoding utf-8

=head1 NAME

SDL2::WindowShaper - SDL Window-shaper Structure

=head1 SYNOPSIS

    use SDL2 qw[:all];

=head1 DESCRIPTION

SDL2::WindowShaper

=head2 Fields

=over

=item C<window>

=item C<userx> - The user's specified coordinates for the window, for once we give it a shape

=item C<usery> - The user's specified coordinates for the window, for once we give it a shape

=item C<mode> - The parameters for shape calculation

=item C<hasshape> - Has this window been assigned a shape?

=item C<driverdata>

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

=end stopwords

=cut

};
1;
