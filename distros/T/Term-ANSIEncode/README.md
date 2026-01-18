# Term::ANSIEncode

![ANSIEncode Logo](ANSI-Encode.png?raw=true "ANSIEncode Logo Title Text 1")

## Description

Markup text to ANSI encoder

## Usage

**ansi-encode** [options] [File or Search]

It is HIGHLY encouraged for your terminal be set as UTF-8 for the advanced features in this module/utility.

Read the pod or man page for Term::ANSIEncode

## Options

### -**a** or --**ansi-modes**
```
    Show aupported ANSI color modes
```

### --**baud**=speed
```
    Slow down output to the specific baud rate.  75, 150, 300, 600, 1200, 2400, 4800, 9600, 19200, 38400, 57600 or 115200
```

### -**c** or --**colors**
```
    Show color grid for use with "COLOR" and "GREY" tokens.
```

### -**d** or --**dump** [search]
~~~
    Shows the symbols only.
~~~

### -**f** or --**frame**
```
    Show sample frame types.
```

### -**h** or --**horizontal-rules**
```
    Show sample horizontal rules.
```

### -**r** or --**rawtokens**
```
    Raw dump of available tokens.
```

### -**s** or --**symbols** [search]
```
    Show all of the symbol character tokens by name.  Use search to shorten the huge list.
````

### -**t** or --**tokens**
```
    Show most used tokens.
```

### -**u** or --**unicode** [search]
```
    Show all of the symbol character tokens by unicode.  Use search to shorten the huge list.
```

### -**v** or --**version**
```
    Show version and licensing info.
```

## Author

Richard Kelsch

* **GitHub** - https://github.com/richcsst

## Fonts

Some fonts do not support all of the Unicode characters.  The "examples" directory has an install script to install the "Awesome" fonts that look great and have all Unicode symbols.

## Tokens

Tokens have to be encapsulated inside [% token %] (the token must be surrounded by at least one space on each side.  Colors beyond the standard 8 will require a terminal that supports 256 colors.

NOTE:  Use "less -r" to view ANSI in "less"

### GENERAL

Please use the "-t" option to see all of the tokens.  This is only a partial list.

| **Token** | **Description** |
| --- | --- |
| RETURN | ASCII RETURN (13) |
| LINEFEED | ASCII LINEFEED (10) |
| NEWLINE | RETURN + LINEFEED (13 + 10) |
| CLEAR | Places cursor at top left, screen cleared |
| CLS | Same as CLEAR |
| CLEAR LINE | Clear to the end of line |
| CLEAR DOWN | Clear down from current cursor position |
| CLEAR UP | Clear up from current cursor position |
| RESET | Reset all colors and attributes |

### CURSOR

| **Token** | **Description** |
| --- | --- |
| UP | Moves cursor up one step |
| DOWN | Moves cursor down one step |
| RIGHT | Moves cursor right one step |
| LEFT | Moves cursor left one step |
| SAVE | Save cursor position |
| RESTORE | Place cursor at saved position |
| BOLD | Bold text (not all terminals support this) |
| FAINT | Faded text (not all terminals support this) |
| ITALIC | Italicized text (not all terminals support this) |
| UNDERLINE | Underlined text (not all terminals support this) |
| SLOW BLINK | Slow cursor blink (Usually one speed for most) |
| RAPID BLINK | Rapid cursor blink (Usually one speed for most) |

### ATTRIBUTES

| **Token** | **Description** |
| --- | --- |
| INVERT | Invert text (flip background and foreground) |
| REVERSE | Reverse |
| CROSSED OUT | Crossed out (not all terminals support this) |
| DEFAULT FONT | Default font |

### COLORS

| **Token** | **Description** |
| --- | --- |
| NORMAL | Sets colors to default |

#### FOREGROUND

| **Token** | **Description** |
| --- | --- |
| DEFAULT | Default foreground color |
| BLACK | Black |
| RED | Red |
| PINK | Hot pink (requires 256 color terminal) |
| ORANGE | Orange (requires 256 color terminal) |
| NAVY | Deep blue (requires 256 color terminal) |
| GREEN | Green |
| YELLOW | Yellow |
| BLUE | Blue |
| MAGENTA | Magenta |
| CYAN | Cyan |
| WHITE | White |
| BRIGHT BLACK | Bright black (dim grey) |
| BRIGHT RED | Bright red |
| BRIGHT GREEN | Lime |
| BRIGHT YELLOW | Bright Yellow |
| BRIGHT BLUE | Bright blue |
| BRIGHT MAGENTA | Bright magenta |
| BRIGHT CYAN | Bright cyan |
| BRIGHT WHITE | Bright white |
| COLOR 16 - COLOR 231 | Term256 colors (use -c to see these) |
| GREY 0 - GREY 23  | Levels of grey |

#### BACKGROUND

| **Token** | **Description** |
| --- | --- |
| B_DEFAULT | Default background color |
| B_BLACK | Black |
| B_RED | Red |
| B_GREEN | Green |
| B_YELLOW | Yellow |
| B_BLUE | Blue |
| B_MAGENTA | Magenta |
| B_CYAN | Cyan |
| B_WHITE | White |
| B_PINK | Hot pink (requires 256 color terminal) |
| B_ORANGE | Orange (requires 256 color terminal) |
| B_NAVY | Deep blue (requires 256 color terminal) |
| B_BRIGHT BLACK | Bright black (grey) |
| B_BRIGHT RED | Bright red |
| B_BRIGHT GREEN | Lime |
| B_BRIGHT YELLOW | Bright yellow |
| B_BRIGHT BLUE | Bright blue |
| B_BRIGHT MAGENTA | Bright magenta |
| B_BRIGHT CYAN | Bright cyan |
| B_BRIGHT WHITE | Bright white |
| B_COLOR 16 - B_COLOR 231 | Term256 background colors (use -c to see these) |
| B_GREY 0 - B_GREY 23 | Levels of grey |

### HORIZONTAL RULES

| **Token** | **Description** |
| --- | --- |
| HORIZONTAL RULE RED | A solid line of red background |
| HORIZONTAL RULE GREEN | A solid line of green background |
| HORIZONTAL RULE YELLOW | A solid line of yellow background |
| HORIZONTAL RULE BLUE | A solid line of blue background |
| HORIZONTAL RULE MAGENTA | A solid line of magenta background |
| HORIZONTAL RULE CYAN | A solid line of cyan background |
| HORIZONTAL RULE PINK | A solid line of hot pink background |
| HORIZONTAL RULE ORANGE | A solid line of orange background |
| HORIZONTAL RULE WHITE | A solid line of white background |
| HORIZONTAL RULE BRIGHT RED | A solid line of bright red background |
| HORIZONTAL RULE BRIGHT GREEN | A solid line of bright green background |
| HORIZONTAL RULE BRIGHT YELLOW | A solid line of bright yellow background |
| HORIZONTAL RULE BRIGHT BLUE | A solid line of bright blue background |
| HORIZONTAL RULE BRIGHT MAGENTA | A solid line of bright magenta background |
| HORIZONTAL RULE BRIGHT CYAN  | A solid line of bright cyan background |
| HORIZONTAL RULE BRIGHT WHITE | A solid line of bright white background |


