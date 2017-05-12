MODULE = OIS     PACKAGE = OIS::Keyboard

bool
Keyboard::isKeyDown(key)
    KeyCode  key

## This is a bit different than the C++ API,
## but not too much. You create a Perl class that
## implements the OIS::KeyListener interface (two methods),
## then pass an object of that class here.
## Behind the scenes, there is a C++ class PerlOISKeyListener
## that handles calling your Perl code from the C++ callback.
## (perlKeyListener below is instantiated "globally" in OIS.xs.)
void
Keyboard::setEventCallback(keyListener)
    SV * keyListener
  CODE:
    poisKeyListener.setPerlObject(keyListener);
    THIS->setEventCallback(&poisKeyListener);

## hmm, not sure why you would want to get this...
KeyListener *
Keyboard::getEventCallback()

void
Keyboard::setTextTranslation(mode)
    int  mode
  C_ARGS:
    (OIS::Keyboard::TextTranslationMode)mode

int
Keyboard::getTextTranslation()

string
Keyboard::getAsString(kc)
    KeyCode  kc

bool
Keyboard::isModifierDown(mod)
    int  mod
  C_ARGS:
    (OIS::Keyboard::Modifier)mod

## this is not wrapped:
## void OIS::Keyboard::copyKeyStates(char keys[256])


## TextTranslationMode enum
static int
Keyboard::Off()
  ALIAS:
    OIS::Keyboard::Unicode = 1
    OIS::Keyboard::Ascii = 2
  CODE:
    switch (ix) {
        case 0: RETVAL = OIS::Keyboard::Off; break;
        case 1: RETVAL = OIS::Keyboard::Unicode; break;
        case 2: RETVAL = OIS::Keyboard::Ascii; break;
    }
  OUTPUT:
    RETVAL

## Modifier enum
static int
Keyboard::Shift()
  ALIAS:
    OIS::Keyboard::Ctrl = 1
    OIS::Keyboard::Alt = 2
  CODE:
    switch (ix) {
        case 0: RETVAL = OIS::Keyboard::Shift; break;
        case 1: RETVAL = OIS::Keyboard::Ctrl; break;
        case 2: RETVAL = OIS::Keyboard::Alt; break;
    }
  OUTPUT:
    RETVAL

## xxx: surely there is a better way than this...
## (technically, these are in OIS namespace, not OIS::Keyboard)
## KeyCode enum
static int
Keyboard::KC_UNASSIGNED()
  ALIAS:
    OIS::Keyboard::KC_ESCAPE = 1
    OIS::Keyboard::KC_1 = 2
    OIS::Keyboard::KC_2 = 3
    OIS::Keyboard::KC_3 = 4
    OIS::Keyboard::KC_4 = 5
    OIS::Keyboard::KC_5 = 6
    OIS::Keyboard::KC_6 = 7
    OIS::Keyboard::KC_7 = 8
    OIS::Keyboard::KC_8 = 9
    OIS::Keyboard::KC_9 = 10
    OIS::Keyboard::KC_0 = 11
    OIS::Keyboard::KC_MINUS = 12
    OIS::Keyboard::KC_EQUALS = 13
    OIS::Keyboard::KC_BACK = 14
    OIS::Keyboard::KC_TAB = 15
    OIS::Keyboard::KC_Q = 16
    OIS::Keyboard::KC_W = 17
    OIS::Keyboard::KC_E = 18
    OIS::Keyboard::KC_R = 19
    OIS::Keyboard::KC_T = 20
    OIS::Keyboard::KC_Y = 21
    OIS::Keyboard::KC_U = 22
    OIS::Keyboard::KC_I = 23
    OIS::Keyboard::KC_O = 24
    OIS::Keyboard::KC_P = 25
    OIS::Keyboard::KC_LBRACKET = 26
    OIS::Keyboard::KC_RBRACKET = 27
    OIS::Keyboard::KC_RETURN = 28
    OIS::Keyboard::KC_LCONTROL = 29
    OIS::Keyboard::KC_A = 30
    OIS::Keyboard::KC_S = 31
    OIS::Keyboard::KC_D = 32
    OIS::Keyboard::KC_F = 33
    OIS::Keyboard::KC_G = 34
    OIS::Keyboard::KC_H = 35
    OIS::Keyboard::KC_J = 36
    OIS::Keyboard::KC_K = 37
    OIS::Keyboard::KC_L = 38
    OIS::Keyboard::KC_SEMICOLON = 39
    OIS::Keyboard::KC_APOSTROPHE = 40
    OIS::Keyboard::KC_GRAVE = 41
    OIS::Keyboard::KC_LSHIFT = 42
    OIS::Keyboard::KC_BACKSLASH = 43
    OIS::Keyboard::KC_Z = 44
    OIS::Keyboard::KC_X = 45
    OIS::Keyboard::KC_C = 46
    OIS::Keyboard::KC_V = 47
    OIS::Keyboard::KC_B = 48
    OIS::Keyboard::KC_N = 49
    OIS::Keyboard::KC_M = 50
    OIS::Keyboard::KC_COMMA = 51
    OIS::Keyboard::KC_PERIOD = 52
    OIS::Keyboard::KC_SLASH = 53
    OIS::Keyboard::KC_RSHIFT = 54
    OIS::Keyboard::KC_MULTIPLY = 55
    OIS::Keyboard::KC_LMENU = 56
    OIS::Keyboard::KC_SPACE = 57
    OIS::Keyboard::KC_CAPITAL = 58
    OIS::Keyboard::KC_F1 = 59
    OIS::Keyboard::KC_F2 = 60
    OIS::Keyboard::KC_F3 = 61
    OIS::Keyboard::KC_F4 = 62
    OIS::Keyboard::KC_F5 = 63
    OIS::Keyboard::KC_F6 = 64
    OIS::Keyboard::KC_F7 = 65
    OIS::Keyboard::KC_F8 = 66
    OIS::Keyboard::KC_F9 = 67
    OIS::Keyboard::KC_F10 = 68
    OIS::Keyboard::KC_NUMLOCK = 69
    OIS::Keyboard::KC_SCROLL = 70
    OIS::Keyboard::KC_NUMPAD7 = 71
    OIS::Keyboard::KC_NUMPAD8 = 72
    OIS::Keyboard::KC_NUMPAD9 = 73
    OIS::Keyboard::KC_SUBTRACT = 74
    OIS::Keyboard::KC_NUMPAD4 = 75
    OIS::Keyboard::KC_NUMPAD5 = 76
    OIS::Keyboard::KC_NUMPAD6 = 77
    OIS::Keyboard::KC_ADD = 78
    OIS::Keyboard::KC_NUMPAD1 = 79
    OIS::Keyboard::KC_NUMPAD2 = 80
    OIS::Keyboard::KC_NUMPAD3 = 81
    OIS::Keyboard::KC_NUMPAD0 = 82
    OIS::Keyboard::KC_DECIMAL = 83
    OIS::Keyboard::KC_OEM_102 = 84
    OIS::Keyboard::KC_F11 = 85
    OIS::Keyboard::KC_F12 = 86
    OIS::Keyboard::KC_F13 = 87
    OIS::Keyboard::KC_F14 = 88
    OIS::Keyboard::KC_F15 = 89
    OIS::Keyboard::KC_KANA = 90
    OIS::Keyboard::KC_ABNT_C1 = 91
    OIS::Keyboard::KC_CONVERT = 92
    OIS::Keyboard::KC_NOCONVERT = 93
    OIS::Keyboard::KC_YEN = 94
    OIS::Keyboard::KC_ABNT_C2 = 95
    OIS::Keyboard::KC_NUMPADEQUALS = 96
    OIS::Keyboard::KC_PREVTRACK = 97
    OIS::Keyboard::KC_AT = 98
    OIS::Keyboard::KC_COLON = 99
    OIS::Keyboard::KC_UNDERLINE = 100
    OIS::Keyboard::KC_KANJI = 101
    OIS::Keyboard::KC_STOP = 102
    OIS::Keyboard::KC_AX = 103
    OIS::Keyboard::KC_UNLABELED = 104
    OIS::Keyboard::KC_NEXTTRACK = 105
    OIS::Keyboard::KC_NUMPADENTER = 106
    OIS::Keyboard::KC_RCONTROL = 107
    OIS::Keyboard::KC_MUTE = 108
    OIS::Keyboard::KC_CALCULATOR = 109
    OIS::Keyboard::KC_PLAYPAUSE = 110
    OIS::Keyboard::KC_MEDIASTOP = 111
    OIS::Keyboard::KC_VOLUMEDOWN = 112
    OIS::Keyboard::KC_VOLUMEUP = 113
    OIS::Keyboard::KC_WEBHOME = 114
    OIS::Keyboard::KC_NUMPADCOMMA = 115
    OIS::Keyboard::KC_DIVIDE = 116
    OIS::Keyboard::KC_SYSRQ = 117
    OIS::Keyboard::KC_RMENU = 118
    OIS::Keyboard::KC_PAUSE = 119
    OIS::Keyboard::KC_HOME = 120
    OIS::Keyboard::KC_UP = 121
    OIS::Keyboard::KC_PGUP = 122
    OIS::Keyboard::KC_LEFT = 123
    OIS::Keyboard::KC_RIGHT = 124
    OIS::Keyboard::KC_END = 125
    OIS::Keyboard::KC_DOWN = 126
    OIS::Keyboard::KC_PGDOWN = 127
    OIS::Keyboard::KC_INSERT = 128
    OIS::Keyboard::KC_DELETE = 129
    OIS::Keyboard::KC_LWIN = 130
    OIS::Keyboard::KC_RWIN = 131
    OIS::Keyboard::KC_APPS = 132
    OIS::Keyboard::KC_POWER = 133
    OIS::Keyboard::KC_SLEEP = 134
    OIS::Keyboard::KC_WAKE = 135
    OIS::Keyboard::KC_WEBSEARCH = 136
    OIS::Keyboard::KC_WEBFAVORITES = 137
    OIS::Keyboard::KC_WEBREFRESH = 138
    OIS::Keyboard::KC_WEBSTOP = 139
    OIS::Keyboard::KC_WEBFORWARD = 140
    OIS::Keyboard::KC_WEBBACK = 141
    OIS::Keyboard::KC_MYCOMPUTER = 142
    OIS::Keyboard::KC_MAIL = 143
    OIS::Keyboard::KC_MEDIASELECT = 144
  CODE:
    switch (ix) {
        case 0: RETVAL = OIS::KC_UNASSIGNED; break;
        case 1: RETVAL = OIS::KC_ESCAPE; break;
        case 2: RETVAL = OIS::KC_1; break;
        case 3: RETVAL = OIS::KC_2; break;
        case 4: RETVAL = OIS::KC_3; break;
        case 5: RETVAL = OIS::KC_4; break;
        case 6: RETVAL = OIS::KC_5; break;
        case 7: RETVAL = OIS::KC_6; break;
        case 8: RETVAL = OIS::KC_7; break;
        case 9: RETVAL = OIS::KC_8; break;
        case 10: RETVAL = OIS::KC_9; break;
        case 11: RETVAL = OIS::KC_0; break;
        case 12: RETVAL = OIS::KC_MINUS; break;
        case 13: RETVAL = OIS::KC_EQUALS; break;
        case 14: RETVAL = OIS::KC_BACK; break;
        case 15: RETVAL = OIS::KC_TAB; break;
        case 16: RETVAL = OIS::KC_Q; break;
        case 17: RETVAL = OIS::KC_W; break;
        case 18: RETVAL = OIS::KC_E; break;
        case 19: RETVAL = OIS::KC_R; break;
        case 20: RETVAL = OIS::KC_T; break;
        case 21: RETVAL = OIS::KC_Y; break;
        case 22: RETVAL = OIS::KC_U; break;
        case 23: RETVAL = OIS::KC_I; break;
        case 24: RETVAL = OIS::KC_O; break;
        case 25: RETVAL = OIS::KC_P; break;
        case 26: RETVAL = OIS::KC_LBRACKET; break;
        case 27: RETVAL = OIS::KC_RBRACKET; break;
        case 28: RETVAL = OIS::KC_RETURN; break;
        case 29: RETVAL = OIS::KC_LCONTROL; break;
        case 30: RETVAL = OIS::KC_A; break;
        case 31: RETVAL = OIS::KC_S; break;
        case 32: RETVAL = OIS::KC_D; break;
        case 33: RETVAL = OIS::KC_F; break;
        case 34: RETVAL = OIS::KC_G; break;
        case 35: RETVAL = OIS::KC_H; break;
        case 36: RETVAL = OIS::KC_J; break;
        case 37: RETVAL = OIS::KC_K; break;
        case 38: RETVAL = OIS::KC_L; break;
        case 39: RETVAL = OIS::KC_SEMICOLON; break;
        case 40: RETVAL = OIS::KC_APOSTROPHE; break;
        case 41: RETVAL = OIS::KC_GRAVE; break;
        case 42: RETVAL = OIS::KC_LSHIFT; break;
        case 43: RETVAL = OIS::KC_BACKSLASH; break;
        case 44: RETVAL = OIS::KC_Z; break;
        case 45: RETVAL = OIS::KC_X; break;
        case 46: RETVAL = OIS::KC_C; break;
        case 47: RETVAL = OIS::KC_V; break;
        case 48: RETVAL = OIS::KC_B; break;
        case 49: RETVAL = OIS::KC_N; break;
        case 50: RETVAL = OIS::KC_M; break;
        case 51: RETVAL = OIS::KC_COMMA; break;
        case 52: RETVAL = OIS::KC_PERIOD; break;
        case 53: RETVAL = OIS::KC_SLASH; break;
        case 54: RETVAL = OIS::KC_RSHIFT; break;
        case 55: RETVAL = OIS::KC_MULTIPLY; break;
        case 56: RETVAL = OIS::KC_LMENU; break;
        case 57: RETVAL = OIS::KC_SPACE; break;
        case 58: RETVAL = OIS::KC_CAPITAL; break;
        case 59: RETVAL = OIS::KC_F1; break;
        case 60: RETVAL = OIS::KC_F2; break;
        case 61: RETVAL = OIS::KC_F3; break;
        case 62: RETVAL = OIS::KC_F4; break;
        case 63: RETVAL = OIS::KC_F5; break;
        case 64: RETVAL = OIS::KC_F6; break;
        case 65: RETVAL = OIS::KC_F7; break;
        case 66: RETVAL = OIS::KC_F8; break;
        case 67: RETVAL = OIS::KC_F9; break;
        case 68: RETVAL = OIS::KC_F10; break;
        case 69: RETVAL = OIS::KC_NUMLOCK; break;
        case 70: RETVAL = OIS::KC_SCROLL; break;
        case 71: RETVAL = OIS::KC_NUMPAD7; break;
        case 72: RETVAL = OIS::KC_NUMPAD8; break;
        case 73: RETVAL = OIS::KC_NUMPAD9; break;
        case 74: RETVAL = OIS::KC_SUBTRACT; break;
        case 75: RETVAL = OIS::KC_NUMPAD4; break;
        case 76: RETVAL = OIS::KC_NUMPAD5; break;
        case 77: RETVAL = OIS::KC_NUMPAD6; break;
        case 78: RETVAL = OIS::KC_ADD; break;
        case 79: RETVAL = OIS::KC_NUMPAD1; break;
        case 80: RETVAL = OIS::KC_NUMPAD2; break;
        case 81: RETVAL = OIS::KC_NUMPAD3; break;
        case 82: RETVAL = OIS::KC_NUMPAD0; break;
        case 83: RETVAL = OIS::KC_DECIMAL; break;
        case 84: RETVAL = OIS::KC_OEM_102; break;
        case 85: RETVAL = OIS::KC_F11; break;
        case 86: RETVAL = OIS::KC_F12; break;
        case 87: RETVAL = OIS::KC_F13; break;
        case 88: RETVAL = OIS::KC_F14; break;
        case 89: RETVAL = OIS::KC_F15; break;
        case 90: RETVAL = OIS::KC_KANA; break;
        case 91: RETVAL = OIS::KC_ABNT_C1; break;
        case 92: RETVAL = OIS::KC_CONVERT; break;
        case 93: RETVAL = OIS::KC_NOCONVERT; break;
        case 94: RETVAL = OIS::KC_YEN; break;
        case 95: RETVAL = OIS::KC_ABNT_C2; break;
        case 96: RETVAL = OIS::KC_NUMPADEQUALS; break;
        case 97: RETVAL = OIS::KC_PREVTRACK; break;
        case 98: RETVAL = OIS::KC_AT; break;
        case 99: RETVAL = OIS::KC_COLON; break;
        case 100: RETVAL = OIS::KC_UNDERLINE; break;
        case 101: RETVAL = OIS::KC_KANJI; break;
        case 102: RETVAL = OIS::KC_STOP; break;
        case 103: RETVAL = OIS::KC_AX; break;
        case 104: RETVAL = OIS::KC_UNLABELED; break;
        case 105: RETVAL = OIS::KC_NEXTTRACK; break;
        case 106: RETVAL = OIS::KC_NUMPADENTER; break;
        case 107: RETVAL = OIS::KC_RCONTROL; break;
        case 108: RETVAL = OIS::KC_MUTE; break;
        case 109: RETVAL = OIS::KC_CALCULATOR; break;
        case 110: RETVAL = OIS::KC_PLAYPAUSE; break;
        case 111: RETVAL = OIS::KC_MEDIASTOP; break;
        case 112: RETVAL = OIS::KC_VOLUMEDOWN; break;
        case 113: RETVAL = OIS::KC_VOLUMEUP; break;
        case 114: RETVAL = OIS::KC_WEBHOME; break;
        case 115: RETVAL = OIS::KC_NUMPADCOMMA; break;
        case 116: RETVAL = OIS::KC_DIVIDE; break;
        case 117: RETVAL = OIS::KC_SYSRQ; break;
        case 118: RETVAL = OIS::KC_RMENU; break;
        case 119: RETVAL = OIS::KC_PAUSE; break;
        case 120: RETVAL = OIS::KC_HOME; break;
        case 121: RETVAL = OIS::KC_UP; break;
        case 122: RETVAL = OIS::KC_PGUP; break;
        case 123: RETVAL = OIS::KC_LEFT; break;
        case 124: RETVAL = OIS::KC_RIGHT; break;
        case 125: RETVAL = OIS::KC_END; break;
        case 126: RETVAL = OIS::KC_DOWN; break;
        case 127: RETVAL = OIS::KC_PGDOWN; break;
        case 128: RETVAL = OIS::KC_INSERT; break;
        case 129: RETVAL = OIS::KC_DELETE; break;
        case 130: RETVAL = OIS::KC_LWIN; break;
        case 131: RETVAL = OIS::KC_RWIN; break;
        case 132: RETVAL = OIS::KC_APPS; break;
        case 133: RETVAL = OIS::KC_POWER; break;
        case 134: RETVAL = OIS::KC_SLEEP; break;
        case 135: RETVAL = OIS::KC_WAKE; break;
        case 136: RETVAL = OIS::KC_WEBSEARCH; break;
        case 137: RETVAL = OIS::KC_WEBFAVORITES; break;
        case 138: RETVAL = OIS::KC_WEBREFRESH; break;
        case 139: RETVAL = OIS::KC_WEBSTOP; break;
        case 140: RETVAL = OIS::KC_WEBFORWARD; break;
        case 141: RETVAL = OIS::KC_WEBBACK; break;
        case 142: RETVAL = OIS::KC_MYCOMPUTER; break;
        case 143: RETVAL = OIS::KC_MAIL; break;
        case 144: RETVAL = OIS::KC_MEDIASELECT; break;
    }
  OUTPUT:
    RETVAL
