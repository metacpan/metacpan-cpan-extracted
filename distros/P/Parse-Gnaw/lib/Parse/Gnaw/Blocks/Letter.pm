


package Parse::Gnaw::Blocks::Letter;

our $VERSION = '0.001';

#BEGIN {print "Parse::Gnaw::Blocks::Letter\n";}

use warnings;
use strict;
use Carp;
use Data::Dumper;
use Storable 'dclone';


use       Parse::Gnaw::Blocks::LetterConstants;
use       Parse::Gnaw::LinkedListConstants;

=head1 NAME

Parse::Gnaw::Blocks::Letter - a linked list element that holds a single scalar payload.


=head2 new

This is the constructor for a letter object, which is part of a LinkedListObject

	Parse::Gnaw::Blocks::Letter->new($linkedlist, $lettervalue, $letterlocation);

Linkedlist is the linkedlist object that contains this letter.
Lettervalue is probably a single character like 'b'.
Letterlocation is a string that describes where the letter originaly came from (filename/linenum).


=cut

sub new {

	my ($pkg, $llist, $value, $location)=@_;
	$location ||= 'unknown';

	my $connmin1=$llist->[LIST__CONNECTIONS_MINUS_ONE];
	my @connections;
	foreach my $dimension (0 .. $connmin1){
		push(@connections, [undef,undef]);
	}


	my $ltrobj=bless([],$pkg);  

	$ltrobj->[LETTER__LINKED_LIST] = $llist;
	$ltrobj->[LETTER__DATA_PAYLOAD]= $value;
	$ltrobj->[LETTER__CONNECTIONS] = \@connections;
	$ltrobj->[LETTER__WHERE_LETTER_CAME_FROM] = $location;
	$ltrobj->[LETTER__LETTER_HAS_BEEN_CONSUMED]=0;

	# get the most recently created letter 
	my $previous_letter;
	if(	$llist->[LIST__MOST_RECENTLY_CREATED_LETTER]){
		$previous_letter  = $llist->[LIST__MOST_RECENTLY_CREATED_LETTER];

		# find out what most recently created letter pointed "next start" to.
		my $next_letter;
		if($previous_letter and $previous_letter->[LETTER__NEXT_START]){
			$next_letter = $previous_letter->[LETTER__NEXT_START];
		}

		# previous_letter connects to newletter
		# $previous_letter->link_two_letters_via_next_start($ltrobj);
		$previous_letter->[LETTER__NEXT_START]=$ltrobj;
		$ltrobj->[LETTER__PREVIOUS_START]=$previous_letter;

	}

	# update the linked list so that THIS newly created letter is now the most recently created letter.	
	$llist->[LIST__MOST_RECENTLY_CREATED_LETTER] = $ltrobj;

	return $ltrobj;	# return the letter
}


my $blank_obj=[];
#print "blank_obj is '$blank_obj'\n"; die;
my $blank_str=$blank_obj.'';
my $blank_len=length($blank_str);
my $BLANK = '.'x($blank_len-5);

=head2 get_raw_address

This is a subroutine. Do NOT call this as a method. This will allow it to handle undef values.

	my $retval = get_raw_address($letterobj);

Given a letter object, get the string that looks like

	Parse::Gnaw::Blocks::Letter=ARRAY(0x850cea4)

and return something like 

	0x850cea4

=cut
sub get_raw_address{
	my ($ltrobj)=@_;

	unless(defined($ltrobj)){
		return $BLANK;
	}

	my $string=$ltrobj.'';
	$string=~m{(\(0x[0-9a-f]+\))} or croak "could not get_raw_address";
	my $addr=$1;

	return $addr;

}


=head2 display

print out a formatted version of letter object.

=cut

sub display {
	my ($ltrobj)=@_;
	print "\n";
	print "\tletterobject: ".$ltrobj."\n";
	print "\tpayload: '".($ltrobj->[LETTER__DATA_PAYLOAD])."'\n";
	print "\tfrom: ".($ltrobj->[LETTER__WHERE_LETTER_CAME_FROM])."\n";
	print "\t"."connections:\n";

	my $self  = get_raw_address($ltrobj);

	foreach my $conn (@{$ltrobj->[LETTER__CONNECTIONS]}){
		my $prev = $conn->[LETTER__CONNECTION_PREV];
		my $next = $conn->[LETTER__CONNECTION_NEXT];
		my $prev_addr = get_raw_address($prev);
		my $next_addr = get_raw_address($next);

		print "\t\t [ $prev_addr , $next_addr ]\n";

	}


	print "\n";
	return; 
}




=head2 get_more_letters

if a LETTER needs more letters, then call this and we'll have the linked list get more letters.
Note that $which will be either NEXTSTART or NEXTCONN

=cut

sub get_more_letters{
	# $which will be "CONNECTIONS" or "NEXTSTART"
	my($ltrobj,$which,$axis)=@_; # note: $axis will default to 0 if not supplied.
	eval{
		$ltrobj->get_linked_list()->get_more_letters($ltrobj,$which,$axis);
	};
	if($@){
		croak "$@ ";
	}
}


=head2 Connections verus Next Starting Position
If we want to parse a 2-D array of text, we have to step through each starting position
and try to match the regular expression to the string. The regular expression can match
through any connection between letters.

For example, a simple 2D list could be interconnected vertically and horizontally like this:

1---2---3
|   |   |      
|   |   |
|   |   |
4---5---6
|   |   |      
|   |   |
|   |   |
7---8---9

Or it could be connected on diagonals as well:

1---2---3
|\ /|\ /|      
| X | X |
|/ \|/ \|
4---5---6
|\ /|\ /|      
| X | X |
|/ \|/ \|
7---8---9

As we try to fit a regular expression to the linked list, we will follow the CONNECTIONS
to figure out what letters are in sequential order.

As we parse, if we're at letter "3", this can connect to 2, 6, and possibly 5.
But if starting from "3" does not yeild a match, then we need to move to the next starting position,
which could be "4". 4 doesn't connect to 3, but it is the next starting position after 3.



simple 3D list might be connected horizontally and vertically like this:

1----2----3
|\   |\   |\
| 4--+-5--+-6
| |  | |  | | 
7-+--8-+--9 |
 \|   \|   \|
  a----b----c


The "starting position" order could be 1->2->3->4->5->6->7->8->9->a->b->c

Note that 3 is not CONNECTED to 4, but if we try 3 as a starting position
and it fails, then after 3 the NEXT STARTING POSITION is 4.

The NextStartingPosition and the ConnectionsBetweenLetters are two different concepts
that are built into the data structures of the linked list and the letters.

And they are accessed through several methods:

Connections:

We can create a connection between two letters with:
	link_two_letters_via_interconnection
And we can get the next connection with:
	next_connection


Starting Positions:

We can create a link between letters for starting connections with:
	link_two_letters_via_next_start
We can traverse from one starting position to the next with:
	advance_start_position



=cut


=head2 link_two_letters_via_next_start

	$first->link_two_letters_via_next_start($second);

Create a link so that after $first, the next starting position is $second.

=cut
sub link_two_letters_via_next_start{
	my ($firstltr,$nextltr)=@_;
	$firstltr->[LETTER__NEXT_START]=$nextltr;
	$nextltr->[LETTER__PREVIOUS_START]=$firstltr;

}

=head2 advance_start_position

Advance (move) the starting position to the next spot.

	my $second = $first->advance_start_position();

We tried to match the regular expression starting from $first, but it didn't match.
So, now we want to advance to the $second starting position and try from there.

If nextstart points to end or null or whatever, then get more letters.

=cut
sub advance_start_position{
	my $ltrobj=shift(@_);

	if(
		# if it is undef or 0 or "false" in any perl sense of false
  		(not($ltrobj->[LETTER__NEXT_START]))	

		# or if it points to the LAST POINTER of the linked list object
		or ($ltrobj->[LETTER__NEXT_START] eq $ltrobj->[LETTER__LINKED_LIST]->[LIST__LAST_START])
	){
		$ltrobj->get_more_letters("START_POSITION");
	}
	return $ltrobj->[LETTER__NEXT_START];
}


=head2 link_two_letters_via_interconnection 

	$first->link_two_letters_via_interconnection($second,$axis);

Create a linkage between $first and $second so that they are INTERCONNECTED 
to be treated as sequential letters for parsing purposes.

The $axis defaults to 0. It represents whatever axis your linked list structure needs.
For example, one axis could be the "vertical" axis. In that example, $first could be thought
of as being "up" from $second. And $second could be thought of as "down" from $first.

=cut

sub link_two_letters_via_interconnection{
	my ($thisltr, $nextltr, $axis)=@_; # axis optional and defaults to 0

#warn "link_two_letters_via_interconnection";
#if(defined($thisltr)){$thisltr->display();}
#if(defined($nextltr)){$nextltr->display();}


	$axis||=0;

	if      ($axis>($thisltr->[LETTER__LINKED_LIST]->[LIST__CONNECTIONS_MINUS_ONE])){
		my $max=$thisltr->[LETTER__LINKED_LIST]->[LIST__CONNECTIONS_MINUS_ONE];
		croak "ERROR: axis greater than max number of axis for letter (axis is $axis)(max is $max)";
	}

	# initially we have START->LAST
	# when we add letter "A", we end up with START->A->LAST, 
	# this is fine for starting position connectoin
	# but parsing interconnection does not connect to FIRSTSTART or LASTSTART.
	# FIRST and LAST are placeholders and should never be parsed.
	my $firststart=$thisltr->[LETTER__LINKED_LIST]->[LIST__FIRST_START];
	my $laststart =$thisltr->[LETTER__LINKED_LIST]->[LIST__LAST_START];
	if(
		   not(defined($thisltr))
		or not(defined($nextltr))
		or ($thisltr eq $firststart)
		or ($thisltr eq $laststart)
		or ($nextltr eq $firststart)
		or ($nextltr eq $laststart)
	){
		# do nothing. Do not create parsing interconnection to FIRSTSTART or LASTSTART markers.
	} else {
		# both letters are valid letters, interconnect them.
		$thisltr->[LETTER__CONNECTIONS]->[$axis]->[LETTER__CONNECTION_NEXT]=$nextltr;
		$nextltr->[LETTER__CONNECTIONS]->[$axis]->[LETTER__CONNECTION_PREV]=$thisltr;
	}
}


=head2 advance_to_next_connection

	my $next_letter = $curr_letter->advance_to_next_connection($overalldirectionforrule);

We are at $curr_letter, trying to fit the regular expression to string.
The next letter will be returned by advance_to_next_connection($axis)
where axis is which index into the array to look for the connection.

=cut

sub advance_to_next_connection {
	my ($ltrobj)=@_;
	
	my $llist = $ltrobj->[LETTER__LINKED_LIST];
	
	my $axis    =$llist->[LIST__HEADING_DIRECTION_INDEX];
	my $prevnext=$llist->[LIST__HEADING_PREVNEXT_INDEX];

	#warn "axis "; print Dumper $axis;
	#warn "prevnext "; print Dumper $prevnext;

	if 		($ltrobj->[LETTER__CONNECTIONS]->[$axis]->[$prevnext]){
		return   $ltrobj->[LETTER__CONNECTIONS]->[$axis]->[$prevnext];
	} else {
		$ltrobj->get_more_letters("CONNECTIONS",  $axis,   $prevnext); 
	    	return   $ltrobj->[LETTER__CONNECTIONS]->[$axis]->[$prevnext];
	}
}





=head2 get_list_of_connecting_letters

return a list of possible letters to try based on parsing connections array for this letter
and any other rules you want to use for your grammar.

By default, this class method will return an array of any connected letter that is not already consumed.

You can override this behaviour by redefining the method to do whatever you want.
You could, for example, require that the connections only go in a straight line.
Or you could, as a counter example, allow any connection, including letters that
have been marked as "consumed" and allow them to be used again and again.

You might even allow the current letter to be used multiple times for multiple rules without advancing.

=cut

sub get_list_of_connecting_letters{

	my($ltrobj)=@_;

	my $arrayref = [];

	my $size = scalar(@{$ltrobj->[LETTER__CONNECTIONS]});

	for(my $firstindex=0; $firstindex<$size; $firstindex++) {
		my $connection_array_ref = $ltrobj->[LETTER__CONNECTIONS]->[$firstindex];
	
		foreach my $secondindex (LETTER__CONNECTION_NEXT, LETTER__CONNECTION_PREV){

			my $nextletter = $connection_array_ref->[$secondindex];


			if(defined($nextletter) and ($nextletter) and ($nextletter->[LETTER__LETTER_HAS_BEEN_CONSUMED]==0) ){
				push(@$arrayref, $nextletter);
			}
		}
	}

	return (@$arrayref);
}


=head2 delete

delete this letter and all previous letters 

work your way back until we get to the first_start position.

Note: this assumes that object connections are symmetrical.

if A connects to B at dimension 3, then B connects to B at dimension 3 in the opposite direction.

=cut

sub delete{
	my ($ltrobj)=@_;	

	# if $thisobj is firststart or laststart, then return. leave the markers alone.
	return if($ltrobj eq $ltrobj->[LETTER__LINKED_LIST]->[LIST__FIRST_START]);
	return if($ltrobj eq $ltrobj->[LETTER__LINKED_LIST]->[LIST__LAST_START]);


	# look at all connections and make sure no one points to $thisobj.
	# want $thisobj reference count to go to zero so it will be garbage collected.
	# Note that this assumes one level of symmetry: that the only thing that points 
	# to $thisobj are the letters connected to $thisobj.
	# The assumption is that nothing connects to A unless A also connects to IT.
	# so if we go through all the connections for $thisobj, then we'll find and delte
	# all the connections TO $thisobj.
	foreach my $dimension (0 .. scalar(@{$ltrobj->[LETTER__CONNECTIONS]})) {
		foreach my $direction ( LETTER__CONNECTION_NEXT, LETTER__CONNECTION_PREV){
			my $otherobj=$ltrobj->[LETTER__CONNECTIONS]->[$dimension]->[$direction];
			if(defined($otherobj) and ref($otherobj)){
				# delete anything in $otherobj connections that equals $thisobj
				# note this assumes another level of symmetry.
				# i.e. if A points to B at dimension 3, direction 0,
				#    then B points to A at dimension 3, direction 1.
				my $inversedirection=($direction == LETTER__CONNECTION_NEXT) 
					? LETTER__CONNECTION_PREV : LETTER__CONNECTION_NEXT;

				# delete the connection from $otherobj to $thisobj. Set it to undef.
				$otherobj->[LETTER__CONNECTIONS]->[$dimension]->[$inversedirection]=undef;
			}
		}
	}


	# get the previous_start letter
	my $prevstart=$ltrobj->[LETTER__PREVIOUS_START];

	# get the nextstart letter from thisobj
	my $nextstart=$ltrobj->[LETTER__NEXT_START];


	# if linked list currstart points to thisobj, then have ll currstart point to nextstart.
	if($ltrobj eq $ltrobj->[LETTER__LINKED_LIST]->[LIST__CURR_START]){
		      $ltrobj->[LETTER__LINKED_LIST]->[LIST__CURR_START] = $nextstart;
	}



	# if prevstart is something, then it's nextstart points to thisobj, delete that reference
	# have prevstart letter point to nextstart letter so that we still have a sequence of some kind.
	# if we continue going back through prevstart, then firststart should eventually end up 
	# pointing to the nextstart letter, adn we'll still be in the correct order.
	if( defined($prevstart) and (ref($prevstart))){
		$prevstart->[LETTER__NEXT_START] = $nextstart;
	}

	# return the previous_start letter. User can loop until we return first_start.
	return $prevstart;

}




1;

