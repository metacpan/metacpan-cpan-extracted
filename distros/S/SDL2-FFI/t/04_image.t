use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Class qw[isa_ok can_ok];
use Test2::Tools::Exception qw[try_ok];
use Path::Tiny;
use lib -d '../t' ? './lib' : 't/lib';
use lib '../lib', 'lib';
#
use SDL2::FFI qw[SDL_RWFromFile SDL_FreeSurface];
use SDL2::Image qw[:all];
#
$|++;
#
my $png = path( ( -d '../t' ? './' : './t/' ) . 'etc/sample.png' );
my $bmp = path( ( -d '../t' ? './' : './t/' ) . 'etc/sample.bmp' );
my $ico = path( ( -d '../t' ? './' : './t/' ) . 'etc/sample.ico' );
my $xpm = path( ( -d '../t' ? './' : './t/' ) . 'etc/sample.xpm' );
my $xcf = path( ( -d '../t' ? './' : './t/' ) . 'etc/sample.xcf' );
my $pcx = path( ( -d '../t' ? './' : './t/' ) . 'etc/sample.pcx' );
my $gif = path( ( -d '../t' ? './' : './t/' ) . 'etc/sample.gif' );
my $jpg = path( ( -d '../t' ? './' : './t/' ) . 'etc/sample.jpg' );
my $tif = path( ( -d '../t' ? './' : './t/' ) . 'etc/sample.tif' );
my $tga = path( ( -d '../t' ? './' : './t/' ) . 'etc/sample.tga' );
my $cur = path( ( -d '../t' ? './' : './t/' ) . 'etc/tiny.cur' );
my $pnm = path( ( -d '../t' ? './' : './t/' ) . 'etc/circle.pnm' );

# Files not created by me:
#   - circle.pnm: https://people.math.sc.edu/Burkardt/data/pnm/pnm.html
#
my $compile_version = SDL2::Version->new();
my $link_version    = IMG_Linked_Version();
SDL_IMAGE_VERSION($compile_version);
diag sprintf 'compiled with SDL_image version: %d.%d.%d', $compile_version->major,
    $compile_version->minor, $compile_version->patch;
diag sprintf 'running with SDL_image version: %d.%d.%d', $link_version->major,
    $link_version->minor, $link_version->patch;
IMG_Init( SDL2::Image::IMG_INIT_PNG() );
#
is IMG_Init(IMG_INIT_PNG), IMG_INIT_PNG, 'IMG_Init( IMG_INIT_PNG ) returned IMG_INIT_PNG';
diag 'Calling IMG_Quit()';
IMG_Quit();
is IMG_Init(), 0, 'IMG_Init( ) returned 0';
#
IMG_SetError( 'myfunc is not implemented! %d was passed in.', 6 );
is IMG_GetError(), 'myfunc is not implemented! 6 was passed in.',
    'IMG_SetError( ... ) and IMG_GetError( ... ) work';
#
my $surface;
isa_ok $surface = IMG_Load($png), ['SDL2::Surface'], 'IMG_Load( ... ) returns a SDL2::Surface';
SDL_FreeSurface($surface);
is IMG_Load('nope.jpeg'), undef, 'IMG_Load( "nope.jpeg" ) returns undef';
is IMG_Load_RW( SDL_RWFromFile( 'nope.jpeg', 'rb' ), 1 ), undef,
    'IMG_Load_RW( ... ) with a fake image does not work';
isa_ok $surface = IMG_Load_RW( SDL_RWFromFile( $png, 'rb' ), 1 ), ['SDL2::Surface'],
    'IMG_Load_RW( ... ) with a real PNG works';
SDL_FreeSurface($surface);
isa_ok $surface = IMG_LoadTyped_RW( SDL_RWFromFile( $png, 'rb' ), 1, 'PNG' ), ['SDL2::Surface'],
    'IMG_LoadTyped_RW( ... ) with a real PNG works';
SDL_FreeSurface($surface);
isa_ok $surface = IMG_LoadCUR_RW( SDL_RWFromFile( $cur, 'rb' ) ), ['SDL2::Surface'],
    'IMG_LoadCUR_RW( ... ) with a real CUR works';
SDL_FreeSurface($surface);
isa_ok $surface = IMG_LoadICO_RW( SDL_RWFromFile( $ico, 'rb' ) ), ['SDL2::Surface'],
    'IMG_LoadICO_RW( ... ) with a real ICO works';
SDL_FreeSurface($surface);
isa_ok $surface = IMG_LoadBMP_RW( SDL_RWFromFile( $bmp, 'rb' ) ), ['SDL2::Surface'],
    'IMG_LoadBMP_RW( ... ) with a real BMP works';
SDL_FreeSurface($surface);
isa_ok $surface = IMG_LoadPNM_RW( SDL_RWFromFile( $pnm, 'rb' ) ), ['SDL2::Surface'],
    'IMG_LoadPNM_RW( ... ) with a real PNM works';
SDL_FreeSurface($surface);
isa_ok $surface = IMG_LoadXPM_RW( SDL_RWFromFile( $xpm, 'rb' ) ), ['SDL2::Surface'],
    'IMG_LoadXPM_RW( ... ) with a real XPM works';
todo 'This dies with an OOM error... weird' => sub {
    diag IMG_GetError()
        unless isa_ok $surface = IMG_LoadXCF_RW( SDL_RWFromFile( $xcf, 'rb' ) ), ['SDL2::Surface'],
        'IMG_LoadXCF_RW( ... ) with a real XCF works';
    SDL_FreeSurface($surface);
};
isa_ok $surface = IMG_LoadPCX_RW( SDL_RWFromFile( $pcx, 'rb' ) ), ['SDL2::Surface'],
    'IMG_LoadPCX_RW( ... ) with a real PCX works';
SDL_FreeSurface($surface);
isa_ok $surface = IMG_LoadGIF_RW( SDL_RWFromFile( $gif, 'rb' ) ), ['SDL2::Surface'],
    'IMG_LoadGIF_RW( ... ) with a real GIF works';
SDL_FreeSurface($surface);
isa_ok $surface = IMG_LoadJPG_RW( SDL_RWFromFile( $jpg, 'rb' ) ), ['SDL2::Surface'],
    'IMG_LoadJPG_RW( ... ) with a real JPEG works';
SDL_FreeSurface($surface);
isa_ok $surface = IMG_LoadTIF_RW( SDL_RWFromFile( $tif, 'rb' ) ), ['SDL2::Surface'],
    'IMG_LoadTIF_RW( ... ) with a real TIF works';
SDL_FreeSurface($surface);
isa_ok $surface = IMG_LoadPNG_RW( SDL_RWFromFile( $png, 'rb' ) ), ['SDL2::Surface'],
    'IMG_LoadPNG_RW( ... ) with a real PNG works';
SDL_FreeSurface($surface);
isa_ok $surface = IMG_LoadTGA_RW( SDL_RWFromFile( $tga, 'rb' ) ), ['SDL2::Surface'],
    'IMG_LoadTGA_RW( ... ) with a real TGA works';
SDL_FreeSurface($surface);
diag 'I do not have an image to test IMG_LoadLBM_RW( ... )';
diag 'I do not have an image to test IMG_LoadXV_RW( ... )';
#
{
    my @lines = grep {defined} map { /^\"(.*)\",?$/; $1 } $xpm->lines();
    diag scalar @lines;
    isa_ok $surface = IMG_ReadXPMFromArray(@lines), ['SDL2::Surface'],
        'IMG_ReadXPMFromArray( ... ) with a real XPM works';
    SDL_FreeSurface($surface);
}
#
ok IMG_isCUR( SDL_RWFromFile( $cur,  'rb' ) ), 'IMG_isCUR( SDL_RWFromFile( $cur, \'rb\' ) )';
ok !IMG_isCUR( SDL_RWFromFile( $jpg, 'rb' ) ), 'IMG_isCUR( SDL_RWFromFile( $jpg, \'rb\' ) ) fails';
ok IMG_isICO( SDL_RWFromFile( $ico,  'rb' ) ), 'IMG_isICO( SDL_RWFromFile( $ico, \'rb\' ) )';
ok !IMG_isICO( SDL_RWFromFile( $jpg, 'rb' ) ), 'IMG_isICO( SDL_RWFromFile( $jpg, \'rb\' ) ) fails';
ok IMG_isBMP( SDL_RWFromFile( $bmp,  'rb' ) ), 'IMG_isBMP( SDL_RWFromFile( $bmp, \'rb\' ) )';
ok !IMG_isBMP( SDL_RWFromFile( $jpg, 'rb' ) ), 'IMG_isBMP( SDL_RWFromFile( $jpg, \'rb\' ) ) fails';
ok IMG_isPNM( SDL_RWFromFile( $pnm,  'rb' ) ), 'IMG_isPNM( SDL_RWFromFile( $pnm, \'rb\' ) )';
ok !IMG_isPNM( SDL_RWFromFile( $jpg, 'rb' ) ), 'IMG_isPNM( SDL_RWFromFile( $jpg, \'rb\' ) ) fails';
ok IMG_isXPM( SDL_RWFromFile( $xpm,  'rb' ) ), 'IMG_isXPM( SDL_RWFromFile( $xpm, \'rb\' ) )';
ok !IMG_isXPM( SDL_RWFromFile( $jpg, 'rb' ) ), 'IMG_isXPM( SDL_RWFromFile( $jpg, \'rb\' ) ) fails';
todo 'This dies with an OOM error... weird' => sub {
    ok IMG_isXCF( SDL_RWFromFile( $xcf, 'rb' ) ), 'IMG_isXCF( SDL_RWFromFile( $xcf, \'rb\' ) )';
};
ok !IMG_isXCF( SDL_RWFromFile( $jpg, 'rb' ) ), 'IMG_isXCF( SDL_RWFromFile( $jpg, \'rb\' ) ) fails';
ok IMG_isPCX( SDL_RWFromFile( $pcx,  'rb' ) ), 'IMG_isPCX( SDL_RWFromFile( $pcx, \'rb\' ) )';
ok !IMG_isPCX( SDL_RWFromFile( $jpg, 'rb' ) ), 'IMG_isPCX( SDL_RWFromFile( $jpg, \'rb\' ) ) fails';
ok IMG_isGIF( SDL_RWFromFile( $gif,  'rb' ) ), 'IMG_isGIF( SDL_RWFromFile( $gif, \'rb\' ) )';
ok !IMG_isGIF( SDL_RWFromFile( $jpg, 'rb' ) ), 'IMG_isGIF( SDL_RWFromFile( $jpg, \'rb\' ) ) fails';
ok IMG_isJPG( SDL_RWFromFile( $jpg,  'rb' ) ), 'IMG_isJPG( SDL_RWFromFile( $jpg, \'rb\' ) )';
ok !IMG_isJPG( SDL_RWFromFile( $gif, 'rb' ) ), 'IMG_isJPG( SDL_RWFromFile( $gif, \'rb\' ) ) fails';
ok IMG_isTIF( SDL_RWFromFile( $tif,  'rb' ) ), 'IMG_isTIF( SDL_RWFromFile( $tif, \'rb\' ) )';
ok !IMG_isTIF( SDL_RWFromFile( $gif, 'rb' ) ), 'IMG_isTIF( SDL_RWFromFile( $gif, \'rb\' ) ) fails';
ok IMG_isPNG( SDL_RWFromFile( $png,  'rb' ) ), 'IMG_isPNG( SDL_RWFromFile( $png, \'rb\' ) )';
ok !IMG_isPNG( SDL_RWFromFile( $gif, 'rb' ) ), 'IMG_isPNG( SDL_RWFromFile( $gif, \'rb\' ) ) fails';
diag 'I do not have an image to test IMG_isLBM( ... )';

#ok IMG_isLBM( SDL_RWFromFile( $lbm,  'rb' ) ), 'IMG_isLBM( SDL_RWFromFile( $lbm, \'rb\' ) )';
ok !IMG_isLBM( SDL_RWFromFile( $gif, 'rb' ) ), 'IMG_isLBM( SDL_RWFromFile( $gif, \'rb\' ) ) fails';
diag 'I do not have an image to test IMG_isXV( ... )';

#ok IMG_isXV( SDL_RWFromFile( $xv,  'rb' ) ), 'IMG_isXV( SDL_RWFromFile( $xv, \'rb\' ) )';
ok !IMG_isXV( SDL_RWFromFile( $gif, 'rb' ) ), 'IMG_isXV( SDL_RWFromFile( $gif, \'rb\' ) ) fails';
#
can_ok $_ for qw[
    SDL_IMG_MAJOR_VERSION
    SDL_IMG_MINOR_VERSION
    SDL_IMG_PATCHLEVEL
    IMG_INIT_JPG
    IMG_INIT_PNG
    IMG_INIT_TIF
    IMG_INIT_WEBP
];
#
done_testing;
