package SDL2::DropEvent {
    use SDL2::Utils;
    has
        type      => 'uint32',
        timestamp => 'uint32',
        file      => 'char[1024]',    # char *
        windowID  => 'uint32';

=encoding utf-8

=head1 NAME

SDL2::DropEvent - File drop event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION
 
A SDL2::DropEvent structure is generated to request a file open by the system.
This event is enabled by default, you can disable it with L<< C<SDL_EventState(
... )>|SDL::FFI/C<SDL_EventState( ... )> >>.

Note: if this event is enabled, you must free the filename in the event.

=head1 Fields

=over

=item C<type> - C<SDL_DROPBEGIN> or C<SDL_DROPFILE> or C<SDL_DROPTEXT> or C<SDL_DROPCOMPLETE>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<file> - The file name, which should be freed with SDL_free(), is NULL on begin/complete

=item C<windowID> - The window that was dropped on, if any

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
