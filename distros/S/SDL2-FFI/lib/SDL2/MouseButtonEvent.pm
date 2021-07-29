package SDL2::MouseButtonEvent {
    use SDL2::Utils;
    has
        type      => 'uint32',
        timestamp => 'uint32',
        windowID  => 'uint32',
        which     => 'uint32',
        button    => 'uint8',
        state     => 'uint8',
        clicks    => 'uint8',
        padding1  => 'uint8',
        x         => 'sint32',
        y         => 'sint32';

=encoding utf-8

=head1 NAME

SDL2::MouseButtonEvent - Mouse button event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION
 

=head1 Fields

=over

=item C<type> - C<SDL_MOUSEBUTTONDOWN> or C<SDL_MOUSEBUTTONUP>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<windowID> - The window with mouse focus, if any

=item C<which> - The mouse instance id, or C<SDL_TOUCH_MOUSEID>

=item C<button> - The mouse button index

=item C<state> - C<SDL_PRESSED> or C<SDL_RELEASED>

=item C<clicks> - C<1> for single-click, C<2> for double-click, etc.

=item C<padding1>

=item C<x> - X coordinate, relative to window

=item C<y> - Y coordinate, relative to window

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
