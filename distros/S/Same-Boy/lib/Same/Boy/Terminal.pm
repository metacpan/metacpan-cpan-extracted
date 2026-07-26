package Same::Boy::Terminal;

use 5.008003;
use strict;
use warnings;
use Object::Proto::Sugar qw(Str is_ro is_rw req);
use Same::Boy;
use POSIX qw(:termios_h);
use Time::HiRes qw(time sleep);
use IO::Select;

our $VERSION = '0.02';

use constant {
    BLK         => "\xe2\x96\x80",   # U+2580 UPPER HALF BLOCK, as UTF-8 bytes
    HOLD_FRAMES => 6,                # frames a tapped button stays pressed
};

my %KEYMAP = (
    "\e[A" => 'up',    "\e[B" => 'down',  "\e[C" => 'right', "\e[D" => 'left',
    w      => 'up',    s      => 'down',  d      => 'right', a      => 'left',
    z      => 'b',     x      => 'a',     ' '    => 'a',
    "\r"   => 'start', "\n"   => 'start', "\\"   => 'select',
);

# ---- configuration -------------------------------------------------------

has rom_path => (is_ro, req, isa => Str);
has scale    => (is_rw, default => 1);
has model    => (is_ro, isa => Str, default => 'cgb');

# ---- derived paths / emulator --------------------------------------------

has sav_path   => (is_ro, lazy => 1, builder => 1);
has state_path => (is_ro, lazy => 1, builder => 1);
has gb         => (is_ro, lazy => 1, builder => 1, predicate => 'has_gb');

sub _build_sav_path   { $_[0]->rom_path . '.sav' }
sub _build_state_path { $_[0]->rom_path . '.state' }

sub _build_gb {
    my ($self) = @_;
    my $gb = Same::Boy->new(model => $self->model, rom => $self->rom_path);
    $gb->set_color_correction('modern_balanced');
    $gb->load_battery_from_file($self->sav_path) if -f $self->sav_path;
    return $gb;
}

# ---- screen geometry -----------------------------------------------------

has width  => (is_ro, lazy => 1, builder => 1);
has height => (is_ro, lazy => 1, builder => 1);
has cols   => (is_ro, lazy => 1, builder => 1);
has rows   => (is_ro, lazy => 1, builder => 1);

sub _build_width  { ($_[0]->gb->dimensions)[0] }
sub _build_height { ($_[0]->gb->dimensions)[1] }
sub _build_cols   { int($_[0]->width  / $_[0]->_scale) }
sub _build_rows   { int($_[0]->height / (2 * $_[0]->_scale)) }

# Scale, clamped to a sane minimum of 1.
sub _scale { my $s = $_[0]->scale; $s < 1 ? 1 : $s }

# ---- terminal state ------------------------------------------------------

has fd          => (is_ro, lazy => 1, builder => 1);
has term        => (is_ro, lazy => 1, builder => 1);
has saved_lflag => (is_ro, lazy => 1, builder => 1);
has saved_iflag => (is_ro, lazy => 1, builder => 1);
has sel         => (is_ro, lazy => 1, builder => 1);

sub _build_fd  { fileno(STDIN) }
sub _build_sel { IO::Select->new(\*STDIN) }

sub _build_term {
    my ($self) = @_;
    my $t = POSIX::Termios->new;
    $t->getattr($self->fd);
    return $t;
}

sub _build_saved_lflag { $_[0]->term->getlflag }
sub _build_saved_iflag { $_[0]->term->getiflag }

# ---- mutable runtime state -----------------------------------------------

has running  => (is_rw, default => 1);
has speed    => (is_rw, default => 1.0);
has hold     => (is_ro, default => sub { +{} });   # button => frames remaining
has msg      => (is_rw, default => '');            # transient status message
has msg_ttl  => (is_rw, default => 0);
has restored => (is_rw, default => 0);             # terminal already restored?
has raw      => (is_rw, default => 0);             # currently in raw mode?

# ---- raw terminal --------------------------------------------------------

sub enter_raw {
    my ($self) = @_;
    my $lflag = $self->saved_lflag;   # capture originals before we mutate
    my $iflag = $self->saved_iflag;

    my $t = POSIX::Termios->new;
    $t->getattr($self->fd);
    $t->setlflag($lflag & ~(ECHO | ICANON));
    $t->setiflag($iflag & ~(IXON));
    $t->setcc(VMIN, 0);
    $t->setcc(VTIME, 0);
    $t->setattr($self->fd, TCSANOW);

    print "\e[?25l\e[2J\e[H";         # hide cursor, clear
    STDOUT->flush;
    $self->raw(1);
    return $self;
}

sub leave_raw {
    my ($self) = @_;
    return $self unless $self->raw;
    $self->raw(0);

    $self->term->setlflag($self->saved_lflag);
    $self->term->setiflag($self->saved_iflag);
    $self->term->setattr($self->fd, TCSANOW);

    print "\e[0m\e[?25h\e[2J\e[H";    # restore colors + cursor, clear
    STDOUT->flush;
    return $self;
}

# ---- persistence ---------------------------------------------------------

# Flush cartridge battery-backed RAM (in-game saves) to ROM.sav. Safe to call
# repeatedly; only writes when the cartridge actually has battery RAM.
sub save_sram {
    my ($self) = @_;
    return unless $self->has_gb;
    my $sram = eval { $self->gb->save_battery };
    return unless defined $sram;
    eval { $self->gb->save_battery_to_file($self->sav_path); 1 };
    return $self;
}

# cleanup() must flush the battery on EVERY exit path (q, Ctrl-C, SIGTERM,
# terminal close) or in-game saves are lost. Idempotent.
sub cleanup {
    my ($self) = @_;
    return if $self->restored;
    $self->restored(1);
    $self->save_sram;
    $self->leave_raw;
    return $self;
}

sub DESTROY { $_[0]->cleanup }

# ---- input ---------------------------------------------------------------

# Show a transient on-screen status message for a short while.
sub flash {
    my ($self, $text) = @_;
    $self->msg($text);
    $self->msg_ttl(120);
    return $self;
}

sub tap {
    my ($self, $btn) = @_;
    my $hold = $self->hold;
    $self->gb->press($btn) unless $hold->{$btn};
    $hold->{$btn} = HOLD_FRAMES;
    return $self;
}

sub handle_input {
    my ($self) = @_;
    return unless $self->sel->can_read(0);
    my $buf = '';
    sysread(STDIN, $buf, 64);
    return unless length $buf;

    while (length $buf) {
        my $key;
        if ($buf =~ /^\e\[[ABCD]/) { $key = substr($buf, 0, 3, '') }
        else                       { $key = substr($buf, 0, 1, '') }

        if (exists $KEYMAP{$key}) { $self->tap($KEYMAP{$key}) }
        elsif ($key eq 'q')       { $self->running(0) }
        elsif ($key eq 'r')       { $self->gb->reset; $self->flash('reset') }
        elsif ($key eq '[')       {
            $self->gb->save_state_to_file($self->state_path);
            $self->flash('state saved -> ' . $self->state_path);
        }
        elsif ($key eq ']')       {
            if (-f $self->state_path) {
                $self->gb->load_state_from_file($self->state_path);
                $self->flash('state loaded');
            }
            else { $self->flash('no save state yet (press [ to save)') }
        }
        elsif ($key eq '=' || $key eq '+') {
            my $speed = $self->speed;
            $speed *= 2 if $speed < 8;
            $self->speed($speed);
            $self->gb->set_clock_multiplier($speed);
            $self->flash("speed ${speed}x");
        }
        elsif ($key eq '-') {
            my $speed = $self->speed;
            $speed /= 2 if $speed > 0.25;
            $self->speed($speed);
            $self->gb->set_clock_multiplier($speed);
            $self->flash("speed ${speed}x");
        }
    }
    return $self;
}

# ---- rendering -----------------------------------------------------------
# Each character cell shows two pixels: the UPPER HALF BLOCK's foreground is
# the top pixel, its background the bottom pixel. Color codes are only emitted
# when they change from the previous cell, keeping the byte volume sane.

sub render {
    my ($self) = @_;
    my $W     = $self->width;
    my $scale = $self->_scale;
    my $cols  = $self->cols;
    my $rows  = $self->rows;

    my @px = unpack 'L*', $self->gb->pixels;
    my $out = "\e[H";
    my ($lfg, $lbg) = (-1, -1);

    for my $cy (0 .. $rows - 1) {
        my $ty   = $cy * 2 * $scale;
        my $by   = $ty + $scale;
        my $trow = $ty * $W;
        my $brow = $by * $W;
        for my $cx (0 .. $cols - 1) {
            my $sx = $cx * $scale;
            my $t  = $px[$trow + $sx] & 0xFFFFFF;
            my $b  = $px[$brow + $sx] & 0xFFFFFF;
            if ($t != $lfg) {
                $out .= sprintf "\e[38;2;%d;%d;%dm",
                    ($t >> 16) & 0xFF, ($t >> 8) & 0xFF, $t & 0xFF;
                $lfg = $t;
            }
            if ($b != $lbg) {
                $out .= sprintf "\e[48;2;%d;%d;%dm",
                    ($b >> 16) & 0xFF, ($b >> 8) & 0xFF, $b & 0xFF;
                $lbg = $b;
            }
            $out .= BLK;
        }
        $out .= "\e[0m\r\n";
        ($lfg, $lbg) = (-1, -1);   # newline resets background state
    }

    # status line: transient message, else the controls legend
    my $status = $self->msg_ttl > 0
        ? '* ' . $self->msg
        : "[=save ]=load  z=B x=A  Enter=Start  \\=Select  -/+ speed  r=reset  q=quit";
    $out .= sprintf "\e[0m\e[2K%.*s\r", $cols > 4 ? $cols : 80, $status;
    syswrite STDOUT, $out;
    return $self;
}

# ---- main loop -----------------------------------------------------------

sub run {
    my ($self) = @_;

    $self->gb;   # build the emulator (loads ROM + battery) up front

    binmode STDOUT, ':raw';
    STDOUT->autoflush(1);
    $self->enter_raw;
    $SIG{$_} = sub { $self->cleanup; exit 0 } for qw(INT TERM HUP);

    my $frame_time = 1 / 60;
    my $frames     = 0;
    while ($self->running) {
        my $t0 = time;

        $self->handle_input;
        $self->gb->run_frame;

        my $hold = $self->hold;
        for my $btn (keys %$hold) {
            if (--$hold->{$btn} <= 0) {
                $self->gb->release($btn);
                delete $hold->{$btn};
            }
        }

        # Safety-net autosave every ~30s so a crash/kill loses little progress.
        $self->save_sram if ++$frames % 1800 == 0;

        $self->msg_ttl($self->msg_ttl - 1) if $self->msg_ttl > 0;
        $self->render;

        my $dt = time - $t0;
        sleep($frame_time - $dt) if $dt < $frame_time;
    }

    my $had_battery = defined $self->gb->save_battery;
    $self->cleanup;   # flushes battery on all exit paths
    return $had_battery;
}

1;

__END__

=head1 NAME

Same::Boy::Terminal - playable truecolor terminal frontend for Same::Boy

=head1 SYNOPSIS

    use Same::Boy::Terminal;

    my $term = Same::Boy::Terminal->new(
        rom_path => 'game.gbc',
        scale    => 1,
        model    => 'cgb',
    );

    my $had_battery = $term->run;
    print "saved battery to ${\ $term->sav_path}\n" if $had_battery;

=head1 DESCRIPTION

Same::Boy::Terminal renders the 160x144 Game Boy screen into a truecolor
terminal using Unicode upper-half-block characters (one cell = two vertically
stacked pixels) and drives L<Same::Boy> from raw-mode keyboard input. It has no
GUI dependencies.

Battery-backed cartridge RAM is loaded from C<< <rom_path>.sav >> at start and
flushed back on every exit path (quit, Ctrl-C, SIGTERM, terminal close). Save
states are written to and read from C<< <rom_path>.state >>.

A truecolor terminal is required; a wide one (>= 160 columns) for C<scale> 1,
or use C<< scale => 2 >> (80 columns).

=head1 ATTRIBUTES

=head2 rom_path

Path to the ROM to load. Required.

=head2 scale

Integer downscale factor for the display (default C<1>). Values below C<1> are
treated as C<1>.

=head2 model

Game Boy model passed to L<Same::Boy> (default C<cgb>).

=head2 sav_path / state_path

Derived from C<rom_path> (C<.sav> and C<.state> suffixes).

=head1 METHODS

=head2 run

Enter raw mode and run the emulator loop until the user quits. Restores the
terminal and flushes battery RAM on exit. Returns true if the cartridge had
battery-backed RAM.

=head2 Controls

    Arrow keys / WASD .. D-pad        z .. B        x / space .. A
    Enter .. Start                    \ .. Select
    [ .. save state   ] .. load state
    - / = .. slower / faster          r .. reset     q .. quit

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
