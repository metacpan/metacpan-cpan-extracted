package SDL2::ControllerAxisEvent {
    use SDL2::Utils;
    has
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'opaque',    # SDL_JoystickID
        axis      => 'uint8',
        padding1  => 'uint8',
        padding2  => 'uint8',
        padding3  => 'uint8',
        value     => 'sint16',
        padding4  => 'uint8';

=encoding utf-8

=head1 NAME

SDL2::ControllerAxisEvent - Game controller axis motion event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION
 

=head1 Fields

=over

=item C<type> - C<SDL_CONTROLLERAXISMOTION>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<which> - The joystick instance id

=item C<axis> - The controller axis

=item C<padding1>

=item C<padding2>

=item C<padding3>

=item C<value> - The axis value (range: C<-32768> to C<32767>)

=item C<padding4>

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
