package SDL2::system 0.01 {
    use SDL2::Utils;
    use experimental 'signatures';
    #
    use SDL2::stdinc;
    use SDL2::keyboard;
    use SDL2::render;
    use SDL2::video;
    #
    # From Perl::osnames
    my $linux = $^O
        =~ qr/\A(?:aix|android|bsdos|bitrig|dgux|dynixptx|cygwin|darwin|dragonfly|freebsd|gnu|gnukfreebsd|hpux|interix|iphoneos|irix|linux|machten|midnightbsd|mirbsd|msys|netbsd|next|nto|openbsd|qnx|sco|sco_sv|solaris|sunos|svr4|svr5|unicos|unicosmk)\z/;
    my $macos   = $^O eq 'darwin';
    my $ios     = $^O eq 'iphoneos';
    my $android = $^O eq 'android';
    my $winrt   = 0;
    my $win32   = $^O eq 'MSWin32';
    #
    if ($win32) {

        package SDL2::IDirect3DDevice9 {
            use SDL2::Utils;
            our $TYPE = has();
        };

        package SDL2::ID3D11Device {
            use SDL2::Utils;
            our $TYPE = has();
        };

        #(void *userdata, void *hWnd, unsigned int message, Uint64 wParam, Sint64 lParam);
        ffi->type( '(opaque,opaque,uint,uint64,sint64)->void' => 'SDL_WindowsMessageHook' );
        attach system => {
            SDL_SetWindowsMessageHook => [
                [ 'SDL_WindowsMessageHook', 'opaque' ] => sub ( $inner, $callback, $userdata = () )
                {
                    my $cb = ffi->closure(
                        sub ( $ud, $hWnd, $msg, $wP, $lP ) {
                            $callback->( $userdata, $hWnd, $msg, $wP, $lP );
                        }
                    );
                    $cb->sticky;
                    $inner->( $cb, $userdata );
                }
            ],
            SDL_Direct3D9GetAdapterIndex => [ ['int'],                   'int' ],
            SDL_RenderGetD3D9Device      => [ ['SDL_Renderer'],          'SDL_IDirect3DDevice9' ],
            SDL_RenderGetD3D11Device     => [ ['SDL_Renderer'],          'SDL_ID3D11Device' ],
            SDL_DXGIGetOutputInfo        => [ [ 'int', 'int*', 'int*' ], 'SDL_bool' ]
        };
    }
    elsif ($macos) {
    }
    elsif ($linux) {
        attach system => { SDL_LinuxSetThreadPriority => [ [ 'sint64', 'int' ], 'int' ] };
    }
    elsif ($ios) {
        ...;
    }
    elsif ($android) {
        ...;
    }
    elsif ($winrt) {
        ...;
    }
    attach system => { SDL_IsTablet => [ [], 'SDL_bool' ] };

=encoding utf-8

=head1 NAME

SDL2::system - Platform Specific SDL API Functions

=head1 SYNOPSIS

    use SDL2 qw[:system];

=head1 DESCRIPTION

Depending on your platform, some of these functions will not be defined. They
may be imported by name or with the C<:system> tag.

=head1 General

These functions are defined for all platforms.

=head2 Functions.

Platform agnostic functions.

=head2 C<SDL_IsTablet( )>

Query if the current device is a tablet.

If SDL can't determine this, it will return C<SDL_FALSE>.

Returns C<SDL_TRUE> if the device is a tablet, C<SDL_FALSE> otherwise.

=head1 Windows

These functions and defined types will only exist on a system running Windows.

=head2 Functions

Platform specified functions for Windows.

=head2 C<SDL_SetWindowsMessageHook( ... )>

Set a callback for every Windows message, run before C<TranslateMessage( )>.

Expected parameters include:

=over

=item C<callback> - the C<SDL_WindowsMessageHook> function to call.

=item C<userdata> - a pointer to pass to every iteration of C<callback>

=back

=head2 C<SDL_Direct3D9GetAdapterIndex( ... )>

Get the D3D9 adapter index that matches the specified display index.

The returned adapter index can be passed to `IDirect3D9::CreateDevice` and
controls on which monitor a full screen application will appear.

Expected parameters include:

=over

=item C<displayIndex> - the display index for which to get the D3D9 adapter index

=back

Returns the D3D9 adapter index on success or a negative error code on failure;
call C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderGetD3D9Device( ... )>

Get the D3D9 device associated with a renderer.

Once you are done using the device, you should release it to avoid a resource
leak.

Expected parameters include:

=over

=item C<renderer> the renderer from which to get the associated D3D device

=back

Returns the D3D9 device associated with given renderer or C<undef> if it is not
a D3D9 renderer; call C<SDL_GetError( )> for more information.

=head2 C<SDL_RenderGetD3D11Device( ... )>

Get the D3D11 device associated with a renderer.

Once you are done using the device, you should release it to avoid a resource
leak.

Expected parameters include:

=over

=item C<renderer> - the renderer from which to get the associated D3D11 device

=back

Returns the D3D11 device associated with given renderer or C<undef> if it is
not a D3D11 renderer; call C<SDL_GetError( )> for more information.

=head2 C<SDL_DXGIGetOutputInfo( ... )>

Get the DXGI Adapter and Output indices for the specified display index.

The DXGI Adapter and Output indices can be passed to C<EnumAdapters> and
C<EnumOutputs> respectively to get the objects required to create a DX10 or
DX11 device and swap chain.

=over

=item C<displayIndex> - the display index for which to get both indices

=item C<adapterIndex> - a pointer to be filled in with the adapter index

=item C<outputIndex> - a pointer to be filled in with the output index

=back

Returns C<SDL_TRUE> on success or C<SDL_FALSE> on failure; call C<SDL_GetError(
)> for more information.

=head2 Defined Values and Enumerations

These will only be defined on Windows.

=head3 C<SDL_WindowsMessageHook>

A callback for every Windows message.

Parameters to expect include:

=over

=item C<userdata>

=item C<hWnd>

=item C<message>

=item C<wParam>

=item C<lParam>

=back

=head1 Linux

These functions will only exist on a system running Linux.

=head2 Functions

Sets the UNIX nice value for a thread.

This uses C<setpriority( )> if possible, and RealtimeKit if available.

Expected parameters include:

=over

=item C<threadID> - the Unix thread ID to change priority of

=item C<priority> - the new, Unix-specific, priority value

=back

Returns C<0> on success, or C<-1> on error.

=head1 iOS

The functions related to iOS are not defined. If you somehow manage to get perl
running on an iOS device and require these functions, file a bug report at this
project's issue tracker and I'll fill in the gaps if you'll assist with
testing.

=head1 Android

The functions related to Android are not defined. If you require these
functions, file a bug report at this project's issue tracker and I'll fill in
the gaps if you'll assist with testing.

=head1 WinRT

The functions related to WinRT are not defined. If you somehow manage to get
perl running on a device with WinRT and require these functions, file a bug
report at this project's issue tracker and I'll fill in the gaps if you'll
assist with testing.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

WinRT

=end stopwords

=cut

};
1;
