package SDL2::UserEvent {
    use SDL2::Utils;
    has
        type      => 'uint32',
        timestamp => 'uint32',
        windowID  => 'uint32',
        code      => 'sint32',
        data1     => 'opaque',    # void *
        data2     => 'opaque';    # void *

=encoding utf-8

=head1 NAME

SDL2::UserEvent - OS Specific event

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION


=head1 Fields

=over

=item C<type> - C<SDL_USEREVENT> through C<SDL_LASTEVENT - 1>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<windowID> - The associated window, if any

=item C<code> - User defined event code

=item C<data1> - User defined data pointer

=item C<data2> - User defined data pointer

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
