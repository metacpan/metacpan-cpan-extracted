## NAME

Term::ANSIEncode

![Term::ANSIEncode](../../images/ANSI-Encode.png?raw-true "Term::ANSIEncode graphic")

## SYNOPSIS

A markup language to generate basic ANSI text.  A terminal that supports UTF-8 is required if you wish to have special characters, both graphical and international.

## USAGE
```
 my $ansi = Term::ANSIEncode->new;

 my $string = 'CLSSome markup encoded string';
 $string .= "\n" . '[% RED     %]Red foreground[% RESET %]' . "\n";
 $string .= "\n" . '[% YELLOW  %]Yellow foreground[% RESET %]' . "\n";
 $string .= "\n" . '[% GREEN   %]Green foreground[% RESET %]' . "\n";
 $string .= "\n" . '[% CYAN    %]Cyan foreground[% RESET %]' . "\n";
 $string .= "\n" . '[% BLUE    %]Blue foreground[% RESET %]' . "\n";
 $string .= "\n" . '[% MAGENTA %]Magenta foreground[% RESET %]' . "\n";

 $ansi->ansi_output($string);
```

## METHODS

| **Name** | **Description** |
| --- | --- |
| **new** | Instantiate the object.  All parameters are ignored. |
| **ansi_colors** | It returns one hash reference to a hash indicating color format support is returned (_see code below_) |

```
     # True = 1 amd 0 = False
     {
         '3 BIT'  => 0, # True for 8 color support (it should be the bare minimum supported)
         '4 BIT'  => 0, # True for bright color support.
         '8 BIT'  => 0, # True for 256 color support (Windows 10+) always
                        # supports.  Linux will have "256" in the TERM
                        # environmernt variable definition
         '24 BIT' => 0, # True for 16.4 million color support.  Not supported
                        # (yet) on Windows.  The Linux environment variable
                        # COLORTERM will ber set to "truecolor" for support.
     }
```

## TOKENS

### GENERAL

| **Token** | **Description** |
| --- | --- |
| **RETURN** | ASCII RETURN (13) |
| **LINEFEED** | ASCII LINEFEED (10) |
| **NEWLINE** | RETURN + LINEFEED (13 + 10) |
| **CLS** | Places cursor at top left, screen cleared |
| **CLEAR** | Clear screen only, cursor remains where it was |
| **CLEAR LINE** | Clear to the end of line |
| **CLEAR DOWN** | Clear down from current cursor position |
| **CLEAR UP** | Clear up from current cursor position |
| **RESET** | Reset all colors and attributes |

### CURSOR

| **Token** | **Description** |
| --- | --- |
| **HOME** | Moves the cursor to the location 1,1. |
| **UP** | Moves cursor up one step |
| **DOWN** | Moves cursor down one step |
| **RIGHT** | Moves cursor right one step |
| **LEFT** | Moves cursor left one step |
| **SAVE** | Save cursor position |
| **RESTORE** | Place cursor at saved position |
| **BOLD** | Bold text (not all terminals support this) |
| **FAINT** | Faded text (not all terminals support this) |
| **ITALIC** | Italicized text (not all terminals support this) |
| **UNDERLINE** | Underlined text |
| **SLOW BLINK** | Slow cursor blink |
| **RAPID BLINK** | Rapid cursor blink |
| **LOCATE column,row** | Set cursor position |

### ATTRIBUTES

| **Token** | **Description** |
| --- | --- |
| **INVERT** | Invert text (flip background and foreground attributes) |
| **REVERSE** | Reverse |
| **CROSSED OUT** | Crossed out |
| **DEFAULT FONT** | Default font |

### FRAMES

This special token takes parameters and requires an end token to function.  The text goes between the token and end token.

| **Token** | **End Token** | **Description** | Types |
| --- | --- | --- | --- |
| **BOX** color,x,y,width,height,type | **ENDBOX** | Draw a frame around text | THIN, ROUND, THICK, BLOCK, WEDGE, DOTS, DIAMOND, STAR, SQUARE |

### COLORS

| **Token** | **Description** |
| --- | --- |
| **NORMAL** | Sets colors to default |

### FOREGROUND

There are many more foreground colors available than those below.  However, the ones below should work on any color terminal.  Other colors may require 256 and 16 million color support.  Most Linux X-Windows and Wayland terminal software should support the extra colors.  Some Windows terminal software should have 'Term256' and 'truecolor' features.  You can used the '-t' option (in the executable "ansiencode" file) for all of the color tokens available or use the 'RGB' token for access to 16 million colors.

| **Token** | **Description** |
| --- | --- |
| **BLACK** | Black |
| **RED** | Red |
| **GREEN** | Green |
| **YELLOW** | Yellow |
| **BLUE** | Blue |
| **MAGENTA** | Magenta |
| **CYAN** | Cyan |
| **WHITE** | White |
| **DEFAULT** | Default foreground color |
| **BRIGHT BLACK** | Bright black (dim grey) |
| **BRIGHT RED** | Bright red |
| **BRIGHT GREEN** | Lime |
| **BRIGHT YELLOW** | Bright Yellow |
| **BRIGHT BLUE** | Bright blue |
| **BRIGHT MAGENTA** | Bright magenta |
| **BRIGHT CYAN** | Bright cyan |
| **BRIGHT WHITE** | Bright white |
| **RGB** red,green,blue | 24 bit color |

### BACKGROUND

There are many more background colors available than the sixteen below.  However, the ones below should work on any color terminal.  Other colors may requite 256 and 16 million color support.  Most Linux X-Windows and Wayland terminal software should support the extra colors.  Some Windows terminal software should have 'Term256' features.  You can used the '-t' option for all of the color tokens available or use the 'B_RGB' token for access to 16 million colors.

| **Token** | **Description** |
| --- | --- |
| **B_BLACK** | Black |
| **B_RED** | Red |
| **B_GREEN** | Green |
| **B_YELLOW** | Yellow |
| **B_BLUE** | Blue |
| **B_MAGENTA** | Magenta |
| **B_CYAN** | Cyan |
| **B_WHITE** | White |
| **B_DEFAULT** | Default background color |
| **B_BRIGHT BLACK** | Bright black (grey) |
| **B_BRIGHT RED** | Bright red |
| **B_BRIGHT GREEN** | Lime |
| **B_BRIGHT YELLOW** | Bright yellow |
| **B_BRIGHT BLUE** | Bright blue |
| **B_BRIGHT MAGENTA** | Bright magenta |
| **B_BRIGHT CYAN** | Bright cyan |
| **B_BRIGHT WHITE** | Bright white |
| **B_RGB** red,green,blue | 24 bit color definition |

### HORIZONAL RULES

Makes a solid blank line, the full width of the screen with the selected color

| **Token** | **Description** |
| --- | --- |
| **HORIZONTAL RULE** [color] | A solid line of [color] background |

### TEXT WRAP

These tokens have an end token where text to be wrapped have text between the token and end token.

| **Token** | **End Token** | **Description** | Types |
| --- | --- | --- | --- |
| WRAP | ENDWRAP | Begins text block to be word-wrapped |
| JUSTIFIED | ENDJUSTIFIED | Begins text block to be word-wrapped and justified |

## MACRO TOKENS

These tokens take a "count" value.

| **Token** | **Parameters** | **Description** |
| --- | --- | --- |
| SPACES | count | Output spaces |
| CHAR | character,count | Output a single character "count" number of times |

## AUTHOR & COPYRIGHT

Richard Kelsch

Copyright © 2025 Richard Kelsch
All Rights Reserved
Perl Artistic License

This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at;

http://www.perlfoundation.org/artistic_license_2_0
