


package Parse::Gnaw::LinkedList;

#BEGIN {warn "inside Parse::Gnaw::LinkedList";}

our $VERSION = '0.001';

use warnings;
use strict;
use Data::Dumper;
use Carp;

use Parse::Gnaw::Blocks::Letter;
use Parse::Gnaw::Blocks::LetterConstants;
use Parse::Gnaw::LinkedListConstants;

use base 'Parse::Gnaw::Blocks::ParsingMethods';
use       Parse::Gnaw::Blocks::ParsingMethods;

=head1 NAME

Parse::Gnaw::LinkedList - A Parsable linked list of Parse::Gnaw::Letter objects.

This class will create a basic, doubly-linked linked-list.

A <=> B <=> C <=> D

B prev will point to A
A next will point to B

and so on.

If you want more sophisticated linked lists, then use this as a base class and 
override the create_interconnections_for_newly_appended_character method

=head1 VERSION

Version 0.01

=cut


=head1 SUBROUTINES/METHODS

=cut

=head2 get_raw_address

call letter package version of get_raw_address

=cut

sub get_raw_address{
	Parse::Gnaw::Blocks::Letter::get_raw_address(@_);
}

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

		# how many connections/directions between each letter.
		# a connection might be "horizontal".
		# note that each connection/direction has a next/previous idea built in.
		# so if you have one connection/direction that is "horizontal",
		# then next/previous might translate into left/right.
		max_connections=>1,

		# linked list of something. this says of what.
		# can change this to make linked list of some other, new class.
		letterpkg=>'Parse::Gnaw::Blocks::Letter',
	);

	return (%defaults);
}


=head2 new

The new method is a constructor for creating a linked list

=cut
sub new{

	my $llistpkg=shift(@_);
	my %defaults=$llistpkg->constructor_defaults();

	my %arguments;

	if(scalar(@_)==1){
		my $arg=shift(@_);
		if(ref($arg)){
			croak "constructor doesnt know how to handle this argument '$arg'";
		}
		$arguments{string}=$arg;
	} elsif((scalar(@_)%2)==1){
			print Dumper \@_;
			croak "constructor doesnt know how to handle odd number of arguments";
	} else {
		%arguments=@_;
	}

	while(my($key,$val)=each(%defaults)){
		unless(exists($arguments{$key})){
			$arguments{$key}=$defaults{$key};
		}
	}

	my $letterpkg=$arguments{letterpkg};

	my $usecmd = "use $letterpkg;";
	# warn "usecmd is '$usecmd' ";
	eval($usecmd);

	my $connm1   =$arguments{max_connections}-1;

	my $llist=bless([],$llistpkg);

	$llist->[LIST__HEADING_DIRECTION_INDEX]=0;
	$llist->[LIST__HEADING_PREVNEXT_INDEX]=0;

	$llist->[LIST__LETTER_PACKAGE]=$letterpkg;
	$llist->[LIST__CONNECTIONS_MINUS_ONE]=$connm1;

	my $first=$letterpkg->new($llist,'FIRSTSTART', 0);
	my $last =$letterpkg->new($llist,'LASTSTART' , 0);

	$llist->[LIST__FIRST_START]=$first;

	$llist->[LIST__LAST_START]=$last;

	$llist->[LIST__CURR_START]=$first;

	$llist->[LIST__PREVIOUS_LINE_LETTER]=[];
	$llist->[LIST__QUANTIFIER_STACK]=[];
	$llist->[LIST__RULE_STACK]=[];

	my $string = $arguments{string};


	# note that each class will define its own "append" method
	# depending on how many dimensions and connections the class 
	# is trying to model.
	# the contructor will always call "append". 
	# it is up to the class to override "append" to do the right thing.
	$llist->append($llist->[LIST__FIRST_START], $string);

	return $llist;
}

=head2 append
this gets overloaded by derived classes so base constructor always does the right thing.
=cut
sub append{
	my $obj=shift(@_);
	$obj->append_string(@_);
}

=head2 get_location_of_caller
If location is defined, just return that. 
If not, go through caller history and find first file/linenum that is not Parse::Gnaw related.
=cut
sub get_location_of_caller{
	my($llist,$location)=@_;

	if($location) {
		return $location;
	}

	my @caller;
	foreach my $callbackdepth (1..10){
		@caller=caller($callbackdepth); 
		my $package=$caller[0];
		last if(not($package =~ m{Parse::Gnaw}));
	}

	my $sourcefilename = $caller[1] || 'unknown'; 
	my $sourcelinenum  = $caller[2] || 'unknown';

	$location = "file $sourcefilename, line $sourcelinenum";

	return $location;
}

=head2 append_string
append a single dimension line of text.
=cut
sub append_string{
	my($llist, $lettertoappendto, $stringtoappend, $location)=@_;

	if(not(defined($location))){
		$location = $llist->get_location_of_caller($location);	
	}

	#warn "append_string llist=$llist, lettertoappendto=$lettertoappendto, stringtoappend=$stringtoappend, location=$location";

	#die "$location";

	my @characters=split(//, $stringtoappend);
	my $last_x_val = scalar(@characters)-1;
	my $first_letter_of_line;

	my @ltrobjs;

	for(my $x=0; $x<=$last_x_val; $x++){
		my $character=$characters[$x];
		my $charlocation = "$location, column $x";

		my $newletter=$llist->append_character($lettertoappendto, $character, $charlocation);

		push(@ltrobjs,$newletter);
		$lettertoappendto=$newletter;
	}

	for(my $x=0; $x<=$last_x_val; $x++){

		my $centerletter=$ltrobjs[$x];

		if($x>0){
			my $leftletter=$ltrobjs[$x-1];
			# connect the interconnections of the new/center letter to the letters on either side.
			$leftletter->link_two_letters_via_interconnection($centerletter,0); 
		}

	}


	# now that we're done adding this line, we can update the object "start of previoius line" 
	# to be the first letter of the line we just added
	$llist->[LIST__PREVIOUS_LINE_LETTER]->[0]=$first_letter_of_line;
	
	return $lettertoappendto;
}


=head2 append_character

	my $newletter = $llist->append_character($lettertoappendto, $single_character_to_append, $location);

Note that the order in which you append individual characters becomes the default 
order for the next_start method.

=cut

sub append_character{
	my($llist, $lettertoappendto, $single_character_to_append, $location)=@_; 

	if(not(defined($location))){
		$location = $llist->get_location_of_caller($location);	
	}

	# we have lettertoappendto -> rightstartletter
	# we make lettertoappendto -> centerletter -> rightstartletter
	# before we do anything, get the rightstartletter so we can remember it.
	my $rightstartletter = $lettertoappendto->[LETTER__NEXT_START];

	# create the new letter, the center letter.
	my $letter_pkg = $llist->[LIST__LETTER_PACKAGE];
	my $centerletter = $letter_pkg->new($llist, $single_character_to_append, $location);

	# connect the start position of center letter to the letters on either side
	$lettertoappendto->link_two_letters_via_next_start($centerletter);
	    $centerletter->link_two_letters_via_next_start($rightstartletter);
	

	return $centerletter;
}

=head2 create_interconnections_for_newly_appended_character

for base class, don't make any connections automatically.
let user, or derived class, make connections.

=cut

sub create_interconnections_for_newly_appended_character{
	my($llist,$prevletter,$justaddedletter)=@_;
	return;
}


=head2 display

print out a formatted version of linked list object.

=cut

sub display {
	my ($llist)=@_;

	print "Dumping LinkedList object\n";

	print "LETPKG => ".($llist->[LIST__LETTER_PACKAGE])." # package name of letter objects\n";
	
	print "CONNMIN1 => ".($llist->[LIST__CONNECTIONS_MINUS_ONE])." # max number of connections, minus 1\n";

	print "HEADING_DIRECTION_INDEX => ".($llist->[LIST__HEADING_DIRECTION_INDEX])."\n";
	print "HEADING_PREVNEXT_INDEX  => ".($llist->[LIST__HEADING_PREVNEXT_INDEX]) ."\n";


	print "FIRSTSTART => \n";

	$llist->[LIST__FIRST_START]->display();


	print "LASTSTART => \n";

	$llist->[LIST__LAST_START]->display();

	print "CURRPTR => \n";

	$llist->[LIST__CURR_START]->display();

	my $letterobj=$llist->[LIST__FIRST_START];

	print "\nletters, by order of next_start_position()\n";

	my $count=0;

	while(($letterobj) and ($letterobj->[LETTER__DATA_PAYLOAD] ne 'LASTSTART')){
		
		$letterobj=$letterobj->[LETTER__NEXT_START];
		$letterobj->display();

		last if($count++ > 24);
		#if($letterobj->[LETTER__DATA_PAYLOAD] eq 'p'){last;}
	}
	
}



=head2 get_connection_iterator

return an array of connections we can iterate. should be something like this:

	[
		[0,0],
		[0,1],
		[1,0],
		[1,1],
		[2,0],
		[2,1],
	]

and so on.

=cut

sub get_connection_iterator{
	my($llist)=@_;	

	my $arrref=[];
	my $cm1 = ($llist->[LIST__CONNECTIONS_MINUS_ONE])+0;
	#warn "connections minus one is '$cm1' ";

	foreach my $dimension (0 .. $cm1){
		for my $direction (0..1){
			push(@$arrref, [$dimension,$direction]);
		}
	}

	#warn "conn iter "; print Dumper $arrref;
	return $arrref;


}




=head2 get_more_letters

Note that by default, this method simply dies.
We assume that for this class, we won't be parsing a stream,
that all letters will be in memory.

If we want to handle parsing a stream, override this method to read text from a file and append it to the letter given.

$which will be "CONNECTIONS" or "NEXTSTART", depending on who ran out of letters.

$llist->get_more_letters($thisletter,$which,$axis);

=cut

sub get_more_letters{
	my($llist,$thisletter,$which,$axis)=@_;

	die "GRAMMARFAIL";
}


=head2 run_coderef_and_catch_grammar_fail

call this subroutine and pass in a coderef. This sub will call coderef and trap grammarfailures.
if grammar failed, return 0.
if grammar passed, return 1.
if grammar died for any other reason, pass the die along.

=cut

sub run_coderef_and_catch_grammar_fail{
	my($llist, $coderef)=@_;
	unless(ref($coderef) eq 'CODE'){
		confess "ERROR: run_subroutine_and_catch_grammar_fail expects first parameter to be a code ref. found $coderef";
	}
	eval{
		$coderef->();
	};

	# if we died,
	if($@){
		# if we died because of GRAMMARFAIL, then that just means we didn't match
		if($@ =~ m{GRAMMARFAIL}){
			return 0;

		# otherwise we died of some sort of real crash/error.
		} else {
			die $@; # some other kind of error.
		}

	# if we didn't die, return success
	} else {
		return 1;
	}
}





=head2 convert_rule_name_to_rule_reference

Given a grammar rule and a string:

	rule('firstrule', 'a', call('subrule'), 'd');
	my $ab_string=Parse::Gnaw::LinkedList->new('abcdefg');


Users can call parse() multiple ways.

The first way to call it is by passing in the array reference to the rule.
Every rule defined creates an array reference in the caller's package namespace.
And that array reference is the same name as the rule, and contains the rule structure.

	$ab_string->parse($firstrule)

The second way to call it is by passing in the name of the rule as a string.
This can either be a simple name without the package specifier:

	$ab_string->parse('firstrule');

Or it can be a fully package specified name:

	$ab_string->parse('main::firstrule');



=cut

sub convert_rule_name_to_rule_reference{

	my($llist,$rulename)=@_;

	unless(defined($rulename)){
		croak "ERROR: need to pass in a defined rule name";
	}

	# this subroutine takes in the name of a rule, such as "Verilog::Module" 
	# and returns the package variable $Verilog::Module, which must be an array reference.
	# if $grammarname is already an array reference, just return it.
	if(ref($rulename)){
		if(ref($rulename) eq 'ARRAY'){
			return $rulename;
		} else {
			print Dumper $rulename;
			confess "ERROR: called convert_rule_name_to_rule_reference and passed in a reference, and I can't handle it '$rulename'";
		}
	} else {
		my $ref;
		if($rulename =~ m{\:\:}){
			my $eval='$ref= $'.$rulename.';';
			eval($eval);
			return $ref;
		} else {
			my $iter=1;
			ITERATOR : while(1){
				my @caller=caller($iter++);
				if(scalar(@caller)<3){
					confess "ERROR: tried to use caller($iter) but appears to be broken";
				}
				my $package=$caller[0];
				if($package =~ m{Parse::Gnaw}){
					next ITERATOR;
				}
				my $ref;
				my $eval='$ref = $'.$package.'::'.$rulename.';';
				#warn "eval is '$eval'";
				eval($eval);
				unless( defined($ref) and (ref($ref) eq 'ARRAY') ){
					confess "ERROR: unable to fine rule '$rulename' in package '$package'";
				}
				return $ref;
			}
		}
	}
}




=head2 parse

$llist->parse($grammar);

Try to match the grammar to the llist, starting from where the CURR pointer points to.
Do not try from any other location.


=cut



sub parse{
	my($llobj, $ruletocall)=@_;

	# get a reference to original rule with this name.
	my $grammarref=$llobj->convert_rule_name_to_rule_reference($ruletocall); 
	my @grammarcopy=@$grammarref;		# make a shallow copy of rule.
	my $grammarcopyref=\@grammarcopy;	# this is a reference to copy of rule

	# the "parse" function always starts from the very beginning of the string.
	# so first thing we need to do is reset the current-pointer 
	$llobj->[LIST__CURR_START] =  $llobj->[LIST__FIRST_START]->[LETTER__NEXT_START];

	my $save_start = $llobj->[LIST__CURR_START];

	eval{
		$llobj->parse_grammarref($grammarcopyref, '');
	};

	if($@){
		#print "parse died with '$@'\n";
		$llobj->[LIST__CURR_START] = $save_start; 	# failed or crashed, either way, restore pointer.

		if($@ =~ m{GRAMMARFAIL}){
			return 0;
		} else {
			#print "parse other error\n";
			die $@;
		}
	} else {
		#print "parse matched\n";

		return 1;
	}
}





=head2 match

$llist->match($grammar);

Try to match the grammar to the llist, starting from where the CURR pointer points to,
and trying every position until get a match or we hit the end of the llist.

=cut

# possible issue here:
# if we start out with an empty list, or with the currpointer at the last letter,
# then we should really try to get more data first, then check to see if currptr equals LASTSTART.
# if we check equality first, then match could fail before even trying.
sub match{
	my($myllist, $mygrammarref)=@_;

	# the only way CURR would equal LAST would be if we ran out of text and couldn't append any new text.
	while($myllist->get_current_start() ne $myllist->get_last_start()){ 

		if($myllist->parse($mygrammarref)){
			return 1;
		} 
		
		$myllist->set_current_start( $myllist->get_current_start()->next_start_position()); # this will get more text if needed and if it can
	}
}

		
1;


