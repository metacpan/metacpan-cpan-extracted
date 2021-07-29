package SDL2::HapticCondition {
    use SDL2::Utils;
    has

        # Header
        type      => 'uint16',
        direction => 'opaque',    # SDL_HapticDirection

        # Replay
        length => 'uint32',
        delay  => 'uint16',

        # Trigger
        button   => 'uint16',
        interval => 'uint16',

        # Condition
        right_sat   => 'uint16[2]',
        left_sat    => 'uint16[2]',
        right_coeff => 'sint16[2]',
        left_coeff  => 'sint16[2]',
        deadband    => 'uint16[2]',
        center      => 'sint16[2]';

=encoding utf-8

=head1 NAME

SDL2::HapticCondition - A structure containing a template for a Condition
effect

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION

A SDL2::HapticCondition contains a template for a Condition effect.

The struct handles the following effects:

=over

=item C<SDL_HAPTIC_SPRING> - Effect based on axes position

=item C<SDL_HAPTIC_DAMPER> - Effect based on axes velocity

=item C<SDL_HAPTIC_INERTIA> - Effect based on axes acceleration

=item C<SDL_HAPTIC_FRICTION> - Effect based on axes movement
 
=back

Direction is handled by condition internals instead of a direction member. The
condition effect specific members have three parameters.  The first refers to
the X axis, the second refers to the Y axis and the third refers to the Z axis.
 The right terms refer to the positive side of the axis and the left terms
refer to the negative side of the axis.  Please refer to the
L<SDL2::HapticDirection> diagram for which side is positive and which is
negative.

=head1 Fields

=over

=item C<type> - C<SDL_HAPTIC_SPRING>, C<SDL_HAPTIC_DAMPER>, C<SDL_HAPTIC_INERTIA>, or C<SDL_HAPTIC_FRICTION>

=item C<direction> - Direction of the effect - Not used ATM

=item C<length> - Duration of the effect

=item C<delay> - Delay before starting the effect

=item C<button> - Button that triggers the effect

=item C<interval> - How soon it can be triggered again after button

=item C<right_sat> - Level when joystick is to the positive side; max C<0xFFFF>

=item C<left_sat> - Level when joystick is to the negative side; max C<0xFFFF>

=item C<right_coeff> - How fast to increase the force towards the positive side

=item C<left_coeff> - How fast to increase the force towards the negative side

=item C<deadband> - Size of the dead zone; max C<0xFFFF>: whole axis-range when C<0>-centered

=item C<center> - Position of the dead zone

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

struct

=end stopwords

=cut

};
1;
