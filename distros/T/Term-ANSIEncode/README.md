# ANSIEncode

![ANSIEncode Logo](ANSI-Encode.png?raw=true "ANSIEncode Logo Title Text 1")

## Description

Markup text to ANSI encoder

## Usage

**ansi-encode** [options] [text file name]

It is HIGHLY encouraged for your terminal be set as UTF-8 for the advanced features in this module/utility.

## Options

### -**v** or --**version**
```
    Show version and licensing info.
```

### -**h** or --**help**
```
    Usage information
```

### -**t** or --**tokens**
```
    Show most used tokens.
```

### -**c** or --**colors**
```
    Show color grid for use with "ANSI" and "GREY" tokens.
```

### -**s** or --**symbols** [search]
```
    Show all of the symbol character tokens by name.  Use search to shorten the huge list.
````

### -**u** or --**unicode** [search]
```
    Show all of the symbol character tokens by unicode.  Use search to shorten the huge list.
```

### -**d** or --**dump** [search]
~~~
    Shows the syumbols only
~~~

### -**f** or --**full**
```
    Use the full token table.  This will increase the initialization time.
```

## Author

Richard Kelsch

* **GitHub** - https://github.com/richcsst

## Tokens

Tokens have to be encapsulated inside [% token %] (the token must be surrounded by at least one space on each side.  Colors beyond the standard 8 will require a terminal that supports 256 colors.

NOTE:  Use "less -r" to view ANSI in "less"

### GENERAL

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
| ANSI0 - ANSI231 | Term256 colors (use -c to see these) |
| GREY0 - GREY23  | Levels of grey |

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
| BRIGHT B_BLACK | Bright black (grey) |
| BRIGHT B_RED | Bright red |
| BRIGHT B_GREEN | Lime |
| BRIGHT B_YELLOW | Bright yellow |
| BRIGHT B_BLUE | Bright blue |
| BRIGHT B_MAGENTA | Bright magenta |
| BRIGHT B_CYAN | Bright cyan |
| BRIGHT B_WHITE | Bright white |
| B_ANSI0 - B_ANSI231 | Term256 background colors (use -c to see these) |
| B_GREY0 - B_GREY23 | Levels of grey |

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

