use v5.40;
use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib 'lib', '../lib', 'blib/lib', '../blib/lib';
use SDL3 qw[:all];

# Pre-test: Set the dummy driver
SDL_SetHint( SDL_HINT_VIDEO_DRIVER, 'dummy' );
SDL_Init(SDL_INIT_VIDEO);
subtest 'Renderer and Texture' => sub {
    imported_ok qw[
        SDL_CreateWindowAndRenderer SDL_DestroyRenderer SDL_DestroyWindow
        SDL_CreateTexture SDL_DestroyTexture SDL_GetTextureSize
        SDL_PIXELFORMAT_RGBA8888 SDL_TEXTUREACCESS_STATIC
    ];
    my ( $win, $ren );
    ok SDL_CreateWindowAndRenderer( 'Test', 640, 480, 0, \$win, \$ren ), 'CreateWindowAndRenderer';
    if ($ren) {
        my $tex = SDL_CreateTexture( $ren, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STATIC, 100, 100 );
        ok $tex, 'CreateTexture (RGBA8888)';
        if ($tex) {
            my ( $w, $h ) = ( 0.0, 0.0 );
            ok SDL_GetTextureSize( $tex, \$w, \$h ), 'GetTextureSize';
            is $w, 100.0, 'Texture width matches';
            is $h, 100.0, 'Texture height matches';
            SDL_DestroyTexture($tex);
        }
        SDL_DestroyRenderer($ren);
    }
    SDL_DestroyWindow($win) if $win;
};
subtest 'Pixel Format Macros' => sub {
    imported_ok qw[SDL_DEFINE_PIXELFORMAT SDL_PIXELFORMAT_RGBA8888];

    # Verify the constant matches the macro result
    # SDL_PIXELFORMAT_RGBA8888 should be:
    # (1 << 28) | (SDL_PIXELTYPE_PACKED32 << 24) | (SDL_PACKEDORDER_RGBA << 20) | (SDL_PACKEDLAYOUT_8888 << 16) | (32 << 8) | (4 << 0)
    # SDL_PIXELTYPE_PACKED32 is 6
    # SDL_PACKEDORDER_RGBA is 4
    # SDL_PACKEDLAYOUT_8888 is 6
    # (1 << 28) | (6 << 24) | (4 << 20) | (6 << 16) | (32 << 8) | 4
    # 0x10000000 | 0x06000000 | 0x00400000 | 0x00060000 | 0x00002000 | 0x00000004 = 0x16462004
    is SDL_PIXELFORMAT_RGBA8888(), 0x16462004, 'SDL_PIXELFORMAT_RGBA8888 is correct';

    # SDL_PIXELTYPE_PACKED32=6, SDL_PACKEDORDER_RGBA=4, SDL_PACKEDLAYOUT_8888=6, bits=32, bytes=4
    my $calc = SDL_DEFINE_PIXELFORMAT( 6, 4, 6, 32, 4 );
    is $calc, SDL_PIXELFORMAT_RGBA8888(), 'SDL_DEFINE_PIXELFORMAT matches constant';
};
SDL_Quit();
done_testing;
