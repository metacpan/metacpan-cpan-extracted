package Term::Spinner::Color;
use strict;
use warnings;
use 5.010;
use POSIX;
use Time::HiRes qw( sleep );
use Term::ANSIColor;
use Term::Cap;
use utf8;
use open ':std', ':encoding(UTF-8)';

$| = 1;    # Disable buffering on STDOUT.

# Couple of instance vars for colors and frame sets
my @colors = qw( red green yellow blue magenta cyan white );
my %frames = (
  'ascii_propeller' => [qw(/ - \\ |)],
  'ascii_plus'      => [qw(x +)],
  'ascii_blink'     => [qw(o -)],
  'ascii_v'         => [qw(v < ^ >)],
  'ascii_inflate'   => [qw(. o O o)],
  'uni_dots'        => [qw(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)],
  'uni_dots2'       => [qw(⣾ ⣽ ⣻ ⢿ ⡿ ⣟ ⣯ ⣷)],
  'uni_dots3'       => [qw(⣷ ⣯ ⣟ ⡿ ⢿ ⣻ ⣽ ⣾)],
  'uni_dots4'       => [qw(⠋ ⠙ ⠚ ⠞ ⠖ ⠦ ⠴ ⠲ ⠳ ⠓)],
  'uni_dots5'       => [qw(⠄ ⠆ ⠇ ⠋ ⠙ ⠸ ⠰ ⠠ ⠰ ⠸ ⠙ ⠋ ⠇ ⠆)],
  'uni_dots6'       => [qw(⠋ ⠙ ⠚ ⠒ ⠂ ⠂ ⠒ ⠲ ⠴ ⠦ ⠖ ⠒ ⠐ ⠐ ⠒ ⠓ ⠋')],
  'uni_dots7'       => [qw(⠁ ⠉ ⠙ ⠚ ⠒ ⠂ ⠂ ⠒ ⠲ ⠴ ⠤ ⠄ ⠄ ⠤ ⠴ ⠲ ⠒ ⠂ ⠂ ⠒ ⠚ ⠙ ⠉ ⠁)],
  'uni_dots8'       => [qw(⠈ ⠉ ⠋ ⠓ ⠒ ⠐ ⠐ ⠒ ⠖ ⠦ ⠤ ⠠ ⠠ ⠤ ⠦ ⠖ ⠒ ⠐ ⠐ ⠒ ⠓ ⠋ ⠉ ⠈)],
  'uni_dots9' =>
    [qw(⠁ ⠁ ⠉ ⠙ ⠚ ⠒ ⠂ ⠂ ⠒ ⠲ ⠴ ⠤ ⠄ ⠄ ⠤ ⠠ ⠠ ⠤ ⠦ ⠖ ⠒ ⠐ ⠐ ⠒ ⠓ ⠋ ⠉ ⠈ ⠈)],
  'uni_dots10'             => [qw(⢹ ⢺ ⢼ ⣸ ⣇ ⡧ ⡗ ⡏)],
  'uni_dots11'             => [qw(⢄ ⢂ ⢁ ⡁ ⡈ ⡐ ⡠)],
  'uni_dots12'             => [qw(⠁ ⠂ ⠄ ⡀ ⢀ ⠠ ⠐ ⠈)],
  'uni_bounce'             => [qw(⠁ ⠂ ⠄ ⠂)],
  'uni_pipes'              => [qw(┤ ┘ ┴ └ ├ ┌ ┬ ┐)],
  'uni_hippie'             => [qw(☮ ✌ ☺ ♥)],
  'uni_hands'              => [qw(☜ ☝ ☞ ☟)],
  'uni_arrow_rot'          => [qw(➫ ➭ ➬ ➭)],
  'uni_cards'              => [qw(♣ ♤ ♥ ♦)],
  'uni_triangle'           => [qw(◢ ◣ ◤ ◥)],
  'uni_square'             => [qw(◰ ◳ ◲ ◱)],
  'uni_pie'                => [qw(◴ ◷ ◶ ◵)],
  'uni_circle'             => [qw(◐ ◓ ◑ ◒)],
  'uni_qtr_circle'         => [qw(◜ ◝ ◞ ◟)],
  'uni_three_lines'        => [qw(⚞ ☰ ⚟ ☰)],
  'uni_trigram_down'       => [qw(☰ ☱ ☲ ☴)],
  'uni_trigram_bounce'     => [qw(☰ ☱ ☲ ☴ ☰ ☴ ☲ ☱)],
  'uni_count'              => [qw(➀ ➁ ➂ ➃ ➄ ➅ ➆ ➇ ➈ ➉)],
  'uni_ellipsis_propeller' => [qw(⋮ ⋰ ⋯ ⋱)],
  'uni_earth'              => [qw(🌍 🌏 🌎)],
  'uni_moon'               => [qw(🌑 🌘 🌗 🌖 🌕 🌔 🌒)],
  'uni_junk_food'          => [qw(🌭 🌮 🌯 🍔 🍕 🍟)],
  'uni_clapping'           => [qw(👐 👏)],
  'uni_diamonds'           => [qw(🔹 🔷 🔸 🔶)],
  'wide_ascii_prog'        => [
    qw([>----] [=>---] [==>--] [===>-] [====>] [----<] [---<=] [--<==] [-<===] [<====])
  ],
  'wide_ascii_propeller' =>
    [qw([|----] [=/---] [==---] [===\-] [====|] [---\=] [---==] [-/===])],
  'wide_ascii_snek' => [
    qw([>----] [~>---] [~~>--] [~~~>-] [~~~~>] [----<] [---<~] [--<~~] [-<~~~] [<~~~~])
  ],
  'wide_uni_greyscale' => [
    qw(▒▒▒▒▒▒▒ █▒▒▒▒▒▒ ██▒▒▒▒▒ ███▒▒▒▒ ████▒▒▒ █████▒▒ ██████▒ ███████ ██████▒ █████▒▒ ████▒▒▒ ███▒▒▒▒ ██▒▒▒▒▒ █▒▒▒▒▒▒ ▒▒▒▒▒▒▒)
  ],
  'wide_uni_greyscale2' => [
    qw(▒▒▒▒▒▒▒ █▒▒▒▒▒▒ ██▒▒▒▒▒ ███▒▒▒▒ ████▒▒▒ █████▒▒ ██████▒ ███████ ▒██████ ▒▒█████ ▒▒▒████ ▒▒▒▒███ ▒▒▒▒▒██ ▒▒▒▒▒█ ▒▒▒▒▒▒)
  ],
);

sub new {
  my ($class, %args) = @_;
  my $self = {};

  # seq can either be an array ref with a whole set of frames, or can be the
  # name of a frame set.
  if (!defined($args{'seq'})) {
    $self->{'seq'} = $frames{'wide_uni_greyscale2'};
  }
  elsif (ref($args{'seq'}) ne 'ARRAY') {
    $self->{'seq'} = $frames{$args{'seq'}};
  }
  else {
    $self->{'seq'} = $args{'seq'};
  }

  $self->{'delay'}      = $args{'delay'}      || 0.2;
  $self->{'color'}      = $args{'color'}      || 'cyan';
  $self->{'colorcycle'} = $args{'colorcycle'} || 0;
  $self->{'bksp'}       = chr(0x08);
  $self->{'last_size'}  = length($self->{'seq'}[0]);
  return bless $self, $class;
}

sub start {
  my $self = shift;
  print "\x1b[?25l";    # Hide cursor
  $self->{'last_size'} = length($self->{'seq'}[0]);
  print colored("$self->{'seq'}[0]", $self->{'color'});
}

sub next {
  my $self = shift;
  state $pos = 1;

  if ($self->{'colorcycle'}) {
    push @colors, shift @colors;    # rotate the colors list
    $self->{'color'} = $colors[0];
  }

  print $self->{'bksp'} x $self->{'last_size'};
  print colored("$self->{'seq'}[$pos]", $self->{'color'});

  $pos = ++$pos % scalar @{$self->{'seq'}};
  $self->{'last_size'} = length($self->{'seq'}[$pos]);
}

sub done {
  my $self = shift;

  print $self->{'bksp'} x $self->{'last_size'};
  print "\x1b[?25h";    # Show cursor
}

# Fork and run spinner asynchronously, until signal received.
sub auto_start {
  my $self = shift;

  my $ppid = $$;
  my $pid  = fork();
  die("Failed to fork progress indicator.\n") unless defined $pid;

  if ($pid) {           # Parent
    $self->{'child'} = $pid;
    return;
  }
  else {                # Kid stuff
    $self->start();
    my $exists;
    while (1) {
      sleep $self->{'delay'};
      $self->next();

      # Check to be sure parent is still running, if not, die
      $exists = kill 0, $ppid;
      unless ($exists) {
        $self->done();
        exit 0;
      }
      $exists = "";
    }
    exit 0;    # Should never get here?
  }
}

sub auto_done {
  my $self = shift;

  kill 'KILL', $self->{'child'};
  my $pid = wait();
  $self->done();
}

# Run, OK? Does a thing, or a list of things. usually long-running things,
# runs a spinner, and prints a nice status message (check or X, whether
# success or err), when done.
sub run_ok {
  my $self      = shift;
  my $exp       = shift;         # A list of functions to call and wait on.
  my $message   = shift;         # String to print before the spinner
  my $termwidth = `tput cols`;
  $termwidth = 80 unless $termwidth <= 80;
  my $cols = $termwidth - length($message) - $self->{'last_size'} - 1;
  my ($ok, $nok, $meh);
  if ($self->{'last_size'} == 1) {
    $ok  = colored("✔", 'green');
    $nok = colored("✘", 'red');
    $meh = colored("⚠", 'yellow');
  }
  elsif ($self->{'last_size'} == 3) {
    $ok  = colored("[✔]", 'white on_green');
    $nok = colored("[✘]", 'white on_red');
    $meh = colored("[⚠]", 'white on_yellow');
  }
  elsif ($self->{'last_size'} == 5) {
    $ok  = colored("[ ✔ ]", 'white on_green');
    $nok = colored("[ ✘ ]", 'white on_red');
    $meh = colored("[ ⚠ ]", 'white on_yellow');
  }
  else {    # Better be 7, or it'll look goofy, but still work
    $ok  = colored("[  ✔  ]", 'white on_green');
    $nok = colored("[  ✘  ]", 'white on_red');
    $meh = colored("[  ⚠  ]", 'white on_yellow');
  }

  print $message;
  print ' ' x $cols;
  if (ref($exp) eq 'ARRAY') {    # List of expressions
    $self->start();
    foreach my $exp (@{$exp}) {
      $self->next();
      my $res = eval $exp;       ## no critic
      if ($res == 0) {
        $self->done();
        say $nok;
        return 0;
      }
      elsif ($res == 2) {        # Non-fatal error
        $self->done();
        say $meh;
        return 2;
      }
    }
    $self->done();
    say $ok;
  }
  else {                         # Single expression
    $self->auto_start();
    my $res = eval $exp;         ## no critic
    unless ($res) {
      $self->auto_done();
      say $nok;
      return 0;
    }
    $self->auto_done();
    say $ok;
  }
}

# Return list of available frames
sub available_frames {
  my $self = shift;
  return \%frames;
}

sub available_colors {
  my $self = shift;
  return @colors;
}

# ok!
# Call this if you want a nice checkmark after you spinn
sub ok {
  my $self = shift;
  my $ok;
  if ($self->{'last_size'} == 1) {
    $ok = colored("✔", 'green');
  }
  elsif ($self->{'last_size'} == 5) {
    $ok = colored("[ ✔ ]", 'white on_green');
  }
  else {    # Better be 7, or it'll look goofy, but still work
    $ok = colored("[  ✔  ]", 'white on_green');
  }
  say $ok;
}

# meh
# call this to tell use that a non-fatal error occurred. prints a yellow ⚠
sub meh {
  my $self = shift;
  my $meh;
  if ($self->{'last_size'} == 1) {
    $meh = colored("⚠", 'yellow');
  }
  elsif ($self->{'last_size'} == 5) {
    $meh = colored("[ ⚠ ]", 'white on_yellow');
  }
  else {    # Better be 7, or it'll look goofy, but still work
    $meh = colored("[  ⚠  ]", 'white on_yellow');
  }
  say $meh;
}

# nok!
# call this to tell user everything is not ok. prints a red x
sub nok {
  my $self = shift;
  my $nok;
  if ($self->{'last_size'} == 1) {
    $nok = colored("✘", 'red');
  }
  elsif ($self->{'last_size'} == 5) {
    $nok = colored("[ ✘ ]", 'white on_red');
  }
  else {    # Better be 7, or it'll look goofy, but still work
    $nok = colored("[  ✘  ]", 'white on_red');
  }
  say $nok;
}

# Frame length of the first frame of a seq...this won't work if
# if the frames change size, but the rest of the spinnner will
# probably also screw up in that case.
sub frame_length {
  my $self = shift;
  return length($self->{'seq'}[0]);
}

1;

__END__

=pod

=encoding utf8

=for html <a href="https://travis-ci.org/swelljoe/perl-Term-Spinner-Color"><img src="https://travis-ci.org/swelljoe/perl-Term-Spinner-Color.svg?branch=master"></a>

=head1 NAME

Term::Spinner::Color - A terminal spinner/progress bar with
Unicode, color, and no non-core dependencies.

=head1 SYNOPSIS

=begin HTML

<p>
<a href="https://asciinema.org/a/1zzn2t139xdw0m3w9j664dqux?autoplay=1&size=big&t=05"
target="_blank"><img src="https://asciinema.org/a/1zzn2t139xdw0m3w9j664dqux.png" /></a>
</p>

=end HTML

    use utf8;
    use 5.010;
    use Term::Spinner::Color;
    my $spin = Term::Spinner::Color->new(
      seq => ['◑', '◒', '◐', '◓'],
      );
    $spin->start();
    $spin->next() for 1 .. 10;
    $spin->done();

Or, if you want to not worry about ticking the sequence forward with C<next>
you can use the C<auto_start> and C<auto_done> methods instead.

    use utf8;
    use 5.010;
    use Term::Spinner::Color;
    my $spin = Term::Spinner::Color->new(
      'delay' => 0.3,
      'colorcycle' => 1,
      );
    $spin->auto_start();
    sleep 5; # do something slow here
    $spin->auto_done();

=head1 DESCRIPTION

This is a simple spinner, useful when you want to show some kind of activity
during a long-running process of indeterminant length.  It's loosely based
on the API from L<Term::Spinner> and L<Term::Spinner::Lite>.  Unlike
L<Term::Spinner> though, this module doesn't have any dependencies outside
of modules shipped with Perl itself. And, unlike L<Term::Spinner::Lite>, this
module has color support and support for wide progress bars.

This module also provides an asynchronous mode, which does not require your
program to manually call the C<next> method.

Some features and some (Unicode) frame sets do not work in Windows PowerShell
or cmd.exe. If you must work across a wide variety of platforms, choosing
ASCII frame sets is wise. C<run_ok> method currently only provides Unicode
output, so it is not suitable for use on Windows (bash, of many types, on
Windows works fine, however). There's probably a way to fix this by switching
to another code page in Windows shells.

=head1 ATTRIBUTES

=over

=item delay

If used asynchronously, this is how long each tick will last. It uses the
L<Time::HiRes> sleep function, so you can use fractional seconds (0.2 is the
default, and provides a nice smooth animation, generally).

=item seq

Either a ref to an array containing your preferred spin character frames, or
a scalar containing the name of your preferred spin character frames, from
the available defaults. Because it re-draws the whole frame on each tick,
very long frames may be unwieldy over slow connections. Several nice Unicode
and ASCII frame sets are provided.

=item color

If provided, this will be the starting color of the spinner. It uses
L<Term::ANSIColor> color names, and the default is C<cyan>.

=item colorcycle

If set to 1, or any truthy value, the colors will cycle through all seven
of the base ANSI color values changing on each tick of the C<seq>.

=back

=head1 METHODS

=over

=item start

Prints the first frame of the C<seq>. Your cursor should be placed where
you want the spinner to appear before starting. This method hides the
cursor, so if interrupted, it may leave the terminal without a cursor (will
be fixed sometime...).

=item next

Increments the C<seq> and prints the next one. Call this method before or
after each step in your program to show "progress". If you don't want to
increment the indicator manually, you can use C<auto_start> at the beginning
of your long-running step or series of steps.

=item done

Resets the cursor to its original position and makes it visible. Call this
when you are finished running your steps.

=item auto_start

Forks a new autonomous spinner process. It will print a spinner at the
current cursor position until C<auto_done> is called. If your program does
not have many short steps, but instead one or more very long-running ones,
this is likely preferable to the manual ticking process provided by C<start>,
C<next>, and C<done>.

=item auto_done

Call this method to end the current spinner process.

=item run_ok

This is a sort of weird method to eval one expression or a series of
expressions in a list, with a spinner running throughout. At the end,
it prints a Unicode checkmark or X to indicate success or failure.

It currently only works with C<seq> frames with length 1, 5, or 7. Any of the
built-in spinner C<seq> options will work with this method.

It uses eval, so should not be given user-provided data or otherwise
tricky stuff. It has no protections against shooting of feet.

=back

=head1 BUGS

Somewhat spotty on Windows shells (cmd.exe or PowerShell). PowerShell seems
to have ANSI color support, but Unicode doesn't seem to work.

Does not support multiple simultaneous spinners. It does not know how to
find current spinner position or return to it. The program would likely
need to make use of Curses, which is not in core, and is probably even
less likely to work on Windows shells than the stuff I'm already using.

Requires tput for the run_ok method to figure out the term column width.

I have no idea how to write tests for this, so there's only a placeholder
test, and several examples in the examples directory.

=cut
