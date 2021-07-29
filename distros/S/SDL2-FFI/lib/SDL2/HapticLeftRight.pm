package SDL2::HapticLeftRight {
    use SDL2::Utils;
    has

        # Header
        type => 'uint16',

        # Replay
        length => 'uint32',

        # Rumble
        large_magnitude => 'uint16',
        small_magnitude => 'uint16';

=encoding utf-8

=head1 NAME

SDL2::HapticLeftRight - A structure containing a template for a Left/Right
effect

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION

A SDL2::HapticLeftRight is exclusively for the C<SDL_HAPTIC_LEFTRIGHT> effect.

The Left/Right effect is used to explicitly control the large and small motors,
commonly found in modern game controllers. The small (right) motor is high
frequency, and the large (left) motor is low frequency.

=head1 Fields

=over

=item C<type> - C<SDL_HAPTIC_RAMP>

=item C<length> - Duration of the effect in milliseconds

=item C<large_magnitude> - Control of the large controller motor

=item C<small_magnitude> - Control of the small controller motor

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
