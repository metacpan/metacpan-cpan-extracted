use v5.40;
use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib 'lib', '../lib', 'blib/lib', '../blib/lib';
use SDL3 qw[:all];
no warnings qw[experimental::builtin];

BEGIN {
    try {
        builtin::load_module('SDL3::Image');
        SDL3::Image->import(qw[:all]);
    }
    catch ($e) {
        plan skip_all => 'SDL3::Image is not available: ' . $e;
    }
}

# Helper to produce a tiny 16x16 red uncompressed 24-bit BMP in memory
sub make_test_bmp {
    my ( $w, $h ) = ( 16, 16 );
    my $row_bytes = ( $w * 3 + 3 ) & ~3;
    my $img_size  = $row_bytes * $h;
    my $file_size = 54 + $img_size;
    my $header    = pack 'a2 V v v V V V V v v V V V V V V', 'BM', $file_size, 0, 0, 54, 40, $w, $h, 1, 24, 0, $img_size, 2835, 2835, 0, 0;

    # BGR for pure red: 0x00, 0x00, 0xFF (row_bytes = 48, so no padding needed)
    my $pixels = ( pack( 'C3', 0, 0, 255 ) x $w ) x $h;
    return $header . $pixels;
}
subtest 'Version & Metadata' => sub {
    imported_ok qw[IMG_Version IMG_MAJOR_VERSION IMG_MINOR_VERSION IMG_MICRO_VERSION IMG_VERSION_ATLEAST];
    my $ver = IMG_Version();
    ok $ver > 0, "IMG_Version returned: $ver";
    is IMG_MAJOR_VERSION(), 3, 'Major version is 3';
    ok IMG_VERSION_ATLEAST( 3, 0, 0 ), 'IMG_VERSION_ATLEAST(3, 0, 0)';
};
subtest 'Format Detection (IMG_is*)' => sub {
    imported_ok qw[IMG_isBMP IMG_isPNG SDL_IOFromConstMem SDL_CloseIO];
    my $bmp    = make_test_bmp();
    my $stream = SDL_IOFromConstMem( \$bmp, length($bmp) );
    ok $stream, 'Created SDL_IOStream from memory buffer';
    if ($stream) {
        ok IMG_isBMP($stream),  'IMG_isBMP recognizes BMP stream';
        ok !IMG_isPNG($stream), 'IMG_isPNG returns false for BMP stream';
        SDL_CloseIO($stream);
    }
};
subtest 'Surface Loading (IMG_Load_IO)' => sub {
    imported_ok qw[IMG_Load_IO SDL_IOFromConstMem SDL_DestroySurface];
    my $bmp    = make_test_bmp();
    my $stream = SDL_IOFromConstMem( \$bmp, length($bmp) );

    # closeio = 1 (SDL closes stream automatically)
    my $surf = IMG_Load_IO( $stream, 1 );
    ok $surf, 'IMG_Load_IO decoded memory BMP into SDL_Surface';
    if ($surf) {
        is $surf->{w}, 16, 'Decoded surface width is 16';
        is $surf->{h}, 16, 'Decoded surface height is 16';
        SDL_DestroySurface($surf);
        pass 'Destroyed surface';
    }
};
subtest 'Texture Loading (IMG_LoadTexture_IO)' => sub {
    imported_ok qw[
        SDL_SetHint SDL_HINT_VIDEO_DRIVER SDL_Init SDL_Quit SDL_INIT_VIDEO
        SDL_CreateWindowAndRenderer SDL_DestroyRenderer SDL_DestroyWindow
        SDL_GetTextureSize SDL_DestroyTexture IMG_LoadTexture_IO SDL_IOFromConstMem
    ];
    SDL_SetHint( SDL_HINT_VIDEO_DRIVER, 'dummy' );
    ok SDL_Init(SDL_INIT_VIDEO), 'Initialized video with dummy driver';
    my ( $win, $ren );

    if ( SDL_CreateWindowAndRenderer( 'Image Test', 64, 64, 0, \$win, \$ren ) ) {
        my $bmp    = make_test_bmp();
        my $stream = SDL_IOFromConstMem( \$bmp, length($bmp) );
        my $tex    = IMG_LoadTexture_IO( $ren, $stream, 1 );
        ok $tex, 'IMG_LoadTexture_IO created GPU texture';
        if ($tex) {
            my ( $tw, $th ) = ( 0.0, 0.0 );
            SDL_GetTextureSize( $tex, \$tw, \$th );
            is $tw, 16.0, 'Texture width matches';
            is $th, 16.0, 'Texture height matches';
            SDL_DestroyTexture($tex);
        }
        SDL_DestroyRenderer($ren);
        SDL_DestroyWindow($win);
    }
    else {
        skip_all 'Could not create dummy window/renderer';
    }
    SDL_Quit();
};
#
done_testing;
