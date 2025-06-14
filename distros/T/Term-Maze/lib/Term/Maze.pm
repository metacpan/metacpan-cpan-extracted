package Term::Maze;

use 5.006;
use strict;
use warnings;
use Term::ReadKey;
our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Term::Maze', $VERSION);

sub run {
	my ($self, $width, $height) = @_;
	ReadMode("cbreak");
	my $maze = Term::Maze->new($width, $height);
	$maze->refresh();
	while (!$maze->at_exit) {
		my $key = ReadKey(0);
		next unless defined $key;
		if ($key =~ m/^[wasd]$/){
			$maze->move_player($key);
		}
		$maze->refresh();
	}

	print "You win!\n";
}

sub refresh {
	my ($self) = @_;
	print "\e[H\e[2J";
	my $rows = $self->get_maze_with_player();
	print "$_\n" for @$rows;
	print "Use WASD to move. Reach the exit to win.\n";
}


1;

__END__

=head1 NAME

Term::Maze - Mazes in the terminal

=head1 VERSION

Version 0.01

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

=head2 run

Runs the maze game. It initializes the maze with the specified width and height, sets the terminal to cbreak mode, and starts the game loop where the player can move using WASD keys.

	Term::Maze->run(40, 20);

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
