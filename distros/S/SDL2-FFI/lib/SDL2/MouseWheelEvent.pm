package SDL2::MouseWheelEvent {
    use SDL2::Utils;
    has
        type      => 'uint32',
        timestamp => 'uint32',
        windowId  => 'uint32',
        which     => 'uint32',
        x         => 'sint32',
        y         => 'sint32',
        direction => 'uint32';

=encoding utf-8

=head1 NAME

SDL2::MouseWheelEvent - Mouse wheel event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION
 

=head1 Fields

=over

=item C<type> - C<SDL_MOUSEWHEEL>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<windowID> - The window with mouse focus, if any

=item C<which> - The mouse instance id, or C<SDL_TOUCH_MOUSEID>

=item C<x> - The amount scrolled horizontally, positive to the right and negative to the left

=item C<y> - The amount scrolled vertically, positive away from the user and negative toward the user

=item C<direction> - Set to one of the C<SDL_MOUSEWHEEL_*> defines. When FLIPPED the values in X and Y will be opposite. Multiply by C<-1> to change them back

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
