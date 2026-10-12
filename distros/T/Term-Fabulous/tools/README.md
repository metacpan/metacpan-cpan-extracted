# Maintainer tools

Maintainer tools that keep the documentation in step with the code, and
the formatting and lint setup.
They are shipped with the distribution but not installed.

## The workflow

```sh
perl Makefile.PL && make
make docs          # after changing an example program or a scenario
make docs-check    # fails when anything is out of date; part of `make release`
```

`make docs` runs `tools/update-docs`, which

1. copies every program shown in the POD into its code block: a code
   block marked with `=for code-from FILE` is replaced by the file
   (without its `#!` line), so the POD always shows the shipped code;
2. checks that every image the POD shows is a screenshot
   (`<img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/TAG/screenshots/NAME.svg">`
   in a `=begin html` block), that every screenshot is defined in
   `screenshots/screenshots.kdl`, and that every defined screenshot is
   shown somewhere;
3. points the URL of every screenshot to the tag `vVERSION` of the
   current `$VERSION`: MetaCPAN shows images in the POD only with
   absolute URLs, and so each release shows its own screenshots once its
   tag is pushed;
4. takes every screenshot again and writes `screenshots/NAME.svg` when it
   changed;

and then regenerates the Markdown pages (`make readme`):
`tools/pod2markdown` writes `README.md` from `lib/Term/Fabulous.pm` and
`docs/NAME.md` from every other `lib/NAME.pm` and `lib/NAME.pod`. The
pages link to each other, show the screenshots of the `master` branch
and fence every code block with the language of the last
`=for highlighter language=NAME` paragraph before it (`perl` by
default). See `perldoc tools/pod2markdown`.

`make docs-check` does the same without writing anything and lists what
is out of date.

## How a screenshot is taken

`screenshots/screenshots.kdl` describes each screenshot: the program,
the terminal size and the input (keys, text, mouse) to give it first.
The syntax is documented in `tools/lib/Term/Fabulous/Screenshot/Scenario.pm`.

The program runs as its own process in a new pseudo terminal, with
`Term::Fabulous::Screenshot::Harness` loaded first. Nothing in the
program changes: Term::Fabulous opens the pseudo terminal with
termbox2 as it would a real one. The harness

- replaces the clock (`time`, `localtime`, `Time::HiRes`) with a virtual
  one that starts at a fixed time and advances only as the event loop
  needs, so timers, animations and displayed times are the same on every
  run and the screenshot of ten seconds of animation takes a fraction of
  a second;
- writes the scenario's input into the terminal as an xterm would send it,
  and waits until the program has received it;
- reads what the terminal shows: the cells from termbox2's front
  buffer and the sixel pictures of the program's last frame.

The runner itself answers the cursor position query (`ESC [ 6 n`) that
inline mode (`inline => ROWS`) sends when it starts, as a terminal
would. It also plays a terminal that shows sixel graphics in cells of
10 x 20 pixels: it answers the device attributes query (`ESC [ c`)
with sixel support and the cell size query (`ESC [ 16 t`), so
`Term::Fabulous::Widget::Sixel` shows its pictures. A scenario's `shell` lines stand for what a shell printed before
the program started: the cursor starts below them, and the screenshot
shows them above the program's inline region, so an inline program
looks as it does in a real terminal.

A program that prints a report and ends (`Term::Fabulous::Static`) is
captured from its colored output instead.

The environment is fixed (`TERM=xterm-256color`, `LC_ALL=C.UTF-8`,
`TZ=UTC`, a fixed hash seed), so the same code always gives the same
image, byte for byte. Child processes a program starts run in real time
while the virtual clock waits for them.

The cells are then drawn as an SVG image in a window frame. Box drawing
and block characters are drawn as shapes, like terminals do, so borders
join without gaps and half-block pixels are square; text is placed cell
by cell, so the columns line up with any monospace font. Sixel pictures
are drawn over the cells they cover, stretched to them, in SVG as
embedded PNG images and in PNG output as well. The SVG uses the
viewer's fonts and needs no other files, which is what MetaCPAN and
GitHub require of images in documentation.

## Screenshots of any program

`tools/screenshot` takes one screenshot of any Term::Fabulous program,
as SVG or PNG:

```sh
perl -Mblib tools/screenshot --output form.svg examples/form.pl
perl -Mblib tools/screenshot --size 100x30 --steps 'type "Ada"; key "Tab"' \
    --output form.png examples/form.pl
perl -Mblib tools/screenshot --size 80x7 --shell '$ perl inline-prompt.pl' \
    --output prompt.png examples/cookbook/inline-prompt.pl
perl -Mblib tools/screenshot --help
```

PNG output needs Imager with PNG and FreeType support and fontconfig
(`fc-match`, `fc-list`) to find fonts. Characters the main monospace font
lacks are drawn with any installed font that has them; when none has
one, the tool stops and names the character instead of drawing a gap.
Emoji need a monochrome emoji font, because Imager cannot draw color
fonts.

## The example pictures

Three tools draw the pictures in `examples/images/`; all need Imager
with PNG support.

`tools/rainbow-circle` draws `rainbow_circle.png`, the picture of
`examples/widgets/image.pl`, the embedded logo of
`examples/cookbook/embedded-logo.pl` and the tests of
`Term::Fabulous::Widget::Image`: six concentric rainbow bands that
blend into each other, with a hard outer edge.

`tools/translucent-circles` draws `translucent_circles.png`, the
picture of `examples/cookbook/picture-viewer.pl`: three overlapping
translucent circles, red, green and blue, whose colors mix where they
overlap.

`tools/mandelbrot` draws `mandelbrot.png`, the picture of
`examples/widgets/sixel.pl` and `examples/cookbook/sixel-viewer.pl`: a
480x320 detail of the Mandelbrot set with smooth color bands and fine
detail, which shows what sixel graphics can do that half blocks cannot.
It takes some seconds.

```sh
perl tools/rainbow-circle                        # rewrites examples/images/rainbow_circle.png
perl tools/translucent-circles                   # rewrites examples/images/translucent_circles.png
perl tools/mandelbrot                            # rewrites examples/images/mandelbrot.png
perl tools/rainbow-circle --output circle.png
```

## The modules

All under `tools/lib/Term/Fabulous/Screenshot/`:

| Module | Purpose |
|---|---|
| `Scenario` | parses `screenshots.kdl` |
| `Input` | key names, text and mouse actions as terminal bytes |
| `Runner` | runs a program in a pseudo terminal, answers its cursor position, device attributes and cell size queries and returns its screen |
| `Harness`, `Clock`, `VirtualLoop` | run inside the program: input, virtual time, capture |
| `Screen` | the captured cells and sixel pictures |
| `Scene`, `BoxDrawing`, `Theme` | what the image shows, independent of the format |
| `Render::SVG`, `Render::PNG` | draw a scene |
| `PodSync` | the code blocks marked with `=for code-from` and the screenshot URLs |

## Formatting and linting

`.perltidyrc` and `.perlcriticrc` in the root of the distribution hold
the formatting and the lint rules. Run perltidy through `tools/tidy`:

```sh
perl tools/tidy lib/Term/Fabulous/Widget/Button.pm   # rewrites the file if it changes
perl tools/tidy --check $(git ls-files '*.pm' '*.pl' '*.t')
perlcritic lib t examples tools
```

`tools/tidy` runs perltidy with `.perltidyrc` and then puts the opening
brace of a class or role whose attributes span several lines back on a
line of its own, which perltidy alone joins onto the last attribute
line. With `--check` it writes nothing, lists the files that are not
tidy and exits with status 1. It also hides `ADJUST :params (` from
perltidy, which would read it as a label before a call and indent the
rest of the class one level deeper, by showing it a method with a
signature instead.
