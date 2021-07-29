package SDL2::HapticPeriodic {
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

        # Periodic
        periodic  => 'sint16',
        magnitude => 'sint16',
        offset    => 'sint16',
        phase     => 'uint16',

        # Envelope
        attack_length => 'uint16',
        attack_level  => 'uint16',
        fade_length   => 'uint16',
        fade_level    => 'uint16';

=encoding utf-8

=head1 NAME

SDL2::HapticPeriodic - A structure containing a template for a Periodic effect

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION

A SDL2::HapticPeriodic contains a template for a Periodic effect.

The struct handles the following effects:

=over 

=item C<SDL_HAPTIC_SINE>

=item C<SDL_HAPTIC_LEFTRIGHT>

=item C<SDL_HAPTIC_TRIANGLE>

=item C<SDL_HAPTIC_SAWTOOTHUP>

=item C<SDL_HAPTIC_SAWTOOTHDOWN>

=back
 
A periodic effect consists in a wave-shaped effect that repeats itself over
time.  The type determines the shape of the wave and the parameters determine
the dimensions of the wave.

Phase is given by hundredth of a degree meaning that giving the phase a value
of 9000 will displace it 25% of its period.  Here are sample values:

=over

=item C<0> - No phase displacement

=item C<9000> - Displaced 25% of its period

=item C<18000> - Displaced 50% of its period

=item C<27000> - Displaced 75% of its period

=item C<36000> - Displaced 100% of its period, same as 0, but 0 is preferred

=back

Examples:

    SDL_HAPTIC_SINE
      __      __      __      __
     /  \    /  \    /  \    /
    /    \__/    \__/    \__/

    SDL_HAPTIC_SQUARE
     __    __    __    __    __
    |  |  |  |  |  |  |  |  |  |
    |  |__|  |__|  |__|  |__|  |
    
    SDL_HAPTIC_TRIANGLE
      /\    /\    /\    /\    /\
     /  \  /  \  /  \  /  \  /
    /    \/    \/    \/    \/
    
    SDL_HAPTIC_SAWTOOTHUP
      /|  /|  /|  /|  /|  /|  /|
     / | / | / | / | / | / | / |
    /  |/  |/  |/  |/  |/  |/  |
    
    SDL_HAPTIC_SAWTOOTHDOWN
    \  |\  |\  |\  |\  |\  |\  |
     \ | \ | \ | \ | \ | \ | \ |
      \|  \|  \|  \|  \|  \|  \|

=head1 Fields

=over

=item C<type> - C<SDL_HAPTIC_SINE>, C<SDL_HAPTIC_LEFTRIGHT>, C<SDL_HAPTIC_TRIANGLE>, C<SDL_HAPTIC_SAWTOOTHUP>, or C<SDL_HAPTIC_SAWTOOTHDOWN>

=item C<direction> - Direction of the effect

=item C<length> - Duration of the effect

=item C<delay> - Delay before starting the effect

=item C<button> - Button that triggers the effect

=item C<interval> - How soon it can be triggered again after button

=item C<period> - Period of the wave

=item C<magnitude> - Peak value; if negative, equivalent to 180 degrees extra phase shift

=item C<offset> - Mean value of the wave

=item C<phase> - Positive phase shift given by hundredth of a degree

=item C<attack_length> - Duration of the attack

=item C<attack_level> - Level at the start of the attack

=item C<fade_length> - Duration of the fade

=item C<fade_level> - Level at the end of the fade

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

struct

=end stopwords

=cut

};
1;
