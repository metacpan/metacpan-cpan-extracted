package SDL2::scancode 0.01 {
    use SDL2::Utils;
    #
    use SDL2::stdinc;
    enum SDL_Scancode => [
        [ SDL_SCANCODE_UNKNOWN => 0 ],  [ SDL_SCANCODE_A     => 4 ],  [ SDL_SCANCODE_B      => 5 ],
        [ SDL_SCANCODE_C       => 6 ],  [ SDL_SCANCODE_D     => 7 ],  [ SDL_SCANCODE_E      => 8 ],
        [ SDL_SCANCODE_F       => 9 ],  [ SDL_SCANCODE_G     => 10 ], [ SDL_SCANCODE_H      => 11 ],
        [ SDL_SCANCODE_I       => 12 ], [ SDL_SCANCODE_J     => 13 ], [ SDL_SCANCODE_K      => 14 ],
        [ SDL_SCANCODE_L       => 15 ], [ SDL_SCANCODE_M     => 16 ], [ SDL_SCANCODE_N      => 17 ],
        [ SDL_SCANCODE_O       => 18 ], [ SDL_SCANCODE_P     => 19 ], [ SDL_SCANCODE_Q      => 20 ],
        [ SDL_SCANCODE_R       => 21 ], [ SDL_SCANCODE_S     => 22 ], [ SDL_SCANCODE_T      => 23 ],
        [ SDL_SCANCODE_U       => 24 ], [ SDL_SCANCODE_V     => 25 ], [ SDL_SCANCODE_W      => 26 ],
        [ SDL_SCANCODE_X       => 27 ], [ SDL_SCANCODE_Y     => 28 ], [ SDL_SCANCODE_Z      => 29 ],
        [ SDL_SCANCODE_1       => 30 ], [ SDL_SCANCODE_2     => 31 ], [ SDL_SCANCODE_3      => 32 ],
        [ SDL_SCANCODE_4       => 33 ], [ SDL_SCANCODE_5     => 34 ], [ SDL_SCANCODE_6      => 35 ],
        [ SDL_SCANCODE_7       => 36 ], [ SDL_SCANCODE_8     => 37 ], [ SDL_SCANCODE_9      => 38 ],
        [ SDL_SCANCODE_0 => 39 ], [ SDL_SCANCODE_RETURN      => 40 ], [ SDL_SCANCODE_ESCAPE => 41 ],
        [ SDL_SCANCODE_BACKSPACE => 42 ], [ SDL_SCANCODE_TAB => 43 ], [ SDL_SCANCODE_SPACE  => 44 ],
        [ SDL_SCANCODE_MINUS       => 45 ], [ SDL_SCANCODE_EQUALS       => 46 ],
        [ SDL_SCANCODE_LEFTBRACKET => 47 ], [ SDL_SCANCODE_RIGHTBRACKET => 48 ],
        [ SDL_SCANCODE_BACKSLASH   => 49 ], [ SDL_SCANCODE_NONUSHASH    => 50 ],
        [ SDL_SCANCODE_SEMICOLON   => 51 ], [ SDL_SCANCODE_APOSTROPHE   => 52 ],
        [ SDL_SCANCODE_GRAVE => 53 ], [ SDL_SCANCODE_COMMA => 54 ], [ SDL_SCANCODE_PERIOD  => 55 ],
        [ SDL_SCANCODE_SLASH => 56 ], [ SDL_SCANCODE_CAPSLOCK => 57 ], [ SDL_SCANCODE_F1   => 58 ],
        [ SDL_SCANCODE_F2    => 59 ], [ SDL_SCANCODE_F3       => 60 ], [ SDL_SCANCODE_F4   => 61 ],
        [ SDL_SCANCODE_F5    => 62 ], [ SDL_SCANCODE_F6       => 63 ], [ SDL_SCANCODE_F7   => 64 ],
        [ SDL_SCANCODE_F8    => 65 ], [ SDL_SCANCODE_F9       => 66 ], [ SDL_SCANCODE_F10  => 67 ],
        [ SDL_SCANCODE_F11 => 68 ], [ SDL_SCANCODE_F12 => 69 ], [ SDL_SCANCODE_PRINTSCREEN => 70 ],
        [ SDL_SCANCODE_SCROLLLOCK => 71 ], [ SDL_SCANCODE_PAUSE => 72 ],
        [ SDL_SCANCODE_INSERT => 73 ], [ SDL_SCANCODE_HOME => 74 ], [ SDL_SCANCODE_PAGEUP   => 75 ],
        [ SDL_SCANCODE_DELETE => 76 ], [ SDL_SCANCODE_END  => 77 ], [ SDL_SCANCODE_PAGEDOWN => 78 ],
        [ SDL_SCANCODE_RIGHT  => 79 ], [ SDL_SCANCODE_LEFT => 80 ], [ SDL_SCANCODE_DOWN     => 81 ],
        [ SDL_SCANCODE_UP        => 82 ], [ SDL_SCANCODE_NUMLOCKCLEAR => 83 ],
        [ SDL_SCANCODE_KP_DIVIDE => 84 ], [ SDL_SCANCODE_KP_MULTIPLY  => 85 ],
        [ SDL_SCANCODE_KP_MINUS  => 86 ], [ SDL_SCANCODE_KP_PLUS      => 87 ],
        [ SDL_SCANCODE_KP_ENTER  => 88 ], [ SDL_SCANCODE_KP_1 => 89 ], [ SDL_SCANCODE_KP_2 => 90 ],
        [ SDL_SCANCODE_KP_3      => 91 ], [ SDL_SCANCODE_KP_4 => 92 ], [ SDL_SCANCODE_KP_5 => 93 ],
        [ SDL_SCANCODE_KP_6      => 94 ], [ SDL_SCANCODE_KP_7 => 95 ], [ SDL_SCANCODE_KP_8 => 96 ],
        [ SDL_SCANCODE_KP_9 => 97 ], [ SDL_SCANCODE_KP_0 => 98 ], [ SDL_SCANCODE_KP_PERIOD => 99 ],
        [ SDL_SCANCODE_NONUSBACKSLASH => 100 ], [ SDL_SCANCODE_APPLICATION => 101 ],
        [ SDL_SCANCODE_POWER          => 102 ], [ SDL_SCANCODE_KP_EQUALS   => 103 ],
        [ SDL_SCANCODE_F13     => 104 ], [ SDL_SCANCODE_F14  => 105 ], [ SDL_SCANCODE_F15 => 106 ],
        [ SDL_SCANCODE_F16     => 107 ], [ SDL_SCANCODE_F17  => 108 ], [ SDL_SCANCODE_F18 => 109 ],
        [ SDL_SCANCODE_F19     => 110 ], [ SDL_SCANCODE_F20  => 111 ], [ SDL_SCANCODE_F21 => 112 ],
        [ SDL_SCANCODE_F22     => 113 ], [ SDL_SCANCODE_F23  => 114 ], [ SDL_SCANCODE_F24 => 115 ],
        [ SDL_SCANCODE_EXECUTE => 116 ], [ SDL_SCANCODE_HELP => 117 ],
        [ SDL_SCANCODE_MENU  => 118 ], [ SDL_SCANCODE_SELECT => 119 ], [ SDL_SCANCODE_STOP => 120 ],
        [ SDL_SCANCODE_AGAIN => 121 ], [ SDL_SCANCODE_UNDO   => 122 ], [ SDL_SCANCODE_CUT  => 123 ],
        [ SDL_SCANCODE_COPY  => 124 ], [ SDL_SCANCODE_PASTE  => 125 ], [ SDL_SCANCODE_FIND => 126 ],
        [ SDL_SCANCODE_MUTE  => 127 ], [ SDL_SCANCODE_VOLUMEUP => 128 ],
        [ SDL_SCANCODE_VOLUMEDOWN => 129 ],

        #not sure whether there's a reason to enable these... they aren't upstream
        #     [SDL_SCANCODE_LOCKINGCAPSLOCK => 130],
        #     [SDL_SCANCODE_LOCKINGNUMLOCK => 131],
        #    [SDL_SCANCODE_LOCKINGSCROLLLOCK => 132],
        [ SDL_SCANCODE_KP_COMMA           => 133 ], [ SDL_SCANCODE_KP_EQUALSAS400   => 134 ],
        [ SDL_SCANCODE_INTERNATIONAL1     => 135 ], [ SDL_SCANCODE_INTERNATIONAL2   => 136 ],
        [ SDL_SCANCODE_INTERNATIONAL3     => 137 ], [ SDL_SCANCODE_INTERNATIONAL4   => 138 ],
        [ SDL_SCANCODE_INTERNATIONAL5     => 139 ], [ SDL_SCANCODE_INTERNATIONAL6   => 140 ],
        [ SDL_SCANCODE_INTERNATIONAL7     => 141 ], [ SDL_SCANCODE_INTERNATIONAL8   => 142 ],
        [ SDL_SCANCODE_INTERNATIONAL9     => 143 ], [ SDL_SCANCODE_LANG1            => 144 ],
        [ SDL_SCANCODE_LANG2              => 145 ], [ SDL_SCANCODE_LANG3            => 146 ],
        [ SDL_SCANCODE_LANG4              => 147 ], [ SDL_SCANCODE_LANG5            => 148 ],
        [ SDL_SCANCODE_LANG6              => 149 ], [ SDL_SCANCODE_LANG7            => 150 ],
        [ SDL_SCANCODE_LANG8              => 151 ], [ SDL_SCANCODE_LANG9            => 152 ],
        [ SDL_SCANCODE_ALTERASE           => 153 ], [ SDL_SCANCODE_SYSREQ           => 154 ],
        [ SDL_SCANCODE_CANCEL             => 155 ], [ SDL_SCANCODE_CLEAR            => 156 ],
        [ SDL_SCANCODE_PRIOR              => 157 ], [ SDL_SCANCODE_RETURN2          => 158 ],
        [ SDL_SCANCODE_SEPARATOR          => 159 ], [ SDL_SCANCODE_OUT              => 160 ],
        [ SDL_SCANCODE_OPER               => 161 ], [ SDL_SCANCODE_CLEARAGAIN       => 162 ],
        [ SDL_SCANCODE_CRSEL              => 163 ], [ SDL_SCANCODE_EXSEL            => 164 ],
        [ SDL_SCANCODE_KP_00              => 176 ], [ SDL_SCANCODE_KP_000           => 177 ],
        [ SDL_SCANCODE_THOUSANDSSEPARATOR => 178 ], [ SDL_SCANCODE_DECIMALSEPARATOR => 179 ],
        [ SDL_SCANCODE_CURRENCYUNIT       => 180 ], [ SDL_SCANCODE_CURRENCYSUBUNIT  => 181 ],
        [ SDL_SCANCODE_KP_LEFTPAREN       => 182 ], [ SDL_SCANCODE_KP_RIGHTPAREN    => 183 ],
        [ SDL_SCANCODE_KP_LEFTBRACE       => 184 ], [ SDL_SCANCODE_KP_RIGHTBRACE    => 185 ],
        [ SDL_SCANCODE_KP_TAB             => 186 ], [ SDL_SCANCODE_KP_BACKSPACE     => 187 ],
        [ SDL_SCANCODE_KP_A => 188 ], [ SDL_SCANCODE_KP_B => 189 ], [ SDL_SCANCODE_KP_C => 190 ],
        [ SDL_SCANCODE_KP_D => 191 ], [ SDL_SCANCODE_KP_E => 192 ], [ SDL_SCANCODE_KP_F => 193 ],
        [ SDL_SCANCODE_KP_XOR            => 194 ], [ SDL_SCANCODE_KP_POWER       => 195 ],
        [ SDL_SCANCODE_KP_PERCENT        => 196 ], [ SDL_SCANCODE_KP_LESS        => 197 ],
        [ SDL_SCANCODE_KP_GREATER        => 198 ], [ SDL_SCANCODE_KP_AMPERSAND   => 199 ],
        [ SDL_SCANCODE_KP_DBLAMPERSAND   => 200 ], [ SDL_SCANCODE_KP_VERTICALBAR => 201 ],
        [ SDL_SCANCODE_KP_DBLVERTICALBAR => 202 ], [ SDL_SCANCODE_KP_COLON       => 203 ],
        [ SDL_SCANCODE_KP_HASH           => 204 ], [ SDL_SCANCODE_KP_SPACE       => 205 ],
        [ SDL_SCANCODE_KP_AT             => 206 ], [ SDL_SCANCODE_KP_EXCLAM      => 207 ],
        [ SDL_SCANCODE_KP_MEMSTORE       => 208 ], [ SDL_SCANCODE_KP_MEMRECALL   => 209 ],
        [ SDL_SCANCODE_KP_MEMCLEAR       => 210 ], [ SDL_SCANCODE_KP_MEMADD      => 211 ],
        [ SDL_SCANCODE_KP_MEMSUBTRACT    => 212 ], [ SDL_SCANCODE_KP_MEMMULTIPLY => 213 ],
        [ SDL_SCANCODE_KP_MEMDIVIDE      => 214 ], [ SDL_SCANCODE_KP_PLUSMINUS   => 215 ],
        [ SDL_SCANCODE_KP_CLEAR          => 216 ], [ SDL_SCANCODE_KP_CLEARENTRY  => 217 ],
        [ SDL_SCANCODE_KP_BINARY         => 218 ], [ SDL_SCANCODE_KP_OCTAL       => 219 ],
        [ SDL_SCANCODE_KP_DECIMAL        => 220 ], [ SDL_SCANCODE_KP_HEXADECIMAL => 221 ],
        [ SDL_SCANCODE_LCTRL             => 224 ], [ SDL_SCANCODE_LSHIFT         => 225 ],
        [ SDL_SCANCODE_LALT   => 226 ], [ SDL_SCANCODE_LGUI => 227 ], [ SDL_SCANCODE_RCTRL => 228 ],
        [ SDL_SCANCODE_RSHIFT => 229 ], [ SDL_SCANCODE_RALT => 230 ], [ SDL_SCANCODE_RGUI  => 231 ],
        [ SDL_SCANCODE_MODE   => 257 ],

        # Usage page 0x0C
        [ SDL_SCANCODE_AUDIONEXT    => 258 ], [ SDL_SCANCODE_AUDIOPREV   => 259 ],
        [ SDL_SCANCODE_AUDIOSTOP    => 260 ], [ SDL_SCANCODE_AUDIOPLAY   => 261 ],
        [ SDL_SCANCODE_AUDIOMUTE    => 262 ], [ SDL_SCANCODE_MEDIASELECT => 263 ],
        [ SDL_SCANCODE_WWW          => 264 ], [ SDL_SCANCODE_MAIL        => 265 ],
        [ SDL_SCANCODE_CALCULATOR   => 266 ], [ SDL_SCANCODE_COMPUTER    => 267 ],
        [ SDL_SCANCODE_AC_SEARCH    => 268 ], [ SDL_SCANCODE_AC_HOME     => 269 ],
        [ SDL_SCANCODE_AC_BACK      => 270 ], [ SDL_SCANCODE_AC_FORWARD  => 271 ],
        [ SDL_SCANCODE_AC_STOP      => 272 ], [ SDL_SCANCODE_AC_REFRESH  => 273 ],
        [ SDL_SCANCODE_AC_BOOKMARKS => 274 ],

        # Walther keys
        [ SDL_SCANCODE_BRIGHTNESSDOWN => 275 ], [ SDL_SCANCODE_BRIGHTNESSUP   => 276 ],
        [ SDL_SCANCODE_DISPLAYSWITCH  => 277 ], [ SDL_SCANCODE_KBDILLUMTOGGLE => 278 ],
        [ SDL_SCANCODE_KBDILLUMDOWN   => 279 ], [ SDL_SCANCODE_KBDILLUMUP     => 280 ],
        [ SDL_SCANCODE_EJECT => 281 ], [ SDL_SCANCODE_SLEEP => 282 ], [ SDL_SCANCODE_APP1 => 283 ],
        [ SDL_SCANCODE_APP2  => 284 ],

        # additional media keys
        [ SDL_SCANCODE_AUDIOREWIND => 285 ], [ SDL_SCANCODE_AUDIOFASTFORWARD => 286 ],

        # Add any other keys here.
        [ SDL_NUM_SCANCODES => 512 ]
    ];

=encoding utf-8

=head1 NAME

SDL2::scancode - Defines Keyboard Scancodes

=head1 SYNOPSIS

    use SDL2 qw[:scancode];

=head1 DESCRIPTION

SDL2::scancode defines values of this type are used to represent keyboard keys,
among other places in the L<< scancode|SDL2::Keysym/C<scancode> >> field of the
L<SDL2::Event> structure.


=head1 Definitions and Enumerations

The SDL keyboard scancode representation.

=head2 C<SDL_Scancode>

The values in this enumeration are based on the USB usage page standard:
L<https://www.usb.org/sites/default/files/documents/hut1_12v2.pdf> and may be
imported by name or with the C<:scancode> tag.

These values are from usage page 0x07 (USB keyboard page).

=over

=item C<SDL_SCANCODE_UNKNOWN>

=item C<SDL_SCANCODE_A>

=item C<SDL_SCANCODE_B>

=item C<SDL_SCANCODE_C>

=item C<SDL_SCANCODE_D>

=item C<SDL_SCANCODE_E>

=item C<SDL_SCANCODE_F>

=item C<SDL_SCANCODE_G>

=item C<SDL_SCANCODE_H>

=item C<SDL_SCANCODE_I>

=item C<SDL_SCANCODE_J>

=item C<SDL_SCANCODE_K>

=item C<SDL_SCANCODE_L>

=item C<SDL_SCANCODE_M>

=item C<SDL_SCANCODE_N>

=item C<SDL_SCANCODE_O>

=item C<SDL_SCANCODE_P>

=item C<SDL_SCANCODE_Q>

=item C<SDL_SCANCODE_R>

=item C<SDL_SCANCODE_S>

=item C<SDL_SCANCODE_T>

=item C<SDL_SCANCODE_U>

=item C<SDL_SCANCODE_V>

=item C<SDL_SCANCODE_W>

=item C<SDL_SCANCODE_X>

=item C<SDL_SCANCODE_Y>

=item C<SDL_SCANCODE_Z>

=item C<SDL_SCANCODE_1>

=item C<SDL_SCANCODE_2>

=item C<SDL_SCANCODE_3>

=item C<SDL_SCANCODE_4>

=item C<SDL_SCANCODE_5>

=item C<SDL_SCANCODE_6>

=item C<SDL_SCANCODE_7>

=item C<SDL_SCANCODE_8>

=item C<SDL_SCANCODE_9>

=item C<SDL_SCANCODE_0>

=item C<SDL_SCANCODE_RETURN>

=item C<SDL_SCANCODE_ESCAPE>

=item C<SDL_SCANCODE_BACKSPACE>

=item C<SDL_SCANCODE_TAB>

=item C<SDL_SCANCODE_SPACE>

=item C<SDL_SCANCODE_MINUS>

=item C<SDL_SCANCODE_EQUALS>

=item C<SDL_SCANCODE_LEFTBRACKET>

=item C<SDL_SCANCODE_RIGHTBRACKET>

=item C<SDL_SCANCODE_BACKSLASH>

Located at the lower left of the return key on ISO keyboards and at the right
end of the QWERTY row on ANSI keyboards. Produces REVERSE SOLIDUS (backslash)
and VERTICAL LINE in a US layout, REVERSE SOLIDUS and VERTICAL LINE in a UK Mac
layout, NUMBER SIGN> and TILDE in a UK Windows layout, DOLLAR SIGN and POUND
SIGN in a Swiss German layout, NUMBER SIGN and APOSTROPHE in a German layout,
GRAVE ACCENT and POUND SIGN in a French Mac layout, and ASTERISK and MICRO SIGN
in a French Windows layout.

=item C<SDL_SCANCODE_NONUSHASH>

ISO USB keyboards actually use this code instead of 49 for the same key, but
all OSes I've seen treat the two codes identically. So, as an implementor,
unless your keyboard generates both of those codes and your OS treats them
differently, you should generate C<SDL_SCANCODE_BACKSLASH> instead of this
code. As a user, you should not rely on this code because SDL will never
generate it with most (all?) keyboards.

=item C<SDL_SCANCODE_SEMICOLON>

=item C<SDL_SCANCODE_APOSTROPHE>

=item C<SDL_SCANCODE_GRAVE>

Located in the top left corner (on both ANSI and ISO keyboards). Produces GRAVE
ACCENT and TILDE in a US Windows layout and in US and UK Mac layouts on ANSI
keyboards, GRAVE ACCENT and NOT SIGN in a UK Windows layout, SECTION SIGN and
PLUS-MINUS SIGN in US and UK Mac layouts on ISO keyboards, SECTION SIGN and
DEGREE SIGN in a Swiss German layout (Mac: only on ISO keyboards), CIRCUMFLEX
ACCENT and DEGREE SIGN in a German layout (Mac: only on ISO keyboards),
SUPERSCRIPT TWO and TILDE in a French Windows layout, COMMERCIAL AT and NUMBER
SIGN in a French Mac layout on ISO keyboards, and LESS-THAN SIGN and
GREATER-THAN SIGN in a Swiss German, German, or French Mac layout on ANSI
keyboards.

=item C<SDL_SCANCODE_COMMA>

=item C<SDL_SCANCODE_PERIOD>

=item C<SDL_SCANCODE_SLASH>

=item C<SDL_SCANCODE_CAPSLOCK>

=item C<SDL_SCANCODE_F1>

=item C<SDL_SCANCODE_F2>

=item C<SDL_SCANCODE_F3>

=item C<SDL_SCANCODE_F4>

=item C<SDL_SCANCODE_F5>

=item C<SDL_SCANCODE_F6>

=item C<SDL_SCANCODE_F7>

=item C<SDL_SCANCODE_F8>

=item C<SDL_SCANCODE_F9>

=item C<SDL_SCANCODE_F10>

=item C<SDL_SCANCODE_F11>

=item C<SDL_SCANCODE_F12>

=item C<SDL_SCANCODE_PRINTSCREEN>

=item C<SDL_SCANCODE_SCROLLLOCK>

=item C<SDL_SCANCODE_PAUSE>

=item C<SDL_SCANCODE_INSERT>

insert on PC, help on some Mac keyboards (but does send code 73, not 117)

=item C<SDL_SCANCODE_HOME>

=item C<SDL_SCANCODE_PAGEUP>

=item C<SDL_SCANCODE_DELETE>

=item C<SDL_SCANCODE_END>

=item C<SDL_SCANCODE_PAGEDOWN>

=item C<SDL_SCANCODE_RIGHT>

=item C<SDL_SCANCODE_LEFT>

=item C<SDL_SCANCODE_DOWN>

=item C<SDL_SCANCODE_UP>

=item C<SDL_SCANCODE_NUMLOCKCLEAR>

num lock on PC, clear on Mac keyboards

=item C<SDL_SCANCODE_KP_DIVIDE>

=item C<SDL_SCANCODE_KP_MULTIPLY>

=item C<SDL_SCANCODE_KP_MINUS>

=item C<SDL_SCANCODE_KP_PLUS>

=item C<SDL_SCANCODE_KP_ENTER>

=item C<SDL_SCANCODE_KP_1>

=item C<SDL_SCANCODE_KP_2>

=item C<SDL_SCANCODE_KP_3>

=item C<SDL_SCANCODE_KP_4>

=item C<SDL_SCANCODE_KP_5>

=item C<SDL_SCANCODE_KP_6>

=item C<SDL_SCANCODE_KP_7>

=item C<SDL_SCANCODE_KP_8>

=item C<SDL_SCANCODE_KP_9>

=item C<SDL_SCANCODE_KP_0>

=item C<SDL_SCANCODE_KP_PERIOD>

=item C<SDL_SCANCODE_NONUSBACKSLASH>

This is the additional key that ISO keyboards have over ANSI ones, located
between left shift and Y. Produces GRAVE ACCENT and TILDE in a US or UK Mac
layout, REVERSE SOLIDUS (backslash) and VERTICAL LINE in a US or UK Windows
layout, and LESS-THAN SIGN and GREATER-THAN SIGN in a Swiss German, German, or
French layout.

=item C<SDL_SCANCODE_APPLICATION>

windows contextual menu, compose

=item C<SDL_SCANCODE_POWER>

The USB document says this is a status flag, not a physical key - but some Mac
keyboards do have a power key.

=item C<SDL_SCANCODE_KP_EQUALS>

=item C<SDL_SCANCODE_F13>

=item C<SDL_SCANCODE_F14>

=item C<SDL_SCANCODE_F15>

=item C<SDL_SCANCODE_F16>

=item C<SDL_SCANCODE_F17>

=item C<SDL_SCANCODE_F18>

=item C<SDL_SCANCODE_F19>

=item C<SDL_SCANCODE_F20>

=item C<SDL_SCANCODE_F21>

=item C<SDL_SCANCODE_F22>

=item C<SDL_SCANCODE_F23>

=item C<SDL_SCANCODE_F24>

=item C<SDL_SCANCODE_EXECUTE>

=item C<SDL_SCANCODE_HELP>

=item C<SDL_SCANCODE_MENU>

=item C<SDL_SCANCODE_SELECT>

=item C<SDL_SCANCODE_STOP>

=item C<SDL_SCANCODE_AGAIN>

redo

=item C<SDL_SCANCODE_UNDO>

=item C<SDL_SCANCODE_CUT>

=item C<SDL_SCANCODE_COPY>

=item C<SDL_SCANCODE_PASTE>

=item C<SDL_SCANCODE_FIND>

=item C<SDL_SCANCODE_MUTE>

=item C<SDL_SCANCODE_VOLUMEUP>

=item C<SDL_SCANCODE_VOLUMEDOWN>

=item C<SDL_SCANCODE_KP_COMMA>

=item C<SDL_SCANCODE_KP_EQUALSAS400>

=item C<SDL_SCANCODE_INTERNATIONAL1>

used on Asian keyboards, see footnotes in USB doc

=item C<SDL_SCANCODE_INTERNATIONAL2>

=item C<SDL_SCANCODE_INTERNATIONAL3>

Yen

=item C<SDL_SCANCODE_INTERNATIONAL4>

=item C<SDL_SCANCODE_INTERNATIONAL5>

=item C<SDL_SCANCODE_INTERNATIONAL6>

=item C<SDL_SCANCODE_INTERNATIONAL7>

=item C<SDL_SCANCODE_INTERNATIONAL8>

=item C<SDL_SCANCODE_INTERNATIONAL9>

=item C<SDL_SCANCODE_LANG1> - Hangul/English toggle

=item C<SDL_SCANCODE_LANG2> - Hanja conversion

=item C<SDL_SCANCODE_LANG3> - Katakana

=item C<SDL_SCANCODE_LANG4> - Hiragana

=item C<SDL_SCANCODE_LANG5> - Zenkaku/Hankaku

=item C<SDL_SCANCODE_LANG6> - reserved

=item C<SDL_SCANCODE_LANG7> - reserved

=item C<SDL_SCANCODE_LANG8> - reserved

=item C<SDL_SCANCODE_LANG9> - reserved

=item C<SDL_SCANCODE_ALTERASE> - Erase-Eaze

=item C<SDL_SCANCODE_SYSREQ>

=item C<SDL_SCANCODE_CANCEL>

=item C<SDL_SCANCODE_CLEAR>

=item C<SDL_SCANCODE_PRIOR>

=item C<SDL_SCANCODE_RETURN2>

=item C<SDL_SCANCODE_SEPARATOR>

=item C<SDL_SCANCODE_OUT>

=item C<SDL_SCANCODE_OPER>

=item C<SDL_SCANCODE_CLEARAGAIN>

=item C<SDL_SCANCODE_CRSEL>

=item C<SDL_SCANCODE_EXSEL>

=item C<SDL_SCANCODE_KP_00>

=item C<SDL_SCANCODE_KP_000>

=item C<SDL_SCANCODE_THOUSANDSSEPARATOR>

=item C<SDL_SCANCODE_DECIMALSEPARATOR>

=item C<SDL_SCANCODE_CURRENCYUNIT>

=item C<SDL_SCANCODE_CURRENCYSUBUNIT>

=item C<SDL_SCANCODE_KP_LEFTPAREN>

=item C<SDL_SCANCODE_KP_RIGHTPAREN>

=item C<SDL_SCANCODE_KP_LEFTBRACE>

=item C<SDL_SCANCODE_KP_RIGHTBRACE>

=item C<SDL_SCANCODE_KP_TAB>

=item C<SDL_SCANCODE_KP_BACKSPACE>

=item C<SDL_SCANCODE_KP_A>

=item C<SDL_SCANCODE_KP_B>

=item C<SDL_SCANCODE_KP_C>

=item C<SDL_SCANCODE_KP_D>

=item C<SDL_SCANCODE_KP_E>

=item C<SDL_SCANCODE_KP_F>

=item C<SDL_SCANCODE_KP_XOR>

=item C<SDL_SCANCODE_KP_POWER>

=item C<SDL_SCANCODE_KP_PERCENT>

=item C<SDL_SCANCODE_KP_LESS>

=item C<SDL_SCANCODE_KP_GREATER>

=item C<SDL_SCANCODE_KP_AMPERSAND>

=item C<SDL_SCANCODE_KP_DBLAMPERSAND>

=item C<SDL_SCANCODE_KP_VERTICALBAR>

=item C<SDL_SCANCODE_KP_DBLVERTICALBAR>

=item C<SDL_SCANCODE_KP_COLON>

=item C<SDL_SCANCODE_KP_HASH>

=item C<SDL_SCANCODE_KP_SPACE>

=item C<SDL_SCANCODE_KP_AT>

=item C<SDL_SCANCODE_KP_EXCLAM>

=item C<SDL_SCANCODE_KP_MEMSTORE>

=item C<SDL_SCANCODE_KP_MEMRECALL>

=item C<SDL_SCANCODE_KP_MEMCLEAR>

=item C<SDL_SCANCODE_KP_MEMADD>

=item C<SDL_SCANCODE_KP_MEMSUBTRACT>

=item C<SDL_SCANCODE_KP_MEMMULTIPLY>

=item C<SDL_SCANCODE_KP_MEMDIVIDE>

=item C<SDL_SCANCODE_KP_PLUSMINUS>

=item C<SDL_SCANCODE_KP_CLEAR>

=item C<SDL_SCANCODE_KP_CLEARENTRY>

=item C<SDL_SCANCODE_KP_BINARY>

=item C<SDL_SCANCODE_KP_OCTAL>

=item C<SDL_SCANCODE_KP_DECIMAL>

=item C<SDL_SCANCODE_KP_HEXADECIMAL>

=item C<SDL_SCANCODE_LCTRL>

=item C<SDL_SCANCODE_LSHIFT>

=item C<SDL_SCANCODE_LALT> - alt, option

=item C<SDL_SCANCODE_LGUI> - windows, command (apple), meta

=item C<SDL_SCANCODE_RCTRL>

=item C<SDL_SCANCODE_RSHIFT>

=item C<SDL_SCANCODE_RALT> - alt gr, option

=item C<SDL_SCANCODE_RGUI> - windows, command (apple), meta

=item C<SDL_SCANCODE_MODE>

I'm not sure if this is really not covered by any of the above, but since
there's a special KMOD_MODE for it I'm adding it here

=back

These values are mapped from usage page 0x0C (USB consumer page).

=over

=item C<SDL_SCANCODE_AUDIONEXT>

=item C<SDL_SCANCODE_AUDIOPREV>

=item C<SDL_SCANCODE_AUDIOSTOP>

=item C<SDL_SCANCODE_AUDIOPLAY>

=item C<SDL_SCANCODE_AUDIOMUTE>

=item C<SDL_SCANCODE_MEDIASELECT>

=item C<SDL_SCANCODE_WWW>

=item C<SDL_SCANCODE_MAIL>

=item C<SDL_SCANCODE_CALCULATOR>

=item C<SDL_SCANCODE_COMPUTER>

=item C<SDL_SCANCODE_AC_SEARCH>

=item C<SDL_SCANCODE_AC_HOME>

=item C<SDL_SCANCODE_AC_BACK>

=item C<SDL_SCANCODE_AC_FORWARD>

=item C<SDL_SCANCODE_AC_STOP>

=item C<SDL_SCANCODE_AC_REFRESH>

=item C<SDL_SCANCODE_AC_BOOKMARKS>

=back

These are values that Christian Walther added (for mac keyboard?).

=over

=item C<SDL_SCANCODE_BRIGHTNESSDOWN>

=item C<SDL_SCANCODE_BRIGHTNESSUP>

=item C<SDL_SCANCODE_DISPLAYSWITCH> - display mirroring/dual display switch, video mode switch

=item C<SDL_SCANCODE_KBDILLUMTOGGLE>

=item C<SDL_SCANCODE_KBDILLUMDOWN>

=item C<SDL_SCANCODE_KBDILLUMUP>>

=item C<SDL_SCANCODE_EJECT>

=item C<SDL_SCANCODE_SLEEP>

=item C<SDL_SCANCODE_APP1>

=item C<SDL_SCANCODE_APP2>

=back

These values are mapped from usage page 0x0C (USB consumer page).

=over

=item C<SDL_SCANCODE_AUDIOREWIND>

=item C<SDL_SCANCODE_AUDIOFASTFORWARD>

=back

Add any other keys here.

=over

=item C<SDL_NUM_SCANCODES>

not a key, just marks the number of scancodes for array bounds

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

scancode scancodes num OSes gr

=end stopwords

=cut

};
1;
