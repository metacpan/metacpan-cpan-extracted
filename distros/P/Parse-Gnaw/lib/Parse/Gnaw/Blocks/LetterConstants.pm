
package Parse::Gnaw::Blocks::LetterConstants;


our $VERSION = '0.001';

use warnings;
use strict;
use Carp;
use Data::Dumper;
use Storable 'dclone';

=head1 NAME

Parse::Gnaw::Blocks::LetterConstants - Hold subroutine/constants for Letter objects
These are NOT contained in a separate package so that another file can use them and they automatically
get imported into that package.

Not in its own package namespace so that whoever uses it, sees all the functions.


=head2 LETTER__LINKED_LIST
This is a constant index into the object array for the LETTER__LINKED_LIST, the linked list object that holds this letter.
=cut

=head2 LETTER__DATA_PAYLOAD
This is a constant index into the object array for the LETTER__DATA_PAYLOAD, the data payload for this letter.
assuming it is a single character. Will have to override and redefine a bunch of methods if
you want it to be something else.
First and Last letters use 'first' and 'last' as the payload.
=cut

=head2 LETTER__CONNECTIONS
This is a constant index into the object array for the LETTER__CONNECTIONS, the axis array which indicates
the next and previous letters on each axis. Axis 0 might represent the "vertical" axis.
Axis0->[0] would be up
Axis0->[1] would be down.
=cut

=head2 LETTER__NEXT_START
This is a constant index into the object array for the LETTER__NEXT_START, the letter that would be the 
next "match" starting position after the current letter.
=cut

=head2 LETTER__PREVIOUS_START
This is a constant index into the object array for the LETTER__PREVIOUS_START, the letter that would be the 
previous "match" starting position before the current letter.
=cut

=head2 LETTER__CAPTURE_COUNT
This is a count of how many letters have been matched(captured) so far.
=cut


=head2 LETTER__WHERE_LETTER_CAME_FROM
This is a constant index into the object array for the LETTER__WHERE_LETTER_CAME_FROM, a string describing where
this particular letter came from. 
=cut

=head2 LETTER__LETTER_HAS_BEEN_CONSUMED
This is a constant index into the object array for the LETTER__LETTER_HAS_BEEN_CONSUMED flag,
this is a boolean indicating whether this particular letter instance has been "consumed" by the grammar or not.
=cut


=head2 LETTER__CONNECTION_NEXT
Each index into the axis array contains a 2-dimensional array for next/prev values.
Axis0->[0] would be up
Axis0->[1] would be down.
=cut

=head2 LETTER__CONNECTION_PREV
Each index into the axis array contains a 2-dimensional array for next/prev values.
Axis0->[0] would be up
Axis0->[1] would be down.
=cut

use Exporter 'import'; 
our @EXPORT = qw(LETTER__LINKED_LIST LETTER__DATA_PAYLOAD LETTER__CONNECTIONS LETTER__NEXT_START 
LETTER__PREVIOUS_START LETTER__WHERE_LETTER_CAME_FROM LETTER__CONNECTION_PREV LETTER__CONNECTION_NEXT LETTER__LETTER_HAS_BEEN_CONSUMED ); 

#######################################################
# this is how you do constants in perl, subroutines with just a number,
# so they get optimized out into plain old fashioned numbers.
#######################################################
sub LETTER__LINKED_LIST 		(){0}	# the linked-list that contains this letter.
sub LETTER__DATA_PAYLOAD 		(){1}	# the letter/payload
sub LETTER__CONNECTIONS 		(){2}	# an array of all possible axis/LETTER__CONNECTIONS
sub LETTER__NEXT_START			(){3}	# next start position
sub LETTER__PREVIOUS_START   		(){4}	# previous start positoin
sub LETTER__CAPTURE_COUNT		(){5}	# a count of how many times this letter is captured as part of the matching pattern.
sub LETTER__WHERE_LETTER_CAME_FROM	(){6}	# string describing where the letter came from
sub LETTER__LETTER_HAS_BEEN_CONSUMED	(){7}	# when we advance to next letter, set this to zero. When we finally match this letter and want to advance pointer again, set this to 1.


sub LETTER__CONNECTION_PREV 		(){1}	# prev connection in axis array, i.e. vertical axis->prev==up
sub LETTER__CONNECTION_NEXT 		(){0}	# next connection in axis array, i.e. vertical axis->next==down




1;

