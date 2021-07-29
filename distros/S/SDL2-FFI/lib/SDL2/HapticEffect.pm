package SDL2::HapticEffect {
    use SDL2::Utils;
    use FFI::C::UnionDef;
    use SDL2::HapticConstant;
    use SDL2::HapticPeriodic;
    use SDL2::HapticCondition;
    use SDL2::HapticRamp;
    use SDL2::HapticLeftRight;
    use SDL2::HapticCustom;
    FFI::C::UnionDef->new( ffi,
        name    => 'SDL_HapticEffect',
        class   => 'SDL2::HapticEffect',
        members => [
            type      => 'uint16',
            constant  => 'SDL_HapticConstant',
            periodic  => 'SDL_HapticPeriodic',
            condition => 'SDL_HapticCondition',
            ramp      => 'SDL_HapticRamp',
            leftright => 'SDL_HapticLeftRight',
            custom    => 'SDL_HapticCustom'
        ]
    );

=encoding utf-8

=head1 NAME

SDL2::HapticEffect - A generic template for a any haptic effect

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION

SDL2::HapticEffect is a C union which generalizes all known haptic effects.

All values max at C<32767> (C<0x7FFF>).  Signed values also can be negative.
Time values unless specified otherwise are in milliseconds.

You can also pass C<SDL_HAPTIC_INFINITY> to length instead of a C<0-32767>
value. Neither C<delay>, C<interval>, C<attack_length> nor C<fade_length>
support C<SDL_HAPTIC_INFINITY>. Fade will also not be used since effect never
ends.

Additionally, the C<SDL_HAPTIC_RAMP> effect does not support a duration of
C<SDL_HAPTIC_INFINITY>.

Button triggers may not be supported on all devices, it is advised to not use
them if possible. Buttons start at index C<1> instead of index C<0> like the
joystick.

If both C<attack_length> and C<fade_level> are C<0>, the envelope is not used,
otherwise both values are used.

Common parts:

=over

=item Replay - All effects have this

=over 

=item C<Uint32 length> - Duration of effect (ms).

=item C<Uint16 delay> - Delay before starting effect.
 
=back

=item Trigger - All effects have this

=over

=item C<Uint16 button> - Button that triggers effect.

=item C<Uint16 interval> - How soon before effect can be triggered again.

=back

=item Envelope - All effects except condition effects have this

=over

=item C<Uint16 attack_length> - Duration of the attack (ms).

=item C<Uint16 attack_level> - Level at the start of the attack.

=item C<Uint16 fade_length> - Duration of the fade out (ms).

=item C<Uint16 fade_level> - Level at the end of the fade.

=back 
 
=back

Here we have an example of a constant effect evolution in time:

    Strength
    ^
    |
    |    effect level -->  _________________
    |                     /                 \
    |                    /                   \
    |                   /                     \
    |                  /                       \
    | attack_level --> |                        \
    |                  |                        |  <---  fade_level
    |
    +--------------------------------------------------> Time
                       [--]                 [---]
                       attack_length        fade_length
    [------------------][-----------------------]
    delay               length
 
 Note either the C<attack_level> or the C<fade_level> may be above the actual
 effect level.

=head1 Fields

As a union, this object main contain the following structures:

=over

=item C<type> - Effect type

=item C<constant> - SDL2::HapticConstant

=item C<periodic> - SDL2::HapticPeriodic

=item C<condition> - SDL2::HapticCondition

=item C<ramp> - SDL2::HapticRamp

=item C<leftright> - SDL2::HapticLeftRight

=item C<custom> - SDL2::HapticCustom

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
