package Term::Menu::Hierarchical;
use strict;
use warnings;
use POSIX;
use Term::Cap;
use Term::ReadKey;
require Exporter;
require 5.007_001;
binmode STDOUT, ":utf8";
$|++;

our @ISA = qw(Exporter);
our @EXPORT = qw(menu);

our $VERSION = '0.95';

# Set up the terminal handling
my $ti = POSIX::Termios->new();
$ti->getattr;
my $t = Term::Cap->Tgetent({ TERM => undef, OSPEED => $ti->getospeed||38400 });
$t->Trequire(qw/ce cl/);
my($max_width, $max_height);

########################################################################################

sub menu {

	my ($all, $data) = shift;
	die "The argument must be a hashref (arbitrary depth); exiting.\n"
   		unless ref($all) eq 'HASH';

	{
		# Refresh size info to catch term resize events
		($max_width, $max_height) = GetTerminalSize "STDOUT";
		$t->Tputs("cl", 1, *STDOUT);
		if (ref($data->{content}) eq 'HASH'){
			$data = _display($data);
		}
		else {
			if (defined $data->{content}){
				_more("$data->{label}\n\n$data->{content}\n");
			}
			$data->{content} = $all;
			$data->{label}   = 'Top';
		}
		redo;
	}
}

sub _more {
	return unless my @txt = split /\n/, shift;
	# Fill @txt so we have full 'pages'
	if (@txt % ($max_height - 2)){
		push @txt, '~' for 3 .. ($max_height - @txt % ($max_height - 2));
	}
	my ($pos, @pages) = 0;
	push @pages, [ splice @txt, 0, ($max_height - 2) ] while @txt;

  	my $prompt = ' [ <space|Enter>=page down  <b>=back  <q>=quit ]   ';
	{
		$t->Tputs("cl", 1, *STDOUT);
		for (@{$pages[$pos]}){
			# (Crude) long line handling. You should format your data...
			if (length($_) > $max_width){
				print substr($_, 0, $max_width - 1);
				$t->Tputs("so", 1, *STDOUT);
				print ">\n";
				$t->Tputs("se", 1, *STDOUT);
			}
			else {
				print "$_\n";
			}
		}

		$t->Tputs("so", 1, *STDOUT);
		$t->Tputs("md", 1, *STDOUT);
		print "\n", $prompt, ' ' x ($max_width - length($prompt));
		$t->Tputs("me", 1, *STDOUT);
		$t->Tputs("se", 1, *STDOUT);

		ReadMode 4;
		my $key;
		1 while not defined ($key = ReadKey(-1));
		ReadMode 0;
		if ($key =~ /q/i){
			return;
		}
		elsif ($key =~ /b/i){
			$pos-- if $pos > 0;
		}
		elsif ($key =~ /\s/){
			$pos++ if $pos < $#pages;
		}
		redo;
	}
}

sub _display {
	my $ref = shift;
	# reverse-sort the lengths of all the item names, count them...
	my $num_items = my @lengths = sort {$b<=>$a} map {length($_)} keys %{$ref->{content}};
	# ...and grab the first number in the list to get the display width.
	my $max_len = $lengths[0];
	die "Your display is too narrow for these items.\n"
		if $max_len + 7 > $max_width;
	
	# How many digits will we need for the index?
	my $count_width = $num_items =~ tr/0-9//;
	# '5' covers the formatting bits (separator, parens, three spaces)
	my $span_width = $max_len + $count_width + 5;
	# Max number of items that will fit in the display width *or*
	# the total number of items if it's less than that.
	my $items_per_line = int($max_width/$span_width) < $num_items ?
		int($max_width/$span_width) : $num_items;
	# Figure out total width for printing; '-1' adjusts for box corners
	my $width = $items_per_line * $span_width - 1;

	# Display the menu, get the answer, and validate it
	my($answer, %list);
	{
		my $count;
		$t->Tputs("cl", 1, *STDOUT);
		print "." . "-" x $width . ".\n";
		for my $item (keys %{$ref->{content}}){
			# Create a number-to-entry lookup table
			$list{++$count} = $item;
			# Print formatted box body
			printf "| %${count_width}s) %-${max_len}s ", $count, $item;
			print  "|\n" unless $count % $items_per_line;
		}
		# If we don't have enough items to fill the last line, pad with empty cells
		if ($count % $items_per_line){
			my $pad = "|" . " " x ($span_width - 1);
			print $pad x ($items_per_line - $count % $items_per_line);
			print "|\n";
		}
		print "'" . "-" x $width . "'\n";

		print "Item number (1-$count, 0 to restart, 'q' to quit)? ";
		chomp($answer = <STDIN>);
		exit if $answer =~ /^q/i;
		redo unless $answer =~ /^\d+$/ && $answer >= 0 && $answer <= $count;
	}
	my $retval;
	if ($answer == 0){
		$retval->{content} = undef;
	}
	else {
		$retval->{label} = "$ref->{label} >> $list{$answer}";
		$retval->{content} = $ref->{content}->{$list{$answer}};
	}
	return $retval;
}

########################################################################################

1;

__END__

=head1 NAME
 
Term::Menu::Hierarchical - Perl extension for creating hierarchical menus
 
=head1 SYNOPSIS

This Perl extension lets you easily create hierarchical menus. Just build a hashref representing the hierarchy and use
it as an argument to the 'menu' function, and Term::Menu::Hierarchical will take care of all the rest.

=head1 ABSTRACT

To generate a menu series that looks like this:

=begin html

<pre>
  .--------------------------------------------.
  | 1) Breakfast | 2) Dinner    | 3) Lunch     |
  '--------------------------------------------'
  Item number (1-3, 0 to restart, 'q' to quit)? 2
</pre>

=end html

=begin html

<pre>
  .-------------------------------.
  | 1) Vegetarian | 2) Meat       |
  '-------------------------------'
  Item number (1-2, 0 to restart, 'q' to quit)? 1
</pre>

=end html

=begin html

<pre>
  .-------------------------------------------------------------------------------------------.
  | 1) Asian Eggplant    | 2) Desserts          | 3) Chickpea Curry    | 4) Broccoli and Rice |
  '-------------------------------------------------------------------------------------------'
  Item number (1-4, 0 to restart, 'q' to quit)? 2
</pre>

=end html

=begin html

<pre>
  .---------------------------------.
  | 1) Milk Shake  | 2) Almond Tofu |
  '---------------------------------'
  Item number (1-2, 0 to restart, 'q' to quit)? 
</pre>

=end html

=begin text

  .--------------------------------------------.
  | 1) Breakfast | 2) Dinner    | 3) Lunch     |
  '--------------------------------------------'
  Item number (1-3, 0 to restart, 'q' to quit)? 2
  
  +++++++++++[New page]++++++++++++++++++++++++++++++
  
  .-------------------------------.
  | 1) Vegetarian | 2) Meat       |
  '-------------------------------'
  Item number (1-2, 0 to restart, 'q' to quit)? 1
  
  +++++++++++[New page]++++++++++++++++++++++++++++++
  
  .-------------------------------------------------------------------------------------------.
  | 1) Asian Eggplant    | 2) Desserts          | 3) Chickpea Curry    | 4) Broccoli and Rice |
  '-------------------------------------------------------------------------------------------'
  Item number (1-4, 0 to restart, 'q' to quit)? 2
  
  +++++++++++[New page]++++++++++++++++++++++++++++++
  
  .---------------------------------.
  | 1) Milk Shake  | 2) Almond Tofu |
  '---------------------------------'
  Item number (1-2, 0 to restart, 'q' to quit)? 


=end text

. 

do this:

=over

 use Term::Menu::Hierarchical;

 my %data = (
 	Breakfast => {
 		'Milk + Cereal' => 'A good start!',
 		'Eggs Benedict' => 'Classic hangover fix.',
 		'French Toast'  => 'Nice and easy for beginners.'
 	},
 	Lunch   =>  {
 		'Mushroomwiches'=> 'A new take on an old favorite.',
 		'Sloppy Janes'  => 'Yummy and filling.',
 		'Corn Dogs'     => 'Traditional American fare.'
 	},
 	Dinner  =>  {
 		Meat        =>  {
 			'Chicken Picadillo' =>  'Mmm-hmm!',
 			'Beef Stroganoff'   =>  'Is good Russian food!',
 			'Turkey Paella'     =>  'Home-made goodness.'
 		},
 		Vegetarian  => {
 			'Asian Eggplant'    =>  'Tasty.',
 			'Broccoli and Rice' =>  'Fun.',
 			'Chickpea Curry'    =>  'Great Indian dish!',
 			'Desserts'          =>  {
 				'Almond Tofu'   =>  'Somewhat odd but good',
 				'Soymilk Shake' =>  'Just like Mama used to make!'
 			}
 		}
 	}
 );
 
	menu(\%data);

=back

### What about keeping the top-level menu in order?

=over

 use Term::Menu::Hierarchical;
 use Tie::IxHash;
 
	 tie(my %data, 'Tie::IxHash',  
	Breakfast => {
		'Milk + Cereal' => 'A good start!',
		'Eggs Benedict' => 'Classic hangover fix.',
		'French Toast'  => 'Nice and easy for beginners.'
	},
	[ ... ]
 );

 menu(\%data);

=back

### How about a simple way to browse a database table?

=over

 my $dbh = DBI->connect("DBI:mysql:geodata", 'user', 'password');
 menu($dbh->selectall_hashref('SELECT * FROM places LIMIT 100', 'placeName'));

=back

=head1 DESCRIPTION
 
This module only exports a single method, 'menu', which takes an arbitrary-depth hashref as an argument. The keys at
every level are used as menu entries; the values, whenever they're reached via the menu, are displayed in a pager.
Many text files (e.g., recipe lists, phone books, etc.) are easily parsed and the result structured as a hashref; this
module makes displaying that kind of content into a simple, self-contained process.
 
The module itself is pure Perl and has no system dependencies; however, terminal handling always involves a pact with
the Devil and arcane rituals involving chicken entrails and moon-lit oak groves. Users are explicitly warned to beware.

Bug reports are always eagerly welcomed.
 
=head1 FEATURES
  
 * No limit on hashref depth
 * Self-adjusts to terminal width and height
 * Keeps track of the "breadcrumb trail" (displayed in the pager)
 * Somewhat basic but serviceable pure-Perl pager
 * Extensively tested with several versions of Linux
  
For those who want to display data beyond plain old ASCII: this module expects UTF8-encoded text. Please don't
disappoint it, and it won't (shouldn't) disappoint you. Perhaps the most common/easiest solution (assuming that your
data is already UTF8-encoded) is to push the ':utf8' PerlIO layer onto the filehandle you want to read from:
 
=over
 
open my $fh, '<:utf8', $filename or die ...
  
=back
 
Or, for filehandles that are already open, just use 'binmode':
 
=over
 
binmode DATA, ':utf8';
  
=back
 
For a full treatment of the topic, see C<perldoc perlunicode>.

 
=head2 EXPORT

.

menu

Takes a single argument, a hashref of arbitrary depth. See the included test scripts for usage examples.

=head1 SEE ALSO

Term::Cap, Term::ReadKey, perl

=head1 AUTHOR

Ben Okopnik, E<lt>ben@okopnik.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Ben Okopnik

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
