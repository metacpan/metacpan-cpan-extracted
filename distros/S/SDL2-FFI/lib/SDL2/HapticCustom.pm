package SDL2::HapticCustom {
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

        # Custom
        channels => 'uint8',
        period   => 'uint16',
        samples  => 'uint16',
        data     => 'opaque',    # uint16 *

        # Envelope
        attack_length => 'uint16',
        attack_level  => 'uint16',
        fade_length   => 'uint16',
        fade_level    => 'uint16';

=encoding utf-8

=head1 NAME

SDL2::HapticCustom - A structure containing a template for a Custom effect

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION

A SDL2::HapticCustom is exclusively for the C<SDL_HAPTIC_CUSTOM> effect.

A custom force feedback effect is much like a periodic effect, where the
application can define its exact shape.  You will have to allocate the data
yourself.  Data should consist of channels * samples Uint16 samples.

If channels is one, the effect is rotated using the defined direction.
Otherwise it uses the samples in data for the different axes.

=head1 Fields

=over

=item C<type> - C<SDL_HAPTIC_CUSTOM>

=item C<direction> - Direction of the effect

=item C<length> - Duration of the effect

=item C<delay> - Delay before starting the effect

=item C<button> - Button that triggers the effect

=item C<interval> - How soon it can be triggered again after button

=item C<channels> - Axes to use, minimum of one

=item C<period> - Sample periods

=item C<samples> - Amount of samples

=item C<data> - Should contain C<channels*samples> items

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
