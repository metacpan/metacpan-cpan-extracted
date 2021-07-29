package SDL2::Keysym {
    use SDL2::Utils;
    ffi->type( 'sint32' => 'SDL_Keycode' );
    has
        scancode => 'SDL_Scancode',
        sym      => 'SDL_Keycode',    # SDL_Keycode
        mod      => 'uint16',
        unused   => 'uint32';

=encoding utf-8

=head1 NAME

SDL2::Keysym - SDL Keysym structure used in key events device

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION


=head1 Fields

=over

=item C<scancode> - SDL physical key code - see SDL_Scancode for details

=item C<sym> - SDL virtual key code - see SDL_Keycode for details

=item C<mod> - Current key modifiers

=item C<unused>

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
