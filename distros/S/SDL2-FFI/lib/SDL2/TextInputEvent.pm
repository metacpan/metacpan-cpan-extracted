package SDL2::TextInputEvent {
    use SDL2::Utils;

    # Defined in https://github.com/libsdl-org/SDL/blob/main/include/SDL_events.h
    sub SDL_TEXTINPUTEVENT_TEXT_SIZE() {32}
    has
        type      => 'uint32',
        timestamp => 'uint32',
        windowId  => 'uint32',
        text      => 'char[' . SDL_TEXTINPUTEVENT_TEXT_SIZE() . ']',
        ;

=encoding utf-8

=head1 NAME

SDL2::TextInputEvent - Keyboard text input event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION
 

=head1 Fields

=over

=item C<type> - C<SDL_TEXTINPUT>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<windowID> - The window with keyboard focus, if any

=item C<text> - The editing text

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
