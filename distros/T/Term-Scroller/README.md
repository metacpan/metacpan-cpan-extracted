# 📜 scroller 📜

View the output of a command inside a scrolling window in your terminal.

## Installation

```sh
perl Build.PL
./Build
./Build test
./Build install
```

## Usage

```
scroller [-h|--help] \[-s|--size SIZE\] [-c|--color COLOR] 
         [--on-exit keep|error|print] [-w|--window WINDOWSPEC]
         COMMAND ARGS..
```
scroller runs a provided command and displays its output (both stderr
and stdout) in a scrolling window in the terminal. By default, the window
is 10 lines tall and as wide as the currently connected terminal, although
this size can be set manually using the `--size`/`-s` option.

Interactive commands or commands that themselves manipulate the terminal will
_not_ play nice with scroller and will likely produce garbled output.

### Examples

```sh
# Default options (window is 10 lines tall with no border)
scroller mycommand

# Adjust the window height to 25 lines, and use a preset border
scroller --size 25 --window box mycommand

# Adjust window height and width, use a custom window design
scroller --size 25x40 --window '-#|#-#|#'

# If 'mycommand' fails, display its entire output when its done
scroller --on-exit error mycommand

# Pipe into another command
# 'myothercommand' will see the unaltered stdout of 'mycommand'!
scroller mycommand | myothercommand
```

### OPTIONS

- _-h_, _--help_ 

    Display help and exit.

- _-s_, _--size_ **SIZE**

    Set the size of view window. **SIZE** is of the form _H\[xW\]_ where _H_ is the 
    height (in lines) of the window and _W_ is the width (in columns) of the
    window. If width isn't specifed, it will default to the width the connected
    terminal (or 80 if the width couldn't be determined for some reason).

- _-c_, _--color_ **COLOR**

    Set the color of the text within the window. **COLOR** is any ANSI escape
    sequence **without** the initial escape character (e.g. "\[34m" for blue text).
    If this is set, any escape sequences within the command's actual output will
    be ignored. Without it, color-setting escape sequences in the output are passed
    through.

- _--on-exit_ **keep|error|print**

    Set the behavior of scroller after the command exits. Value is one of _keep_,
    _error_ or _print_. If _keep_, then the window will remain with the 
    last lines of output still visible. If _print_, then the window will be erased
    and the **entire** output of the command will be printed. _error_ is like
    _print_ except the output will only be printed if the command fails 
    (non-zero exit status). If this option is not specified, then the window
    disappears after the command exits.

- _-w_, _--window_ **WINDOWSPEC**

    Specify the borders of a window to draw around the view of the output text.
    See the **WINDOW DRAWING** section for how to create a **WINDOWSPEC**.
    Alternatively, you can provide one of the words, _box_, _flagpole_, _pipe_,
    _box-ascii_, _flagpole-acii_ or _pipe-ascii_, to use a preset design. The
    regular presets use Unicode box drawing characters, so if you're limited to
    only ascii, use one of the "-ascii" variants. See the **WINDOW PRESETS** section
    for examples of the presets.

### OUTPUT REDIRECTION & PIPES

If scroller is called such that it outputs directly to the terminal, then
the the scrolling window is printed on stderr. However, scroller is designed
to play well with pipelines and redirection, so if the output (of either
stdout or stderr) is not a terminal (such as a pipe or file) then the scrolling
window is printed directly to _/dev/tty_ and the command's stdout and stderr
will pass through unchanged.

### WINDOW DRAWING

A **WINDOWSPEC** is a string up to 8 characters long indicating which character
to use for a part of the window, in clockwise order. That is, the characters
specify the top side, top-right corner, right side, bottom-right corner,
bottom side, bottom-left corner, left side and top-left corner respectively.
If any character is a whitespace or is missing (due to the string not being
long enough), then that part of the window will not be drawn.

### WINDOW PRESETS

(Depending on how you're viewing this document, the Unicode text may not
be displayed correctly)

- **box**: '─┐│┘─└│┌'

        ┌────────────┐
        │your text here│
        └────────────┘

- **flagpole**: '     ·│·'

        ·
        │your text here
        ·

- **pipe**: '      │ '

        │your text here

- **box-ascii**: '-#|#-#|#'

        #--------------#
        |your text here|
        #--------------#

- **flagpole-ascii**: '     #|#'

        #
        |your text here
        #

- **pipe-ascii**: '      | '

        |your text here

# LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Cameron Tauxe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
