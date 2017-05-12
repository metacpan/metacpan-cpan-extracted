

package Parse::Gnaw::LinkedListDimensions2;

our $VERSION = '0.001';

use warnings;
use strict;
use Data::Dumper;
use Carp;

use Parse::Gnaw::Blocks::LetterConstants;

use       Parse::Gnaw::LinkedList;
use base "Parse::Gnaw::LinkedList";
use       Parse::Gnaw::LinkedListConstants;


use Parse::Gnaw::Blocks::LetterDimensions2;

=head1 NAME

Parse::Gnaw::LinkedListLetterDimensions2 - Create a Parsable linked list of Parse::Gnaw::Letter objects, 
with 4 axis of dimension. This would be equivalent to a 2-dimensional block of text, equivalent to somthing like:

	a-b-c
	|X|X|
	d-e-f
	|X|X|
	g-h-i	



=head1 SUBROUTINES/METHODS

=cut

=head2 constructor_defaults

return a hash containing the default values for constructor arguments.
this gets overloaded by derived classes so base constructor always does the right thing.

=cut
sub constructor_defaults{
	# derived classes always override the defaults for constructor
	my %defaults=(
		# you don't have to pass in a string to convert into a linked list.
		# can create bare linked list now, and then append string later.
		string=>'',

		# 0 => horizontally
		# 1 => vertically
		# 2 => diagonal upper left to lower right
		# 3 => diagonal upper right ot lower left
		max_connections=>4,

		# linked list of something. this says of what.
		# can change this to make linked list of some other, new class.
		letterpkg=>'Parse::Gnaw::Blocks::LetterDimensions2',
	);

	return (%defaults);
}


=head2 append
this gets overloaded by derived classes so base constructor always does the right thing.
=cut
sub append{
	my $obj=shift(@_);
	$obj->append_block_d2(@_);
}



=head2 append_block_d2
This method appends a two-dimensional block of text
=cut
sub append_block_d2{
	my($llist, $lettertoappendto, $blocktoappend, $location)=@_;

	if(not(defined($location))){
		$location = $llist->get_location_of_caller($location);	
	}

	my @strings=split("\n", $blocktoappend);
	my $linenum=0;
	my @two_most_recent_lines_created;
	foreach my $string (@strings){
		$linenum++;
		my $stringlocation = "$location, textline $linenum";

		my $newletter = $llist->append_string($lettertoappendto, $string, $stringlocation);

		my $packletter = $lettertoappendto->[LETTER__NEXT_START];

		# follow the letter to the end of the line
		my @letters_in_this_line;
		push(@two_most_recent_lines_created, \@letters_in_this_line);
		if(scalar(@two_most_recent_lines_created)>2){
			shift(@two_most_recent_lines_created);
		}

		while($packletter){
			push(@letters_in_this_line, $packletter);
			$packletter=$packletter->[LETTER__CONNECTIONS]->[0]->[LETTER__CONNECTION_NEXT];
		}





		if(scalar(@two_most_recent_lines_created)==2){
			my $aboveline =$two_most_recent_lines_created[0];
			my $bottomline=$two_most_recent_lines_created[1];
	
			for(my $x=0; $x<scalar(@$aboveline); $x++){
				my $aboveletter=$aboveline->[$x];
				my $bottomletter=$bottomline->[$x];

				$aboveletter->link_two_letters_via_interconnection($bottomletter,2); 
	
				if($x>0){
					my $aboveleftletter=$aboveline->[$x-1];
					my $bottomleftletter=$bottomline->[$x-1];

					$aboveleftletter->link_two_letters_via_interconnection($bottomletter,1); 
					$aboveletter->link_two_letters_via_interconnection($bottomleftletter,3); 
				

				}
			}

		}

		$lettertoappendto = $newletter;
	}





}

my $blank_obj=[];
#print "blank_obj is '$blank_obj'\n"; die;
my $blank_str=$blank_obj.'';
my $blank_len=length($blank_str);
my $BLANK = '.'x($blank_len-5);



=head2 create_interconnections_for_newly_appended_character

The variable names reflect the physical position of hte letters

$upleft $above

$left   $newletter


The axis interconnect the letters as follows:

0 => horizontally
1 => vertically
2 => diagonal upper left to lower right
3 => diagonal upper right ot lower left

Assume that axis [0] is already connected.
We need to connect axis 1,2,3

=cut

sub create_interconnections_for_newly_appended_character{
	my($llist,$newletter)=@_;

	my $above = $llist->[LIST__PREVIOUS_LINE_LETTER]->[0];

	# if we just added first line, then previous line will be undefined.
	return unless($above);

	$llist->[LIST__PREVIOUS_LINE_LETTER]->[0]=$above->[LETTER__CONNECTIONS]->[0]->[LETTER__CONNECTION_NEXT];

	# letter adn letter above it are defined, connect them on vertical axis.
	$above->link_two_letters_via_interconnection($newletter,1);

	# assume [0] is already connected, so we can do what we're about to do:
	my $left = $newletter->[LETTER__CONNECTIONS]->[0]->[LETTER__CONNECTION_PREV];
	my $upleft =   $above->[LETTER__CONNECTIONS]->[0]->[LETTER__CONNECTION_PREV];

	# if we are adding first letter of line, then previous column will be undefined.
	# if not first letter of line, then column to left will be defined, connect it.
	if($upleft){

		$upleft->link_two_letters_via_interconnection($newletter,2); 
		 $above->link_two_letters_via_interconnection($left,3); 

	}
}


		
1;


