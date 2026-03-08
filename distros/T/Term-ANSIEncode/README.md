# Term::ANSIEncode

![Term::ANSIEncode Logo](images/ANSI-Encode.png?raw=true "Term::ANSIEncode Logo Title Text")

## Description

Markup text to ANSI encoder.  Very handy for making server identification screens.

GitHub will ALWAYS have the latest version and CPAN is not guaranteed to have the latest.

## Usage

### To use the Perl module:
```
 # Read the module's POD manual for more information, via "man" or "perldoc"

 my $ansi = Term::ANSIEncode->new;

 my $string = '[% CLS %]Some markup encoded string';
 $string .= "\n" . '[% RED     %]Red foreground[% RESET %]' . "\n";
 $string .= "\n" . '[% YELLOW  %]Yellow foreground[% RESET %]' . "\n";
 $string .= "\n" . '[% GREEN   %]Green foreground[% RESET %]' . "\n";
 $string .= "\n" . '[% CYAN    %]Cyan foreground[% RESET %]' . "\n";
 $string .= "\n" . '[% BLUE    %]Blue foreground[% RESET %]' . "\n";
 $string .= "\n" . '[% MAGENTA %]Magenta foreground[% RESET %]' . "\n";

 $ansi->ansi_output($string);
```
### To use the executable, run:
```
ansi-encode [options] [File or Search]
```
It is **HIGHLY** encouraged for your terminal be set as **UTF-8** for the advanced features in this module/utility.  It is also encouraged that you use a font having the graphics characters for frames and other features.

Excellent True-Type fonts for use:  http://github.com/gabrielelana/awesome-terminal-fonts (Listed as "Source Code" fonts)

For Windows, this setting is in your "Region" setting.  Also note, Windows Terminal/Command/PowerShell lacks some capabilities.

## Options

![Help Screen](images/help.png?raw=true "Term::ANSIEncode Help Screen")

### -**a** or --**ansi-modes**

Show aupported ANSI color modes

![Support Color Modes](images/supported.png?raw=true "Term::ANSIEncode Supported Color Modes")

### --**baud**=speed

Slow down output to the specific baud rate.  It can be any baud rate.  Full speed otherwise.

### -**c** or --**colors**

Show color grid for use with "COLOR" and "GRAY" tokens.

![Colors](images/colors.png?raw=true "Term::ANSIEncode Color Examples")

### -**d** or --**dump** [search]

Shows the symbols only.

### -**f** or --**frame**

Show sample frame types.

![Frames](images/frames.png?raw=true "Term::ANSIEncode Frames Example")

### -**h** or --**horizontal-rules**

Show sample horizontal rules.

![Horizontal Rules](images/rules.png?raw=true "Term::ANSIEncode Horizontal Rules Example")

### -**r** or --**rawtokens**

Raw dump of available tokens.

### -**s** or --**symbols** [search]

Show all of the symbol character tokens by name.  Use search to shorten the huge list.

### -**t** or --**tokens**

Show most used tokens.

### -**u** or --**unicode** [search]

Show all of the symbol character tokens by unicode.  Use search to shorten the huge list.

### -**v** or --**version**

Show version and licensing info.

![Version](images/version.png?raw=true "Term::ANSIEncode Version")

## Author

Richard Kelsch

* **GitHub** - https://github.com/richcsst

## Fonts

Some fonts do not support all of the Unicode characters.  The "examples" directory has an install script to install the "Awesome" fonts that look great and have all Unicode symbols.  They look great, are easy to read and have a plethora of support for the graphics and unicode characters.  They are TrueType fonts and can be installed on most systems and terminals.

* http://github.com/gabrielelana/awesome-terminal-fonts

I suggest "**SourceCodePro-Powerline-Awesome**" when selecting a font

## Tokens

Tokens have to be encapsulated inside [% token %] (the token must be surrounded by at least one space on each side.  Colors beyond the standard 8 will require a terminal that supports 16, 256 and/or 16.7 million colors.  This list is only a partial list of tokens.

NOTE:  Use "less -r" to view ANSI in "less".

### CLEAR

Please use the "-t" option to see all of the tokens.  This is only a partial list.

| **Token** | **Description** |
| --- | --- |
| CLEAR | Places cursor at top left, screen cleared |
| CLS | Same as CLEAR |
| CLEAR LINE | Clear to the end of line |
| CLEAR DOWN | Clear down from current cursor position |
| CLEAR UP | Clear up from current cursor position |

### CURSOR

| **Token** | **Description** |
| --- | --- |
| CURSOR OFF | Turn off the text cursor |
| CURSOR ON | Turn on the text cursor |
| DOWN | Moves cursor down one step |
| HOME | Place the cursor at the top-left of the screen |
| LEFT | Moves cursor left one step |
| LINEFEED | One line down, keeping horizontal position the same.  Will scroll if the bottom of the screen |
| NEWLINE | Start a new (blank) line on column 1 of the next line.  Will scroll if the bottom of the screen.
| NEXT LINE | Move to column 1 of the next line down.
| PREVIOUS LINE | Move to column 1 of the previous line.
| RESTORE | Place cursor at saved position |
| RETURN | Sends a carriage return (ASCII 13) |
| RIGHT | Moves cursor right one step |
| SAVE | Save cursor position |
| SCREEN 1 | Sets display to screen 1 (default) |
| SCREEN 2 | Sets display to screen 2 |
| UP | Moves cursor up one step |
| SPACES count | "count" number of spaces |
| TABS count | "count" number of horizontal tabs |
| CHAR character,count | Repeat "character" "count" number of times |
| LOCATE column,row | Sets the cursor location |
| SCROLL UP count | Scroll the screen up "count" number of times |
| SCROLL DOWN count | Scroll the screen down "count" number of times |

### ATTRIBUTES

| **Token** | **Description** |
| --- | --- |
| BOLD | Bold text |
| CROSSED OUT | Crossed out (not all terminals support this) |
| DEFAULT FONT | Set to the default font |
| DEFAULT UNDERLINE COLOR | Set to the default color for the underline attribute |
| ENCIRCLED | Turn on encircled letters |
| ENCIRCLED OFF | Turn off encircled letters |
| FAINT | Use faint (light) text |
| FONT DEFAULT | Use default font size |
| FONT DOUBLE-HEIGHT BOTTOM | Use double-height font bottom half |
| FONT DOUBLE-HEIGHT TOP | Use double-height font top half |
| FONT DOUBLE-WIDTH | Use double-width font |
| FRAMED | Turn on framed text |
| FRAMED OFF | Turn off framed text |
| HIDE | Hide text (later exposed with REVEAL) |
| INVERT | Invert text (swap foreground and background colors) |
| ITALIC | Show italic text |
| NORMAL | Set text attributes back to defaults |
| OVERLINED | Turn on overlined text |
| OVERLINED OFF | Turn off overlined text |
| PROPORTIONAL OFF | Turn off proportional spaced text |
| PROPORTIONAL ON | Turn on proportional spaced text |
| RAPID BLINK | Blink text rapidly |
| RESET | Reset all colors and attributes to their defaults |
| REVEAL | Show all text hidden with HIDE |
| REVERSE | Invert text (just like INVERT) |
| RING BELL | Rings the console bell |
| SLOW BLINK | Blink text slowly |
| SUBSCRIPT | Turn on subscript text |
| SUBSCRIPT OFF | Turn off subscript text |
| SUPERSCRIPT | Turn on superscript text |
| SUPERSCRIPT OFF | Turn off superscript text |
| UNDERLINE | Underline text |
| UNDERLINE COLOR color | Set the color of underlines to the color token |
| WRAP | Begin text region to be word-wrapped |
| ENDWRAP | Ends text region to be word-wrapped |
| JUSTFIFIED | Begin text region to be word-wrapped and justified |
| ENDJUSTIFIED | End text region to be word-wraopped and justified |

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
| RGB red,green,blue | 24 bit colors |

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
} B_RGB red,green,blue | 24 bit background colors |

### HORIZONTAL RULES

| **Token** | **Description** |
| --- | --- |
| HORIZONTAL RULE token | A solid line of background in the color defined by "token" |

## SUGGESTIONS

* When making a tokenized file for output, first prepare what you want to show in just black and white text.
* Make two copies of the output in the file and only work on the last copy for adding color and attributes, referring to the original above for reference.
* Have a second terminal window open to run ```ansi-encode [filename]``` to quickly see what the output looks like, without having to exit your editor.
* Remove the original copy, once everything looks great, then you are finished.

