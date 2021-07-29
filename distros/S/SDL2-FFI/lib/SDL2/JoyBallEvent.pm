package SDL2::JoyBallEvent {
    use SDL2::Utils;
    has
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'opaque',    # SDL_JoystickID
        ball      => 'uint8',
        padding1  => 'uint8',
        padding2  => 'uint8',
        padding3  => 'uint8',
        xrel      => 'sint16',
        yrel      => 'sint16';

=encoding utf-8

=head1 NAME

SDL2::JoyBallEvent - Joystick trackball motion event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION
 

=head1 Fields

=over

=item C<type> - C<SDL_JOYBALLMOTION>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<which> - The joystick instance id

=item C<ball> - The joystick trackball index

=item C<padding1>

=item C<padding2>

=item C<padding3>

=item C<xrel> - The relative motion in the X direction

=item C<yrel> - The relative motion in the Y direction

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
