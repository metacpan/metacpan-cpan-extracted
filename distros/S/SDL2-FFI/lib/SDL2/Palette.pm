package SDL2::Palette {
    use SDL2::Utils;
    has
        ncolors  => 'int',
        colors   => 'SDL_Color',
        version  => 'uint32',
        refcount => 'int';

=encoding utf-8

=head1 NAME

SDL2::Palette - RGBA color palette structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION


=head1 Fields

=over

=item C<ncolors>

=item C<colors>

=item C<version>

=item C<refcount>

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
