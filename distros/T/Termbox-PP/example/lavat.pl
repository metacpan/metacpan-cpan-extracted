#!perl
use 5.010;
use strict;
use warnings;

use version;
our $VERSION = version->declare("v2.1.0");

use Config;
use Data::Dumper;
use Getopt::Long;
Getopt::Long::Configure qw(
  bundling
  no_ignore_case
);
use Pod::Usage;
use Time::HiRes qw( usleep );

use constant RANDBITS => $Config{randbits};
use constant RAND_MAX => 2**RANDBITS;

use lib '../lib', 'lib';
use Termbox::PP;
use Termbox qw( :all );

use constant MIN_NBALLS => 5;
use constant MAX_NBALLS => 20;

use constant Ball => {
  x => 0,
  y => 0,
  dx => 0,
  dy => 0,
};

my $custom;
my $custom2;
my $color = TB_WHITE;
my $color2 = TB_WHITE;
my $party = 0;
my $nballs = 10;
my $speedMult = 5;
my $rim = 1;
my $contained = 0;
my $radiusIn = 100.0;
my $radius = 0;
my $margin = 0;
my $sumConst = 0;
my $sumConst2 = 0;
my ($maxX, $maxY) = (0,0);
my $speed = 0;
my @balls = map{ {%{Ball()}} } 1..MAX_NBALLS;
my $event = Termbox::Event->new();
my @colors = (TB_WHITE, TB_RED, TB_YELLOW, TB_BLUE, TB_GREEN, TB_MAGENTA, 
  TB_CYAN, TB_BLACK);

sub init_params;
sub event_handler;
sub parse_options;
sub print_help;
sub next_color;
sub fix_rim_color;
sub set_random_colors;

sub main { # $ ($, @)
  my ($argc, @argv) = @_;

  return 0
    if !parse_options($argc, @argv);

  # my @balls = { %{Ball} } x $nballs;

  srand(time());

  tb_init();
  tb_set_input_mode(TB_INPUT_ESC);

  tb_hide_cursor();

  init_params();

  while (1) {

    # move balls
    for (my $i = 0; $i < $nballs; $i++) {

      if ( $balls[$i]->{x} + $balls[$i]->{dx} >= $maxX - $margin 
        || $balls[$i]->{x} + $balls[$i]->{dx} < $margin
      ) {
        $balls[$i]->{dx} *= -1;
      }

      if ( $balls[$i]->{y} + $balls[$i]->{dy} >= $maxY - $margin 
        || $balls[$i]->{y} + $balls[$i]->{dy} < $margin
      ) {
        $balls[$i]->{dy} *= -1;
      }

      $balls[$i]->{x} += $balls[$i]->{dx};
      $balls[$i]->{y} += $balls[$i]->{dy};
    }

    # render
    for (my $i = 0; $i < $maxX; $i++) {
      for (my $j = 0; $j < int($maxY / 2); $j++) {
        # calculate the two halfs of the block at the same time
        my @sum = (0,0);

        for (my $j2 = 0; $j2 < (!$custom ? 2 : 1); $j2++) {

          for (my $k = 0; $k < $nballs; $k++) {
            my $y = $j * 2 + $j2;
            $sum[$j2] += ($radius * $radius) /
                         (($i - $balls[$k]->{x}) * ($i - $balls[$k]->{x}) +
                          ($y - $balls[$k]->{y}) * ($y - $balls[$k]->{y}) ||1);
          }
        }

        if (!$custom) {
          if ($sum[0] > $sumConst) {
            if ($sum[1] > $sumConst) {
              # Full block
              tb_printf($i, $j, $color2, 0, "\N{U+2588}");
            } else {
              # Upper half block
              tb_printf($i, $j, $color2, 0, "\N{U+2580}");
            }
          } elsif ($sum[1] > $sumConst) {
            # Lower half block
            tb_printf($i, $j, $color2, 0, "\N{U+2584}");
          }

          if ($rim) {
            if ($sum[0] > $sumConst2) {
              if ($sum[1] > $sumConst2) {
                # Full block
                tb_printf($i, $j, $color, 0, "\N{U+2588}");
              } else {
                # Lower half block
                tb_printf($i, $j, $color2, $color, "\N{U+2584}");
              }
            } elsif ($sum[1] > $sumConst2) {
              # Upper half block
              tb_printf($i, $j, $color2, $color, "\N{U+2580}");
            }
          }
        } else {
          if ($sum[0] > $sumConst) {
            tb_printf($i, $j, $color2, 0, $custom2);
          }

          if ($rim) {
            if ($sum[0] > $sumConst2) {
              tb_printf($i, $j, $color, 0, $custom);
            }
          }
        }
      }
    }
    if ($party > 0) {
      set_random_colors($party);
    }
    tb_present();
    usleep($speed);
    tb_clear();

    tb_peek_event($event, 10);

    event_handler();
  }
  tb_shutdown();

  # @balls = ();
  return 0;
}

sub event_handler { # void ()
  if ($event->{type} == TB_EVENT_RESIZE) {
    do {
      tb_peek_event($event, 10);
    } while ($event->{type} == TB_EVENT_RESIZE);

    init_params();
  } elsif ($event->{type} == TB_EVENT_KEY) {

    if ($event->{key} == TB_KEY_CTRL_C || $event->{key} == TB_KEY_ESC) {
      tb_shutdown();
      exit(0);
    }

    switch: for ($event->{ch}) {
      case: ord('-') == $_
      ||    ord('_') == $_ and do {
        if ($speedMult < 10) {
          $speedMult++;
          $speed = (((1 / ($maxX + $maxY)) * 1000000) + 10000) * $speedMult;
        }
        last;
      };
      case: ord('+') == $_
      ||    ord('=') == $_ and do {
        if ($speedMult > 1) {
          $speedMult--;
          $speed = (((1 / ($maxX + $maxY)) * 1000000) + 10000) * $speedMult;
        }
        last;
      };
      case: ord('m') == $_
      ||    ord('M') == $_ and do {
        if ($nballs + 1 <= MAX_NBALLS) {
          $nballs++;
        }
        last;
      };
      case: ord('l') == $_
      ||    ord('L') == $_ and do {
        if ($nballs - 1 >= MIN_NBALLS) {
          $nballs--;
        }
        last;
      };
      case: ord('i') == $_ and do {
        if ($radiusIn + 10 <= 150) {
          $radiusIn += 10;
          $radius = ($radiusIn * $radiusIn + $maxX * $maxY) / 15000;
          $margin = $contained ? $radius * 10 : 0;
        }
        last;
      };
      case: ord('d') == $_ and do {
        if ($radiusIn - 10 >= 50) {
          $radiusIn -= 10;
          $radius = ($radiusIn * $radiusIn + $maxX * $maxY) / 15000;
          $margin = $contained ? $radius * 10 : 0;
        }
        last;
      };
      case: ord('I') == $_ and do {
        if ($color != TB_WHITE || $custom) {
          if ($rim + 1 <= 5) {
            $rim++;
            $sumConst2 = $sumConst * (1 + 0.25 * $rim);
          }
        }
        last;
      };
      case: ord('D') == $_ and do {
        if ($color != TB_WHITE || $custom) {
          if ($rim - 1 >= 0) {
            $rim--;
            $sumConst2 = $sumConst * (1 + 0.25 * $rim);
          }
        }
        last;
      };
      case: ord('c') == $_ and do {
        $color = next_color($color);
        fix_rim_color();
        last;
      };
      case: ord('k') == $_ and do {
        $color2 = next_color($color2);
        fix_rim_color();
        last;
      };
      case: ord('p') == $_ and do {
        $party = ($party + 1) % 4;
        last;
      };
      case: ord('q') == $_
      ||    ord('Q') == $_ and do {
        tb_shutdown();
        exit(0);
      };
    }
  }
  return;
}

sub init_params { # void ()

  $maxX = tb_width();
  $maxY = tb_height() * 2;
  $speedMult = 11 - $speedMult;
  $speed = (((1 / ($maxX + $maxY)) * 1000000) + 10000) * $speedMult;
  $radius = ($radiusIn * $radiusIn + $maxX * $maxY) / 15000;

  $margin = $contained ? $radius * 10 : 0;

  $sumConst = 0.0225;
  $sumConst2 = $sumConst * (1 + 0.25 * $rim);

  $custom2 = $custom;

  if ($color2 == TB_WHITE || !$rim) {
    $color2 = $color | TB_BRIGHT;
  }
  if (defined($custom) && length($custom) > 1 && $rim) {
    $custom2 = substr($custom, 1);
  }

  for (my $i = 0; $i < MAX_NBALLS; $i++) {
    $balls[$i]->{x} = rand(RAND_MAX) % ($maxX - 2 * $margin) + $margin;
    $balls[$i]->{y} = rand(RAND_MAX) % ($maxY - 2 * $margin) + $margin;
    $balls[$i]->{dx} = rand(RAND_MAX) % 2 == 0 ? -1 : 1;
    $balls[$i]->{dy} = rand(RAND_MAX) % 2 == 0 ? -1 : 1;
  }
  return;
}

sub next_color { # $ ($)
  my ($current) = @_;
  for (my $i = 0; $i < 8; $i++) {
    if ($current == $colors[$i] || $current == ($colors[$i] | TB_BRIGHT )) {
      return $colors[($i+1) % 8];
    }
  }
  return $current;
}

sub fix_rim_color { # void ()
  if ($color2 == $color) {
    $color2 |= $color2;
  }
  return;
}

sub set_random_colors() { # void ($)
  my ($level) = @_;
  $color = $colors[rand(RAND_MAX) % 7] if $level == 1 || $level == 3;
  $color2 = $colors[rand(RAND_MAX) % 7] if $level == 2 || $level == 3; 
  fix_rim_color();
  return;
}

sub set_color { # $ (\$, $)
  my ($var, $optarg) = @_;

  if ($optarg eq "red") {
    $$var = TB_RED;
  } elsif ($optarg eq "yellow") {
    $$var = TB_YELLOW;
  } elsif ($optarg eq "blue") {
    $$var = TB_BLUE;
  } elsif ($optarg eq "green") {
    $$var = TB_GREEN;
  } elsif ($optarg eq "magenta") {
    $$var = TB_MAGENTA;
  } elsif ($optarg eq "cyan") {
    $$var = TB_CYAN;
  } elsif ($optarg eq "black") {
    $$var = TB_BLACK;
  } elsif ($optarg eq "white") {
    $$var = TB_WHITE;
  } else {
    printf("Unknown color: %s\n", $optarg);
    return 0;
  }
  return 1;
}

sub parse_options { # $ ($, @)
  my ($argc, @argv) = @_;
  my %h = ();
  GetOptions(\%h,
    'c|color=s', 
    'k|rimcolor=s', 
    's|speed=i', 
    'R|rim=i',
    'r|radius=i', 
    'b|balls=i', 
    'F|custom=s', 
    'C|contained', 
    'p|party=i', 
    'h|help|?',
    'm|man',
    'v|version',
  ) or pod2usage("Try '$0 --help' for more information.");
  while (my ($optopt, $optarg) = each %h) {
    switch: for ($optopt) {
      case: 'c' eq $_ and do {
        return 0
          if !set_color(\$color, $optarg // '');
        last;
      };
      case: 'k' eq $_ and do {
        return 0
          if !set_color(\$color2, $optarg // '');
        last;
      };
      case: 's' eq $_ and do {
        $speedMult = int($optarg // 0);
        if ($speedMult > 10 || $speedMult <= 0) {
          printf("Invalid speed, only values between 1 and 10 are allowed\n");
          return 0;
        }
        last;
      };
      case: 'R' eq $_ and do {
        $rim = int($optarg // 0);
        if ($rim > 5 || $rim < 1) {
          printf("Invalid rim, only values between 1 and 5 are allowed\n");
          return 0;
        }
        last;
      };
      case: 'r' eq $_ and do {
        $radiusIn = 50 + int($optarg // 0) * 10;
        if ($radiusIn > 150 || $radiusIn < 50) {
          printf("Invalid radius, only values between 1 and 10 are allowed\n");
          return 0;
        }
        last;
      };
      case: 'b' eq $_ and do {
        $nballs = int($optarg // 0);
        if ($nballs > MAX_NBALLS || $nballs < MIN_NBALLS) {
          printf("Invalid number of metaballs, only values between %i and %i".
                " are allowed\n",
                MIN_NBALLS, MAX_NBALLS);
          return 0;
        }
        last;
      };
      case: 'F' eq $_ and do {
        $custom = "$optarg";
        last;
      };
      case: 'C' eq $_ and do {
        $contained = 1;
        last;
      };
      case: 'p' eq $_ and do {
        $party = int($optarg // 0);
        if ($party < 0 || $party > 3) {
          printf("Invalid party mode, only values between 1 and 3 are ".
          "allowed\n");
          return 0;
        }
        last;
      };
      case: 'h' eq $_ and do {
        print_help();
        return 0;
      };
      case: 'v' eq $_ and do {
        printf("Version %s\n", $VERSION->normal);
        return 0;
      };
      case: 'm' eq $_ and do {
        pod2usage(-exitval => 0, -verbose => 2);
        return 0;
      };
    }
  }

  return 1;
}

sub print_help { # void ()
  pod2usage(-verbose => 1);
}

exit main($#ARGV, $0, @ARGV);

__END__

=head1 NAME

lavat - Little program that simulates a lava lamp in the terminal.

=head1 SYNOPSIS

lavat.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<< -c <COLOR> >>

=item B<< --color <COLOR> >>

Set color.
Available colours: red, blue, yellow, green, cyan, magenta, white and black.

=item B<< -s <SPEED> >>

=item B<< --speed <SPEED> >>

Set the speed, from 1 to 10 (default: 5).

=item B<< -r <RADIUS> >>

=item B<< --radius <RADIUS> >>

Set the radius of the metaballs, from 1 to 10 (default: 5).

=item B<< -R <RIM> >>

=item B<< --rim <RIM> >>

Set a rim for each metaball, sizes from 1 to 5 (default: 1).
This option does not work with the default color. 
If you use Kitty or Alacritty you must use it with the -k option to see the rim.

=item B<< -k <COLOR> >>

=item B<< --rimcolor <COLOR> >>

Set the color of the rim if there is one. Available colours: red, blue, 
yellow, green, cyan, magenta, white and black.

=item B<< -b <NBALLS> >>

=item B<< --balls <NBALLS> >>

Set the number of metaballs in the simulation, from 5 to 20 (default: 10).

=item B<< -F <CHARS> >>

=item B<< --custom <CHARS> >>

Allows for a custom set of chars to be used. 
Only ascii symbols are supported for now, wide/unicode chars may appear broken.

=item B<< -C >>

=item B<< --contained >>

Retain the entire lava inside the terminal.
It may not work well with a lot of balls or with a bigger radius than the 
default one.

=item B<< -p <MODE> >>

=item B<< --party <MODE> >>

PARTY!! THREE MODES AVAILABLE (p1, p2 and p3).

=item B<< -h >>

=item B<< --help >>

=item B<< -? >>

Print help.

=item B<< -v >>

=item B<< --version >>

Print version.

=item B<< -m >>

=item B<< --man >>

Full documentation.

=back

=head1 RUNTIME CONTROLS

=over

=item B<i>

Increase radius of the metaballs.

=item B<d>

Decrease radius of the metaballs.

=item B<shift i>

Increase rim of the metaballs.

=item B<shift d>

Decrease rim of the metaballs.

=item B<m>

Increase the number of metaballs.

=item B<l>

Decrease the number metaballs.

=item B<c>

Change the color of the metaballs.

=item B<k>

Change the rim color of the metaballs.

=item B<+>

Increase speed.

=item B<->

Decrease speed.

=item B<p>

TURN ON THE PARTY AND CYCLE THROUGH THE PARTY MODES (it can also turns off the 
party).

=back

(Tip: Zoom out in your terminal before running the program to get a better 
resolution of the lava.)

=head1 REQUIREMENTS

A text based terminal system, perl v5.14 (or higher) and the Termbox::Go module.

=head1 DEMO

=head2 Party Mode

  lavat -p3

=for html <img alt="demo 6" src="https://github.com/AngelJumbo/demos/blob/main/lavat/6.gif?raw=true" />

PARTY MODE!!!

=head2 Set color

  lavat -c red -R 1

=for html <img alt="demo 1" src="https://github.com/AngelJumbo/demos/blob/main/lavat/1.gif?raw=true" />

=head2 More metaballs

  lavat -c cyan -R 4 -b 20 -r 2

=for html <img alt="demo 2" src="https://github.com/AngelJumbo/demos/blob/main/lavat/2.gif?raw=true" />

If you send more than one character to the -F option you can have 3d-ish 
effect.

=head2 Set custom chars

  lavat -c blue -R2 -F @@:::::: -r10

=for html <img alt="demo 4" src="https://github.com/AngelJumbo/demos/blob/main/lavat/4.gif?raw=true" />

For the Alacritty and Kitty users I know that the -R option haven't been 
working for you, but now you can set the color of the rim independently. 
Try: L</Set rim color>.

=head2 Set rim color

  lavat -c yellow -R1 -k red

=for html <img alt="demo 5" src="https://github.com/AngelJumbo/demos/blob/main/lavat/5.gif?raw=true" />

B<Note>: The colors depend on your color scheme.

=cut

=head1 COPYRIGHT AND LICENCE

=over

=item * Copyright (c) 2022 by AngelJumbo

=item * MIT License

=back

=head1 CREDITS

=over

=item * Author J. Schneider E<lt>L<http://github.com/brickpool>E<gt>

=item * 

This program is a port of L<lavat|https://github.com/AngelJumbo/lavat>.

=item * 

L<Lava lamp in JavaScript|https://codeguppy.com/site/tutorials/lava-lamp.html>

=back

=cut
