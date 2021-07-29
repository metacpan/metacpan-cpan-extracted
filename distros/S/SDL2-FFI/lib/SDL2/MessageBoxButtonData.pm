package SDL2::MessageBoxButtonData {
    use SDL2::Utils;
    has
        flags    => 'uint32',
        buttonid => 'int',
        text     => 'opaque';    # 'string';

=encoding utf-8

=head1 NAME

SDL2::MessageBoxButtonData - Individual button data

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION


=head1 Fields

=over

=item C<flags> - L<< C<SDL_MessageBoxButtonFlags>|SDL2::FFI/C<:messageBoxButtonFlags> >>

=item C<buttonid> - User defined button id (value returned via L<< C<SDL_ShowMessageBox( ... )>|SDL2::FFI/C<SDL_ShowMessageBox( ... )> >>)

=item C<text> - The UTF-8 button text

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
