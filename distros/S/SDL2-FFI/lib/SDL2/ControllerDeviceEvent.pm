package SDL2::ControllerDeviceEvent {
    use SDL2::Utils;
    has
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'sint32';

=encoding utf-8

=head1 NAME

SDL2::ControllerDeviceEvent - Game controller button event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION
 

=head1 Fields

=over

=item C<type> - C<SDL_CONTROLLERDEVICEADDED>, C<SDL_CONTROLLERDEVICEREMOVED>, or C<SDL_CONTROLLERDEVICEREMAPPED>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<which> - The joystick device index for the C<ADDED> event, instance id for the C<REMOVED> or C<REMAPPED> event

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
