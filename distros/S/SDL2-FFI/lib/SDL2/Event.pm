package SDL2::Event {
    use SDL2::Utils;
    use FFI::C::UnionDef;
    use SDL2::CommonEvent;
    use SDL2::DisplayEvent;
    use SDL2::KeyboardEvent;
    use SDL2::MouseButtonEvent;
    use SDL2::MouseMotionEvent;
    use SDL2::MouseWheelEvent;
    use SDL2::JoyAxisEvent;
    use SDL2::JoyBallEvent;
    use SDL2::JoyHatEvent;
    use SDL2::JoyButtonEvent;
    use SDL2::JoyDeviceEvent;
    use SDL2::ControllerAxisEvent;
    use SDL2::ControllerButtonEvent;
    use SDL2::ControllerDeviceEvent;
    use SDL2::AudioDeviceEvent;
    use SDL2::TouchFingerEvent;
    use SDL2::TextEditingEvent;
    use SDL2::TextInputEvent;
    use SDL2::MultiGestureEvent;
    use SDL2::DollarGestureEvent;
    use SDL2::DropEvent;
    use SDL2::SensorEvent;
    use SDL2::QuitEvent;
    use SDL2::UserEvent;
    use SDL2::SysWMEvent;
    use SDL2::WindowEvent;
    FFI::C::UnionDef->new( ffi,
        name    => 'SDL_Event',
        class   => 'SDL2::Event',
        members => [
            type     => 'uint32',
            common   => 'SDL_CommonEvent',
            display  => 'SDL_DisplayEvent',
            window   => 'SDL_WindowEvent',
            key      => 'SDL_KeyboardEvent',
            edit     => 'SDL_TextEditingEvent',
            text     => 'SDL_TextInputEvent',
            motion   => 'SDL_MouseMotionEvent',
            button   => 'SDL_MouseButtonEvent',
            wheel    => 'SDL_MouseWheelEvent',
            jaxis    => 'SDL_JoyAxisEvent',
            jball    => 'SDL_JoyBallEvent',
            jhat     => 'SDL_JoyHatEvent',
            jbutton  => 'SDL_JoyButtonEvent',
            jdevice  => 'SDL_JoyDeviceEvent',
            caxis    => 'SDL_ControllerAxisEvent',
            cbutton  => 'SDL_ControllerButtonEvent',
            cdevice  => 'SDL_ControllerDeviceEvent',
            adevice  => 'SDL_AudioDeviceEvent',
            sensor   => 'SDL_SensorEvent',
            quit     => 'SDL_QuitEvent',
            user     => 'SDL_UserEvent',
            syswm    => 'SDL_SysWMEvent',
            tfinger  => 'SDL_TouchFingerEvent',
            mgesture => 'SDL_MultiGestureEvent',
            dgesture => 'SDL_DollarGestureEvent',
            drop     => 'SDL_DropEvent',
            padding  => 'uint8[56]'
        ]
    );

=encoding utf-8

=head1 NAME

SDL2::Event - General event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION

SDL2::Event is a C union which generalizes all known SDL2 events.

=head1 Fields

As a union, this object main contain the following structures:

=over

=item C<type> - Event type, shared with all events

=item C<common> - SDL2::CommonEvent

=item C<display> - SDL2::DisplayEvent

=item C<window> - SDL2::WindowEvent

=item C<key> - SDL2::KeyboardEvent

=item C<edit> - SDL2::TextEditingEvent

=item C<text> - SDL2::TextInputEvent

=item C<motion> - SDL2::MouseMotionEvent

=item C<button> - SDL2::MouseButtonEvent

=item C<wheel> - SDL2::MouseWheelEvent

=item C<jaxis> - SDL2::JoyAxisEvent

=item C<jball> - SDL2::JoyBallEvent

=item C<jhat> - SDL2::JoyHatEvent

=item C<jbutton> - SDL2::JoyButtonEvent

=item C<jdevice> - SDL2::JoyDeviceEvent

=item C<caxis> - SDL2::ControllerAxisEvent

=item C<cbutton> - SDL2::ControllerButtonEvent

=item C<cdevice> - SDL2::ControllerDeviceEvent

=item C<adevice> - SDL2::AudioDeviceEvent

=item C<sensor> - SDL2::SensorEvent

=item C<quit> - SDL2::QuitEvent

=item C<user> - SDL2::UserEvent

=item C<syswm> - SDL2::SysWMEvent

=item C<tfinger> - SDL2::TouchFingerEvent

=item C<mgesture> - SDL2::MultiGestureEvent

=item C<dgesture> - SDL2::DollarGestureEvent

=item C<drop> - SDL2::DropEvent

=item C<padding> - Raw data used internally to protect ABI compatibility between VC++ and GCC

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
