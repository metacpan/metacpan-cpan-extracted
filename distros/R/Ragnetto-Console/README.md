# 🕷️ Ragnetto::Console

**Ragnetto::Console** is a lightweight Perl utility for terminal manipulation using ANSI escape sequences

It provides an easy-to-use interface for colors, cursor positioning, and non-blocking input handling.

This module is part of the ragnetto software suite.


---


## 🚀 Features

*   **ANSI Colors** : Full support for 16 foreground and background colors.
*   **Cursor Control** : Move (X, Y), toggle visibility (ON/OFF), and change shapes (Block, Bar, Underline).
*   **Advanced Input** : Read single keys immediately without pressing Enter (Non-blocking input) with or without Echo.
*   **Cross-platform** : Support for Unix-like systems (Linux/macOS) and Windows (via PowerShell integration).
*   **Terminal Info** : Auto-detect console width and height.


---


## 📦 Installation

Install the module via [CPAN](https://www.cpan.org/):

```bash
cpan Ragnetto::Console
```


---


## 🛠️ Quick Start

```perl
use Ragnetto::Console qw(:all);

# Clear screen and set window title
clear();
title("Ragnetto::Console Demo");

# Write colored text at specific coordinates (X, Y)
write("Welcome to Ragnetto::Console!", "LIGHT_GREEN", "BLACK", 10, 5);

# Read a key without waiting for Enter
print "\nPress any key to exit...";
getkey();

# Reset terminal styles to default
reset();
```

---


## 📖 API Reference

| Function | Description |
| :--- | :--- |
| `clear()` | Clears the screen and resets the cursor to the home position. |
| `backcolor($color)` | Set the background text color. |
| `forecolor($color)` | Set the foreground text color. |
| `cursor($state)` | Toggles cursor visibility. |
| `caret($shape)` | Changes the cursor shape. |
| `position($x, $y)` | Moves the cursor to the specified coordinates. |
| `write($text, [$f], [$b], [$x], [$y])` | Writes text with optional colors and coordinates. |
| `getkey()` | Reads a single keypress immediately (No-echo). |
| `putkey()` | Reads a single keypress and prints it (Echo). |
| `title($text)` | Sets the terminal window title. |
| `width()` | Returns the current terminal width. |
| `height()` | Returns the current terminal height. |
| `reset()` | Resets all styles, colors, and cursor states. |

---
## 💎 Constants

### 🎨 Colors

You can use these strings for foreground (`f`) and background (`b`) parameters:

*   **Standard**: `BLACK`, `RED`, `GREEN`, `YELLOW`, `BLUE`, `MAGENTA`, `CYAN`, `WHITE`
*   **Bright**: `GRAY`, `LIGHT_RED`, `LIGHT_GREEN`, `LIGHT_YELLOW`, `LIGHT_BLUE`, `LIGHT_MAGENTA`, `LIGHT_CYAN`, `LIGHT_WHITE`

### 🖱️ Caret Shapes

Values for the `Console::Caret(shape)` function:


| Constant | Description |
| :--- | :--- |
| `BLOCK_BLINK` | Blinking block cursor |
| `BLOCK_STEADY` | Static block cursor |
| `UNDER_BLINK` | Blinking underline cursor |
| `UNDER_STEADY` | Static underline cursor |
| `BAR_BLINK` | Blinking vertical bar |
| `BAR_STEADY` | Static vertical bar |


### ⚙️ States

Values for `Console::Cursor(state)`:
*   `1` or `"ON"`: Show cursor.
*   `0` or `"OFF"`: Hide cursor.

---


## 📝 License

Distributed under the MIT License. See LICENSE for more information.

Author: [ragnetto-gab](https://github.com/ragnetto-gab) (Ragnetto&reg;)

E-Mail: [ragnettosoftware@gmail.com](mailto:ragnettosoftware@gmail.com)
