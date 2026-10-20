use v5.40;
use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib 'lib', '../lib', 'blib/lib', '../blib/lib';
use SDL3 qw[:all];
no warnings qw[experimental::builtin];

BEGIN {
    try {
        builtin::load_module('SDL3::TTF');
        SDL3::TTF->import(qw[:all]);
    }
    catch ($e) {
        plan skip_all => 'SDL3::TTF is not available: ' . $e;
    }
}
subtest 'Init & WasInit Lifecycle' => sub {
    imported_ok qw[TTF_Init TTF_WasInit TTF_Quit];
    is TTF_WasInit(), 0, 'TTF is not initialized yet';
    ok TTF_Init(),        'TTF_Init() succeeded';
    ok TTF_WasInit() > 0, 'TTF_WasInit() confirms initialization';
    subtest 'Version & FreeType Query' => sub {    # FreeType version must be queried after TTF_Init(); might as well do it here.
        imported_ok qw[TTF_Version TTF_MAJOR_VERSION TTF_VERSION_ATLEAST TTF_GetFreeTypeVersion];
        my $ver = TTF_Version();
        ok $ver > 0, "TTF_Version returned: $ver";
        is TTF_MAJOR_VERSION(), 3, 'Major version is 3';
        ok TTF_VERSION_ATLEAST( 3, 0, 0 ), 'TTF_VERSION_ATLEAST(3, 0, 0)';
        my ( $maj, $min, $patch ) = ( 0, 0, 0 );
        TTF_GetFreeTypeVersion( \$maj, \$min, \$patch );
        ok $maj > 0, "FreeType version reported: $maj.$min.$patch";
    };
    TTF_Quit();
    is TTF_WasInit(), 0, 'TTF_Quit() deinitialized library';
};
subtest 'Font Metrics & Text Rendering' => sub {
    imported_ok qw[
        TTF_Init TTF_Quit TTF_OpenFont TTF_CloseFont TTF_GetFontSize
        TTF_SetFontStyle TTF_GetFontStyle TTF_STYLE_BOLD
        TTF_GetStringSize TTF_RenderText_Solid SDL_DestroySurface
    ];

    # Scan for standard system fonts across Windows, Linux, and macOS
    my @font_candidates = (
        $ENV{WINDIR} ? "$ENV{WINDIR}/Fonts/arial.ttf" : (),                'C:/Windows/Fonts/arial.ttf',
        'C:/Windows/Fonts/consola.ttf',                                    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
        '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf', '/usr/share/fonts/TTF/DejaVuSans.ttf',
        '/System/Library/Fonts/Helvetica.ttc',                             '/Library/Fonts/Arial.ttf'
    );
    my ($font_file) = grep { -f $_ } @font_candidates;
    if ( !$font_file ) {
        skip_all 'No standard OS TrueType font found; skipping rendering tests';
    }
    diag "Testing with system font: $font_file";
    TTF_Init();
    my $font = TTF_OpenFont( $font_file, 18.0 );
    ok $font, 'TTF_OpenFont loaded font from disk';
    if ($font) {
        my $size = TTF_GetFontSize($font);
        is sprintf( "%.1f", $size ), '18.0', 'Font point size is 18.0';
        TTF_SetFontStyle( $font, TTF_STYLE_BOLD() );
        is TTF_GetFontStyle($font), TTF_STYLE_BOLD(), 'TTF_SetFontStyle set to BOLD';

        # Measure text string
        my ( $w, $h ) = ( 0, 0 );
        ok TTF_GetStringSize( $font, 'Hello SDL3', 0, \$w, \$h ), 'TTF_GetStringSize measured text';
        ok $w > 0,                                                "Measured width: $w px";
        ok $h > 0,                                                "Measured height: $h px";

        # Render solid text to an 8-bit surface
        my $color = { r => 255, g => 255, b => 255, a => 255 };
        my $surf  = TTF_RenderText_Solid( $font, 'Hello SDL3', 0, $color );
        ok $surf, 'TTF_RenderText_Solid returned SDL_Surface';
        if ($surf) {
            ok $surf->{w} >= $w, 'Rendered surface width matches expectation';
            SDL_DestroySurface($surf);
        }
        TTF_CloseFont($font);
    }
    TTF_Quit();
};
#
done_testing;
