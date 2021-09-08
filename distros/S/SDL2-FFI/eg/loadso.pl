use strict;
use warnings;
use experimental 'signatures';
use lib '../lib';
use SDL2::FFI qw[:all -assert=3];
$|++;
#
if ( @ARGV < 2 ) {
    SDL_Log( "USAGE: %s <library> <functionname>\n",  $0 );    # /usr/lib/libc.so.6 strftime
    SDL_Log( "       %s --hello <lib with puts()>\n", $0 );    # --hello /usr/lib/libc.so.6
    exit 1;
}
my $hello = 0;
my ( $libname, $symname ) = @ARGV;
if ( $libname eq '--hello' ) {
    $hello   = 1;
    $libname = $symname;
    $symname = 'puts';
}

# Initialize SDL
if ( SDL_Init(0) < 0 ) {
    SDL_LogError( SDL_LOG_CATEGORY_APPLICATION, "Couldn't initialize SDL: %s\n", SDL_GetError() );
    exit 2;
}
my $lib = SDL_LoadObject($libname);
if ( !defined $lib ) {
    SDL_LogError( SDL_LOG_CATEGORY_APPLICATION, "SDL_LoadObject('%s') failed: %s\n",
        $libname, SDL_GetError() );
    exit 3;
}
else {
    my $fn = SDL_LoadFunction( $lib, $symname, $hello ? ( ['string'], 'int' ) : () );
    if ( !defined $fn ) {
        SDL_LogError( SDL_LOG_CATEGORY_APPLICATION, "SDL_LoadFunction('%s') failed: %s\n",
            $symname, SDL_GetError() );
        exit 4;
    }
    else {
        SDL_Log( "Found %s in %s at %p\n", $symname, $libname, $fn );
        if ($hello) {
            SDL_Log("Calling function...\n");
            $fn->("     HELLO, WORLD!\r\n");
            SDL_Log("...apparently, we survived.  :)\n");
            SDL_Log("Unloading library...\n");
        }
    }
    SDL_UnloadObject($lib);
}
SDL_Quit();
