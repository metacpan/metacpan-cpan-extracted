#include <ffi_platypus_bundle.h>
#include <libtcod.h>

void PERL_console_clear(
    TCOD_console_t con,
    TCOD_color_t*  fg,
    TCOD_color_t*  bg,
    int ch
) {
    if ( fg == NULL ) {
        fg = &con->fore;
    }

    if ( bg == NULL ) {
        bg = &con->back;
    }

    struct TCOD_ConsoleTile fill = {
        ch,
        { fg->r, fg->g, fg->b, 255 },
        { bg->r, bg->g, bg->b, 255 },
    };

    for ( int i = 0; i < con->elements; ++i ) {
        con->tiles[i] = fill;
    }
}
