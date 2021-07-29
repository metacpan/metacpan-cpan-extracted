package SDL2::MessageBoxData {
    use SDL2::Utils;
    use SDL2::MessageBoxButtonData;
    use SDL2::MessageBoxColorScheme;
    has
        flags       => 'uint32',
        window      => 'opaque',                      # TODO: SDL_Window*
        title       => 'opaque',                      # string
        message     => 'opaque',                      # string
        numbuttons  => 'int',
        buttons     => 'SDL_MessageBoxButtonData',
        colorScheme => 'SDL_MessageBoxColorScheme';

=encoding utf-8

=head1 NAME

SDL2::MessageBoxData - MessageBox structure containing title, text, window,
etc.

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION


=head1 Fields

=over

=item C<flags> - L<< C<SDL_MessageBoxFlags>|SDL2::FFI/C<:messageBoxFlags> >>

=item C<window> - Parent window, can be undefined

=item C<title> - UTF-8 title

=item C<message> - UTF-8 message text

=item C<numbuttons>

=item C<buttons>

=item C<colorScheme> - L<SDL2::MessageBoxColorScheme>, can be undefined to use system settings

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
