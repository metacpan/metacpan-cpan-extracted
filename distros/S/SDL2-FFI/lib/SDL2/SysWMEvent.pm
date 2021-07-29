package SDL2::SysWMEvent {
    use SDL2::Utils;
    use SDL2::SysWMmsg;
    has
        type      => 'uint32',
        timestamp => 'uint32',
        msg       => 'opaque';    # SDL_SysWMmsg;

=encoding utf-8

=head1 NAME

SDL2::SysWMEvent - Video driver dependent system event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION

A SDL2::SysWMEvent object represents a video driver dependent system event.

This event is disabled by default, you can enable it with L<< C<SDL_EventState(
... )>|SDL::FFI/C<SDL_EventState( ... )> >>.

=head1 Fields

=over

=item C<type> - C<SDL_SYSWMEVENT>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<msg> - Driver dependant data, defined in C<SDL_syswm.h>

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
