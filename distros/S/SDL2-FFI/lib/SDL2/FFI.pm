package SDL2::FFI 0.08 {
    use lib '../lib', 'lib';

    # ABSTRACT: FFI Wrapper for SDL (Simple DirectMedia Layer) Development Library
    use strict;
    use warnings;
    use experimental 'signatures';
    use base 'Exporter::Tiny';
    use SDL2::Utils;
    our %EXPORT_TAGS;
    CORE::state $SDL_ASSERT_LEVEL = 2;
    sub SDL_ASSERT_LEVEL { $SDL_ASSERT_LEVEL //= 2; $SDL_ASSERT_LEVEL; }

    sub _exporter_validate_opts {
        my $class = shift;
        my ($globals) = @_;
        if    ( $globals->{'assert=0'} ) { $SDL_ASSERT_LEVEL = 0 }
        elsif ( $globals->{'assert=1'} ) { $SDL_ASSERT_LEVEL = 1 }
        elsif ( $globals->{'assert=2'} ) { $SDL_ASSERT_LEVEL = 2 }
        elsif ( $globals->{'assert=3'} ) { $SDL_ASSERT_LEVEL = 3 }

        #...;   # do stuff here
        #use Data::Dump;
        #ddx $globals;
        $class->SUPER::_exporter_validate_opts(@_);
    }
    my $platform = $^O;                            # https://perldoc.perl.org/perlport#PLATFORMS
    my $Windows  = !!( $platform eq 'MSWin32' );
    #
    load_lib('SDL2');
    #
    require SDL2::stdinc;
    require SDL2::assert;                          # Enable with use var like C<use SDL2 -assert=3;>
    require SDL2::atomic;
    require SDL2::rwops;                           # Does not belong here?
    require SDL2::audio;
    require SDL2::clipboard;
    require SDL2::cpuinfo;
    require SDL2::error;
    require SDL2::events;
    require SDL2::filesystem;
    require SDL2::gamecontroller;
    require SDL2::haptic;
    require SDL2::hints;
    require SDL2::joystick;
    require SDL2::loadso;
    require SDL2::log;
    require SDL2::messagebox;
    require SDL2::metal;
    require SDL2::mutex;
    require SDL2::power;
    require SDL2::render;
    require SDL2::rwops;
    require SDL2::sensor;
    require SDL2::shape;
    require SDL2::system;
    require SDL2::thread;
    require SDL2::timer;
    require SDL2::version;
    require SDL2::video;
    require SDL2::locale;
    require SDL2::misc;
    #
    require SDL2::platform;    # We bypass config.h to get platform.h
    require SDL2::syswm;
    #
    #
    define init => [
        [ SDL_INIT_TIMER          => 0x00000001 ],
        [ SDL_INIT_AUDIO          => 0x00000010 ],
        [ SDL_INIT_VIDEO          => 0x00000020 ],
        [ SDL_INIT_JOYSTICK       => 0x00000200 ],
        [ SDL_INIT_HAPTIC         => 0x00001000 ],
        [ SDL_INIT_GAMECONTROLLER => 0x00002000 ],
        [ SDL_INIT_EVENTS         => 0x00004000 ],
        [ SDL_INIT_SENSOR         => 0x00008000 ],
        [ SDL_INIT_NOPARACHUTE    => 0x00100000 ],
        [   SDL_INIT_EVERYTHING => sub {
                SDL_INIT_TIMER() | SDL_INIT_AUDIO() | SDL_INIT_VIDEO() | SDL_INIT_EVENTS()
                    | SDL_INIT_JOYSTICK() | SDL_INIT_HAPTIC() | SDL_INIT_GAMECONTROLLER()
                    | SDL_INIT_SENSOR();
            }
        ]
    ];

    # https://github.com/libsdl-org/SDL/blob/main/include/SDL.h
    push @{ $EXPORT_TAGS{default} }, qw[:init];
    attach
        init => {
        SDL_Init          => [ ['uint32'] => 'int' ],
        SDL_InitSubSystem => [ ['uint32'] => 'int' ],
        SDL_QuitSubSystem => [ ['uint32'] ],
        SDL_WasInit       => [ ['uint32'] => 'uint32' ],
        SDL_Quit          => [ [] ],
        },
        unknown => { SDL_SetMainReady => [ [] => 'void' ] };

    # bundled code testing
    #my $holder;
    #die;
    if ( threads_wrapped() ) {
        attach
            events  => { Bundle_SDL_Yield => [ [] ] },
            threads => {
            Bundle_SDL_Wrap_BEGIN => [ [ 'string', 'int', 'opaque' ] ],
            Bundle_SDL_Wrap_END   => [ ['string'] ]
            };
        SDL_Wrap_BEGIN( __PACKAGE__, scalar(@ARGV), \@ARGV );
        END { SDL_Wrap_END(__PACKAGE__) if threads_wrapped() }
    }
    else {
        define events => [ [ SDL_Yield => sub () {1} ], ];
    }

    # Define a four character code as a Uint32
    sub SDL_FOURCC ( $A, $B, $C, $D ) {
        ( ord($A) << 0 ) | ( ord($B) << 8 ) | ( ord($C) << 16 ) | ( ord($D) << 24 );
    }

    # Exts
    # TODO
    package SDL2::Mixer {
        use SDL2::Utils;
        has;
    };

    package SDL2::Mixer::Mix::MusicType {
        use SDL2::Utils;
        has;
    };

    package SDL2::Mixer::Fading {
        use SDL2::Utils;
        has;
    };

    package SDL2::Net {
        use SDL2::Utils;
        has;
    };

    package SDL2::RTF {
        use SDL2::Utils;
        has;
    };

    package SDL2::RTF::Context {
        use SDL2::Utils;
        has;
    };

    package SDL2::RTF::FontEngine {
        use SDL2::Utils;
        has;
    };

    #warn SDL2::SDLK_UP();
    #warn SDL2::SDLK_DOWN();
    # https://github.com/libsdl-org/SDL/blob/main/include/SDL_hints.h
    # Export symbols!
    our @EXPORT_OK = map {@$_} values %EXPORT_TAGS;

    #$EXPORT_TAGS{default} = [];             # Export nothing by default
    $EXPORT_TAGS{all} = \@EXPORT_OK;    # Export everything with :all tag

    #use Data::Dump;
    #ddx \%EXPORT_TAGS;
    #ddx \%SDL2::;
};
1;

=encoding utf-8

=head1 NAME

SDL2::FFI - FFI Wrapper for SDL (Simple DirectMedia Layer) Development Library

=head1 SYNOPSIS

    use SDL2::FFI qw[:all];
    die 'Error initializing SDL: ' . SDL_GetError() unless SDL_Init(SDL_INIT_VIDEO) == 0;
    my $win = SDL_CreateWindow( 'Example window!',
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 640, 480, SDL_WINDOW_RESIZABLE );
    die 'Could not create window: ' . SDL_GetError() unless $win;
    my $event = SDL2::Event->new;
    SDL_Init(SDL_INIT_VIDEO);
    my $renderer = SDL_CreateRenderer( $win, -1, 0 );
    SDL_SetRenderDrawColor( $renderer, 242, 242, 242, 255 );
    do {
        SDL_WaitEventTimeout( $event, 10 );
        SDL_RenderClear($renderer);
        SDL_RenderPresent($renderer);
    } until $event->type == SDL_QUIT;
    SDL_DestroyRenderer($renderer);
    SDL_DestroyWindow($win);
    SDL_Quit();

=head1 DESCRIPTION

SDL2::FFI is an L<FFI::Platypus> backed bindings to the B<S>imple
B<D>irectMedia B<L>ayer - a cross-platform development library designed to
provide low level access to audio, keyboard, mouse, joystick, and graphics
hardware.

=head1 Initialization and Shutdown

The functions in this category are used to set SDL up for use and generally
have global effects in your program. These functions may be imported with the
C<:init> or C<:default> tag.

=head2 C<SDL_Init( ... )>

Initializes the SDL library. This must be called before using most other SDL
functions.

	SDL_Init( SDL_INIT_TIMER | SDL_INIT_VIDEO | SDL_INIT_EVENTS );

C<SDL_Init( ... )> simply forwards to calling L<< C<SDL_InitSubSystem( ...
)>|/C<SDL_InitSubSystem( ... )> >>. Therefore, the two may be used
interchangeably. Though for readability of your code L<< C<SDL_InitSubSystem(
... )>|/C<SDL_InitSubSystem( ... )> >> might be preferred.

The file I/O (for example: C<SDL_RWFromFile( ... )>) and threading
(C<SDL_CreateThread( ... )>) subsystems are initialized by default. Message
boxes (C<SDL_ShowSimpleMessageBox( ... )>) also attempt to work without
initializing the video subsystem, in hopes of being useful in showing an error
dialog when SDL_Init fails. You must specifically initialize other subsystems
if you use them in your application.

Logging (such as C<SDL_Log( ... )>) works without initialization, too.

Expected parameters include:

=over

=item C<flags> which may be any be imported with the L<< C<:init>|SDL2::Enum/C<:init> >> tag and may be OR'd together

=back

Subsystem initialization is ref-counted, you must call L<< C<SDL_QuitSubSystem(
... )>|/C<SDL_QuitSubSystem( ... )> >> for each L<< C<SDL_InitSubSystem( ...
)>|/C<SDL_InitSubSystem( ... )> >> to correctly shutdown a subsystem manually
(or call L<< C<SDL_Quit( )>|/C<SDL_Quit( )> >> to force shutdown). If a
subsystem is already loaded then this call will increase the ref-count and
return.

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_InitSubSystem( ... )>

Compatibility function to initialize the SDL library.

In SDL2, this function and L<< C<SDL_Init( ... )>|/C<SDL_Init( ... )> >> are
interchangeable.

	SDL_InitSubSystem( SDL_INIT_TIMER | SDL_INIT_VIDEO | SDL_INIT_EVENTS );

Expected parameters include:

=over

=item C<flags> which may be any be imported with the L<< C<:init>|SDL2::Enum/C<:init> >> tag and may be OR'd together.

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_QuitSubSystem( ... )>

Shut down specific SDL subsystems.

	SDL_QuitSubSystem( SDL_INIT_VIDEO );

If you start a subsystem using a call to that subsystem's init function (for
example C<SDL_VideoInit( )>) instead of L<< C<SDL_Init( ... )>|/C<SDL_Init( ...
)> >> or L<< C<SDL_InitSubSystem( ... )>|/C<SDL_InitSubSystem( ... )> >>, L<<
C<SDL_QuitSubSystem( ... )>|/C<SDL_QuitSubSystem( ... )> >> and L<<
C<SDL_WasInit( ... )>|/C<SDL_WasInit( ... )> >> will not work. You will need to
use that subsystem's quit function (C<SDL_VideoQuit( )> directly instead. But
generally, you should not be using those functions directly anyhow; use L<<
C<SDL_Init( ... )>|/C<SDL_Init( ... )> >> instead.

You still need to call L<< C<SDL_Quit( )>|/C<SDL_Quit( )> >> even if you close
all open subsystems with L<< C<SDL_QuitSubSystem( ... )>|/C<SDL_QuitSubSystem(
... )> >>.

Expected parameters include:

=over

=item C<flags> which may be any be imported with the L<< C<:init>|SDL2::Enum/C<:init> >> tag and may be OR'd together.

=back

=head2 C<SDL_WasInit( ... )>

Get a mask of the specified subsystems which are currently initialized.

	SDL_Init( SDL_INIT_VIDEO | SDL_INIT_AUDIO );
	warn SDL_WasInit( SDL_INIT_TIMER ); # false
	warn SDL_WasInit( SDL_INIT_VIDEO ); # true (32 == SDL_INIT_VIDEO)
	my $mask = SDL_WasInit( );
	warn 'video init!'  if ($mask & SDL_INIT_VIDEO); # yep
	warn 'video timer!' if ($mask & SDL_INIT_TIMER); # nope

Expected parameters include:

=over

=item C<flags> which may be any be imported with the L<< C<:init>|SDL2::Enum/C<:init> >> tag and may be OR'd together.

=back

If C<flags> is C<0>, it returns a mask of all initialized subsystems, otherwise
it returns the initialization status of the specified subsystems.

The return value does not include C<SDL_INIT_NOPARACHUTE>.

=head2 C<SDL_Quit( )>

Clean up all initialized subsystems.

	SDL_Quit( );

You should call this function even if you have already shutdown each
initialized subsystem with C<SDL_QuitSubSystem( )>. It is safe to call this
function even in the case of errors in initialization.

If you start a subsystem using a call to that subsystem's init function (for
example C<SDL_VideoInit( )>) instead of L<< C<SDL_Init( ... )>|/C<SDL_Init( ...
)> >> or L<< C<SDL_InitSubSystem( ... )>|/C<SDL_InitSubSystem( ... )> >>, then
you must use that subsystem's quit function (C<SDL_VideoQuit( )>) to shut it
down before calling C<SDL_Quit( )>. But generally, you should not be using
those functions directly anyhow; use L<< C<SDL_Init( ... )>|/C<SDL_Init( ... )>
>> instead.

You can use this function in an C<END { ... }> block to ensure that it is run
when your application is shutdown.

=head1 Defined Values and Enumerations

Defined values may be imported by name or with given tag.

=head2 C<SDL_INIT_*>

These are the flags which may be passed to C<SDL_Init( ... )>.  You should
specify the subsystems which you will be using in your application. These may
be imported with the C<:init> or C<:default> tag.

=over

=item C<SDL_INIT_TIMER>

=item C<SDL_INIT_AUDIO>

=item C<SDL_INIT_VIDEO> - C<SDL_INIT_VIDEO> implies C<SDL_INIT_EVENTS>

=item C<SDL_INIT_JOYSTICK> - C<SDL_INIT_JOYSTICK> implies C<SDL_INIT_EVENTS>

=item C<SDL_INIT_HAPTIC>

=item C<SDL_INIT_GAMECONTROLLER> - C<SDL_INIT_GAMECONTROLLER> implies C<SDL_INIT_JOYSTICK>

=item C<SDL_INIT_EVENTS>

=item C<SDL_INIT_SENSOR>

=item C<SDL_INIT_NOPARACHUTE> - compatibility; this flag is ignored

=item C<SDL_INIT_EVERYTHING>

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

imple irectMedia ayer

=end stopwords

=cut

# Examples:
#  - https://github.com/crust/sdl2-examples
#
