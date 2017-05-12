# -*- Perl -*-
=head1 NAME

Term::ReadLine::Perl5::readline

=head1 DESCRIPTION

A non-OO package similar to GNU's readline. The preferred OO Package
is L<Term::ReadLine::Perl5>. But that uses this internally.

It could be made better by removing more of the global state and
moving it into the L<Term::ReadLine::Perl5> side.

There is some support for EUC-encoded Japanese text. This should be
rewritten for Perl Unicode though.

Someone please volunteer to rewrite this!

See also L<Term::ReadLine::Perl5::readline-guide>.

=cut
use warnings;
package Term::ReadLine::Perl5::readline;
use File::Glob ':glob';

# no critic
# Version can be below the version given in Term::ReadLine::Perl5
our $VERSION = '1.43';

#
# Separation into my and vars needs more work.
# use strict 'vars';
#
use vars qw(@KeyMap %KeyMap $rl_screen_width $rl_start_default_at_beginning
          $rl_completion_function $rl_basic_word_break_characters
          $rl_completer_word_break_characters $rl_special_prefixes
          $rl_max_numeric_arg $rl_OperateCount
          $rl_completion_suppress_append
          $history_stifled
          $KillBuffer $dumb_term $stdin_not_tty $InsertMode
          $mode $winsz $force_redraw
          $have_getpwent
          $minlength $rl_readline_name
          @winchhooks
          $rl_NoInitFromFile
          $DEBUG;
          );

@ISA     = qw(Exporter);
@EXPORT  = qw($minlength rl_NoInitFromFile rl_bind rl_set
              rl_read_init_file
              rl_basic_commands rl_filename_list
              completion_function);


use File::HomeDir;
use File::Spec;
use Term::ReadKey;

eval "use rlib '.' ";  # rlib is now optional
use Term::ReadLine::Perl5::Common;
use Term::ReadLine::Perl5::Dumb;
use Term::ReadLine::Perl5::History;
use Term::ReadLine::Perl5::Keymap
    qw(KeymapEmacs KeymapVi KeymapVicmd KeymapVipos KeymapVisearch);
use Term::ReadLine::Perl5::TermCap; # For ornaments

my $autoload_broken = 1;        # currently: defined does not work with a-l
my $useioctl = 1;
my $usestty = 1;
my $max_include_depth = 10;     # follow $include's in init files this deep

my $HOME = File::HomeDir->my_home;

BEGIN {                 # Some old systems have ioctl "unsupported"
  *ioctl = sub ($$$) { eval { CORE::ioctl $_[0], $_[1], $_[2] } };
}

$rl_getc = \&rl_getc;
$minlength = 1;
$history_stifled = 0;

&preinit;
&init;

#
# my ($InputLocMsg, $term_OUT, $term_IN);
# my ($winsz_t, $TIOCGWINSZ, $winsz, $rl_margin);
# my ($hook, %var_HorizontalScrollMode, %var_EditingMode, %var_OutputMeta);
# my ($var_HorizontalScrollMode, $var_EditingMode, $var_OutputMeta);
# my (%var_ConvertMeta, $var_ConvertMeta, %var_MarkModifiedLines, $var_MarkModifiedLines);
my $inDOS;
# my (%var_PreferVisibleBell, $var_PreferVisibleBell);
# my (%var_TcshCompleteMode, $var_TcshCompleteMode);
# my (%var_CompleteAddsuffix, $var_CompleteAddsuffix);
# my ($BRKINT, $ECHO, $FIONREAD, $ICANON, $ICRNL, $IGNBRK, $IGNCR, $INLCR,
#     $ISIG, $ISTRIP, $NCCS, $OPOST, $RAW, $TCGETS, $TCOON, $TCSETS, $TCXONC,
#     $TERMIOS_CFLAG, $TERMIOS_IFLAG, $TERMIOS_LFLAG, $TERMIOS_NORMAL_IOFF,
#     $TERMIOS_NORMAL_ION, $TERMIOS_NORMAL_LOFF, $TERMIOS_NORMAL_LON,
#     $TERMIOS_NORMAL_OOFF, $TERMIOS_NORMAL_OON, $TERMIOS_OFLAG,
#     $TERMIOS_READLINE_IOFF, $TERMIOS_READLINE_ION, $TERMIOS_READLINE_LOFF,
#     $TERMIOS_READLINE_LON, $TERMIOS_READLINE_OOFF, $TERMIOS_READLINE_OON,
#     $TERMIOS_VMIN, $TERMIOS_VTIME, $TIOCGETP, $TIOCGWINSZ, $TIOCSETP,
#     $fion, $fionread_t, $mode, $sgttyb_t,
#     $termios, $termios_t, $winsz, $winsz_t);
# my ($line, $initialized);
#
# Global variables added for vi mode (I'm leaving them all commented
# out, like the declarations above, until SelfLoader issues
#     are resolved).

# True when we're in one of the vi modes.
my $Vi_mode;

# Array refs: saves keystrokes for '.' command.  Undefined when we're
#     not doing a '.'-able command.
my $Dot_buf;                # Working buffer
my $Last_vi_command;        # Gets $Dot_buf when a command is parsed

# These hold state for vi 'u' and 'U'.
my($Dot_state, $Vi_undo_state, $Vi_undo_all_state);

# Refs to hashes used for cursor movement
my($Vi_delete_patterns, $Vi_move_patterns,
   $Vi_change_patterns, $Vi_yank_patterns);

# Array ref: holds parameters from the last [fFtT] command, for ';'
#     and ','.
my $Last_findchar;

# Globals for history search commands (/, ?, n, N)
my $Vi_search_re;       # Regular expression (compiled by qr{})
my $Vi_search_reverse;  # True for '?' search, false for '/'

=head1 SUBROUTINES

=cut
# Fix: case-sensitivity of inputrc on/off keywords in
#      `set' commands. readline lib doesn't care about case.
# changed case of keys 'On' and 'Off' to 'on' and 'off'
# &rl_set changed so that it converts the value to
# lower case before hash lookup.
sub preinit
{
    $DEBUG = 0;

    ## Set up the input and output handles

    $term_IN = \*STDIN unless defined $term_IN;
    $term_OUT = \*STDOUT unless defined $term_OUT;
    ## not yet supported... always on.
    $var_HorizontalScrollMode = 1;
    $var_HorizontalScrollMode{'On'} = 1;
    $var_HorizontalScrollMode{'Off'} = 0;

    $var_EditingMode{'emacs'}    = \@emacs_keymap;
    $var_EditingMode{'vi'}       = \@vi_keymap;
    $var_EditingMode{'vicmd'}    = \@vicmd_keymap;
    $var_EditingMode{'vipos'}    = \@vipos_keymap;
    $var_EditingMode{'visearch'} = \@visearch_keymap;

    ## this is an addition. Very nice.
    $var_TcshCompleteMode = 0;
    $var_TcshCompleteMode{'On'} = 1;
    $var_TcshCompleteMode{'Off'} = 0;

    $var_CompleteAddsuffix = 1;
    $var_CompleteAddsuffix{'On'} = 1;
    $var_CompleteAddsuffix{'Off'} = 0;

    $var_DeleteSelection = $var_DeleteSelection{'On'} = 1;
    $var_DeleteSelection{'Off'} = 0;
    *rl_delete_selection = \$var_DeleteSelection; # Alias

    ## not yet supported... always on
    for ('InputMeta', 'OutputMeta') {
        ${"var_$_"} = 1;
        ${"var_$_"}{'Off'} = 0;
        ${"var_$_"}{'On'} = 1;
    }

    ## not yet supported... always off
    for (
	qw(
	BlinkMatchingParen
	ConvertMeta
	EnableKeypad
	PrintCompletionsHorizontally
        CompletionIgnoreCase
        DisableCompletion
        MarkDirectories
        MarkModifiedLines
        MetaFlag
        PreferVisibleBell
        ShowAllIfAmbiguous
        VisibleStats
        )) {
        ${"var_$_"} = 0;
        ${"var_$_"}{'Off'} = 0;
        ${"var_$_"}{'On'} = 1;
    }

    # WINCH hooks
    @winchhooks = ();

    $inDOS = $^O eq 'os2' || defined $ENV{OS2_SHELL} unless defined $inDOS;

    # try to get, don't die if not found.
    eval {require "ioctl.pl"};
    eval {require "sgtty.ph"};

    if ($inDOS and !defined $TIOCGWINSZ) {
	$TIOCGWINSZ=0;
	$TIOCGETP=1;
	$TIOCSETP=2;
	$sgttyb_t="I5 C8";
	$winsz_t="";
	$RAW=0xf002;
	$ECHO=0x0008;
    }
    $TIOCGETP = &TIOCGETP if defined(&TIOCGETP);
    $TIOCSETP = &TIOCSETP if defined(&TIOCSETP);
    $TIOCGWINSZ = &TIOCGWINSZ if defined(&TIOCGWINSZ);
    $FIONREAD = &FIONREAD if defined(&FIONREAD);
    $TCGETS = &TCGETS if defined(&TCGETS);
    $TCSETS = &TCSETS if defined(&TCSETS);
    $TCXONC = &TCXONC if defined(&TCXONC);
    $TIOCGETP   = 0x40067408 if !defined($TIOCGETP);
    $TIOCSETP   = 0x80067409 if !defined($TIOCSETP);
    $TIOCGWINSZ = 0x40087468 if !defined($TIOCGWINSZ);
    $FIONREAD   = 0x4004667f if !defined($FIONREAD);
    $TCGETS     = 0x40245408 if !defined($TCGETS);
    $TCSETS     = 0x80245409 if !defined($TCSETS);
    $TCXONC     = 0x20005406 if !defined($TCXONC);

    ## TTY modes
    $ECHO = &ECHO if defined(&ECHO);
    $RAW = &RAW if defined(&RAW);
    $RAW      = 040 if !defined($RAW);
    $ECHO     = 010 if !defined($ECHO);
    $mode = $RAW; ## could choose CBREAK for testing....

    $IGNBRK     = 1 if !defined($IGNBRK);
    $BRKINT     = 2 if !defined($BRKINT);
    $ISTRIP     = 040 if !defined($ISTRIP);
    $INLCR      = 0100 if !defined($INLCR);
    $IGNCR      = 0200 if !defined($IGNCR);
    $ICRNL      = 0400 if !defined($ICRNL);
    $OPOST      = 1 if !defined($OPOST);
    $ISIG       = 1 if !defined($ISIG);
    $ICANON     = 2 if !defined($ICANON);
    $TCOON      = 1 if !defined($TCOON);
    $TERMIOS_READLINE_ION = $BRKINT;
    $TERMIOS_READLINE_IOFF = $IGNBRK | $ISTRIP | $INLCR | $IGNCR | $ICRNL;
    $TERMIOS_READLINE_OON = 0;
    $TERMIOS_READLINE_OOFF = $OPOST;
    $TERMIOS_READLINE_LON = 0;
    $TERMIOS_READLINE_LOFF = $ISIG | $ICANON | $ECHO;
    $TERMIOS_NORMAL_ION = $BRKINT;
    $TERMIOS_NORMAL_IOFF = $IGNBRK;
    $TERMIOS_NORMAL_OON = $OPOST;
    $TERMIOS_NORMAL_OOFF = 0;
    $TERMIOS_NORMAL_LON = $ISIG | $ICANON | $ECHO;
    $TERMIOS_NORMAL_LOFF = 0;

    $sgttyb_t   = 'C4 S' if !defined($sgttyb_t);
    $winsz_t = "S S S S" if !defined($winsz_t);
    # rows,cols, xpixel, ypixel
    $winsz = pack($winsz_t,0,0,0,0);
    $NCCS = 17;
    $termios_t = "LLLLc" . ("c" x $NCCS);  # true for SunOS 4.1.3, at least...
    $termios = ''; ## just to shut up "perl -w".
    $termios = pack($termios, 0);  # who cares, just make it long enough
    $TERMIOS_IFLAG = 0;
    $TERMIOS_OFLAG = 1;
    ## $TERMIOS_CFLAG = 2;
    $TERMIOS_LFLAG = 3;
    $TERMIOS_VMIN = 5 + 4;
    $TERMIOS_VTIME = 5 + 5;
    $rl_delete_selection = 1;
    $rl_correct_sw = ($inDOS ? 1 : 0);
    $rl_scroll_nextline = 1 unless defined $rl_scroll_nextline;
    $rl_last_pos_can_backspace = ($inDOS ? 0 : 1) # Can backspace when the
      unless defined $rl_last_pos_can_backspace;  # whole line is filled?

    $rl_start_default_at_beginning = 0;
    $rl_vi_replace_default_on_insert = 0;
    $rl_screen_width = 79; ## default

    $rl_completion_function = "rl_filename_list"
        unless defined($rl_completion_function);
    $rl_basic_word_break_characters = "\\\t\n' \"`\@\$><=;|&{(";
    $rl_completer_word_break_characters = $rl_basic_word_break_characters;
    $rl_special_prefixes = '';
    ($rl_readline_name = $0) =~ s#.*[/\\]## if !defined($rl_readline_name);

    $rl_max_numeric_arg = 200 if !defined($rl_max_numeric_arg);
    $rl_OperateCount = 0 if !defined($rl_OperateCount);
    $rl_completion_suppress_append = 0
	if !defined($rl_completion_suppress_append);

    no warnings 'once';
    $rl_term_set = \@Term::ReadLine::TermCap::rl_term_set;
    @$rl_term_set or $rl_term_set = ["","","",""];

    $InsertMode=1;
    $KillBuffer='';
    $line='';
    $D = 0;
    $InputLocMsg = ' [initialization]';

    KeymapEmacs(\&InitKeymap, \@emacs_keymap, $inDOS);
    *KeyMap = \@emacs_keymap;
    my @add_bindings = ();
    foreach ('-', '0' .. '9') {
	push(@add_bindings, "M-$_", 'DigitArgument');
    }
    foreach ("A" .. "Z") {
	next if
         # defined($KeyMap[27]) && defined (%{"$KeyMap{name}_27"}) &&
        defined $ {"$KeyMap{name}_27"}[ord $_];
      push(@add_bindings, "M-$_", 'DoLowercaseVersion');
    }
    if ($inDOS) {
        # Default translation of Alt-char
        $ {"$KeyMap{name}_0"}{'Esc'} = *{"$KeyMap{name}_27"};
        $ {"$KeyMap{name}_0"}{'default'} = 'F_DoEscVersion';
    }
    &rl_bind(@add_bindings);

    local(*KeyMap);

    # Vi input mode.
    KeymapVi(\&InitKeymap, \@vi_keymap);

    # Vi command mode.
    KeymapVicmd(\&InitKeymap, \@vicmd_keymap);

    # Vi positioning commands (suffixed to vi commands like 'd').
    KeymapVipos(\&InitKeymap, \@vipos_keymap, $inDOS);

    # Vi search string input mode for '/' and '?'.
    KeymapVisearch(\&InitKeymap, \@visearch_keymap);

    # These constant hashes hold the arguments to &forward_scan() or
    #     &backward_scan() for vi positioning commands, which all
    #     behave a little differently for delete, move, change, and yank.
    #
    # Note: I originally coded these as qr{}, but changed them to q{} for
    #       compatibility with older perls at the expense of some performance.
    #
    # Note: Some of the more obscure key combinations behave slightly
    #       differently in different vi implementation.  This module matches
    #       the behavior of /usr/ucb/vi, which is different from the
    #       behavior of vim, nvi, and the ksh command line.  One example is
    #       the command '2de', when applied to the string ('^' represents the
    #       cursor, not a character of the string):
    #
    #           ^5.6   7...88888888
    #
    #       With /usr/ucb/vi and with this module, the result is
    #
    #           ^...88888888
    #
    #       but with the other three vi implementations, the result is
    #
    #           ^   7...88888888

    $Vi_delete_patterns = {
        ord('w')  =>  q{(?:\w+|[^\w\s]+|)\s*},
        ord('W')  =>  q{\S*\s*},
        ord('b')  =>  q{\w+\s*|[^\w\s]+\s*|^\s+},
        ord('B')  =>  q{\S+\s*|^\s+},
        ord('e')  =>  q{.\s*\w+|.\s*[^\w\s]+|.\s*$},
        ord('E')  =>  q{.\s*\S+|.\s*$},
    };

    $Vi_move_patterns = {
        ord('w')  =>  q{(?:\w+|[^\w\s]+|)\s*},
        ord('W')  =>  q{\S*\s*},
        ord('b')  =>  q{\w+\s*|[^\w\s]+\s*|^\s+},
        ord('B')  =>  q{\S+\s*|^\s+},
        ord('e')  =>  q{.\s*\w*(?=\w)|.\s*[^\w\s]*(?=[^\w\s])|.?\s*(?=\s$)},
        ord('E')  =>  q{.\s*\S*(?=\S)|.?\s*(?=\s$)},
    };

    $Vi_change_patterns = {
        ord('w')  =>  q{\w+|[^\w\s]+|\s},
        ord('W')  =>  q{\S+|\s},
        ord('b')  =>  q{\w+\s*|[^\w\s]+\s*|^\s+},
        ord('B')  =>  q{\S+\s*|^\s+},
        ord('e')  =>  q{.\s*\w+|.\s*[^\w\s]+|.\s*$},
        ord('E')  =>  q{.\s*\S+|.\s*$},
    };

    $Vi_yank_patterns = {
        ord('w')  =>  q{(?:\w+|[^\w\s]+|)\s*},
        ord('W')  =>  q{\S*\s*},
        ord('b')  =>  q{\w+\s*|[^\w\s]+\s*|^\s+},
        ord('B')  =>  q{\S+\s*|^\s+},
        ord('e')  =>  q{.\s*\w*(?=\w)|.\s*[^\w\s]*(?=[^\w\s])|.?\s*(?=\s$)},
        ord('E')  =>  q{.\s*\S*(?=\S)|.?\s*(?=\s$)},
    };

    *KeyMap = $var_EditingMode = $var_EditingMode{'emacs'};
    1; # Returning a glob causes a bug in db5.001m
}

# FIXME: something in here causes terminal attributes like bold and
# underline to work.
sub rl_term_set()
{
    $rl_term_set = \@Term::ReadLine::TermCap::rl_term_set;
}

sub init()
{
    if ($ENV{'TERM'} and ($ENV{'TERM'} eq 'emacs' || $ENV{'TERM'} eq 'dumb')) {
        $dumb_term = 1;
    } elsif (! -c $term_IN && $term_IN eq \*STDIN) { # Believe if it is given
        $stdin_not_tty = 1;
    } else {
        &get_window_size;
        &F_ReReadInitFile if !defined($rl_NoInitFromFile);
        $InputLocMsg = '';
        *KeyMap = $var_EditingMode;
    }

    $initialized = 1;
}


=head2 InitKeyMap

C<InitKeymap(*keymap, 'default', 'name', bindings...)>

=cut

sub InitKeymap
{
    local(*KeyMap) = shift(@_);
    my $default = shift(@_);
    my $name = $KeyMap{'name'} = shift(@_);

    # 'default' is now optional - if '', &do_command() defaults it to
    #     'F_Ding'.  Meta-maps now don't set a default - this lets
    #     us detect multiple '\*' default declarations.              JP
    if ($default ne '') {
        my $func = $KeyMap{'default'} = "F_$default";
        ### Temporarily disabled
        die qq/Bad default function [$func] for keymap "$name"/
          if !$autoload_broken and !defined(&$func);
    }

    &rl_bind if @_ > 0; ## The rest of @_ gets passed silently.
}

sub filler_Pending ($) {
  my $keys = shift;
  sub {
    my $c = shift;
    push @Pending, map chr, @$keys;
    return if not @$keys or $c == 1 or not defined(my $in = &getc_with_pending);
    # provide the numeric argument
    local(*KeyMap) = $var_EditingMode;
    $doingNumArg = 1;           # Allow NumArg inside NumArg
    &do_command(*KeyMap, $c, ord $in);
    return;
  }
}


=head2 _unescape

    _unescape($string) -> List of keys

This internal function that takes I<$string> possibly containing
escape sequences, and converts to a series of octal keys.

It has special rules for dealing with readline-specific escape-sequence
commands.

New-style key bindings are enclosed in double-quotes.
Characters are taken verbatim except the special cases:

    \C-x    Control x (for any x)
    \M-x    Meta x (for any x)
    \e      Escape
    \*      Set the keymap default   (JP: added this)
            (must be the last character of the sequence)
    \x      x  (unless it fits the above pattern)

Special case "\C-\M-x", should be treated like "\M-\C-x".

=cut

my @ESCAPE_REGEXPS = (
    # Ctrl-meta <x>
    [ qr/^\\C-\\M-(.)/, sub { ord("\e"), ctrl(ord(shift)) } ],
    # Meta <e>
    [ qr/^\\(M-|e)/, sub { ord("\e") } ],
    # Ctrl <x>
    [ qr/^\\C-(.)/, sub { ctrl(ord(shift)) } ],
    # hex value
    [ qr/^\\x([0-9a-fA-F]{2})/, sub { hex(shift) } ],
    # octal value
    [ qr/^\\([0-7]{3})/, sub { oct(shift) } ],
    # default
    [ qr/^\\\*$/, sub { 'default'; } ],
    # EOT (Ctrl-D)
    [ qr/^\\d/, sub { 4 } ],
    # Backspace
    [ qr/\\b/, sub { 0x7f } ],
    # Escape Sequence
    [ qr/\\(.)/,
      sub {
          my $chr = shift;
          ord(($chr =~ /^[afnrtv]$/) ? eval(qq("\\$chr")) : $chr);
      } ],
    );

sub _unescape ($) {
  my($key, @keys) = shift;

  CHAR: while (length($key) > 0) {
    foreach my $command (@ESCAPE_REGEXPS) {
      my $regex = $command->[0];
      if ($key =~ s/^$regex//) {
        push @keys, $command->[1]->($1);
        next CHAR;
      }
    }
    push @keys, ord($key);
    substr($key,0,1) = '';
  }
  @keys
}

sub RL_func ($) {
  my $name_or_macro = shift;
  if ($name_or_macro =~ /^"((?:\\.|[^\\\"])*)"|^'((?:\\.|[^\\\'])*)'/s) {
    filler_Pending [_unescape "$+"];
  } else {
    "F_$name_or_macro";
  }
}

=head2 bind_parsed_keyseq

B<bind_parsed_keyseq>(I<$function1>, I<@sequence1>, ...)

Actually inserts the binding for I<@sequence> to I<$function> into the
current map. I<@sequence> is an array of character ordinals.

If C<sequence> is more than one element long, all but the last will
cause meta maps to be created.

I<$Function> will have an implicit I<F_> prepended to it.

0 is returned if there is no error.

=cut

sub bind_parsed_keyseq
{
    my $bad = 0;
    while (@_) {
	my $func = shift;
	my ($key, @keys) = @{shift()};
	$key += 0;
	local(*KeyMap) = *KeyMap;
	my $map;
	while (@keys) {
	    if (defined($KeyMap[$key]) && ($KeyMap[$key] ne 'F_PrefixMeta')) {
		warn "Warning$InputLocMsg: ".
		    "Re-binding char #$key from [$KeyMap[$key]] to meta for [@keys] => $func.\n" if $^W;
	    }
	    $KeyMap[$key] = 'F_PrefixMeta';
	    $map = "$KeyMap{'name'}_$key";
	    InitKeymap(*$map, '', $map) if !(%$map);
	    *KeyMap = *$map;
	    $key = shift @keys;
	    #&bind_parsed_keyseq($func, \@keys);
	}

	my $name = $KeyMap{'name'};
	if ($key eq 'default') {      # JP: added
	    warn "Warning$InputLocMsg: ".
		" changing default action to $func in $name key map\n"
		if $^W && defined $KeyMap{'default'};

	    $KeyMap{'default'} = RL_func $func;
	}
	else {
	    if (defined($KeyMap[$key]) && $KeyMap[$key] eq 'F_PrefixMeta'
		&& $func ne 'PrefixMeta')
	    {
		warn "Warning$InputLocMsg: ".
		    " Re-binding char #$key to non-meta ($func) in $name key map\n"
		    if $^W;
	    }
	    $KeyMap[$key] = RL_func $func;
	}
    }
    return $bad;
}

=head2 GNU ReadLine-ish Routines

Many of these aren't the the name GNU readline uses, nor do they
correspond to GNU ReadLine functions. Sigh.

=head3 rl_bind_keyseq

B<rl_bind_keyseq>(I<$keyspec>, I<$function>)

Bind the key sequence represented by the string I<keyseq> to the
function function, beginning in the current keymap. This makes new
keymaps as necessary. The return value is non-zero if keyseq is
invalid.  I<$keyspec> should be the name of key sequence in one of two
forms:

Old (GNU readline documented) form:

     M-x        to indicate Meta-x
     C-x        to indicate Ctrl-x
     M-C-x      to indicate Meta-Ctrl-x
     x          simple char x

where I<x> above can be a single character, or the special:

     special    means
     --------   -----
     space      space   ( )
     spc        space   ( )
     tab        tab     (\t)
     del        delete  (0x7f)
     rubout     delete  (0x7f)
     newline    newline (\n)
     lfd        newline (\n)
     ret        return  (\r)
     return     return  (\r)
     escape     escape  (\e)
     esc        escape  (\e)

New form:
  "chars"   (note the required double-quotes)

where each char in the list represents a character in the sequence, except
for the special sequences:

          \\C-x         Ctrl-x
          \\M-x         Meta-x
          \\M-C-x       Meta-Ctrl-x
          \\e           escape.
          \\x           x (if not one of the above)


C<$function> should be in the form C<BeginningOfLine> or C<beginning-of-line>.

It is an error for the function to not be known....

As an example, the following lines in .inputrc will bind one's xterm
arrow keys:

    "\e[[A": previous-history
    "\e[[B": next-history
    "\e[[C": forward-char
    "\e[[D": backward-char

=cut

sub rl_bind_keyseq($$)
{
    my ($key, $func) = @_;
    $func = canonic_command_function($func);

    ## print "sequence [$key] func [$func]\n"; ##DEBUG

    my @keys = ();
    ## See if it's a new-style binding.
    if ($key =~ m/"((?:\\.|[^\\])*)"/s) {
	@keys = _unescape "$1";
    } else {
	## old-style binding... only one key (or Meta+key)
	my ($isctrl, $orig) = (0, $key);
	$isctrl = $key =~ s/\b(C|Control|CTRL)-//i;
	push(@keys, ord("\e")) if $key =~ s/\b(M|Meta)-//i; ## is meta?
	## Isolate key part. This matches GNU's implementation.
	## If the key is '-', be careful not to delete it!
	$key =~ s/.*-(.)/$1/;
	if    ($key =~ /^(space|spc)$/i)   { $key = ' ';    }
	elsif ($key =~ /^(rubout|del)$/i)  { $key = "\x7f"; }
	elsif ($key =~ /^tab$/i)           { $key = "\t";   }
	elsif ($key =~ /^(return|ret)$/i)  { $key = "\r";   }
	elsif ($key =~ /^(newline|lfd)$/i) { $key = "\n";   }
	elsif ($key =~ /^(escape|esc)$/i)  { $key = "\e";   }
	elsif (length($key) > 1) {
	    warn "Warning$InputLocMsg: strange binding [$orig]\n" if $^W;
	}
	$key = ord($key);
	$key = ctrl($key) if $isctrl;
	push(@keys, $key);
    }

    # Now do the mapping of the sequence represented in @keys
    printf "rl_bind(%s, %s)\n", $func, join(', ', @keys) if $DEBUG;
    &bind_parsed_keyseq($func, \@keys);
}

=head3 rl_bind

Accepts an array as pairs ($keyspec, $function, [$keyspec, $function]...).
and maps the associated bindings to the current KeyMap.
=cut

sub rl_bind
{
    while (defined($key = shift(@_)) && defined($func = shift(@_)))
    {
	rl_bind_keyseq($key, $func);
    }
}

=head3 rl_set

C<rl_set($var_name, $value_string)>

Sets the named variable as per the given value, if both are appropriate.
Allows the user of the package to set such things as HorizontalScrollMode
and EditingMode.  Value_string may be of the form

      HorizontalScrollMode
      horizontal-scroll-mode

Also called during the parsing of F<~/.inputrc> for "set var value" lines.

The previous value is returned, or undef on error.

Consider the following example for how to add additional variables
accessible via rl_set (and hence via F<~/.inputrc>).

Want:

We want an external variable called "FooTime" (or "foo-time").
It may have values "January", "Monday", or "Noon".
Internally, we'll want those values to translate to 1, 2, and 12.

How:

Have an internal variable $var_FooTime that will represent the current
internal value, and initialize it to the default value.
Make an array %var_FooTime whose keys and values are are the external
(January, Monday, Noon) and internal (1, 2, 12) values:

    $var_FooTime = $var_FooTime{'January'} =  1; #default
                   $var_FooTime{'Monday'}  =  2;
                   $var_FooTime{'Noon'}    = 12;

=cut

sub rl_set
{
    local($var, $val) = @_;

    # &preinit's keys are all Capitalized
    $val = ucfirst lc $val if $val =~ /^(on|off)$/i;

    $var = 'CompleteAddsuffix' if $var eq 'visible-stats';

    ## if the variable is in the form "some-name", change to "SomeName"
    local($_) = "\u$var";
    local($return) = undef;
    s/-(.)/\u$1/g;

    # Skip unknown variables:
    return unless defined $ {'Term::ReadLine::Perl5::readline::'}{"var_$_"};
    local(*V);    # avoid <Undefined value assign to typeglob> warning
    { local $^W; *V = $ {'Term::ReadLine::Perl5::readline::'}{"var_$_"}; }
    if (!defined($V)) {                 # XXX Duplicate check?
        warn("Warning$InputLocMsg:\n".
             "  Invalid variable `$var'\n") if $^W;
    } elsif (!defined($V{$val})) {
        local(@selections) = keys(%V);
        warn("Warning$InputLocMsg:\n".
             "  Invalid value `$val' for variable `$var'.\n".
             "  Choose from [@selections].\n") if $^W;
    } else {
        $return = $V;
        $V = $V{$val}; ## make the setting
    }
    $return;
}

=head3 rl_filename_list

  rl_filename_list($pattern) => list of files

Returns a list of completions that begin with the string I<$pattern>.
Can be used to pass to I<completion_matches()>.

This function corresponds to the L<Term::ReadLine::GNU> function
I<rl_filename_list)>. But that doesn't handle tilde expansion while
this does. Also, directories returned will have the '/' suffix
appended as is the case returned by GNU Readline, but not
I<Term::ReadLine::GNU>. Adding the '/' suffix is useful in completion
because it forces the next completion to complete inside that
directory.

GNU Readline also will complete partial I<~> names; for example
I<~roo> maybe expanded to C</root> for the root user. When
getpwent/setpwent is available we provide that.

The user of this package can set I<$rl_completion_function> to
'rl_filename_list' to restore the default of filename matching if
they'd changed it earlier, either directly or via &rl_basic_commands.

=cut

sub rl_filename_list
{
    my $pattern = $_[0];
    if ($pattern =~ m{^~[^/]*$}) {
	if ($have_getpwent and length($pattern) > 1) {
	    map { -d $_ ? $_ . '/' : $_ }
	    tilde_complete(substr($pattern, 1));
	} else {
	    map { -d $_ ? $_ . '/' : $_ } bsd_glob($pattern);
	}
    } else {
	map { -d $_ ? $_ . '/' : $_ } bsd_glob($pattern . '*');
    }
}

=head3 rl_filename_list_deprecated

C<rl_filename_list_deprecated($pattern)>

This was the I<Term::ReadLine::Perl5> function before version 1.30,
and the current I<Term::ReadLine::Perl> function.

For reasons that are a mystery to me (rocky), there seemed to be a the
need to classify the result adding a suffix for executable (*),
pipe/socket (=), and symbolic link (@), and directory (/). Of these,
the only useful one is directory since that will cause a further
completion to continue.

=cut
sub rl_filename_list_deprecated
{
    my $pattern = $_[0];
    my @files = (<$pattern*>);
    if ($var_CompleteAddsuffix) {
        foreach (@files) {
            if (-l $_) {
                $_ .= '@';
            } elsif (-d _) {
                $_ .= '/';
            } elsif (-x _) {
                $_ .= '*';
            } elsif (-S _ || -p _) {
                $_ .= '=';
            }
        }
    }
    return @files;
}

# Handle one line of an input file. Note we also assume
# local-bound arrays I<@action> and I<@level>.
sub parse_and_bind($$$)
{
    $_ = shift;
    my $file = shift;
    my $include_depth = shift;
    s/^\s+//;
    return if m/^\s*(#|$)/;
    $InputLocMsg = " [$file line $.]";
    if (/^\$if\s+(.*)/) {
	my($test) = $1;
	push(@level, 'if');
	if ($action[$#action] ne 'exec') {
	    ## We're supposed to be skipping or ignoring this level,
	    ## so for subsequent levels we really ignore completely.
	    push(@action, 'ignore');
	} else {
	    ## We're executing this IF... do the test.
	    ## The test is either "term=xxxx", or just a string that
	    ## we compare to $rl_readline_name;
	    if ($test =~ /term=([a-z0-9]+)/) {
		$test = ($ENV{'TERM'} && $1 eq $ENV{'TERM'});
	    } else {
		$test = $test =~ /^(perl|$rl_readline_name)\s*$/i;
	    }
	    push(@action, $test ? 'exec' : 'skip');
	}
	return;
    } elsif (/^\$endif\b/) {
	die qq/\rWarning$InputLocMsg: unmatched endif\n/ if @level == 0;
	pop(@level);
	pop(@action);
	return;
    } elsif (/^\$else\b/) {
	die qq/\rWarning$InputLocMsg: unmatched else\n/ if
	    @level == 0 || $level[$#level] ne 'if';
	$level[$#level] = 'else'; ## an IF turns into an ELSE
	if ($action[$#action] eq 'skip') {
	    $action[$#action] = 'exec'; ## if were SKIPing, now EXEC
	} else {
	    $action[$#action] = 'ignore'; ## otherwise, just IGNORE.
	}
	return;
    } elsif (/^\$include\s+(\S+)/) {
	if ($include_depth > $max_include_depth) {
	    warn "Deep recursion in \$include directives in $file.\n";
	} else {
	    read_an_init_file($1, $include_depth + 1);
	}
    } elsif ($action[$#action] ne 'exec') {
	## skipping this one....
	# Readline permits trailing comments in inputrc
	# For example, /etc/inputrc on Mandrake Linux boxes has trailing
	# comments
    } elsif (m/\s*set\s+(\S+)\s+(\S*)/) { # Allow trailing comment
	&rl_set($1, $2, $file);
    } elsif (m/^\s*(\S+):\s+("(?:\\.|[^\\\"])*"|'(\\.|[^\\\'])*')/) { # Allow trailing comment
	&rl_bind($1, $2);
    } elsif (m/^\s*(\S+|"[^\"]+"):\s+(\S+)/) { # Allow trailing comment
	&rl_bind($1, $2);
    } else {
	chomp;
	warn "\rWarning$InputLocMsg: Bad line [$_]\n" if $^W;
    }
}

=head3 rl_parse_and_bind

B<rl_parse_and_bind>(I<$line>)

Parse I<$line> as if it had been read from the inputrc file and
perform any key bindings and variable assignments found.

=cut
sub rl_parse_and_bind($)
{
    my $line = shift;
    parse_and_bind($line, '*bogus*',  0);
}

=head3 rl_basic_commands

Called with a list of possible commands, will allow command completion
on those commands, but only for the first word on a line.  For
example:

    &rl_basic_commands('set', 'quit', 'type', 'run');

This is for people that want quick and simple command completion.
A more thoughtful implementation would set I<$rl_completion_function>
to a routine that would look at the context of the word being completed
and return the appropriate possibilities.

=cut
sub rl_basic_commands
{
     @rl_basic_commands = @_;
     $rl_completion_function = 'use_basic_commands';
}

sub rl_getc() {
    $Term::ReadLine::Perl5::term->Tk_loop
	if $Term::ReadLine::toloop && defined &Tk::DoOneEvent;
    return Term::ReadKey::ReadKey(0, $term_IN);
}

=head3 rl_read_init_file

B<rl_read_initfile>(I<$filename>)
Read keybindings and variable assignments from filename I<$filename>.

=cut
sub rl_read_init_file($) {
    read_an_init_file(shift, 0);
}


###########################################################################
## Bindable functions... pretty much in the same order as in readline.c ###
###########################################################################
=head1 BINDABLE FUNCTIONS

There are pretty much in the same order as in readline.c

=head2 Commands For Moving

=head3 F_BeginningOfLine

Move to the start of the current line.

=cut

sub F_BeginningOfLine
{
    $D = 0;
}

=head3 F_EndOfLine

Move to the end of the line.

=cut

sub F_EndOfLine
{
    &F_ForwardChar(100) while !&at_end_of_line;
}


=head3 F_ForwardChar

Move forward (right) $count characters.

=cut

sub F_ForwardChar
{
    my $count = shift;
    return &F_BackwardChar(-$count) if $count < 0;

    while (!&at_end_of_line && $count-- > 0) {
        $D += &CharSize($D);
    }
}

=head3 F_BackwardChar

Move backward (left) $count characters.

=cut

sub F_BackwardChar
{
    my $count = shift;
    return &F_ForwardChar(-$count) if $count < 0;

    while (($D > 0) && ($count-- > 0)) {
        $D--;                      ## Move back one regardless,
        $D-- if &OnSecondByte($D); ## another if over a big char.
    }
}

=head3 F_ForwardWord

Move forward to the end of the next word. Words are composed of
letters and digits.

Done as many times as $count says.

=cut

sub F_ForwardWord
{
    my $count = shift;
    return &F_BackwardWord(-$count) if $count < 0;

    while (!&at_end_of_line && $count-- > 0)
    {
        ## skip forward to the next word (if not already on one)
        &F_ForwardChar(1) while !&at_end_of_line && &WordBreak($D);
        ## skip forward to end of word
        &F_ForwardChar(1) while !&at_end_of_line && !&WordBreak($D);
    }
}

=head3 F_BackwardWord

Move back to the start of the current or previous word. Words are
composed of letters and digits.

Done as many times as $count says.

=cut

sub F_BackwardWord
{
    my $count = shift;
    return &F_ForwardWord(-$count) if $count < 0;

    while ($D > 0 && $count-- > 0) {
        ## skip backward to the next word (if not already on one)
        &F_BackwardChar(1) while (($D > 0) && &WordBreak($D-1));
        ## skip backward to start of word
        &F_BackwardChar(1) while (($D > 0) && !&WordBreak($D-1));
    }
}

=head3 F_ClearScreen

Clear the screen and redraw the current line, leaving the current line
at the top of the screen.

If given a numeric arg other than 1, simply refreshes the line.

=cut

sub F_ClearScreen
{
    my $count = shift;
    return &F_RedrawCurrentLine if $count != 1;

    $rl_CLEAR = `clear` if !defined($rl_CLEAR);
    local $\ = '';
    print $term_OUT $rl_CLEAR;
    $force_redraw = 1;
}

=head3 F_RedrawCurrentLine

Refresh the current line. By default, this is unbound.

=cut

sub F_RedrawCurrentLine
{
    $force_redraw = 1;
}

###########################################################################
=head2 Commands tor Manipulating the History

=head3 F_AcceptLine

Accept the line regardless of where the cursor is. If this line is
non-empty, it may be added to the history list for future recall with
add_history(). If this line is a modified history line, the history
line is restored to its original state.

=cut

sub F_AcceptLine
{
    &add_line_to_history($line, $minlength);
    $AcceptLine = $line;
    local $\ = '';
    print $term_OUT "\r\n";
    $force_redraw = 0;
    (pos $line) = undef;        # Another way to force redraw...
}

=head3 F_PreviousHistory

Move `back' through the history list, fetching the previous command.

=cut
sub F_PreviousHistory {
    &get_line_from_history($rl_HistoryIndex - shift);
}

=head3 F_PreviousHistory

Move `forward' through the history list, fetching the next command.

=cut
sub F_NextHistory {
    &get_line_from_history($rl_HistoryIndex + shift);
}

=head3 F_BeginningOfHistory

Move to the first line in the history.

=cut
sub F_BeginningOfHistory
{
    &get_line_from_history(0);
}

=head3 F_EndOfHistory

Move to the end of the input history, i.e., the line currently being
entered.

=cut
sub F_EndOfHistory { &get_line_from_history(@rl_History); }

=head3 F_ReverseSearchHistory

Search backward starting at the current line and moving `up' through
the history as necessary. This is an incremental search.

=cut
sub F_ReverseSearchHistory
{
    &DoSearch($_[0] >= 0 ? 1 : 0);
}

=head3

Search forward starting at the current line and moving `down' through
the the history as necessary. This is an increment

=cut

sub F_ForwardSearchHistory
{
    &DoSearch($_[0] >= 0 ? 0 : 1);
}

=head3 F_HistorySearchBackward

Search backward through the history for the string of characters
between the start of the current line and the point. The search string
must match at the beginning of a history line. This is a
non-incremental search. By default, this command is unbound.

=cut
sub F_HistorySearchBackward
{
    &DoSearchStart(($_[0] >= 0 ? 1 : 0),substr($line,0,$D));
}

=head3 F_HistorySearchForward

Search forward through the history for the string of characters
between the start of the current line and the point. The search string
may match anywhere in a history line. This is a non-incremental
search. By default, this command is unbound.

=cut

sub F_HistorySearchForward
{
    &DoSearchStart(($_[0] >= 0 ? 0 : 1),substr($line,0,$D));
}

sub F_PrintHistory {
    my($count) = @_;

    $count = 20 if $count == 1;             # Default - assume 'H', not '1H'
    my $end = $rl_HistoryIndex + $count/2;
    $end = @rl_History if $end > @rl_History;
    my $start = $end - $count + 1;
    $start = 0 if $start < 0;

    my $lmh = length $rl_MaxHistorySize;

    my $lspace = ' ' x ($lmh+3);
    my $hdr = "$lspace-----";
    $hdr .= " (Use ESC <num> UP to retrieve command <num>) -----" unless $Vi_mode;
    $hdr .= " (Use '<num>G' to retrieve command <num>) -----" if $Vi_mode;

    local ($\, $,) = ('','');
    print "\n$hdr\n";
    print $lspace, ". . .\n" if $start > 0;
    my $i;
    my $shift = ($Vi_mode != 0);
    for $i ($start .. $end) {
        print + ($i == $rl_HistoryIndex) ? '>' : ' ',

                sprintf("%${lmh}d: ", @rl_History - $i + $shift),

                ($i < @rl_History)       ? $rl_History[$i] :
                ($i == $rl_HistoryIndex) ? $line           :
                                           $line_for_revert,

                "\n";
    }
    print $lspace, ". . .\n" if $end < @rl_History;
    print "$hdr\n";

    rl_forced_update_display();

    &F_ViInput() if $line eq '' && $Vi_mode;
}

###########################################################################
=head2 Commands For Changing Text

=head3 F_DeleteChar

Removes the $count chars from under the cursor.
If there is no line and the last command was different, tells
readline to return EOF.
If there is a line, and the cursor is at the end of it, and we're in
tcsh completion mode, then list possible completions.
If $count > 1, deleted chars saved to kill buffer.

=cut

sub F_DeleteChar
{
    return if remove_selection();

    my $count = shift;
    return F_DeleteBackwardChar(-$count) if $count < 0;
    if (length($line) == 0) {   # EOF sent (probably OK in DOS too)
        $AcceptLine = $ReturnEOF = 1 if $lastcommand ne 'F_DeleteChar';
        return;
    }
    if ($D == length ($line))
    {
        &complete_internal('?') if $var_TcshCompleteMode;
        return;
    }
    my $oldD = $D;
    &F_ForwardChar($count);
    return if $D == $oldD;
    &kill_text($oldD, $D, $count > 1);
}

=head3 F_BackwardDeleteChar

Removes $count chars to left of cursor (if not at beginning of line).
If $count > 1, deleted chars saved to kill buffer.

=cut

sub F_BackwardDeleteChar
{
    return if remove_selection();

    my $count = shift;
    return F_DeleteChar(-$count) if $count < 0;
    my $oldD = $D;
    &F_BackwardChar($count);
    return if $D == $oldD;
    &kill_text($oldD, $D, $count > 1);
}

=head3 F_QuotedInsert

Add the next character typed to the line verbatim. This is how to
insert key sequences like C-q, for example.

=cut

sub F_QuotedInsert
{
    my $count = shift;
    &F_SelfInsert($count, ord(&getc_with_pending));
}

=head3 F_TabInsert

Insert a tab character.

=cut

sub F_TabInsert
{
    my $count = shift;
    &F_SelfInsert($count, ord("\t"));
}

=head3 F_SelfInsert

B<F_SelfInsert>(I<$count>, I<$ord>)

I<$ord> is an ASCII ordinal; inserts I<$count> of them into global
I<$line>.

Insert yourself.

=cut

sub F_SelfInsert
{
    remove_selection();
    my ($count, $ord) = @_;
    my $text2add = pack('C', $ord) x $count;
    if ($InsertMode) {
        substr($line,$D,0) .= $text2add;
    } else {
        ## note: this can screw up with 2-byte characters.
        substr($line,$D,length($text2add)) = $text2add;
    }
    $D += length($text2add);
}

=head3 F_TransposeChars

Switch char at dot with char before it.
If at the end of the line, switch the previous two...
I<Note>: this could screw up multibyte characters.. should do correctly)

=cut

sub F_TransposeChars
{
    if ($D == length($line) && $D >= 2) {
        substr($line,$D-2,2) = substr($line,$D-1,1).substr($line,$D-2,1);
    } elsif ($D >= 1) {
        substr($line,$D-1,2) = substr($line,$D,1)  .substr($line,$D-1,1);
    } else {
        F_Ding();
    }
}

=head3 F_TransposeWords

Drag the word before point past the word after point, moving point
past that word as well. If the insertion point is at the end of the
line, this transposes the last two words on the line.

=cut
sub F_TransposeWords {
    my $c = shift;
    return F_Ding() unless $c;
    # Find "this" word
    F_BackwardWord(1);
    my $p0 = $D;
    F_ForwardWord(1);
    my $p1 = $D;
    return F_Ding() if $p1 == $p0;
    my ($p2, $p3) = ($p0, $p1);
    if ($c > 0) {
      F_ForwardWord($c);
      $p3 = $D;
      F_BackwardWord(1);
      $p2 = $D;
    } else {
      F_BackwardWord(1 - $c);
      $p0 = $D;
      F_ForwardWord(1);
      $p1 = $D;
    }
    return F_Ding() if $p3 == $p2 or $p2 < $p1;
    my $r = substr $line, $p2, $p3 - $p2;
    substr($line, $p2, $p3 - $p2) = substr $line, $p0, $p1 - $p0;
    substr($line, $p0, $p1 - $p0) = $r;
    $D = $c > 0 ? $p3 : $p0 + $p3 - $p2; # End of "this" word after edit
    return 1;
}

=head3 F_UpcaseWord

Uppercase the current (or following) word. With a negative argument,
uppercase the previous word, but do not move the cursor.

=cut
sub F_UpcaseWord     { &changecase($_[0], 'up');   }

=head3 F_DownCaseWord

Lowercase the current (or following) word. With a negative argument,
lowercase the previous word, but do not move the cursor.

=cut
sub F_DownCaseWord   { &changecase($_[0], 'down'); }

=head3 F_CapitalizeWord

Capitalize the current (or following) word. With a negative argument,
capitalize the previous word, but do not move the cursor.

=cut
sub F_CapitalizeWord { &changecase($_[0], 'cap');  }

=head3 F_OverwriteMode

Toggle overwrite mode. With an explicit positive numeric argument,
switches to overwrite mode. With an explicit non-positive numeric
argument, switches to insert mode. This command affects only emacs
mode; vi mode does overwrite differently. Each call to readline()
starts in insert mode.  In overwrite mode, characters bound to
self-insert replace the text at point rather than pushing the text to
the right. Characters bound to backward-delete-char replace the
character before point with a space.

By default, this command is unbound.

=cut
sub F_OverwriteMode
{
    $InsertMode = 0;
}

###########################################################################
=head2 Killing and Yanking

=head3 F_KillLine

delete characters from cursor to end of line.

=cut

sub F_KillLine
{
    my $count = shift;
    return F_BackwardKillLine(-$count) if $count < 0;
    kill_text($D, length($line), 1);
}

=head3 F_BackwardKillLine

Delete characters from cursor to beginning of line.

=cut

sub F_BackwardKillLine
{
    my $count = shift;
    return F_KillLine(-$count) if $count < 0;
    return F_Ding if $D == 0;
    kill_text(0, $D, 1);
}

=head3 F_UnixLineDiscard

Kill line from cursor to beginning of line.

=cut

sub F_UnixLineDiscard
{
    return F_Ding() if $D == 0;
    kill_text(0, $D, 1);
}

=head3 F_KillWord

Delete characters to the end of the current word. If not on a word, delete to
## the end of the next word.

=cut

sub F_KillWord
{
    my $count = shift;
    return &F_BackwardKillWord(-$count) if $count < 0;
    my $oldD = $D;
    &F_ForwardWord($count);     ## moves forward $count words.
    kill_text($oldD, $D, 1);
}

=head3 F_BackwardKillWord

Delete characters backward to the start of the current word, or, if
currently not on a word (or just at the start of a word), to the start
of the previous word.

=cut
sub F_BackwardKillWord
{
    my $count = shift;
    return F_KillWord(-$count) if $count < 0;
    my $oldD = $D;
    &F_BackwardWord($count);    ## moves backward $count words.
    kill_text($D, $oldD, 1);
}

=head3 F_UnixWordRubout

Kill to previous whitespace.

=cut

sub F_UnixWordRubout
{
    return F_Ding() if $D == 0;
    (my $oldD, local $rl_basic_word_break_characters) = ($D, "\t ");
                             # JP:  Fixed a bug here - both were 'my'
    F_BackwardWord(1);
    kill_text($D, $oldD, 1);
}

=head3 F_KillRegion

Kill the text in the current region. By default, this command is
unbound.

=cut
sub F_KillRegion {
    return F_Ding() unless $line_rl_mark == $rl_HistoryIndex;
    $rl_mark = length $line if $rl_mark > length $line;
    kill_text($rl_mark, $D, 1);
    $line_rl_mark = -1;         # Disable mark
}

=head3 F_CopyRegionAsKill

Copy the text in the region to the kill buffer, so it can be yanked right away. By default, this command is unbound.

=cut
sub F_CopyRegionAsKill {
    return F_Ding() unless $line_rl_mark == $rl_HistoryIndex;
    $rl_mark = length $line if $rl_mark > length $line;
    my ($s, $e) = ($rl_mark, $D);
    ($s, $e) = ($e, $s) if $s > $e;
    $ThisCommandKilledText = 1 + $s;
    $KillBuffer = '' if !$LastCommandKilledText;
    $KillBuffer .= substr($line, $s, $e - $s);
}

=head3 F_Yank

Yank the top of the kill ring into the buffer at point.

=cut
sub F_Yank
{
    remove_selection();
    &TextInsert($_[0], $KillBuffer);
}

sub F_YankPop    {
   1;
   ## not implemented yet
}

sub F_YankNthArg {
   1;
   ## not implemented yet
}

###########################################################################
=head2 Specifying Numeric Arguments

=head3 F_DigitArgument

Add this digit to the argument already accumulating, or start a new
argument. C<M--> starts a negative argument.

=cut
sub F_DigitArgument
{
    my $in = chr $_[1];
    my ($NumericArg, $sawDigit) = (1, 0);
    my ($increment, $ord);
    ($NumericArg, $sawDigit) = ($_[0], $_[0] !~ /e0$/i)
        if $doingNumArg;        # XXX What if Esc-- 1 ?

    do
    {
        $ord = ord $in;
        if (defined($KeyMap[$ord]) && $KeyMap[$ord] eq 'F_UniversalArgument') {
            $NumericArg *= 4;
        } elsif ($ord == ord('-') && !$sawDigit) {
            $NumericArg = -$NumericArg;
        } elsif ($ord >= ord('0') && $ord <= ord('9')) {
            $increment = ($ord - ord('0')) * ($NumericArg < 0 ? -1 : 1);
            if ($sawDigit) {
                $NumericArg = $NumericArg * 10 + $increment;
            } else {
                $NumericArg = $increment;
                $sawDigit = 1;
            }
        } else {
            local(*KeyMap) = $var_EditingMode;
            rl_redisplay();
            $doingNumArg = 1;           # Allow NumArg inside NumArg
            &do_command(*KeyMap, $NumericArg . ($sawDigit ? '': 'e0'), $ord);
            return;
        }
        ## make sure it's not toooo big.
        if ($NumericArg > $rl_max_numeric_arg) {
            $NumericArg = $rl_max_numeric_arg;
        } elsif ($NumericArg < -$rl_max_numeric_arg) {
            $NumericArg = -$rl_max_numeric_arg;
        }
        redisplay(sprintf("(arg %d) ", $NumericArg));
    } while defined($in = &getc_with_pending);
}

=head3 F_UniversalArgument

This is another way to specify an argument. If this command is
followed by one or more digits, optionally with a leading minus sign,
those digits define the argument. If the command is followed by
digits, executing universal-argument again ends the numeric argument,
but is otherwise ignored. As a special case, if this command is
immediately followed by a character that is neither a digit or minus
sign, the argument count for the next command is multiplied by
four. The argument count is initially one, so executing this function
the first time makes the argument count four, a second time makes the
argument count sixteen, and so on. By default, this is not bound to a
key.

=cut
sub F_UniversalArgument
{
    &F_DigitArgument;
}

###########################################################################
=head2 Letting Readline Type For You

=head3 F_Complete

Do a completion operation.  If the last thing we did was a completion
operation, we'll now list the options available (under normal emacs
mode).

In I<TcshCompleteMode>, each contiguous subsequent completion
operation lists another of the possible options.

Returns true if a completion was done, false otherwise, so vi
completion routines can test it.

=cut

sub F_Complete
{
    if ($lastcommand eq 'F_Complete') {
        if ($var_TcshCompleteMode && @tcsh_complete_selections > 0) {
            substr($line, $tcsh_complete_start, $tcsh_complete_len)
                = $tcsh_complete_selections[0];
            $D -= $tcsh_complete_len;
            $tcsh_complete_len = length($tcsh_complete_selections[0]);
            $D += $tcsh_complete_len;
            push(@tcsh_complete_selections, shift(@tcsh_complete_selections));
        } else {
            &complete_internal('?') or return;
        }
    } else {
        @tcsh_complete_selections = ();
        &complete_internal("\t") or return;
    }

    1;
}

=head3 F_PossibleCompletions

List possible completions

=cut

sub F_PossibleCompletions
{
    &complete_internal('?');
}

=head3 F_PossibleCompletions

Insert all completions of the text before point that would have been
generated by possible-completions.

=cut

sub F_InsertCompletions
{
    &complete_internal('*');
}

###########################################################################
=head2 Miscellaneous Commands

=head3 F_ReReadInitFile

Read in the contents of the inputrc file, and incorporate any bindings
or variable assignments found there.

=cut

sub F_ReReadInitFile
{
    my ($file) = $ENV{'TRP5_INPUTRC'};
    $file = $ENV{'INPUTRC'} unless defined $file;
    unless (defined $file) {
        return unless defined $HOME;
        $file = File::Spec->catfile($HOME, '.inputrc');
    }
    rl_read_init_file($file);
}

=head3 F_Abort

Abort the current editing command and ring the terminal's bell
(subject to the setting of bell-style).

=cut
sub F_Abort
{
    F_Ding();
}


=head3 F_Undo

Incremental undo, separately remembered for each line.

=cut

sub F_Undo
{
    pop(@undo); # unless $undo[-1]->[5]; ## get rid of the state we just put on, so we can go back one.
    if (@undo) {
        &getstate(pop(@undo));
    } else {
        F_Ding();
    }
}

=head3 F_RevertLine

Undo all changes made to this line. This is like executing the undo
command enough times to get back to the beginning.

=cut

sub F_RevertLine
{
    if ($rl_HistoryIndex >= $#rl_History+1) {
        $line = $line_for_revert;
    } else {
        $line = $rl_History[$rl_HistoryIndex];
    }
    $D = length($line);
}

=head3 F_TildeExpand

Perform tilde expansion on the current word.

=cut
sub F_TildeExpand {

    my $what_to_do = shift;
    my ($point, $end) = ($D, $D);

    # In vi mode, complete if the cursor is at the *end* of a word, not
    #     after it.
    ($point++, $end++) if $Vi_mode;

    # Get text to work complete on.
    if ($point) {
        ## Not at the beginning of the line; Isolate the word to be
        ## completed.
        1 while (--$point && (-1 == index($rl_completer_word_break_characters,
                substr($line, $point, 1))));

        # Either at beginning of line or at a word break.
        # If at a word break (that we don't want to save), skip it.
        $point++ if (
	    (index($rl_completer_word_break_characters,
		   substr($line, $point, 1)) != -1) &&
	    (index($rl_special_prefixes, substr($line, $point, 1)) == -1)
	    );
    }

    my $text = substr($line, $point, $end - $point);

    # If the first character of the current word is a tilde, perform
    # tilde expansion and insert the result.  If not a tilde, do
    # nothing.
    return if substr($text, 0, 1) ne '~';

    my @matches = tilde_complete($text);
    if (@matches == 0) {
        return F_Ding();
    }
    my $replacement = shift(@matches);
    $replacement .= $rl_completer_terminator_character
	if @matches == 1 && !$rl_completion_suppress_append;
    F_Ding() if @matches != 1;
    if ($var_TcshCompleteMode) {
	@tcsh_complete_selections = (@matches, $text);
	$tcsh_complete_start = $point;
	$tcsh_complete_len = length($replacement);
    }

    if ($replacement ne '') {
	# Finally! Do the replacement.
	substr($line, $point, $end-$point) = $replacement;
	$D = $D - ($end - $point) + length($replacement);
    }
}

=head3 F_SetMark

Set the mark to the point. If a numeric argument is supplied, the mark
is set to that position.

=cut

sub F_SetMark {
    $rl_mark = $D;
    pos $line = $rl_mark;
    $line_rl_mark = $rl_HistoryIndex;
    $force_redraw = 1;
}

=head3 F_ExchangePointAndMark

Set the mark to the point. If a numeric argument is supplied, the mark
is set to that position.

=cut

sub F_ExchangePointAndMark {
    return F_Ding unless $line_rl_mark == $rl_HistoryIndex;
    ($rl_mark, $D) = ($D, $rl_mark);
    pos $line = $rl_mark;
    $D = length $line if $D > length $line;
    $force_redraw = 1;
}

=head3 F_OperateAndGetNext

Accept the current line and fetch from the history the next line
relative to current line for default.

=cut

sub F_OperateAndGetNext
{
    my $count = shift;

    &F_AcceptLine;

    my $remainingEntries = $#rl_History - $rl_HistoryIndex;
    if ($count > 0 && $remainingEntries >= 0) {  # there is something to repeat
        if ($remainingEntries > 0) {  # if we are not on last line
            $rl_HistoryIndex++;       # fetch next one
            $count = $remainingEntries if $count > $remainingEntries;
        }
        $rl_OperateCount = $count;
    }
}

=head3 F_DoLowercaseVersion

If the character that got us here is upper case,
do the lower-case equivalent command.

=cut

sub F_DoLowercaseVersion
{
    my $c = $_[1];
    if (isupper($c)) {
        &do_command(*KeyMap, $_[0], lc($c));
    } else {
        &F_Ding;
    }
}

=head3 F_DoControlVersion

do the equiv with control key...
If the character that got us here is upper case,
do the lower-case equivalent command.

=cut

sub F_DoControlVersion
{
    local *KeyMap = $var_EditingMode;
    my $key = $_[1];

    if ($key == ord('?')) {
        $key = 0x7F;
    } else {
        $key &= ~(0x80 | 0x60);
    }
    &do_command(*KeyMap, $_[0], $key);
}

=head3 F_DoMetaVersion

do the equiv with meta key...

=cut

sub F_DoMetaVersion
{
    local *KeyMap = $var_EditingMode;
    unshift @Pending, chr $_[1];

    &do_command(*KeyMap, $_[0], ord "\e");
}

=head3 F_DoEscVersion

If the character that got us here is Alt-Char,
do the Esc Char equiv...

=cut

sub F_DoEscVersion
{
    my ($ord, $t) = $_[1];
    &F_Ding unless $KeyMap{'Esc'};
    for $t (([ord 'w', '`1234567890-='],
             [ord ',', 'zxcvbnm,./\\'],
             [16,      'qwertyuiop[]'],
             [ord(' ') - 2, 'asdfghjkl;\''])) {
      next unless $ord >= $t->[0] and $ord < $t->[0] + length($t->[1]);
      $ord = ord substr $t->[1], $ord - $t->[0], 1;
      return &do_command($KeyMap{'Esc'}, $_[0], $ord);
    }
    &F_Ding;
}

sub F_EmacsEditingMode
{
    $var_EditingMode = $var_EditingMode{'emacs'};
    $Vi_mode = 0;
}

=head3 F_Interrupt

(Attempt to) interrupt the current program via I<kill('INT')>
=cut

sub F_Interrupt
{
    local $\ = '';
    print $term_OUT "\r\n";
    &ResetTTY;
    kill ("INT", 0);

    ## We're back.... must not have died.
    $force_redraw = 1;
}

##
## Execute the next character input as a command in a meta keymap.
##
sub F_PrefixMeta
{
    my($count, $keymap) = ($_[0], "$KeyMap{'name'}_$_[1]");
    print "F_PrefixMeta [$keymap]\n\r" if $DEBUG;
    die "<internal error, $_[1]>" unless %$keymap;
    do_command(*$keymap, $count, ord(&getc_with_pending));
}

sub F_InsertMode
{
    $InsertMode = 1;
}

sub F_ToggleInsertMode
{
    $InsertMode = !$InsertMode;
}

=head3

(Attempt to) suspend the program via I<kill('TSTP')>

=cut

sub F_Suspend
{
    if ($inDOS && length($line)==0) { # EOF sent
        $AcceptLine = $ReturnEOF = 1 if $lastcommand ne 'F_DeleteChar';
        return;
    }
    local $\ = '';
    print $term_OUT "\r\n";
    &ResetTTY;
    eval { kill ("TSTP", 0) };
    ## We're back....
    &SetTTY;
    $force_redraw = 1;
}

=head3 F_Ding

Ring the bell.

Should do something with I<$var_PreferVisibleBel> here, but what?
=cut
sub F_Ding {
    Term::ReadLine::Perl5::Common::F_Ding($term_OUT)
}

=head2 vi Routines

=cut

sub F_ViAcceptLine
{
    &F_AcceptLine();
    &F_ViInput();
}

=head3 F_ViRepeatLastCommand

Repeat the most recent one of these vi commands:

   a A c C d D i I p P r R s S x X ~

=cut
sub F_ViRepeatLastCommand {
    my($count) = @_;
    return F_Ding() if !$Last_vi_command;

    my @lastcmd = @$Last_vi_command;

    # Multiply @lastcmd's numeric arg by $count.
    unless ($count == 1) {

        my $n = '';
        while (@lastcmd and $lastcmd[0] =~ /^\d$/) {
            $n *= 10;
            $n += shift(@lastcmd);
        }
        $count *= $n unless $n eq '';
        unshift(@lastcmd, split(//, $count));
    }

    push(@Pending, @lastcmd);
}

sub F_ViMoveCursor
{
    my($count, $ord) = @_;

    my $new_cursor = &get_position($count, $ord, undef, $Vi_move_patterns);
    return F_Ding() if !defined $new_cursor;

    $D = $new_cursor;
}

sub F_ViFindMatchingParens {

    # Move to the first parens at or after $D
    my $old_d = $D;
    &forward_scan(1, q/[^[\](){}]*/);
    my $parens = substr($line, $D, 1);

    my $mate_direction = {
                    '('  =>  [ ')',  1 ],
                    '['  =>  [ ']',  1 ],
                    '{'  =>  [ '}',  1 ],
                    ')'  =>  [ '(', -1 ],
                    ']'  =>  [ '[', -1 ],
                    '}'  =>  [ '{', -1 ],

                }->{$parens};

    return &F_Ding() unless $mate_direction;

    my($mate, $direction) = @$mate_direction;

    my $lvl = 1;
    while ($lvl) {
        last if !$D && ($direction < 0);
        &F_ForwardChar($direction);
        last if &at_end_of_line;
        my $c = substr($line, $D, 1);
        if ($c eq $parens) {
            $lvl++;
        }
        elsif ($c eq $mate) {
            $lvl--;
        }
    }

    if ($lvl) {
        # We didn't find a match
        $D = $old_d;
        return &F_Ding();
    }
}

sub F_ViForwardFindChar {
    &do_findchar(1, 1, @_);
}

sub F_ViBackwardFindChar {
    &do_findchar(-1, 0, @_);
}

sub F_ViForwardToChar {
    &do_findchar(1, 0, @_);
}

sub F_ViBackwardToChar {
    &do_findchar(-1, 1, @_);
}

sub F_ViMoveCursorTo
{
    &do_findchar(1, -1, @_);
}

sub F_ViMoveCursorFind
{
    &do_findchar(1, 0, @_);
}


sub F_ViRepeatFindChar {
    my($n) = @_;
    return &F_Ding if !defined $Last_findchar;
    &findchar(@$Last_findchar, $n);
}

sub F_ViInverseRepeatFindChar {
    my($n) = @_;
    return &F_Ding if !defined $Last_findchar;
    my($c, $direction, $offset) = @$Last_findchar;
    &findchar($c, -$direction, $offset, $n);
}

sub do_findchar {
    my($direction, $offset, $n) = @_;
    my $c = &getc_with_pending;
    $c = &getc_with_pending if $c eq "\cV";
    return &F_ViCommandMode if $c eq "\e";
    $Last_findchar = [$c, $direction, $offset];
    &findchar($c, $direction, $offset, $n);
}

sub findchar {
    my($c, $direction, $offset, $n) = @_;
    my $old_d = $D;
    while ($n) {
        last if !$D && ($direction < 0);
        &F_ForwardChar($direction);
        last if &at_end_of_line;
        my $char = substr($line, $D, 1);
        $n-- if substr($line, $D, 1) eq $c;
    }
    if ($n) {
        # Not found
        $D = $old_d;
        return &F_Ding;
    }
    &F_ForwardChar($offset);
}

sub F_ViMoveToColumn {
    my($n) = @_;
    $D = 0;
    my $col = 1;
    while (!&at_end_of_line and $col < $n) {
        my $c = substr($line, $D, 1);
        if ($c eq "\t") {
            $col += 7;
            $col -= ($col % 8) - 1;
        }
        else {
            $col++;
        }
        $D += &CharSize($D);
    }
}

=head3 F_SaveLine

Prepend line with '#', add to history, and clear the input buffer
(this feature was borrowed from ksh).

=cut
sub F_SaveLine
{
    local $\ = '';
    $line = '#'.$line;
    rl_redisplay();
    print $term_OUT "\r\n";
    &add_line_to_history($line, $minlength);
    $line_for_revert = '';
    &get_line_from_history(scalar @rl_History);
    &F_ViInput() if $Vi_mode;
}

=head3 F_ViNonePosition

Come here if we see a non-positioning keystroke when a positioning
keystroke is expected.
=cut
sub F_ViNonPosition {
    # Not a positioning command - undefine the cursor to indicate the error
    #     to get_position().
    undef $D;
}

=head3 ViPositionEsc

Comes here if we see I<esc>I<char>, but I<not> an arrow key or other
mapped sequence, when a positioning keystroke is expected.
=cut

sub F_ViPositionEsc {
    my($count, $ord) = @_;

    # We got <esc><char> in vipos mode.  Put <char> back onto the
    #     input stream and terminate the positioning command.
    unshift(@Pending, pack('c', $ord));
    &F_ViNonPosition;
}

sub F_ViUndo {
    return &F_Ding unless defined $Vi_undo_state;
    my $state = savestate();
    &getstate($Vi_undo_state);
    $Vi_undo_state = $state;
}

sub F_ViUndoAll {
    $Vi_undo_state = $Vi_undo_all_state;
    &F_ViUndo;
}

sub F_ViChange
{
    my($count, $ord) = @_;
    &start_dot_buf(@_);
    &do_delete($count, $ord, $Vi_change_patterns) || return();
    &vi_input_mode;
}

sub F_ViDelete
{
    my($count, $ord) = @_;
    &start_dot_buf(@_);
    &do_delete($count, $ord, $Vi_delete_patterns);
    &end_dot_buf;
}

sub F_ViDeleteChar {
    my($count) = @_;
    &save_dot_buf(@_);
    my $other_end = $D + $count;
    $other_end = length($line) if $other_end > length($line);
    &kill_text($D, $other_end, 1);
}

sub F_ViBackwardDeleteChar {
    my($count) = @_;
    &save_dot_buf(@_);
    my $other_end = $D - $count;
    $other_end = 0 if $other_end < 0;
    &kill_text($other_end, $D, 1);
    $D = $other_end;
}

=head3 F_ViFirstWord

Go to first non-space character of line.
=cut
sub F_ViFirstWord
{
    $D = 0;
    &forward_scan(1, q{\s+});
}

=head3 F_ViTtoggleCase

# Like the emacs case transforms.

I<Note>: this doesn't work for multi-byte characters.
=cut

sub F_ViToggleCase {
    my($count) = @_;
    &save_dot_buf(@_);
    while ($count-- > 0) {
        substr($line, $D, 1) =~ tr/A-Za-z/a-zA-Z/;
        &F_ForwardChar(1);
        if (&at_end_of_line) {
            &F_BackwardChar(1);
            last;
        }
    }
}

=head3 F_ViHistoryLine

Go to the numbered history line, as listed by the 'H' command,
i.e. the current $line is line 1, the youngest line in I<@rl_History>
is 2, etc.

=cut

sub F_ViHistoryLine {
    my($n) = @_;
    &get_line_from_history(@rl_History - $n + 1);
}

=head3 F_ViSearch

Search history for matching string.  As with vi in nomagic mode, the
^, $, \<, and \> positional assertions, the \* quantifier, the \.
character class, and the \[ character class delimiter all have special
meaning here.
=cut
sub F_ViSearch {
    my($n, $ord) = @_;

    my $c = pack('c', $ord);

    my $str = &get_vi_search_str($c);
    if (!defined $str) {
        # Search aborted by deleting the '/' at the beginning of the line
        return &F_ViInput() if $line eq '';
        return();
    }

    # Null string repeats last search
    if ($str eq '') {
        return &F_Ding unless defined $Vi_search_re;
    }
    else {
        # Convert to a regular expression.  Interpret $str Like vi in nomagic
        #     mode: '^', '$', '\<', and '\>' positional assertions, '\*'
        #     quantifier, '\.' and '\[]' character classes.

        my @chars = ($str =~ m{(\\?.)}g);
        my(@re, @tail);
        unshift(@re,   shift(@chars)) if @chars and $chars[0]  eq '^';
        push   (@tail, pop(@chars))   if @chars and $chars[-1] eq '$';
        my $in_chclass;
        my %chmap = (
            '\<' => '\b(?=\w)',
            '\>' => '(?<=\w)\b',
            '\*' => '*',
            '\[' => '[',
            '\.' => '.',
        );
        my $ch;
        foreach $ch (@chars) {
            if ($in_chclass) {
                # Any backslashes in vi char classes are literal
                push(@re, "\\") if length($ch) > 1;
                push(@re, $ch);
                $in_chclass = 0 if $ch =~ /\]$/;
            }
            else {
                push(@re, (length $ch == 2) ? ($chmap{$ch} || $ch) :
                          ($ch =~ /^\w$/)   ? $ch                  :
                                              ("\\", $ch));
                $in_chclass = 1 if $ch eq '\[';
            }
        }
        my $re = join('', @re, @tail);
        $Vi_search_re = q{$re};
    }

    local $reverse = $Vi_search_reverse = ($c eq '/') ? 1 : 0;
    &do_vi_search();
}

sub F_ViRepeatSearch {
    my($n, $ord) = @_;
    my $c = pack('c', $ord);
    return &F_Ding unless defined $Vi_search_re;
    local $reverse = $Vi_search_reverse;
    $reverse ^= 1 if $c eq 'N';
    &do_vi_search();
}

sub F_ViEndSearch {}

sub F_ViSearchBackwardDeleteChar {
    if ($line eq '') {
        # Backspaced past beginning of line - terminate search mode
        undef $line;
    }
    else {
        &F_BackwardDeleteChar(@_);
    }
}

=head3 F_ViChangeEntireLine

Kill entire line and enter input mode
=cut
sub F_ViChangeEntireLine
{
    &start_dot_buf(@_);
    kill_text(0, length($line), 1);
    &vi_input_mode;
}

=head3 F_ViChangeChar

Kill characters and enter input mode
=cut
sub F_ViChangeChar
{
    &start_dot_buf(@_);
    &F_DeleteChar(@_);
    &vi_input_mode;
}

sub F_ViReplaceChar
{
    &start_dot_buf(@_);
    my $c = &getc_with_pending;
    $c = &getc_with_pending if $c eq "\cV";   # ctrl-V
    return &F_ViCommandMode if $c eq "\e";
    &end_dot_buf;

    local $InsertMode = 0;
    local $D = $D;                  # Preserve cursor position
    &F_SelfInsert(1, ord($c));
}

=head3 F_ViChangeLine

Delete characteres from cursor to end of line and enter VI input mode.

=cut

sub F_ViChangeLine
{
    &start_dot_buf(@_);
    &F_KillLine(@_);
    &vi_input_mode;
}

sub F_ViDeleteLine
{
    &save_dot_buf(@_);
    &F_KillLine(@_);
}

sub F_ViPut
{
    my($count) = @_;
    &save_dot_buf(@_);
    my $text2add = $KillBuffer x $count;
    my $ll = length($line);
    $D++;
    $D = $ll if $D > $ll;
    substr($line, $D, 0) = $KillBuffer x $count;
    $D += length($text2add) - 1;
}

sub F_ViPutBefore
{
    &save_dot_buf(@_);
    &TextInsert($_[0], $KillBuffer);
}

sub F_ViYank
{
    my($count, $ord) = @_;
    my $pos = &get_position($count, undef, $ord, $Vi_yank_patterns);
    &F_Ding if !defined $pos;
    if ($pos < 0) {
        # yy
        &F_ViYankLine;
    }
    else {
        my($from, $to) = ($pos > $D) ? ($D, $pos) : ($pos, $D);
        $KillBuffer = substr($line, $from, $to-$from);
    }
}

sub F_ViYankLine
{
    $KillBuffer = $line;
}

sub F_ViInput
{
    @_ = (1, ord('i')) if !@_;
    &start_dot_buf(@_);
    &vi_input_mode;
}

sub F_ViBeginInput
{
    &start_dot_buf(@_);
    &F_BeginningOfLine;
    &vi_input_mode;
}

sub F_ViReplaceMode
{
    &start_dot_buf(@_);
    $InsertMode = 0;
    $var_EditingMode = $var_EditingMode{'vi'};
    $Vi_mode = 1;
}
# The previous keystroke was an escape, but the sequence was not recognized
#     as a mapped sequence (like an arrow key).  Enter vi comand mode and
#     process this keystroke.
sub F_ViAfterEsc {
    my($n, $ord) = @_;
    &F_ViCommandMode;
    &do_command($var_EditingMode, 1, $ord);
}

sub F_ViAppend
{
    &start_dot_buf(@_);
    &vi_input_mode;
    &F_ForwardChar;
}

sub F_ViAppendLine
{
    &start_dot_buf(@_);
    &vi_input_mode;
    &F_EndOfLine;
}

sub F_ViCommandMode
{
    $var_EditingMode = $var_EditingMode{'vicmd'};
    $Vi_mode = 1;
}

sub F_ViAcceptInsert {
    local $in_accept_line = 1;
    &F_ViEndInsert;
    &F_ViAcceptLine;
}

sub F_ViEndInsert
{
    if ($Dot_buf) {
        if ($line eq '' and $Dot_buf->[0] eq 'i') {
            # We inserted nothing into an empty $line - assume it was a
            #     &F_ViInput() call with no arguments, and don't save command.
            undef $Dot_buf;
        }
        else {
            # Regardless of which keystroke actually terminated this insert
            #     command, replace it with an <esc> in the dot buffer.
            @{$Dot_buf}[-1] = "\e";
            &end_dot_buf;
        }
    }
    &F_ViCommandMode;
    # Move cursor back to the last inserted character, but not when
    # we're about to accept a line of input
    &F_BackwardChar(1) unless $in_accept_line;
}

sub F_ViDigit {
    my($count, $ord) = @_;

    my $n = 0;
    my $ord0 = ord('0');
    while (1) {

        $n *= 10;
        $n += $ord - $ord0;

        my $c = &getc_with_pending;
        return unless defined $c;
        $ord = ord($c);
        last unless $c =~ /^\d$/;
    }

    $n *= $count;                   # So  2d3w  deletes six words
    $n = $rl_max_numeric_arg if $n > $rl_max_numeric_arg;

    &do_command($var_EditingMode, $n, $ord);
}

sub F_ViComplete {
    my($n, $ord) = @_;

    $Dot_state = savestate();     # Completion is undo-able
    undef $Dot_buf;              #       but not redo-able

    my $ch;
    while (1) {

        &F_Complete() or return;

        # Vi likes the cursor one character right of where emacs like it.
        &F_ForwardChar(1);
        rl_forced_update_display();

        # Look ahead to the next input keystroke.
        $ch = &getc_with_pending();
        last unless ord($ch) == $ord;   # Not a '\' - quit.

        # Another '\' was typed - put the cursor back where &F_Complete left
        #     it, and try again.
        &F_BackwardChar(1);
        $lastcommand = 'F_Complete';   # Play along with &F_Complete's kludge
    }
    unshift(@Pending, $ch);      # Unget the lookahead keystroke

    # Successful completion - enter input mode with cursor beyond end of word.
    &vi_input_mode;
}

sub F_ViInsertPossibleCompletions {
    $Dot_state = savestate();     # Completion is undo-able
    undef $Dot_buf;              #       but not redo-able

    &complete_internal('*') or return;

    # Successful completion - enter input mode with cursor beyond end of word.
    &F_ForwardChar(1);
    &vi_input_mode;
}

sub F_ViPossibleCompletions {

    # List possible completions
    &complete_internal('?');

    # Enter input mode with cursor where we left off.
    &F_ForwardChar(1);
    &vi_input_mode;
}

sub F_CopyRegionAsKillClipboard {
    return clipboard_set($line) unless $line_rl_mark == $rl_HistoryIndex;
    &F_CopyRegionAsKill;
    clipboard_set($KillBuffer);
}

sub F_KillRegionClipboard {
    &F_KillRegion;
    clipboard_set($KillBuffer);
}

sub F_YankClipboard
{
    remove_selection();
    my $in;
    if ($^O eq 'os2') {
      eval {
        require OS2::Process;
        $in = OS2::Process::ClipbrdText();
        $in =~ s/\r\n/\n/g;             # With old versions, or what?
      }
    } elsif ($^O eq 'MSWin32') {
      eval {
        require Win32::Clipboard;
        $in = Win32::Clipboard::GetText();
        $in =~ s/\r\n/\n/g;  # is this needed?
      }
    } else {
      my $mess;
      my $paste_fh;
      if ($ENV{RL_PASTE_CMD}) {
        $mess = "Reading from pipe `$ENV{RL_PASTE_CMD}'";
        open($paste_fh, "$ENV{RL_PASTE_CMD} |") or warn("$mess: $!"), return;
      } elsif (defined $HOME) {
	my $cutpastefile = File::Spec($HOME, '.rl_cutandpaste');
        $mess = "Reading from file `$cutpastefile'";
        open($paste_fh, '<:encoding(utf-8)', $cutpastefile)
	    or warn("$mess: $!"), return;
      }
      if ($mess) {
        local $/;
        $in = <$paste_fh>;
        close $paste_fh or warn("$mess, closing: $!");
      }
    }
    if (defined $in) {
        $in =~ s/\n+$//;
        return &TextInsert($_[0], $in);
    }
    &TextInsert($_[0], $KillBuffer);
}

sub F_BeginUndoGroup {
    push @undoGroupS, $#undo;
}

sub F_EndUndoGroup {
    return F_Ding unless @undoGroupS;
    my $last = pop @undoGroupS;
    return unless $#undo > $last + 1;
    my $now = pop @undo;
    $#undo = $last;
    push @undo, $now;
}

sub F_DoNothing {               # E.g., reset digit-argument
    1;
}

sub F_ForceMemorizeDigitArgument {
    $memorizedArg = shift;
}

sub F_MemorizeDigitArgument {
    return if defined $memorizedArg;
    $memorizedArg = shift;
}

sub F_UnmemorizeDigitArgument {
    $memorizedArg = undef;
}

sub F_MemorizePos {
    $memorizedPos = $D;
}

###########################################################################

# It is assumed that F_MemorizePos was called, then something was inserted,
# then F_MergeInserts is called with a prefix argument to multiply
# insertion by

sub F_MergeInserts {
    my $n = shift;
    return F_Ding unless defined $memorizedPos and $n > 0;
    my ($b, $e) = ($memorizedPos, $D);
    ($b, $e) = ($e, $b) if $e < $b;
    if ($n) {
        substr($line, $e, 0) = substr($line, $b, $e - $b) x ($n - 1);
    } else {
        substr($line, $b, $e - $b) = '';
    }
    $D = $b + ($e - $b) * $n;
}

sub F_ResetDigitArgument {
    return F_Ding unless defined $memorizedArg;
    my $in = &getc_with_pending;
    return unless defined $in;
    my $ord = ord $in;
    local(*KeyMap) = $var_EditingMode;
    &do_command(*KeyMap, $memorizedArg, $ord);
}

sub F_BeginPasteGroup {
    my $c = shift;
    $memorizedArg = $c unless defined $memorizedArg;
    F_BeginUndoGroup(1);
    $memorizedPos = $D;
}

sub F_EndPasteGroup {
    my $c = $memorizedArg;
    undef $memorizedArg;
    $c = 1 unless defined $c;
    F_MergeInserts($c);
    F_EndUndoGroup(1);
}

sub F_BeginEditGroup {
    $memorizedArg = shift;
    F_BeginUndoGroup(1);
}

sub F_EndEditGroup {
    undef $memorizedArg;
    F_EndUndoGroup(1);
}

###########################################################################
=head2 Internal Routines

=head3 get_window_size

   get_window_size([$redisplay])

I<Note: this function is deprecated. It is not in L<Term::ReadLine::GNU>
or the GNU ReadLine library. As such, it may disappear and be replaced
by the corresponding L<Term::ReadLine::GNU> routines.>

Causes a query to get the terminal width. If the terminal width can't
be obtained, nothing is done. Otherwise...

=over

=item * Set I<$rl_screen_width> and to the current screen width.
I<$rl_margin> is then set to be 1/3 of I<$rl_screen_width>.

=item * any window-changeing hooks stored in array I<@winchhooks> are
run.

=item * I<SIG{WINCH}> is set to run this routine. Any routines set are
lost. A better behavior would be to add existing hooks to
I<@winchhooks>, but hey, this routine is deprecated.

=item * If I<$redisplay> is passed and is true, then a redisplay of
the input line is done by calling I<redisplay()>.

=back

=cut

sub get_window_size
{
    my $redraw = shift;

    # Preserve $! etc; the rest for hooks
    local($., $@, $!, $^E, $?);

    my ($num_cols,$num_rows) = (undef, undef);
    eval {
	($num_cols,$num_rows) =  Term::ReadKey::GetTerminalSize($term_OUT);
    };
    return unless defined($num_cols) and defined($num_rows);
    $rl_screen_width = $num_cols - $rl_correct_sw
	if defined($num_cols) && $num_cols;
    $rl_margin = int($rl_screen_width/3);
    if (defined $redraw) {
	rl_forced_update_display();
    }

    for my $hook (@winchhooks) {
      eval {&$hook()}; warn $@ if $@ and $^W;
    }
}


sub get_ornaments_selected {
    return if @$rl_term_set >= 6;
    local $^W=0;
    my $Orig = Term::ReadLine::TermCap::ornaments(__PACKAGE__);
    eval {
        # Term::ReadLine does not expose its $terminal, so make another
        require Term::Cap;
        my $terminal = Tgetent Term::Cap ({OSPEED=>9600});
        # and be sure the terminal supports highlighting
        $terminal->Trequire('mr');
    };
    if (!$@ and $Orig ne ',,,'){
        my @set = @$rl_term_set;

        Term::ReadLine::TermCap::ornaments(__PACKAGE__,
                                        join(',',
                                             (split(/,/, $Orig))[0,1])
                                        . ',mr,me') ;
        @set[4,5] = @$rl_term_set[2,3];
        Term::ReadLine::TermCap::ornaments(__PACKAGE__, $Orig);
        @$rl_term_set = @set;
    } else {
        @$rl_term_set[4,5] = @$rl_term_set[2,3];
    }
}

=head3 readline

    &readline::readline($prompt, $default)>

The main routine to call interactively read lines. Parameter
I<$prompt> is the text you want to prompt with If it is empty string,
no preceding prompt text is given. It is I<undef> a default value of
"INPUT> " is used.

Parameter I<$default> is the default value; it can be can be
omitted. The next input line is returned or I<undef> on EOF.

=cut

sub readline($;$)
{
    no warnings 'once';
    $Term::ReadLine::Perl5::term->register_Tk
      if not $Term::ReadLine::registered and $Term::ReadLine::toloop
        and defined &Tk::DoOneEvent;
    if ($stdin_not_tty) {
        local $/ = "\n";
        return undef if !defined($line = <$term_IN>);
        chomp($line);
        return $line;
    }

    $old = select $term_OUT;
    $oldbar = $|;
    local($|) = 1;
    local($input);

    ## prompt should be given to us....
    $prompt = defined($_[0]) ? $_[0] : 'INPUT> ';

    # Try to move cursor to the beginning of the next line if this line
    # contains anything.

    # On DOSish 80-wide console
    #   perl -we "print 1 x shift, qq(\b2\r3); sleep 2" 79
    # prints 3 on the same line,
    #   perl -we "print 1 x shift, qq(\b2\r3); sleep 2" 80
    # on the next; $rl_screen_width is 79.

    # on XTerm one needs to increase the number by 1.

    print $term_OUT ' ' x ($rl_screen_width - !$rl_last_pos_can_backspace) . "\b  \r"
      if $rl_scroll_nextline;

    if ($dumb_term) {
        return Term::ReadLine::Perl5::Dumb::readline($prompt, $term_IN,
						     $term_OUT);
    }

    # test if we resume an 'Operate' command
    if ($rl_OperateCount > 0 && (!defined $_[1] || $_[1] eq '')) {
        ## it's from a valid previous 'Operate' command and
        ## user didn't give a default line
        ## we leave $rl_HistoryIndex untouched
        $line = $rl_History[$rl_HistoryIndex];
    } else {
        ## set history pointer at the end of history
        $rl_HistoryIndex = $#rl_History + 1;
        $rl_OperateCount = 0;
        $line = defined $_[1] ? $_[1] : '';
    }
    $rl_OperateCount-- if $rl_OperateCount > 0;

    $line_for_revert = $line;

# I don't think we need to do this, actually...
#    while (&ioctl(STDIN,$FIONREAD,$fion))
#    {
#       local($n_chars_available) = unpack ($fionread_t, $fion);
#       ## print "n_chars = $n_chars_available\n";
#       last if $n_chars_available == 0;
#       $line .= getc_with_pending;  # should we prepend if $rl_start_default_at_beginning?
#    }

    $D = $rl_start_default_at_beginning ? 0 : length($line); ## set dot.
    $LastCommandKilledText = 0;     ## heck, was no last command.
    $lastcommand = '';              ## Well, there you go.
    $line_rl_mark = -1;

    ##
    ## some stuff for rl_redisplay.
    ##
    $lastredisplay = '';        ## Was no last redisplay for this time.
    $lastlen = length($lastredisplay);
    $lastpromptlen = 0;
    $lastdelta = 0;             ## Cursor was nowhere
    $si = 0;                    ## Want line to start left-justified
    $force_redraw = 1;          ## Want to display with brute force.
    if (!eval {SetTTY()}) {     ## Put into raw mode.
        warn $@ if $@;
        $dumb_term = 1;
        return Term::ReadLine::Perl5::Dumb::readline($prompt, $term_IN,
						     $term_OUT);
    }

    *KeyMap = $var_EditingMode;
    undef($AcceptLine);         ## When set, will return its value.
    undef($ReturnEOF);          ## ...unless this on, then return undef.
    @Pending = ();              ## Contains characters to use as input.
    @undo = ();                 ## Undo history starts empty for each line.
    @undoGroupS = ();           ## Undo groups start empty for each line.
    undef $memorizedArg;        ## No digitArgument memorized
    undef $memorizedPos;        ## No position memorized

    undef $Vi_undo_state;
    undef $Vi_undo_all_state;

    # We need to do some additional initialization for vi mode.
    # RS: bug reports/platform issues are welcome: russ@dvns.com
    if ($KeyMap{'name'} eq 'vi_keymap'){
        &F_ViInput();
        if ($rl_vi_replace_default_on_insert){
            local $^W=0;
            my $Orig = Term::ReadLine::TermCap::ornaments(__PACKAGE__);
           eval {
               # Term::ReadLine does not expose its $terminal, so make another
               require Term::Cap;
               my $terminal = Tgetent Term::Cap ({OSPEED=>9600});
               # and be sure the terminal supports highlighting
               $terminal->Trequire('mr');
           };
           if (!$@ and $Orig ne ',,,'){
               Term::ReadLine::TermCap::ornaments(__PACKAGE__,
                                               join(',',
                                                    (split(/,/, $Orig))[0,1])
                                               . ',mr,me');
        }
            my $F_SelfInsert_Real = \&F_SelfInsert;
            *F_SelfInsert = sub {
                Term::ReadLine::TermCap::ornaments(__PACKAGE__);
                &F_ViChangeEntireLine;
                local $^W=0;
                *F_SelfInsert = $F_SelfInsert_Real;
                &F_SelfInsert;
            };
            my $F_ViEndInsert_Real = \&F_ViEndInsert;
            *F_ViEndInsert = sub {
               Term::ReadLine::TermCap::ornaments(__PACKAGE__, $Orig);
                local $^W=0;
                *F_SelfInsert = $F_SelfInsert_Real;
                *F_ViEndInsert = $F_ViEndInsert_Real;
                &F_ViEndInsert;
               $force_redraw = 1;
               rl_redisplay();
            };
        }
    }

    if ($rl_default_selected) {
        redisplay_high();
    } else {
        ## Show the line (prompt+default at this point).
        rl_redisplay();
    }

    # pretend input if we 'Operate' on more than one line
    &F_OperateAndGetNext($rl_OperateCount) if $rl_OperateCount > 0;

    $rl_first_char = 1;
    while (!defined($AcceptLine)) {
        ## get a character of input
        $input = &getc_with_pending(); # bug in debugger, returns 42. - No more!

        unless (defined $input) {
          # XXX What to do???  Until this is clear, just pretend we got EOF
          $AcceptLine = $ReturnEOF = 1;
          last;
        }
        preserve_state();

        $ThisCommandKilledText = 0;
        ##print "\n\rline is @$D:[$line]\n\r"; ##DEBUG
        my $cmd = get_command($var_EditingMode, ord($input));
        if ( $rl_first_char && $cmd =~ /^F_(SelfInsert$|Yank)/
             && length $line && $rl_default_selected ) {
	    # (Backward)?DeleteChar special-cased in the code.
            $line = '';
            $D = 0;
            $cmd = 'F_BackwardDeleteChar' if $cmd eq 'F_DeleteChar';
        }
        undef $doingNumArg;

	# Execute input
        eval { &$cmd(1, ord($input)); };

        $rl_first_char = 0;
        $lastcommand = $cmd;
        *KeyMap = $var_EditingMode;           # JP: added

        # In Vi command mode, don't position the cursor beyond the last
        #     character of the line buffer.
        &F_BackwardChar(1) if $Vi_mode and $line ne ''
            and &at_end_of_line and $KeyMap{'name'} eq 'vicmd_keymap';

        rl_redisplay();
        $LastCommandKilledText = $ThisCommandKilledText;
    }

    undef @undo; ## Release the memory.
    undef @undoGroupS; ## Release the memory.
    &ResetTTY;   ## Restore the tty state.
    $| = $oldbar;
    select $old;
    return undef if defined($ReturnEOF);
    #print STDOUT "|al=`$AcceptLine'";
    $AcceptLine; ## return the line accepted.
}

sub SetTTY {
    return if $dumb_term || $stdin_not_tty;
    #return system 'stty raw -echo' if defined &DB::DB;
    Term::ReadKey::ReadMode(4, $term_IN);
    if ($^O eq 'MSWin32') {
	# If we reached this, Perl isn't cygwin; Enter sends \r; thus
	# we need binmode XXXX Do we need to undo???  $term_IN is most
	# probably private now...
	binmode $term_IN;
    }
    return 1;
}

sub ResetTTY {
    return if $dumb_term || $stdin_not_tty;
    return Term::ReadKey::ReadMode(0, $term_IN);
}

=head3 substr_with_props

C<substr_with_props($prompt, $string, $from, $len, $ket, $bsel, $esel)>

Gives the I<substr()> of C<$prompt.$string> with embedded face-change
commands.

=cut

sub substr_with_props {
  my ($p, $s, $from, $len, $ket, $bsel, $esel) = @_;
  my $lp = length $p;

  defined $from or $from = 0;
  defined $len or $len = length($p) + length($s) - $from;
  unless (defined $ket) {
    warn 'bug in Term::ReadLine::Perl5, please report to its author';
    $ket = '';
  }
  # We may draw over to put cursor in a correct position:
  $ket = '' if $len < length($p) + length($s) - $from; # Not redrawn

  if ($from >= $lp) {
    $p = '';
    my $start = $from - $lp;
    if ($start < length($s)) {
	$s = substr $s, $start;
	$lp = 0;
    } else {
	return '';
    }
  } else {
    $p = substr $p, $from;
    $lp -= $from;
    $from = 0;
  }
  $s = substr $s, 0, $len - $lp;
  $p =~ s/^(\s*)//; my $bs = $1;
  $p =~ s/(\s*)$//; my $as = $1;
  $p = $rl_term_set->[0] . $p . $rl_term_set->[1] if length $p;
  $p = "$bs$p$as";
  $ket = chop $s if $ket;
  if (defined $bsel and $bsel != $esel) {
    $bsel = $len if $bsel > $len;
    $esel = $len if $esel > $len;
  }
  if (defined $bsel and $bsel != $esel) {
    get_ornaments_selected;
    $bsel -= $lp; $esel -= $lp;
    my ($pre, $sel, $post) =
      (substr($s, 0, $bsel),
       substr($s, $bsel, $esel-$bsel),
       substr($s, $esel));
    $pre  = $rl_term_set->[2] . $pre  . $rl_term_set->[3] if length $pre;
    $sel  = $rl_term_set->[4] . $sel  . $rl_term_set->[5] if length $sel;
    $post = $rl_term_set->[2] . $post . $rl_term_set->[3] if length $post;
    $s = "$pre$sel$post"
  } else {
    $s = $rl_term_set->[2] . $s . $rl_term_set->[3] if length $s;
  }

  if (!$lp) {                   # Should not happen...
    return $s;
  } elsif (!length $s) {        # Should not happen
    return $p;
  } else {                      # Do not underline spaces in the prompt
    return "$p$s"
      . (length $ket ? ($rl_term_set->[0] . $ket . $rl_term_set->[1]) : '');
  }
}

sub redisplay_high {
  get_ornaments_selected();
  @$rl_term_set[2,3,4,5] = @$rl_term_set[4,5,2,3];
  ## Show the line, default inverted.
  rl_redisplay();
  @$rl_term_set[2,3,4,5] = @$rl_term_set[4,5,2,3];
  $force_redraw = 1;
}

=head3 rl_redisplay

B<rl_redisplay()>

Updates the screen to reflect the current value of global C<$line>.

For the purposes of this routine, we prepend the prompt to a local
copy of C<$line> so that we display the prompt as well.  We then
modify it to reflect that some characters have different sizes. That
is, control-C is represented as C<^C>, tabs are expanded, etc.

This routine is somewhat complicated by two-byte characters.... must
make sure never to try do display just half of one.

This is some nasty code.

=cut

sub rl_redisplay()
{
    my ($thislen, $have_bra);
    my($dline) = $prompt . $line;
    local($D) = $D + length($prompt);
    my ($bsel, $esel);
    if (defined pos $line) {
      $bsel = (pos $line) + length $prompt;
    }
    my ($have_ket) = '';

    ##
    ## If the line contains anything that might require special processing
    ## for displaying (such as tabs, control characters, etc.), we will
    ## take care of that now....
    ##
    if ($dline =~ m/[^\x20-\x7e]/)
    {
        local($new, $Dinc, $c) = ('', 0);

        ## Look at each character of $dline in turn.....
        for (my $i = 0; $i < length($dline); $i++) {
            $c = substr($dline, $i, 1);

            ## A tab to expand...
            if ($c eq "\t") {
                $c = ' ' x  (8 - (($i-length($prompt)) % 8));

            ## A control character....
            } elsif ($c =~ tr/\000-\037//) {
                $c = sprintf("^%c", ord($c)+ord('@'));

            ## the delete character....
            } elsif (ord($c) == 127) {
                $c = '^?';
            }
            $new .= $c;

            ## Bump over $D if this char is expanded and left of $D.
            $Dinc += length($c) - 1 if (length($c) > 1 && $i < $D);
            ## Bump over $bsel if this char is expanded and left of $bsel.
            $bsel += length($c) - 1 if (defined $bsel && length($c) > 1 && $i < $bsel);
        }
        $dline = $new;
        $D += $Dinc;
    }

    ##
    ## Now $dline is what we'd like to display (with a prepended prompt)
    ## $D is the position of the cursor on it.
    ##
    ## If it's too long to fit on the line, we must decide what we can fit.
    ##
    ## If we end up moving the screen index ($si) [index of the leftmost
    ## character on the screen], to some place other than the front of the
    ## the line, we'll have to make sure that it's not on the first byte of
    ## a 2-byte character, 'cause we'll be placing a '<' marker there, and
    ## that would screw up the 2-byte character.
    ##
    ## $si is preserved between several displays (if possible).
    ##
    ## Similarly, if the line needs chopped off, we make sure that the
    ## placement of the tailing '>' won't screw up any 2-byte character in
    ## the vicinity.

    # Now $si keeps the value from previous display
    if ($D == length($prompt)   # If prompts fits exactly, show only if need not show trailing '>'
        and length($prompt) < $rl_screen_width - (0 != length $dline)) {
        $si = 0;   ## prefer displaying the whole prompt
    } elsif ($si >= $D) {       # point to the left of what was displayed
        $si = &max(0, $D - $rl_margin);
        $si-- if $si > 0 && $si != length($prompt) && !&OnSecondByte($si);
    } elsif ($si + $rl_screen_width <= $D) { # Point to the right of ...
        $si = &min(length($dline), ($D - $rl_screen_width) + $rl_margin);
        $si-- if $si > 0 && $si != length($prompt) && !&OnSecondByte($si);
    } elsif (length($dline) - $si < $rl_screen_width - $rl_margin and $si) {
        # Too little of the line shown
        $si = &max(0, length($dline) - $rl_screen_width + 3);
        $si-- if $si > 0 && $si != length($prompt) && !&OnSecondByte($si);
    } else {
        ## Fine as-is.... don't need to change $si.
    }
    $have_bra = 1 if $si != 0; # Need the "chopped-off" marker

    $thislen = &min(length($dline) - $si, $rl_screen_width);
    if ($si + $thislen < length($dline)) {
        ## need to place a '>'... make sure to place on first byte.
        $thislen-- if &OnSecondByte($si+$thislen-1);
        substr($dline, $si+$thislen-1,1) = '>';
        $have_ket = 1;
    }

    ##
    ## Now know what to display.
    ## Must get substr($dline, $si, $thislen) on the screen,
    ## with the cursor at $D-$si characters from the left edge.
    ##
    $dline = substr($dline, $si, $thislen);
    $delta = $D - $si;  ## delta is cursor distance from beginning of $dline.
    if (defined $bsel) {        # Highlight the selected part
      $bsel -= $si;
      $esel = $delta;
      ($bsel, $esel) = ($esel, $bsel) if $bsel > $esel;
      $bsel = 0 if $bsel < 0;
      if ($have_ket) {
        $esel = $thislen - 1 if $esel > $thislen - 1;
      } else {
        $esel = $thislen if $esel > $thislen;
      }
    }
    if ($si >= length($prompt)) { # Keep $dline for $lastredisplay...
      $prompt = ($have_bra ? "<" : "");
      $dline = substr $dline, 1 if length($dline); # After prompt
      $bsel = 1 if defined $bsel and $bsel == 0;
    } else {
      $dline = substr($dline, (length $prompt) - $si);
      $prompt = substr($prompt,$si);
      substr($prompt, 0, 1) = '<' if $si > 0;
    }
    # Now $dline is the part after the prompt...

    ##
    ## Now must output $dline, with cursor $delta spaces from left of TTY
    ##

    local ($\, $,) = ('','');

    ##
    ## If $force_redraw is not set, we can attempt to optimize the redisplay
    ## However, if we don't happen to find an easy way to optimize, we just
    ## fall through to the brute-force method of re-drawing the whole line.
    ##
    if (not $force_redraw and not defined $bsel)
    {
        ## can try to optimize here a bit.

        ## For when we only need to move the cursor
        if ($lastredisplay eq $dline and $lastpromptlen == length $prompt) {
            ## If we need to move forward, just overwrite as far as we need.
            if ($lastdelta < $delta) {
                print $term_OUT
                  substr_with_props($prompt, $dline,
                                    $lastdelta, $delta-$lastdelta, $have_ket);
            ## Need to move back.
            } elsif($lastdelta > $delta) {
                ## Two ways to move back... use the fastest. One is to just
                ## backspace the proper amount. The other is to jump to the
                ## the beginning of the line and overwrite from there....
                my $out = substr_with_props($prompt, $dline, 0, $delta, $have_ket);
                if ($lastdelta - $delta <= length $out) {
                    print $term_OUT "\b" x ($lastdelta - $delta);
                } else {
                    print $term_OUT "\r", $out;
                }
            }
            ($lastlen, $lastredisplay, $lastdelta, $lastpromptlen)
              = ($thislen, $dline, $delta, length $prompt);
            # print $term_OUT "\a"; # Debugging
            return;
        }

        ## for when we've just added stuff to the end
        if ($thislen > $lastlen &&
            $lastdelta == $lastlen &&
            $delta == $thislen &&
            $lastpromptlen == length($prompt) &&
            substr($dline, 0, $lastlen - $lastpromptlen) eq $lastredisplay)
        {
            print $term_OUT substr_with_props($prompt, $dline,
                                              $lastdelta, undef, $have_ket);
            # print $term_OUT "\a"; # Debugging
            ($lastlen, $lastredisplay, $lastdelta, $lastpromptlen)
              = ($thislen, $dline, $delta, length $prompt);
            return;
        }

        ## There is much more opportunity for optimizing.....
        ## something to work on later.....
    }

    ##
    ## Brute force method of redisplaying... redraw the whole thing.
    ##

    print $term_OUT "\r", substr_with_props($prompt, $dline, 0, undef, $have_ket, $bsel, $esel);
    my $back = length ($dline) + length ($prompt) - $delta;
    $back += $lastlen - $thislen,
        print $term_OUT ' ' x ($lastlen - $thislen) if $lastlen and $lastlen > $thislen;

    if ($back) {
        my $out = substr_with_props($prompt, $dline, 0, $delta, $have_ket, $bsel, $esel);
        if ($back <= length $out and not defined $bsel) {
            print $term_OUT "\b" x $back;
        } else {
            print $term_OUT "\r", $out;
        }
    }

    ($lastlen, $lastredisplay, $lastdelta, $lastpromptlen)
      = ($thislen, $dline, $delta, length $prompt);

    $force_redraw = 0;
}

=head3 redisplay

B<redisplay>[(I<$prompt>)]

If an argument I<$prompt> is given, it is used instead of the prompt.
Updates the screen to reflect the current value of global C<$line> via
L<rl_redisplay>.
=cut

sub redisplay(;$)
{
    ## local $line has prompt also; take that into account with $D.
    local($prompt) = defined($_[0]) ? $_[0] : $prompt;
    $prompt = '' unless defined($prompt);
    rl_redisplay();

}

sub min($$) { $_[0] < $_[1] ? $_[0] : $_[1]; }

sub getc_with_pending {

    my $key = @Pending ? shift(@Pending) : &$rl_getc;

    # Save keystrokes for vi '.' command
    push(@$Dot_buf, $key) if $Dot_buf;

    $key;
}

=head3 get_command

C<get_command(*keymap, $ord_command_char)>

If the C<*keymap>) has an entry for C<$ord_command_char>, it is returned.
Otherwise, the default command in C<$Keymap{'default'}> is returned if that
exists. If C<$Keymap{'default'}> is false, C<'F_Ding'> is returned.

=cut

sub get_command
{
    local *KeyMap = shift;
    my ($key) = @_;
    my $cmd = defined($KeyMap[$key]) ? $KeyMap[$key]
                                     : ($KeyMap{'default'} || 'F_Ding');
    if (!defined($cmd) || $cmd eq ''){
        warn "internal error (key=$key)";
        $cmd = 'F_Ding';
    }
    $cmd
}

=head3 do_command

C<do_command(*keymap, $numericarg, $key)>

If the C<*keymap> has an entry for C<$key>, it is executed.
Otherwise, the default command for the keymap is executed.

=cut

sub do_command
{
    my ($keymap, $count, $key) = @_;
    my $cmd = get_command($keymap, $key);

    local *KeyMap = $keymap;            # &$cmd may expect it...
    &$cmd($count, $key);
    $lastcommand = $cmd;
}

=head3 savestate

C<savestate()>

Save whatever state we wish to save as an anonymous array.  The only
other function that needs to know about its encoding is
getstate/preserve_state.

=cut

sub savestate
{
    [$D, $si, $LastCommandKilledText, $KillBuffer, $line, @_];
}

=head3 preserve_state

C<preserve_tate()>

=cut

sub preserve_state {
    return if $Vi_mode;
    push(@undo, savestate()), return unless @undo;
    my $last = $undo[-1];
    my @only_movement;
    if ( #$last->[1] == $si and $last->[2] eq $LastCommandKilledText
         # and $last->[3] eq $KillBuffer and
         $last->[4] eq $line ) {
        # Only position changed; remove old only-position-changed records
        pop @undo if $undo[-1]->[5];
        @only_movement = 1;
    }
    push(@undo, savestate(@only_movement));
}

sub remove_selection {
    if ( $rl_first_char && length $line && $rl_default_selected ) {
      $line = '';
      $D = 0;
      return 1;
    }
    if ($rl_delete_selection and defined pos $line and $D != pos $line) {
      kill_text(pos $line, $D);
      return 1;
    }
    return;
}

sub max($$)     { $_[0] > $_[1] ? $_[0] : $_[1]; }
sub isupper($) { ord($_[0]) >= ord('A') && ord($_[0]) <= ord('Z'); }
sub islower($) { ord($_[0]) >= ord('a') && ord($_[0]) <= ord('z'); }

=head3 OnSecondByte

B<OnSecondByte>(I<$index>)

Returns true if the byte at I<$index> into I<$line> is the second byte
of a two-byte character.

=cut

sub OnSecondByte
{
    return 0 if !$_rl_japanese_mb || $_[0] == 0 || $_[0] == length($line);

    die 'internal error' if $_[0] > length($line);

    ##
    ## must start looking from the beginning of the line .... can
    ## have one- and two-byte characters interspersed, so can't tell
    ## without starting from some know location.....
    ##
    for (my $i = 0; $i < $_[0]; $i++) {
        next if ord(substr($line, $i, 1)) < 0x80;
        ## We have the first byte... must bump up $i to skip past the 2nd.
        ## If that one we're skipping past is the index, it should be changed
        ## to point to the first byte of the pair (therefore, decremented).
        return 1 if ++$i == $_[0];
    }
    0; ## seemed to be OK.
}


=head3 CharSize

BC<CharSize>(I<$index>)

Returns the size of the character at the given I<$index> in the
current line.  Most characters are just one byte in length.  However,
if the byte at the index and the one after both have the high bit set
and I<$_rl_japanese_mb> is set, those two bytes are one character of
size two.

Assumes that I<$index> points to the first of a 2-byte char if not
pointing to a 1-byte char.

TODO: handle Unicode

=cut
sub CharSize
{
    my $index = shift;
    return 2 if $_rl_japanese_mb &&
                ord(substr($line, $index,   1)) >= 0x80 &&
                ord(substr($line, $index+1, 1)) >= 0x80;
    1;
}

sub GetTTY
{
    $base_termios = $termios;  # make it long enough
    &ioctl($term_IN,$TCGETS,$base_termios) || die "Can't ioctl TCGETS: $!";
}

sub XonTTY
{
    # I don't know which of these I actually need to do this to, so we'll
    # just cover all bases.

    &ioctl($term_IN,$TCXONC,$TCOON);    # || die "Can't ioctl TCXONC STDIN: $!";
    &ioctl($term_OUT,$TCXONC,$TCOON);   # || die "Can't ioctl TCXONC STDOUT: $!";
}

sub ___SetTTY
{
    if ($DEBUG) {
	print "before ResetTTY\n\r";
	system 'stty -a';
    }

    &XonTTY;

    &GetTTY
        if !defined($base_termios);

    @termios = unpack($termios_t,$base_termios);
    $termios[$TERMIOS_IFLAG] |= $TERMIOS_READLINE_ION;
    $termios[$TERMIOS_IFLAG] &= ~$TERMIOS_READLINE_IOFF;
    $termios[$TERMIOS_OFLAG] |= $TERMIOS_READLINE_OON;
    $termios[$TERMIOS_OFLAG] &= ~$TERMIOS_READLINE_OOFF;
    $termios[$TERMIOS_LFLAG] |= $TERMIOS_READLINE_LON;
    $termios[$TERMIOS_LFLAG] &= ~$TERMIOS_READLINE_LOFF;
    $termios[$TERMIOS_VMIN] = 1;
    $termios[$TERMIOS_VTIME] = 0;
    $termios = pack($termios_t,@termios);
    &ioctl($term_IN,$TCSETS,$termios) || die "Can't ioctl TCSETS: $!";

    if ($DEBUG) {
	print "after ResetTTY\n\r";
	system 'stty -a';
    }
}

sub normal_tty_mode
{
    return if $stdin_not_tty || $dumb_term || !$initialized;
    &XonTTY;
    &GetTTY if !defined($base_termios);
    &ResetTTY;
}

sub ___ResetTTY
{
    if ($DEBUG) {
	print "before ResetTTY\n\r";
	system 'stty -a';
    }

    @termios = unpack($termios_t,$base_termios);
    $termios[$TERMIOS_IFLAG] |= $TERMIOS_NORMAL_ION;
    $termios[$TERMIOS_IFLAG] &= ~$TERMIOS_NORMAL_IOFF;
    $termios[$TERMIOS_OFLAG] |= $TERMIOS_NORMAL_OON;
    $termios[$TERMIOS_OFLAG] &= ~$TERMIOS_NORMAL_OOFF;
    $termios[$TERMIOS_LFLAG] |= $TERMIOS_NORMAL_LON;
    $termios[$TERMIOS_LFLAG] &= ~$TERMIOS_NORMAL_LOFF;
    $termios = pack($termios_t,@termios);
    &ioctl($term_IN,$TCSETS,$termios) || die "Can't ioctl TCSETS: $!";

    if ($DEBUG) {
	print "after ResetTTY\n\r";
	system 'stty -a';
    }
}

=head3 WordBreak

C<WordBreak(index)>

Returns true if the character at I<index> into $line is a basic word
break character, false otherwise.

=cut

sub WordBreak
{
    index($rl_basic_word_break_characters,
	  substr($line,$_[0],1)) != -1;
}

sub getstate
{
    ($D, $si, $LastCommandKilledText, $KillBuffer, $line) = @{$_[0]};
    $ThisCommandKilledText = $LastCommandKilledText;
}

=head3 kill_text

kills from D=$_[0] to $_[1] (to the killbuffer if $_[2] is true)

=cut

sub kill_text
{
    my($from, $to, $save) = (&min($_[0], $_[1]), &max($_[0], $_[1]), $_[2]);
    my $len = $to - $from;
    if ($save) {
        $KillBuffer = '' if !$LastCommandKilledText;
        if ($from < $LastCommandKilledText - 1) {
          $KillBuffer = substr($line, $from, $len) . $KillBuffer;
        } else {
          $KillBuffer .= substr($line, $from, $len);
        }
        $ThisCommandKilledText = 1 + $from;
    }
    substr($line, $from, $len) = '';

    ## adjust $D
    if ($D > $from) {
        $D -= $len;
        $D = $from if $D < $from;
    }
}


=head3 at_end_of_line

Returns true if $D at the end of the line.

=cut

sub at_end_of_line
{
    ($D + &CharSize($D)) == (length($line) + 1);
}

=head3 changecase

     changecase($count, $up_down_caps)

Translated from GNU's I<readline.c>.

If I<$up_down_caps> is 'up' to upcase I<$count> words;
'down' to downcase them, or something else to capitalize them.

If I<$count> is negative, the dot is not moved.

=cut
sub changecase
{
    my $op = $_[1];

    my ($start, $state, $c, $olddot) = ($D, 0);
    if ($_[0] < 0)
    {
        $olddot = $D;
        $_[0] = -$_[0];
    }

    &F_ForwardWord;  ## goes forward $_[0] words.

    while ($start < $D) {
        $c = substr($line, $start, 1);

        if ($op eq 'up') {
            $c = uc $c;
        } elsif ($op eq 'down') {
            $c = lc $c;
        } else { ## must be 'cap'
            if ($state == 1) {
                $c = lc $c;
            } else {
                $c = uc $c;
                $state = 1;
            }
            $state = 0 if $c !~ tr/a-zA-Z//;
        }

        substr($line, $start, 1) = $c;
        $start++;
    }
    $D = $olddot if defined($olddot);
}

=head3 search

    search($position, $string)

Checks if $string is at position I<$rl_History[$position]> and returns
I<$position> if found or -1 if not found.

This is intended to be the called first in a potentially repetitive
search, which is why the unusual return value. See also
L<searchStart>.

=cut

sub search($$) {
  my ($i, $str) = @_;
  return -1 if $i < 0 || $i > $#rl_History;      ## for safety
  while (1) {
    return $i if rindex($rl_History[$i], $str) >= 0;
    if ($reverse) {
      return -1 if $i-- == 0;
    } else {
      return -1 if $i++ == $#rl_History;
    }
  }
}

sub DoSearch
{
    local $reverse = shift;     # Used in search()
    my $oldline = $line;
    my $oldD = $D;
    my $tmp;

    my $searchstr = '';  ## string we're searching for
    my $I = -1;              ## which history line

    $si = 0;

    while (1)
    {
        if ($I != -1) {
            $line = $rl_History[$I];
            $D += index($rl_History[$I], $searchstr);
        }
        redisplay( '('.($reverse?'reverse-':'') ."i-search) `$searchstr': ");

        $c = &getc_with_pending;
        if (($KeyMap[ord($c)] || 0) eq 'F_ReverseSearchHistory') {
            if ($reverse && $I != -1) {
                if ($tmp = &search($I-1,$searchstr), $tmp >= 0) {
                    $I = $tmp;
                } else {
                    &F_Ding;
                }
            }
            $reverse = 1;
        } elsif (($KeyMap[ord($c)] || 0) eq 'F_ForwardSearchHistory') {
            if (!$reverse && $I != -1) {
                if ($tmp = &search($I+1,$searchstr), $tmp >= 0) {
                    $I = $tmp;
                } else {
                    &F_Ding;
                }
            }
            $reverse = 0;
        } elsif ($c eq "\007") {  ## abort search... restore line and return
            $line = $oldline;
            $D = $oldD;
            return;
        } elsif (ord($c) < 32 || ord($c) > 126) {
            push(@Pending, $c) if $c ne "\e";
            if ($I < 0) {
                ## just restore
                $line = $oldline;
                $D = $oldD;
            } else {
                #chose this line
                $line = $rl_History[$I];
                $D = index($rl_History[$I], $searchstr);
            }
            rl_redisplay();
            last;
        } else {
            ## Add this character to the end of the search string and
            ## see if that'll match anything.
            $tmp = &search($I < 0 ? $rl_HistoryIndex-$reverse: $I, $searchstr.$c);
            if ($tmp == -1) {
                &F_Ding;
            } else {
                $searchstr .= $c;
                $I = $tmp;
            }
        }
    }
}

=head3 search

    searchStart($position, $reverse, $string)

I<$reverse> should be either +1, or -1;

Checks if $string is at position I<$rl_History[$position+$reverse]> and
returns I<$position> if found or -1 if not found.

This is intended to be the called first in a potentially repetitive
search, which is why the unusual return value. See also L<search>.

=cut
sub searchStart($$$) {
  my ($i, $reverse, $str) = @_;
  $i += $reverse ? - 1: +1;
  return -1 if $i < 0 || $i > $#rl_History;  ## for safety
  while (1) {
    return $i if index($rl_History[$i], $str) == 0;
    if ($reverse) {
      return -1 if $i-- == 0;
    } else {
      return -1 if $i++ == $#rl_History;
    }
  }
}

sub DoSearchStart
{
    my ($reverse,$what) = @_;
    my $i = searchStart($rl_HistoryIndex, $reverse, $what);
    return if $i == -1;
    $rl_HistoryIndex = $i;
    ($D, $line) = (0, $rl_History[$rl_HistoryIndex]);
    F_BeginningOfLine();
    F_ForwardChar(length($what));

}

###########################################################################
###########################################################################

=head3 TextInsert

C<TextInsert($count, $string)>

=cut

sub TextInsert {
  my $count = shift;
  my $text2add = shift(@_) x $count;
  if ($InsertMode) {
    substr($line,$D,0) .= $text2add;
  } else {
    substr($line,$D,length($text2add)) = $text2add;
  }
  $D += length($text2add);
}

=head3 complete_internal

The meat of command completion. Patterned closely after GNU's.

The supposedly partial word at the cursor is "completed" as per the
single argument:
     "\t"    complete as much of the word as is unambiguous
     "?"     list possibilities.
     "*"     replace word with all possibilities. (who would use this?)

A few notable variables used:
  $rl_completer_word_break_characters
     -- characters in this string break a word.
  $rl_special_prefixes
     -- but if in this string as well, remain part of that word.

Returns true if a completion was done, false otherwise, so vi completion
    routines can test it.

=cut
sub complete_internal

{
    my $what_to_do = shift;
    my ($point, $end) = ($D, $D);

    # In vi mode, complete if the cursor is at the *end* of a word, not
    #     after it.
    ($point++, $end++) if $Vi_mode;

    if ($point)
    {
        ## Not at the beginning of the line; Isolate the word to be completed.
        1 while (--$point && (-1 == index($rl_completer_word_break_characters,
                substr($line, $point, 1))));

        # Either at beginning of line or at a word break.
        # If at a word break (that we don't want to save), skip it.
        $point++ if (
                (index($rl_completer_word_break_characters,
                       substr($line, $point, 1)) != -1) &&
                (index($rl_special_prefixes, substr($line, $point, 1)) == -1)
        );
    }

    my $text = substr($line, $point, $end - $point);
    $rl_completer_terminator_character = ' ';
    my @matches =
	&completion_matches($rl_completion_function,$text,$line,$point);

    if (@matches == 0) {
        return &F_Ding;
    } elsif ($what_to_do eq "\t") {
        my $replacement = shift(@matches);
	$replacement .= $rl_completer_terminator_character
	    if @matches == 1 && !$rl_completion_suppress_append;
        &F_Ding if @matches != 1;
        if ($var_TcshCompleteMode) {
            @tcsh_complete_selections = (@matches, $text);
            $tcsh_complete_start = $point;
            $tcsh_complete_len = length($replacement);
        }
        if ($replacement ne '') {
            substr($line, $point, $end-$point) = $replacement;
            $D = $D - ($end - $point) + length($replacement);
        }
    } elsif ($what_to_do eq '?') {
        shift(@matches); ## remove prepended common prefix
        local $\ = '';
        print $term_OUT "\n\r";
        # print "@matches\n\r";
        &pretty_print_list (@matches);
        $force_redraw = 1;
    } elsif ($what_to_do eq '*') {
        shift(@matches); ## remove common prefix.
        local $" = $rl_completer_terminator_character;
        my $replacement = "@matches$rl_completer_terminator_character";
        substr($line, $point, $end-$point) = $replacement; ## insert all.
        $D = $D - ($end - $point) + length($replacement);
    } else {
        warn "\r\n[Internal error]";
        return &F_Ding;
    }

    1;
}

=head3 use_basic_commands

  use_basic_commands($text, $line, $start);

Used as a completion function by I<&rl_basic_commands>. Return items
from I<@rl_basic_commands> that start with the pattern in I<$text>.

I<$start> should be 0, signifying matching from the beginning of the
line, for this to work. Otherwise we return the empty list.  I<$line>
is ignored, but needs to be there in to match the completion-function
API.

=cut

sub use_basic_commands($$$) {
  my ($text, $line, $start) = @_;
  return () if $start != 0;
  grep(/^$text/, @rl_basic_commands);
}

=head3 completion_matches

   completion_matches(func, text, line, start)

I<func> is a function to call as

   func($text, $line, $start)

where I<$text> is the item to be completed,
I<$line> is the whole command line, and
I<$start> is the starting index of I<$text> in I<$line>.
The function I<$func> should return a list of items that might match.

completion_matches will return that list, with the longest common
prefix prepended as the first item of the list.  Therefore, the list
will either be of zero length (meaning no matches) or of 2 or more.....

=cut
sub completion_matches
{
    my ($func, $text, $line, $start) = @_;

    ## get the raw list
    my @matches;

    #print qq/\r\neval("\@matches = &$func(\$text, \$line, \$start)\n\r/;#DEBUG
    #eval("\@matches = &$func(\$text, \$line, \$start);1") || warn "$@ ";

    @matches = &$func($text, $line, $start);

    ## if anything returned , find the common prefix among them
    if (@matches) {
        my $prefix = $matches[0];
        my $len = length($prefix);
        for (my $i = 1; $i < @matches; $i++) {
            next if substr($matches[$i], 0, $len) eq $prefix;
            $prefix = substr($prefix, 0, --$len);
            last if $len == 0;
            $i--; ## retry this one to see if the shorter one matches.
        }
        unshift(@matches, $prefix); ## make common prefix the first thing.
    }
    @matches;
}

$have_getpwent = eval{
    my @fields = getpwent(); setpwent(); 1;
};

sub rl_tilde_expand($) {
    my $prefix = shift;
    my @matches = ();
    setpwent();
    while (my @fields = (getpwent)[0]) {
	push @matches, $fields[0]
	    if ( $prefix eq ''
		 || $prefix eq substr($fields[0], 0, length($prefix)) );
    }
    setpwent();
    @matches;
}

sub tilde_complete($) {
    my $prefix = shift;
    return $prefix unless $have_getpwent;
    my @names = rl_tilde_expand($prefix);
    if (scalar @names == 1) {
	(getpwnam($names[0]))[7];
    } else {
	map {'~' . $_} @names;
    }
}

=head3 pretty_print_list

Print an array in columns like ls -C.  Originally based on stuff
(lsC2.pl) by utashiro@sran230.sra.co.jp (Kazumasa Utashiro).

See L<Array::Columnize> for a more flexible and more general routine.

=cut

sub pretty_print_list
{
    my @list = @_;
    return unless @list;
    my ($lines, $columns, $mark, $index);

    ## find width of widest entry
    my $maxwidth = 0;
    grep(length > $maxwidth && ($maxwidth = length), @list);
    $maxwidth++;

    $columns = $maxwidth >= $rl_screen_width
               ? 1 : int($rl_screen_width / $maxwidth);

    ## if there's enough margin to interspurse among the columns, do so.
    $maxwidth += int(($rl_screen_width % $maxwidth) / $columns);

    $lines = int((@list + $columns - 1) / $columns);
    $columns-- while ((($lines * $columns) - @list + 1) > $lines);

    $mark = $#list - $lines;
    local $\ = '';
    for ($l = 0; $l < $lines; $l++) {
        for ($index = $l; $index <= $mark; $index += $lines) {
            printf("%-$ {maxwidth}s", $list[$index]);
        }
        print $term_OUT $list[$index] if $index <= $#list;
        print $term_OUT "\n\r";
    }
}

sub start_dot_buf {
    my($count, $ord) = @_;
    $Dot_buf = [pack('c', $ord)];
    unshift(@$Dot_buf, split(//, $count)) if $count > 1;
    $Dot_state = savestate();
}

sub end_dot_buf {
    # We've recognized an editing command

    # Save the command keystrokes for use by '.'
    $Last_vi_command = $Dot_buf;
    undef $Dot_buf;

    # Save the pre-command state for use by 'u' and 'U';
    $Vi_undo_state     = $Dot_state;
    $Vi_undo_all_state = $Dot_state if !$Vi_undo_all_state;

    # Make sure the current line is treated as new line for history purposes.
    $rl_HistoryIndex = $#rl_History + 1;
}

sub save_dot_buf {
    &start_dot_buf(@_);
    &end_dot_buf;
}

sub do_delete {

    my($count, $ord, $poshash) = @_;

    my $other_end = &get_position($count, undef, $ord, $poshash);
    return &F_Ding if !defined $other_end;

    if ($other_end < 0) {
        # dd - delete entire line
        &kill_text(0, length($line), 1);
    }
    else {
        &kill_text($D, $other_end, 1);
    }

    1;    # True return value
}

=head3 get_position

    get_position($count, $ord, $fulline_ord, $poshash)

Interpret vi positioning commands
=cut

sub get_position {
    my ($count, $ord, $fullline_ord, $poshash) = @_;

    # Manipulate a copy of the cursor, not the real thing
    local $D = $D;

    # $ord (first character of positioning command) is an optional argument.
    $ord = ord(&getc_with_pending) if !defined $ord;

    # Detect double character (for full-line operation, e.g. dd)
    return -1 if defined $fullline_ord and $ord == $fullline_ord;

    my $re = $poshash->{$ord};

    if ($re) {
        my $c = pack('c', $ord);
        if (lc($c) eq 'b') {
            &backward_scan($count, $re);
        }
        else {
            &forward_scan($count, $re);
        }
    }
    else {
        # Move the local copy of the cursor
        &do_command($var_EditingMode{'vipos'}, $count, $ord);
    }

    # Return the new cursor (undef if illegal command)
    $D;
}

sub forward_scan {
    my($count, $re) = @_;
    while ($count--) {
        last unless substr($line, $D) =~ m{^($re)};
        $D += length($1);
    }
}

sub backward_scan {
    my($count, $re) = @_;
    while ($count--) {
        last unless substr($line, 0, $D) =~ m{($re)$};
        $D -= length($1);
    }
}

sub get_line_from_history($) {
    my($n) = @_;
    return &F_Ding if $n < 0 or $n > @rl_History;
    return if $n == $rl_HistoryIndex;

    # If we're moving from the currently-edited line, save it for later.
    $line_for_revert = $line if $rl_HistoryIndex == @rl_History;

    # Get line from history buffer (or from saved edit line).
    $line = ($n == @rl_History) ? $line_for_revert : $rl_History[$n];
    $D = $Vi_mode ? 0 : length $line;

    # Subsequent 'U' will bring us back to this point.
    $Vi_undo_all_state = savestate() if $Vi_mode;

    $rl_HistoryIndex = $n;
}

# Redisplay the line, without attempting any optimization
sub rl_forced_update_display() {
    local $force_redraw = 1;
    redisplay(@_);
}

## returns a new $i or -1 if not found.
sub vi_search {
    my ($i) = @_;
    return -1 if $i < 0 || $i > $#rl_History;    ## for safety
    while (1) {
        return $i if $rl_History[$i] =~ /$Vi_search_re/;
        if ($reverse) {
            return -1 if $i-- == 0;
        } else {
            return -1 if $i++ == $#rl_History;
        }
    }
}

sub do_vi_search {
    my $incr = $reverse ? -1 : 1;

    my $i = &vi_search($rl_HistoryIndex + $incr);
    return &F_Ding if $i < 0;                  # Not found.

    $rl_HistoryIndex = $i;
    ($D, $line) = (0, $rl_History[$rl_HistoryIndex]);
}

# Using local $line, $D, and $prompt, get and return the string to
# search for.
sub get_vi_search_str($) {
    my($c) = @_;

    local $prompt = $prompt . $c;
    local ($line, $D) = ('', 0);
    rl_redisplay();

    # Gather a search string in our local $line.
    while ($lastcommand ne 'F_ViEndSearch') {
        &do_command($var_EditingMode{'visearch'}, 1, ord(&getc_with_pending));
        rl_redisplay();

        # We've backspaced past beginning of line
        return undef if !defined $line;
    }
    $line;
}

sub vi_input_mode()
{
    $InsertMode = 1;
    $var_EditingMode = $var_EditingMode{'vi'};
    $Vi_mode = 1;
}

sub clipboard_set($) {
    my $in = shift;
    if ($^O eq 'os2') {
      eval {
        require OS2::Process;
        OS2::Process::ClipbrdText_set($in); # Do not disable \r\n-conversion
        1
      } and return;
    } elsif ($^O eq 'MSWin32') {
      eval {
        require Win32::Clipboard;
        Win32::Clipboard::Set($in);
        1
      } and return;
    }
    my $mess;
    if ($ENV{RL_CLCOPY_CMD}) {
      $mess = "Writing to pipe `$ENV{RL_CLCOPY_CMD}'";
      open COPY, "| $ENV{RL_CLCOPY_CMD}" or warn("$mess: $!"), return;
    } elsif (defined $HOME) {
	my $cutpastefile = File::Spec($HOME, '.rl_cutandpaste');
      $mess = "Writing to file `$cutpastefile'";
      open COPY, "> $cutpastefile" or warn("$mess: $!"), return;
    } else {
      return;
    }
    print COPY $in;
    close COPY or warn("$mess: closing $!");
}

=head3 read_an_init_file

B<read_an_init_file>(I<inputrc_file>, [I<include_depth>])

Reads and executes I<inputrc_file> which does things like Sets input
key bindings in key maps.

If there was a problem return 0.  Otherwise return 1;

=cut

sub read_an_init_file($;$)
{
    my $file = shift;
    my $include_depth = shift or 0;
    my $rc;

    $file = File::Spec->catfile($HOME, $file) unless -f $file;
    return 0 unless open $rc, "< $file";
    local (@action) = ('exec'); ## exec, skip, ignore (until appropriate endnif)
    local (@level) = ();        ## if, else

    local $/ = "\n";
    while (my $line = <$rc>) {
	parse_and_bind($line, $file, $include_depth);
    }
    close($rc);
    return 1;
}

=head1 SEE ALSO

L<Term::ReadLine::Perl5>

=cut
1;
