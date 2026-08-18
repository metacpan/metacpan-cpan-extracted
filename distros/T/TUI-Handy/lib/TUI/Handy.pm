package TUI::Handy;
#
# TUI::Handy - Text-based user interface (ANSI escape only, no external modules)
#
# A tiny form toolkit driven by a plain-text DSL.  You write one text file that
# looks like the screen you want; running it turns that text into an interactive
# keyboard-driven form on the console.  The result is returned as a hash
# reference whose keys are the labels written in the DSL.
#
# Design notes
#   * Pure Perl, no CPAN / no ncurses.  Works on Perl 5.005_03 and later.
#   * Source is US-ASCII; all DSL text (which may be Japanese) is read at run
#     time, so no non-ASCII byte ever appears in this file.
#   * Multibyte (zenkaku) text is handled at the byte level.  UTF-8, Shift_JIS
#     (CP932) and EUC-JP are supported for display-width and character counting.
#   * Two drivers: an ANSI full-screen driver (used when the terminal can be put
#     into cbreak/raw mode via stty) and a portable line-oriented fallback (used
#     on bare Windows cmd.exe where stty is not available).
#
# Usage as a module
#   use TUI::Handy;
#   my $tui  = TUI::Handy->new(dsl => $text);   # or  new(file => $path)
#   $tui->set('Register', sub { my $form = shift; save($form); 0 });  # button
#   $tui->set('Company', 'ACME');                                     # preset
#   my $form = $tui->run;                       # returns a hash reference
#
# Usage as a command
#   perl Handy.pm form.txt                      # runs form.txt, prints results
#
# Install path when used as a module:  lib/TUI/Handy.pm
#
use strict;
use vars qw($VERSION $ENCODING $SAVED_STTY $RAW_ON $SAVED_SIG);

$VERSION = '0.01';

# Default encoding is guessed from the operating system, but may be overridden
# with $TUI::Handy::ENCODING or the TUI_HANDY_ENCODING environment variable.
# Recognised values: 'utf8', 'sjis', 'euc'.
$ENCODING = ($^O =~ /MSWin32/i) ? 'sjis' : 'utf8';
$ENCODING = $ENV{'TUI_HANDY_ENCODING'} if defined $ENV{'TUI_HANDY_ENCODING'};

$SAVED_STTY = '';   # terminal settings saved before entering cbreak mode
$RAW_ON     = 0;    # true while the terminal is in cbreak mode
$SAVED_SIG  = {};   # signal handlers displaced while in cbreak mode

# ANSI escape (single byte 0x1b) - written with \e so the source stays ASCII.
my $E = "\e";

#--------------------------------------------------------------------------
# Low level multibyte helpers
#
# Both routines walk a byte string one character at a time.  The number of
# bytes consumed for each character depends on the encoding.  _width() returns
# the number of terminal columns the string occupies; _chars() splits the
# string into a list of one-character byte strings.
#--------------------------------------------------------------------------

# Return how many bytes the character starting at $o (a lead byte) occupies,
# and how many display columns it uses, for the current encoding.
#
# $b2 and $b3 are the two bytes that follow, or -1 when they are unknown or
# past the end of the string.  They are needed only by the UTF-8 branch, to
# tell half-width katakana apart from the other three-byte characters; a
# caller that wants the byte length alone may leave them out.
sub _char_len {
    my ($o, $enc, $b2, $b3) = @_;
    $b2 = -1 unless defined $b2;
    $b3 = -1 unless defined $b3;
    return (1, 1) if $o < 0x80;                 # plain ASCII
    if ($enc eq 'sjis') {
        return (1, 1) if $o >= 0xa1 && $o <= 0xdf;   # half-width katakana
        return (2, 2);                                # double-byte
    }
    elsif ($enc eq 'euc') {
        return (2, 1) if $o == 0x8e;                  # SS2 half-width katakana
        return (3, 2) if $o == 0x8f;                  # SS3
        return (2, 2);                                # GR double-byte
    }
    else {                                           # utf8
        return (4, 2) if $o >= 0xf0;
        if ($o == 0xef) {
            # Half-width katakana U+FF61-U+FF9F encodes as ef bd a1 - ef bd bf
            # and ef be 80 - ef be 9f.  One column, like its Shift_JIS and
            # EUC-JP counterparts.
            return (3, 1) if $b2 == 0xbd && $b3 >= 0xa1;
            return (3, 1) if $b2 == 0xbe && $b3 >= 0x80 && $b3 <= 0x9f;
        }
        return (3, 2) if $o >= 0xe0;
        return (2, 1) if $o >= 0xc0;                  # 2-byte utf8 (Latin etc.)
        return (1, 1);                                # stray continuation byte
    }
}

# Display width (columns) of a byte string.
sub _width {
    my ($s, $enc) = @_;
    $enc = $ENCODING unless defined $enc;
    my $w = 0;
    my $i = 0;
    my $n = length $s;
    while ($i < $n) {
        my ($bl, $cw) = _char_len(ord(substr($s, $i, 1)), $enc,
                                  ($i + 1 < $n) ? ord(substr($s, $i + 1, 1)) : -1,
                                  ($i + 2 < $n) ? ord(substr($s, $i + 2, 1)) : -1);
        $w += $cw;
        $i += $bl;
    }
    return $w;
}

# Split a byte string into a list of characters (each a 1+ byte string).
sub _chars {
    my ($s, $enc) = @_;
    $enc = $ENCODING unless defined $enc;
    my @out;
    my $i = 0;
    my $n = length $s;
    while ($i < $n) {
        my ($bl, $cw) = _char_len(ord(substr($s, $i, 1)), $enc,
                                  ($i + 1 < $n) ? ord(substr($s, $i + 1, 1)) : -1,
                                  ($i + 2 < $n) ? ord(substr($s, $i + 2, 1)) : -1);
        push @out, substr($s, $i, $bl);
        $i += $bl;
    }
    return @out;
}

# True if the whole string is 7-bit ASCII.
sub _is_ascii {
    my $s = shift;
    return $s =~ /^[\x00-\x7f]*$/ ? 1 : 0;
}

#--------------------------------------------------------------------------
# Constructor
#--------------------------------------------------------------------------
sub new {
    my $class = shift;
    my %arg   = @_;
    my $self  = {
        widgets    => [],    # ordered list of parsed widgets
        focus      => [],    # indices (into widgets) of focusable widgets
        form       => {},    # the value hash returned by run()
        order_keys => [],    # data keys in DSL order (for command-mode dump)
        done       => 0,     # set true to leave the run loop
        aborted    => 0,     # set true when the user pressed ESC
        pressed    => undef, # label of the button that closed the form
    };
    bless $self, $class;

    my $dsl = $arg{'dsl'};
    if (!defined $dsl && defined $arg{'file'}) {
        $dsl = _slurp($arg{'file'});
    }
    $dsl = '' unless defined $dsl;
    $self->_parse($dsl);
    return $self;
}

# Read a whole file using a two-argument open (5.005_03 style).
sub _slurp {
    my $file = shift;
    local *IN;
    open(IN, "<$file") or die "TUI::Handy: cannot open $file: $!\n";
    local $/;
    my $data = <IN>;
    close(IN);
    return $data;
}

#--------------------------------------------------------------------------
# DSL parser
#
# Every line becomes exactly one widget so that the screen and the data
# structure stay in one-to-one correspondence.  The widget kinds are:
#
#   label   plain text / separator line (also serves as a radio group title)
#   text    labelled input box:  Label: [____]  [####]  [$$$$]  [YYYYMMDD] [box]
#   check   checkbox:            [X] Label   or   [ ] Label
#   radio   radio button:        (*) Label   or   ( ) Label
#   button  push button:         [Label]      (bracket only, no label before it)
#--------------------------------------------------------------------------
sub _parse {
    my ($self, $dsl) = @_;
    my @lines = split(/\r?\n/, $dsl, -1);
    # Drop a single trailing empty element produced by a final newline.
    pop @lines if @lines && $lines[-1] eq '';

    my $last_heading = '';   # most recent heading, used as a radio group title
    my $prev_radio   = 0;    # was the previous parsed line a radio button?
    my $cur_group    = '';   # current radio group title

    my $row = 0;
    for my $line (@lines) {
        $row++;
        $line =~ s/\r$//;

        # -- radio button:  (*) label   or   ( ) label -----------------------
        if ($line =~ /^(\s*)\(([ *])\)\s*(\S.*?)\s*$/) {
            my ($pre, $mark, $label) = ($1, $2, $3);
            if (!$prev_radio) {          # any non-radio line starts a new group
                $cur_group = $last_heading;
                $cur_group =~ s/\s*:\s*$//;      # strip a trailing colon
                $cur_group =~ s/^\s+//;
                $cur_group =~ s/\s+$//;
            }
            my $sel = ($mark eq '*') ? 1 : 0;
            $self->_add({
                kind    => 'radio',
                group   => $cur_group,
                label   => $label,
                selected=> $sel,
                pre     => $pre . '(',
                post    => ') ' . $label,
                row     => $row,
                col     => _width($pre) + 1,
            });
            $self->{form}{$cur_group} = $label if $sel;
            $self->_remember_key($cur_group);
            $prev_radio = 1;
            next;
        }
        $prev_radio = 0;

        # -- checkbox:  [X] label   or   [ ] label ---------------------------
        if ($line =~ /^(\s*)\[([ xX])\]\s*(\S.*?)\s*$/) {
            my ($pre, $mark, $label) = ($1, $2, $3);
            my $val = ($mark =~ /[xX]/) ? 1 : 0;
            $self->_add({
                kind  => 'check',
                label => $label,
                value => $val,
                pre   => $pre . '[',
                post  => '] ' . $label,
                row   => $row,
                col   => _width($pre) + 1,
            });
            $self->{form}{$label} = $val;
            $self->_remember_key($label);
            next;
        }

        # -- something in square brackets: text box or button ----------------
        if ($line =~ /^(.*?)\[([^\]]*)\](.*)$/) {
            my ($pre, $inner, $post) = ($1, $2, $3);

            # No label text before the bracket  ->  push button.
            if ($pre =~ /^\s*$/) {
                $self->_add({
                    kind  => 'button',
                    label => $inner,
                    pre   => $pre . '[',
                    post  => ']' . $post,
                    row   => $row,
                    col   => _width($pre) + 1,
                });
                # Buttons default to no handler until the caller registers one.
                $self->{form}{$inner} = undef unless exists $self->{form}{$inner};
                $self->_remember_key($inner);
                next;
            }

            # Labelled bracket  ->  text input box.  Decide the sub-type from
            # the fill characters written between the brackets.
            my $subtype;
            my $just = 'L';
            if    ($inner =~ /^_+$/)        { $subtype = 'hankaku'; }
            elsif ($inner =~ /^\#+$/)       { $subtype = 'num'; $just = 'R'; }
            elsif ($inner =~ /^[\$\\]+$/)   { $subtype = 'cur'; $just = 'R'; }
            elsif ($inner =~ /^%+$/)        { $subtype = 'date'; }
            elsif ($inner =~ /^[YMD]+$/i)   { $subtype = 'date'; }
            elsif (!_is_ascii($inner))      { $subtype = 'zenkaku'; }
            else                            { $subtype = 'hankaku'; }

            my $key = $pre;
            $key =~ s/\s*:\s*$//;   # "Company:" -> "Company"
            $key =~ s/^\s+//;
            $key =~ s/\s+$//;

            my @cells = _chars($inner);   # marker cells -> max input length
            $self->_add({
                kind    => 'text',
                subtype => $subtype,
                key     => $key,
                label   => $key,
                size    => scalar(@cells),   # maximum number of characters
                iw      => _width($inner),   # interior width in columns
                just    => $just,
                chars   => [],               # current value as a list of chars
                caret   => 0,
                pre     => $pre . '[',
                post    => ']' . $post,
                row     => $row,
                col     => _width($pre) + 1,
            });
            $self->{form}{$key} = '';
            $self->_remember_key($key);
            next;
        }

        # -- plain heading / separator line ----------------------------------
        $self->_add({ kind => 'label', text => $line, row => $row });
        if ($line =~ /\S/ && $line !~ /^[\s\-=_.*]+$/) {
            $last_heading = $line;
        }
    }

    # Build the focus ring (every interactive widget, in screen order).
    my $i = 0;
    for my $w (@{$self->{widgets}}) {
        push @{$self->{focus}}, $i
            if $w->{kind} eq 'text'
            || $w->{kind} eq 'check'
            || $w->{kind} eq 'radio'
            || $w->{kind} eq 'button';
        $i++;
    }
    $self->{fi} = 0;   # current position within the focus ring
}

sub _add {
    my ($self, $w) = @_;
    push @{$self->{widgets}}, $w;
}

# Record a data key once, preserving DSL order (used by command-mode output).
sub _remember_key {
    my ($self, $k) = @_;
    return if $self->{_seen}{$k};
    $self->{_seen}{$k} = 1;
    push @{$self->{order_keys}}, $k;
}

#--------------------------------------------------------------------------
# Public helpers
#--------------------------------------------------------------------------

# set(LABEL, VALUE)
#   If VALUE is a code reference it becomes the handler for the button LABEL.
#   Otherwise VALUE presets the value of the text box / checkbox / radio group
#   whose key is LABEL.
sub set {
    my ($self, $key, $val) = @_;
    if (ref($val) eq 'CODE') {
        $self->{form}{$key} = $val;      # button handler
        return $self;
    }
    for my $w (@{$self->{widgets}}) {
        if ($w->{kind} eq 'text' && $w->{key} eq $key) {
            $self->_set_text($w, $val);
            return $self;
        }
        if ($w->{kind} eq 'check' && $w->{label} eq $key) {
            $w->{value} = $val ? 1 : 0;
            $self->{form}{$key} = $w->{value};
            return $self;
        }
    }
    # Radio group preset: select the member whose label matches VALUE.  A
    # value naming no member of an existing group is ignored rather than
    # applied: clearing every button and storing a label that is not on the
    # screen would leave the form in a state the user could not have reached,
    # and the caller would never learn of the typo.
    my $v     = defined($val) ? $val : '';
    my $group = 0;
    my $hit   = 0;
    for my $w (@{$self->{widgets}}) {
        next unless $w->{kind} eq 'radio' && $w->{group} eq $key;
        $group = 1;
        $hit   = 1 if $w->{label} eq $v;
    }
    return $self if $group && !$hit;

    for my $w (@{$self->{widgets}}) {
        if ($w->{kind} eq 'radio' && $w->{group} eq $key) {
            $w->{selected} = ($w->{label} eq $v) ? 1 : 0;
        }
    }
    $self->{form}{$key} = $val;
    return $self;
}

# Return the (live) value hash.
sub form { return $_[0]->{form}; }

# Ask the run loop to finish (may be called from a button handler).
sub close_form { $_[0]->{done} = 1; return; }

# Which button closed the form (undef if closed some other way).
sub pressed { return $_[0]->{pressed}; }

#--------------------------------------------------------------------------
# Value editing (shared by both drivers)
#--------------------------------------------------------------------------

# True if $char is acceptable input for text widget $w.
sub _accept {
    my ($w, $char) = @_;
    my $t = $w->{subtype};
    if ($t eq 'hankaku') {
        return (length($char) == 1 && ord($char) >= 0x20 && ord($char) < 0x7f);
    }
    elsif ($t eq 'zenkaku') {
        return (ord($char) >= 0x80);          # any multibyte character
    }
    else {                                   # num / cur / date
        return ($char =~ /^[0-9]$/) ? 1 : 0;
    }
}

# Replace the whole value of a text widget from a string (used by set() and
# by the line-mode driver).
sub _set_text {
    my ($self, $w, $str) = @_;
    my @c;
    for my $ch (_chars($str)) {
        last if @c >= $w->{size};
        push @c, $ch if _accept($w, $ch);
    }
    $w->{chars} = [ @c ];
    $w->{caret} = scalar(@c);
    $self->{form}{$w->{key}} = join('', @c);
}

# Insert one character at the caret.
sub _insert {
    my ($self, $w, $char) = @_;
    return unless _accept($w, $char);
    return if @{$w->{chars}} >= $w->{size};
    splice(@{$w->{chars}}, $w->{caret}, 0, $char);
    $w->{caret}++;
    $self->{form}{$w->{key}} = join('', @{$w->{chars}});
}

# Delete the character before the caret (Backspace).
sub _backspace {
    my ($self, $w) = @_;
    return if $w->{caret} <= 0;
    splice(@{$w->{chars}}, $w->{caret} - 1, 1);
    $w->{caret}--;
    $self->{form}{$w->{key}} = join('', @{$w->{chars}});
}

# Toggle a checkbox.
sub _toggle {
    my ($self, $w) = @_;
    $w->{value} = $w->{value} ? 0 : 1;
    $self->{form}{$w->{label}} = $w->{value};
}

# Select a radio button (and clear its group siblings).
sub _select_radio {
    my ($self, $w) = @_;
    for my $o (@{$self->{widgets}}) {
        next unless $o->{kind} eq 'radio' && $o->{group} eq $w->{group};
        $o->{selected} = ($o == $w) ? 1 : 0;
    }
    $self->{form}{$w->{group}} = $w->{label};
}

# Fire a button handler.  Returns true if the form should close.
sub _press {
    my ($self, $w) = @_;
    my $h = $self->{form}{$w->{label}};
    if (ref($h) eq 'CODE') {
        my $r = $h->($self->{form}, $self);
        my $closing = ($r || $self->{done}) ? 1 : 0;
        # The press is recorded only when it actually closes the form.  A
        # handler that returns false is saying "stay open", and leaving
        # pressed() set from that attempt would make a later abort look like
        # a successful button press to the caller.
        $self->{pressed} = $closing ? $w->{label} : undef;
        return $closing;
    }
    # No handler registered: treat the press as "submit and close".
    $self->{pressed} = $w->{label};
    return 1;
}

#--------------------------------------------------------------------------
# Rendering (ANSI driver)
#
# _render_frame() returns the whole screen as one string of bytes including
# escape sequences.  Keeping it a pure function makes the layout testable
# without a real terminal.
#--------------------------------------------------------------------------
sub _render_frame {
    my $self = shift;
    # -1 when nothing is focusable (a form of nothing but headings), so that
    # the comparison below is still a comparison of two numbers.
    my $focus_idx = @{$self->{focus}} ? $self->{focus}[$self->{fi}] : -1;
    my $out = $E . "[H";                 # cursor home
    my $cursor = '';                     # trailing cursor placement, if any

    my $i = 0;
    for my $w (@{$self->{widgets}}) {
        my $focused = ($i == $focus_idx) ? 1 : 0;
        my $line;

        if ($w->{kind} eq 'label') {
            $line = defined($w->{text}) ? $w->{text} : '';
        }
        elsif ($w->{kind} eq 'text') {
            my $body = $self->_field_body($w);
            my $inner = $focused ? ($E."[7m".$body.$E."[0m") : $body;
            $line = $w->{pre} . $inner . $w->{post};
            if ($focused) {
                $cursor = $E . "[" . $w->{row} . ";" . $self->_caret_col($w) . "H";
            }
        }
        elsif ($w->{kind} eq 'check') {
            my $mark = $w->{value} ? 'X' : ' ';
            $line = $w->{pre} . $mark . $w->{post};
            $line = $E."[7m".$line.$E."[0m" if $focused;
        }
        elsif ($w->{kind} eq 'radio') {
            my $mark = $w->{selected} ? '*' : ' ';
            $line = $w->{pre} . $mark . $w->{post};
            $line = $E."[7m".$line.$E."[0m" if $focused;
        }
        elsif ($w->{kind} eq 'button') {
            $line = $w->{pre} . $w->{label} . $w->{post};
            $line = $E."[7m".$line.$E."[0m" if $focused;
        }
        else {
            $line = '';
        }

        $out .= $line . $E . "[K\r\n";   # clear rest of line, then newline
        $i++;
    }

    $out .= $E . "[J";                    # clear anything below the form

    # Show the cursor only inside a text box; hide it otherwise.
    if ($cursor ne '') {
        $out .= $cursor . $E . "[?25h";
    }
    else {
        $out .= $E . "[?25l";
    }
    return $out;
}

# Build the padded interior of a text box (exactly iw columns wide).
sub _field_body {
    my ($self, $w) = @_;
    my $val = join('', @{$w->{chars}});
    my $vw  = _width($val);
    my $pad = $w->{iw} - $vw;
    $pad = 0 if $pad < 0;
    my $sp  = ' ' x $pad;
    return ($w->{just} eq 'R') ? ($sp . $val) : ($val . $sp);
}

# Terminal column (1-based) where the edit caret should sit.
sub _caret_col {
    my ($self, $w) = @_;
    my $base = $w->{col} + 1;             # column just after the '['
    if ($w->{just} eq 'R') {
        return $base + $w->{iw} - 1;      # right-justified: sit at the last cell
    }
    my @c = @{$w->{chars}};
    my $off = 0;
    for (my $k = 0; $k < $w->{caret} && $k < @c; $k++) {
        $off += _width($c[$k]);
    }
    return $base + $off;
}

#--------------------------------------------------------------------------
# Focus movement and event handling (shared logic, no I/O)
#--------------------------------------------------------------------------
sub _focus_next { my $s = shift; $s->{fi} = ($s->{fi} + 1) % scalar(@{$s->{focus}}) if @{$s->{focus}}; }
sub _focus_prev { my $s = shift; $s->{fi} = ($s->{fi} - 1) % scalar(@{$s->{focus}}) if @{$s->{focus}}; }

sub _cur_widget {
    my $self = shift;
    return undef unless @{$self->{focus}};
    return $self->{widgets}[ $self->{focus}[$self->{fi}] ];
}

# Handle one event.  $ev is either ['key', NAME] or ['char', BYTES].
sub _handle_event {
    my ($self, $ev) = @_;
    my ($type, $data) = @$ev;

    # ESC is answered before anything else, because it is the way out and a
    # form has to have one even when it holds nothing to focus.  _read_key()
    # also reports end of input as ESC, so this is what stops the run loop
    # when STDIN closes.
    if ($type eq 'key' && $data eq 'ESC') {
        $self->{aborted} = 1;
        $self->{done}    = 1;
        return;
    }

    my $w = $self->_cur_widget;
    return unless $w;

    if ($type eq 'key') {
        if    ($data eq 'TAB'  || $data eq 'DOWN') { $self->_focus_next; return; }
        elsif ($data eq 'STAB' || $data eq 'UP')   { $self->_focus_prev; return; }

        if ($w->{kind} eq 'text') {
            if    ($data eq 'ENTER') { $self->_focus_next; }
            elsif ($data eq 'BS')    { $self->_backspace($w); }
            elsif ($data eq 'LEFT')  {
                if ($w->{just} eq 'R') { $self->_focus_prev; }
                else { $w->{caret}-- if $w->{caret} > 0; }
            }
            elsif ($data eq 'RIGHT') {
                if ($w->{just} eq 'R') { $self->_focus_next; }
                else { $w->{caret}++ if $w->{caret} < @{$w->{chars}}; }
            }
            elsif ($data eq 'HOME') { $w->{caret} = 0; }
            elsif   ($data eq 'END')  { $w->{caret} = scalar(@{$w->{chars}}); }
        }
        elsif ($w->{kind} eq 'check') {
            if    ($data eq 'ENTER') { $self->_toggle($w); }
            elsif ($data eq 'LEFT')  { $self->_focus_prev; }
            elsif ($data eq 'RIGHT') { $self->_focus_next; }
        }
        elsif ($w->{kind} eq 'radio') {
            if    ($data eq 'ENTER') { $self->_select_radio($w); }
            elsif ($data eq 'LEFT')  { $self->_focus_prev; }
            elsif ($data eq 'RIGHT') { $self->_focus_next; }
        }
        elsif ($w->{kind} eq 'button') {
            if    ($data eq 'ENTER') { $self->{done} = 1 if $self->_press($w); }
            elsif ($data eq 'LEFT')  { $self->_focus_prev; }
            elsif ($data eq 'RIGHT') { $self->_focus_next; }
        }
        return;
    }

    # $type eq 'char'
    if ($data eq ' ') {          # Space acts as toggle/select/press off text.
        if    ($w->{kind} eq 'text')   { $self->_insert($w, ' '); }
        elsif ($w->{kind} eq 'check')  { $self->_toggle($w); }
        elsif ($w->{kind} eq 'radio')  { $self->_select_radio($w); }
        elsif ($w->{kind} eq 'button') { $self->{done} = 1 if $self->_press($w); }
        return;
    }
    if ($w->{kind} eq 'text') {
        $self->_insert($w, $data);
    }
}

#--------------------------------------------------------------------------
# Keyboard input (ANSI driver, cbreak mode)
#--------------------------------------------------------------------------

# Try to put the terminal into cbreak mode.  Returns true on success.  Signal
# handling (Ctrl-C) is left enabled on purpose.
sub _raw_on {
    return 0 if $^O =~ /MSWin32/i;             # bare Windows has no stty
    my $saved = `stty -g 2>/dev/null`;
    return 0 unless defined $saved;
    chomp $saved;
    return 0 if $saved eq '';
    $SAVED_STTY = $saved;
    system("stty -icanon -echo min 1 time 0 2>/dev/null");
    $RAW_ON = 1;

    # A signal that is not trapped kills the process outright, without running
    # END blocks, so the clean-up cannot be delegated to one: the terminal
    # would be left in cbreak mode with the cursor hidden, and the user would
    # have to type a blind "stty sane" to get it back.
    $SAVED_SIG = {};
    for my $sig ('INT', 'TERM', 'HUP') {
        $SAVED_SIG->{$sig} = $SIG{$sig};
        $SIG{$sig} = \&_signal_exit;
    }
    return 1;
}

sub _raw_off {
    return unless $RAW_ON;
    system("stty $SAVED_STTY 2>/dev/null") if $SAVED_STTY ne '';
    for my $sig (sort keys %$SAVED_SIG) {
        if (defined $SAVED_SIG->{$sig}) { $SIG{$sig} = $SAVED_SIG->{$sig}; }
        else                            { $SIG{$sig} = 'DEFAULT'; }
    }
    $SAVED_SIG = {};
    $RAW_ON = 0;
}

# Signal handler installed while the terminal is in cbreak mode.  It puts the
# terminal back, then lets the signal do what it was going to do, so the exit
# status still says the process was killed rather than that it ended normally.
sub _signal_exit {
    my $sig = shift;
    _raw_off();
    print STDOUT $E . "[?25h" . $E . "[0m\r\n";
    $SIG{$sig} = 'DEFAULT';
    kill($sig, $$);
    exit(1);            # only reached if the signal is blocked or ignored
}

# Last resort: a die outside run(), or an exit() from a button handler, would
# otherwise leave the terminal in cbreak mode.  A no-op once _raw_off() has
# already run, which is the normal case.
END {
    if ($RAW_ON) {
        print STDOUT $E . "[?25h" . $E . "[0m\r\n";
        _raw_off();
    }
}

# Read exactly one byte from STDIN (blocking).  Returns undef at end of file.
sub _getbyte {
    my $b;
    my $n = sysread(STDIN, $b, 1);
    return (defined $n && $n > 0) ? $b : undef;
}

# Read one byte but give up after a short timeout.  Used to tell a lone ESC
# apart from an escape sequence such as an arrow key.
sub _getbyte_timeout {
    my $rin = '';
    vec($rin, fileno(STDIN), 1) = 1;
    my $ready = select($rin, undef, undef, 0.06);
    return undef if $ready <= 0;
    return _getbyte();
}

# Read one key and return it as ['key', NAME] or ['char', BYTES].
sub _read_key {
    my $self = shift;
    my $c = _getbyte();
    return ['key', 'ESC'] unless defined $c;   # EOF -> treat as abort
    my $o = ord $c;

    if ($o == 0x1b) {                          # ESC or escape sequence
        my $n = _getbyte_timeout();
        return ['key', 'ESC'] unless defined $n;
        if ($n eq '[' || $n eq 'O') {
            my $m = _getbyte();
            return ['key', 'ESC'] unless defined $m;
            return ['key', 'UP']    if $m eq 'A';
            return ['key', 'DOWN']  if $m eq 'B';
            return ['key', 'RIGHT'] if $m eq 'C';
            return ['key', 'LEFT']  if $m eq 'D';
            return ['key', 'HOME']  if $m eq 'H';
            return ['key', 'END']   if $m eq 'F';
            return ['key', 'STAB']  if $m eq 'Z';   # Shift-Tab
            if ($m =~ /[0-9]/) {                     # e.g. ESC [ 3 ~
                my $x;
                do { $x = _getbyte(); } while (defined $x && $x !~ /[~A-Za-z]/);
            }
            return ['key', 'IGN'];
        }
        return ['key', 'ESC'];
    }

    return ['key', 'TAB']   if $o == 0x09;
    return ['key', 'ENTER'] if $o == 0x0d || $o == 0x0a;
    return ['key', 'BS']    if $o == 0x7f || $o == 0x08;
    return ['key', 'IGN']   if $o < 0x20;

    if ($o >= 0x80) {                          # multibyte lead byte
        my ($bl) = _char_len($o, $ENCODING);
        my $rest = '';
        for (my $k = 1; $k < $bl; $k++) {
            my $b = _getbyte();
            last unless defined $b;
            $rest .= $b;
        }
        return ['char', $c . $rest];
    }
    return ['char', $c];                       # ordinary printable ASCII
}

#--------------------------------------------------------------------------
# Run
#--------------------------------------------------------------------------

# Choose a driver and run the form.  Returns the value hash reference.
sub run {
    my $self = shift;
    my $mode = defined $ENV{'TUI_HANDY_MODE'} ? $ENV{'TUI_HANDY_MODE'} : '';
    if ($mode eq 'line') {
        return $self->_run_line;
    }
    if ($mode ne 'ansi' && !_raw_on()) {
        # Could not obtain a raw terminal - fall back to portable line mode.
        return $self->_run_line;
    }
    _raw_on() if $mode eq 'ansi';
    return $self->_run_ansi;
}

sub _run_ansi {
    my $self = shift;
    local $| = 1;
    binmode(STDOUT);
    binmode(STDIN);
    print STDOUT $E . "[2J";                   # clear once at the start

    # Guard so the terminal is always restored, even on die.
    eval {
        while (!$self->{done}) {
            print STDOUT $self->_render_frame;
            my $ev = $self->_read_key;
            $self->_handle_event($ev);
        }
    };
    my $err = $@;

    print STDOUT $E . "[?25h";                  # show cursor
    my $rows = scalar(@{$self->{widgets}});
    print STDOUT $E . "[" . ($rows + 1) . ";1H" . $E . "[0m\r\n";
    _raw_off();
    die $err if $err;
    return $self->{form};
}

#--------------------------------------------------------------------------
# Portable line-oriented driver
#
# Used when no raw terminal is available (typically bare Windows cmd.exe).
# It walks the widgets top to bottom asking for one value per line, so it
# needs neither ANSI support nor single-key input.
#--------------------------------------------------------------------------
sub _run_line {
    my $self = shift;
    local $| = 1;

    # The button list does not change between passes, so it is collected
    # once rather than rebuilt on every walk of the widgets.
    my @buttons = grep { $_->{kind} eq 'button' } @{$self->{widgets}};

    my $pass = 0;
    while (!$self->{done}) {
        $pass++;
        print "\n" if $pass > 1;
        $self->_line_ask_fields;

        last unless @buttons;

        my $w = $self->_line_ask_button(@buttons);
        unless (defined $w) {
            # End of input.  The full-screen driver reaches the same state
            # through ESC, so it is recorded the same way: aborted, with
            # pressed() left undefined.
            $self->{aborted} = 1;
            last;
        }
        last if $self->_press($w);

        # _press() returned false: the handler wants the form to stay open,
        # which is the contract the full-screen driver honours.  The fields
        # are walked again, showing everything already entered as the
        # defaults, so the user retypes only what needs changing.
    }
    return $self->{form};
}

# One walk over the widgets, asking for one value per line.  Values already
# held are offered as defaults, so an empty answer keeps them; that is what
# makes a second pass cheap for the user.
sub _line_ask_fields {
    my $self = shift;

    my %group_done;      # radio groups already asked about

    for my $w (@{$self->{widgets}}) {
        my $k = $w->{kind};

        if ($k eq 'label') {
            print $w->{text}, "\n";

        }
        elsif ($k eq 'text') {
            my $cur = join('', @{$w->{chars}});
            print $w->{label}, " [", $cur, "]: ";
            my $in = <STDIN>;
            if (defined $in) {
                chomp $in; $in =~ s/\r$//;
                $self->_set_text($w, $in) if $in ne '';
            }

        }
        elsif ($k eq 'check') {
            my $cur = $w->{value} ? 'Y' : 'N';
            print "[", $w->{label}, "] (y/n) [", $cur, "]: ";
            my $in = <STDIN>;
            if (defined $in) {
                chomp $in; $in =~ s/\r$//;
                if    ($in =~ /^y/i) { $w->{value} = 1; }
                elsif ($in =~ /^n/i) { $w->{value} = 0; }
                $self->{form}{$w->{label}} = $w->{value};
            }

        }
        elsif ($k eq 'radio') {
            next if $group_done{$w->{group}}++;
            my @members = grep {
                $_->{kind} eq 'radio' && $_->{group} eq $w->{group}
            } @{$self->{widgets}};
            my $n = 0;
            for my $m (@members) {
                $n++;
                my $flag = $m->{selected} ? '*' : ' ';
                print "  ", $n, ") (", $flag, ") ", $m->{label}, "\n";
            }
            print "  choose 1-", $n, ": ";
            my $in = <STDIN>;
            if (defined $in && $in =~ /(\d+)/ && $1 >= 1 && $1 <= $n) {
                $self->_select_radio($members[$1 - 1]);
            }
        }
    }
    return;
}

# Ask which button to press.  Returns the chosen widget, or undef at end of
# input.  A choice outside the range only re-prompts: a typo here must not
# cost the user another walk through every field.
sub _line_ask_button {
    my ($self, @buttons) = @_;

    my $n = scalar(@buttons);
    return undef unless $n;

    while (1) {
        print "\n";
        my $i = 0;
        for my $b (@buttons) {
            $i++;
            print "  ", $i, ") [", $b->{label}, "]\n";
        }
        print "  press 1-", $n, ": ";
        my $in = <STDIN>;
        return undef unless defined $in;
        if ($in =~ /(\d+)/ && $1 >= 1 && $1 <= $n) {
            return $buttons[$1 - 1];
        }
    }
}

#--------------------------------------------------------------------------
# Command-line entry point (modulino)
#--------------------------------------------------------------------------
sub _main {
    my @args = @_;
    my $file = shift @args;
    unless (defined $file) {
        print STDERR "usage: perl Handy.pm FORMFILE\n";
        return 2;
    }
    my $dsl = eval { _slurp($file) };
    if (!defined $dsl) {
        print STDERR $@;
        return 2;
    }
    my $tui  = TUI::Handy->new(dsl => $dsl);
    my $form = $tui->run;

    # Print the collected data as TAB-separated key/value lines.  Button
    # entries (code references or undef) are skipped.
    for my $k (@{$tui->{order_keys}}) {
        my $v = $form->{$k};
        next if ref($v) eq 'CODE';
        next unless defined $v;
        print $k, "\t", $v, "\n";
    }
    print "__pressed__\t", (defined $tui->pressed ? $tui->pressed : ''), "\n";
    return 0;
}

# Run as a command when this file is executed directly; stay quiet when it is
# loaded as a module.
unless (caller()) {
    exit(_main(@ARGV));
}

1;

__END__

=head1 NAME

TUI::Handy - Text-based user interface (ANSI-only form toolkit)

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

As a module:

    use TUI::Handy;

    my $dsl = <<'FORM';
    Customer registration
    Company: [________________________]
    Contact: [______________]
    Qty:     [###]
    Price:   [$$$$$$$$]
    Date:    [YYYYMMDD]
    --------------------------------
    [X] Shipped
    [ ] Stock check

    Payment:
    (*) Cash
    ( ) Transfer
    ( ) Credit
    --------------------------------
    [Register]
    [Quit]
    FORM

    my $tui = TUI::Handy->new(dsl => $dsl);
    $tui->set('Company',  'ACME');                 # preset a value
    $tui->set('Register', sub { my $form = shift; do_save($form); 0 });
    $tui->set('Quit',     sub { 1 });              # true closes the form
    my $form = $tui->run;
    print "Company = $form->{'Company'}\n";

As a command:

    perl Handy.pm form.txt

=head1 DESCRIPTION

TUI::Handy renders a plain-text form definition as an interactive console
form, using nothing but ANSI escape sequences.  It is pure Perl, has no
dependencies at all beyond C<strict> and C<vars>, and runs on Perl 5.005_03
and later.

The form definition is not a description of a screen; it I<is> the screen.
The text you write is drawn as written, and the labels you write become the
keys of the hash that C<run()> returns, so the layout and the data structure
cannot drift apart.  Moving a field one line up is an edit to the text, not
to any code.

=head2 Why this module exists

The Perl ecosystem already offers several ways to build a terminal
interface.  Every one of them is unavailable in the environments this
module targets:

=over 4

=item * Curses and Curses::UI need an XS build and the ncurses library.  A
locked-down server with no compiler, or no ncurses headers, cannot install
them.

=item * Prima and Tk are graphical toolkits and assume a display.

=item * Term::Choose, Term::Menus and friends are pure Perl but present
menus and selection lists; they are not form editors.

=item * Term::ReadLine::Gnu needs XS and the GNU readline library.

=back

TUI::Handy therefore does not compete with Curses::UI; it fills the gap
below it.  The intended situation is a machine where CPAN is unreachable,
no compiler is installed and the perl is whatever shipped with the system:
a plant or in-house server on a closed network, a customer site, a locked
image, a classroom.  Installing TUI::Handy there means copying one file to
C<TUI/Handy.pm> somewhere in C<@INC>.  Nothing is built, nothing is
downloaded, and the same file works on a perl that has not been updated for
twenty years.

The second reason is multibyte text.  Drawing a form that contains
Japanese requires knowing the display width of every character, and
C<Encode> is core only from Perl 5.8.  TUI::Handy computes width and
character boundaries at the byte level for UTF-8, Shift_JIS (CP932) and
EUC-JP, so a Japanese form stays aligned without loading anything.  The
module source itself is US-ASCII; every non-ASCII byte lives in the form
definition, which is read at run time.

=head1 THE FORM DSL

The DSL has no attributes and no syntax beyond what is drawn.

=over 4

=item Heading / separator

Any plain line, drawn as written.  A heading line immediately above a run
of radio buttons also names their group.

=item Text box

C<Label: [____]>.  The characters between the brackets set both the field
width and the field type: C<_> half-width text, a full-width square
full-width text, C<#> numeric (right aligned), C<$> or C<\> currency (right
aligned), C<YYYYMMDD> or C<%> a date.  Input that does not fit the type is
rejected as it is typed, and text longer than the field is clipped.

=item Checkbox

C<[X] Label> / C<[ ] Label>.  Stored as 1 or 0 under C<Label>.

=item Radio button

C<(*) Label> / C<( ) Label>.  Grouped by the preceding heading line, and
stored under that group title as the label of the selected member.

=item Button

C<[Label]> alone on its line.  Its value is a code reference registered
with C<set()>; returning true from the handler closes the form.

=back

=head2 Keys

TAB and Down move to the next field, Shift-TAB and Up to the previous one.
Enter, Space and the arrow keys edit the current field or activate a
button.  ESC aborts the form.

=head1 METHODS

=over 4

=item TUI::Handy-E<gt>new(dsl =E<gt> $text)

=item TUI::Handy-E<gt>new(file =E<gt> $path)

Parse a form definition and return an object.  C<dsl> takes the definition
as a string, C<file> reads it from a file.

=item $tui-E<gt>set($key, $value)

Preset a field, or register a button handler.  A code reference is taken as
a handler for the button named C<$key>; anything else is a value for the
text box, checkbox or radio group named C<$key>.  Returns the object, so
calls chain.

=item $tui-E<gt>run

Run the form and return the value hash reference when it closes.  Keys are
the labels from the definition.  Button entries hold the registered code
reference.

=item $tui-E<gt>form

The same hash reference, live, at any time.  Useful inside a button
handler, which is passed it as its first argument.

=item $tui-E<gt>pressed

The label of the button that closed the form, or C<undef> if the form was
closed some other way (for instance by ESC).

=item $tui-E<gt>close_form

Ask the run loop to finish.  Intended for a button handler that needs to do
something else before the form closes.

=back

A button handler is called with the value hash reference and the object.
Returning true closes the form; returning false leaves it open, which is
how a handler rejects what the user entered without losing any of it.
C<pressed()> is set only by a press that actually closed the form, so a
form abandoned after a rejected press reports C<undef>.  Both drivers
follow this rule.

=head1 ENVIRONMENT

=over 4

=item TUI_HANDY_ENCODING

C<utf8> (the default off Windows), C<sjis> (the default on Windows) or
C<euc>.  It is read once, as the module is loaded, so it has to be set
before C<use TUI::Handy>.  Later on, assign to C<$TUI::Handy::ENCODING>
instead.

=item TUI_HANDY_MODE

Force C<ansi> or C<line> instead of auto-detecting.  It is read by
C<run()>, so it may be set at any point before the form is run.

=back

=head1 EXAMPLES

The C<eg/> directory of the distribution holds runnable examples:

=over 4

=item eg/quickstart.pl

The smallest useful form: three fields and two buttons.

=item eg/setup_wizard.pl

A configuration wizard.  Reads an existing C<key=value> file into the form,
lets the user edit it and writes it back.

=item eg/master_entry.pl

Repeated master-record entry.  Validates each record, appends it to a
tab-separated file and re-opens the form for the next one.

=back

=head1 LIMITATIONS

These are deliberate, and they are the price of the dependency-free design.
If you need what is listed here, Curses::UI is the right tool.

=over 4

=item * One screen.  There is no scrolling, so a form has to fit the
terminal.

=item * Form widgets only: no lists, tables, menus, tabs or sub-windows.

=item * No colour beyond reverse video for the focused widget, and no
mouse support.

=item * A terminal resize during the run is not tracked.

=item * Display width is decided from the encoding of each character rather
than from a Unicode table, because no table can be loaded.  ASCII, the
Japanese full-width ranges and half-width katakana -- the characters these
forms are made of -- come out right in all three encodings.  Under UTF-8,
though, everything else above U+07FF is counted as two columns, so a form
whose labels use narrow characters from that range (dashes and quotation
marks from General Punctuation, arrows, box-drawing) will draw a little
wide.  Shift_JIS and EUC-JP cannot express those characters at all, so this
applies to UTF-8 only.

=item * One key per label.  A label written twice yields two widgets sharing
one hash key, so the second overwrites the first and C<set()> reaches only
the first.  A button whose label repeats the label of a field is the same
collision, and there the button ends up with no entry of its own.  Labels
within a form need to be distinct.

=item * In line mode an empty answer means "keep what is there", which is
what makes a second pass over the fields cheap.  The cost is that a value
already entered cannot be cleared from that driver.

=item * Full-screen ANSI mode needs a terminal that C<stty> can place in
cbreak mode, which covers Linux, the other Unices, macOS, WSL, Cygwin and
Git Bash.  On a bare Windows C<cmd.exe>, where C<stty> is absent and no
external module may be used, TUI::Handy falls back to a portable
line-oriented driver.  The display is plainer -- one prompt per line
instead of a screen -- but the same definition yields the same hash, and
button handlers behave identically: a handler that returns false keeps the
form open there too, and the fields are then walked again with everything
already entered offered as the defaults.

=back

=head1 SEE ALSO

L<Curses::UI> for a full widget toolkit where XS and ncurses are available;
L<Term::Choose> and L<Term::Menus> for selection lists; L<Prima> and L<Tk>
for graphical interfaces.

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt> in a CPAN

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See L<perlartistic>.

This software is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.

=cut
