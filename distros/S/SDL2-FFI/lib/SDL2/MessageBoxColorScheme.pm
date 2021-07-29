package SDL2::MessageBoxColorScheme {
    use SDL2::Utils;
    use SDL2::MessageBoxColor;
    has colors => 'opaque'    # TODO

        #'SDL_MessageBoxColor[' . SDL2::FFI::SDL_MESSAGEBOX_COLOR_MAX() . ']'
        ;

=encoding utf-8

=head1 NAME

SDL2::MessageBoxColorScheme - A set of colors to use for message box dialogs

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION


=head1 Fields

=over

=item C<colors>

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
