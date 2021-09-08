package SDL2::haptic 0.01 {
    use SDL2::Utils;
    #
    use SDL2::stdinc;
    use SDL2::error;
    use SDL2::joystick;

    package SDL2::Haptic 0.01 {
        use SDL2::Utils;
        our $TYPE = has();
    };
    define haptic => [
        [ SDL_HAPTIC_CONSTANT      => ( 1 << 0 ) ],
        [ SDL_HAPTIC_SINE          => ( 1 << 1 ) ],
        [ SDL_HAPTIC_LEFTRIGHT     => ( 1 << 2 ) ],
        [ SDL_HAPTIC_TRIANGLE      => ( 1 << 3 ) ],
        [ SDL_HAPTIC_SAWTOOTHUP    => ( 1 << 4 ) ],
        [ SDL_HAPTIC_SAWTOOTHDOWN  => ( 1 << 5 ) ],
        [ SDL_HAPTIC_RAMP          => ( 1 << 6 ) ],
        [ SDL_HAPTIC_SPRING        => ( 1 << 7 ) ],
        [ SDL_HAPTIC_DAMPER        => ( 1 << 8 ) ],
        [ SDL_HAPTIC_INERTIA       => ( 1 << 9 ) ],
        [ SDL_HAPTIC_FRICTION      => ( 1 << 10 ) ],
        [ SDL_HAPTIC_CUSTOM        => ( 1 << 11 ) ],
        [ SDL_HAPTIC_GAIN          => ( 1 << 12 ) ],
        [ SDL_HAPTIC_AUTOCENTER    => ( 1 << 13 ) ],
        [ SDL_HAPTIC_STATUS        => ( 1 << 14 ) ],
        [ SDL_HAPTIC_PAUSE         => ( 1 << 15 ) ],
        [ SDL_HAPTIC_POLAR         => 0 ],
        [ SDL_HAPTIC_CARTESIAN     => 1 ],
        [ SDL_HAPTIC_SPHERICAL     => 2 ],
        [ SDL_HAPTIC_STEERING_AXIS => 3 ],
        [ SDL_HAPTIC_INFINITY      => 4294967295 ]
    ];

    package SDL2::HapticDirection {
        use SDL2::Utils;
        our $TYPE = has
            type => 'uint8',
            dir  => 'sint32[3]';
    };

    package SDL2::HapticConstant {
        use SDL2::Utils;
        our $TYPE = has

            # Header
            type      => 'uint16',
            direction => 'SDL_HapticDirection',

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
    };

    package SDL2::HapticPeriodic {
        use SDL2::Utils;
        our $TYPE = has

            # Header
            type      => 'uint16',
            direction => 'SDL_HapticDirection',

            # Replay
            length => 'uint32',
            delay  => 'uint16',

            # Trigger
            button   => 'uint16',
            interval => 'uint16',

            # Periodic
            period    => 'sint16',
            magnitude => 'sint16',
            offset    => 'sint16',
            phase     => 'uint16',

            # Envelope
            attack_length => 'uint16',
            attack_level  => 'uint16',
            fade_length   => 'uint16',
            fade_level    => 'uint16';
    };

    package SDL2::HapticCondition {
        use SDL2::Utils;
        our $TYPE = has

            # Header
            type      => 'uint16',
            direction => 'SDL_HapticDirection',

            # Replay
            length => 'uint32',
            delay  => 'uint16',

            # Trigger
            button   => 'uint16',
            interval => 'uint16',

            # Condition
            right_sat   => 'uint16[3]',
            left_sat    => 'uint16[3]',
            right_coeff => 'sint16[3]',
            left_coeff  => 'sint16[3]',
            deadband    => 'uint16[3]',
            center      => 'sint16[3]';
    };

    package SDL2::HapticRamp {
        use SDL2::Utils;
        our $TYPE = has

            # Header
            type      => 'uint16',
            direction => 'SDL_HapticDirection',

            # Replay
            length => 'uint32',
            delay  => 'uint16',

            # Trigger
            button   => 'uint16',
            interval => 'uint16',

            # Ramp
            start => 'sint16',
            end   => 'sint16',

            # Envelope
            attack_length => 'uint16',
            attack_level  => 'uint16',
            fade_length   => 'uint16',
            fade_level    => 'uint16';
    };

    package SDL2::HapticLeftRight {
        use SDL2::Utils;
        our $TYPE = has

            # Header
            type => 'uint16',

            # Replay
            length => 'uint32',

            # Rumble
            large_magnitude => 'uint16',
            small_magnitude => 'uint16';
    };

    package SDL2::HapticCustom {
        use SDL2::Utils;
        our $TYPE = has

            # Header
            type      => 'uint16',
            direction => 'SDL_HapticDirection',

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
    };

    package SDL2::HapticEffect {
        use SDL2::Utils;
        is 'Union';
        has
            type      => 'uint16',
            constant  => 'SDL_HapticConstant',
            periodic  => 'SDL_HapticPeriodic',
            condition => 'SDL_HapticCondition',
            ramp      => 'SDL_HapticRamp',
            leftright => 'SDL_HapticLeftRight',
            custom    => 'SDL_HapticCustom';
    };
    attach haptic => {
        SDL_NumHaptics              => [ [],               'int' ],
        SDL_HapticName              => [ ['int'],          'string' ],
        SDL_HapticOpen              => [ ['int'],          'SDL_Haptic' ],
        SDL_HapticOpened            => [ ['int'],          'int' ],
        SDL_HapticIndex             => [ ['SDL_Haptic'],   'int' ],
        SDL_MouseIsHaptic           => [ [],               'int' ],
        SDL_HapticOpenFromMouse     => [ [],               'SDL_Haptic' ],
        SDL_JoystickIsHaptic        => [ ['SDL_Joystick'], 'int' ],
        SDL_HapticOpenFromJoystick  => [ ['SDL_Joystick'], 'SDL_Haptic' ],
        SDL_HapticClose             => [ ['SDL_Haptic'] ],
        SDL_HapticNumEffects        => [ ['SDL_Haptic'],                              'int' ],
        SDL_HapticNumEffectsPlaying => [ ['SDL_Haptic'],                              'int' ],
        SDL_HapticQuery             => [ ['SDL_Haptic'],                              'int' ],
        SDL_HapticNumAxes           => [ ['SDL_Haptic'],                              'int' ],
        SDL_HapticEffectSupported   => [ [ 'SDL_Haptic', 'SDL_HapticEffect' ],        'int' ],
        SDL_HapticNewEffect         => [ [ 'SDL_Haptic', 'SDL_HapticEffect' ],        'int' ],
        SDL_HapticUpdateEffect      => [ [ 'SDL_Haptic', 'int', 'SDL_HapticEffect' ], 'int' ],
        SDL_HapticRunEffect         => [ [ 'SDL_Haptic', 'int', 'uint32' ],           'int' ],
        SDL_HapticStopEffect        => [ [ 'SDL_Haptic', 'int' ],                     'int' ],
        SDL_HapticDestroyEffect     => [ [ 'SDL_Haptic', 'int' ] ],
        SDL_HapticGetEffectStatus   => [ [ 'SDL_Haptic', 'int' ],             'int' ],
        SDL_HapticSetGain           => [ [ 'SDL_Haptic', 'int' ],             'int' ],
        SDL_HapticSetAutocenter     => [ [ 'SDL_Haptic', 'int' ],             'int' ],
        SDL_HapticPause             => [ ['SDL_Haptic'],                      'int' ],
        SDL_HapticUnpause           => [ ['SDL_Haptic'],                      'int' ],
        SDL_HapticStopAll           => [ ['SDL_Haptic'],                      'int' ],
        SDL_HapticRumbleSupported   => [ ['SDL_Haptic'],                      'int' ],
        SDL_HapticRumbleInit        => [ ['SDL_Haptic'],                      'int' ],
        SDL_HapticRumblePlay        => [ [ 'SDL_Haptic', 'float', 'uint32' ], 'int' ],
        SDL_HapticRumbleStop        => [ ['SDL_Haptic'],                      'int' ]
    };

=encoding utf-8

=head1 NAME

SDL2::haptic - SDL Haptic Subsystem Allowing You to Control Haptic (Force
Feedback) Devices

=head1 SYNOPSIS

    use SDL2 qw[:haptic];

=head1 DESCRIPTION

The SDL haptic subsystem allows you to control haptic (force feedback) devices.

The basic usage is as follows:

=over

=item - Initialize the subsystem (C<SDL_INIT_HAPTIC>).

=item - Open a haptic device.

=over

=item - L<< C<SDL_HapticOpen( ... )>|/C<SDL_HapticOpen( ... )> >> to open from index.

=item - L<< C<SDL_HapticOpenFromJoystick( ... )>|/C<SDL_HapticOpenFromJoystick( ... )> >> to open from an existing joystick.

=back

=item - Create an effect (C<SDL_HapticEffect>).

=item - Upload the effect with L<< C<SDL_HapticNewEffect( ... )>|/C<SDL_HapticNewEffect( ... )> >>.

=item - Run the effect with L<< C<SDL_HapticRunEffect( ... )>|/C<SDL_HapticRunEffect( ... )> >>.

=item - (optional) Free the effect with L<< C<SDL_HapticDestroyEffect( ... )>|/C<SDL_HapticDestroyEffect( ... )> >>.

=item - Close the haptic device with L<< C<SDL_HapticClose( ... )>|/C<SDL_HapticClose( ... )> >>.

=back

Simple rumble example:

    # Open the device
    my $haptic = SDL_HapticOpen( 0 );
    $haptic // return -1;

    # Initialize simple rumble
    return -1 if SDL_HapticRumbleInit( $haptic ) != 0;

    # Play effect at 50% strength for 2 seconds
    return -1 if SDL_HapticRumblePlay( $haptic, 0.5, 2000 ) != 0;
    SDL_Delay( 2000 );

    # Clean up
    SDL_HapticClose( $haptic );

Complete example:

    sub test_haptic ($joystick) {
        my $effect_id;

        # Open the device
        my $haptic = SDL_HapticOpenFromJoystick($joystick);
        $haptic // return -1;    # Most likely joystick isn't haptic

        # See if it can do sine waves
        if ( ( SDL_HapticQuery($haptic) & SDL_HAPTIC_SINE ) == 0 ) {
            SDL_HapticClose($haptic);    # No sine effect
            return -1;
        }

        # Create the effect
        my $effect = SDL2::HapticEffect->new();
        $effect->type(SDL_HAPTIC_SINE);
        $effect->periodic->direction->type(SDL_HAPTIC_POLAR);   # Polar coordinates
        $effect->periodic->direction->dir->[0] = 18000;         # Force comes from south
        $effect->periodic->period(1000);                        # 1000 ms
        $effect->periodic->magnitude(20000);                    # 20000/32767 strength
        $effect->periodic->length(5000);                        # 5 seconds long
        $effect->periodic->attack_length(1000);                 # Takes 1 second to get max strength
        $effect->periodic->fade_length(1000);                   # Takes 1 second to fade away

        #  Upload the effect
        $effect_id = SDL_HapticNewEffect( $haptic, \$effect );

        # Test the effect
        SDL_HapticRunEffect( $haptic, $effect_id, 1 );
        SDL_Delay(5000);                                        # Wait for the effect to finish

        # We destroy the effect, although closing the device also does this
        SDL_HapticDestroyEffect( $haptic, $effect_id );

        # Close the device
        SDL_HapticClose($haptic);
        return 0;                                               # Success
    }

=head1 Functions

These may be imported by name or with the C<:haptic> tag.

=head2 C<SDL_NumHaptics( ... )>

Count the number of haptic devices attached to the system.

Returns the number of haptic devices detected on the system or a negative error
code on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticName( ... )>

Get the implementation dependent name of a haptic device.

This can be called before any joysticks are opened. If no name can be found,
this function returns C<undef>.

Expected parameters include:

=over

=item C<device_index> - index of the device to query

=back

Returns the name of the device or C<undef> on failure; call C<SDL_GetError( )>
for more information.

=head2 C<SDL_HapticOpen( ... )>

Open a haptic device for use.

The index passed as an argument refers to the N'th haptic device on this
system.

When opening a haptic device, its gain will be set to maximum and autocenter
will be disabled. To modify these values use L<< C<SDL_HapticSetGain( ...
)>|/C<SDL_HapticSetGain( ... )> >> and L<< C<SDL_HapticSetAutocenter( ...
)>|/C<SDL_HapticSetAutocenter( ... )> >>.

Expected parameters include:

=over

=item C<device_index> - index of the device to open

=back

Returns the device identifier or C<undef> on failure; call C<SDL_GetError( )>
for more information.

=head2 C<SDL_HapticOpened( ... )>

Check if the haptic device at the designated index has been opened.

Expected parameters include:

=over

=item C<device_index> - the index of the device to query

=back

Returns C<1> if it has been opened, C<0> if it hasn't or on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticIndex( ... )>

Get the index of a haptic device.

Expected parameters include:

=over

=item C<haptic> - the L<SDL2::Haptic> device to query

=back

Returns the index of the specified haptic device or a negative error code on
failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_MouseIsHaptic( )>

Query whether or not the current mouse has haptic capabilities.

Returns C<SDL_TRUE> if the mouse is haptic or C<SDL_FALSE> if it isn't.

=head2 C<SDL_HapticOpenFromMouse( )>

Try to open a haptic device from the current mouse.

Returns the haptic device identifier or C<undef> on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_JoystickIsHaptic( ... )>

Query if a joystick has haptic features.

Expected parameters include:

=over

=item C<joystick> - the L<SDL2::Joystick> to test for haptic capabilities

=back

Returns C<SDL_TRUE> if the joystick is haptic, C<SDL_FALSE> if it isn't, or a
negative error code on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticOpenFromJoystick( ... )>

Open a haptic device for use from a joystick device.

You must still close the haptic device separately. It will not be closed with
the joystick.

When opened from a joystick you should first close the haptic device before
closing the joystick device. If not, on some implementations the haptic device
will also get unallocated and you'll be unable to use force feedback on that
device.

Expected parameters include:

=over

=item C<joystick> - the L<SDL2::Joystick> to create a haptic device from

=back

Returns a valid haptic device identifier on success or C<undef> on failure;
call C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticClose( ... )>

Close a haptic device previously opened with SDL_HapticOpen().

Expected parameters include:

=over

=item C<haptic> - the L<SDL2::Haptic> device to close

=back

=head2 C<SDL_HapticNumEffects( ... )>

Get the number of effects a haptic device can store.

On some platforms this isn't fully supported, and therefore is an
approximation. Always check to see if your created effect was actually created
and do not rely solely on SDL_HapticNumEffects().

Expected parameters include:

=over

=item C<haptic> - the L<SDL2::Haptic> device to query

=back

Returns the number of effects the haptic device can store or a negative error
code on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticNumEffectsPlaying( ... )>

Get the number of effects a haptic device can play at the same time.

This is not supported on all platforms, but will always return a value.

Expected parameters include:

=over

=item C<haptic> - the L<SDL2::Haptic> device to query maximum playing effects

=back

Returns the number of effects the haptic device can play at the same time or a
negative error code on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticQuery( ... )>

Get the haptic device's supported features in bitwise manner.

Expected parameters include:

=over

=item C<haptic> - the L<SDL2::Haptic> device to query

=back

Returns a list of supported haptic features in bitwise manner (OR'd), or C<0>
on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticNumAxes( ... )>

Get the number of haptic axes the device has.

The number of haptic axes might be useful if working with the
L<SDL2::HapticDirection> effect.

Expected parameters include:

=over

=item C<haptic> - the L<SDL2::Haptic> device to query

=back

Returns the number of axes on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticEffectSupported( ... )>

Check to see if an effect is supported by a haptic device.

Expected parameters include:

=over

=item C<haptic> - the L<SDL2::Haptic> device to query

=item C<effect> - the desired effect to query

=back

Returns C<SDL_TRUE> if effect is supported, C<SDL_FALSE> if it isn't, or a
negative error code on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticNewEffect( ... )>

Create a new haptic effect on a specified device.

Expected parameters include:

=over

=item C<haptic> - an L<SDL2::Haptic> device to create the effect on

=item C<effect> - an L<SDL2::HapticEffect> structure containing the properties of the effect to create

=back

Returns the ID of the effect on success or a negative error code on failure;
call C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticUpdateEffect( ... )>

Update the properties of an effect.

Can be used dynamically, although behavior when dynamically changing direction
may be strange. Specifically the effect may re-upload itself and start playing
from the start. You also cannot change the type either when running L<<
C<SDL_HapticUpdateEffect( ... )>|/C<SDL_HapticUpdateEffect( ... )> >>.

Expected parameters include:

=over

=item C<haptic> - the L<SDL2::Haptic> device that has the effect

=item C<effect> - the identifier of the effect to update

=item C<data> - an L<SDL2::HapticEffect> structure containing the new effect properties to use

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticRunEffect( ... )>

Run the haptic effect on its associated haptic device.

To repeat the effect over and over indefinitely, set C<iterations> to
C<SDL_HAPTIC_INFINITY>. (Repeats the envelope - attack and fade.) To make one
instance of the effect last indefinitely (so the effect does not fade), set the
effect's `length` in its structure/union to C<SDL_HAPTIC_INFINITY> instead.

Expected parameters include:

=over

=item C<haptic> - the L<SDL2::Haptic> device to run the effect on

=item C<effect> - the ID of the haptic effect to run

=item C<iterations> - the number of iterations to run the effect; use C<SDL_HAPTIC_INFINITY> to repeat forever

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticStopEffect( ... )>

Stop the haptic effect on its associated haptic device.

Expected parameters include:

=over

=item C<haptic> - the SDL_Haptic device to stop the effect on

=item C<effect> - the ID of the haptic effect to stop

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticDestroyEffect( ... )>

Destroy a haptic effect on the device.

This will stop the effect if it's running. Effects are automatically destroyed
when the device is closed.

Expected parameters include:

=over

=item C<haptic> - the L<SDL2::Haptic> device to destroy the effect on

=item C<effect> - the ID of the haptic effect to destroy

=back

=head2 C<SDL_HapticGetEffectStatus( ... )>

Get the status of the current effect on the specified haptic device.

Device must support the C<SDL_HAPTIC_STATUS> feature.

Expected parameters include:

=over

=item C<haptic> - the L<SDL2::Haptic> device to query for the effect status on

=item C<effect> - the ID of the haptic effect to query its status

=back

Returns C<0> if it isn't playing, C<1> if it is playing, or a negative error
code on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticSetGain( ... )>

Set the global gain of the specified haptic device.

Device must support the C<SDL_HAPTIC_GAIN> feature.

The user may specify the maximum gain by setting the environment variable
C<SDL_HAPTIC_GAIN_MAX> which should be between C<0> and C<100>. All calls to
L<< C<SDL_HapticSetGain( ... )>|/C<SDL_HapticSetGain( ... )> >> will scale
linearly using C<SDL_HAPTIC_GAIN_MAX> as the maximum.

Expected parameters include:

=over

=item C<haptic> - the L<SDL2::Haptic> device to set the gain on

=item C<gain> - value to set the gain to, should be between C<0> and C<100>

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticSetAutocenter( ... )>

Set the global autocenter of the device.

Autocenter should be between 0 and 100. Setting it to 0 will disable
autocentering.

Device must support the C<SDL_HAPTIC_AUTOCENTER> feature.

Expected parameters include:

=over

=item C<haptic> - the L<SDL2::Haptic> device to set autocentering on

=item C<autocenter> - value to set autocenter to (0-100)

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticPause( ... )>

Pause a haptic device.

Device must support the C<SDL_HAPTIC_PAUSE> feature. Call L<<
C<SDL_HapticUnpause( ... )>|/C<SDL_HapticUnpause( ... )> >> to resume playback.

Do not modify the effects nor add new ones while the device is paused. That can
cause all sorts of weird errors.

Expected parameters include:

=over

=item C<haptic> - the L<SDL2::Haptic> device to pause

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticUnpause( ... )>

Unpause a haptic device.

Call to unpause after L<< C<SDL_HapticPause( ... )>|/C<SDL_HapticPause( ... )>
>>.

Expected parameters include:

=over

=item C<haptic> - the L<SDL2::Haptic> device to unpause

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticStopAll( ... )>

Stop all the currently playing effects on a haptic device.

Expected parameters include:

=over

=item C<haptic> - the L<SDL2::Haptic> device to stop

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticRumbleSupported( ... )>

Check whether rumble is supported on a haptic device.

Expected parameters include:

=over

=item C<haptic> - haptic device to check for rumble support

=back

Returns C<SDL_TRUE> if effect is supported, C<SDL_FALSE> if it isn't, or a
negative error code on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticRumbleInit( ... )>

Initialize a haptic device for simple rumble playback.

Expected parameters include:

=over

=item C<haptic> - the haptic device to initialize for simple rumble playback

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticRumblePlay( ... )>

Run a simple rumble effect on a haptic device.

Expected parameters include:

=over

=item C<haptic> - the haptic device to play the rumble effect on

=item C<strength> - strength of the rumble to play as a 0-1 float value

=item C<length> - length of the rumble to play in milliseconds

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_HapticRumbleStop( ... )>

Stop the simple rumble on a haptic device.

Expected parameters include:

=over

=item C<haptic> - the haptic device to stop the rumble effect on

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head1 Defined Values and Enumerations

These may be imported by name or with the given tag.

=head2 Haptic Features

Different haptic features a device can have. These values may all be imported
with the C<:haptic> tag.

=head3 Haptic effects

=over

=item C<SDL_HAPTIC_CONSTANT> - Constant haptic effect

=item C<SDL_HAPTIC_SINE> - Periodic haptic effect that simulates sine waves

=item C<SDL_HAPTIC_LEFTRIGHT> - Haptic effect for direct control over high/low frequency motors

=item C<SDL_HAPTIC_TRIANGLE> - Periodic haptic effect that simulates triangular waves

=item C<SDL_HAPTIC_SAWTOOTHUP> - Periodic haptic effect that simulates saw tooth up waves

=item C<SDL_HAPTIC_SAWTOOTHDOWN> - Periodic haptic effect that simulates saw tooth down waves

=item C<SDL_HAPTIC_RAMP> - Ramp haptic effect

=item C<SDL_HAPTIC_SPRING> - Condition haptic effect that simulates a spring. Effect is based on the axes position

=item C<SDL_HAPTIC_DAMPER> - Condition haptic effect that simulates dampening. Effect is based on the axes velocity

=item C<SDL_HAPTIC_INERTIA> - Condition haptic effect that simulates inertia. Effect is based on the axes acceleration

=item C<SDL_HAPTIC_FRICTION> - Condition haptic effect that simulates friction. Effect is based on the axes movement

=item C<SDL_HAPTIC_CUSTOM> - User defined custom haptic effect

=back

These last few are features the device has, not effects:

=over

=item C<SDL_HAPTIC_GAIN> - Device supports setting the global gain

=item C<SDL_HAPTIC_AUTOCENTER> - Device supports setting autocenter

=item C<SDL_HAPTIC_STATUS> - Device supports querying effect status

=item C<SDL_HAPTIC_PAUSE> - Devices supports being paused

=back

=head3 Direction encodings

=over

=item C<SDL_HAPTIC_POLAR> - Uses polar coordinates for the direction

=item C<SDL_HAPTIC_CARTESIAN> - Uses cartesian coordinates for the direction

=item C<SDL_HAPTIC_SPHERICAL> - Uses spherical coordinates for the direction

=item C<SDL_HAPTIC_STEERING_AXIS> - Use this value to play an effect on the steering wheel axis. This provides better compatibility across platforms and devices as SDL will guess the correct axis

=back

=head3 Misc defines

=over

=item C<SDL_HAPTIC_INFINITY> - Used to play a device an infinite number of times

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

N'th autocentering unpause autocenter

=end stopwords

=cut

};
1;
