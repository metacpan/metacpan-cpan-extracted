package SDL2::joystick 0.01 {
    use SDL2::Utils;
    use experimental 'signatures';
    #
    use SDL2::stdinc;
    use SDL2::error;

    package SDL2::Joystick {
        use SDL2::Utils;
        our $TYPE = has();
    };

    package SDL2::JoystickGUID {
        use SDL2::Utils;
        our $TYPE = has data => 'uint8[16]';
    };
    #
    ffi->type( 'sint32' => 'SDL_JoystickID' );
    enum SDL_JoystickType => [
        qw[
            SDL_JOYSTICK_TYPE_UNKNOWN
            SDL_JOYSTICK_TYPE_GAMECONTROLLER
            SDL_JOYSTICK_TYPE_WHEEL
            SDL_JOYSTICK_TYPE_ARCADE_STICK
            SDL_JOYSTICK_TYPE_FLIGHT_STICK
            SDL_JOYSTICK_TYPE_DANCE_PAD
            SDL_JOYSTICK_TYPE_GUITAR
            SDL_JOYSTICK_TYPE_DRUM_KIT
            SDL_JOYSTICK_TYPE_ARCADE_PAD
            SDL_JOYSTICK_TYPE_THROTTLE
        ]
        ],
        SDL_JoystickPowerLevel => [
        [ SDL_JOYSTICK_POWER_UNKNOWN => -1 ], qw[SDL_JOYSTICK_POWER_EMPTY
            SDL_JOYSTICK_POWER_LOW
            SDL_JOYSTICK_POWER_MEDIUM
            SDL_JOYSTICK_POWER_FULL
            SDL_JOYSTICK_POWER_WIRED
            SDL_JOYSTICK_POWER_MAX
        ]
        ];
    #
    define joystick => [
        [ SDL_IPHONE_MAX_GFORCE => 5.0 ],
        [ SDL_JOYSTICK_AXIS_MAX => 32767 ],
        [ SDL_JOYSTICK_AXIS_MIN => -32768 ],
        [ SDL_HAT_CENTERED      => 0x00 ],
        [ SDL_HAT_UP            => 0x01 ],
        [ SDL_HAT_RIGHT         => 0x02 ],
        [ SDL_HAT_DOWN          => 0x04 ],
        [ SDL_HAT_LEFT          => 0x08 ],
        [ SDL_HAT_RIGHTUP       => sub () { ( SDL_HAT_RIGHT | SDL_HAT_UP ) } ],
        [ SDL_HAT_RIGHTDOWN     => sub () { ( SDL_HAT_RIGHT | SDL_HAT_DOWN ) } ],
        [ SDL_HAT_LEFTUP        => sub () { ( SDL_HAT_LEFT | SDL_HAT_UP ) } ],
        [ SDL_HAT_LEFTDOWN      => sub () { ( SDL_HAT_LEFT | SDL_HAT_DOWN ) } ],
    ];
    #
    attach joystick => {
        SDL_LockJoysticks                   => [ [] ],
        SDL_UnlockJoysticks                 => [ [] ],
        SDL_NumJoysticks                    => [ [],                      'int' ],
        SDL_JoystickNameForIndex            => [ ['int'],                 'string' ],
        SDL_JoystickGetDevicePlayerIndex    => [ ['int'],                 'int' ],
        SDL_JoystickGetDeviceGUID           => [ ['int'],                 'SDL_JoystickGUID' ],
        SDL_JoystickGetDeviceVendor         => [ ['int'],                 'uint16' ],
        SDL_JoystickGetDeviceProduct        => [ ['int'],                 'uint16' ],
        SDL_JoystickGetDeviceProductVersion => [ ['int'],                 'uint16' ],
        SDL_JoystickGetDeviceType           => [ ['int'],                 'SDL_JoystickType' ],
        SDL_JoystickGetDeviceInstanceID     => [ ['int'],                 'SDL_JoystickID' ],
        SDL_JoystickOpen                    => [ ['int'],                 'SDL_Joystick' ],
        SDL_JoystickFromInstanceID          => [ ['SDL_JoystickID'],      'SDL_Joystick' ],
        SDL_JoystickFromPlayerIndex         => [ ['int'],                 'SDL_Joystick' ],
        SDL_JoystickAttachVirtual           => [ [ 'int', 'int', 'int' ], 'int' ],
        SDL_JoystickDetachVirtual           => [ ['int'],                 'int' ],
        SDL_JoystickIsVirtual               => [ ['int'],                 'SDL_bool' ],
        SDL_JoystickSetVirtualAxis          => [ [ 'SDL_Joystick', 'int', 'sint16' ], 'int' ],
        SDL_JoystickSetVirtualButton        => [ [ 'SDL_Joystick', 'int', 'uint8' ],  'int' ],
        SDL_JoystickSetVirtualHat           => [ [ 'SDL_Joystick', 'int', 'uint8' ],  'int' ],
        SDL_JoystickName                    => [ ['SDL_Joystick'],                    'string' ],
        SDL_JoystickGetPlayerIndex          => [ ['SDL_Joystick'],                    'int' ],
        SDL_JoystickSetPlayerIndex          => [ [ 'SDL_Joystick', 'int' ] ],
        SDL_JoystickGetGUID                 => [ ['SDL_Joystick'], 'SDL_JoystickGUID' ],
        SDL_JoystickGetVendor               => [ ['SDL_Joystick'], 'uint16' ],
        SDL_JoystickGetProduct              => [ ['SDL_Joystick'], 'uint16' ],
        SDL_JoystickGetProductVersion       => [ ['SDL_Joystick'], 'uint16' ],
        SDL_JoystickGetSerial               => [ ['SDL_Joystick'], 'string' ],
        SDL_JoystickGetType                 => [ ['SDL_Joystick'], 'SDL_JoystickType' ],
        SDL_JoystickGetGUIDString           => [ [ 'SDL_JoystickGUID', 'string', 'int' ] ],
        SDL_JoystickGetGUIDFromString       => [ ['string'],       'SDL_JoystickGUID' ],
        SDL_JoystickGetAttached             => [ ['SDL_Joystick'], 'SDL_bool' ],
        SDL_JoystickInstanceID              => [ ['SDL_Joystick'], 'SDL_JoystickID' ],
        SDL_JoystickNumAxes                 => [ ['SDL_Joystick'], 'int' ],
        SDL_JoystickNumBalls                => [ ['SDL_Joystick'], 'int' ],
        SDL_JoystickNumHats                 => [ ['SDL_Joystick'], 'int' ],
        SDL_JoystickNumButtons              => [ ['SDL_Joystick'], 'int' ],
        SDL_JoystickUpdate                  => [ [] ],
        SDL_JoystickEventState              => [ ['int'],                             'int' ],
        SDL_JoystickGetAxis                 => [ [ 'SDL_Joystick', 'int' ],           'sint16' ],
        SDL_JoystickGetAxisInitialState     => [ [ 'SDL_Joystick', 'int', 'sint16' ], 'SDL_bool' ],
        SDL_JoystickGetHat                  => [ [ 'SDL_Joystick', 'int' ],           'uint8' ],
        SDL_JoystickGetBall        => [ [ 'SDL_Joystick', 'int', 'int*', 'int*' ],        'int' ],
        SDL_JoystickGetButton      => [ [ 'SDL_Joystick', 'int' ],                        'uint8' ],
        SDL_JoystickRumble         => [ [ 'SDL_Joystick', 'uint16', 'uint16', 'uint32' ], 'int' ],
        SDL_JoystickRumbleTriggers => [ [ 'SDL_Joystick', 'uint16', 'uint16', 'uint32' ], 'int' ],
        SDL_JoystickHasLED         => [ ['SDL_Joystick'],                              'SDL_bool' ],
        SDL_JoystickSetLED         => [ [ 'SDL_Joystick', 'uint8', 'uint8', 'uint8' ], 'int' ],
        SDL_JoystickClose             => [ ['SDL_Joystick'] ],
        SDL_JoystickCurrentPowerLevel => [ ['SDL_Joystick'], 'SDL_JoystickPowerLevel' ]
    };

=encoding utf-8

=head1 NAME

SDL2::joystick - SDL Joystick Event Handling

=head1 SYNOPSIS

    use SDL2 qw[:joystick];

=head1 DESCRIPTION

The term "device_index" identifies currently plugged in joystick devices
between 0 and L<< C<SDL_NumJoysticks( )>|/C<SDL_NumJoysticks( )> >>, with the
exact joystick behind a C<device_index> changing as joysticks are plugged and
unplugged.

The term "instance_id" is the current instantiation of a joystick device in the
system, if the joystick is removed and then re-inserted then it will get a new
C<instance_id>, C<instance_id>'s are monotonically increasing identifiers of a
joystick plugged in.

The term "C<player_index>" is the number assigned to a player on a specific
controller. For XInput controllers this returns the XInput user index. Many
joysticks will not be able to supply this information.

The term JoystickGUID is a stable 128-bit identifier for a joystick device that
does not change over time, it identifies class of the device (a X360 wired
controller for example). This identifier is platform dependent.


=head1 Functions

These functions may be imported with the C<:joystick> tag or by name.

=head2 C<SDL_LockJoysticks( )>

Locking for multi-threaded access to the joystick API.

If you are using the joystick API or handling events from multiple threads you
should use these locking functions to protect access to the joysticks.

In particular, you are guaranteed that the joystick list won't change, so the
API functions that take a joystick index will be valid, and joystick and game
controller events will not be delivered.

=head2 C<SDL_UnlockJoysticks( )>

Unlocking for multi-threaded access to the joystick API

If you are using the joystick API or handling events from multiple threads you
should use these locking functions to protect access to the joysticks.

In particular, you are guaranteed that the joystick list won't change, so the
API functions that take a joystick index will be valid, and joystick and game
controller events will not be delivered.

=head2 C<SDL_NumJoysticks( )>

Count the number of joysticks attached to the system.

	my $count = SDL_NumJoysticks( );

Returns the number of attached joysticks on success or a negative error code on
failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_JoystickNameForIndex( ... )>

Get the implementation dependent name of a joystick.

This can be called before any joysticks are opened.

Expected parameters include:

=over

=item C<device_index> - the index of the joystick to query (the N'th joystick on the system)

=back

Returns the name of the selected joystick. If no name can be found, this
function returns C<undef>; call C<SDL_GetError( )> for more information.

=head2 C<SDL_JoystickGetDevicePlayerIndex( ... )>

Get the player index of a joystick, or C<-1> if it's not available This can be
called before any joysticks are opened.

	my $p_id = SDL_JoystickGetDevicePlayerIndex( 1 );

Expected parameters include:

=over

=item C<device_index>

=back

Returns the player index or C<-1> on error; call C<SDL_GetError( )> for more
information.

=head2 C<SDL_JoystickGetDeviceGUID( ... )>

Get the implementation-dependent GUID for the joystick at a given device index.

This function can be called before any joysticks are opened.

Expected parameters include:

=over

=item C<device_index> - the index of the joystick to query (the N'th joystick on the system

=back

Returns the GUID of the selected joystick. If called on an invalid index, this
function returns a zero GUID.

=head2 C<SDL_JoystickGetDeviceVendor( ... )>

Get the USB vendor ID of a joystick, if available.

This can be called before any joysticks are opened. If the vendor ID isn't
available this function returns C<0>.

Expected parameters include:

=over

=item C<device_index> - the index of the joystick to query (the N'th joystick on the system

=back

Returns the USB vendor ID of the selected joystick. If called on an invalid
index, this function returns zero.

=head2 C<SDL_JoystickGetDeviceProduct( ... )>

Get the USB product ID of a joystick, if available.

This can be called before any joysticks are opened. If the product ID isn't
available this function returns 0.

Expected parameters include:

=over

=item C<device_index> - the index of the joystick to query (the N'th joystick on the system

=back

Returns the USB product ID of the selected joystick. If called on an invalid
index, this function returns zero.

=head2 C<SDL_JoystickGetDeviceProductVersion( ... )>

Get the product version of a joystick, if available.

This can be called before any joysticks are opened. If the product version
isn't available this function returns C<0>.

Expected parameters include:

=over

=item C<device_index> - the index of the joystick to query (the N'th joystick on the system

=back

Returns the product version of the selected joystick. If called on an invalid
index, this function returns zero.

=head2 C<SDL_JoystickGetDeviceType( ... )>

Get the type of a joystick, if available.

This can be called before any joysticks are opened.

Expected parameters include:

=over

=item C<device_index> - the index of the joystick to query (the N'th joystick on the system

=back

Returns the C<SDL_JoystickType> of the selected joystick. If called on an
invalid index, this function returns C<SDL_JOYSTICK_TYPE_UNKNOWN>.

=head2 C<SDL_JoystickGetDeviceInstanceID( ... )>

Get the instance ID of a joystick.

This can be called before any joysticks are opened. If the index is out of
range, this function will return C<-1>.

Expected parameters include:

=over

=item C<device_index> - the index of the joystick to query (the N'th joystick on the system

=back

Returns the instance id of the selected joystick. If called on an invalid
index, this function returns zero.

=head2 C<SDL_JoystickOpen( ... )>

Open a joystick for use.

	# Initialize the joystick subsystem
	SDL_InitSubSystem( SDL_INIT_JOYSTICK );

	# Check for joystick
	if (SDL_NumJoysticks( ) > 0) {
		# Open joystick
		my $joy = SDL_JoystickOpen( 0 );

		if (joy) {
			printf( "Opened Joystick 0\n" );
			printf( "Name: %s\n", SDL_JoystickNameForIndex( 0 ) );
			printf( "Number of Axes: %d\n", SDL_JoystickNumAxes($joy) );
			printf( "Number of Buttons: %d\n", SDL_JoystickNumButtons( $joy ) );
			printf( "Number of Balls: %d\n", SDL_JoystickNumBalls( $joy ) );
		}
		else {
			printf( "Couldn't open Joystick 0\n" );
		}

		# Close if opened
		if ( SDL_JoystickGetAttached( $joy ) ) {
			SDL_JoystickClose( $joy );
		}
	}

The C<device_index> argument refers to the N'th joystick presently recognized
by SDL on the system. It is B<NOT> the same as the instance ID used to identify
the joystick in future events. See L<< C<SDL_JoystickInstanceID( ...
)>|/C<SDL_JoystickInstanceID( ... )> >> for more details about instance IDs.

The joystick subsystem must be initialized before a joystick can be opened for
use.

Expected parameters include:

=over

=item C<device_index> - the index of the joystick to query

=back

Returns a joystick identifier or C<undef> if an error occurred; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_JoystickFromInstanceID( ... )>

Get the L<SDL2::Joystick> associated with an instance id.

Expected parameters include:

=over

=item C<instance_id> - the instance id to get the SDL_Joystick for

=back

Returns an L<SDL2::Joystick> on success or C<undef> on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_JoystickFromPlayerIndex( ... )>

Get the L<SDL2::Joystick> associated with a player index.

Expected parameters include:

=over

=item C<player_index> - the player index to get the L<SDL2::Joystick> for

=back

Returns an L<SDL2::Joystick> on success or C<undef> on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_JoystickAttachVirtual( ... )>

Attach a new virtual joystick.

Expected parameters include:

=over

=item C<type> - C<SDL_JoystickType>

=item C<naxes> - number of axes

=item C<nbuttons> - number of buttons

=item C<nhats> - number of hats

=back

Returns the joystick's device index, or C<-1> if an error occurred.

=head2 C<SDL_JoystickDetachVirtual( ... )>

Detach a virtual joystick.

Expected parameters include:

=over

=item C<device_index> - a value previously returned from L<< C<SDL_JoystickAttachVirtual( ... )>|/C<SDL_JoystickAttachVirtual( ... )> >>

=back

Returns C<0> on success, or C<-1> if an error occurred.

=head2 C<SDL_JoystickIsVirtual( ... )>

Query whether or not the joystick at a given device index is virtual.

Expected parameters include:

=over

=item C<device_index> - a joystick device index

=back

Returns C<SDL_TRUE> if the joystick is virtual, C<SDL_FALSE> otherwise.

=head2 C<SDL_JoystickSetVirtualAxis( ... )>

Set values on an opened, virtual-joystick's axis.

Please note that values set here will not be applied until the next call to
SDL_JoystickUpdate, which can either be called directly, or can be called
indirectly through various other SDL APIs, including, but not limited to the
following: C<SDL_PollEvent>, C<SDL_PumpEvents>, C<SDL_WaitEventTimeout>,
C<SDL_WaitEvent>.

Expected parameters include:

=over

=item C<joystick> - the virtual joystick on which to set state

=item C<axis> - the specific axis on the virtual joystick to set

=item C<value> - the new value for the specified axis

=back

Returns C<0> on success, C<-1> on error.

=head2 C<SDL_JoystickSetVirtualButton( ... )>

Set values on an opened, virtual-joystick's button.

Please note that values set here will not be applied until the next call to
SDL_JoystickUpdate, which can either be called directly, or can be called
indirectly through various other SDL APIs, including, but not limited to the
following: C<SDL_PollEvent>, C<SDL_PumpEvents>, C<SDL_WaitEventTimeout>,
C<SDL_WaitEvent>.

Expected parameters include:

=over

=item C<joystick> - the virtual joystick on which to set state

=item C<button> - the specific button on the virtual joystick to set

=item C<value> - the new value for the specified button

=back

Returns C<0> on success, C<-1> on error.

=head2 C<SDL_JoystickSetVirtualHat( ... )>

Set values on an opened, virtual-joystick's hat.

Please note that values set here will not be applied until the next call to
C<SDL_JoystickUpdate>, which can either be called directly, or can be called
indirectly through various other SDL APIs, including, but not limited to the
following: C<SDL_PollEvent>, C<SDL_PumpEvents>, C<SDL_WaitEventTimeout>,
C<SDL_WaitEvent>.

Expected parameters include:

=over

=item C<joystick> - the virtual joystick on which to set state

=item C<hat> - the specific hat on the virtual joystick to set

=item C<value> - the new value for the specified hat

=back

Returns C<0> on success, C<-1> on error.

=head2 C<SDL_JoystickName( ... )>

Get the implementation dependent name of a joystick.

Expected parameters include:

=over

=item C<joystick> - the L<SDL2::Joystick> obtained from L<< C<SDL_JoystickOpen( ... )>|/C<SDL_JoystickOpen( ... )> >>

=back

Returns the name of the selected joystick. If no name can be found, this
function returns C<undef>; call C<SDL_GetError( )> for more information.

=head2 C<SDL_JoystickGetPlayerIndex( ... )>

Get the player index of an opened joystick.

For XInput controllers this returns the XInput user index. Many joysticks will
not be able to supply this information.

Expected parameters include:

=over

=item C<joystick> - the L<SDL2::Joystick> obtained from L<< C<SDL_JoystickOpen( ... )>|/C<SDL_JoystickOpen( ... )> >>

=back

Returns the player index, or C<-1> if it's not available.

=head2 C<SDL_JoystickSetPlayerIndex( ... )>

Set the player index of an opened joystick.

Expected parameters include:

=over

=item C<joystick> - the L<SDL2::Joystick> obtained from L<< C<SDL_JoystickOpen( ... )>|/C<SDL_JoystickOpen( ... )> >>

=item C<player_index> - the player index to set

=back

=head2 C<SDL_JoystickGetGUID( ... )>

Get the implementation-dependent GUID for the joystick.

This function requires an open joystick.

Expected parameters include:

=over

=item C<joystick> - the L<SDL2::Joystick> obtained from L<< C<SDL_JoystickOpen( ... )>|/C<SDL_JoystickOpen( ... )> >>

=back

Returns the GUID of the given joystick. If called on an invalid index, this
function returns a zero GUID; call C<SDL_GetError( )> for more information.

=head2 C<SDL_JoystickGetVendor( ... )>

Get the USB vendor ID of an opened joystick, if available.

If the vendor ID isn't available this function returns C<0>.

Expected parameters include:

=over

=item C<joystick> - the L<SDL2::Joystick> obtained from L<< C<SDL_JoystickOpen( ... )>|/C<SDL_JoystickOpen( ... )> >>

=back

Returns the USB vendor ID of the selected joystick, or C<0> if unavailable.

=head2 C<SDL_JoystickGetProduct( ... )>

Get the USB product ID of an opened joystick, if available.

If the product ID isn't available this function returns C<0>.

Expected parameters include:

=over

=item C<joystick> - the L<SDL2::Joystick> obtained from L<< C<SDL_JoystickOpen( ... )>|/C<SDL_JoystickOpen( ... )> >>

=back

Returns the USB product ID of the selected joystick, or C<0> if unavailable.

=head2 C<SDL_JoystickGetProductVersion( ... )>

Get the product version of an opened joystick, if available. If the product
version isn't available this function returns C<0>.

Expected parameters include:

=over

=item C<joystick> - the L<SDL2::Joystick> obtained from L<< C<SDL_JoystickOpen( ... )>|/C<SDL_JoystickOpen( ... )> >>

=back

Returns the product version of the selected joystick, or C<0> if unavailable.

=head2 C<SDL_JoystickGetSerial( ... )>

Get the serial number of an opened joystick, if available.

=over

=item C<joystick> - the L<SDL2::Joystick> obtained from L<< C<SDL_JoystickOpen( ... )>|/C<SDL_JoystickOpen( ... )> >>

=back

Returns the serial number of the joystick, or C<undef> if it is not available.

=head2 C<SDL_JoystickGetType( ... )>

Get the type of an opened joystick.

Expected parameters include:

=over

=item C<joystick> - the L<SDL2::Joystick> obtained from L<< C<SDL_JoystickOpen( ... )>|/C<SDL_JoystickOpen( ... )> >>

=back

Returns the C<SDL_JoystickType> of the selected joystick.

=head2 C<SDL_JoystickGetGUIDString( ... )>

Get an ASCII string representation for a given C<SDL_JoystickGUID>.

You should supply at least 33 bytes for pszGUID.

Expected parameters include:

=over

=item C<guid> - the C<SDL_JoystickGUID> you wish to convert to string

=item C<pszGUID> - buffer in which to write the ASCII string

=item C<cbGUID> - the size of pszGUID

=back

=head2 C<SDL_JoystickGetGUIDFromString( ... )>

Convert a GUID string into a C<SDL_JoystickGUID> structure.

Performs no error checking. If this function is given a string containing an
invalid GUID, the function will silently succeed, but the GUID generated will
not be useful.

Expected parameters include:

=over

=item C<pchGUID> - string containing an ASCII representation of a GUID

=back

Returns a C<SDL_JoystickGUID> structure.

=head2 C<SDL_JoystickGetAttached( ... )>

Get the status of a specified joystick.

Expected parameters include:

=over

=item C<joystick> - the L<joystick|SDL2::Joystick> to query

=back

Returns C<SDL_TRUE> if the joystick has been opened, C<SDL_FALSE> if it has
not; call C<SDL_GetError( )> for more information.

=head2 C<SDL_JoystickInstanceID( ... )>

Get the instance ID of an opened joystick.

Expected parameters include:

=over

=item C<joystick> - an L<SDL2::Joystick> structure containing joystick information

=back

Returns the instance ID of the specified joystick on success or a negative
error code on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_JoystickNumAxes( ... )>

Get the number of general axis controls on a joystick.

Often, the directional pad on a game controller will either look like 4
separate buttons or a POV hat, and not axes, but all of this is up to the
device and platform.

Expected parameters include:

=over

=item C<joystick> - an L<SDL2::Joystick> structure containing joystick information

=back

Returns the number of axis controls/number of axes on success or a negative
error code on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_JoystickNumBalls( ... )>

Get the number of trackballs on a joystick.

Joystick trackballs have only relative motion events associated with them and
their state cannot be polled.

Most joysticks do not have trackballs.

Expected parameters include:

=over

=item C<joystick> - an L<SDL2::Joystick> structure containing joystick information

=back

Returns the number of trackballs on success or a negative error code on
failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_JoystickNumHats( ... )>

Get the number of POV hats on a joystick.

Expected parameters include:

=over

=item C<joystick> - an L<SDL2::Joystick> structure containing joystick information

=back

Returns the number of POV hats on success or a negative error code on failure;
call C<SDL_GetError( )> for more information.

=head2 C<SDL_JoystickNumButtons( ... )>

Get the number of buttons on a joystick.

Expected parameters include:

=over

=item C<joystick> - an L<SDL2::Joystick> structure containing joystick information

=back

Returns the number of buttons on success or a negative error code on failure;
call C<SDL_GetError( )> for more information.

=head2 C<SDL_JoystickUpdate( )>

Update the current state of the open joysticks.

This is called automatically by the event loop if any joystick events are
enabled.

=head2 C<SDL_JoystickEventState( ... )>

Enable/disable joystick event polling.

If joystick events are disabled, you must call L<< C<SDL_JoystickUpdate(
)>|/C<SDL_JoystickUpdate( )> >> yourself and manually check the state of the
joystick when you want joystick information.

It is recommended that you leave joystick event handling enabled.

B<WARNING>: Calling this function may delete all events currently in SDL's
event queue.

Expected parameters include:

=over

=item C<state> - can be one of C<SDL_QUERY>, C<SDL_IGNORE>, or C<SDL_ENABLE>

=back

Returns C<1> if enabled, C<0> if disabled, or a negative error code on failure;
call C<SDL_GetError( )> for more information.

If C<state> is C<SDL_QUERY> then the current state is returned, otherwise the
new processing state is returned.

=head2 C<SDL_JoystickGetAxis( ... )>

Get the current state of an axis control on a joystick.

SDL makes no promises about what part of the joystick any given axis refers to.
Your game should have some sort of configuration UI to let users specify what
each axis should be bound to. Alternately, SDL's higher-level Game Controller
API makes a great effort to apply order to this lower-level interface, so you
know that a specific axis is the "left thumb stick," etc.

The value returned by L<< C<SDL_JoystickGetAxis( ... )>|/C<SDL_JoystickGetAxis(
... )> >> is a signed integer (C<-32768> to C<32767>) representing the current
position of the axis. It may be necessary to impose certain tolerances on these
values to account for jitter.

Expected parameters include:

=over

=item C<joystick> - an L<SDL2::Joystick> structure containing joystick information

=item C<axis> - the axis to query; the axis indices start at index C<0>

=back

Returns a 16-bit signed integer representing the current position of the axis
or 0 on failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_JoystickGetAxisInitialState( ... )>

Get the initial state of an axis control on a joystick.

The state is a value ranging from C<-32768> to C<32767>.

The axis indices start at index C<0>.

Expected parameters include:

=over

=item C<joystick> - an L<SDL2::Joystick> structure containing joystick information

=item C<axis> - the axis to query; the axis indices start at index C<0>

=item C<state> - upon return, the initial value is supplied here

=back

Return C<SDL_TRUE> if this axis has any initial value, or C<SDL_FALSE> if not.

=head2 C<SDL_JoystickGetHat>

Get the current state of a POV hat on a joystick.

The returned value will be one of the following positions:

=over

=item C<SDL_HAT_CENTERED>

=item C<SDL_HAT_UP>

=item C<SDL_HAT_RIGHT>

=item C<SDL_HAT_DOWN>

=item C<SDL_HAT_LEFT>

=item C<SDL_HAT_RIGHTUP>

=item C<SDL_HAT_RIGHTDOWN>

=item C<SDL_HAT_LEFTUP>

=item C<SDL_HAT_LEFTDOWN>

=back

Expected parameters include:

=over

=item C<joystick> - an L<SDL2::Joystick> structure containing joystick information

=item C<hat> - the hat index to get the state from; indices start at index C<0>

=back

Returns the current hat position.

=head2 C<SDL_JoystickGetBall( ... )>

Get the ball axis change since the last poll.

Trackballs can only return relative motion since the last call to L<<
C<SDL_JoystickGetBall( ... )>|/C<SDL_JoystickGetBall( ... )> >>, these motion
deltas are placed into C<dx> and C<dy>.

Most joysticks do not have trackballs.

Expected parameters include:

=over

=item C<joystick> - the L<SDL2::Joystick> to query

=item C<ball> - the ball index to query; ball indices start at index C<0>

=item C<dx> - stores the difference in the x axis position since the last poll

=item C<dy> - stores the difference in the y axis position since the last poll

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_JoystickGetButton( ... )>

Get the current state of a button on a joystick.

Expected parameters include:

=over

=item C<joystick> - an L<SDL2::Joystick> structure containing joystick information

=item C<button> - the button index to get the state from; indices start at index C<0>

=back

Returns C<1> if the specified button is pressed, C<0> otherwise.

=head2 C<SDL_JoystickRumble( ... )>

Start a rumble effect.

Each call to this function cancels any previous rumble effect, and calling it
with C<0> intensity stops any rumbling.

Expected parameters include:

=over

=item C<joystick> - the joystick to vibrate

=item C<low_frequency_rumble> - the intensity of the low frequency (left) rumble motor, from C<0> to C<0xFFFF>

=item C<high_frequency_rumble> - the intensity of the high frequency (right) rumble motor, from C<0> to C<0xFFFF>

=item C<duration_ms> - the duration of the rumble effect, in milliseconds

=back

Returns C<0>, or C<-1> if rumble isn't supported on this joystick.

=head2 C<SDL_JoystickRumbleTriggers( ... )>

Start a rumble effect in the joystick's triggers

Each call to this function cancels any previous trigger rumble effect, and
calling it with 0 intensity stops any rumbling.

Note that this function is for _trigger_ rumble; the first joystick to support
this was the PlayStation 5's DualShock 5 controller. If you want the (more
common) whole-controller rumble, use SDL_JoystickRumble() instead.

Expected parameters include:

=over

=item C<joystick> - the joystick to vibrate

=item C<left_rumble> - the intensity of the left trigger rumble motor, from C<0> to C<0xFFFF>

=item C<right_rumble> - the intensity of the right trigger rumble motor, from C<0> to C<0xFFFF>

=item C<duration_ms> - the duration of the rumble effect, in milliseconds

=back

Returns C<0>, or C<-1> if trigger rumble isn't supported on this joystick.

=head2 C<SDL_JoystickHasLED( ... )>

Query whether a joystick has an LED.

An example of a joystick LED is the light on the back of a PlayStation 4's
DualShock 4 controller.

Expected parameters include:

=over

=item C<joystick> - the joystick to query

=back

Return C<SDL_TRUE> if the joystick has a modifiable LED, C<SDL_FALSE>
otherwise.

=head2 C<SDL_JoystickSetLED( ... )>

Update a joystick's LED color.

An example of a joystick LED is the light on the back of a PlayStation 4's
DualShock 4 controller.

Expected parameters include:

=over

=item C<joystick> - the joystick to update

=item C<red> - the intensity of the red LED

=item C<green> - the intensity of the green LED

=item C<blue> - the intensity of the blue LED

=back

Returns C<0> on success, C<-1> if this joystick does not have a modifiable LED.

=head2 C<SDL_JoystickClose( ... )>

Close a joystick previously opened with L<< CC<SDL_JoystickOpen( ...
)>|/C<SDL_JoystickOpen( ... )> >>.

Expected parameters include:

=over

=item C<joystick> - the joystick device to close

=back

=head2 C<SDL_JoystickCurrentPowerLevel( ... )>

Get the battery level of a joystick as C<SDL_JoystickPowerLevel>.

Expected parameters include:

=over

=item C<joystick> - the L<SDL2::Joystick> to query

=back

Returns the current battery level as C<SDL_JoystickPowerLevel> on success or
C<SDL_JOYSTICK_POWER_UNKNOWN> if it is unknown

=head1 Defined Values and Enumerations

You may import these values by name or, unless another tag is given, with the
C<:joystick> tag.

=head2 C<SDL_JoystickType>

These values may be imported with the C<:joystickType> tag.

=over

=item C<SDL_JOYSTICK_TYPE_UNKNOWN>

=item C<SDL_JOYSTICK_TYPE_GAMECONTROLLER>

=item C<SDL_JOYSTICK_TYPE_WHEEL>

=item C<SDL_JOYSTICK_TYPE_ARCADE_STICK>

=item C<SDL_JOYSTICK_TYPE_FLIGHT_STICK>

=item C<SDL_JOYSTICK_TYPE_DANCE_PAD>

=item C<SDL_JOYSTICK_TYPE_GUITAR>

=item C<SDL_JOYSTICK_TYPE_DRUM_KIT>

=item C<SDL_JOYSTICK_TYPE_ARCADE_PAD>

=item C<SDL_JOYSTICK_TYPE_THROTTLE>

=back

=head2 C<SDL_JoystickPowerLevel>

These values by me imported with the C<:joystickPowerLevel> tag.

=over

=item C<SDL_JOYSTICK_POWER_UNKNOWN>

=item C<SDL_JOYSTICK_POWER_EMPTY> - C<< <= 5% >>

=item C<SDL_JOYSTICK_POWER_LOW> - C<< <= 20% >>

=item C<SDL_JOYSTICK_POWER_MEDIUM> - C<< <= 70% >>

=item C<SDL_JOYSTICK_POWER_FULL> - C<< <= 100% >>

=item C<SDL_JOYSTICK_POWER_WIRED>

=item C<SDL_JOYSTICK_POWER_MAX>

=back

=head2 C<SDL_IPHONE_MAX_GFORCE>

Set max recognized G-force from accelerometer. See
C<src/joystick/uikit/SDL_sysjoystick.m> for notes on why this is needed.

=head2 Axis limits

These may be imported with the C<:joystick> tag.

=over

=item C<SDL_JOYSTICK_AXIS_MAX>

=item C<SDL_JOYSTICK_AXIS_MIN>

=back

=head2 Hat Positions

These may be imported by name or with the C<:joystick> tag.

=over

=item C<SDL_HAT_CENTERED>

=item C<SDL_HAT_UP>

=item C<SDL_HAT_RIGHT>

=item C<SDL_HAT_DOWN>

=item C<SDL_HAT_LEFT>

=item C<SDL_HAT_RIGHTUP>

=item C<SDL_HAT_RIGHTDOWN>

=item C<SDL_HAT_LEFTUP>

=item C<SDL_HAT_LEFTDOWN>

=back


=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

bitwise scancoded scancodes N'th XInput JoystickGUID pszGUID

=end stopwords

=cut

};
1;
