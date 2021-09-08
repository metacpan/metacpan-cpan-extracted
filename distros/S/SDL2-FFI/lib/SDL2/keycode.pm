package SDL2::keycode 0.01 {
    use SDL2::Utils;
    use experimental 'signatures';
    #
    use SDL2::stdinc;
    use SDL2::scancode;
    #
    ffi->type( 'sint32' => 'SDL_Keycode' );
    define keycode => [
        [ SDLK_SCANCODE_MASK      => ( 1 << 30 ) ],
        [ SDL_SCANCODE_TO_KEYCODE => sub ($X) { ( $X | SDL2::FFI::SDLK_SCANCODE_MASK() ) } ]
    ];
    enum SDL_KeyCode => [
        [ SDLK_UNKNOWN   => 0 ],        [ SDLK_RETURN  => ord "\r" ], [ SDLK_ESCAPE => ord "\x1B" ],
        [ SDLK_BACKSPACE => ord "\b" ], [ SDLK_TAB     => ord "\t" ], [ SDLK_SPACE  => ord ' ' ],
        [ SDLK_EXCLAIM  => ord '!' ], [ SDLK_QUOTEDBL  => ord '"' ], [ SDLK_HASH       => ord '#' ],
        [ SDLK_PERCENT  => ord '%' ], [ SDLK_DOLLAR    => ord '$' ], [ SDLK_AMPERSAND  => ord '&' ],
        [ SDLK_QUOTE    => ord "'" ], [ SDLK_LEFTPAREN => ord '(' ], [ SDLK_RIGHTPAREN => ord ')' ],
        [ SDLK_ASTERISK => ord '*' ], [ SDLK_PLUS      => ord '+' ], [ SDLK_COMMA      => ord ',' ],
        [ SDLK_MINUS    => ord '-' ], [ SDLK_PERIOD    => ord '.' ], [ SDLK_SLASH      => ord '/' ],
        [ SDLK_0 => ord '0' ], [ SDLK_1 => ord '1' ], [ SDLK_2 => ord '2' ], [ SDLK_3 => ord '3' ],
        [ SDLK_4 => ord '4' ], [ SDLK_5 => ord '5' ], [ SDLK_6 => ord '6' ], [ SDLK_7 => ord '7' ],
        [ SDLK_8         => ord '8' ], [ SDLK_9        => ord '9' ], [ SDLK_COLON  => ord ':' ],
        [ SDLK_SEMICOLON => ord ';' ], [ SDLK_LESS     => ord '<' ], [ SDLK_EQUALS => ord '=' ],
        [ SDLK_GREATER   => ord '>' ], [ SDLK_QUESTION => ord '?' ], [ SDLK_AT     => ord '@' ],

        # Skip uppercase letters
        [ SDLK_LEFTBRACKET  => ord '[' ],
        [ SDLK_BACKSLASH    => ord "\\" ],
        [ SDLK_RIGHTBRACKET => ord ']' ],
        [ SDLK_CARET        => ord '^' ],
        [ SDLK_UNDERSCORE   => ord '_' ],
        [ SDLK_BACKQUOTE    => ord '`' ],
        [ SDLK_a            => ord 'a' ],
        [ SDLK_b            => ord 'b' ],
        [ SDLK_c            => ord 'c' ],
        [ SDLK_d            => ord 'd' ],
        [ SDLK_e            => ord 'e' ],
        [ SDLK_f            => ord 'f' ],
        [ SDLK_g            => ord 'g' ],
        [ SDLK_h            => ord 'h' ],
        [ SDLK_i            => ord 'i' ],
        [ SDLK_j            => ord 'j' ],
        [ SDLK_k            => ord 'k' ],
        [ SDLK_l            => ord 'l' ],
        [ SDLK_m            => ord 'm' ],
        [ SDLK_n            => ord 'n' ],
        [ SDLK_o            => ord 'o' ],
        [ SDLK_p            => ord 'p' ],
        [ SDLK_q            => ord 'q' ],
        [ SDLK_r            => ord 'r' ],
        [ SDLK_s            => ord 's' ],
        [ SDLK_t            => ord 't' ],
        [ SDLK_u            => ord 'u' ],
        [ SDLK_v            => ord 'v' ],
        [ SDLK_w            => ord 'w' ],
        [ SDLK_x            => ord 'x' ],
        [ SDLK_y            => ord 'y' ],
        [ SDLK_z            => ord 'z' ],
        [   SDLK_CAPSLOCK => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_CAPSLOCK() );
            }
        ],
        [   SDLK_F1 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F1() ) }
        ],
        [   SDLK_F2 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F2() ) }
        ],
        [   SDLK_F3 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F3() ) }
        ],
        [   SDLK_F4 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F4() ) }
        ],
        [   SDLK_F5 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F5() ) }
        ],
        [   SDLK_F6 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F6() ) }
        ],
        [   SDLK_F7 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F7() ) }
        ],
        [   SDLK_F8 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F8() ) }
        ],
        [   SDLK_F9 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F9() ) }
        ],
        [   SDLK_F10 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F10() ) }
        ],
        [   SDLK_F11 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F11() ) }
        ],
        [   SDLK_F12 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F12() ) }
        ],
        [   SDLK_PRINTSCREEN => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_PRINTSCREEN() );
            }
        ],
        [   SDLK_SCROLLLOCK => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_SCROLLLOCK() );
            }
        ],
        [   SDLK_PAUSE =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_PAUSE() ) }
        ],
        [   SDLK_INSERT => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_INSERT() );
            }
        ],
        [   SDLK_HOME =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_HOME() ) }
        ],
        [   SDLK_PAGEUP => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_PAGEUP() );
            }
        ],
        [ SDLK_DELETE => ord "\x7F" ],
        [   SDLK_END =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_END() ) }
        ],
        [   SDLK_PAGEDOWN => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_PAGEDOWN() );
            }
        ],
        [   SDLK_RIGHT =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_RIGHT() ) }
        ],
        [   SDLK_LEFT =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_LEFT() ) }
        ],
        [   SDLK_DOWN =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_DOWN() ) }
        ],
        [   SDLK_UP =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_UP() ) }
        ],
        [   SDLK_NUMLOCKCLEAR => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_NUMLOCKCLEAR() );
            }
        ],
        [   SDLK_KP_DIVIDE =>
                sub () { SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_DIVIDE() ) }
        ],
        [   SDLK_KP_MULTIPLY => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_MULTIPLY() );
            }
        ],
        [   SDLK_KP_MINUS => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_MINUS() );
            }
        ],
        [   SDLK_KP_PLUS => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_PLUS() );
            }
        ],
        [   SDLK_KP_ENTER => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_ENTER() );
            }
        ],
        [   SDLK_KP_1 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_1() ) }
        ],
        [   SDLK_KP_2 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_2() ) }
        ],
        [   SDLK_KP_3 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_3() ) }
        ],
        [   SDLK_KP_4 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_4() ) }
        ],
        [   SDLK_KP_5 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_5() ) }
        ],
        [   SDLK_KP_6 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_6() ) }
        ],
        [   SDLK_KP_7 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_7() ) }
        ],
        [   SDLK_KP_8 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_8() ) }
        ],
        [   SDLK_KP_9 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_9() ) }
        ],
        [   SDLK_KP_0 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_0() ) }
        ],
        [   SDLK_KP_PERIOD => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_PERIOD() );
            }
        ],
        [   SDLK_APPLICATION => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_APPLICATION() );
            }
        ],
        [   SDLK_POWER =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_POWER() ) }
        ],
        [   SDLK_KP_EQUALS => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_EQUALS() );
            }
        ],
        [   SDLK_F13 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F13() ) }
        ],
        [   SDLK_F14 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F14() ) }
        ],
        [   SDLK_F15 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F15() ) }
        ],
        [   SDLK_F16 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F16() ) }
        ],
        [   SDLK_F17 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F17() ) }
        ],
        [   SDLK_F18 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F18() ) }
        ],
        [   SDLK_F19 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F19() ) }
        ],
        [   SDLK_F20 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F20() ) }
        ],
        [   SDLK_F21 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F21() ) }
        ],
        [   SDLK_F22 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F22() ) }
        ],
        [   SDLK_F23 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F23() ) }
        ],
        [   SDLK_F24 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_F24() ) }
        ],
        [   SDLK_EXECUTE => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_EXECUTE() );
            }
        ],
        [   SDLK_HELP =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_HELP() ) }
        ],
        [   SDLK_MENU =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_MENU() ) }
        ],
        [   SDLK_SELECT => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_SELECT() );
            }
        ],
        [   SDLK_STOP =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_STOP() ) }
        ],
        [   SDLK_AGAIN =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_AGAIN() ) }
        ],
        [   SDLK_UNDO =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_UNDO() ) }
        ],
        [   SDLK_CUT =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_CUT() ) }
        ],
        [   SDLK_COPY =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_COPY() ) }
        ],
        [   SDLK_PASTE =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_PASTE() ) }
        ],
        [   SDLK_FIND =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_FIND() ) }
        ],
        [   SDLK_MUTE =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_MUTE() ) }
        ],
        [   SDLK_VOLUMEUP => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_VOLUMEUP() );
            }
        ],
        [   SDLK_VOLUMEDOWN => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_VOLUMEDOWN() );
            }
        ],
        [   SDLK_KP_COMMA => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_COMMA() );
            }
        ],
        [   SDLK_KP_EQUALSAS400 => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_EQUALSAS400() );
            }
        ],
        [   SDLK_ALTERASE => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_ALTERASE() );
            }
        ],
        [   SDLK_SYSREQ => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_SYSREQ() );
            }
        ],
        [   SDLK_CANCEL => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_CANCEL() );
            }
        ],
        [   SDLK_CLEAR =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_CLEAR() ) }
        ],
        [   SDLK_PRIOR =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_PRIOR() ) }
        ],
        [   SDLK_RETURN2 => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_RETURN2() );
            }
        ],
        [   SDLK_SEPARATOR => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_SEPARATOR() );
            }
        ],
        [   SDLK_OUT =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_OUT() ) }
        ],
        [   SDLK_OPER =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_OPER() ) }
        ],
        [   SDLK_CLEARAGAIN => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_CLEARAGAIN() );
            }
        ],
        [   SDLK_CRSEL =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_CRSEL() ) }
        ],
        [   SDLK_EXSEL =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_EXSEL() ) }
        ],
        [   SDLK_KP_00 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_00() ) }
        ],
        [   SDLK_KP_000 => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_000() );
            }
        ],
        [   SDLK_THOUSANDSSEPARATOR => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE(
                    SDL2::FFI::SDL_SCANCODE_THOUSANDSSEPARATOR() );
            }
        ],
        [   SDLK_DECIMALSEPARATOR => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE(
                    SDL2::FFI::SDL_SCANCODE_DECIMALSEPARATOR() );
            }
        ],
        [   SDLK_CURRENCYUNIT => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_CURRENCYUNIT() );
            }
        ],
        [   SDLK_CURRENCYSUBUNIT => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_CURRENCYSUBUNIT() );
            }
        ],
        [   SDLK_KP_LEFTPAREN => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_LEFTPAREN() );
            }
        ],
        [   SDLK_KP_RIGHTPAREN => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_RIGHTPAREN() );
            }
        ],
        [   SDLK_KP_LEFTBRACE => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_LEFTBRACE() );
            }
        ],
        [   SDLK_KP_RIGHTBRACE => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_RIGHTBRACE() );
            }
        ],
        [   SDLK_KP_TAB => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_TAB() );
            }
        ],
        [   SDLK_KP_BACKSPACE => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_BACKSPACE() );
            }
        ],
        [   SDLK_KP_A =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_A() ) }
        ],
        [   SDLK_KP_B =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_B() ) }
        ],
        [   SDLK_KP_C =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_C() ) }
        ],
        [   SDLK_KP_D =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_D() ) }
        ],
        [   SDLK_KP_E =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_E() ) }
        ],
        [   SDLK_KP_F =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_F() ) }
        ],
        [   SDLK_KP_XOR => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_XOR() );
            }
        ],
        [   SDLK_KP_POWER => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_POWER() );
            }
        ],
        [   SDLK_KP_PERCENT => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_PERCENT() );
            }
        ],
        [   SDLK_KP_LESS => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_LESS() );
            }
        ],
        [   SDLK_KP_GREATER => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_GREATER() );
            }
        ],
        [   SDLK_KP_AMPERSAND => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_AMPERSAND() );
            }
        ],
        [   SDLK_KP_DBLAMPERSAND => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_DBLAMPERSAND() );
            }
        ],
        [   SDLK_KP_VERTICALBAR => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_VERTICALBAR() );
            }
        ],
        [   SDLK_KP_DBLVERTICALBAR => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE(
                    SDL2::FFI::SDL_SCANCODE_KP_DBLVERTICALBAR() );
            }
        ],
        [   SDLK_KP_COLON => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_COLON() );
            }
        ],
        [   SDLK_KP_HASH => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_HASH() );
            }
        ],
        [   SDLK_KP_SPACE => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_SPACE() );
            }
        ],
        [   SDLK_KP_AT =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_AT() ) }
        ],
        [   SDLK_KP_EXCLAM => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_EXCLAM() );
            }
        ],
        [   SDLK_KP_MEMSTORE => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_MEMSTORE() );
            }
        ],
        [   SDLK_KP_MEMRECALL => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_MEMRECALL() );
            }
        ],
        [   SDLK_KP_MEMCLEAR => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_MEMCLEAR() );
            }
        ],
        [   SDLK_KP_MEMADD => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_MEMADD() );
            }
        ],
        [   SDLK_KP_MEMSUBTRACT => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_MEMSUBTRACT() );
            }
        ],
        [   SDLK_KP_MEMMULTIPLY => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_MEMMULTIPLY() );
            }
        ],
        [   SDLK_KP_MEMDIVIDE => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_MEMDIVIDE() );
            }
        ],
        [   SDLK_KP_PLUSMINUS => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_PLUSMINUS() );
            }
        ],
        [   SDLK_KP_CLEAR => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_CLEAR() );
            }
        ],
        [   SDLK_KP_CLEARENTRY => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_CLEARENTRY() );
            }
        ],
        [   SDLK_KP_BINARY => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_BINARY() );
            }
        ],
        [   SDLK_KP_OCTAL => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_OCTAL() );
            }
        ],
        [   SDLK_KP_DECIMAL => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_DECIMAL() );
            }
        ],
        [   SDLK_KP_HEXADECIMAL => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KP_HEXADECIMAL() );
            }
        ],
        [   SDLK_LCTRL =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_LCTRL() ) }
        ],
        [   SDLK_LSHIFT => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_LSHIFT() );
            }
        ],
        [   SDLK_LALT =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_LALT() ) }
        ],
        [   SDLK_LGUI =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_LGUI() ) }
        ],
        [   SDLK_RCTRL =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_RCTRL() ) }
        ],
        [   SDLK_RSHIFT => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_RSHIFT() );
            }
        ],
        [   SDLK_RALT =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_RALT() ) }
        ],
        [   SDLK_RGUI =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_RGUI() ) }
        ],
        [   SDLK_MODE =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_MODE() ) }
        ],
        [   SDLK_AUDIONEXT => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_AUDIONEXT() );
            }
        ],
        [   SDLK_AUDIOPREV => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_AUDIOPREV() );
            }
        ],
        [   SDLK_AUDIOSTOP => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_AUDIOSTOP() );
            }
        ],
        [   SDLK_AUDIOPLAY => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_AUDIOPLAY() );
            }
        ],
        [   SDLK_AUDIOMUTE => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_AUDIOMUTE() );
            }
        ],
        [   SDLK_MEDIASELECT => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_MEDIASELECT() );
            }
        ],
        [   SDLK_WWW =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_WWW() ) }
        ],
        [   SDLK_MAIL =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_MAIL() ) }
        ],
        [   SDLK_CALCULATOR => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_CALCULATOR() );
            }
        ],
        [   SDLK_COMPUTER => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_COMPUTER() );
            }
        ],
        [   SDLK_AC_SEARCH => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_AC_SEARCH() );
            }
        ],
        [   SDLK_AC_HOME => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_AC_HOME() );
            }
        ],
        [   SDLK_AC_BACK => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_AC_BACK() );
            }
        ],
        [   SDLK_AC_FORWARD => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_AC_FORWARD() );
            }
        ],
        [   SDLK_AC_STOP => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_AC_STOP() );
            }
        ],
        [   SDLK_AC_REFRESH => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_AC_REFRESH() );
            }
        ],
        [   SDLK_AC_BOOKMARKS => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_AC_BOOKMARKS() );
            }
        ],
        [   SDLK_BRIGHTNESSDOWN => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_BRIGHTNESSDOWN() );
            }
        ],
        [   SDLK_BRIGHTNESSUP => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_BRIGHTNESSUP() );
            }
        ],
        [   SDLK_DISPLAYSWITCH => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_DISPLAYSWITCH() );
            }
        ],
        [   SDLK_KBDILLUMTOGGLE => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KBDILLUMTOGGLE() );
            }
        ],
        [   SDLK_KBDILLUMDOWN => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KBDILLUMDOWN() );
            }
        ],
        [   SDLK_KBDILLUMUP => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_KBDILLUMUP() );
            }
        ],
        [   SDLK_EJECT =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_EJECT() ) }
        ],
        [   SDLK_SLEEP =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_SLEEP() ) }
        ],
        [   SDLK_APP1 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_APP1() ) }
        ],
        [   SDLK_APP2 =>
                sub () { ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_APP2() ) }
        ],
        [   SDLK_AUDIOREWIND => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE( SDL2::FFI::SDL_SCANCODE_AUDIOREWIND() );
            }
        ],
        [   SDLK_AUDIOFASTFORWARD => sub () {
                ord SDL2::FFI::SDL_SCANCODE_TO_KEYCODE(
                    SDL2::FFI::SDL_SCANCODE_AUDIOFASTFORWARD() );
            }
        ]
        ],
        SDL_Keymod => [
        [ KMOD_NONE     => 0x0000 ],
        [ KMOD_LSHIFT   => 0x0001 ],
        [ KMOD_RSHIFT   => 0x0002 ],
        [ KMOD_LCTRL    => 0x0040 ],
        [ KMOD_RCTRL    => 0x0080 ],
        [ KMOD_LALT     => 0x0100 ],
        [ KMOD_RALT     => 0x0200 ],
        [ KMOD_LGUI     => 0x0400 ],
        [ KMOD_RGUI     => 0x0800 ],
        [ KMOD_NUM      => 0x1000 ],
        [ KMOD_CAPS     => 0x2000 ],
        [ KMOD_MODE     => 0x4000 ],
        [ KMOD_RESERVED => 0x8000 ],
        [ KMOD_CTRL     => sub () { SDL2::FFI::KMOD_LCTRL() | SDL2::FFI::KMOD_RCTRL() } ],
        [ KMOD_SHIFT    => sub () { SDL2::FFI::KMOD_LSHIFT() | SDL2::FFI::KMOD_RSHIFT() } ],
        [ KMOD_ALT      => sub () { SDL2::FFI::KMOD_LALT() | SDL2::FFI::KMOD_RALT() } ],
        [ KMOD_GUI      => sub () { SDL2::FFI::KMOD_LGUI() | SDL2::FFI::KMOD_RGUI() } ]
        ];

=encoding utf-8

=head1 NAME

SDL2::keycode - Defines Constants Which Identify Keyboard Keys and Modifiers

=head1 SYNOPSIS

    use SDL2 qw[:keycode];

=head1 DESCRIPTION

The SDL virtual key representation.

=head1 Defines and Enumerations

Values of this type are used to represent keyboard keys using the current
layout of the keyboard.  These values include Unicode values representing the
unmodified character that would be generated by pressing the key, or an
C<SDLK_*> constant for those keys that do not generate characters.

A special exception is the number keys at the top of the keyboard which always
map to C<SDLK_0>...C<SDLK_9>, regardless of layout.

=head2 C<SDL_KeyCode>

These may be imported with the C<:keyCode> tag.

=over

=item C<SDLK_UNKNOWN>

=item C<SDLK_RETURN>

=item C<SDLK_ESCAPE>

=item C<SDLK_BACKSPACE>

=item C<SDLK_TAB>

=item C<SDLK_SPACE>

=item C<SDLK_EXCLAIM>

=item C<SDLK_QUOTEDBL>

=item C<SDLK_HASH>

=item C<SDLK_PERCENT>

=item C<SDLK_DOLLAR>

=item C<SDLK_AMPERSAND>

=item C<SDLK_QUOTE>

=item C<SDLK_LEFTPAREN>

=item C<SDLK_RIGHTPAREN>

=item C<SDLK_ASTERISK>

=item C<SDLK_PLUS>

=item C<SDLK_COMMA>

=item C<SDLK_MINUS>

=item C<SDLK_PERIOD>

=item C<SDLK_SLASH>

=item C<SDLK_0>

=item C<SDLK_1>

=item C<SDLK_2>

=item C<SDLK_3>

=item C<SDLK_4>

=item C<SDLK_5>

=item C<SDLK_6>

=item C<SDLK_7>

=item C<SDLK_8>

=item C<SDLK_9>

=item C<SDLK_COLON>

=item C<SDLK_SEMICOLON>

=item C<SDLK_LESS>

=item C<SDLK_EQUALS>

=item C<SDLK_GREATER>

=item C<SDLK_QUESTION>

=item C<SDLK_AT>

=item C<SDLK_LEFTBRACKET>

=item C<SDLK_BACKSLASH>

=item C<SDLK_RIGHTBRACKET>

=item C<SDLK_CARET>

=item C<SDLK_UNDERSCORE>

=item C<SDLK_BACKQUOTE>

=item C<SDLK_a>

=item C<SDLK_b>

=item C<SDLK_c>

=item C<SDLK_d>

=item C<SDLK_e>

=item C<SDLK_f>

=item C<SDLK_g>

=item C<SDLK_h>

=item C<SDLK_i>

=item C<SDLK_j>

=item C<SDLK_k>

=item C<SDLK_l>

=item C<SDLK_m>

=item C<SDLK_n>

=item C<SDLK_o>

=item C<SDLK_p>

=item C<SDLK_q>

=item C<SDLK_r>

=item C<SDLK_s>

=item C<SDLK_t>

=item C<SDLK_u>

=item C<SDLK_v>

=item C<SDLK_w>

=item C<SDLK_x>

=item C<SDLK_y>

=item C<SDLK_z>

=item C<SDLK_CAPSLOCK>

=item C<SDLK_F1>

=item C<SDLK_F2>

=item C<SDLK_F3>

=item C<SDLK_F4>

=item C<SDLK_F5>

=item C<SDLK_F6>

=item C<SDLK_F7>

=item C<SDLK_F8>

=item C<SDLK_F9>

=item C<SDLK_F10>

=item C<SDLK_F11>

=item C<SDLK_F12>

=item C<SDLK_PRINTSCREEN>

=item C<SDLK_SCROLLLOCK>

=item C<SDLK_PAUSE>

=item C<SDLK_INSERT>

=item C<SDLK_HOME>

=item C<SDLK_PAGEUP>

=item C<SDLK_DELETE>

=item C<SDLK_END>

=item C<SDLK_PAGEDOWN>

=item C<SDLK_RIGHT>

=item C<SDLK_LEFT>

=item C<SDLK_DOWN>

=item C<SDLK_UP>

=item C<SDLK_NUMLOCKCLEAR>

=item C<SDLK_KP_DIVIDE>

=item C<SDLK_KP_MULTIPLY>

=item C<SDLK_KP_MINUS>

=item C<SDLK_KP_PLUS>

=item C<SDLK_KP_ENTER>

=item C<SDLK_KP_1>

=item C<SDLK_KP_2>

=item C<SDLK_KP_3>

=item C<SDLK_KP_4>

=item C<SDLK_KP_5>

=item C<SDLK_KP_6>

=item C<SDLK_KP_7>

=item C<SDLK_KP_8>

=item C<SDLK_KP_9>

=item C<SDLK_KP_0>

=item C<SDLK_KP_PERIOD>

=item C<SDLK_APPLICATION>

=item C<SDLK_POWER>

=item C<SDLK_KP_EQUALS>

=item C<SDLK_F13>

=item C<SDLK_F14>

=item C<SDLK_F15>

=item C<SDLK_F16>

=item C<SDLK_F17>

=item C<SDLK_F18>

=item C<SDLK_F19>

=item C<SDLK_F20>

=item C<SDLK_F21>

=item C<SDLK_F22>

=item C<SDLK_F23>

=item C<SDLK_F24>

=item C<SDLK_EXECUTE>

=item C<SDLK_HELP>

=item C<SDLK_MENU>

=item C<SDLK_SELECT>

=item C<SDLK_STOP>

=item C<SDLK_AGAIN>

=item C<SDLK_UNDO>

=item C<SDLK_CUT>

=item C<SDLK_COPY>

=item C<SDLK_PASTE>

=item C<SDLK_FIND>

=item C<SDLK_MUTE>

=item C<SDLK_VOLUMEUP>

=item C<SDLK_VOLUMEDOWN>

=item C<SDLK_KP_COMMA>

=item C<SDLK_KP_EQUALSAS400>

=item C<SDLK_ALTERASE>

=item C<SDLK_SYSREQ>

=item C<SDLK_CANCEL>

=item C<SDLK_CLEAR>

=item C<SDLK_PRIOR>

=item C<SDLK_RETURN2>

=item C<SDLK_SEPARATOR>

=item C<SDLK_OUT>

=item C<SDLK_OPER>

=item C<SDLK_CLEARAGAIN>

=item C<SDLK_CRSEL>

=item C<SDLK_EXSEL>

=item C<SDLK_KP_00>

=item C<SDLK_KP_000>

=item C<SDLK_THOUSANDSSEPARATOR>

=item C<SDLK_DECIMALSEPARATOR>

=item C<SDLK_CURRENCYUNIT>

=item C<SDLK_CURRENCYSUBUNIT>

=item C<SDLK_KP_LEFTPAREN>

=item C<SDLK_KP_RIGHTPAREN>

=item C<SDLK_KP_LEFTBRACE>

=item C<SDLK_KP_RIGHTBRACE>

=item C<SDLK_KP_TAB>

=item C<SDLK_KP_BACKSPACE>

=item C<SDLK_KP_A>

=item C<SDLK_KP_B>

=item C<SDLK_KP_C>

=item C<SDLK_KP_D>

=item C<SDLK_KP_E>

=item C<SDLK_KP_F>

=item C<SDLK_KP_XOR>

=item C<SDLK_KP_POWER>

=item C<SDLK_KP_PERCENT>

=item C<SDLK_KP_LESS>

=item C<SDLK_KP_GREATER>

=item C<SDLK_KP_AMPERSAND>

=item C<SDLK_KP_DBLAMPERSAND>

=item C<SDLK_KP_VERTICALBAR>

=item C<SDLK_KP_DBLVERTICALBAR>

=item C<SDLK_KP_COLON>

=item C<SDLK_KP_HASH>

=item C<SDLK_KP_SPACE>

=item C<SDLK_KP_AT>

=item C<SDLK_KP_EXCLAM>

=item C<SDLK_KP_MEMSTORE>

=item C<SDLK_KP_MEMRECALL>

=item C<SDLK_KP_MEMCLEAR>

=item C<SDLK_KP_MEMADD>

=item C<SDLK_KP_MEMSUBTRACT>

=item C<SDLK_KP_MEMMULTIPLY>

=item C<SDLK_KP_MEMDIVIDE>

=item C<SDLK_KP_PLUSMINUS>

=item C<SDLK_KP_CLEAR>

=item C<SDLK_KP_CLEARENTRY>

=item C<SDLK_KP_BINARY>

=item C<SDLK_KP_OCTAL>

=item C<SDLK_KP_DECIMAL>

=item C<SDLK_KP_HEXADECIMAL>

=item C<SDLK_LCTRL>

=item C<SDLK_LSHIFT>

=item C<SDLK_LALT>

=item C<SDLK_LGUI>

=item C<SDLK_RCTRL>

=item C<SDLK_RSHIFT>

=item C<SDLK_RALT>

=item C<SDLK_RGUI>

=item C<SDLK_MODE>

=item C<SDLK_AUDIONEXT>

=item C<SDLK_AUDIOPREV>

=item C<SDLK_AUDIOSTOP>

=item C<SDLK_AUDIOPLAY>

=item C<SDLK_AUDIOMUTE>

=item C<SDLK_MEDIASELECT>

=item C<SDLK_WWW>

=item C<SDLK_MAIL>

=item C<SDLK_CALCULATOR>

=item C<SDLK_COMPUTER>

=item C<SDLK_AC_SEARCH>

=item C<SDLK_AC_HOME>

=item C<SDLK_AC_BACK>

=item C<SDLK_AC_FORWARD>

=item C<SDLK_AC_STOP>

=item C<SDLK_AC_REFRESH>

=item C<SDLK_AC_BOOKMARKS>

=item C<SDLK_BRIGHTNESSDOWN>

=item C<SDLK_BRIGHTNESSUP>

=item C<SDLK_DISPLAYSWITCH>

=item C<SDLK_KBDILLUMTOGGLE>

=item C<SDLK_KBDILLUMDOWN>

=item C<SDLK_KBDILLUMUP>

=item C<SDLK_EJECT>

=item C<SDLK_SLEEP>

=item C<SDLK_APP1>

=item C<SDLK_APP2>

=item C<SDLK_AUDIOREWIND>

=item C<SDLK_AUDIOFASTFORWARD>

=back

=head2 C<SDL_Keymod>

Enumeration of valid key mods (possibly OR'd together). These may be imported
with the C<:keymod> tag.

=over

=item C<KMOD_NONE>

=item C<KMOD_LSHIFT>

=item C<KMOD_RSHIFT>

=item C<KMOD_LCTRL>

=item C<KMOD_RCTRL>

=item C<KMOD_LALT>

=item C<KMOD_RALT>

=item C<KMOD_LGUI>

=item C<KMOD_RGUI>

=item C<KMOD_NUM>

=item C<KMOD_CAPS>

=item C<KMOD_MODE>

=item C<KMOD_RESERVED>

=item C<KMOD_CTRL>

=item C<KMOD_SHIFT>

=item C<KMOD_ALT>

=item C<KMOD_GUI>

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

=end stopwords

=cut

};
1;
