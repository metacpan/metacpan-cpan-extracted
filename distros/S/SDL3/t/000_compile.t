use v5.40;
use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib 'lib', '../lib', 'blib/lib', '../blib/lib';
use SDL3 qw[:all];
#
ok $SDL3::VERSION, 'SDL3::VERSION: ' . $SDL3::VERSION;
subtest ':hints' => sub {
    imported_ok qw[SDL_SetHint SDL_GetHint SDL_HINT_VIDEO_DRIVER];
    diag 'Force the dummy driver so this runs on servers/CI without displays';

    # This is important for many of the following tests.
    ok SDL_SetHint( SDL_HINT_VIDEO_DRIVER, 'dummy' ), 'Set video driver to dummy';
    is SDL_GetHint(SDL_HINT_VIDEO_DRIVER), 'dummy', 'Verified video driver hint';
};
subtest ':init' => sub {
    imported_ok qw[SDL_Init SDL_Quit SDL_WasInit SDL_INIT_VIDEO SDL_INIT_EVENTS];

    # Initialize video (which implies events)
    ok SDL_Init( SDL_INIT_VIDEO | SDL_INIT_EVENTS ), 'SDL_Init(VIDEO | EVENTS)';
    is SDL_WasInit(SDL_INIT_VIDEO), SDL_INIT_VIDEO, 'SDL_WasInit confirms VIDEO is initialized';
};
subtest ':clipboard' => sub {    # This must come after SDL_Init...
    imported_ok qw[SDL_SetClipboardText SDL_GetClipboardText];
    ok SDL_SetClipboardText('Perl SDL3 Rocks'), 'Set clipboard text';

    # On some strict headless CI (like minimal docker containers),
    # clipboard internal operations might fail or return empty strings.
    # We check if the call didn't crash, but getting the value back depends on OS support.
    my $txt = SDL_GetClipboardText();
    diag "Clipboard contains: " . ( $txt // '<undef>' );
};
subtest ':error' => sub {
    imported_ok qw[SDL_SetError SDL_GetError SDL_ClearError];
    is SDL_SetError('Test Error'), F(),          'SDL_SetError(...)';
    is SDL_GetError(),             'Test Error', 'SDL_SetError set the message correctly';
    SDL_ClearError();
    is SDL_GetError(), "", 'SDL_ClearError cleared message';
};
subtest ':stdinc' => sub {
    imported_ok qw[SDL_malloc SDL_free SDL_strcmp SDL_strlen SDL_memcpy];

    # Test Memory Allocation
    my $ptr = SDL_malloc(1024);
    ok $ptr, 'SDL_malloc allocated memory';
    SDL_free($ptr);
    pass 'SDL_free executed';

    # Test Strings
    is SDL_strlen('Hello'),          5, 'SDL_strlen calculations correct';
    is SDL_strcmp( 'foo', 'foo' ),   0, 'SDL_strcmp match';
    isnt SDL_strcmp( 'foo', 'bar' ), 0, 'SDL_strcmp mismatch';
};
subtest ':rect' => sub {
    imported_ok qw[SDL_HasRectIntersection SDL_GetRectUnion];
    my $rect_a = { x => 0,   y => 0,   w => 100, h => 100 };
    my $rect_b = { x => 50,  y => 50,  w => 100, h => 100 };
    my $rect_c = { x => 200, y => 200, w => 10,  h => 10 };
    ok SDL_HasRectIntersection( $rect_a,  $rect_b ), 'Rect A and B intersect';
    ok !SDL_HasRectIntersection( $rect_a, $rect_c ), 'Rect A and C do not intersect';
    my $union = { x => 0, y => 0, w => 0, h => 0 };    # Storage for result
    ok SDL_GetRectUnion( $rect_a, $rect_b, $union ), 'Calculated union';
    is $union->{w}, 150, 'Union width';
    is $union->{h}, 150, 'Union height';
};
subtest ':properties' => sub {
    imported_ok qw[SDL_CreateProperties SDL_SetStringProperty SDL_GetStringProperty SDL_DestroyProperties];
    my $props_id = SDL_CreateProperties();
    ok $props_id,                                        'Created Properties ID: ' . $props_id;
    ok SDL_SetStringProperty( $props_id, 'foo', 'bar' ), 'Set string property';
    is SDL_GetStringProperty( $props_id, 'foo',     'default' ), 'bar',     'Get string property';
    is SDL_GetStringProperty( $props_id, 'missing', 'default' ), 'default', 'Get default for missing property';
    SDL_DestroyProperties($props_id);
};
subtest ':filesystem' => sub {
    imported_ok qw[SDL_GetBasePath SDL_GetPrefPath];
    my $base = SDL_GetBasePath();
    ok $base, 'Base Path: ' . $base;

    # Note: PrefPath creates the directory if it doesn't exist
    my $pref = SDL_GetPrefPath( 'MyOrg', 'MyApp' );
    ok $pref, 'Pref Path: ' . $pref;
};
subtest ':surface' => sub {    # Should be safe for a headless smoker because we use a software renderer
    imported_ok qw[SDL_CreateSurface SDL_FillSurfaceRect SDL_DestroySurface SDL_PIXELFORMAT_RGBA8888];
    #
    my $surf = SDL_CreateSurface( 10, 10, SDL_PIXELFORMAT_RGBA8888 );
    ok $surf, 'Created 10x10 Surface';

    # Fill with Red (R=255, G=0, B=0, A=255)
    my $rect = { x => 0, y => 0, w => 5, h => 5 };
    ok SDL_FillSurfaceRect( $surf, $rect, 0xFF0000FF ), 'Filled rect on surface';
    SDL_DestroySurface($surf);
};
subtest ':timer' => sub {
    imported_ok qw[SDL_GetTicks SDL_Delay];
    my $start = SDL_GetTicks();
    SDL_Delay(50);    # 50ms pause
    my $end = SDL_GetTicks();
    ok $end > $start, sprintf 'Time moved forward (Start: %d, End: %d)', $start, $end;
};
subtest ':version' => sub {
    imported_ok qw[
        SDL_GetVersion SDL_MAJOR_VERSION SDL_MINOR_VERSION SDL_MICRO_VERSION
        SDL_VERSIONNUM SDL_VERSIONNUM_MAJOR SDL_VERSIONNUM_MINOR SDL_VERSIONNUM_MICRO
        SDL_VERSION SDL_VERSION_ATLEAST
    ];
    diag 'SDL_GetVersion() == ' . SDL_GetVersion();
    is SDL_MAJOR_VERSION(), 3, 'we should be using SDL3';
    diag 'SDL_MAJOR_VERSION == ' . SDL_MAJOR_VERSION();
    diag 'SDL_MINOR_VERSION == ' . SDL_MINOR_VERSION();
    diag 'SDL_MICRO_VERSION == ' . SDL_MICRO_VERSION();
    is SDL_VERSIONNUM( 1, 2, 3 ), '1002003', 'SDL_VERSIONNUM(1, 2, 3)';
    is SDL_VERSIONNUM( SDL_MAJOR_VERSION, SDL_MINOR_VERSION, SDL_MICRO_VERSION ), SDL_GetVersion(),
        'SDL_VERSIONNUM(SDL_MAJOR_VERSION, SDL_MINOR_VERSION, SDL_MICRO_VERSION)';
    is SDL_VERSION(), SDL_GetVersion(), 'SDL_VERSION()';
    is SDL_VERSION_ATLEAST( SDL_MAJOR_VERSION, SDL_MINOR_VERSION, SDL_MICRO_VERSION ), T(),
        'SDL_VERSION_ATLEAST( SDL_MAJOR_VERSION, SDL_MINOR_VERSION, SDL_MICRO_VERSION ) == true';
    is SDL_VERSION_ATLEAST( SDL_MAJOR_VERSION, SDL_MINOR_VERSION, SDL_MICRO_VERSION() + 10 ), F(),
        'SDL_VERSION_ATLEAST( SDL_MAJOR_VERSION, SDL_MINOR_VERSION, SDL_MICRO_VERSION + 10 ) == false';
};
subtest ':video' => sub {    # This might not work on a headless system...
    imported_ok qw[SDL_CreateWindow SDL_DestroyWindow SDL_GetWindowFlags SDL_WINDOW_HIDDEN];

    # We use the _HIDDEN flag just to be extra polite to the OS,
    # though the dummy driver won't show anything anyway.
    my $win = SDL_CreateWindow( 'Headless Test', 640, 480, SDL_WINDOW_HIDDEN );
    ok $win, 'Created Window (Dummy driver)';
    my $flags = SDL_GetWindowFlags($win);
    ok( ( $flags & SDL_WINDOW_HIDDEN ), 'Window has HIDDEN flag' );
    SDL_DestroyWindow($win);
};
#
SDL_Quit();
#
done_testing;
