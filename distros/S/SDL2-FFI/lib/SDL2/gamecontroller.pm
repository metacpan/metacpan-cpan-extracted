package SDL2::gamecontroller 0.01 {
    use SDL2::Utils;
    use experimental 'signatures';
    #
    use SDL2::stdinc;
    use SDL2::error;
    use SDL2::rwops;
    use SDL2::sensor;
    use SDL2::joystick;
    #
    package SDL2::GameController {
        use SDL2::Utils;
        our $TYPE = has();
    };
    enum SDL_GameControllerType => [
        [ SDL_CONTROLLER_TYPE_UNKNOWN => 0 ], qw[SDL_CONTROLLER_TYPE_XBOX360
            SDL_CONTROLLER_TYPE_XBOXONE
            SDL_CONTROLLER_TYPE_PS3
            SDL_CONTROLLER_TYPE_PS4
            SDL_CONTROLLER_TYPE_NINTENDO_SWITCH_PRO
            SDL_CONTROLLER_TYPE_VIRTUAL
            SDL_CONTROLLER_TYPE_PS5]
        ],
        SDL_GameControllerBindType => [
        [ SDL_CONTROLLER_BINDTYPE_NONE => 0 ], qw[SDL_CONTROLLER_BINDTYPE_BUTTON
            SDL_CONTROLLER_BINDTYPE_AXIS
            SDL_CONTROLLER_BINDTYPE_HAT]
        ],
        SDL_GameControllerAxis => [
        [ SDL_CONTROLLER_AXIS_INVALID => -1 ], qw[    SDL_CONTROLLER_AXIS_LEFTX
            SDL_CONTROLLER_AXIS_LEFTY
            SDL_CONTROLLER_AXIS_RIGHTX
            SDL_CONTROLLER_AXIS_RIGHTY
            SDL_CONTROLLER_AXIS_TRIGGERLEFT
            SDL_CONTROLLER_AXIS_TRIGGERRIGHT
            SDL_CONTROLLER_AXIS_MAX]
        ],
        SDL_GameControllerButton => [
        [ SDL_CONTROLLER_BUTTON_INVALID => -1 ], qw[ SDL_CONTROLLER_BUTTON_A
            SDL_CONTROLLER_BUTTON_B
            SDL_CONTROLLER_BUTTON_X
            SDL_CONTROLLER_BUTTON_Y
            SDL_CONTROLLER_BUTTON_BACK
            SDL_CONTROLLER_BUTTON_GUIDE
            SDL_CONTROLLER_BUTTON_START
            SDL_CONTROLLER_BUTTON_LEFTSTICK
            SDL_CONTROLLER_BUTTON_RIGHTSTICK
            SDL_CONTROLLER_BUTTON_LEFTSHOULDER
            SDL_CONTROLLER_BUTTON_RIGHTSHOULDER
            SDL_CONTROLLER_BUTTON_DPAD_UP
            SDL_CONTROLLER_BUTTON_DPAD_DOWN
            SDL_CONTROLLER_BUTTON_DPAD_LEFT
            SDL_CONTROLLER_BUTTON_DPAD_RIGHT
            SDL_CONTROLLER_BUTTON_MISC1
            SDL_CONTROLLER_BUTTON_PADDLE1
            SDL_CONTROLLER_BUTTON_PADDLE2
            SDL_CONTROLLER_BUTTON_PADDLE3
            SDL_CONTROLLER_BUTTON_PADDLE4
            SDL_CONTROLLER_BUTTON_TOUCHPAD
            SDL_CONTROLLER_BUTTON_MAX]
        ];

    package SDL2::GameControllerButtonBind {
        use SDL2::Utils;

        package SDL2::GameControllerButtonBind_Hat {
            use SDL2::Utils;
            our $TYPE = has
                hat      => 'int',
                hat_mask => 'int';
        };

        package SDL2::GameControllerButtonBind_Value {
            use SDL2::Utils;
            is 'Union';
            our $TYPE = has
                button => 'int',
                axis   => 'int',
                hat    => 'SDL_GameControllerButtonBind_Hat';    # GameControllerButtonBind_Hat
        };
        our $TYPE = has
            bindType => 'SDL_GameControllerBindType',
            value    => 'SDL_GameControllerButtonBind_Value';
    };
    attach gamecontroller => {
        SDL_GameControllerAddMappingsFromRW     => [ [ 'SDL_RWops', 'int', ], 'int' ],
        SDL_GameControllerAddMapping            => [ ['string'],              'int' ],
        SDL_GameControllerNumMappings           => [ [],                      'int' ],
        SDL_GameControllerMappingForIndex       => [ ['int'],                 'string' ],
        SDL_GameControllerMappingForGUID        => [ ['SDL_JoystickGUID'],    'string' ],
        SDL_GameControllerMapping               => [ ['SDL_GameController'],  'string' ],
        SDL_IsGameController                    => [ ['int'],                 'SDL_bool' ],
        SDL_GameControllerNameForIndex          => [ ['int'],                 'string' ],
        SDL_GameControllerTypeForIndex          => [ ['int'],            'SDL_GameControllerType' ],
        SDL_GameControllerMappingForDeviceIndex => [ ['int'],            'string' ],
        SDL_GameControllerOpen                  => [ ['int'],            'SDL_GameController' ],
        SDL_GameControllerFromInstanceID        => [ ['SDL_JoystickID'], 'SDL_GameController' ],
        SDL_GameControllerFromPlayerIndex       => [ ['int'],            'SDL_GameController' ],
        SDL_GameControllerName              => [ ['SDL_GameController'], 'string' ],
        SDL_GameControllerGetType           => [ ['SDL_GameController'], 'SDL_GameControllerType' ],
        SDL_GameControllerGetPlayerIndex    => [ ['SDL_GameController'], 'int' ],
        SDL_GameControllerSetPlayerIndex    => [ [ 'SDL_GameController', 'int' ] ],
        SDL_GameControllerGetVendor         => [ ['SDL_GameController'], 'uint16' ],
        SDL_GameControllerGetProduct        => [ ['SDL_GameController'], 'uint16' ],
        SDL_GameControllerGetProductVersion => [ ['SDL_GameController'], 'uint16' ],
        SDL_GameControllerGetSerial         => [ ['SDL_GameController'], 'string' ],
        SDL_GameControllerGetAttached       => [ ['SDL_GameController'], 'SDL_bool' ],
        SDL_GameControllerGetJoystick       => [ ['SDL_GameController'], 'SDL_Joystick' ],
        SDL_GameControllerEventState        => [ ['int'],                'int' ],
        SDL_GameControllerUpdate            => [ [] ],
        #
        SDL_GameControllerGetAxisFromString => [ ['string'], 'SDL_GameControllerAxis' ],
        SDL_GameControllerGetStringForAxis  => [ ['SDL_GameControllerAxis'], 'string' ],
        SDL_GameControllerGetBindForAxis    =>
            [ [ 'SDL_GameController', 'SDL_GameControllerAxis' ], 'SDL_GameControllerButtonBind' ],
        SDL_GameControllerHasAxis =>
            [ [ 'SDL_GameController', 'SDL_GameControllerAxis' ], 'SDL_bool' ],
        SDL_GameControllerGetAxis =>
            [ [ 'SDL_GameController', 'SDL_GameControllerAxis' ], 'sint16' ],
        #
        SDL_GameControllerGetButtonFromString => [ ['string'], 'SDL_GameControllerButton' ],
        SDL_GameControllerGetStringForButton  => [ ['SDL_GameControllerButton'], 'string' ],
        SDL_GameControllerGetBindForButton    => [
            [ 'SDL_GameController', 'SDL_GameControllerButton' ], 'SDL_GameControllerButtonBind'
        ],
        SDL_GameControllerHasButton =>
            [ [ 'SDL_GameController', 'SDL_GameControllerButton' ], 'SDL_bool' ],
        SDL_GameControllerGetButton =>
            [ [ 'SDL_GameController', 'SDL_GameControllerButton' ], 'uint8' ],
        SDL_GameControllerGetNumTouchpads       => [ ['SDL_GameController'],          'int' ],
        SDL_GameControllerGetNumTouchpadFingers => [ [ 'SDL_GameController', 'int' ], 'int' ],
        SDL_GameControllerGetTouchpadFinger     => [
            [ 'SDL_GameController', 'int', 'int', 'uint8*', 'uint8*', 'uint8*', 'float*' ], 'int'
        ],
        SDL_GameControllerHasSensor => [ [ 'SDL_GameController', 'SDL_SensorType' ], 'SDL_bool' ],
        SDL_GameControllerSetSensorEnabled =>
            [ [ 'SDL_GameController', 'SDL_SensorType', 'SDL_bool' ], 'int' ],
        SDL_GameControllerIsSensorEnabled =>
            [ [ 'SDL_GameController', 'SDL_SensorType' ], 'SDL_bool' ],
        SDL_GameControllerGetSensorData =>
            [ [ 'SDL_GameController', 'SDL_SensorType', 'float*', 'int' ], 'int' ],
        SDL_GameControllerRumble =>
            [ [ 'SDL_GameController', 'uint16', 'uint16', 'uint16' ], 'int' ],
        SDL_GameControllerRumbleTriggers =>
            [ [ 'SDL_GameController', 'uint16', 'uint16', 'uint32' ], 'int' ],
        SDL_GameControllerHasLED => [ ['SDL_GameController'], 'SDL_bool' ],
        SDL_GameControllerSetLED => [ [ 'SDL_GameController', 'uint8', 'uint8', 'uint8' ], 'int' ],
        SDL_GameControllerClose  => [ ['SDL_GameController'] ],
    };
    define gamecontroller => [
        [   SDL_GameControllerAddMappingsFromFile => sub ($file) {
                SDL2::FFI::SDL_GameControllerAddMappingsFromRW(
                    SDL2::FFI::SDL_RWFromFile( $file, 'rb' ), 1 );
            }
        ]
    ];

=encoding utf-8

=head1 NAME

SDL2::gamecontroller - SDL Game Controller Event Handling

=head1 SYNOPSIS

    use SDL2 qw[:gamecontroller];

=head1 DESCRIPTION

In order to use these functions, C<SDL_Init( ... )> must have been called with
the C<SDL_INIT_GAMECONTROLLER> flag.  This causes SDL to scan the system for
game controllers, and load appropriate drivers.

If you would like to receive controller updates while the application is in the
background, you should set the following hint before calling C<SDL_Init( ...
)>: C<SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS>.

=head1 Functions

These may be imported by name or with the C<:gamecontroller> tag.

=head2 C<SDL_GameControllerAddMappingsFromRW( ... )>

Load a set of Game Controller mappings from a seekable SDL data stream.

You can call this function several times, if needed, to load different database
files.

If a new mapping is loaded for an already known controller GUID, the later
version will overwrite the one currently loaded.

Mappings not belonging to the current platform or with no platform field
specified will be ignored (i.e. mappings for Linux will be ignored in Windows,
etc).

This function will load the text database entirely in memory before processing
it, so take this into consideration if you are in a memory constrained
environment.

Expected parameters include:

=over

=item C<rw> - the data stream for the mappings to be added

=item C<freerw> - non-zero to close the stream after being read

=back

Returns the number of mappings added or C<-1> on error; call C<SDL_GetError( )>
for more information.

=head2 C<SDL_GameControllerAddMappingsFromRW( ... )>

Load a set of mappings from a file, filtered by the current C<SDL_GetPlatform(
)>.

	SDL_GameControllerAddMappingsFromFile( 'gamecontrollerdb.txt' );

Expected parameters include:

=over

=item C<file> - the name of the database you want to load

=back

Returns the number of mappings added or C<-1> on error; call C<SDL_GetError( )>
for more information.

=head2 C<SDL_GameControllerAddMapping( ... )>

Add support for controllers that SDL is unaware of or to cause an existing
controller to have a different binding.

The mapping string has the format "GUID,name,mapping", where GUID is the string
value from C<SDL_JoystickGetGUIDString( ... )>, name is the human readable
string for the device and mappings are controller mappings to joystick ones.
Under Windows there is a reserved GUID of "xinput" that covers all XInput
devices. The mapping format for joystick is:

	{| |bX |a joystickbutton, index X |- |hX.Y |hat X with value Y |- |aX |axis X of the joystick|}

Buttons can be used as a controller axes and vice versa.

This string shows an example of a valid mapping for a controller:

	341a3608000000000000504944564944,Afterglow PS3 Controller,a:b1,b:b2,y:b3,x:b0,start:b9,guide:b12,back:b8,dpup:h0.1,dpleft:h0.8,dpdown:h0.4,dpright:h0.2,leftshoulder:b4,rightshoulder:b5,leftstick:b10,rightstick:b11,leftx:a0,lefty:a1,rightx:a2,righty:a3,lefttrigger:b6,righttrigger:b7

Expected parameters include:

=over

=item C<mappingString> - the mapping string

=back

Returns C<1> if a new mapping is added, C<0> if an existing mapping is updated,
C<-1> on error; call C<SDL_GetError( )> for more information.

=head2 C<SDL_GameControllerNumMappings( )>

Get the number of mappings installed.

Returns the number of mappings.

=head2 C<SDL_GameControllerMappingForIndex( ... )>

Get the mapping at a particular index.

Returns the mapping string.  Must be freed with C<SDL_free( ... )>. Returns
C<undef> if the index is out of range.

=head2 C<SDL_GameControllerMappingForGUID( ... )>

Get the game controller mapping string for a given GUID.

The returned string must be freed with C<SDL_free( ... )>.

Expected parameters include:

=over

=item C<guid> - a structure containing the GUID for which a mapping is desired

=back

Returns a mapping string or NULL on error; call C<SDL_GetError( )> for more
information.

=head2 C<SDL_GameControllerMapping( ... )>

Get the current mapping of a Game Controller.

The returned string must be freed with C<SDL_free( ... )>.

Details about mappings are discussed with L<< C<SDL_GameControllerAddMapping(
... )>|/C<SDL_GameControllerAddMapping( ... )> >>.

Expected parameters include:

=over

=item C<gamecontroller> - the game controller you want to get the current mapping for

=back

Returns a string that has the controller's mapping or C<undef> if no mapping is
available; call C<SDL_GetError( )> for more information.

=head2 C<SDL_IsGameController( ... )>

Check if the given joystick is supported by the game controller interface.

C<joystick_index> is the same as the C<device_index> passed to L<<
C<SDL_JoystickOpen( ... )>|SDL2::joystick/C<SDL_JoystickOpen( ... )> >>.

Expected parameters include:

=over

=item C<joystick_index> - the C<device_index> of a device, up to L<< C<SDL_NumJoysticks( )>|SDL2::joystick/C<SDL_NumJoysticks( )> >>

=back

Returns C<SDL_TRUE> if the given joystick is supported by the game controller
interface, C<SDL_FALSE> if it isn't or it's an invalid index.

=head2 C<SDL_GameControllerNameForIndex( ... )>

Get the implementation dependent name for the game controller.

This function can be called before any controllers are opened.

C<joystick_index> is the same as the C<device_index> passed to L<<
C<SDL_JoystickOpen( ... )>|SDL2::joystick/C<SDL_JoystickOpen( ... )> >>.

Expected parameters include:

=over

=item C<joystick_index> - the device_index of a device, from zero to C<SDL_NumJoysticks( ) - 1>

=back

Returns the implementation-dependent name for the game controller, or C<undef>
if there is no name or the index is invalid.

=head2 C<SDL_GameControllerTypeForIndex( ... )>

Get the type of a game controller.

This can be called before any controllers are opened.

Expected parameters include:

=over

=item C<joystick_index> - the device_index of a device, from zero to C<SDL_NumJoysticks( ) - 1>

=back

Returns the controller type.

=head2 C<SDL_GameControllerMappingForDeviceIndex( ... )>

Get the mapping of a game controller.

This can be called before any controllers are opened.

Expected parameters include:

=over

=item C<joystick_index> - the device_index of a device, from zero to C<SDL_NumJoysticks( ) - 1>

=back

Returns the mapping string. Must be freed with C<SDL_free( ... )>. Returns
C<undef> if no mapping is available.

=head2 C<SDL_GameControllerOpen( ... )>

Open a game controller for use.

C<joystick_index> is the same as the C<device_index> passed to L<<
C<SDL_JoystickOpen( ... )>|SDL2::joystick/C<SDL_JoystickOpen( ... )> >>.

The index passed as an argument refers to the N'th game controller on the
system. This index is not the value which will identify this controller in
future controller events. The joystick's instance id (C<SDL_JoystickID>) will
be used there instead.

Expected parameters include;

=over

=item C<joystick_index> - the device_index of a device, up to L<< C<SDL_NumJoysticks( )>|SDL2::joystick/C<SDL_NumJoysticks( )> >>

=back

Returns a gamecontroller identifier or C<undef> if an error occurred; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GameControllerFromInstanceID( ... )>

Get the SDL_GameController associated with an instance id.

Expected parameters include:

=over

=item C<joyid> - the instance id to get the C<SDL2::GameController> for

=back

Returns an L<SDL2::GameController> on success or C<undef> on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GameControllerFromPlayerIndex( ... )>

Get the L<SDL2::GameController> associated with a player index.

Please note that the player index is _not_ the device index, nor is it the
instance id!

Expected parameters include:

=over

=item C<player_index> - the player index (which is not the device index or the instance id)

=back

Returns the L<SDL2::GameController> associated with a player index.

=head2 C<SDL_GameControllerName( ... )>

Get the implementation-dependent name for an opened game controller.

This is the same name as returned by SDL_GameControllerNameForIndex(), but it
takes a controller identifier instead of the (unstable) device index.

Expected parameters include:

=over

=item C<gamecontroller> a game controller identifier previously returned by L<< C<SDL_GameControllerOpen( ... )>|/C<SDL_GameControllerOpen( ... )> >>

=back

Returns the implementation dependent name for the game controller, or C<undef>
if there is no name or the identifier passed is invalid.

=head2 C<SDL_GameControllerGetType( ... )>

Get the type of this currently opened controller

This is the same name as returned by L<< C<SDL_GameControllerTypeForIndex( ...
)>|/C<SDL_GameControllerTypeForIndex( ... )> >>, but it takes a controller
identifier instead of the (unstable) device index.

Expected parameters include:

=over

=item C<gamecontroller> - the game controller object to query

=back

Returns the controller type.

=head2 C<SDL_GameControllerGetPlayerIndex( ... )>

Get the player index of an opened game controller.

For XInput controllers this returns the XInput user index.

Expected parameters include:

=over

=item C<gamecontroller> - the game controller object to query

=back

Returns player index for controller, or C<-1> if it's not available.

=head2 C<SDL_GameControllerSetPlayerIndex( ... )>

Set the player index of an opened game controller.

Expected parameters include:

=over

=item C<gamecontroller> - the game controller object to adjust

=item C<player_index> - player index to assign to this controller

=back

=head2 C<SDL_GameControllerGetVendor( ... )>

Get the USB vendor ID of an opened controller, if available.

If the vendor ID isn't available this function returns 0.

Expected parameters include:

=over

=item C<gamecontroller> - the game controller object to query

=back

Return USB vendor ID, or zero if unavailable.

=head2 C<SDL_GameControllerGetProduct( ... )>

Get the USB product ID of an opened controller, if available.

If the product ID isn't available this function returns 0.

Expected parameters include:

=over

=item C<gamecontroller> - the game controller object to query

=back

Return USB product ID, or zero if unavailable.

=head2 C<SDL_GameControllerGetProductVersion( ... )>

Get the product version of an opened controller, if available.

If the product version isn't available this function returns 0.

Expected parameters include:

=over

=item C<gamecontroller> - the game controller object to query

=back

Return USB product version, or zero if unavailable.

=head2 C<SDL_GameControllerGetSerial( ... )>

Get the serial number of an opened controller, if available.

Returns the serial number of the controller, or C<undef> if it is not
available.

Expected parameters include:

=over

=item C<gamecontroller> - the game controller object to query

=back

Returns a serial number, or C<undef> if unavailable.

=head2 C<SDL_GameControllerGetAttached( ... )>

Check if a controller has been opened and is currently connected.

Expected parameters include:

=over

=item C<gamecontroller> - a game controller identifier previously returned by L<< C<SDL_GameControllerOpen( ... )>|/C<SDL_GameControllerOpen( ... )> >>

=back

Returns C<SDL_TRUE> if the controller has been opened and is currently
connected, or C<SDL_FALSE> if not.



=head2 C<SDL_GameControllerGetJoystick( ... )>

Get the Joystick ID from a Game Controller.

This function will give you a L<SDL2::Joystick> object, which allows you to use
the L<SDL2::Joystick> functions with a L<SDL2::GameController> object. This
would be useful for getting a joystick's position at any given time, even if it
hasn't moved (moving it would produce an event, which would have the axis'
value).

The pointer returned is owned by the L<SDL2::GameController>. You should not
call L<< C<SDL_JoystickClose( ... )>|SDL2::joystick/C<SDL_JoystickClose( ... )>
>> on it, for example, since doing so will likely cause SDL to crash.

Expected parameters include:

=over

=item C<gamecontroller> - the game controller object that you want to get a joystick from

=back

Returns a L<SDL2::Joystick> object; call C<SDL_GetError( )> for more
information.

=head2 C<SDL_GameControllerEventState( ... )>

Query or change current state of Game Controller events.

If controller events are disabled, you must call L<<
C<SDL_GameControllerUpdate( )>|/C<SDL_GameControllerUpdate( )> >> yourself and
check the state of the controller when you want controller information.

Any number can be passed to C<SDL_GameControllerEventState( ... )>, but only
C<-1>, C<0>, and C<1> will have any effect. Other numbers will just be
returned.

=over

=item C<state> - can be one of C<SDL_QUERY>, C<SDL_IGNORE>, or C<SDL_ENABLE>

=back

Returns the same value passed to the function, with exception to C<-1>
(C<SDL_QUERY>), which will return the current state.

=head2 C<SDL_GameControllerUpdate( )>

Manually pump game controller updates if not using the loop.

This function is called automatically by the event loop if events are enabled.
Under such circumstances, it will not be necessary to call this function.

=head2 C<SDL_GameControllerGetAxisFromString( ... )>

Convert a string into L<< C<SDL_GameControllerAxis>|/C<SDL_GameControllerAxis>
>> enum.

This function is called internally to translate L<SDL2::GameController> mapping
strings for the underlying joystick device into the consistent
L<SDL2::GameController> mapping. You do not normally need to call this function
unless you are parsing L<SDL2::GameController> mappings in your own code.

Expected parameters include:

=over

=item C<str> - string representing a L<SDL2::GameController> axis

=back

Returns the L<< C<SDL_GameControllerAxis>|/C<SDL_GameControllerAxis> >> enum
corresponding to the input string, or C<SDL_CONTROLLER_AXIS_INVALID> if no
match was found.

=head2 C<SDL_GameControllerGetStringForAxis( ... )>

Convert from an SDL_GameControllerAxis enum to a string.

The caller should not C<SDL_free( ... )> the returned string.

Expected parameters include:

=over

=item C<axis> - an enum value for a given L<< C<SDL_GameControllerAxis>|/C<SDL_GameControllerAxis> >>

=back

Returns a string for the given axis, or C<undef> if an invalid axis is
specified. The string returned is of the format used by L<SDL2::GameController>
mapping strings.

=head2 C<SDL_GameControllerGetBindForAxis( ... )>

Get the SDL joystick layer binding for a controller axis mapping.

Expected parameters include:

=over

=item C<gamecontroller> - a game controller

=item C<axis> - an axis enum value (one of the L<< C<SDL_GameControllerAxis>|/C<SDL_GameControllerAxis> >> values)

=back

Returns a L<SDL2::GameControllerButtonBind> describing the bind. On failure
(like the given Controller axis doesn't exist on the device), its C<bindType>
will be C<SDL_CONTROLLER_BINDTYPE_NONE>.

=head2 C<SDL_GameControllerHasAxis( ... )>

Query whether a game controller has a given axis.

This merely reports whether the controller's mapping defined this axis, as that
is all the information SDL has about the physical device.

Expected parameters include:

=over

=item C<gamecontroller> - a game controller

=item C<axis> - an axis enum value (an L<< C<SDL_GameControllerAxis>|/C<SDL_GameControllerAxis> >> value)

=back

Returns C<SDL_TRUE> if the controller has this axis, C<SDL_FALSE> otherwise.

=head2 C<SDL_GameControllerGetAxis( ... )>

Get the current state of an axis control on a game controller.

The axis indices start at index C<0>.

The state is a value ranging from C<-32768> to C<32767>. Triggers, however,
range from C<0> to C<32767> (they never return a negative value).

Expected parameters include:

=over

=item C<gamecontroller> - a game controller

=item C<axis> - an axis index (one of the L<< C<SDL_GameControllerAxis>|/C<SDL_GameControllerAxis> >> values)

=back

Returns axis state (including C<0>) on success or C<0> (also) on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GameControllerGetButtonFromString( ... )>

Convert a string into an C<SDL_GameControllerButton> enum.

This function is called internally to translate L<SDL2::GameController> mapping
strings for the underlying joystick device into the consistent
L<SDL2::GameController> mapping. You do not normally need to call this function
unless you are parsing L<SDL2::GameController> mappings in your own code.

Expected parameters include:

=over

=item C<str> - string representing a L<SDL2::GameController> axis

=back

Returns the C<SDL_GameControllerButton> enum corresponding to the input string,
or C<SDL_CONTROLLER_AXIS_INVALID> if no match was found.

=head2 C<SDL_GameControllerGetStringForButton( ... )>

Convert from an C<SDL_GameControllerButton> enum to a string.

The caller should not C<SDL_free( )> the returned string.

Expected parameters include:

=over

=item C<button> - an enum value for a given L<SDL2::GameControllerButton>

=back

Returns a string for the given button, or C<undef> if an invalid axis is
specified. The string returned is of the format used by L<SDL2::GameController>
mapping strings.

=head2 C<SDL_GameControllerGetBindForButton( ... )>

Get the SDL joystick layer binding for a controller button mapping.

Expected parameters includes:

=over

=item C<gamecontroller> - a game controller

=item C<button> - an button enum value (an C<SDL_GameControllerButton> value)

=back

Returns a C<SDL_GameControllerButtonBind> describing the bind. On failure (like
the given Controller button doesn't exist on the device), its C<bindType> will
be C<SDL_CONTROLLER_BINDTYPE_NONE>.

=head2 C<SDL_GameControllerHasButton( ... )>

Query whether a game controller has a given button.

This merely reports whether the controller's mapping defined this button, as
that is all the information SDL has about the physical device.

Expected parameters include:

=over

=item C<gamecontroller> - a game controller

=item C<button> - a button enum value (an C<SDL_GameControllerButton> value)

=back

Returns C<SDL_TRUE> if the controller has this button, C<SDL_FALSE> otherwise.

=head2 C<SDL_GameControllerGetButton( ... )>

Get the current state of a button on a game controller.

Expected parameters include:

=over

=item C<gamecontroller> - a game controller

=item C<button> - a button index (one of the SDL_GameControllerButton values)

=back

Returns C<1> for pressed state or C<0> for not pressed state or error; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GameControllerGetNumTouchpads( ... )>

Get the number of touchpads on a game controller.

Expected parameters include:

=over

=item C<gamecontroller> - a game controller

=back

Returns the number of touchpads.


=head2 C<SDL_GameControllerGetNumTouchpadFingers( ... )>

Get the number of supported simultaneous fingers on a touchpad on a game
controller.

Expected parameters include:

=over

=item C<gamecontroller> - a game controller

=item C<touchpad> - index of the touchpad to query

=back

Returns the number of supported simultaneous fingers.

=head2 C<SDL_GameControllerGetTouchpadFinger( ... )>

Get the current state of a finger on a touchpad on a game controller.

Expected parameters include:

=over

=item C<gamecontroller> - a game controller

=item C<touchpad> - touchpad index to query

=item C<finger> - finger index to query

=item C<state> - pointer

=item C<x> - pointer

=item C<y> - pointer

=item C<pressure> - pointer

=back

Returns C<0> if the given finger is defined on the given touchpad on the given
controller, C<-1> otherwise.

=head2 C<SDL_GameControllerHasSensor( ... )>

Return whether a game controller has a particular sensor.

Expected parameters include:

=over

=item C<gamecontroller> - the controller to query

=item C<type> - the type of sensor to query

=back

Returns C<SDL_TRUE> if the sensor exists, C<SDL_FALSE> otherwise.

=head2 C<SDL_GameControllerSetSensorEnabled( ... )>

Set whether data reporting for a game controller sensor is enabled.

Expected parameters include:

=over

=item C<gamecontroller> - the controller to update

=item C<type>  - the type of sensor to enable/disable

=item C<enabled> - whether data reporting should be enabled

=back

Returns C<0> or C<-1> if an error occurred.

=head2 C<SDL_GameControllerIsSensorEnabled( ... )>

Query whether sensor data reporting is enabled for a game controller.

Expected parameters include:

=over

=item C<gamecontroller> - the controller to query

=item C<type> - the type of sensor to query

=back

Returns C<SDL_TRUE> if the sensor is enabled, C<SDL_FALSE> otherwise.

=head2 C<SDL_GameControllerGetSensorData( ... )>

Get the current state of a game controller sensor.

The number of values and interpretation of the data is sensor dependent. See
C<SDL_sensor.h> for the details for each type of sensor.

Expected parameters include;

=over

=item C<gamecontroller> - the controller to query

=item C<type> - the type of sensor to query

=item C<data> - a pointer filled with the current sensor state

=item C<num_values> - the number of values to write to data

=back

Return C<0> or C<-1> if an error occurred.

=head2 C<SDL_GameControllerRumble( ... )>

Start a rumble effect on a game controller.

Each call to this function cancels any previous rumble effect, and calling it
with 0 intensity stops any rumbling.

Expected parameters include:

=over

=item C<gamecontroller> - the controller to vibrate

=item C<low_frequency_rumble> - the intensity of the low frequency (left) rumble motor, from C<0> to C<0xFFFF>

=item C<high_frequency_rumble> - the intensity of the high frequency (right) rumble motor, from C<0> to C<0xFFFF>

=item C<duration_ms> - the duration of the rumble effect, in milliseconds

=back

Returns C<0>, or C<-1> if rumble isn't supported on this controller

=head2 C<SDL_GameControllerRumbleTriggers( ... )>

Start a rumble effect in the game controller's triggers.

Each call to this function cancels any previous trigger rumble effect, and
calling it with 0 intensity stops any rumbling.

Note that this is rumbling of the _triggers_ and not the game controller as a
whole. The first controller to offer this feature was the PlayStation 5's
DualShock 5.

Expected parameters include:

=over

=item C<gamecontroller> - the controller to vibrate

=item C<left_rumble> - the intensity of the left trigger rumble motor, from C<0> to C<0xFFFF>

=item C<right_rumble> - the intensity of the right trigger rumble motor, from C<0> to C<0xFFFF>

=item C<duration_ms> - the duration of the rumble effect, in milliseconds

=back

Returns C<0>, or C<-1> if trigger rumble isn't supported on this controller.

=head2 C<SDL_GameControllerHasLED( ... )>

Query whether a game controller has an LED.

Expected parameters include:

=over

=item C<gamecontroller> - the controller to query

=back

Returns C<SDL_TRUE>, or C<SDL_FALSE> if this controller does not have a
modifiable LED.

=head2 C<SDL_GameControllerSetLED( ... )>

Update a game controller's LED color.

Expected parameters include:

=over

=item C<gamecontroller> - the controller to update

=item C<red> - the intensity of the red LED

=item C<green> - the intensity of the green LED

=item C<blue> - the intensity of the blue LED

=back

Returns C<0>, or C<-1> if this controller does not have a modifiable LED

=head2 C<SDL_GameControllerClose( ... )>

Close a game controller previously opened with L<< C<SDL_GameControllerOpen(
... )>|/C<SDL_GameControllerOpen( ... )> >>.

Expected parameters include:

=over

=item C<gamecontroller> - a game controller identifier previously returned by L<< C<SDL_GameControllerOpen( ... )>|/C<SDL_GameControllerOpen( ... )> >>

=back

=head1 Defined Values and Enumerations

These may be imported by name or with the given tag.

=head2 C<SDL_GameControllerType>

=over

=item C<SDL_CONTROLLER_TYPE_UNKNOWN>

=item C<SDL_CONTROLLER_TYPE_XBOX360>

=item C<SDL_CONTROLLER_TYPE_XBOXONE>

=item C<SDL_CONTROLLER_TYPE_PS3>

=item C<SDL_CONTROLLER_TYPE_PS4>

=item C<SDL_CONTROLLER_TYPE_NINTENDO_SWITCH_PRO>

=item C<SDL_CONTROLLER_TYPE_VIRTUAL>

=item C<SDL_CONTROLLER_TYPE_PS5>

=back

=head2 C<SDL_GameControllerBindType>

=over

=item C<SDL_CONTROLLER_BINDTYPE_NONE>

=item C<SDL_CONTROLLER_BINDTYPE_BUTTON>

=item C<SDL_CONTROLLER_BINDTYPE_AXIS>

=item C<SDL_CONTROLLER_BINDTYPE_HAT>

=back

=head2 C<SDL_GameControllerAxis>

The list of axes available from a controller

Thumbstick axis values range from C<SDL_JOYSTICK_AXIS_MIN> to
C<SDL_JOYSTICK_AXIS_MAX>, and are centered within ~8000 of zero, though
advanced UI will allow users to set or autodetect the dead zone, which varies
between controllers.

Trigger axis values range from C<0> to C<SDL_JOYSTICK_AXIS_MAX>.

=over

=item C<SDL_CONTROLLER_AXIS_INVALID>

=item C<SDL_CONTROLLER_AXIS_LEFTX>

=item C<SDL_CONTROLLER_AXIS_LEFTY>

=item C<SDL_CONTROLLER_AXIS_RIGHTX>

=item C<SDL_CONTROLLER_AXIS_RIGHTY>

=item C<SDL_CONTROLLER_AXIS_TRIGGERLEFT>

=item C<SDL_CONTROLLER_AXIS_TRIGGERRIGHT>

=item C<SDL_CONTROLLER_AXIS_MAX>

=back

=head2 C<SDL_GameControllerButton>

The list of buttons available from a controller.

=over

=item C<SDL_CONTROLLER_BUTTON_INVALID>

=item C<SDL_CONTROLLER_BUTTON_A>

=item C<SDL_CONTROLLER_BUTTON_B>

=item C<SDL_CONTROLLER_BUTTON_X>

=item C<SDL_CONTROLLER_BUTTON_Y>

=item C<SDL_CONTROLLER_BUTTON_BACK>

=item C<SDL_CONTROLLER_BUTTON_GUIDE>

=item C<SDL_CONTROLLER_BUTTON_START>

=item C<SDL_CONTROLLER_BUTTON_LEFTSTICK>

=item C<SDL_CONTROLLER_BUTTON_RIGHTSTICK>

=item C<SDL_CONTROLLER_BUTTON_LEFTSHOULDER>

=item C<SDL_CONTROLLER_BUTTON_RIGHTSHOULDER>

=item C<SDL_CONTROLLER_BUTTON_DPAD_UP>

=item C<SDL_CONTROLLER_BUTTON_DPAD_DOWN>

=item C<SDL_CONTROLLER_BUTTON_DPAD_LEFT>

=item C<SDL_CONTROLLER_BUTTON_DPAD_RIGHT>

=item C<SDL_CONTROLLER_BUTTON_MISC1> - Xbox Series X share button, PS5 microphone button, Nintendo Switch Pro capture button

=item C<SDL_CONTROLLER_BUTTON_PADDLE1> - Xbox Elite paddle P1

=item C<SDL_CONTROLLER_BUTTON_PADDLE2> - Xbox Elite paddle P3

=item C<SDL_CONTROLLER_BUTTON_PADDLE3> - Xbox Elite paddle P2

=item C<SDL_CONTROLLER_BUTTON_PADDLE4> - Xbox Elite paddle P4

=item C<SDL_CONTROLLER_BUTTON_TOUCHPAD> - PS4/PS5 touchpad button

=item C<SDL_CONTROLLER_BUTTON_MAX>

=back

=head2 Notes

To count the number of game controllers in the system for the following:

	my $nJoysticks = SDL_NumJoysticks();
	my $nGameControllers = 0;
	for my $i (0 .. $nJoysticks) {
		$nGameControllers++ if SDL_IsGameController($i);
	}

Using the C<SDL_HINT_GAMECONTROLLERCONFIG> hint or the L<<
C<SDL_GameControllerAddMapping( ... )>|/C<SDL_GameControllerAddMapping( ... )>
>> you can add support for controllers SDL is unaware of or cause an existing
controller to have a different binding. The format is: C<guid,name,mappings>,

Where GUID is the string value from C<SDL_JoystickGetGUIDString( ... )>, name
is the human readable string for the device and mappings are controller
mappings to joystick ones. Under Windows there is a reserved GUID of "xinput"
that covers any XInput devices. The mapping format for joystick is:

=over

=item C<bX> - a joystick button, index X

=item C<hX.Y> - hat X with value Y

=item C<aX> - axis X of the joystick

=back

Buttons can be used as a controller axis and vice versa.

This string shows an example of a valid mapping for a controller

	03000000341a00003608000000000000,PS3 Controller,a:b1,b:b2,y:b3,x:b0,start:b9,guide:b12,back:b8,dpup:h0.1,dpleft:h0.8,dpdown:h0.4,dpright:h0.2,leftshoulder:b4,rightshoulder:b5,leftstick:b10,rightstick:b11,leftx:a0,lefty:a1,rightx:a2,righty:a3,lefttrigger:b6,righttrigger:b7

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

xinput versa N'th touchpads autodetect

=end stopwords

=cut

};
1;
