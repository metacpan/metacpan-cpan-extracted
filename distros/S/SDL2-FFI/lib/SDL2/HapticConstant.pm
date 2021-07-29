package SDL2::HapticConstant {
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

        # Constant
        level => 'sint16',

        # Envelope
        attack_length => 'uint16',
        attack_level  => 'uint16',
        fade_length   => 'uint16',
        fade_level    => 'uint16';

=encoding utf-8

=head1 NAME

SDL2::HapticConstant - A structure containing a template for a Constant effect

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION

A SDL2::HapticConstant is exclusively for the C<SDL_HAPTIC_CONSTANT> effect.

A constant effect applies a constant force in the specified direction to the
joystick.

=head1 Fields

=over

=item C<type> - C<SDL_HAPTIC_CONSTANT>

=item C<direction> - Direction of the effect

=item C<length> - Duration of the effect

=item C<delay> - Delay before starting the effect

=item C<button> - Button that triggers the effect

=item C<interval> - How soon it can be triggered again after button

=item C<level> - Strength of the constant effect

=item C<attack_length> - Duration of the attack

=item C<attack_level> - Level at the start of the attack

=item C<fade_length> - Duration of the fade

=item C<fade_level> - Level at the end of the fade

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
