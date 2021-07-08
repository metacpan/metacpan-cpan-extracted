package SDL2::Window {
    use SDL2::Utils;
    has
        magic                 => 'opaque',
        id                    => 'uint32',
        title                 => 'opaque',         # char *
        icon                  => 'SDL_Surface',
        x                     => 'int',
        y                     => 'int',
        w                     => 'int',
        h                     => 'int',
        min_w                 => 'int',
        min_h                 => 'int',
        max_w                 => 'int',
        max_h                 => 'int',
        flags                 => 'uint32',
        last_fullscreen_flags => 'uint32',
        windowed              => 'SDL_Rect',
        fullscreen_mode       => 'opaque',         # SDL_DisplayMode
        opacity               => 'float',
        brightness            => 'float',
        gamma                 => 'uint16[255]',    # uint16*
        saved_gamma           => 'uint16[255]',    # uint16*
        surface               => 'opaque',         # SDL_Surface*
        surface_valid         => 'bool',
        is_hiding             => 'bool',
        is_destroying         => 'bool',
        is_dropping           => 'bool',
        shaper                => 'opaque',         # SDL_WindowShaper
        hit_test              => 'opaque',         # SDL_HitTest
        hit_test_data         => 'opaque',         # void*
        data                  => 'opaque',         # SDL_WindowUserData*
        driverdata            => 'opaque',         # void*
        prev                  => 'opaque',         # SDL_Window*
        next                  => 'opaque'          # SDL_Window*
        ;

=encoding utf-8

=head1 NAME

SDL2::Window - Information About the Version of SDL in Use

=head1 SYNOPSIS

    use SDL2 qw[:all];
    SDL_Init(SDL_INIT_VIDEO);    # Initialize SDL2

    # Create an application window with the following settings;
    my $window = SDL_CreateWindow(
        'An SDL2 window',           # window title
        SDL_WINDOWPOS_UNDEFINED,    # initial x position
        SDL_WINDOWPOS_UNDEFINED,    # initial y position
        640,                        # width, in pixels
        480,                        # height, in pixels
        SDL_WINDOW_OPENGL           # flags
    );

    # Check that the window was successfully created
    exit printf 'Could not create window: %s', SDL_GetError() if !defined $window;

    # The window is open: could enter program loop here (see SDL__PollEvent())
    sleep 5;                       # Pause execution for 5 secconds, for example
    SDL_DestroyWindow($window);    # Close and destory the window
    SDL_Quit();                    # Clean up
    exit;

=head1 DESCRIPTION

SDL2::Window

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords



=end stopwords

=cut

};
1;
