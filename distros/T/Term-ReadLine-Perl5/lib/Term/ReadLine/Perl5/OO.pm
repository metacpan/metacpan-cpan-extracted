package Term::ReadLine::Perl5::OO;
use 5.008005;
use strict; use warnings;
use POSIX qw(termios_h);
use Storable;
use Text::VisualWidth::PP 0.03 qw(vwidth);
use Unicode::EastAsianWidth::Detect qw(is_cjk_lang);
use Term::ReadKey qw(GetTerminalSize ReadLine ReadKey ReadMode);
use IO::Handle;
use English;

eval "use rlib '.' ";  # rlib is now optional
use Term::ReadLine::Perl5::OO::History;
use Term::ReadLine::Perl5::OO::Keymap;
use Term::ReadLine::Perl5::OO::State;
use Term::ReadLine::Perl5::Common;
use Term::ReadLine::Perl5::readline;
use Term::ReadLine::Perl5::TermCap;

our $VERSION = "0.43";

use constant HISTORY_NEXT => +1;
use constant HISTORY_PREV => -1;

my $IS_WIN32 = $^O eq 'MSWin32';
require Win32::Console::ANSI if $IS_WIN32;

use Class::Accessor::Lite 0.05 (
    rw => [qw(completion_callback rl_MaxHistorySize)],
);

use constant {
    CTRL_B => 2,
    CTRL_C => 3,
    CTRL_F => 6,
    CTRL_H => 8,
    CTRL_Z => 26,
    BACKSPACE => 127,
    ENTER => 13,
    TAB => 9,
    ESC => 27,
};

no warnings 'once';
*add_history     = \&Term::ReadLine::Perl5::OO::History::add_history;
*read_history    = \&Term::ReadLine::Perl5::OO::History::read_history;
*write_history   = \&Term::ReadLine::Perl5::OO::History::write_history;
use warnings 'once';

my %attribs = (
    stiflehistory => 1,
    getHistory    => 1,
    addHistory    => 1,
    attribs       => 1,
    appname       => 1,
    autohistory   => 1,
    readHistory   => 1,
    setHistory    => 1
    );

my %features = (
    appname => 1,       # "new" is recognized
    minline => 1,       # we have a working MinLine()
    autohistory => 1,   # lines are put into history automatically,
		                     # subject to MinLine()
    getHistory => 1,    # we have a working getHistory()
    setHistory => 1,    # we have a working setHistory()
    addHistory => 1,    # we have a working add_history(), addhistory(),
                                     # or addHistory()
    attribs => 1,
    stiflehistory => 1, # we have stifle_history()
    );


sub Attribs  { \%attribs; }
sub Features { \%features; }

our @EmacsKeymap = ();

=head3 new

B<new>([I<%options>])

returns the handle for subsequent calls to following functions.
Argument is the name of the application.

=cut

sub new {
    my $class = shift;
    my %args = @_==1? %{$_[0]} : @_;
    my $keymap;
    my $editMode = $args{'editMode'} || 'emacs';
    if ($editMode eq 'vicmd') {
	$keymap = Term::ReadLine::Perl5::OO::Keymap::ViKeymap();
    } else {
	$keymap = Term::ReadLine::Perl5::OO::Keymap::EmacsKeymap();
    }

    my $self = bless {
	char                 => undef, # last character
	current_keymap       => $keymap,
	toplevel_keymap      => $keymap,
	debug                => !!$ENV{CAROLINE_DEBUG},
	history_base         => 0,
	history_stifled      => 0,
	minlength            => 1,
	multi_line           => 1,
	rl_HistoryIndex      => 0,  # Is set on use
	rl_MaxHistorySize    => 100,
	rl_history_length    => 0,  # is set on use
	rl_max_input_history => 0,
	state                => undef, # line buffer and its state
        rl_History           => [],
	rl_term_set          => \@Term::ReadLine::TermCap::rl_term_set,
	editMode             => $editMode,
        %args
    }, $class;
    return $self;
}

sub debug {
    my ($self, $stuff) = @_;
    return unless $self->{debug};

#   require JSON::PP;
    open my $fh, '>>:utf8', 'readline-oo.debug.log';
    print $fh $stuff;
#   print $fh JSON::PP->new->allow_nonref(1)->encode($stuff) . "\n";
    close $fh;
}

sub is_supported($) {
    my $self = shift;
    return 1 if $IS_WIN32;
    my $term = $ENV{'TERM'};
    return 0 unless defined $term;
    return 0 if $term eq 'dumb';
    return 0 if $term eq 'cons25';
    return 1;
}

#### FIXME redo this history stuff:
sub history($) { shift->{rl_History} }

sub history_len($) {
    shift->{rl_history_length};
}

sub refresh_line {
    my ($self, $state) = @_;
    if ($self->{multi_line}) {
        $self->refresh_multi_line($state);
    } else {
        $self->refresh_single_line($state);
    }
}

sub refresh_multi_line {
    my ($self, $state) = @_;

    my $plen = vwidth($state->prompt);
    $self->debug($state->buf . "\n");

    # rows used by current buf
    my $rows = int(($plen + vwidth($state->buf) + $state->cols -1) / $state->cols);
    if (defined $state->query) {
        $rows++;
    }

    # cursor relative row
    my $rpos = int(($plen + $state->oldpos + $state->cols) / $state->cols);

    my $old_rows = $state->maxrows;

    # update maxrows if needed.
    if ($rows > $state->maxrows) {
        $state->maxrows($rows);
    }

    $self->debug(sprintf "[%d %d %d] p: %d, rows: %d, rpos: %d, max: %d, oldmax: %d",
                $state->len, $state->pos, $state->oldpos, $plen, $rows, $rpos, $state->maxrows, $old_rows);

    # First step: clear all the lines used before. To do start by going to the last row.
    if ($old_rows - $rpos > 0) {
        $self->debug(sprintf ", go down %d", $old_rows-$rpos);
        printf STDOUT "\x1b[%dB", $old_rows-$rpos;
    }

    # Now for every row clear it, go up.
    my $j;
    for ($j=0; $j < ($old_rows-1); ++$j) {
        $self->debug(sprintf ", clear+up %d %d", $old_rows-1, $j);
        print("\x1b[0G\x1b[0K\x1b[1A");
    }

    # Clean the top line
    $self->debug(", clear");
    print("\x1b[0G\x1b[0K");

    # Write the prompt and the current buffer content
    print $state->prompt;
    print $state->buf;
    if (defined $state->query) {
        print "\015\nSearch: " . $state->query;
    }

    # If we are at the very end of the screen with our prompt, we need to
    # emit a newline and move the prompt to the first column
    if ($state->pos && $state->pos == $state->len && ($state->pos + $plen) % $state->cols == 0) {
        $self->debug("<newline>");
        print "\n";
        print "\x1b[0G";
        $rows++;
        if ($rows > $state->maxrows) {
            $state->maxrows(int $rows);
        }
    }

    # Move cursor to right position
    my $rpos2 = int(($plen + $state->vpos + $state->cols) / $state->cols); # current cursor relative row
    $self->debug(sprintf ", rpos2 %d", $rpos2);
    # Go up till we reach the expected position
    if ($rows - $rpos2 > 0) {
        # cursor up
        printf "\x1b[%dA", $rows-$rpos2;
    }

    # Set column
    my $col;
    {
        $col = 1;
        my $buf = $state->prompt . substr($state->buf, 0, $state->pos);
        for (split //, $buf) {
            $col += vwidth($_);
            if ($col > $state->cols) {
                $col -= $state->cols;
            }
        }
    }
    $self->debug(sprintf ", set col %d", $col);
    printf "\x1b[%dG", $col;

    $state->oldpos($state->pos);

    $self->debug("\n");
}


# Show the line, default inverted.
sub redisplay_inverted($$) {
    my ($self, $line) = @_;

    # FIXME: fixup from readline::redisplay_high
    # get_ornaments_selected();
    # @$rl_term_set[2,3,4,5] = @$rl_term_set[4,5,2,3];

    # Show the line, default inverted.
    print STDOUT $line;

    # FIXME: fixup from readline::redisplay_high
    # @$rl_term_set[2,3,4,5] = @$rl_term_set[4,5,2,3];
}

sub refresh_single_line($$) {
    my ($self, $state) = @_;

    my $buf = $state->buf;
    my $len = $state->len;
    my $pos = $state->pos;
    while ((vwidth($state->prompt)+$pos) >= $state->cols) {
        substr($buf, 0, 1) = '';
        $len--;
        $pos--;
    }
    while (vwidth($state->prompt) + vwidth($buf) > $state->cols) {
        $len--;
    }

    print STDOUT "\x1b[0G"; # cursor to left edge
    $self->redisplay_high($self->{prompt});
    print STDOUT $buf;
    print STDOUT "\x1b[0K"; # erase to right

    # Move cursor to original position
    printf "\x1b[0G\x1b[%dC", (
        length($state->{prompt})
        + vwidth(substr($buf, 0, $pos))
    );
}

sub edit_insert {
    my ($self, $state, $c) = @_;
    if (length($state->buf) == $state->pos) {
        $state->{buf} .= $c;
    } else {
        substr($state->{buf}, $state->{pos}, 0) = $c;
    }
    $state->{pos}++;
    $self->refresh_line($state);
}

sub edit_delete_prev_word {
    my ($self, $state) = @_;

    my $old_pos = $state->pos;
    while ($state->pos > 0 && substr($state->buf, $state->pos-1, 1) eq ' ') {
        $state->{pos}--;
    }
    while ($state->pos > 0 && substr($state->buf, $state->pos-1, 1) ne ' ') {
        $state->{pos}--;
    }
    my $diff = $old_pos - $state->pos;
    substr($state->{buf}, $state->pos, $diff) = '';
    $self->refresh_line($state);
}

sub edit_history($$$) {
    my ($self, $state, $dir) = @_;
    my $hist_len = $self->{rl_history_length};
    if ($hist_len > 0) {
        $self->{rl_HistoryIndex} += $dir ;
        if ($self->{rl_HistoryIndex} <= 0) {
	    $self->F_Ding();
            $self->{rl_HistoryIndex} = 1;
            return;
        } elsif ($self->{rl_HistoryIndex} > $hist_len) {
	    $self->F_Ding();
            $self->{rl_HistoryIndex} = $hist_len;
            return;
        }
        $state->{buf} = $self->{rl_History}->[$self->{rl_HistoryIndex}-1];
        $state->{pos} = $state->len;
        $self->refresh_line($state);
    }
}

########################################

sub F_AcceptLine($) {
    my $self = shift;
    my $buf = $self->{state}->buf;
    Term::ReadLine::Perl5::OO::History::add_history($self, $buf);
    return (1, $buf);
}

sub F_BackwardChar($) {
    my $self = shift;
    my $state = $self->{state};
    if ($state->pos > 0) {
        $state->{pos}--;
        $self->refresh_line($state);
    }
    return undef, undef;
}

sub F_BackwardDeleteChar($) {
    my $self = shift;
    my $state = $self->{state};
    if ($state->pos > 0 && length($state->buf) > 0) {
        substr($state->{buf}, $state->pos-1, 1) = '';
        $state->{pos}--;
        $self->refresh_line($state);
    }
    return undef, undef;
}

sub F_BeginningOfLine($)
{
    my $self  = shift;
    my $state = $self->{state};
    $state->{pos} = 0;
    $self->refresh_line($state);
    return undef, undef;
}

sub F_ClearScreen($) {
    my $self = shift;
    my $state = $self->{state};
    print STDOUT "\x1b[H\x1b[2J";
    return undef, undef;
    $self->refresh_line($state);
}

sub F_DeleteChar($) {
    my $self  = shift;
    my $state = $self->{state};
    if (length($state->buf) > 0) {
	$self->edit_delete($state);
    }
    return undef, undef;
}

sub F_EndOfLine($)
{
    my $self  = shift;
    my $state = $self->{state};
    $state->{pos} = length($state->buf);
    $self->refresh_line($state);
    return undef, undef;
}

sub F_Ding($) {
    my $self = shift;
    Term::ReadLine::Perl5::Common::F_Ding(*STDERR);
    return undef, undef;
}

sub F_ForwardChar($) {
    my $self = shift;
    my $state = $self->{state};
    if ($state->pos != length($state->buf)) {
        $state->{pos}++;
        $self->refresh_line($state);
    }
    return undef, undef;
}

sub F_Interrupt() {
    my $self = shift;
    $self->{sigint}++;
    return undef, undef;
}

sub F_KillLine($)
{
    my $self  = shift;
    my $state = $self->{state};
    substr($state->{buf}, $state->{pos}) = '';
    $self->refresh_line($state);
    return undef, undef;
}

sub F_NextHistory($) {
    my $self  = shift;
    my $state = $self->{state};
    $self->edit_history($state, HISTORY_NEXT);
    return undef, undef;
}

##
## Execute the next character input as a command in a meta keymap.
##
sub F_PrefixMeta
{
    my $self  = shift;
    my $cc    = ord($self->{char});
    $self->{current_keymap} = $self->{function}[$cc]->[1];
    return undef, undef;
}

sub F_PreviousHistory($) {
    my $self  = shift;
    my $state = $self->{state};
    $self->edit_history($state, HISTORY_PREV);
    return undef, undef;
}

sub F_ReverseSearchHistory($) {
    my $self  = shift;
    my $state = $self->{state};
    $self->search($state);
    return undef, undef;
}

sub F_SelfInsert($)
{
    my $self  = shift;
    my $state = $self->{state};
    my $c     = $self->{char};
    $self->debug("inserting ord($c)\n");
    $self->edit_insert($state, $c);
    # tuple[0] == '' signals not to eval function again
    return '', undef;
}

sub F_Suspend($)
{
    my $self  = shift;
    my $state = $self->{state};
    $self->{sigtstp}++;
    return 1, $state->buf;
}

# swaps current character with previous
sub F_TransposeChars($) {
    my $self = shift;
    my $state = $self->{state};
    if ($state->pos > 0 && $state->pos < $state->len) {
	my $aux = substr($state->buf, $state->pos-1, 1);
	substr($state->{buf}, $state->pos-1, 1) = substr($state->{buf}, $state->pos, 1);
	substr($state->{buf}, $state->pos, 1) = $aux;
	if ($state->pos != $state->len -1) {
	    $state->{pos}++;
	}
    }
    $self->refresh_line($state);
    return undef, undef;
}

sub F_UnixLineDiscard($)
{
    my $self      = shift;
    my $state     = $self->{state};
    $state->{buf} = '';
    $state->{pos} = 0;
    $self->refresh_line($state);
    return undef, undef;
}

sub F_UnixRubout($)
{
    my $self      = shift;
    my $state     = $self->{state};
    $self->edit_delete_prev_word($state);
    return undef, undef;
}

########################################

sub DESTROY {
    shift->disable_raw_mode();
    Term::ReadLine::Perl5::readline::ResetTTY;
}

sub readline {
    my ($self, $prompt) = @_;
    $prompt = '> ' unless defined $prompt;
    STDOUT->autoflush(1);

    local $Text::VisualWidth::PP::EastAsian = is_cjk_lang;

    if ($self->is_supported && -t STDIN) {
        return $self->read_raw($prompt);
    } else {
        print STDOUT $prompt;
        STDOUT->flush;
        # I need to use ReadLine() to support Win32.
        my $line = ReadLine(0);
        $line =~ s/\n$// if defined $line;
        return $line;
    }
}

sub get_columns {
    my $self = shift;
    my ($wchar, $hchar, $wpixels, $hpixels) = GetTerminalSize();
    return $wchar;
}

sub readkey {
    my $self = shift;
    my $c = ReadKey(0);
    return undef unless defined $c;
    return $c unless $IS_WIN32;

    # Win32 API always return the bytes encoded with ACP. So it must be
    # decoded from double byte sequence. To detect double byte sequence, it
    # use Win32 API IsDBCSLeadByte.
    require Win32::API;
    require Encode;
    require Term::Encoding;
    $self->{isleadbyte} ||= Win32::API->new(
      'kernel32', 'int IsDBCSLeadByte(char a)',
    );
    $self->{encoding} ||= Term::Encoding::get_encoding();
    if ($self->{isleadbyte}->Call($c)) {
        $c .= ReadKey(0);
        $c = Encode::decode($self->{encoding}, $c);
    }
    $c;
}

# linenoiseRaw
sub read_raw {
    my ($self, $prompt) = @_;

    local $self->{sigint};
    local $self->{sigtstp};
    my $ret;
    {
        $self->enable_raw_mode();
        $ret = $self->edit($prompt);
        $self->disable_raw_mode();
    }
    print STDOUT "\n";
    STDOUT->flush;
    if ($self->{sigint}) {
        kill 'INT', $$;
    } elsif ($self->{sigtstp}) {
        kill $IS_WIN32 ? 'INT' : 'TSTP', $$;
    }
    return $ret;
}

sub enable_raw_mode {
    my $self = shift;

    if ($IS_WIN32) {
        ReadMode(5);
        return undef;
    }
    my $termios = POSIX::Termios->new;
    $termios->getattr(0);
    $self->{rawmode} = [$termios->getiflag, $termios->getoflag, $termios->getcflag, $termios->getlflag, $termios->getcc(VMIN), $termios->getcc(VTIME)];
    $termios->setiflag($termios->getiflag & ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON));
    $termios->setoflag($termios->getoflag & ~(OPOST));
    $termios->setcflag($termios->getcflag | ~(CS8));
    $termios->setlflag($termios->getlflag & ~(ECHO|ICANON|IEXTEN | ISIG));
    $termios->setcc(VMIN, 1);
    $termios->setcc(VTIME, 0);
    $termios->setattr(0, TCSAFLUSH);
    return undef;
}

sub disable_raw_mode {
    my $self = shift;

    if ($IS_WIN32) {
        ReadMode(0);
        return undef;
    }
    if (my $r = delete $self->{rawmode}) {
        my $termios = POSIX::Termios->new;
        $termios->getattr(0);
        $termios->setiflag($r->[0]);
        $termios->setoflag($r->[1]);
        $termios->setcflag($r->[2]);
        $termios->setlflag($r->[3]);
        $termios->setcc(VMIN, $r->[4]);
        $termios->setcc(VTIME, $r->[5]);
        $termios->setattr(0, TCSAFLUSH);
    }
    return undef;
}

sub lookup_key($)
{
    my ($self, $cc) = @_;
    my $tuple = $self->{current_keymap}{function}->[$cc];
    return $tuple if $tuple && defined($tuple->[0]);
    my $fn_raw = $self->{current_keymap}{default};
    my $fn = "F_${fn_raw}()";
    print "+++", $fn, "\n";
    my($done, $retval);
    my $cmd = "(\$done, \$retval) = \$self->$fn";
    # print $cmd, "\n";
    eval($cmd);
    return [$done, $retval];
}

sub edit {
    my ($self, $prompt) = @_;
    print STDOUT $prompt;
    STDOUT->flush;

    my $state = Term::ReadLine::Perl5::OO::State->new;
    $state->{prompt} = $prompt;
    $state->cols($self->get_columns);
    $self->debug("Columns: $state->{cols}\n");
    $self->{state} = $state;

    while (1) {
        my $c = $self->readkey;
        unless (defined $c) {
            return $state->buf;
        }
        my $cc = ord($c) or next;

        if ($cc == TAB && defined $self->{completion_callback}) {
            $c = $self->complete_line($state);
            return undef unless defined $c;
            $cc = ord($c);
            next if $cc == 0;
        }

	$self->{char} = $c;
	my $tuple = $self->lookup_key($cc);
	if ($tuple && $tuple->[0] ) {
	    my $fn = sprintf "F_%s()", $tuple->[0];
	    my($done, $retval);
	    ###### DEBUG ######
	    # if ($fn eq 'F_PrefixMeta()') {
	    # 	print "+++ Switching keymap\n";
	    # 	$self->{current_keymap} = $tuple->[1];
	    # 	next;
	    # }
	    my $cmd = "(\$done, \$retval) = \$self->$fn";
	    # use Data::Printer;
	    # print "+++ cmd:\n$cmd\n";
	    # p $tuple;
	    eval($cmd);
	    return $retval if $done;
	} else {
	    # print "+++ Back to top\n";
	    $self->{current_keymap} = $self->{toplevel_keymap}
	}

	# FIXME: When doing keymap lookup, I need a way to note that
	# we want a return rather than to continue editing.
        if ($cc == ESC) { # escape sequence
            # Read the next two bytes representing the escape sequence
            my $buf = $self->readkey or return undef;
            $buf .= $self->readkey or return undef;

            if ($buf eq "[D") { # left arrow
                $self->F_BackwardChar($state);
            } elsif ($buf eq "[C") { # right arrow
                $self->F_ForwardChar($state);
            } elsif ($buf eq "[A") { # up arrow
                $self->F_PreviousHistory($state);
            } elsif ($buf eq "[B") { # down arrow
                $self->F_NextHistory($state);
            } elsif ($buf eq "[1") { # home
                $buf = $self->readkey or return undef;
                if ($buf eq '~') {
                    $state->{pos} = 0;
                    $self->refresh_line($state);
                }
            } elsif ($buf eq "[4") { # end
                $buf = $self->readkey or return undef;
                if ($buf eq '~') {
                    $state->{pos} = length($state->buf);
                    $self->refresh_line($state);
                }
            }
            # TODO:
#           else if (seq[0] == 91 && seq[1] > 48 && seq[1] < 55) {
#               /* extended escape, read additional two bytes. */
#               if (read(fd,seq2,2) == -1) break;
#               if (seq[1] == 51 && seq2[0] == 126) {
#                   /* Delete key. */
#                   linenoiseEditDelete(&l);
#               }
#           }
        }
    }
    return $state->buf;
}

sub edit_delete {
    my ($self, $status) = @_;
    if ($status->len > 0 && $status->pos < $status->len) {
        substr($status->{buf}, $status->pos, 1) = '';
        $self->refresh_line($status);
    }
}

sub search {
    my ($self, $state) = @_;

    my $query = '';
    local $state->{query} = '';
    LOOP:
    while (1) {
        my $c = $self->readkey;
        unless (defined $c) {
            return $state->buf;
        }
        my $cc = ord($c) or next;

        if (
            $cc == CTRL_B
            || $cc == CTRL_C
            || $cc == CTRL_F
            || $cc == ENTER
        ) {
            return;
        }
        if ($cc == BACKSPACE || $cc == CTRL_H) {
            $self->debug("ctrl-h in searching\n");
            $query =~ s/.\z//;
        } else {
            $query .= $c;
        }
        $self->debug("C: $cc\n");

        $state->query($query);
        $self->debug("Searching '$query'\n");
        SEARCH:
        for my $hist (@{$self->history}) {
            if ((my $idx = index($hist, $query)) >= 0) {
                $state->buf($hist);
                $state->pos($idx);
                $self->refresh_line($state);
                next LOOP;
            }
        }
        $self->F_Ding();
        $self->refresh_line($state);
    }
}

sub complete_line {
    my ($self, $state) = @_;

    my @ret = grep { defined $_ } $self->{completion_callback}->($state->buf);
    unless (@ret) {
        $self->F_Ding();
        return "\0";
    }

    my $i = 0;
    while (1) {
        # Show completion or original buffer
        if ($i < @ret) {
            my $cloned = Storable::dclone($state);
            $cloned->{buf} = $ret[$i];
            $cloned->{pos} = length($cloned->{buf});
            $self->refresh_line($cloned);
        } else {
            $self->refresh_line($state);
        }

        my $c = $self->readkey;
        unless (defined $c) {
            return undef;
        }
        my $cc = ord($c) or next;

        if ($cc == TAB) { # tab
            $i = ($i+1) % (1+@ret);
            if ($i==@ret) {
                $self->F_Ding();
            }
        } elsif ($cc == ESC) { # escape
            # Re-show original buffer
            if ($i<@ret) {
                $self->refresh_line($state);
            }
            return $c;
        } else {
            # Update buffer and return
            if ($i<@ret) {
                $state->{buf} = $ret[$i];
                $state->{pos} = length($state->{buf});
            }
            return $c;
        }
    }
}

unless (caller()) {
    my $c = __PACKAGE__->new;
    if (@ARGV) {
	while (defined(my $line = $c->readline($ARGV[0] .'> '))) {
	    if ($line =~ /\S/) {
		print eval $line, "\n";
	    }
	}
    }
}

sub MinLine($;$) {
    my $self = $_[0];
    my $old = $self->{minlength};
    $self->{minlength} = $_[1] if @_ == 2;
    return $old;
}

1;
__END__

=for stopwords binmode

=encoding utf-8

=head1 NAME

Term::ReadLine::Perl5::OO - OO version of L<Term::ReadLine::Perl5>

=head1 SYNOPSIS

    use Term::ReadLine::Perl5::OO;

    my $c = Term::ReadLine::Perl5::OO->new;
    while (defined(my $line = $c->readline('> '))) {
        if ($line =~ /\S/) {
            print eval $line;
        }
    }

=head1 DESCRIPTION

An Object-Oriented GNU Readline line editing library like
L<Term::ReadLine::Perl5>.

This module

=over 4

=item has History handling

=item has programmable command Completion

=item is Portable

=item has no C library dependency

=back

Nested keymap is not fully supported yet.

=head1 METHODS

=head2 new

   my $term = Term::ReadLine::Perl5::OO->new();

Create new Term::ReadLine::Perl5::OO instance.

Options are:

=over 4

=item completion_callback : CodeRef

You can write completion callback function like this:

    use Term::ReadLine::Perl5::OO;
    my $c = Term::ReadLine::Perl5::OO->new(
        completion_callback => sub {
            my ($line) = @_;
            if ($line eq 'h') {
                return (
                    'hello',
                    'hello there'
                );
            } elsif ($line eq 'm') {
                return (
                    '突然のmattn'
                );
            }
            return;
        },
    );

=back

=head2 read

   my $line = $term->read($prompt);

Read line with C<$prompt>.

Trailing newline is removed. Returns undef on EOF.

=head2 history

   $term->history()

Get the current history data in C< ArrayRef[Str] >.

=head2 write_history

   $term->write_history($filename)

Write history data to the file.

=head2 read_history

   $term->read_history($filename)

Read history data from history file.

=head1 Multi byte character support

If you want to support multi byte characters, you need to set binmode to STDIN.
You can add the following code before call I<Term::ReadLine::Perl5::OO>

    use Term::Encoding qw(term_encoding);
    my $encoding = term_encoding();
    binmode *STDIN, ":encoding(${encoding})";

=head1 About east Asian ambiguous width characters

I<Term::ReadLine::Perl5::OO> detects east Asian ambiguous character
width from environment variable using
L<Unicode::EastAsianWidth::Detect>.

User need to set locale correctly. For more details, please read L<Unicode::EastAsianWidth::Detect>.

=head1 LICENSE

Copyright (C) tokuhirom.
Copyright (C) Rocky Bernstein.


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item *

L<Caroline>, the Perl package from which this is dervied

=item *

L<https://github.com/antirez/linenoise/blob/master/linenoise.c>, the C
code from which L<Caroline> is derived

=back

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>
mattn

Extended and rewritten to make more compatible with GNU ReadLine and
I<Term::ReadLine::Perl5> by Rocky Bernstein

=cut
