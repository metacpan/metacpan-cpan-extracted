use v5.40;
use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use blib;
use SDL3 qw[:all];
subtest 'Platform Info' => sub {
    imported_ok qw[SDL_GetPlatform SDL_GetRevision];
    my $platform = SDL_GetPlatform();
    ok $platform, "Platform: $platform";
    my $rev = SDL_GetRevision();
    ok $rev, "Revision: $rev";
};
subtest 'Detailed Properties' => sub {
    imported_ok qw[
        SDL_CreateProperties SDL_DestroyProperties
        SDL_SetNumberProperty SDL_GetNumberProperty
        SDL_SetBooleanProperty SDL_GetBooleanProperty
        SDL_SetPointerProperty SDL_GetPointerProperty
    ];
    my $props = SDL_CreateProperties();
    ok $props, 'Created properties';

    # Number
    ok SDL_SetNumberProperty( $props, 'num', 1234 ), 'Set number property';
    is SDL_GetNumberProperty( $props, 'num', 0 ), 1234, 'Get number property';

    # Boolean
    ok SDL_SetBooleanProperty( $props, 'bool', 1 ), 'Set boolean property (true)';
    is SDL_GetBooleanProperty( $props, 'bool', 0 ), 1, 'Get boolean property (true)';

    # Pointer (using a simple scalar ref as a dummy pointer)
    my $dummy = "Hello";
    ok SDL_SetPointerProperty( $props, 'ptr', \$dummy ), 'Set pointer property';
    my $ptr = SDL_GetPointerProperty( $props, 'ptr', undef );
    ok $ptr, 'Get pointer property';
    SDL_DestroyProperties($props);
};
subtest 'CPU Info' => sub {
    imported_ok qw[SDL_GetNumLogicalCPUCores SDL_GetSystemRAM SDL_HasSSE SDL_HasSSE2];
    my $cpus = SDL_GetNumLogicalCPUCores();
    ok $cpus > 0, "CPU count: $cpus";
    my $ram = SDL_GetSystemRAM();
    ok $ram > 0, "System RAM: $ram MB";
    diag "Has SSE: " .  ( SDL_HasSSE()  ? 'Yes' : 'No' );
    diag "Has SSE2: " . ( SDL_HasSSE2() ? 'Yes' : 'No' );
};
done_testing;
