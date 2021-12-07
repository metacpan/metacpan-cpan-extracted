package SDL2::events 0.01 {
    use strict;
    use warnings;
    use SDL2::Utils;
    use experimental 'signatures';
    #
    use SDL2::stdinc;
    use SDL2::error;
    use SDL2::video;
    use SDL2::keyboard;
    use SDL2::mouse;
    use SDL2::joystick;
    use SDL2::gamecontroller;
    use SDL2::quit;
    use SDL2::gesture;
    use SDL2::touch;
    #
    use SDL2::version;    # Not in upstream header but required for SDL_version
    use SDL2::syswm;      # Header is not included by default but let's make life easy on folks

    #
    define events      => [ [ SDL_RELEASED => 0 ], [ SDL_PRESSED => 1 ] ];
    enum SDL_EventType => [
        [ SDL_FIRSTEVENT => 0 ], [ SDL_QUIT => 0x100 ],

        # These application events have special meaning on iOS, see README-ios.md for details
        qw[SDL_APP_TERMINATING
            SDL_APP_LOWMEMORY
            SDL_APP_WILLENTERBACKGROUND
            SDL_APP_DIDENTERBACKGROUND
            SDL_APP_WILLENTERFOREGROUND
            SDL_APP_DIDENTERFOREGROUND],
        #
        'SDL_LOCALECHANGED',

        #Display events
        [ SDL_DISPLAYEVENT => 0x150 ],

        # Window events
        [ SDL_WINDOWEVENT => 0x200 ], 'SDL_SYSWMEVENT',

        # Keyboard events
        [ SDL_KEYDOWN => 0x300 ], qw[SDL_KEYUP
            SDL_TEXTEDITING
            SDL_TEXTINPUT
            SDL_KEYMAPCHANGED],

        # Mouse events
        [ SDL_MOUSEMOTION => 0x400 ], qw[SDL_MOUSEBUTTONDOWN
            SDL_MOUSEBUTTONUP
            SDL_MOUSEWHEEL],

        # Joystick events
        [ SDL_JOYAXISMOTION => 0x600 ], qw[SDL_JOYBALLMOTION
            SDL_JOYHATMOTION
            SDL_JOYBUTTONDOWN
            SDL_JOYBUTTONUP
            SDL_JOYDEVICEADDED
            SDL_JOYDEVICEREMOVED],

        # Game controller events
        [ SDL_CONTROLLERAXISMOTION => 0x650 ], qw[SDL_CONTROLLERBUTTONDOWN
            SDL_CONTROLLERBUTTONUP
            SDL_CONTROLLERDEVICEADDED
            SDL_CONTROLLERDEVICEREMOVED
            SDL_CONTROLLERDEVICEREMAPPED
            SDL_CONTROLLERTOUCHPADDOWN
            SDL_CONTROLLERTOUCHPADMOTION
            SDL_CONTROLLERTOUCHPADUP
            SDL_CONTROLLERSENSORUPDATE],

        # Touch events
        [ SDL_FINGERDOWN => 0x700 ], qw[SDL_FINGERUP
            SDL_FINGERMOTION],

        # Gesture events
        [ SDL_DOLLARGESTURE => 0x800 ], qw[SDL_DOLLARRECORD
            SDL_MULTIGESTURE],

        # Clipboard events
        [ SDL_CLIPBOARDUPDATE => 0x900 ],

        # Drag and drop events
        [ SDL_DROPFILE => 0x1000 ], qw[SDL_DROPTEXT
            SDL_DROPBEGIN
            SDL_DROPCOMPLETE],

        # Audio hotplug events
        [ SDL_AUDIODEVICEADDED => 0x1100 ], 'SDL_AUDIODEVICEREMOVED',

        # Sensor events
        [ SDL_SENSORUPDATE => 0x1200 ],

        # Render events
        [ SDL_RENDER_TARGETS_RESET => 0x2000 ], 'SDL_RENDER_DEVICE_RESET',

        # Events ::SDL_USEREVENT through ::SDL_LASTEVENT are for your use,
        # and should be allocated with SDL_RegisterEvents()
        [ SDL_USEREVENT => 0x8000 ],

        # This last event is only for bounding internal arrays
        [ SDL_LASTEVENT => 0xFFFF ]
    ];

    package SDL2::CommonEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32';
    };

    package SDL2::DisplayEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            display   => 'uint32',
            event     => 'uint8',
            padding1  => 'uint8',
            padding2  => 'uint8',
            padding3  => 'uint8',
            data1     => 'sint32';
    };

    package SDL2::WindowEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            windowID  => 'uint32',
            event     => 'uint8',
            padding1  => 'uint8',
            padding2  => 'uint8',
            padding3  => 'uint8',
            data1     => 'sint32',
            data2     => 'sint32';
    };

    package SDL2::KeyboardEvent {
        use SDL2::Utils;

        #use SDL2::Keysym;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            windowId  => 'uint32',
            state     => 'uint8',
            repeat    => 'uint8',
            padding2  => 'uint8',
            padding3  => 'uint8',
            keysym    => 'SDL_Keysym';
    };
    #
    define events => [ [ SDL_TEXTEDITINGEVENT_TEXT_SIZE => 32 ] ];

    package SDL2::TextEditingEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            windowId  => 'uint32',
            _text     => 'char[' . SDL2::FFI::SDL_TEXTEDITINGEVENT_TEXT_SIZE() . ']',
            start     => 'sint32',
            length    => 'sint32';

        sub text ($s) {
            my $txt = '';
            for my $chr ( @{ $s->_text } ) {
                last if $chr == 0;
                $txt .= chr $chr;
            }
            $txt;
        }
    };
    define events => [ [ SDL_TEXTINPUTEVENT_TEXT_SIZE => 32 ] ];

    package SDL2::TextInputEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            windowId  => 'uint32',
            _text     => 'char[' . SDL2::FFI::SDL_TEXTINPUTEVENT_TEXT_SIZE() . ']';

        sub text ($s) {
            my $txt = '';
            for my $chr ( @{ $s->_text } ) {
                last if $chr == 0;
                $txt .= chr $chr;
            }
            $txt;
        }
    };

    package SDL2::MouseMotionEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            windowId  => 'uint32',
            which     => 'uint32',
            state     => 'uint32',
            x         => 'sint32',
            y         => 'sint32',
            xrel      => 'sint32',
            yrel      => 'sint32';
    };

    package SDL2::MouseButtonEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            windowID  => 'uint32',
            which     => 'uint32',
            button    => 'uint8',
            state     => 'uint8',
            clicks    => 'uint8',
            padding1  => 'uint8',
            x         => 'sint32',
            y         => 'sint32';
    };

    package SDL2::MouseWheelEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            windowId  => 'uint32',
            which     => 'uint32',
            x         => 'sint32',
            y         => 'sint32',
            direction => 'uint32';
    };

    package SDL2::JoyAxisEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'SDL_JoystickID',
            axis      => 'uint8',
            padding1  => 'uint8',
            padding2  => 'uint8',
            padding3  => 'uint8',
            value     => 'sint16',
            padding4  => 'uint16';
    };

    package SDL2::JoyBallEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'SDL_JoystickID',
            ball      => 'uint8',
            padding1  => 'uint8',
            padding2  => 'uint8',
            padding3  => 'uint8',
            xrel      => 'sint16',
            yrel      => 'sint16';
    };

    package SDL2::JoyHatEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'SDL_JoystickID',
            hat       => 'uint8',
            value     => 'uint8',
            padding1  => 'uint8',
            padding2  => 'uint8';
    };

    package SDL2::JoyButtonEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'SDL_JoystickID',
            button    => 'uint8',
            state     => 'uint8',
            padding1  => 'uint8',
            padding2  => 'uint8';
    };

    package SDL2::JoyDeviceEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'sint32';
    };

    package SDL2::ControllerAxisEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'SDL_JoystickID',
            axis      => 'uint8',
            padding1  => 'uint8',
            padding2  => 'uint8',
            padding3  => 'uint8',
            value     => 'sint16',
            padding4  => 'uint8';
    };

    package SDL2::ControllerButtonEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'SDL_JoystickID',
            button    => 'uint8',
            state     => 'uint8',
            padding1  => 'uint8',
            padding2  => 'uint8';
    };

    package SDL2::ControllerDeviceEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'sint32';
    };

    package SDL2::ControllerTouchpadEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'SDL_JoystickID',
            touchpad  => 'sint32',
            finger    => 'sint32',
            x         => 'float',
            y         => 'float',
            pressure  => 'float';
    };

    package SDL2::ControllerSensorEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'SDL_JoystickID',
            sensor    => 'sint32',
            data      => 'float[3]';
    };

    package SDL2::AudioDeviceEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'uint32',
            iscapture => 'uint8',
            padding1  => 'uint8',
            padding2  => 'uint8',
            padding3  => 'uint8';
    };

    package SDL2::TouchFingerEvent {
        use SDL2::Utils;

        #ffi->type( 'sint64' => 'SDL_TouchID' );
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            touchId   => 'SDL_TouchID',
            fingerId  => 'SDL_FingerID',
            x         => 'float',
            y         => 'float',
            dx        => 'float',
            dy        => 'float',
            pressure  => 'float',
            windowID  => 'uint32';
    };

    package SDL2::MultiGestureEvent {
        use SDL2::Utils;
        our $TYPE = has
            type       => 'uint32',
            timestamp  => 'uint32',
            touchId    => 'SDL_TouchID',
            dTheta     => 'float',
            dDist      => 'float',
            x          => 'float',
            y          => 'float',
            numFingers => 'uint16',
            padding    => 'uint16';
    };

    package SDL2::DollarGestureEvent {
        use SDL2::Utils;

        #ffi->type( 'sint64' => 'SDL_GestureID' );
        our $TYPE = has
            type       => 'uint32',
            timestamp  => 'uint32',
            touchId    => 'SDL_TouchID',
            gestureId  => 'SDL_GestureID',
            numFingers => 'uint32',
            error      => 'float',
            x          => 'float',
            y          => 'float';
    };

    package SDL2::DropEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            file      => 'string(1024)',    #'char[1024]',    # char *
            windowID  => 'uint32';
    };

    package SDL2::SensorEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'sint32',
            data      => 'float[6]';
    };

    package SDL2::QuitEvent {
        use SDL2::Utils;
        our $TYPE = has type => 'uint32', timestamp => 'uint32';
    };

    package SDL2::OSEvent {
        use SDL2::Utils;
        our $TYPE = has type => 'uint32', timestamp => 'uint32';
    };

    package SDL2::UserEvent {
        use SDL2::Utils;
        our $TYPE = has
            type      => 'uint32',
            timestamp => 'uint32',
            windowID  => 'uint32',
            code      => 'sint32',
            data1     => 'opaque',    # void *
            data2     => 'opaque';    # void *
    };

    package SDL2::SysWMEvent 0.01 {
        use SDL2::Utils;
        our $TYPE = has               # TODO: Complex!
            type      => 'uint32',
            timestamp => 'uint32',
            _msg      => 'opaque'     # SDL_SysWMmsg *
            ;

        sub msg {
            ffi->cast( 'opaque', 'SDL_SysWMmsg', $_[0]->_msg );
        }
    };

    package SDL2::Event {
        use SDL2::Utils;
        is 'Union';
        our $TYPE = has
            type      => 'uint32',
            common    => 'SDL_CommonEvent',
            display   => 'SDL_DisplayEvent',
            window    => 'SDL_WindowEvent',
            key       => 'SDL_KeyboardEvent',
            edit      => 'SDL_TextEditingEvent',
            text      => 'SDL_TextInputEvent',
            motion    => 'SDL_MouseMotionEvent',
            button    => 'SDL_MouseButtonEvent',
            wheel     => 'SDL_MouseWheelEvent',
            jaxis     => 'SDL_JoyAxisEvent',
            jball     => 'SDL_JoyBallEvent',
            jhat      => 'SDL_JoyHatEvent',
            jbutton   => 'SDL_JoyButtonEvent',
            jdevice   => 'SDL_JoyDeviceEvent',
            caxis     => 'SDL_ControllerAxisEvent',
            cbutton   => 'SDL_ControllerButtonEvent',
            cdevice   => 'SDL_ControllerDeviceEvent',
            ctouchpad => 'SDL_ControllerTouchpadEvent',
            csensor   => 'SDL_ControllerSensorEvent',
            adevice   => 'SDL_AudioDeviceEvent',
            sensor    => 'SDL_SensorEvent',
            quit      => 'SDL_QuitEvent',
            user      => 'SDL_UserEvent',
            syswm     => 'SDL_SysWMEvent',                # broken?
            tfinger   => 'SDL_TouchFingerEvent',
            mgesture  => 'SDL_MultiGestureEvent',
            dgesture  => 'SDL_DollarGestureEvent',
            drop      => 'SDL_DropEvent',
            padding   => 'uint8[56]';
    };
    attach events        => { SDL_PumpEvents => [ [] ] };
    enum SDL_eventaction => [qw[SDL_ADDEVENT SDL_PEEKEVENT SDL_GETEVENT ]];
    attach events        => {
        SDL_PeepEvents => [
            [ 'SDL_Event', 'int', 'SDL_eventaction', 'uint32', 'uint32' ] => 'int' =>
                sub ( $inner, $events, $numevents, $action, $minType, $maxType ) {
                SDL2::FFI::SDL_Yield();
                $inner->( $events, $numevents, $action, $minType, $maxType );
            }
        ],
        SDL_HasEvent => [
            ['uint32'] => 'bool' => sub ( $inner, @etc ) { SDL2::FFI::SDL_Yield(); $inner->(@etc) }
        ],
        SDL_HasEvents => [
            [ 'uint32', 'uint32' ] => 'bool' =>
                sub ( $inner, @etc ) { SDL2::FFI::SDL_Yield(); $inner->(@etc) }
        ],
        SDL_FlushEvent =>
            [ ['uint32'] => sub ( $inner, @etc ) { SDL2::FFI::SDL_Yield(); $inner->(@etc) } ],
        SDL_FlushEvents => [
            [ 'uint32', 'uint32' ] =>
                sub ( $inner, @etc ) { SDL2::FFI::SDL_Yield(); $inner->(@etc) }
        ],
        SDL_PollEvent => [
            ['SDL_Event'] => 'int' =>
                sub ( $inner, @etc ) { SDL2::FFI::SDL_Yield(); $inner->(@etc) }
        ],
        SDL_WaitEvent => [
            ['SDL_Event'] => 'int' =>
                sub ( $inner, @etc ) { SDL2::FFI::SDL_Yield(); $inner->(@etc) }
        ],
        SDL_WaitEventTimeout => [
            [ 'SDL_Event', 'int' ] => 'int' =>
                sub ( $inner, @etc ) { SDL2::FFI::SDL_Yield(); $inner->(@etc) }
        ],
        SDL_PushEvent => [
            ['SDL_Event'] => 'int' =>
                sub ( $inner, @etc ) { SDL2::FFI::SDL_Yield(); $inner->(@etc) }
        ]
    };
    ffi->type( '(opaque,opaque)->int' => 'SDL_EventFilter' );
    attach events => {
        SDL_SetEventFilter => [ [ 'SDL_EventFilter', 'opaque' ] ],
        SDL_GetEventFilter => [ [ 'SDL_EventFilter', 'opaque*' ], 'SDL_bool' ],
        SDL_AddEventWatch  => [ [ 'SDL_EventFilter', 'opaque' ] ],
        SDL_DelEventWatch  => [ [ 'SDL_EventFilter', 'opaque' ] ],
        SDL_FilterEvents   => [ [ 'SDL_EventFilter', 'opaque' ] ]
    };
    define eventState =>
        [ [ SDL_QUERY => -1 ], [ SDL_IGNORE => 0 ], [ SDL_DISABLE => 0 ], [ SDL_ENABLE => 1 ] ];
    attach events => { SDL_EventState => [ [ 'uint32', 'int' ], 'uint8' ] };
    define events => [
        [   SDL_GetEventState =>
                sub ($type) { SDL2::FFI::SDL_EventState( $type, SDL2::FFI::SDL_QUERY() ) }
        ]
    ];
    attach events => { SDL_RegisterEvents => [ ['int'], 'uint32' ] };

=encoding utf-8

=head1 NAME

SDL2::events - SDL Event Handling

=head1 SYNOPSIS

    use SDL2 qw[:events];

=head1 DESCRIPTION

SDL2::events represents the library's version as three levels: major, minor,
and patch level.

=head1 Functions

These functions might be imported by name or with the C<:events> tag.

=head2 C<SDL_PumpEvents( )>

Pump the event loop, gathering events from the input devices.

    SDL_PumpEvents( );

This function updates the event queue and internal input device state.

B<WARNING>: This should only be run in the thread that initialized the video
subsystem, and for extra safety, you should consider only doing those things on
the main thread in any case.

C<SDL_PumpEvents( )> gathers all the pending input information from devices and
places it in the event queue. Without calls to C<SDL_PumpEvents( )> no events
would ever be placed on the queue. Often the need for calls to
C<SDL_PumpEvents( )> is hidden from the user since L<< C<SDL_PollEvent( ...
)>|/C<SDL_PollEvent( ... )> >> and L<< C<SDL_WaitEvent( ...
)>|/C<SDL_WaitEvent( ... )> >> implicitly call C<SDL_PumpEvents( )>. However,
if you are not polling or waiting for events (e.g. you are filtering them),
then you must call C<SDL_PumpEvents( )> to force an event queue update.

=head2 C<SDL_PeepEvents( ... )>

Check the event queue for messages and optionally return them.

C<action> may be any of the following:

=over

=item C<SDL_ADDEVENT>: up to C<numevents> events will be added to the back of the event queue

=item C<SDL_PEEKEVENT>: C<numevents> events at the front of the event queue, within the specified minimum and maximum type, will be returned to the caller and will _not_ be removed from the queue

=item C<SDL_GETEVENT>: up to C<numevents> events at the front of the event queue, within the specified minimum and maximum type, will be returned to the caller and will be removed from the queue

=back

You may have to call L<< C<SDL_PumpEvents( )>|/C<SDL_PumpEvents( )> >> before
calling this function. Otherwise, the events may not be ready to be filtered
when you call L<< C<SDL_PeepEvents( )>|/C<SDL_PumpEvents( )> >>.

This function is thread-safe.

Expected parameters include:

=over

=item C<events> - destination buffer for the retrieved events

=item C<numevents> - if action is C<SDL_ADDEVENT>, the number of events to add back to the event queue; if action is C<SDL_PEEKEVENT> or C<SDL_GETEVENT>, the maximum number of events to retrieve

=item C<action> - action to take

=item C<minType> - minimum value of the event type to be considered; C<SDL_FIRSTEVENT> is a safe choice

=item C<maxType> - maximum value of the event type to be considered; C<SDL_LASTEVENT> is a safe choice

=back

Returns the number of events actually stored or a negative error code on
failure; call C<SDL_GetError( )> for more information.

=head2 C<SDL_HasEvent( ... )>

Check for the existence of a certain event type in the event queue.

If you need to check for a range of event types, use C<SDL_HasEvents( )>
instead.

Expected parameters include:

=over

=item C<type> - the type of event to be queried; see SDL_EventType for details

=back

Returns C<SDL_TRUE> if events matching C<type> are present, or C<SDL_FALSE> if
events matching C<type> are not present.

=head2 C<SDL_HasEvents( ... )>

Check for the existence of certain event types in the event queue.

If you need to check for a single event type, use C<SDL_HasEvent( )> instead.

Expected parameters include:

=over

=item C<minType> - the low end of event type to be queried, inclusive; see C<SDL_EventType> for details

=item C<maxType> - the high end of event type to be queried, inclusive; see C<SDL_EventType> for details

=back

Returns C<SDL_TRUE> if events with type >= C<minType> and <= C<maxType> are
present, or C<SDL_FALSE> if not.

=head2 C<SDL_FlushEvent( ... )>

Clear events of a specific type from the event queue.

This will unconditionally remove any events from the queue that match C<type>.
If you need to remove a range of event types, use C<SDL_FlushEvents( )>
instead.

It's also normal to just ignore events you don't care about in your event loop
without calling this function.

This function only affects currently queued events. If you want to make sure
that all pending OS events are flushed, you can call C<SDL_PumpEvents( )> on
the main thread immediately before the flush call.

Expected parameters include:

=over

=item C<type> - the type of event to be cleared; see C<SDL_EventType> for details

=back

=head2 C<SDL_FlushEvents( ... )>

Clear events of a range of types from the event queue.

This will unconditionally remove any events from the queue that are in the
range of C<minType> to C<maxType>, inclusive. If you need to remove a single
event type, use C<SDL_FlushEvent( )> instead.

It's also normal to just ignore events you don't care about in your event loop
without calling this function.

This function only affects currently queued events. If you want to make sure
that all pending OS events are flushed, you can call C<SDL_PumpEvents( )> on
the main thread immediately before the flush call.

Expected parameters include:

=over

=item C<minType> - the low end of event type to be cleared, inclusive; see C<SDL_EventType> for details

=item C<maxType> - the high end of event type to be cleared, inclusive; see C<SDL_EventType> for details

=back

=head2 C<SDL_PollEvent( ... )>

Poll for currently pending events.

If C<event> is not C<undef>, the next event is removed from the queue and
stored in the L<SDL2::Event> structure pointed to by C<event>. The C<1>
returned refers to this event, immediately stored in the SDL Event structure --
not an event to follow.

If C<event> is C<undef>, it simply returns C<1> if there is an event in the
queue, but will not remove it from the queue.

As this function implicitly calls C<SDL_PumpEvents( )>, you can only call this
function in the thread that set the video mode.

C<SDL_PollEvent( ... )> is the favored way of receiving system events since it
can be done from the main loop and does not suspend the main loop while waiting
on an event to be posted.

The common practice is to fully process the event queue once every frame,
usually as a first step before updating the game's state:

	while (game_is_still_running()) {
		while (SDL_PollEvent(\my $event)) { #  poll until all events are handled!
			# decide what to do with this event.
		}
		# update game state, draw the current frame
	}

Expected parameters include:

=over

=item C<event> - the L<SDL2::Event> structure to be filled with the next event from the queue, or C<undef>

=back

Returns C<1> if there is a pending event or C<0> if there are none available.

=head2 C<SDL_WaitEvent( ... )>

Wait indefinitely for the next available event.

If C<event> is not C<undef>, the next event is removed from the queue and
stored in the L<SDL2::Event> structure pointed to by C<event>.

As this function implicitly calls C<SDL_PumpEvents( )>, you can only call this
function in the thread that initialized the video subsystem.

Expected parameters include:

=over

=item C<event> - the L<SDL2::Event> structure to be filled in with the next event from the queue, or C<undef>

=back

Returns C<1> on success or C<0> if there was an error while waiting for events;
call C<SDL_GetError( )> for more information.

=head2 C<SDL_WaitEventTimeout( ... )>

Wait until the specified timeout (in milliseconds) for the next available
event.

If C<event> is not C<>, the next event is removed from the queue and stored in
the L<DL2::Event> structure pointed to by C<event>.

As this function implicitly calls C<SDL_PumpEvents( )>, you can only call this
function in the thread that initialized the video subsystem.

Expected parameters include:

=over

=item C<event> - the L<SDL2::Event> structure to be filled in with the next event from the queue, or C<undef>

=item C<timeout> - the maximum number of milliseconds to wait for the next available event

=back

Returns C<1> on success or C<0> if there was an error while waiting for events;
call C<SDL_GetError( )> for more information. This also returns C<0> if the
timeout elapsed without an event arriving.

=head2 C<SDL_PushEvent( ... )>

Add an event to the event queue.

The event queue can actually be used as a two way communication channel. Not
only can events be read from the queue, but the user can also push their own
events onto it. C<event> is a pointer to the event structure you wish to push
onto the queue. The event is copied into the queue, and the caller may dispose
of the memory pointed to after C<SDL_PushEvent( )> returns.

Note: Pushing device input events onto the queue doesn't modify the state of
the device within SDL.

This function is thread-safe, and can be called from other threads safely.

Note: Events pushed onto the queue with C<SDL_PushEvent( )> get passed through
the event filter but events added with C<SDL_PeepEvents( )> do not.

For pushing application-specific events, please use C<SDL_RegisterEvents( )> to
get an event type that does not conflict with other code that also wants its
own custom event types.

Expected parameters include:

=over

=item C<event> - the L<SDL2::Event> to be added to the queue

=back

Returns C<1> on success, C<0> if the event was filtered, or a negative error
code on failure; call C<SDL_GetError( )> for more information. A common reason
for error is the event queue being full.

=head2 C<SDL_SetEventFilter( ... )>

Set up a filter to process all events before they change internal state and are
posted to the internal event queue.

If the filter function returns 1 when called, then the event will be added to
the internal queue. If it returns C<0>, then the event will be dropped from the
queue, but the internal state will still be updated. This allows selective
filtering of dynamically arriving events.

B<WARNING>: Be very careful of what you do in the event filter function, as it
may run in a different thread!

On platforms that support it, if the quit event is generated by an interrupt
signal (e.g. pressing Ctrl-C), it will be delivered to the application at the
next event poll.

There is one caveat when dealing with the C<SDL_QuitEvent> event type.  The
event filter is only called when the window manager desires to close the
application window.  If the event filter returns C<1>, then the window will be
closed, otherwise the window will remain open if possible.

Note: Disabled events never make it to the event filter function; see
C<SDL_EventState( )>.

Note: If you just want to inspect events without filtering, you should use
C<SDL_AddEventWatch( )> instead.

Note: Events pushed onto the queue with C<SDL_PushEvent( )> get passed through
the event filter, but events pushed onto the queue with C<SDL_PeepEvents( )> do
not.

Expected parameters include:

=over

=item C<filter> - An C<SDL_EventFilter> function to call when an event happens param userdata a pointer that is passed to C<filter>

=item C<userdata> - a pointer that is passed to C<filter>

=back

=head2 C<SDL_GetEventFilter( ... )>

Query the current event filter.

This function can be used to "chain" filters, by saving the existing filter
before replacing it with a function that will call that saved filter.

Expected parameters include:

=over

=item C<filter> - the current callback function will be stored here

=item C<userdata> - the pointer that is passed to the current event filter will be stored here

=back

Returns C<SDL_TRUE> on success or C<SDL_FALSE> if there is no event filter set.

=head2 C<SDL_AddEventWatch( ... )>

Add a callback to be triggered when an event is added to the event queue.

C<filter> will be called when an event happens, and its return value is
ignored.

B<WARNING>: Be very careful of what you do in the event filter function, as it
may run in a different thread!

If the quit event is generated by a signal (e.g. C<SIGINT>), it will bypass the
internal queue and be delivered to the watch callback immediately, and arrive
at the next event poll.

Note: the callback is called for events posted by the user through
C<SDL_PushEvent( )>, but not for disabled events, nor for events by a filter
callback set with C<SDL_SetEventFilter( )>, nor for events posted by the user
through C<SDL_PeepEvents( )>.

Expected parameters include:

=over

=item C<filter> - an C<SDL_EventFilter> function to call when an event happens.

=item C<userdata> - a pointer that is passed to C<filter>

=back

=head2 C<SDL_DelEventWatch( ... )>

Remove an event watch callback added with C<SDL_AddEventWatch( )>.

This function takes the same input as C<SDL_AddEventWatch( )> to identify and
delete the corresponding callback.

Expected parameters include:

=over

=item C<filter> - the function originally passed to C<SDL_AddEventWatch( )>

=item C<userdata> - the pointer originally passed to C<SDL_AddEventWatch( )>

=back

=head2 C<SDL_FilterEvents( ... )>

Run a specific filter function on the current event queue, removing any events
for which the filter returns C<0>.

See C<SDL_SetEventFilter( )> for more information. Unlike C<SDL_SetEventFilter(
)>, this function does not change the filter permanently, it only uses the
supplied filter until this function returns.

Expected parameters include:

=over

=item C<filter> - the C<SDL_EventFilter> function to call when an event happens

=item C<userdata> - a pointer that is passed to C<filter>

=back

=head2 C<SDL_EventState( ... )>

Set the state of processing events by type.

C<state> may be any of the following:

=over

=item - C<SDL_QUERY>: returns the current processing state of the specified event

=item - C<SDL_IGNORE> (aka C<SDL_DISABLE>): the event will automatically be dropped from the event queue and will not be filtered

=item - C<SDL_ENABLE>: the event will be processed normally

=back

Expected parameters include:

=over

=item C<type> - the type of event; see C<SDL_EventType> for details

=item C<state> - how to process the event

=back

Returns C<SDL_DISABLE> or C<SDL_ENABLE>, representing the processing state of
the event before this function makes any changes to it.

=head2 C<SDL_GetEventState( ... )>

Queries for the current processing state of the specified event.

Expected parameters include:

=over

=item C<type> - the type of event; see C<SDL_EventType> for details

=back

Returns C<SDL_DISABLE> or C<SDL_ENABLE>, representing the processing state of
the event before this function makes any changes to it.

=head2 C<SDL_RegisterEvents( ... )>

Allocate a set of user-defined events, and return the beginning event number
for that set of events.

Calling this function with `numevents` <= 0 is an error and will return
C<(Uint32)-1>.

Note, C<(Uint32)-1> means the maximum unsigned 32-bit integer value (or
C<0xFFFFFFFF>), but is clearer to write.

Expected parameters include:

=over

=item C<numevents> - the number of events to be allocated

=back

Returns the beginning event number, or C<(Uint32)-1> if there are not enough
user-defined events left.

=head1 Defined Values and Enumerations

These may be imported by name or with the given tag.

=head2 Event States

General keyboard/mouse state definitions. These may be imported with the
C<:eventstate> tag.

=over

=item C<SDL_RELEASED>

=item C<SDL_PRESSED>

=back

=head2 C<SDL_EventType>

The types of events that can be delivered. This enumerations may be imported
with the C<:eventType> tag.

=over

=item C<SDL_FIRSTEVENT> - Unused

=back

Application events

=over

=item C<SDL_QUIT> - User-requested quit

=back

These application events have special meaning on iOS, see C<README-ios.md> for
details.

=over

=item C<SDL_APP_TERMINATING> - The application is being terminated by the OS

Called on iOS in C<applicationWillTerminate()>

Called on Android in C<onDestroy()>

=item C<SDL_APP_LOWMEMORY> - The application is low on memory, free memory if possible.

Called on iOS in C<applicationDidReceiveMemoryWarning()>

Called on Android in C<onLowMemory()>

=item C<SDL_APP_WILLENTERBACKGROUND> - The application is about to enter the background

Called on iOS in C<applicationWillResignActive()>

Called on Android in C<onPause()>

=item C<SDL_APP_DIDENTERBACKGROUND> - The application did enter the background and may not get CPU for some time

Called on iOS in C<applicationDidEnterBackground()>

Called on Android in C<onPause()>

=item C<SDL_APP_WILLENTERFOREGROUND> - The application is about to enter the foreground

Called on iOS in C<applicationWillEnterForeground()>

Called on Android in C<onResume()>

=item C<SDL_APP_DIDENTERFOREGROUND> - The application is now interactive

Called on iOS in C<applicationDidBecomeActive()>

Called on Android in C<onResume()>

=item C<SDL_LOCALECHANGED> - The user's locale preferences have changed.

=back

Display events

=over

=item C<SDL_DISPLAYEVENT> - Display state change

=back

Window events

=over

=item C<SDL_WINDOWEVENT> - Window state change

=item C<SDL_SYSWMEVENT> - System specific event

=back

Keyboard events

=over

=item C<SDL_KEYDOWN> - Key pressed

=item C<SDL_KEYUP> - Key released

=item C<SDL_TEXTEDITING> - Keyboard text editing (composition)

=item C<SDL_TEXTINPUT> - Keyboard text input

=item C<SDL_KEYMAPCHANGED> - Keymap changed due to a system event such as an input language or keyboard layout change

=back

Mouse events

=over

=item C<SDL_MOUSEMOTION> -  Mouse moved

=item C<SDL_MOUSEBUTTONDOWN> - Mouse button pressed

=item C<SDL_MOUSEBUTTONUP> - Mouse button released

=item C<SDL_MOUSEWHEEL> - Mouse wheel motion

=back

Joystick events

=over

=item C<SDL_JOYAXISMOTION> - Joystick axis motion

=item C<SDL_JOYBALLMOTION> - Joystick trackball motion

=item C<SDL_JOYHATMOTION> - Joystick hat position change

=item C<SDL_JOYBUTTONDOWN> - Joystick button pressed

=item C<SDL_JOYBUTTONUP> - Joystick button released

=item C<SDL_JOYDEVICEADDED> - A new joystick has been inserted into the system

=item C<SDL_JOYDEVICEREMOVED> - An opened joystick has been removed

=back

Game controller events

=over

=item C<SDL_CONTROLLERAXISMOTION> - Game controller axis motion

=item C<SDL_CONTROLLERBUTTONDOWN> - Game controller button pressed

=item C<SDL_CONTROLLERBUTTONUP> - Game controller button released

=item C<SDL_CONTROLLERDEVICEADDED> - A new Game controller has been inserted into the system

=item C<SDL_CONTROLLERDEVICEREMOVED> - An opened Game controller has been removed

=item C<SDL_CONTROLLERDEVICEREMAPPED> - The controller mapping was updated

=item C<SDL_CONTROLLERTOUCHPADDOWN> - Game controller touchpad was touched

=item C<SDL_CONTROLLERTOUCHPADMOTION> - Game controller touchpad finger was moved

=item C<SDL_CONTROLLERTOUCHPADUP> - Game controller touchpad finger was lifted

=item C<SDL_CONTROLLERSENSORUPDATE> - Game controller sensor was updated

=back

Touch events

=over

=item C<SDL_FINGERDOWN>

=item C<SDL_FINGERUP>

=item C<SDL_FINGERMOTION>

=back

Gesture events

=over

=item C<SDL_DOLLARGESTURE>

=item C<SDL_DOLLARRECORD>

=item C<SDL_MULTIGESTURE>

=back

Clipboard events

=over

=item C<SDL_CLIPBOARDUPDATE> - The clipboard changed

=back

Drag and drop events

=over

=item C<SDL_DROPFILE> - The system requests a file open

=item C<SDL_DROPTEXT> - text/plain drag-and-drop event

=item C<SDL_DROPBEGIN> - A new set of drops is beginning (NULL filename)

=item C<SDL_DROPCOMPLETE> - Current set of drops is now complete (NULL filename)

=back

Audio hotplug events

=over

=item C<SDL_AUDIODEVICEADDED> - A new audio device is available

=item C<SDL_AUDIODEVICEREMOVED> - An audio device has been removed

=back

Sensor events

=over

=item C<SDL_SENSORUPDATE> - A sensor was updated

=back

Render events

=over

=item C<SDL_RENDER_TARGETS_RESET> - The render targets have been reset and their contents need to be updated

=item C<SDL_RENDER_DEVICE_RESET> - The device has been reset and all textures need to be recreated

=back

Events C<SDL_USEREVENT> through C<SDL_LASTEVENT> are for your use, and should
be allocated with C<SDL_RegisterEvents( ... )>

=over

=item C<SDL_USEREVENT>

=back

This last event is only for bounding internal arrays

=over

=item C<SDL_LASTEVENT>

=back

=head2 C<SDL_eventaction>

This enumeration may be imported with the C<:eventaction> tag.

=over

=item C<SDL_ADDEVENT>

=item C<SDL_PEEKEVENT>

=item C<SDL_GETEVENT>

=back

=head2 C<SDL_EventFilter>

A function pointer used for callbacks that watch the event queue.

Parameters to expect:

=over

=item C<userdata> - what was passed as C<userdata> to C<SDL_SetEventFilter( )> or C<SDL_AddEventWatch>, etc.

=item C<event> - the event that triggered the callback

=back

Your callback should return C<1> to permit event to be added to the queue, and
C<0> to disallow it. When used with C<SDL_AddEventWatch>, the return value is
ignored.

=head2 Event State

These values may be imported with the C<eventState> tag.

=over

=item C<SDL_QUERY> - returns the current processing state of the specified event

=item C<SDL_IGNORE> - aka C<SDL_DISABLE>; the event will automatically be dropped from the event queue and will not be filtered

=item C<SDL_DISABLE> - aka C<SDL_IGNORE>

=item C<SDL_ENABLE> - the event will be processed normally

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

userdata aka numevents hotplug

=end stopwords

=cut

};
1;
