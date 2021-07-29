package SDL2::RendererInfo {
    use SDL2::Utils;
    has name                => 'opaque',       # string
        flags               => 'uint32',
        num_texture_formats => 'uint32',
        texture_formats     => 'uint32[16]',
        max_texture_width   => 'int',
        max_texture_height  => 'int';

=encoding utf-8

=head1 NAME

SDL2::RendererInfo - Information on the Capabilities of a Render Driver or
Context

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO
    warn $renderer->name;

=head1 DESCRIPTION

SDL2::RendererInfo

=head1 Fields

=over

=item C<name> - the name of the renderer

=item C<flags> - supported L<< C<:rendererFlags>|/C<:rendererFlags> >>

=item C<num_texture_formats> - the number of available texture format

=item C<texture_formats> - the available texture formats

=item C<max_texture_width> - the maximum texture width

=item C<max_texture_height> - the maximum texture height

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords



=end stopwords

=cut

};
1;
