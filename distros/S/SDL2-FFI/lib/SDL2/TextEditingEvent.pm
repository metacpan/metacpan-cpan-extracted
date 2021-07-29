package SDL2::TextEditingEvent {
    use SDL2::Utils;

    # Defined in https://github.com/libsdl-org/SDL/blob/main/include/SDL_events.h
    sub SDL_TEXTEDITINGEVENT_TEXT_SIZE() {32}
    has
        type      => 'uint32',
        timestamp => 'uint32',
        windowId  => 'uint32',
        text      => 'char[' . SDL_TEXTEDITINGEVENT_TEXT_SIZE() . ']',
        start     => 'sint32',
        length    => 'sint32';

=encoding utf-8

=head1 NAME

SDL2::TextEditingEvent - Keyboard text editing event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION
 

=head1 Fields

=over

=item C<type> - C<SDL_TEXTEDITING>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<windowID> - The window with keyboard focus, if any

=item C<text> - The editing text

=item C<start> - The start cursor of selected editing text

=item C<length> - The length of selected editing text

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
