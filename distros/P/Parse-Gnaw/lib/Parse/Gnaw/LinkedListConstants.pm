
package Parse::Gnaw::LinkedListConstants;

our $VERSION = '0.001';

use warnings;
use strict;

=head1 NAME

Parse::Gnaw::LinkedListLetterConstants - Hold subroutine/constants for LinkedListLetter objects
These are NOT contained in a separate package so that another file can use them and they automatically
get imported into that package.

=head1 VERSION

Version 0.01

=cut


=head1 SUBROUTINES/METHODS

=cut

=head2 LIST__LETTER_PACKAGE
This is a constant index into the object array for the "letter" object package name.
The linked list object will need to create new letters and it will need to know 
what package to use to create those letters from.
=cut

=head2 LIST__CONNECTIONS_MINUS_ONE
This is a constant index into the object array for the Maximum Number of Axis, minus 1.
An object with 3 axis will have this set to 2. 
Index into the axis array will be 0 .. LIST__CONNECTIONS_MINUS_ONE
=cut

=head2 LIST__FIRST_START
This is a constant index into the object array for the LIST__FIRST_START.
The First start is a dummy placeholder letter that is always the "first"
Start position in the linked list and doesn't contain any real payload.
=cut

=head2 LIST__LAST_START
This is a constant index into the object array for the LIST__LAST_START.
The Last Start is a dummy placeholder letter that is always the "last"
letter in the linked list "start" sequence and doesn't contain any real payload.
=cut

=head2 LIST__CURR_START
This is a constant index into the object array for the LIST__CURR_START.
This is the current letter where we would start our next match/parse.
This is the letter AFTER the previous match.

	A B C D E F G

If we do a match/parse that matches "A B C" then LIST__CURR_START will point to D.
=cut

=head2 LIST__MOST_RECENTLY_CREATED_LETTER
This is a pointer to whatever was the last letter that was created by the linked list.
=cut

=head2 LIST__HEADING_DIRECTION_INDEX
This remembers which way we are heading when we start finding a match.
=cut

=head2 LIST__HEADING_PREVNEXT_INDEX
This remembers which way we are heading when we start finding a match.
=cut

=head2 LIST__PREVIOUS_LINE_LETTER
This remembers the letter from the previous line.
Need this for 2D text and any other linked list structure that isn't just 1D.
=cut

=head2 LIST__QUANTIFIER_STACK
As we parse this linked/list, ew need to keep track of the quantifiers we encounter.
=cut

=head2 LIST__RULE_STACK
might need this later. currently not using it.
=cut

use Exporter 'import'; 
our @EXPORT = qw( LIST__LETTER_PACKAGE LIST__CONNECTIONS_MINUS_ONE LIST__FIRST_START LIST__LAST_START
 LIST__CURR_START LIST__MOST_RECENTLY_CREATED_LETTER  LIST__HEADING_DIRECTION_INDEX  LIST__HEADING_PREVNEXT_INDEX
LIST__PREVIOUS_LINE_LETTER LIST__QUANTIFIER_STACK LIST__RULE_STACK ); 

sub LIST__LETTER_PACKAGE 		(){0}	# package name of letter class
sub LIST__CONNECTIONS_MINUS_ONE		(){1}	# max number of axis in this linked list minus 1
sub LIST__FIRST_START			(){2}	# pointer to FIRST start START position (always a place holder, not an actual letter)
sub LIST__LAST_START			(){3}	# pointer to LAST  letter (always a place holder, not an actual letter)
sub LIST__CURR_START			(){4}	# pointer to CURRENT letter. Sometimes a placeholder, sometimes a letter.
sub LIST__MOST_RECENTLY_CREATED_LETTER	(){5}	# pointer to the most recently created letter associated with this linked list
sub LIST__HEADING_DIRECTION_INDEX	(){6}	# the direction index used by advance_to_next_connection
sub LIST__HEADING_PREVNEXT_INDEX	(){7}	# the prevnext  index used by advance_to_next_connection
sub LIST__PREVIOUS_LINE_LETTER		(){8}	# the letter that is one line "up" from last appended letter (last start)
sub LIST__QUANTIFIER_STACK		(){9}	# quantifiers have to be kept track of so we can try differnt quantities.
sub LIST__RULE_STACK			(){10}	# quantifiers have to be kept track of so we can try differnt quantities.


1;


