package SDL2::syswm 0.01 {
    use SDL2::Utils;
    #
    use SDL2::stdinc;
    use SDL2::error;
    use SDL2::video;
    use SDL2::version;
    #
    enum SDL_SYSWM_TYPE => [
        qw[
            SDL_SYSWM_UNKNOWN
            SDL_SYSWM_WINDOWS
            SDL_SYSWM_X11
            SDL_SYSWM_DIRECTFB
            SDL_SYSWM_COCOA
            SDL_SYSWM_UIKIT
            SDL_SYSWM_WAYLAND
            SDL_SYSWM_MIR
            SDL_SYSWM_WINRT
            SDL_SYSWM_ANDROID
            SDL_SYSWM_VIVANTE
            SDL_SYSWM_OS2
            SDL_SYSWM_HAIKU
            SDL_SYSWM_KMSDRM
        ]
    ];

    package SDL2::SysWMmsg {
        use SDL2::Utils;    # TODO: Complex!

        package SDL2::Win {
            use SDL2::Utils;
            has
                HWND   => 'uint32',
                msg    => 'uint32',
                wParam => 'uint32',
                lParam => 'uint32';
        };

        package SDL2::X11 {
            use SDL2::Utils;
            has event => 'opaque';    # XEvent
        };

        package SDL2::DFB {
            use SDL2::Utils;
            has event => 'opaque';    # DFBEvent
        };

        package SDL2::Cocoa {
            use SDL2::Utils;
            has dummy => 'int';
        };

        package SDL2::UIKit {
            use SDL2::Utils;
            has dummy => 'int';
        };

        package SDL2::Vivante {
            use SDL2::Utils;
            has dummy => 'int';
        };

        package SDL2::OS2 {
            use SDL2::Utils;
            has
                fFrame => 'bool',
                hwnd   => 'uint32',
                msg    => 'ulong',
                mp1    => 'uint32',
                mp2    => 'uint32';
        };

        package SDL2::msg {
            use SDL2::Utils;
            is 'Union';
            has
                event => 'SDL_X11',
                dummy => 'int';
        };
        our $TYPE = has
            version   => 'SDL_Version',
            subsystem => 'SDL_SYSWM_TYPE',
            #
            msg => 'SDL_msg',
            #
            ;    # contents depends on driver, platform, etc.
    };

=begin :todo

    union
    {
#if defined(SDL_VIDEO_DRIVER_WINDOWS)
        struct {
            HWND hwnd;                  /**< The window for the message */
            UINT msg;                   /**< The type of message */
            WPARAM wParam;              /**< WORD message parameter */
            LPARAM lParam;              /**< LONG message parameter */
        } win;
#endif
#if defined(SDL_VIDEO_DRIVER_X11)
        struct {
            XEvent event;
        } x11;
#endif
#if defined(SDL_VIDEO_DRIVER_DIRECTFB)
        struct {
            DFBEvent event;
        } dfb;
#endif
#if defined(SDL_VIDEO_DRIVER_COCOA)
        struct
        {
            /* Latest version of Xcode clang complains about empty structs in C v. C++:
                 error: empty struct has size 0 in C, size 1 in C++
             */
            int dummy;
            /* No Cocoa window events yet */
        } cocoa;
#endif
#if defined(SDL_VIDEO_DRIVER_UIKIT)
        struct
        {
            int dummy;
            /* No UIKit window events yet */
        } uikit;
#endif
#if defined(SDL_VIDEO_DRIVER_VIVANTE)
        struct
        {
            int dummy;
            /* No Vivante window events yet */
        } vivante;
#endif
#if defined(SDL_VIDEO_DRIVER_OS2)
        struct
        {
            BOOL fFrame;                /**< TRUE if hwnd is a frame window */
            HWND hwnd;                  /**< The window receiving the message */
            ULONG msg;                  /**< The message identifier */
            MPARAM mp1;                 /**< The first first message parameter */
            MPARAM mp2;                 /**< The second first message parameter */
        } os2;
#endif
        /* Can't have an empty union */
        int dummy;
    } msg;

=end :todo

=cut

    package SDL2::SysWMinfo 0.01 {
        use SDL2::Utils;
        our $TYPE = has()    # TODO: Complex!
            ;
    };
    #
    attach syswm => { SDL_GetWindowWMInfo => [ [ 'SDL_Window', 'SDL_SysWMinfo' ], 'SDL_bool' ] };

=encoding utf-8

=head1 NAME

SDL2::syswm - SDL Custom System Window Manager Hooks

=head1 SYNOPSIS

    use SDL2 qw[:syswm];

=head1 DESCRIPTION

Your application has access to a special type of event ::SDL_SYSWMEVENT, which
contains window-manager specific information and arrives whenever an unhandled
window event occurs.  This event is ignored by default, but you can enable it
with C<SDL_EventState( )>.

=head1 Functions

These may be imported by name or with the C<:syswm> tag.

=head2 C<SDL_GetWindowWMInfo( )>

Get driver-specific information about a window.

The caller must initialize the C<info> structure's version by using C<<
SDL_VERSION( $info->version) >>, and then this function will fill in the rest
of the structure with information about the given window.

Expected parameters include:

=over

=item C<window> - the window about which information is being requested

=item C<info> - an L<SDL2::SysWMinfo> structure filled in with window information

=back

Returns C<SDL_TRUE> if the function is implemented and the C<version> member of
the C<info> struct is valid, or C<SDL_FALSE> if the information could not be
retrieved; call C<SDL_GetError( )> for more information.

=head1 Defined Variables and Enumerations

Variables may be imported by name or with the C<:syswm> tag.

=head2 C<SDL_SYSWM_TYPE>

These are the various supported windowing subsystems.

=over

=item C<SDL_SYSWM_UNKNOWN>

=item C<SDL_SYSWM_WINDOWS>

=item C<SDL_SYSWM_X11>

=item C<SDL_SYSWM_DIRECTFB>

=item C<SDL_SYSWM_COCOA>

=item C<SDL_SYSWM_UIKIT>

=item C<SDL_SYSWM_WAYLAND>

=item C<SDL_SYSWM_MIR> - no longer available, left for API/ABI compatibility. Remove in 2.1!

=item C<SDL_SYSWM_WINRT>

=item C<SDL_SYSWM_ANDROID>

=item C<SDL_SYSWM_VIVANTE>

=item C<SDL_SYSWM_OS2>

=item C<SDL_SYSWM_HAIKU>

=item C<SDL_SYSWM_KMSDRM>

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

=end stopwords

=cut

};
1;
