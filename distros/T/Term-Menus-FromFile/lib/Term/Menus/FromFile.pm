#!/usr/bin/perl

package Term::Menus::FromFile;

=head1 NAME

I<Term::Menus::FromFile>

=head1 SYNOPSIS

Lets you store I<Term::Menu> menu definitions in a file.

=head1 DESCRIPTION

I<Term::Menus::FromFile> reads a file (in a specific format), an uses that to
create a menu with I<Term::Menu>.  The menus can either just return their 
selection (like I<Term::Menu>) or can call other scripts/programs on your
system.  In the latter case I<Term::Menu::FromFile> will run the program for you,
and return the output of the program.

There are seperate functions for if you have an open filehandle, or just the
path to the file.  If you want multiple return values, there are functions
wrapping I<Term::Menu>'s menu function as well.  (Note: The 'call the chosen
script' ablity does not exist for multiple return value menus.)

=head1 USAGE

No functions are imported by default: you'll have to import them yourself.
Avalible functions are listed below.

=head2 Menu File Format

The file format is fairly straightforward:  At the top of the file is a 
'Title' line, followed by menu entry lines.  Menu entries have three fields,
seperated by semicolons.  The fields are: 'Order', 'Menu_text' and 'Command'.
The 'Command' field is only relevant if you want to call a script on selection.
Title lines must start with C<#TITLE:>.

Example file:

	#TITLE:Menu 1
	1;Item 1;
	2;Item 2;perl test_data/test_command.pl
	3;Item 3;fiddledo

In the example, 'Item 1' has no command, 'Item 2' uses C<perl> to run a script
and 'Item 3' runs the C<fiddledo> command directly.  (I wonder what that does...)

=head2 Functions

=head3 Possible Exports

	pick_from_filename   pick_command_from_filename 
	pick_from_file       pick_command_from_file
	menu_from_filename   menu_from_file

=cut

use 5.006;	# This module uses some Perl 5.6 semantics.

use warnings;
use strict;
use Carp;
use Exporter;
use Term::Menus;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

@ISA = qw(Exporter);

$VERSION = '1.00.00';

@EXPORT_OK = qw(pick_from_filename pick_command_from_filename 
				pick_from_file pick_command_from_file
				menu_from_filename menu_from_file
				);
				
#%EXPORT_TAGS = (PICKS => [qw(pick_from_filename pick_command_from_filename 
#							pick_from_file pick_command_from_file
#							)]
#				,MENUS => [qw(menu_from_filename menu_from_file)]
#				,FILENAMES => [qw(pick_from_filename pick_command_from_filename
#								menu_from_filename
#								)]
#				,FILES => [qw(pick_from_file pick_command_from_file menu_from_file)]
#				,COMMANDS => [qw(pick_command_from_filename pick_command_from_file)]
#				,NO_CMD => [qw(pick_from_filename pick_from_file menu_from_filename 
#							 menu_from_file
#							 )]
#				);

=head3 pick_from_filename

=over 4

=item Arguments

One argument: The name of the menu file.

=item Return Value

Returns the menu item picked.  (By text, as in I<Term::Menu>'s C<pick> function.)

=back

Opens a menu file, reads it, displays a menu to the user, and returns the user-picked
value to the program.  It will C<croak> if it can't find or open the menu file, or 
if the file parses to an empty menu.

=cut

sub pick_from_filename ($) {
	my $menu_file_name = shift;
	
	# Open the menu file, if it exists.
	my $menu_file = _open_file($menu_file_name);
	
	# Call pick_from_file to get the actual pick.
	return pick_from_file($menu_file);
}

=head3 pick_command_from_filename

=over 4

=item Arguments

One argument: The name of the menu file.

=item Return Value

Returns the output of the command that was run.

=back

Opens a menu file, reads it, displays a menu to the user, and runs the command 
specifed in the menu file for the menu time the user picked.  The output of the
command is returned in a scalar.  (Note that the return value will be in $?, 
also called $CHILD_ERROR.)

It will C<croak> if it can't find or open the menu file, or if the file parses 
to an empty menu.

=cut

sub pick_command_from_filename ($) {
	my $menu_file_name = shift;
	
	# Open the menu file, if it exists.
	my $menu_file = _open_file($menu_file_name);
		
	# Call pick_command_from_file to get the actual pick.
	return pick_command_from_file($menu_file);

}

=head3 pick_from_file

=over 4

=item Arguments

One argument: An open filehandle.

=item Return Value

Returns the menu item picked.  (By text, as in I<Term::Menu>'s C<pick> function.)

=back

Reads an already opened menu file, displays the menu to the user, and returns the 
user-picked value to the program.  It will C<croak> if it can't find or open the 
menu file, or if the file parses to an empty menu.

=cut

sub pick_from_file ($) {
	my $menu_file = shift;

	(my $title, my $menu_lines) = _parse_file($menu_file);
	my @menu_lines = @$menu_lines;
	
	# Sort the array correctly, then drop extra info.
	@menu_lines = map { $$_{'menu_item'} } (sort { $$a{'order'} <=> $$b{'order'} } @menu_lines);
	
	# Return the user's pick.
	return pick(\@menu_lines, $title);	
}

=head3 pick_command_from_file

=over 4

=item Arguments

One argument: An open filehandle.

=item Return Value

Returns the output of the command that was run.

=back

Reads an already open menu file, displays the menu to the user, and runs the command 
specifed in the menu file for the menu time the user picked.  The output of the
command is returned in a scalar.  (Note that the return value will be in $?, 
also called $CHILD_ERROR.)

It will C<croak> if it can't find or open the menu file, or if the file parses 
to an empty menu.

=cut

sub pick_command_from_file ($) {
	my $menu_file = shift;
	
	(my $title, my $menu_lines) = _parse_file($menu_file);
	my @menu_lines = @$menu_lines;
	
	# Sort the menu items into the correct order.
	@menu_lines = sort { $$a{'order'} <=> $$b{'order'} } @menu_lines;
	
	# Grab the commands, then the menu items themselves
	# and trash the rest.
	my %command = map { $$_{'menu_item'} => $$_{'command'} } @menu_lines;
	@menu_lines = map { $$_{'menu_item'} } @menu_lines;
	
	# Get the user's pick.
	my $menu_pick = pick(\@menu_lines, $title);
	
	# Check to see if they actually choose anything...
	if ($menu_pick eq ']quit[') {
		# This isn't an error, so we don't throw one,
		# but the caller should be able to tell nothing was done.
		return ']quit[';
	}
	
	# Run the command, and return the output.
	# (The return value will be avalible in $?, or $CHILD_ERROR.)
	my $return = eval { `$command{$menu_pick}`; };
	if ($?) { 
		carp "Unable to run user's command choice: $command{$menu_pick} $!\n";
	}
	return $return;
}

=head3 menu_from_filename

=over 4

=item Arguments

One argument: The name of the menu file.

=item Return Value

Returns the menu items picked.  (By text in an array reference,
as in I<Term::Menu>'s C<Menu> function.)

=back

Opens a menu file, reads it, displays a menu to the user, and returns the user-picked
values to the caller.  It will C<croak> if it can't find or open the menu file, or 
if the file parses to an empty menu.

I< B<!-- Currently this does not work. --!> >

=cut

sub menu_from_filename ($) {
	my $menu_file_name = shift;
	
	# Open the menu file, if it exists.
	my $menu_file = _open_file($menu_file_name);

	# Call menu_from_file to get the actual menu picks.
	return menu_from_file($menu_file);
}

=head3 menu_from_file

=over 4

=item Arguments

One argument: An open filehandle.

=item Return Value

Returns the menu items picked.  (By text in an array reference,
as in I<Term::Menu>'s C<Menu> function.)

=back

Reads an open menu file, displays a menu to the user, and returns the user-picked
values to the caller.  It will C<croak> if it can't find or open the menu file, or 
if the file parses to an empty menu.

I< B<!-- Currently this does not work. --!> >

=cut

sub menu_from_file ($) {
	my $menu_file = shift;
	
	(my $title, my $menu_lines) = _parse_file($menu_file);
	my @menu_lines = @$menu_lines;
	
	# Sort the array correctly, then drop extra info.
	@menu_lines = map { $$_{'menu_item'} } (sort { $$a{'order'} <=> $$b{'order'} } @menu_lines);
	
	# Return the user's choices.
	return Menu(\@menu_lines,$title);
}

####################################################
#
# Below here are private functions.
#
####################################################


# Opens a file for reading, and returns a filehandle.
# Arugments: The name of the file, in a scalar.
# Return value: A filehandle, in a scalar.
# Croaks if the file can't be found, or if there were
# Errors opening it.
sub _open_file ($) {
	my $menu_file_name = shift;
	
	# Open the menu file, if it exists.
    my $menu_file;
    if ( -e $menu_file_name ) {
            open $menu_file, '<', $menu_file_name or croak "Unable to open menu file $menu_file_name: $!/n";
    }
    else {
            croak "The menu file $menu_file_name does not exist.\n";
    }

	return $menu_file;
}

# Parses an open file.
# Arguments: A filehandled, in a scalar.
# Return Value: A two-member list.  The first value is
# the title of the menu, and the second is a reference to
# an array with the menu items.
# Each menu item is a hash in the array, containing three
# values: 'order', 'menu_item', and 'command'.
# Croaks if no menu times were found in the file.
sub _parse_file ($) {
	my $menu_file = shift;
	
	# Read out the title, which should be the first thing in the file.	
	my $title;
	while (my $line = <$menu_file>) {
	print $line;
		if ($line =~ /#TITLE:(.*)/ ) {
			$title = $1;
			last;
		} 
	}
	
	#Break out the menu items, into an array.
	my @menu_lines;
	while (my $line = <$menu_file>) {
	print $line;
		my %menu_item;
		($menu_item{'order'}, $menu_item{'menu_item'}, $menu_item{'command'})
			= split /;/, $line;
		push @menu_lines, \%menu_item;
	}
	
	if ($#menu_lines <= 0) {
		croak "There are no entries in the menu file given.\n";
	}
	
	return ($title, \@menu_lines);
}

=head1 CAVEATS

The menu file is basically assumed to be valid, if we managed to parse any
lines.  We probably shouldn't do that.

Also, the title is required, when it really should be optional.

And comments.  We don't allow comments.

There are some forms of menus that I<Term::Menus> supports that we don't.

The 'menu' functions don't work, until I figure out what format I<Term::Menus>
actually does support.

=head1 REQUIRES

Perl 5.6

Term::Menus

=head1 AUTHOR

Daniel T. Staal

DStaal@usa.net

=head1 SEE ALSO

L<Term::Menus>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2008 Daniel T. Staal. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

This copyright will expire in 30 years, or 5 years after the author's
death, whichever is longer.

=cut

1;
