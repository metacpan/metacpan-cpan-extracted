# Term::Ghostty Examples

Run the examples from the distribution root after building, so they load the
module you just built rather than an installed one:

```bash
perl Makefile.PL && make
perl -Mblib examples/ansi2html.pl --help
```

`headless_agent.pl`, `tui_test_framework.pl`, `split_multiplexer.pl`,
`live_web_monitor.pl` and `session_recorder.pl` run programs in a
pseudo-terminal and need `IO::Pty` (`cpanm IO::Pty`). The others use only core
modules.

Output read from a pipe or a file has bare LF line endings, which a terminal
treats as "move down" without returning to column 0; `ansi2html.pl` and
`terminal_diff.pl` turn them into CRLF, as a pty's line discipline would.

libghostty-vt keeps only a few hundred rows of scrollback unless `max_scrollback`
is given. `session_recorder.pl` keeps 100000 rows; `ansi2html.pl` keeps as many
rows as the input has lines, so nothing scrolls away.

---

### `ansi2html.pl`

Renders ANSI/VT output from files, stdin or a shell command (`--cmd`) as HTML,
scrollback included. `--standalone` wraps it in a complete page with default
foreground and background colors; the 256-color palette comes with the
library's HTML.

```bash
git log -p --color=always | perl -Mblib examples/ansi2html.pl --standalone > log.html
perl -Mblib examples/ansi2html.pl --cmd 'ls -la --color=always' --standalone > dir.html
```

---

### `headless_agent.pl`

Drives an interactive `bash` in a headless terminal. It waits for each new
prompt (the prompt carries bash's command number, so a stale prompt still on
screen never matches), lets Term::Ghostty answer the shell's cursor position
query through `on_pty_write`, reports title changes from `on_title_changed`, and
prints the final screen.

```bash
perl -Mblib examples/headless_agent.pl
```

---

### `asciinema_player.pl`

Replays an asciinema v2 (`.cast`) recording, output and resize events, through
Term::Ghostty. By default it prints the screen the recording ends on, or the
screen at `--frame-at SECONDS`, as plain text, VT or HTML (`--standalone` for a
complete page). `--speed N` plays the recording in your terminal instead.

```bash
perl -Mblib examples/asciinema_player.pl --format html --standalone recording.cast > recording.html
perl -Mblib examples/asciinema_player.pl --frame-at 3.5 recording.cast
perl -Mblib examples/asciinema_player.pl --speed 2 recording.cast
```

---

### `tui_test_framework.pl`

A small Test::More harness for terminal programs: it runs the program in a
pseudo-terminal, sends keys, and checks the screen text, cursor position,
window title and exit status. Screen and cursor checks poll until they pass or
time out, so they do not race the program. The demo tests a tiny menu program.

```bash
perl -Mblib examples/tui_test_framework.pl
```

---

### `terminal_diff.pl`

Feeds two command outputs or two files into separate terminals and prints the
resulting screens side by side, marking rows whose text differs with `!` and
comparing the cursor positions. Colors are not compared. Exits 1 when the
screens differ.

```bash
perl -Mblib examples/terminal_diff.pl --cmd1 'git status -s' --cmd2 'git status' --cols 45
perl -Mblib examples/terminal_diff.pl before.txt after.txt
```

---

### `split_multiplexer.pl`

Runs two commands, each in its own pseudo-terminal and Term::Ghostty instance,
and redraws both screens side by side in your terminal until `--duration`
seconds have passed or you press Ctrl-C.

```bash
perl -Mblib examples/split_multiplexer.pl --cmd1 'vmstat 1' --cmd2 'df -h' --duration 5
```

---

### `live_web_monitor.pl`

Runs a command (default `top -d 1`) in a pseudo-terminal and serves its current
screen as a web page that reloads every second. It listens on 127.0.0.1 unless
`--bind` says otherwise, sends a Content-Security-Policy that allows no
scripts, and keeps serving the last screen after the command exits.

```bash
perl -Mblib examples/live_web_monitor.pl --port 8080 --cmd 'top -d 1'
```

---

### `stream_ground_annotator.pl`

Inserts a marker into a VT stream at every chunk boundary. Inserted blindly,
the markers land inside an escape sequence, a UTF-8 character and an OSC title
and corrupt all three; inserted only where `write_until_ground` reports that
the parser is back in the ground state, they leave the output intact. Feeding
split chunks on their own is always fine: the parser keeps its state between
calls.

```bash
perl -Mblib examples/stream_ground_annotator.pl
```

---

### `session_recorder.pl`

Runs a command (default `$SHELL`) in a pseudo-terminal and passes it through to
your terminal, keyboard included. When the command exits, or the recorder gets
SIGINT, SIGTERM or SIGHUP, it writes the whole session to an HTML, plain text
or VT transcript and exits with the command's status.

```bash
perl -Mblib examples/session_recorder.pl --out build.html -- make
```

---

### `terminal_scraper.pl`

Feeds a full-screen dialog drawn with cursor addressing and reads it back: the
plain-text screen, values parsed from specific rows, the highlighted button
found through its reverse-video style in `get_vt`, and the cursor position and
visibility.

```bash
perl -Mblib examples/terminal_scraper.pl
```
