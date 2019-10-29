# NAME

Term::Clui.pm - Perl module offering a Command-Line User Interface

# SYNOPSIS

```perl
use Term::Clui;
$chosen = choose("A Title", @a_list);  # single choice
@chosen = choose("A Title", @a_list);  # multiple choice
# multi-line question-texts are possible...
$x = choose("Which ?\n(Mouse, or Arrow-keys and Return)", @w);
$x = choose("Which ?\n".help_text(), @w);

if (confirm($text)) { do_something(); };

$answer = ask($question);
$answer = ask($question,$suggestion);
$password = ask_password("Enter password:");
$filename = ask_filename("Which file ?");  # with Tab-completion

$newtext = edit($title, $oldtext);
edit($filename);

view($title, $text)  # if $title is not a filename
view($textfile)  # if $textfile _is_ a filename

edit(choose("Edit which file ?", grep(-T, readdir D)));
```

# DESCRIPTION

Term::Clui
offers a high-level user interface to give the user of
command-line applications a consistent "look and feel".
Its metaphor for the computer is as a human-like conversation-partner,
and as each question/response is completed it is summarised onto one line,
and remains on screen, so that the history of the session gradually
accumulates on the screen and is available for review, or for cut/paste.
This user interface can therefore be intermixed with
standard applications which write to STDOUT or STDERR,
such as _make_, _pgp_, _rcs_ etc.

For the user, _choose()_ uses either
(since 1.50) the mouse;
or arrow keys (or hjkl) and Return;
also **q** to quit, and SpaceBar or Button3 to highlight multiple choices.
_confirm()_ expects y, Y, n or N.
In general, ctrl-L redraws the (currently active bit of the) screen.
_edit()_ and _view()_ use the default EDITOR and PAGER if possible.  

It's fast, simple, and has few external dependencies.
It doesn't use _curses_ (which is a whole-of-screen interface);
it uses a small subset of vt100 sequences (up down left right normal
and reverse) which are very portable,
and also (since 1.50) the _SET\_ANY\_EVENT\_MOUSE_ and _kmous_ (terminfo)
sequences,
which are supported by all _xterm_, _rxvt_, _konsole_, _screen_,
_linux_, _gnome_ and _putty_ terminals.

There is an associated file selector, Term::Clui::FileSelect

Since version 1.60, a speaking interface is provided
for the visually-impaired user;
it employs _eflite_ or _espeak_.
Speech is turned on if the _CLUI\_SPEAK_ environment variable
is set to any non-empty string.
Since version 1.62, if _speakup_ is running,
it is silenced while Term::Clui runs, and then restored.
Because Term::Clui's metaphor for the computer
is a human-like conversation-partner, this works very naturally.
The application needs no modification.

There is an equivalent Python3 module,
with (as far as possible) the same calling interface, at
http://cpansearch.perl.org/src/PJB/Term-Clui-1.71/py/TermClui.py

This is Term::Clui.pm version 1.71

# WINDOW-SIZE

Term::Clui attempts to handle the WINCH signal.
If the window size is changed,
then as soon as the user enters the next keystroke (such as ctrl-L)
the current question/response will be redisplayed to fit the new size.

The first line of the question, the one which will remain on-screen, is
not re-formatted, but is left to be dealt with by the width of the window.
Subsequent lines are split into blank-separated words which are
filled into the available width; lines beginning with white-space
are treated as the beginning of a new indented paragraph,
individual words which will not fit onto one line are truncated,
and successive blank lines are collapsed into one.
If the question will not fit within the available rows, it is truncated.

If the available choice items in a _choose()_ overflow the screen,
the user is asked to enter "clue" letters,
and as soon as the items matching them will fit onto the screen
they are displayed as a choice.

# SUBROUTINES

- _ask_( $question );  OR _ask_( $question, $default );

    Asks the user the question and returns a string answer,
    with no newline character at the end.
    If the optional second argument is present,
    it is offered to the user as a default.
    If the _$question_ is multi-line,
    the entry-field is at the top to the right of the first line,
    and the subsequent lines are formatted within the
    screen width and displayed beneath, as with _choose_.

    For the user, left and right arrow keys move backward and forward
    through the string, delete and backspace erase the previous character,
    ctrl-A moves to the beginning, ctrl-E to the end,
    and ctrl-D or ctrl-X clear the current string.

- _ask\_password_( $question );

    Does the same with no echo, as used for password entry.

- _ask\_filename_( $question );

    Uses _Term::ReadLine::Gnu_ to provide filename-completion with
    the _Tab_ key, but also displays multi-line questions in the
    same way as _ask_ and _choose_ do.
    This function was introduced in version 1.65.

- _choose_( $question, @list );

    Displays the question, and formats the list items onto the lines beneath it.

    If _choose_ is called in a scalar context,
    the user can choose an item using arrow keys (or hjkl) and Return,
    or cancel the choice with a "q".
    _choose_ then returns the chosen item,
    or _undefined_ if the choice was cancelled.

    If _choose_ is called in an array context,
    the user can also mark an item with the SpaceBar.
    _choose_ then returns the list of marked items,
    (including the item highlit when Return was pressed),
    or an empty array if the choice was cancelled.

    A DBM database is maintained of the question and its chosen response.
    The next time the user is offered a choice with the same question,
    if that response is still in the list it is highlighted
    as the default; otherwise the first item is highlighted.
    Different parts of the code, or different applications using _Term::Clui.pm_
    can therefore exchange defaults simply by using the same question words,
    such as "Which printer ?".
    Multiple choices are not remembered, as the danger exists
    that the user might fail to notice some of the highlit items
    (for example, all the items might not fit onto one screen).

    The database _~/.clui\_dir/choices_ or _$ENV{CLUI\_DIR}/choices_
    is available to be read or written if lower-level manipulation is needed,
    and the _EXPORT\_OK_ routines _get\_default_($question) and
    _set\_default_($question, $choice) should be used for this purpose,
    as they handle DBM's problem with concurrent accesses.
    The whole default database mechanism can be disabled by
    _CLUI\_DIR=OFF_ if you really want to :-(

    If the items won't fit on the screen, the user is asked to enter
    a substring as a clue. As soon as the matching items will fit,
    they are displayed to be chosen as normal. If the user pressed "q"
    at this choice, they are asked if they wish to change their substring
    clue; if they reply "n" to this, choose quits and returns _undefined_.

    If the $question is multi-line,
    The first line is put at the top as usual with the choices
    arranged beneath it; the subsequent lines are formatted within the
    screen width and displayed at the bottom.
    After the choice is made all but the first line is erased,
    and the first line remains on-screen with the choice appended after it.
    You should therefore try to arrange multi-line questions
    so that the first line is the question in short form,
    and subsequent lines are explanation and elaboration.

- _confirm_( $question );

    Asks the question, takes "y", "n", "Y" or "N" as a response.
    If the $question is multi-line, after the response, all but the first
    line is erased, and the first line remains on-screen with _Yes_ or _No_
    appended after it; you should therefore try to arrange multi-line
    questions so that the first line is the question in short form,
    and subsequent lines are explanation and elaboration.
    Returns true or false.

- _edit_( $title, $text );  OR  _edit_( $filename );

    Uses the environment variable EDITOR ( or _vi_ :-)
    Uses RCS if directory RCS/ exists

- _sorry_( $message );

    Similar to _warn "Sorry, $message\\n";_

- _inform_( $message );

    Similar to _warn "$message\\n";_ except that it doesn't add the
    newline at the end if there already is one,
    and it uses _/dev/tty_ rather than _STDERR_ if it can.

- _view_( $title, $text );  OR  _view_( $filename );

    If the _$text_ is longer than a screenful, uses the environment
    variable PAGER ( or _less_ ) to display it.
    If it is one or two lines it just omits the title and displays it.
    Otherwise it uses a simple built-in routine which expects either "q"
    or _Return_ from the user; if the user presses _Return_
    the displayed text remains on the screen and the dialogue continues
    after it, if the user presses "q" the text is erased.

    If there is only one argument and it's a filename,
    then the user's PAGER displays it,
    except (since 1.65) if it's a _.doc_ file, when either
    _wvText_, _antiword_ or _catdoc_ is used to extract its contents first.

- _help\_text_( $mode );

    This returns a short help message for the user.
    If _mode_ is "ask" then the text describes the keys the user has available
    when responding to an _&ask_ question;
    If _mode_ is "multi" then the text describes the keys
    and mouse actions the user has available
    when responding to a multiple-choice _&choose_ question;
    otherwise, the text describes the keys
    and mouse actions the user has available
    when responding to a single-choice _&choose_.

# EXPORT\_OK SUBROUTINES

The following routines are not exported by default, but are
exported under the _ALL_ tag, so if you need them you should:

```
import Term::Clui qw(:ALL);
```

- _beep_()

    Beeps.

- _timestamp_()

    Returns a sortable timestamp string in "YYYYMMDD hhmmss" form.

- _get\_default_( $question )

    Consults the database _~/.clui\_dir/choices_ or
    _$ENV{CLUI\_DIR}/choices_ and returns the choice that
    the user made the last time this question was asked.
    This is better than opening the database directly
    as it handles DBM's problem with concurrent accesses.

- _set\_default_( $question, $new\_default )

    Opens the database _~/.clui\_dir/choices_ or
    _$ENV{CLUI\_DIR}/choices_ and sets the default response which will
    be offered to the user made the next time this question is asked.
    This is better than opening the database directly
    as it handles DBM's problem with concurrent accesses.

# DEPENDENCIES

It requires Exporter, which is core Perl.
It uses Term::ReadKey if it's available;
and uses Term::Size if it's available;
if not, it tries _tput_ before guessing 80x24.

# ENVIRONMENT

The environment variable _CLUI\_DIR_ can be used (by programmer or user)
to override _~/.clui\_dir_ as the directory in which _choose()_ keeps
its database of previous choices.
The whole default database mechanism can be disabled by
_CLUI\_DIR = OFF_ if you really want to :-(

If either the LANG or the LC\_TYPE environment variables
contain the string _utf8_ or _utf-8_ (case insensitive),
then _choose()_ and _inform()_ open _/dev/tty_ with a _utf8_ encoding.

If the environment variable _CLUI\_SPEAK_ is set
or if _EDITOR_ is set to _emacspeak_,
and if _flite_ is installed,
then _Term::Clui_ will use _flite_
to speak its questions and choices out loud.

If the environment variable _CLUI\_MOUSE_ is set to _OFF_
then _choose()_ will not interpret mouse-clicks as making a choice.
The advantage of this is that the mouse can then be used
to highlight and paste text from this window as usual.

_Term::Clui_ also consults the environment variables
HOME, LOGDIR, EDITOR and PAGER, if they are set.

# EXAMPLES

These scripts using Term::Clui and Term::Clui::FileSelect are to
be found in the _examples_ subdirectory of the build directory.

- _linux\_admin_

    I use this script a lot at work, for routine system administration of
    linux boxes, particularly Fedora and Debian.  It includes crontab,
    chkconfig, update-rc.d, visudo, vipw, starting and stopping daemons,
    reconfiguring squid samba or apache, editing sysconfig or running
    any of the system-config-\* utilities, and much else.

- _audio\_stuff_

    This script offers an arrow-key-and-return interface integrating
    aplaymidi, cdrecord, cdda2wav, icedax, lame, mkisofs, muscript,
    normalize, normalize-audio,
    mpg123, sndfile-play, timidity, wodim and so on,
    allowing audio files to be ripped,
    burned, played, or converted between Muscript, MIDI, WAV and MP3 formats.

- _login\_shell_

    This script offers the naive user arrow-key-and-return access
    to a text-based browser, a mail client, a news client, ssh and ftp
    and various other stuff.

- _test\_script_

    This is the test script, as used during development.

- _choose_

    This is a script which wraps Term::Clui::choose for use at the shell-script
    level. It can either choose between command-line arguments,
    or, with the **-f** (filter) option, between lines of STDIN, like grep.
    A **-m** (multiple) option allows multiple-choice.
    This can be a very useful script, and you may want to copy it into
    _/usr/local/bin/_ or elsewhere in your PATH.

# AUTHOR

Original author:

Peter J Billam www.pjb.com.au/comp/contact.html

Current maintainer:

Graham Ollis

Contributors:

Peter Scott

# CREDITS

Based on some old perl 4 libraries, _ask.pl_, _choose.pl_,
_confirm.pl_, _edit.pl_, _sorry.pl_, _inform.pl_ and _view.pl_,
which were in turn based on some even older curses-based programs in _C_.

# SEE ALSO

```
Term::Clui::FileSelect
Term::ReadKey
Term::Size
http://www.pjb.com.au/
http://invisible-island.net/xterm/ctlseqs/ctlseqs.html
http://search.cpan.org/~pjb
festival(1)
eflite(1)
espeak(1)
espeakup(1)
edbrowse(1)
emacspeak(1)
perl(1)
```

There is an equivalent Python3 module,
with (as far as possible) the same calling interface, at
https://fastapi.metacpan.org/source/PJB/Term-Clui-1.71/py/TermClui.py
