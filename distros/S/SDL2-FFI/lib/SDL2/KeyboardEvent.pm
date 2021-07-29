package SDL2::KeyboardEvent {
    use SDL2::Utils;
    use SDL2::Keysym;
    has
        type      => 'uint32',
        timestamp => 'uint32',
        windowId  => 'uint32',
        state     => 'uint8',
        repeat    => 'uint8',
        padding2  => 'uint8',
        padding3  => 'uint8',
        keysym    => 'SDL_Keysym';

=encoding utf-8

=head1 NAME

SDL2::KeyboardEvent - Keyboard button event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION
 

=head1 Fields

=over

=item C<type> - C<SDL_KEYDOWN> or C<SDL_KEYUP>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<windowID> - The window with keyboard focus, if any

=item C<state> - C<SDL_PRESSED> or C<SDL_RELEASED>

=item C<repeat> - Non-zero if this is a key repeat

=item C<padding2>

=item C<padding3>

=item C<keysym> - The key that was pressed or released

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
