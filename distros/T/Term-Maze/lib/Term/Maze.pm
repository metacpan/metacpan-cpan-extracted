package Term::Maze;

use 5.006;
use strict;
use warnings;
use Term::ReadKey ();
use Getopt::Long ();
our $VERSION = '0.06';

require XSLoader;
XSLoader::load('Term::Maze', $VERSION);

our $READER = \&Term::ReadKey::ReadKey;
our $READMODE = \&Term::ReadKey::ReadMode;
our $MODE;

sub _usage {
	return <<'USAGE';
maze - mazes in the terminal

usage: maze [options]
       maze WIDTH HEIGHT

  --width N      columns, at least 2 (default 40)
  --height N     rows, at least 2 (default 20)
  --help         this

exit status:
  0   you reached the exit, or you quit
  2   a bad option

Move with WASD or HJKL. Reach the exit to win; q or escape quits.
USAGE
}

sub _mode {
	my ($mode) = @_;
	$MODE = $mode;
	$READMODE->($mode);
	return;
}

sub _sizes {
	my (@argv) = @_;
	my ($width, $height) = (40, 20);
	if (grep { !/^\d+$/ } @argv) {
		my %opt;
		my $ok = eval {
			local $SIG{__WARN__} = sub { print STDERR "maze: $_[0]" };
			Getopt::Long::GetOptionsFromArray(\@argv, \%opt, 'width=i', 'height=i', 'help');
		};
		if (!$ok)       { print STDERR _usage(); return }
		if ($opt{help}) { print _usage(); return 0 }
		if (@argv)      { print STDERR "maze: not an option: $argv[0]\n", _usage(); return }
		$width  = $opt{width}  if defined $opt{width};
		$height = $opt{height} if defined $opt{height};
	}
	else {
		if (@argv > 2) { print STDERR "maze: too many sizes: @argv\n", _usage(); return }
		$width  = $argv[0] if defined $argv[0];
		$height = $argv[1] if defined $argv[1];
	}
	for ([width => $width], [height => $height]) {
		next if $_->[1] >= 2;
		print STDERR "maze: --$_->[0] must be at least 2, not $_->[1]\n", _usage();
		return;
	}
	return ($width, $height);
}

sub options {
	return [
		{ name => 'width', type => 'int', min => 5, max => 120, help => 'cells across' },
		{ name => 'height', type => 'int', min => 5, max => 60, help => 'cells down' },
	];
}

sub run {
	my ($class, @argv) = @_;
	my @size = _sizes(@argv);
	return 2 unless @size;
	return 0 if @size == 1;
	my ($width, $height) = @size;

	local @SIG{qw(INT TERM HUP)};
	for my $sig (qw(INT TERM HUP)) {
		$SIG{$sig} = sub { _mode(0); $SIG{$sig} = 'DEFAULT'; kill $sig, $$ };
	}

	_mode("cbreak");
	my $won = eval { _play($width, $height) };
	my $died = $@;
	_mode(0);
	die $died if $died;
	print "You win!\n" if $won;
	return 0;
}

sub _play {
	my ($width, $height) = @_;
	my $maze = Term::Maze->new($width, $height);
	$maze->refresh();
	while (!$maze->at_exit) {
		my $key = $READER->(0);
		next unless defined $key;
		return 0 if $key eq 'q';
		if ($key eq "\e") {
			my $next = $READER->(-1);
			return 0 unless defined $next;
			$next = $READER->(-1) while defined $next && $next !~ /[A-Za-z~]/;
			next;
		}
		if ($key =~ m/^[wasdhjkl]$/) {
			$maze->move_player($key);
		}
		$maze->refresh();
	}
	return 1;
}
sub refresh {
	my ($self) = @_;
	print "\e[H\e[2J";
	my $rows = $self->get_maze_with_player();
	print "$_\n" for @$rows;
	print "Use WASD or HJKL to move. Reach the exit to win.\n";
}

1;

__END__

=head1 NAME

Term::Maze - Mazes in the terminal

=head1 VERSION

Version 0.06

=cut

=head1 SYNOPSIS

	use Term::Maze;

	Term::Maze->run(40, 20);
	
	...

	#########################################
	#S#   #   #       #               #     #
	# # # ### # # ### ####### ####### # # # #
	# # # #   # #   #       #       #   # # #
	# # # # ### ### ####### ### ######### # #
	# # # # #   # #       #   # #   #     # #
	# # # # # ### ####### ### ### # # ##### #
	# # # #         #     #   #   # # # #   #
	# # # ####### ### ##### ### ### # # # ###
	#   #     #   #   # #   #   #     # #   #
	######### # ### ### # ### ######### ### #
	#         #   #  @# #   #     #     #   #
	# ########### ### # ### ### # # # ### ###
	#   #         # # #       # # # #   # # #
	### # ######### # ####### # # ##### # # #
	#   #           # #     # # #   #   #   #
	# ############# # # ### # ##### # ##### #
	#             # #     # #     # #   #   #
	############# ######### ##### # # # # ###
	#                       #       # #    E#
	#########################################
	Use WASD to move. Reach the exit to win.


=head1 SUBROUTINES/METHODS

=head2 options

    my $fields = Term::Maze->options;

The options a person would set before a game, in the order a launcher shows
them. Each is a hash reference with a C<name>, a C<type> and a C<help>, and
C<min> and C<max> or C<choices> where the type has them. A new list is
returned each time.

=over 4

=item C<width>

A whole number from 5 to 120: cells across.

=item C<height>

A whole number from 5 to 60: cells down.

=back

=head2 run

	Term::Maze->run(40, 20);

	exit Term::Maze->run(@ARGV);

Runs the maze game and returns the exit status. Two bare non-negative integers are the width and height, as they always were; anything else is read as options: C<--width N> and C<--height N> (defaults 40 and 20, each at least 2) and C<--help>, which prints the usage on C<STDOUT> and returns 0. A bad option prints the usage on C<STDERR> and returns 2.

The terminal is put into cbreak mode for the game and B<restored on every way out>: on reaching the exit, on quitting, after a die, and from C<INT>, C<TERM> and C<HUP>, whose handlers are local to the call and re-raise once the mode is back. Move with WASD or HJKL; B<q or escape quits> with status 0, and reaching the exit prints "You win!" and returns 0.

=head2 refresh

Refreshes the maze display in the terminal. It clears the screen, retrieves the maze with the player's position, and prints it to the terminal.

	$maze->refresh();

=cut

=head2 new

Instantiate a new Term::Maze object with the specified width and height. This method initializes the maze structure, player position, and exit point.

	my $maze = Term::Maze->new($width, $height);

=cut

=head2 move_player

Moves the player in the maze based on the input key. The player can move up, down, left, or right using the WASD keys. It checks for valid moves and updates the player's position accordingly.

	$maze->move_player('w'); # Move up
	$maze->move_player('a'); # Move left
	$maze->move_player('s'); # Move down
	$maze->move_player('d'); # Move right

=head2 get_maze_with_player

Returns the maze structure with the player's current position. It generates a 2D array representation of the maze, including walls, paths, the player, and the exit.

	my $rows = $maze->get_maze_with_player();

=head2 at_exit

Checks if the player has reached the exit point in the maze. It compares the player's current position with the exit coordinates.

	my $at_exit = $maze->at_exit;

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-term-maze at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Term-Maze>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	 perldoc Term::Maze


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Term-Maze>

=item * Search CPAN

L<https://metacpan.org/release/Term-Maze>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Term::Maze
